`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_monitor extends uvm_monitor;
    `uvm_component_utils(axi4_monitor)

    virtual axi4_lite_if vif;
    uvm_analysis_port #(axi4_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "virtual interface not set : vif")
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_write();
            monitor_read();
        join
    endtask

    task monitor_write();
        bit [31:0] captured_awaddr;
        bit [31:0] captured_wdata;
        axi4_transaction tr;

        forever begin
            // AW, W 채널을 순서에 상관없이 독립적으로 캡처
            fork
                begin : watch_aw
                    forever begin
                        @(posedge vif.clk);
                        if (vif.awvalid && vif.awready) begin
                            captured_awaddr = vif.awaddr;
                            break;
                        end
                    end
                end

                begin : watch_w
                    forever begin
                        @(posedge vif.clk);
                        if (vif.wvalid && vif.wready) begin
                            captured_wdata = vif.wdata;
                            break;
                        end
                    end
                end
            join

            // 여기 도달 했다는 건 AW, W 둘 다 순서 상관없이 캡처되었다는 뜻.
            tr = axi4_transaction::type_id::create("tr");
            tr.is_write = 1;
            tr.addr = captured_awaddr;
            tr.data = captured_wdata;

            // B 채널(응답) 대기
            while (!vif.bvalid) @(posedge vif.clk);
            tr.resp = vif.bresp;

            `uvm_info("MON", $sformatf(
                      "Observed WRITE addr=0x%0h, data=0x%0h, resp=%0d", tr.addr, tr.data, tr.resp),
                      UVM_LOW)
            ap.write(tr);
        end
    endtask

    task monitor_read();
        axi4_transaction tr;
        forever begin
            @(posedge vif.clk);
            if (vif.arvalid && vif.arready) begin
                tr = axi4_transaction::type_id::create("tr");
                tr.is_write = 0;
                tr.addr = vif.araddr;

                // R 채널(응답) 대기
                while (!vif.rvalid) @(posedge vif.clk);
                tr.data = vif.rdata;
                tr.resp = vif.rresp;

                `uvm_info("MON", $sformatf("Observed READ addr=0x%0h, data=0x%0h, resp=%0d",
                                           tr.addr, tr.data, tr.resp), UVM_LOW)
                ap.write(tr);
            end
        end
    endtask

endclass
