
module axi_apb_bridge (
    input  logic        clk,
    input  logic        rst_n,

    // ---------------- AXI4-Lite slave port ----------------
    input  logic [31:0] awaddr,
    input  logic        awvalid,
    output logic        awready,

    input  logic [31:0] wdata,
    input  logic [ 3:0] wstrb,
    input  logic        wvalid,
    output logic        wready,

    output logic [ 1:0] bresp,
    output logic        bvalid,
    input  logic        bready,

    input  logic [31:0] araddr,
    input  logic        arvalid,
    output logic        arready,

    output logic [31:0] rdata,
    output logic [ 1:0] rresp,
    output logic        rvalid,
    input  logic        rready,

    // ---------------- APB master port ----------------
    output logic [31:0] paddr,
    output logic        psel,
    output logic        penable,
    output logic        pwrite,
    output logic [31:0] pwdata,
    input  logic [31:0] prdata,
    input  logic        pready,
    input  logic        pslverr
);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_APB_SETUP,
        ST_APB_ACCESS,
        ST_WRITE_RESP,
        ST_READ_RESP
    } state_e;

    state_e state, state_next;

    // AW/W 독립 캡처
    logic        aw_hs, w_hs;
    logic [31:0] cap_awaddr, cap_wdata;
    logic [31:0] cap_araddr;
    logic        is_write;

    assign awready = (state == ST_IDLE) && !aw_hs;
    assign wready  = (state == ST_IDLE) && !w_hs;
    assign arready = (state == ST_IDLE) && !aw_hs && !w_hs;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            aw_hs      <= 1'b0;
            w_hs       <= 1'b0;
            cap_awaddr <= 32'd0;
            cap_wdata  <= 32'd0;
            cap_araddr <= 32'd0;
        end else begin
            if (awvalid && awready) begin
                aw_hs      <= 1'b1;
                cap_awaddr <= awaddr;
            end
            if (wvalid && wready) begin
                w_hs      <= 1'b1;
                cap_wdata <= wdata;
            end
            if (arvalid && arready) begin
                cap_araddr <= araddr;
            end
            // 다음 트랜잭션을 위해 IDLE로 돌아갈 때 클리어
            if (state == ST_IDLE && aw_hs && w_hs) begin
                aw_hs <= 1'b0;
                w_hs  <= 1'b0;
            end
        end
    end

    // ---------------- state register ----------------
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) state <= ST_IDLE;
        else state <= state_next;
    end

    // ---------------- next state / APB 구동 ----------------
    always_comb begin
        state_next = state;
        psel       = 1'b0;
        penable    = 1'b0;
        pwrite     = is_write;
        paddr      = is_write ? cap_awaddr : cap_araddr;
        pwdata     = cap_wdata;

        case (state)
            ST_IDLE: begin
                if (aw_hs && w_hs) state_next = ST_APB_SETUP;
                else if (arvalid && arready) state_next = ST_APB_SETUP;
            end

            ST_APB_SETUP: begin
                psel       = 1'b1;
                penable    = 1'b0;
                state_next = ST_APB_ACCESS;
            end

            ST_APB_ACCESS: begin
                psel    = 1'b1;
                penable = 1'b1;
                if (pready) begin
                    state_next = is_write ? ST_WRITE_RESP : ST_READ_RESP;
                end
            end

            ST_WRITE_RESP: begin
                if (bvalid && bready) state_next = ST_IDLE;
            end

            ST_READ_RESP: begin
                if (rvalid && rready) state_next = ST_IDLE;
            end
        endcase
    end

    // is_write는 SETUP 진입 시점에 래치 (ACCESS 중간에 바뀌면 안 되므로)
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) is_write <= 1'b0;
        else if (state == ST_IDLE && state_next == ST_APB_SETUP)
            is_write <= (aw_hs && w_hs);
    end

    // ---------------- B / R 응답 ----------------
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            bvalid <= 1'b0;
            bresp  <= 2'b00;
            rvalid <= 1'b0;
            rresp  <= 2'b00;
            rdata  <= 32'd0;
        end else begin
            // write response
            if (state == ST_APB_ACCESS && is_write && pready) begin
                bvalid <= 1'b1;
                bresp  <= pslverr ? 2'b10 : 2'b00;
            end else if (bvalid && bready) begin
                bvalid <= 1'b0;
            end

            // read response
            if (state == ST_APB_ACCESS && !is_write && pready) begin
                rvalid <= 1'b1;
                rdata  <= prdata;
                rresp  <= pslverr ? 2'b10 : 2'b00;
            end else if (rvalid && rready) begin
                rvalid <= 1'b0;
            end
        end
    end

endmodule