class apb_dut_test extends uvm_test;
    `uvm_component_utils(apb_dut_test)

    apb_agent      agt;
    apb_scoreboard scb;
    apb_coverage   cov;

    function new(string name = "apb_dut_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = apb_agent::type_id::create("agt", this);
        scb = apb_scoreboard::type_id::create("scb", this);
        cov = apb_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        apb_wr_rd_seq seq;
        phase.raise_objection(this);
        seq = apb_wr_rd_seq::type_id::create("seq");
        seq.start(agt.sqr);
        #100;
        phase.drop_objection(this);
    endtask
endclass


module apb_dut_tb;

    logic clk;
    logic rst_n;

    apb_if U_APB_IF (
        .clk  (clk),
        .rst_n(rst_n)
    );

    apb_reg_slave U_DUT (
        .clk    (clk),
        .rst_n  (rst_n),
        .paddr  (U_APB_IF.paddr),
        .psel   (U_APB_IF.psel),
        .penable(U_APB_IF.penable),
        .pwrite (U_APB_IF.pwrite),
        .pwdata (U_APB_IF.pwdata),
        .prdata (U_APB_IF.prdata),
        .pready (U_APB_IF.pready),
        .pslverr(U_APB_IF.pslverr)
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
        uvm_config_db#(virtual apb_if)::set(null, "*", "vif", U_APB_IF);
        run_test("apb_dut_test");
    end

endmodule
