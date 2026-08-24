`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_agent extends uvm_agent;
    `uvm_component_utils(axi4_agent)

    axi4_sequencer sqr;
    axi4_driver drv;
    axi4_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = axi4_monitor::type_id::create("mon", this);

        // active agent일 때만 sequencer/driver 생성
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = axi4_sequencer::type_id::create("sqr", this);
            drv = axi4_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass
