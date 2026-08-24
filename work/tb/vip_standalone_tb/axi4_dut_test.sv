`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_dut_test extends uvm_test;
    `uvm_component_utils(axi4_dut_test)

    axi4_agent      agt;
    axi4_scoreboard scb;
    axi4_coverage   cov;

    function new(string name = "axi4_dut_test", uvm_component parent = null);
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
        phase.drop_objection(this);
    endtask

endclass

module axi4_dut_tb;

    logic clk;
    logic rst_n;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        #20 rst_n = 1;
    end

    axi4_lite_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) intf (
        .clk  (clk),
        .rst_n(rst_n)
    );

    axi_lite_reg_slave dut (
        .clk(clk),
        .rst_n(rst_n),
        .awaddr(intf.awaddr),
        .awvalid(intf.awvalid),
        .awready(intf.awready),
        .wdata(intf.wdata),
        .wstrb(intf.wstrb),
        .wvalid(intf.wvalid),
        .wready(intf.wready),
        .bresp(intf.bresp),
        .bvalid(intf.bvalid),
        .bready(intf.bready),
        .araddr(intf.araddr),
        .arvalid(intf.arvalid),
        .arready(intf.arready),
        .rdata(intf.rdata),
        .rresp(intf.rresp),
        .rvalid(intf.rvalid),
        .rready(intf.rready)
    );

    initial begin
        uvm_config_db#(virtual axi4_lite_if)::set(null, "*", "vif", intf);
        run_test("axi4_dut_test");
    end

endmodule
