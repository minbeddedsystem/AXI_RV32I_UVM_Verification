`timescale 1ns / 1ps

module mux_2x1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic        sel,
    output logic [31:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;

endmodule
