`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_driver extends uvm_driver #(axi4_transaction);
    `uvm_component_utils(axi4_driver)

    virtual axi4_lite_if vif;

    localparam int TIMEOUT_CYCLES = 1000;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "virtual interface not set: vif")
    endfunction

    task run_phase(uvm_phase phase);
        axi4_transaction tr;

        // 초기값
        vif.awvalid <= 0;
        vif.wvalid  <= 0;
        vif.bready  <= 1;
        vif.arvalid <= 0;
        vif.rready  <= 1;

        // Reset 해제까지 대기
        `uvm_info("DRV", "Waiting for reset deassertion...", UVM_LOW)
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);
        `uvm_info("DRV", "Reset deasserted, driver starting", UVM_LOW)

        forever begin
            seq_item_port.get_next_item(tr);
            if (tr.is_write) drive_write(tr);
            else drive_read(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_write(axi4_transaction tr);
        int aw_timeout, w_timeout, b_timeout;

        @(posedge vif.clk);
        vif.awaddr  <= tr.addr;
        vif.awvalid <= 1;
        vif.wdata   <= tr.data;
        vif.wstrb   <= 4'hF;
        vif.wvalid  <= 1;

        // AW, W 채널을 독립적으로(병렬로) 처리
        fork
            begin : aw_ch
                aw_timeout = 0;
                while (!(vif.awvalid && vif.awready)) begin
                    @(posedge vif.clk);
                    if (++aw_timeout > TIMEOUT_CYCLES)
                        `uvm_fatal("DRV", "AW channel handshake timeout")
                end
                vif.awvalid <= 0;
            end
            begin : w_ch
                w_timeout = 0;
                while (!(vif.wvalid && vif.wready)) begin
                    @(posedge vif.clk);
                    if (++w_timeout > TIMEOUT_CYCLES)
                        `uvm_fatal("DRV", "W channel handshake timeout")
                end
                vif.wvalid <= 0;
            end
        join

        // 응답(B 채널) 대기
        b_timeout = 0;
        while (!vif.bvalid) begin
            @(posedge vif.clk);
            if (++b_timeout > TIMEOUT_CYCLES) `uvm_fatal("DRV", "B channel response timeout")
        end
        tr.resp = vif.bresp;

        `uvm_info("DRV", $sformatf("WRITE addr=0x%0h data=0x%0h resp=%0d", tr.addr, tr.data,
                                   tr.resp), UVM_LOW)
    endtask

    task drive_read(axi4_transaction tr);
        int ar_timeout, r_timeout;

        @(posedge vif.clk);
        vif.araddr  <= tr.addr;
        vif.arvalid <= 1;

        ar_timeout = 0;
        while (!(vif.arvalid && vif.arready)) begin
            @(posedge vif.clk);
            if (++ar_timeout > TIMEOUT_CYCLES) `uvm_fatal("DRV", "AR channel handshake timeout")
        end
        vif.arvalid <= 0;

        r_timeout = 0;
        while (!vif.rvalid) begin
            @(posedge vif.clk);
            if (++r_timeout > TIMEOUT_CYCLES) `uvm_fatal("DRV", "R channel response timeout")
        end
        tr.data = vif.rdata;
        tr.resp = vif.rresp;

        `uvm_info("DRV", $sformatf("READ addr=0x%0h data=0x%0h resp=%0d", tr.addr, tr.data,
                                   tr.resp), UVM_LOW)
    endtask

endclass
