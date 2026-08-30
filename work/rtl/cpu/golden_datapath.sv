`timescale 1ns / 1ps
`include "define.vh"

// =========================================================
// Golden Model 전용 datapath (싱글사이클)
//   - alu, imm_extend, mux_2x1, register_file, control_unit은
//     rtl/cpu/ 안에 있는 파이프라인용 파일을 그대로 재사용
//     (원래 rv32i_datapath.sv 안에 있던 중복 모듈은 여기서 뺌)
//   - program_counter, mux_wb, datapath만 여기 남김
// =========================================================
module datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic        alusrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic [ 2:0] rf_src_sel,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata,

    // scoreboard 감시용 (레지스터 파일 write 이벤트를 밖으로 노출)
    output logic         wb_we_mon,
    output logic [ 4:0] wb_waddr_mon,
    output logic [31:0] wb_wdata_mon
);

    logic [31:0] rs1, rs2, alu_result, wb_out, pc_imm, pc_4;
    logic [31:0] imm_extend, alu_rs2_mux;
    logic b_taken;

    assign daddr  = alu_result;
    assign dwdata = rs2;

    assign wb_we_mon    = rf_we;
    assign wb_waddr_mon = instr_code[11:7];
    assign wb_wdata_mon = wb_out;

    mux_wb U_WB_MUX (
        .in0   (alu_result),
        .in1   (drdata),
        .in2   (imm_extend),
        .in3   (pc_imm),
        .in4   (pc_4),
        .sel   (rf_src_sel),
        .wb_out(wb_out)
    );

    register_file_golden U_REG_FILE (
        .clk   (clk),
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .rf_we (rf_we),
        .waddr (instr_code[11:7]),
        .wdata (wb_out),
        .rdata1(rs1),
        .rdata2(rs2)
    );

    alu U_ALU (
        .alu_control(alu_control),
        .rs1        (rs1),
        .rs2        (alu_rs2_mux),
        .alu_result (alu_result),
        .b_taken    (b_taken)
    );

    mux_2x1 U_ALU_RS2_MUX (
        .in0    (rs2),
        .in1    (imm_extend),
        .sel    (alusrc_sel),
        .out_mux(alu_rs2_mux)
    );

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

    program_counter U_PC (
        .clk(clk),
        .rst(rst),
        .b_taken(b_taken),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .rs1(rs1),
        .pc_in(instr_addr),
        .imm_extend(imm_extend),
        .pc_out(instr_addr),
        .pc_imm(pc_imm),
        .pc_4(pc_4)
    );

endmodule


// =================================
// program counter
// =================================
module program_counter (
    input         clk,
    input         rst,
    input         b_taken,
    input         branch,
    input         jal,
    input         jalr,
    input  [31:0] rs1,
    input  [31:0] pc_in,
    input  [31:0] imm_extend,
    output [31:0] pc_out,
    output [31:0] pc_imm,
    output [31:0] pc_4

);
    logic [31:0] pc_reg, pc_next, pc_jalr;
    assign pc_out = pc_reg;
    assign pc_imm = imm_extend + pc_jalr;
    assign pc_4   = pc_in + 32'd4;

    mux_2x1 U_PC_JALR_MUX (
        .in0    (pc_in),
        .in1    (rs1),
        .sel    (jalr),
        .out_mux(pc_jalr)
    );

    mux_2x1 U_PC_SRC_MUX (
        .in0    (pc_4),
        .in1    (pc_imm),
        .sel    (jalr | jal | (branch && b_taken)),
        .out_mux(pc_next)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 0;
        end else begin
            pc_reg <= pc_next;
        end
    end

endmodule


module mux_wb (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic [31:0] in2,
    input  logic [31:0] in3,
    input  logic [31:0] in4,
    input  logic [ 2:0] sel,
    output logic [31:0] wb_out
);

    always_comb begin
        wb_out = 32'd0;
        case (sel)
            3'b000: wb_out = in0;  // load alu
            3'b001: wb_out = in1;  // load data memory
            3'b010: wb_out = in2;  // load LUI : Load Upper Imm
            3'b011: wb_out = in3;  // load Add Upper Imm to PC
            3'b100: wb_out = in4;  // load JAL / JARL : PC+4
        endcase
    end

endmodule