interface axi4_lite_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst_n
);

    // Write Address Channel
    logic [  ADDR_WIDTH-1:0] awaddr;
    logic                    awvalid;
    logic                    awready;

    // Write Data Channel
    logic [  DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic                    wvalid;
    logic                    wready;

    // Write Response Channel
    logic [             1:0] bresp;
    logic                    bvalid;
    logic                    bready;

    // Read Address Channel
    logic [  ADDR_WIDTH-1:0] araddr;
    logic                    arvalid;
    logic                    arready;

    // Read Data Channel
    logic [  DATA_WIDTH-1:0] rdata;
    logic [             1:0] rresp;
    logic                    rvalid;
    logic                    rready;

endinterface
