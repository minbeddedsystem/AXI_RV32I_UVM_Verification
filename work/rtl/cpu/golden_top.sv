`timescale 1ns / 1ps

// =========================================================
// Golden Model Top (싱글사이클 RV32I CPU + 명령어/데이터 메모리)
//   - control_unit, alu, imm_extend, mux_2x1, register_file은
//     rtl/cpu/ 파이프라인용 파일 재사용
//   - datapath, program_counter, mux_wb는 golden_datapath.sv 것 사용
//   - instruction_mem, data_mem도 rtl/cpu/ 파일 재사용 (DUT와는 별도 인스턴스)
// =========================================================
module rv32i_cpu_golden (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [ 2:0] mem_mode,
    output logic        dwe,
    output logic [31:0] daddr,
    output logic [31:0] dwdata,

    // scoreboard 감시용
    output logic        wb_we_mon,
    output logic [ 4:0] wb_waddr_mon,
    output logic [31:0] wb_wdata_mon
);

    logic rf_we, branch, alusrc_sel;
    logic jal, jalr;
    logic [3:0] alu_control;
    logic [2:0] rf_src_sel;

    control_unit U_CONTROL_UNIT (.*);
    datapath U_DATA_PATH (.*);

endmodule


module golden_top (
    input  logic clk,
    input  logic rst,

    output logic        wb_we_mon,
    output logic [ 4:0] wb_waddr_mon,
    output logic [31:0] wb_wdata_mon
);

    logic [31:0] instr_code, instr_addr, daddr, dwdata, drdata;
    logic [2:0] mem_mode;
    logic       dwe;

    instruction_mem U_INSTR_ROM (.*);
    rv32i_cpu_golden U_CPU (.*);
    data_mem U_DATA_RAM (.*);

endmodule