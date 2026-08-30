`timescale 1ns / 1ps

module if_stage (
    input logic clk,
    input logic rst,

    // hazard control
    input logic pc_write,
    input logic if_id_write,
    input logic flush,

    input logic        pc_sel,      // 0: pc+4, 1: target_addr
    input logic [31:0] target_addr,

    input  logic [31:0] instr_code_in,
    output logic [31:0] instr_addr,

    output logic [31:0] id_pc,
    output logic [31:0] id_pc_4,
    output logic [31:0] id_instr_code
);

    logic [31:0] pc_reg, pc_next, pc_plus4;

    assign pc_plus4   = pc_reg + 32'd4;
    assign pc_next    = pc_sel ? target_addr : pc_plus4;
    assign instr_addr = pc_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) pc_reg <= 32'd0;
        else if (pc_write) pc_reg <= pc_next;
        // pc_write == 0 : stall, 그대로 유지
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            id_pc         <= 32'd0;
            id_pc_4       <= 32'd0;
            id_instr_code <= 32'd0;  // NOP
        end else if (flush) begin
            id_pc <= 32'd0;
            id_pc_4 <= 32'd0;
            id_instr_code <= 32'd0;  // NOP (0x00000013 아니어도 opcode 0 -> control_unit에서 전부 0 출력)
        end else if (if_id_write) begin
            id_pc         <= pc_reg;
            id_pc_4       <= pc_plus4;
            id_instr_code <= instr_code_in;
        end
        // if_id_write == 0 : stall, 그대로 유지
    end

endmodule
