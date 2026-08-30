`timescale 1ns / 1ps

// =========================================================
// RV32I 5-Stage Pipeline CPU Top
//   IF -> ID -> EX -> MEM -> WB
//   + forwarding_unit (data hazard)
//   + hazard_unit (load-use stall, branch flush)
//   instruction_mem / data_mem 포함 (SoC top)
// =========================================================
module rv32i_pipeline_top (
    input logic clk,
    input logic rst
);

    // ---------------- IF ----------------
    logic [31:0] if_instr_addr, if_instr_code;
    logic [31:0] id_pc, id_pc_4, id_instr_code;

    // ---------------- ID ----------------
    logic [ 4:0] id_rs1_addr_w, id_rs2_addr_w;
    logic [31:0] ex_pc, ex_pc_4, ex_rs1, ex_rs2, ex_imm;
    logic [ 4:0] ex_rs1_addr, ex_rs2_addr, ex_rd_addr;
    logic        ex_rf_we, ex_branch, ex_jal, ex_jalr, ex_alusrc_sel;
    logic [ 3:0] ex_alu_control;
    logic [ 2:0] ex_rf_src_sel, ex_mem_mode;
    logic        ex_dwe;

    // ---------------- EX ----------------
    logic        pc_sel;
    logic [31:0] target_addr;
    logic [31:0] mem_alu_result, mem_imm, mem_pc_imm, mem_pc_4, mem_store_data;
    logic [ 4:0] mem_rd_addr;
    logic        mem_rf_we;
    logic [ 2:0] mem_rf_src_sel, mem_mem_mode;
    logic        mem_dwe;

    // ---------------- MEM ----------------
    logic [31:0] daddr, dwdata, drdata;
    logic        dwe_out;
    logic [ 2:0] mem_mode_out;
    logic [31:0] wb_alu_result, wb_imm, wb_pc_imm, wb_pc_4, wb_drdata;
    logic [ 4:0] wb_rd_addr;
    logic        wb_rf_we;
    logic [ 2:0] wb_rf_src_sel;

    // ---------------- WB ----------------
    logic [31:0] wb_wdata;
    logic [ 4:0] wb_waddr;
    logic        wb_we;

    // ---------------- forwarding / hazard ----------------
    logic [1:0] forward_a, forward_b;
    logic       pc_write, if_id_write, if_flush, id_flush;


    // =====================================================
    // IF
    // =====================================================
    if_stage U_IF (
        .clk          (clk),
        .rst          (rst),
        .pc_write     (pc_write),
        .if_id_write  (if_id_write),
        .flush        (if_flush),
        .pc_sel       (pc_sel),
        .target_addr  (target_addr),
        .instr_code_in(if_instr_code),
        .instr_addr   (if_instr_addr),
        .id_pc        (id_pc),
        .id_pc_4      (id_pc_4),
        .id_instr_code(id_instr_code)
    );

    instruction_mem U_IMEM (
        .instr_addr(if_instr_addr),
        .instr_code(if_instr_code)
    );


    // =====================================================
    // ID
    // =====================================================
    id_stage U_ID (
        .clk          (clk),
        .rst          (rst),
        .flush        (id_flush),
        .pc           (id_pc),
        .pc_4         (id_pc_4),
        .instr_code   (id_instr_code),
        .wb_we        (wb_we),
        .wb_waddr     (wb_waddr),
        .wb_wdata     (wb_wdata),
        .id_rs1_addr  (id_rs1_addr_w),
        .id_rs2_addr  (id_rs2_addr_w),
        .ex_pc        (ex_pc),
        .ex_pc_4      (ex_pc_4),
        .ex_rs1       (ex_rs1),
        .ex_rs2       (ex_rs2),
        .ex_imm       (ex_imm),
        .ex_rs1_addr  (ex_rs1_addr),
        .ex_rs2_addr  (ex_rs2_addr),
        .ex_rd_addr   (ex_rd_addr),
        .ex_rf_we     (ex_rf_we),
        .ex_branch    (ex_branch),
        .ex_jal       (ex_jal),
        .ex_jalr      (ex_jalr),
        .ex_alusrc_sel(ex_alusrc_sel),
        .ex_alu_control(ex_alu_control),
        .ex_rf_src_sel(ex_rf_src_sel),
        .ex_mem_mode  (ex_mem_mode),
        .ex_dwe       (ex_dwe)
    );


    // =====================================================
    // EX
    // =====================================================
    ex_stage U_EX (
        .clk           (clk),
        .rst           (rst),
        .pc            (ex_pc),
        .pc_4          (ex_pc_4),
        .rs1           (ex_rs1),
        .rs2           (ex_rs2),
        .imm           (ex_imm),
        .rs1_addr      (ex_rs1_addr),
        .rs2_addr      (ex_rs2_addr),
        .rd_addr       (ex_rd_addr),
        .rf_we         (ex_rf_we),
        .branch        (ex_branch),
        .jal           (ex_jal),
        .jalr          (ex_jalr),
        .alusrc_sel    (ex_alusrc_sel),
        .alu_control   (ex_alu_control),
        .rf_src_sel    (ex_rf_src_sel),
        .mem_mode      (ex_mem_mode),
        .dwe           (ex_dwe),
        .forward_a     (forward_a),
        .forward_b     (forward_b),
        .wb_fwd_data   (wb_wdata),
        .pc_sel        (pc_sel),
        .target_addr   (target_addr),
        .mem_alu_result(mem_alu_result),
        .mem_imm       (mem_imm),
        .mem_pc_imm    (mem_pc_imm),
        .mem_pc_4      (mem_pc_4),
        .mem_store_data(mem_store_data),
        .mem_rd_addr   (mem_rd_addr),
        .mem_rf_we     (mem_rf_we),
        .mem_rf_src_sel(mem_rf_src_sel),
        .mem_mem_mode  (mem_mem_mode),
        .mem_dwe       (mem_dwe)
    );


    // =====================================================
    // MEM
    // =====================================================
    mem_stage U_MEM (
        .clk          (clk),
        .rst          (rst),
        .alu_result   (mem_alu_result),
        .imm          (mem_imm),
        .pc_imm       (mem_pc_imm),
        .pc_4         (mem_pc_4),
        .store_data   (mem_store_data),
        .rd_addr      (mem_rd_addr),
        .rf_we        (mem_rf_we),
        .rf_src_sel   (mem_rf_src_sel),
        .mem_mode     (mem_mem_mode),
        .dwe          (mem_dwe),
        .daddr        (daddr),
        .dwdata       (dwdata),
        .dwe_out      (dwe_out),
        .mem_mode_out (mem_mode_out),
        .drdata       (drdata),
        .wb_alu_result(wb_alu_result),
        .wb_imm       (wb_imm),
        .wb_pc_imm    (wb_pc_imm),
        .wb_pc_4      (wb_pc_4),
        .wb_drdata    (wb_drdata),
        .wb_rd_addr   (wb_rd_addr),
        .wb_rf_we     (wb_rf_we),
        .wb_rf_src_sel(wb_rf_src_sel)
    );

    data_mem U_DMEM (
        .clk     (clk),
        .dwe     (dwe_out),
        .mem_mode(mem_mode_out),
        .daddr   (daddr),
        .dwdata  (dwdata),
        .drdata  (drdata)
    );


    // =====================================================
    // WB
    // =====================================================
    wb_stage U_WB (
        .alu_result(wb_alu_result),
        .drdata    (wb_drdata),
        .imm       (wb_imm),
        .pc_imm    (wb_pc_imm),
        .pc_4      (wb_pc_4),
        .rf_src_sel(wb_rf_src_sel),
        .rd_addr   (wb_rd_addr),
        .rf_we     (wb_rf_we),
        .wb_wdata  (wb_wdata),
        .wb_waddr  (wb_waddr),
        .wb_we     (wb_we)
    );


    // =====================================================
    // Forwarding / Hazard
    // =====================================================
    forwarding_unit U_FWD (
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .mem_rd_addr(mem_rd_addr),
        .mem_rf_we  (mem_rf_we),
        .wb_rd_addr (wb_rd_addr),
        .wb_rf_we   (wb_rf_we),
        .forward_a  (forward_a),
        .forward_b  (forward_b)
    );

    hazard_unit U_HAZ (
        .id_rs1_addr  (id_rs1_addr_w),
        .id_rs2_addr  (id_rs2_addr_w),
        .ex_rd_addr   (ex_rd_addr),
        .ex_rf_src_sel(ex_rf_src_sel),
        .branch_taken (pc_sel),
        .pc_write     (pc_write),
        .if_id_write  (if_id_write),
        .if_flush     (if_flush),
        .id_flush     (id_flush)
    );

endmodule