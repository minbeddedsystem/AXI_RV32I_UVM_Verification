import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_apb_bridge_test extends uvm_test;
    `uvm_component_utils(axi_apb_bridge_test)

    axi4_agent      agt;
    axi4_scoreboard scb;
    axi4_coverage   cov;

    function new(string name = "axi_apb_bridge_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = axi4_agent::type_id::create("agt", this);
        scb = axi4_scoreboard::type_id::create("scb", this);
        cov = axi4_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_wr_rd_seq seq;
        phase.raise_objection(this);
        seq = axi4_wr_rd_seq::type_id::create("seq");
        seq.start(agt.sqr);
        #100;
        phase.drop_objection(this);
    endtask
endclass


module axi_apb_bridge_tb;

    logic clk;
    logic rst_n;

    // ---------------- AXI4-Lite (VIP <-> bridge) ----------------
    axi4_lite_if U_AXI_IF (
        .clk  (clk),
        .rst_n(rst_n)
    );

    // ---------------- APB (bridge <-> apb_reg_slave, 순수 와이어) ----------------
    logic [31:0] apb_paddr;
    logic        apb_psel;
    logic        apb_penable;
    logic        apb_pwrite;
    logic [31:0] apb_pwdata;
    logic [31:0] apb_prdata;
    logic        apb_pready;
    logic        apb_pslverr;

    axi_apb_bridge U_BRIDGE (
        .clk  (clk),
        .rst_n(rst_n),

        .awaddr (U_AXI_IF.awaddr),
        .awvalid(U_AXI_IF.awvalid),
        .awready(U_AXI_IF.awready),

        .wdata (U_AXI_IF.wdata),
        .wstrb (U_AXI_IF.wstrb),
        .wvalid(U_AXI_IF.wvalid),
        .wready(U_AXI_IF.wready),

        .bresp (U_AXI_IF.bresp),
        .bvalid(U_AXI_IF.bvalid),
        .bready(U_AXI_IF.bready),

        .araddr (U_AXI_IF.araddr),
        .arvalid(U_AXI_IF.arvalid),
        .arready(U_AXI_IF.arready),

        .rdata (U_AXI_IF.rdata),
        .rresp (U_AXI_IF.rresp),
        .rvalid(U_AXI_IF.rvalid),
        .rready(U_AXI_IF.rready),

        .paddr  (apb_paddr),
        .psel   (apb_psel),
        .penable(apb_penable),
        .pwrite (apb_pwrite),
        .pwdata (apb_pwdata),
        .prdata (apb_prdata),
        .pready (apb_pready),
        .pslverr(apb_pslverr)
    );

    apb_reg_slave U_APB_DUT (
        .clk    (clk),
        .rst_n  (rst_n),
        .paddr  (apb_paddr),
        .psel   (apb_psel),
        .penable(apb_penable),
        .pwrite (apb_pwrite),
        .pwdata (apb_pwdata),
        .prdata (apb_prdata),
        .pready (apb_pready),
        .pslverr(apb_pslverr)
    );

    // clock: 10ns 주기
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // reset: 20ns 동안 active-low
    initial begin
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual axi4_lite_if)::set(null, "*", "vif", U_AXI_IF);
        run_test("axi_apb_bridge_test");
    end

endmodule
