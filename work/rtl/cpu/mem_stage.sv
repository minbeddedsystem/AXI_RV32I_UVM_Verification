`timescale 1ns / 1ps

module mem_stage (
    input logic clk,
    input logic rst,

    input logic [31:0] alu_result,
    input logic [31:0] imm,
    input logic [31:0] pc_imm,
    input logic [31:0] pc_4,
    input logic [31:0] store_data,
    input logic [ 4:0] rd_addr,
    input logic        rf_we,
    input logic [ 2:0] rf_src_sel,
    input logic [ 2:0] mem_mode,
    input logic        dwe,

    output logic [31:0] daddr,
    output logic [31:0] dwdata,
    output logic        dwe_out,
    output logic [ 2:0] mem_mode_out,
    input  logic [31:0] drdata,

    output logic [31:0] wb_alu_result,
    output logic [31:0] wb_imm,
    output logic [31:0] wb_pc_imm,
    output logic [31:0] wb_pc_4,
    output logic [31:0] wb_drdata,
    output logic [ 4:0] wb_rd_addr,
    output logic        wb_rf_we,
    output logic [ 2:0] wb_rf_src_sel
);

    assign daddr        = alu_result;
    assign dwdata       = store_data;
    assign dwe_out      = dwe;
    assign mem_mode_out = mem_mode;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wb_alu_result <= 32'd0;
            wb_imm        <= 32'd0;
            wb_pc_imm     <= 32'd0;
            wb_pc_4       <= 32'd0;
            wb_drdata     <= 32'd0;
            wb_rd_addr    <= 5'd0;
            wb_rf_we      <= 1'b0;
            wb_rf_src_sel <= 3'd0;
        end else begin
            wb_alu_result <= alu_result;
            wb_imm        <= imm;
            wb_pc_imm     <= pc_imm;
            wb_pc_4       <= pc_4;
            wb_drdata     <= drdata;
            wb_rd_addr    <= rd_addr;
            wb_rf_we      <= rf_we;
            wb_rf_src_sel <= rf_src_sel;
        end
    end

endmodule
