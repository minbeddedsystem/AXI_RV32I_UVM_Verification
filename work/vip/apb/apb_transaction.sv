import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_transaction extends uvm_sequence_item;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        is_write;
    bit             slverr;

    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(slverr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction
endclass
