`timescale 1ns / 1ps
`include "define.vh"

module imm_extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);
    always_comb begin
        imm_extend = 32'd0;
        case (instr_code[6:0])
            `S_TYPE:
            imm_extend = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };
            // 반복 연산자 {20{instr_code[31]}} : 20 -> 반복 횟수.

            `IL_TYPE, `I_TYPE, `JL_TYPE: begin
                imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            end

            `B_TYPE: begin  // 12, 11, 10:5, 4:1
                imm_extend = {
                    {20{instr_code[31]}},  // 20
                    instr_code[7],  // 1
                    instr_code[30:25],  // 6
                    instr_code[11:8],  // 4
                    1'b0  // 1
                };
            end

            `UL_TYPE, `UA_TYPE: begin
                imm_extend = {instr_code[31:12], 12'h000};
            end

            `J_TYPE: begin
                imm_extend = {
                    {12{instr_code[31]}},
                    instr_code[19:12],
                    instr_code[20],
                    instr_code[30:21],
                    1'b0
                };
            end
        endcase
    end

endmodule