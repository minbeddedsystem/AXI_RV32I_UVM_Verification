interface apb_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst_n
);

    logic [ADDR_WIDTH-1:0] paddr;
    logic                  psel;
    logic                  penable;
    logic                  pwrite;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [DATA_WIDTH-1:0] prdata;
    logic                  pready;
    logic                  pslverr;

endinterface
