`timescale 1ns / 1ps

// =========================================================
// rv32i_pipeline_top용 testbench
//   - clock/reset 생성
//   - golden model(싱글사이클, golden_top) 같이 인스턴스화
//   - cpu_scoreboard로 두 CPU의 레지스터 write 이벤트를 순서대로 비교
// =========================================================
module rv32i_pipeline_tb;

    logic clk;
    logic rst;

    // ---------------- DUT (파이프라인) ----------------
    rv32i_pipeline_top U_DUT (
        .clk(clk),
        .rst(rst)
    );

    // ---------------- Golden model (싱글사이클) ----------------
    logic        golden_we;
    logic [ 4:0] golden_waddr;
    logic [31:0] golden_wdata;

    golden_top U_GOLDEN (
        .clk         (clk),
        .rst         (rst),
        .wb_we_mon   (golden_we),
        .wb_waddr_mon(golden_waddr),
        .wb_wdata_mon(golden_wdata)
    );

    // ---------------- Scoreboard ----------------
    cpu_scoreboard U_SCB (
        .clk         (clk),
        .rst         (rst),
        .golden_we   (golden_we),
        .golden_waddr(golden_waddr),
        .golden_wdata(golden_wdata),
        .dut_we      (U_DUT.wb_we),
        .dut_waddr   (U_DUT.wb_waddr),
        .dut_wdata   (U_DUT.wb_wdata)
    );

    // FSDB 덤프 (testbench에서 직접, +mda로 memory/array까지 덤프)
    // 먼저 정답 여부(scoreboard PASS/FAIL)만 빨리 확인하기 위해
    // 컴파일 매크로(DUMP_WAVES)로 껐다 켰다 할 수 있게 함.
    // 파형이 필요할 때만 make compile ... "+define+DUMP_WAVES ..." 로 켜서 컴파일.
`ifdef DUMP_WAVES
    initial begin
        $fsdbDumpfile("rv32i_pipeline_tb.fsdb");
        $fsdbDumpvars(0, rv32i_pipeline_tb, "+mda");
    end
`endif

    // clock: 10ns 주기 (5ns high, 5ns low)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // reset: 20ns 동안 유지
    initial begin
        rst = 1'b1;
        #20;
        rst = 1'b0;
    end

    // 충분히 돌려보고 종료 (golden model이 DUT보다 빨리 끝나므로 넉넉하게)
    initial begin
        #20000;
        $display("=== SIMULATION DONE (timeout) ===");
        $finish;
    end

endmodule