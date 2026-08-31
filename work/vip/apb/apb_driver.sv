import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_driver extends uvm_driver #(apb_transaction);
    `uvm_component_utils(apb_driver)

    virtual apb_if vif;
    localparam int TIMEOUT_CYCLES = 1000;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "virtual interface not set: vif")
    endfunction

    task run_phase(uvm_phase phase);
        apb_transaction tr;

        vif.psel    <= 0;
        vif.penable <= 0;
        vif.pwrite  <= 0;
        vif.paddr   <= 0;
        vif.pwdata  <= 0;

        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(tr);
            drive_transfer(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(apb_transaction tr);
        int timeout_cnt;

        // ---- SETUP phase ----
        @(posedge vif.clk);
        vif.psel    <= 1'b1;
        vif.penable <= 1'b0;
        vif.pwrite  <= tr.is_write;
        vif.paddr   <= tr.addr;
        vif.pwdata  <= tr.is_write ? tr.data : 32'h0;

        // ---- ACCESS phase ----
        @(posedge vif.clk);
        vif.penable <= 1'b1;

        timeout_cnt = 0;
        while (!vif.pready) begin
            @(posedge vif.clk);
            if (++timeout_cnt > TIMEOUT_CYCLES) `uvm_fatal("DRV", "APB pready timeout")
        end

        if (!tr.is_write) tr.data = vif.prdata;
        tr.slverr = vif.pslverr;

        // ---- IDLE (다음 트랜잭션 SETUP 전) ----
        vif.psel    <= 1'b0;
        vif.penable <= 1'b0;
    endtask

endclass
