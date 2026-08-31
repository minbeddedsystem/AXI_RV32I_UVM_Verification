class apb_wr_rd_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_wr_rd_seq)

    function new(string name = "apb_wr_rd_seq");
        super.new(name);
    endfunction

    task body();
        apb_transaction wr_tr, rd_tr;

        // 1) 랜덤 write-read 5쌍
        repeat (5) begin
            wr_tr = apb_transaction::type_id::create("wr_tr");
            start_item(wr_tr);
            assert (wr_tr.randomize() with {
                is_write == 1;
                addr[31:4] == 0;  // 레지스터 4개(addr 0,4,8,12)만 사용
            });
            finish_item(wr_tr);

            rd_tr = apb_transaction::type_id::create("rd_tr");
            start_item(rd_tr);
            assert (rd_tr.randomize() with {
                is_write == 0;
                addr == wr_tr.addr;
            });
            finish_item(rd_tr);
        end

        // 2) directed: 4개 레지스터 x 데이터 2종
        for (int reg_idx = 0; reg_idx < 4; reg_idx++) begin
            bit [31:0] directed_data[2] = '{32'h0000_0000, 32'hFFFF_FFFF};

            foreach (directed_data[i]) begin
                apb_transaction wr_d, rd_d;

                wr_d = apb_transaction::type_id::create("wr_d");
                start_item(wr_d);
                assert (wr_d.randomize() with {
                    is_write == 1;
                    addr == (reg_idx << 2);
                    data == directed_data[i];
                });
                finish_item(wr_d);

                rd_d = apb_transaction::type_id::create("rd_d");
                start_item(rd_d);
                assert (rd_d.randomize() with {
                    is_write == 0;
                    addr == (reg_idx << 2);
                });
                finish_item(rd_d);
            end
        end
    endtask
endclass
