module axi_lite_reg_slave (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] awaddr,
    input  logic        awvalid,
    output logic        awready,

    input  logic [31:0] wdata,
    input  logic [ 3:0] wstrb,
    input  logic        wvalid,
    output logic        wready,

    output logic [1:0] bresp,
    output logic       bvalid,
    input  logic       bready,

    input  logic [31:0] araddr,
    input  logic        arvalid,
    output logic        arready,

    output logic [31:0] rdata,
    output logic [ 1:0] rresp,
    output logic        rvalid,
    input  logic        rready
);

    logic [31:0] regfile[0:3];

    // ---- Write channel (AW/W 독립 처리) ----
    logic aw_hs, w_hs;
    logic [31:0] awaddr_q, wdata_q;
    logic [3:0] wstrb_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready <= 1'b1;
            wready  <= 1'b1;
            bvalid  <= 1'b0;
            aw_hs   <= 1'b0;
            w_hs    <= 1'b0;
        end else begin
            if (awvalid && awready) begin
                awaddr_q <= awaddr;
                aw_hs    <= 1'b1;
                awready  <= 1'b0;
            end

            if (wvalid && wready) begin
                wdata_q <= wdata;
                wstrb_q <= wstrb;
                w_hs    <= 1'b1;
                wready  <= 1'b0;
            end

            if (aw_hs && w_hs && !bvalid) begin
                if (wstrb_q[0]) regfile[awaddr_q[3:2]][7:0] <= wdata_q[7:0];
                if (wstrb_q[1]) regfile[awaddr_q[3:2]][15:8] <= wdata_q[15:8];
                if (wstrb_q[2]) regfile[awaddr_q[3:2]][23:16] <= wdata_q[23:16];
                if (wstrb_q[3]) regfile[awaddr_q[3:2]][31:24] <= wdata_q[31:24];
                bvalid <= 1'b1;
                bresp  <= 2'b00;  // OKAY
                aw_hs  <= 1'b0;
                w_hs   <= 1'b0;
            end

            if (bvalid && bready) begin
                bvalid  <= 1'b0;
                awready <= 1'b1;
                wready  <= 1'b1;
            end
        end
    end

    // ---- Read channel ----
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready <= 1'b1;
            rvalid  <= 1'b0;
        end else begin
            if (arvalid && arready) begin
                rdata   <= regfile[araddr[3:2]];
                rresp   <= 2'b00;  // OKAY
                rvalid  <= 1'b1;
                arready <= 1'b0;
            end

            if (rvalid && rready) begin
                rvalid  <= 1'b0;
                arready <= 1'b1;
            end
        end
    end

endmodule
