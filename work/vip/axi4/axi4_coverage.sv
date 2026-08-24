`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_coverage extends uvm_subscriber #(axi4_transaction);
    `uvm_component_utils(axi4_coverage)

    axi4_transaction tr;

    covergroup cg;
        option.per_instance = 1;

        cp_rw: coverpoint tr.is_write {bins write = {1}; bins read = {0};}

        cp_addr: coverpoint tr.addr[3:2] {
            bins reg0 = {0}; bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3};
        }

        cp_data: coverpoint tr.data {
            bins zero = {32'h0000_0000}; bins all_one = {32'hFFFF_FFFF}; bins others = default;
        }

        cx_addr_rw: cross cp_addr, cp_rw;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void write(axi4_transaction t);
        tr = t;
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Functional coverage = %.2f%%", cg.get_coverage()), UVM_LOW)
    endfunction

endclass
