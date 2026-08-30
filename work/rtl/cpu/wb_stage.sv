`timescale 1ns / 1ps

module wb_stage (
    input logic [31:0] alu_result,
    input logic [31:0] drdata,
    input logic [31:0] imm,
    input logic [31:0] pc_imm,
    input logic [31:0] pc_4,
    input logic [ 2:0] rf_src_sel,
    input logic [ 4:0] rd_addr,
    input logic        rf_we,

    output logic [31:0] wb_wdata,
    output logic [ 4:0] wb_waddr,
    output logic        wb_we
);

    always_comb begin
        wb_wdata = 32'd0;
        case (rf_src_sel)
            3'b000:  wb_wdata = alu_result;
            3'b001:  wb_wdata = drdata;
            3'b010:  wb_wdata = imm;
            3'b011:  wb_wdata = pc_imm;
            3'b100:  wb_wdata = pc_4;
            default: wb_wdata = 32'd0;
        endcase
    end

    assign wb_waddr = rd_addr;
    assign wb_we    = rf_we;

endmodule
