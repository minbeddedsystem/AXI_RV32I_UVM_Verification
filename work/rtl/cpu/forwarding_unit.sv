`timescale 1ns / 1ps

module forwarding_unit (
    input  logic [4:0] ex_rs1_addr,
    input  logic [4:0] ex_rs2_addr,

    input  logic [4:0] mem_rd_addr,
    input  logic       mem_rf_we,

    input  logic [4:0] wb_rd_addr,
    input  logic       wb_rf_we,

    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always_comb begin
        if (mem_rf_we && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs1_addr))
            forward_a = 2'b10;
        else if (wb_rf_we && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs1_addr))
            forward_a = 2'b01;
        else
            forward_a = 2'b00;
    end

    always_comb begin
        if (mem_rf_we && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs2_addr))
            forward_b = 2'b10;
        else if (wb_rf_we && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs2_addr))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end

endmodule