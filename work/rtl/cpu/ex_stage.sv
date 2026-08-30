`timescale 1ns / 1ps

// =========================================================
// EX Stage
//   - forwarding mux (forward_a/forward_b는 forwarding_unit이 결정, 아직 미구현이라 포트만 열어둠)
//   - alu 연산, branch 판정
//   - branch/jal/jalr target 주소 계산 -> IF 스테이지 redirect용
//   - EX/MEM 파이프라인 레지스터
// =========================================================
module ex_stage (
    input  logic        clk,
    input  logic        rst,

    // ID/EX 레지스터에서 넘어온 값
    input  logic [31:0] pc,
    input  logic [31:0] pc_4,
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    input  logic [31:0] imm,
    input  logic [ 4:0] rs1_addr,
    input  logic [ 4:0] rs2_addr,
    input  logic [ 4:0] rd_addr,
    input  logic        rf_we,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic        alusrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic [ 2:0] rf_src_sel,
    input  logic [ 2:0] mem_mode,
    input  logic        dwe,

    // forwarding (forwarding_unit이 결정)
    // 2'b00: forward 안 함 (rs1/rs2 그대로), 2'b10: EX/MEM 결과 forward, 2'b01: MEM/WB 결과 forward
    input  logic [ 1:0] forward_a,
    input  logic [ 1:0] forward_b,
    input  logic [31:0] wb_fwd_data,   // WB 단계 최종 write-back 값

    // branch/jump redirect -> IF 스테이지로
    output logic        pc_sel,
    output logic [31:0] target_addr,

    // EX/MEM pipeline register outputs (MEM 스테이지로)
    output logic [31:0] mem_alu_result,
    output logic [31:0] mem_imm,        // LUI write-back 값 (immediate 원본)
    output logic [31:0] mem_pc_imm,     // AUIPC write-back 값 (pc + imm)
    output logic [31:0] mem_pc_4,       // JAL/JALR write-back 값 (pc + 4)
    output logic [31:0] mem_store_data, // S-type store data (forward 적용된 rs2)
    output logic [ 4:0] mem_rd_addr,
    output logic        mem_rf_we,
    output logic [ 2:0] mem_rf_src_sel,
    output logic [ 2:0] mem_mem_mode,
    output logic        mem_dwe
);

    // ---------------- EX/MEM forwarding 값 계산 ----------------
    // mem_alu_result만 그냥 넘기면 안 됨: LUI/AUIPC/JAL/JALR은 최종
    // write-back 값이 ALU 결과가 아니라 imm/pc_imm/pc_4이기 때문에,
    // WB 단계의 mux(wb_stage)와 동일한 선택을 EX/MEM 단계에서도 해줘야
    // "LUI 다음 바로 그 레지스터를 쓰는" 같은 1칸 forwarding이 맞게 됨.
    // (mem_rf_src_sel==001, 즉 load는 이 시점에 drdata가 아직 없으므로
    //  여기서 절대 forwarding 대상이 되면 안 되는데, load-use는 hazard_unit이
    //  1사이클 stall시켜서 항상 MEM/WB 단계 forwarding으로 넘어가게 되어 있음.)
    logic [31:0] mem_fwd_value;

    always_comb begin
        case (mem_rf_src_sel)
            3'b000:  mem_fwd_value = mem_alu_result;  // R/I-type ALU 결과
            3'b010:  mem_fwd_value = mem_imm;         // LUI
            3'b011:  mem_fwd_value = mem_pc_imm;      // AUIPC
            3'b100:  mem_fwd_value = mem_pc_4;        // JAL / JALR
            default: mem_fwd_value = mem_alu_result;
        endcase
    end

    // ---------------- forwarding mux ----------------
    logic [31:0] rs1_fwd, rs2_fwd;

    always_comb begin
        case (forward_a)
            2'b10:   rs1_fwd = mem_fwd_value;  // EX/MEM 결과
            2'b01:   rs1_fwd = wb_fwd_data;    // MEM/WB 결과
            default: rs1_fwd = rs1;
        endcase
    end

    always_comb begin
        case (forward_b)
            2'b10:   rs2_fwd = mem_fwd_value;
            2'b01:   rs2_fwd = wb_fwd_data;
            default: rs2_fwd = rs2;
        endcase
    end

    // ---------------- ALU ----------------
    logic [31:0] alu_rs2_mux, alu_result;
    logic        b_taken;

    assign alu_rs2_mux = alusrc_sel ? imm : rs2_fwd;

    alu U_ALU (
        .alu_control(alu_control),
        .rs1        (rs1_fwd),
        .rs2        (alu_rs2_mux),
        .alu_result (alu_result),
        .b_taken    (b_taken)
    );

    // ---------------- branch/jump target ----------------
    logic [31:0] jalr_base, pc_imm;

    assign jalr_base  = jalr ? rs1_fwd : pc;
    assign pc_imm      = imm + jalr_base;

    assign pc_sel      = jal | jalr | (branch & b_taken);
    assign target_addr = pc_imm;

    // ---------------- EX/MEM pipeline register ----------------
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            mem_alu_result <= 32'd0;
            mem_imm        <= 32'd0;
            mem_pc_imm     <= 32'd0;
            mem_pc_4       <= 32'd0;
            mem_store_data <= 32'd0;
            mem_rd_addr    <= 5'd0;
            mem_rf_we      <= 1'b0;
            mem_rf_src_sel <= 3'd0;
            mem_mem_mode   <= 3'd0;
            mem_dwe        <= 1'b0;
        end else begin
            mem_alu_result <= alu_result;
            mem_imm        <= imm;
            mem_pc_imm     <= pc_imm;
            mem_pc_4       <= pc_4;
            mem_store_data <= rs2_fwd;
            mem_rd_addr    <= rd_addr;
            mem_rf_we      <= rf_we;
            mem_rf_src_sel <= rf_src_sel;
            mem_mem_mode   <= mem_mode;
            mem_dwe        <= dwe;
        end
    end

endmodule