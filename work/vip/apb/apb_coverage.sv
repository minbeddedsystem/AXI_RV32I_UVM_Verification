import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_coverage extends uvm_subscriber #(apb_transaction);
    `uvm_component_utils(apb_coverage)

    apb_transaction tr;

    covergroup cg;
        option.per_instance = 1;
        cp_rw: coverpoint tr.is_write {bins write = {1}; bins read = {0};}
        cp_addr: coverpoint tr.addr[3:2] {
            bins reg0 = {0}; bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3};
        }
        cp_data: coverpoint tr.data {
            bins zero = {32'h0}; bins all_one = {32'hFFFFFFFF}; bins others = default;
        }
        cx_addr_rw: cross cp_addr, cp_rw;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void write(apb_transaction t);
        tr = t;
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("APB Functional coverage = %.2f%%", cg.get_coverage()), UVM_LOW)
    endfunction
endclass
