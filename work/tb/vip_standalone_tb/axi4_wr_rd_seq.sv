`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_wr_rd_seq extends uvm_sequence #(axi4_transaction);
    `uvm_object_utils(axi4_wr_rd_seq)

    function new(string name = "axi4_wr_rd_seq");
        super.new(name);
    endfunction

    task body();
        axi4_transaction wr_tr, rd_tr;
        bit [31:0] addr;
        bit [31:0] data;

        // ---- 1) 기존 랜덤 write-read 5쌍 ----
        repeat (5) begin
            wr_tr = axi4_transaction::type_id::create("wr_tr");
            start_item(wr_tr);
            assert (wr_tr.randomize() with {is_write == 1;});
            addr = wr_tr.addr;
            data = wr_tr.data;
            finish_item(wr_tr);

            rd_tr = axi4_transaction::type_id::create("rd_tr");
            start_item(rd_tr);
            rd_tr.is_write = 0;
            rd_tr.addr     = addr;
            finish_item(rd_tr);
        end

        // ---- 2) directed: 4개 레지스터 전부 write+read, 데이터는 0/all_one ----
        for (int reg_idx = 0; reg_idx < 4; reg_idx++) begin
            bit [31:0] directed_data[2] = '{32'h0000_0000, 32'hFFFF_FFFF};

            foreach (directed_data[i]) begin
                wr_tr = axi4_transaction::type_id::create("wr_tr");
                start_item(wr_tr);
                wr_tr.is_write = 1;
                wr_tr.addr     = reg_idx << 2;  // addr[3:2] = reg_idx
                wr_tr.data     = directed_data[i];
                `uvm_info("SEQ", $sformatf(
                          "Directed WRITE reg=%0d data=0x%0h", reg_idx, directed_data[i]), UVM_LOW)
                finish_item(wr_tr);

                rd_tr = axi4_transaction::type_id::create("rd_tr");
                start_item(rd_tr);
                rd_tr.is_write = 0;
                rd_tr.addr     = reg_idx << 2;
                `uvm_info("SEQ", $sformatf("Directed READ  reg=%0d", reg_idx), UVM_LOW)
                finish_item(rd_tr);
            end
        end
    endtask

endclass
