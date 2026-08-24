`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_sequence extends uvm_sequence #(axi4_transaction);
    `uvm_object_utils(axi4_sequence)

    function new(string name = "axi4_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_transaction tr;
        repeat (5) begin
            tr = axi4_transaction::type_id::create("tr");
            start_item(tr);
            assert (tr.randomize());
            `uvm_info(
                "SEQ", $sformatf(
                "Generated: addr=-0x%0h, data=0x%0h, is_write=%0d", tr.addr, tr.data, tr.is_write),
                UVM_LOW)
            finish_item(tr);
        end
    endtask
endclass
