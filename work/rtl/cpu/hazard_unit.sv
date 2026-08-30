`timescale 1ns / 1ps

module hazard_unit (
    input logic [4:0] id_rs1_addr,
    input logic [4:0] id_rs2_addr,
    input logic [4:0] ex_rd_addr,
    input logic [2:0] ex_rf_src_sel,

    input logic branch_taken,

    output logic pc_write,
    output logic if_id_write,
    output logic if_flush,
    output logic id_flush
);

    logic load_use_hazard;
    logic ex_is_load;

    assign ex_is_load = (ex_rf_src_sel == 3'b001);

    assign load_use_hazard = ex_is_load && (ex_rd_addr != 5'd0) &&
                              ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

    assign pc_write = ~load_use_hazard;
    assign if_id_write = ~load_use_hazard;

    assign if_flush = branch_taken;

    assign id_flush = load_use_hazard || branch_taken;

endmodule
