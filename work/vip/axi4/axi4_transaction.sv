`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_transaction extends uvm_sequence_item;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        is_write;  // 1: write, 0: read

    bit      [ 1:0] resp;  // AXI response : 2bit

    `uvm_object_utils_begin(axi4_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4_transaction");
        super.new(name);
    endfunction

endclass
