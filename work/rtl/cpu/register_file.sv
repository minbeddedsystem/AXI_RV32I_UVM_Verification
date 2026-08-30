`timescale 1ns / 1ps

module register_file (
    input  logic        clk,
    input  logic [ 4:0] raddr1,  // rs1
    input  logic [ 4:0] raddr2,  // rs2
    input  logic        rf_we,   // register file write enable (WB 단계에서 옴)
    input  logic [ 4:0] waddr,   // rd (WB 단계에서 옴)
    input  logic [31:0] wdata,   // rd write data (WB 단계에서 옴)
    output logic [31:0] rdata1,  // rs1 read data
    output logic [31:0] rdata2   // rs2 read data
);

    logic [31:0] register_file[0:31];

    initial begin
        for (int i = 0; i < 32; i++) begin
            register_file[i] = i;
        end
        register_file[0]  = 32'h0000_0000;
        register_file[31] = 32'h0000_00B0;
    end

    always @(posedge clk) begin
        if (rf_we && (waddr != 5'd0)) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 :
                     (rf_we && (waddr == raddr1)) ? wdata :
                     register_file[raddr1];

    assign rdata2 = (raddr2 == 5'd0) ? 32'd0 :
                     (rf_we && (waddr == raddr2)) ? wdata :
                     register_file[raddr2];

endmodule
