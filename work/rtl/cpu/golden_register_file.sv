`timescale 1ns / 1ps

// =========================================================
// Golden Model 전용 register_file (싱글사이클용, bypass 없음)
//   - 파이프라인용 register_file.sv에는 write-through bypass가 있는데,
//     그건 ID(read)와 WB(write) 사이에 파이프라인 레지스터가 있어야
//     안전한 로직임. 싱글사이클(golden model)은 read/write가 같은
//     사이클에 조합적으로 연결돼 있어서 bypass를 넣으면
//     rdata -> alu -> wdata -> (bypass) -> rdata 로 되돌아오는
//     진짜 combinational loop가 생겨서 시뮬레이션이 멈춰버림(hang).
//   - 그래서 원본 그대로, bypass 없는 순수 배열 read/write 버전을 따로 둠.
// =========================================================
module register_file_golden (
    input  logic        clk,
    input  logic [ 4:0] raddr1,
    input  logic [ 4:0] raddr2,
    input  logic        rf_we,
    input  logic [ 4:0] waddr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
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

    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : register_file[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : register_file[raddr2];

endmodule