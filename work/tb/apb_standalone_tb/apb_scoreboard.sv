class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_transaction, apb_scoreboard) ap_imp;

    bit [31:0] mem_model[bit [31:0]];
    int pass_cnt;
    int fail_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(apb_transaction tr);
        if (tr.is_write) begin
            mem_model[tr.addr] = tr.data;
        end else begin
            if (mem_model.exists(tr.addr)) begin
                if (mem_model[tr.addr] === tr.data) begin
                    pass_cnt++;
                end else begin
                    fail_cnt++;
                    `uvm_error("SCB", $sformatf(
                               "READ MISMATCH addr=0x%08h expected=0x%08h actual=0x%08h",
                               tr.addr,
                               mem_model[tr.addr],
                               tr.data
                               ))
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("APB Scoreboard: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt),
                  UVM_LOW)
    endfunction
endclass
