module apb_reg_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr
);

    logic [DATA_WIDTH-1:0] regs[0:3];

    assign pready  = psel && penable;
    assign pslverr = 1'b0;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            regs[0] <= '0;
            regs[1] <= '0;
            regs[2] <= '0;
            regs[3] <= '0;
        end else if (psel && penable && pwrite) begin
            regs[paddr[3:2]] <= pwdata;
        end
    end

    always_comb begin
        prdata = regs[paddr[3:2]];
    end

endmodule
