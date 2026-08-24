`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi4_scoreboard)

    uvm_analysis_imp #(axi4_transaction, axi4_scoreboard) ap_imp;

    bit [31:0] mem_model[bit [31:0]];  // 주소 -> 마지막에 쓴 값

    int pass_cnt, fail_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(axi4_transaction tr);
        if (tr.is_write) begin
            mem_model[tr.addr] = tr.data;
            `uvm_info("SCB", $sformatf("Recorded WRITE addr=0x%0h data=0x%0h", tr.addr, tr.data),
                      UVM_LOW)
        end else begin
            if (mem_model.exists(tr.addr)) begin
                if (mem_model[tr.addr] === tr.data) begin
                    pass_cnt++;
                    `uvm_info("SCB", $sformatf("PASS: addr=0x%0h data=0x%0h matches expected",
                                               tr.addr, tr.data), UVM_LOW)
                end else begin
                    fail_cnt++;
                    `uvm_error("SCB", $sformatf(
                               "MISMATCH: addr=0x%0h expected=0x%0h actual=0x%0h",
                               tr.addr,
                               mem_model[tr.addr],
                               tr.data
                               ))
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("Scoreboard Summary: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt),
                  UVM_LOW)
    endfunction

endclass
