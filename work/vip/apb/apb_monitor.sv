import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    uvm_analysis_port #(apb_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "virtual interface not set: vif")
    endfunction

    task run_phase(uvm_phase phase);
        apb_transaction tr;

        forever begin
            @(posedge vif.clk);
            if (vif.psel && vif.penable && vif.pready) begin
                tr          = apb_transaction::type_id::create("tr");
                tr.addr     = vif.paddr;
                tr.is_write = vif.pwrite;
                tr.data     = vif.pwrite ? vif.pwdata : vif.prdata;
                tr.slverr   = vif.pslverr;
                ap.write(tr);
            end
        end
    endtask

endclass
