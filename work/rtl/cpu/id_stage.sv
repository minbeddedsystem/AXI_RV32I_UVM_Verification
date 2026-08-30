`timescale 1ns / 1ps
`include "define.vh"

module id_stage (
    input logic clk,
    input logic rst,

    // hazard control
    input logic flush,

    input logic [31:0] pc,
    input logic [31:0] pc_4,
    input logic [31:0] instr_code,

    input logic        wb_we,
    input logic [ 4:0] wb_waddr,
    input logic [31:0] wb_wdata,

    output logic [4:0] id_rs1_addr,
    output logic [4:0] id_rs2_addr,

    output logic [31:0] ex_pc,
    output logic [31:0] ex_pc_4,
    output logic [31:0] ex_rs1,
    output logic [31:0] ex_rs2,
    output logic [31:0] ex_imm,
    output logic [ 4:0] ex_rs1_addr,
    output logic [ 4:0] ex_rs2_addr,
    output logic [ 4:0] ex_rd_addr,
    output logic        ex_rf_we,
    output logic        ex_branch,
    output logic        ex_jal,
    output logic        ex_jalr,
    output logic        ex_alusrc_sel,
    output logic [ 3:0] ex_alu_control,
    output logic [ 2:0] ex_rf_src_sel,
    output logic [ 2:0] ex_mem_mode,
    output logic        ex_dwe
);

    logic [31:0] rs1_data, rs2_data, imm_d;
    logic rf_we_d, branch_d, jal_d, jalr_d, alusrc_sel_d, dwe_d;
    logic [3:0] alu_control_d;
    logic [2:0] rf_src_sel_d, mem_mode_d;

    logic [4:0] rs1_addr_d, rs2_addr_d, rd_addr_d;
    assign rs1_addr_d  = instr_code[19:15];
    assign rs2_addr_d  = instr_code[24:20];
    assign rd_addr_d   = instr_code[11:7];

    assign id_rs1_addr = rs1_addr_d;
    assign id_rs2_addr = rs2_addr_d;

    register_file U_REG_FILE (
        .clk   (clk),
        .raddr1(rs1_addr_d),
        .raddr2(rs2_addr_d),
        .rf_we (wb_we),
        .waddr (wb_waddr),
        .wdata (wb_wdata),
        .rdata1(rs1_data),
        .rdata2(rs2_data)
    );

    control_unit U_CONTROL_UNIT (
        .instr_code (instr_code),
        .rf_we      (rf_we_d),
        .branch     (branch_d),
        .jal        (jal_d),
        .jalr       (jalr_d),
        .alusrc_sel (alusrc_sel_d),
        .alu_control(alu_control_d),
        .rf_src_sel (rf_src_sel_d),
        .mem_mode   (mem_mode_d),
        .dwe        (dwe_d)
    );

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_d)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst || flush) begin
            ex_pc          <= 32'd0;
            ex_pc_4        <= 32'd0;
            ex_rs1         <= 32'd0;
            ex_rs2         <= 32'd0;
            ex_imm         <= 32'd0;
            ex_rs1_addr    <= 5'd0;
            ex_rs2_addr    <= 5'd0;
            ex_rd_addr     <= 5'd0;
            ex_rf_we       <= 1'b0;
            ex_branch      <= 1'b0;
            ex_jal         <= 1'b0;
            ex_jalr        <= 1'b0;
            ex_alusrc_sel  <= 1'b0;
            ex_alu_control <= 4'd0;
            ex_rf_src_sel  <= 3'd0;
            ex_mem_mode    <= 3'd0;
            ex_dwe         <= 1'b0;
        end else begin
            ex_pc          <= pc;
            ex_pc_4        <= pc_4;
            ex_rs1         <= rs1_data;
            ex_rs2         <= rs2_data;
            ex_imm         <= imm_d;
            ex_rs1_addr    <= rs1_addr_d;
            ex_rs2_addr    <= rs2_addr_d;
            ex_rd_addr     <= rd_addr_d;
            ex_rf_we       <= rf_we_d;
            ex_branch      <= branch_d;
            ex_jal         <= jal_d;
            ex_jalr        <= jalr_d;
            ex_alusrc_sel  <= alusrc_sel_d;
            ex_alu_control <= alu_control_d;
            ex_rf_src_sel  <= rf_src_sel_d;
            ex_mem_mode    <= mem_mode_d;
            ex_dwe         <= dwe_d;
        end
    end

endmodule
