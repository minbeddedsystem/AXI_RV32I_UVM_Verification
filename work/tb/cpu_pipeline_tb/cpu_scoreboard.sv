`timescale 1ns / 1ps

// =========================================================
// CPU Scoreboard
//   - golden model(싱글사이클)과 DUT(파이프라인)이 레지스터에
//     write하는 이벤트를 각각 큐에 쌓고, 순서대로 pop해서 비교.
//   - 사이클 타이밍은 서로 달라도(파이프라인은 5스테이지 지연,
//     stall로 더 늦어질 수 있음) "같은 프로그램이면 같은 순서로
//     같은 값을 쓴다"는 것만 보장되면 되므로 순서 비교로 충분.
//   - x0(waddr==0) write는 아키텍처상 무시되는 명령어이므로 큐에 안 넣음.
// =========================================================
module cpu_scoreboard (
    input logic        clk,
    input logic        rst,

    input logic         golden_we,
    input logic [ 4:0] golden_waddr,
    input logic [31:0] golden_wdata,

    input logic         dut_we,
    input logic [ 4:0] dut_waddr,
    input logic [31:0] dut_wdata
);

    typedef struct packed {
        logic [4:0]  waddr;
        logic [31:0] wdata;
    } wr_event_t;

    wr_event_t golden_q[$];
    wr_event_t dut_q[$];

    int pass_cnt;
    int fail_cnt;

    always_ff @(posedge clk) begin
        if (!rst) begin
            if (golden_we && (golden_waddr != 5'd0))
                golden_q.push_back('{golden_waddr, golden_wdata});

            if (dut_we && (dut_waddr != 5'd0))
                dut_q.push_back('{dut_waddr, dut_wdata});

            while (golden_q.size() > 0 && dut_q.size() > 0) begin
                automatic wr_event_t g = golden_q.pop_front();
                automatic wr_event_t d = dut_q.pop_front();

                if ((g.waddr === d.waddr) && (g.wdata === d.wdata)) begin
                    pass_cnt++;
                end else begin
                    fail_cnt++;
                    $display("[SCB] MISMATCH #%0d @ time %0t : golden x%0d=0x%08h, dut x%0d=0x%08h",
                              pass_cnt + fail_cnt, $time, g.waddr, g.wdata, d.waddr, d.wdata);
                end
            end
        end
    end

    final begin
        $display("=== CPU Scoreboard Result : PASS=%0d FAIL=%0d (golden_q left=%0d, dut_q left=%0d) ===",
                  pass_cnt, fail_cnt, golden_q.size(), dut_q.size());
    end

endmodule