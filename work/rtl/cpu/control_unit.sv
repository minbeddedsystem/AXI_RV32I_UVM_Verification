`timescale 1ns / 1ps
`include "define.vh"

module control_unit (
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        alusrc_sel,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] rf_src_sel,
    output logic [ 2:0] mem_mode,
    output logic        dwe
);
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] opcode;

    assign funct3 = instr_code[14:12];
    assign funct7 = instr_code[31:25];
    assign opcode = instr_code[6:0];


    //[DEBUG]
    typedef enum logic [6:0] {
        DBG_R_TYPE  = `R_TYPE,
        DBG_S_TYPE  = `S_TYPE,
        DBG_IL_TYPE = `IL_TYPE,
        DBG_I_TYPE  = `I_TYPE,
        DBG_B_TYPE  = `B_TYPE,
        DBG_UL_TYPE = `UL_TYPE,
        DBG_UA_TYPE = `UA_TYPE,
        DBG_J_TYPE  = `J_TYPE,
        DBG_JL_TYPE = `JL_TYPE
    } opcode_dbg_e;
    opcode_dbg_e opcode_dbg;
    assign opcode_dbg = opcode_dbg_e'(opcode);


    always_comb begin
        rf_we       = 0;
        branch      = 0;
        jal         = 0;
        jalr        = 0;
        alusrc_sel  = 0;
        alu_control = 0;
        rf_src_sel  = 3'b0;
        mem_mode    = 3'b0;
        dwe         = 0;

        case (opcode)
            `R_TYPE: begin
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 0;
                alu_control = {funct7[5], funct3};
                rf_src_sel  = 0;
                mem_mode    = 3'd0;
                dwe         = 0;
            end

            `S_TYPE: begin
                rf_we       = 1'b0;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b1;
                alu_control = `ADD;
                rf_src_sel  = 0;
                mem_mode    = funct3;
                dwe         = 1'b1;
            end

            `IL_TYPE: begin
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b1;  // rs1 + imm
                alu_control = `ADD;
                rf_src_sel  = 1;
                mem_mode    = funct3;
                dwe         = 1'b0;
            end

            `I_TYPE: begin
                rf_we      = 1'b1;
                branch     = 0;
                jal        = 0;
                jalr       = 0;
                alusrc_sel = 1'b1;  // rs1 + imm
                if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                else alu_control = {1'b0, funct3};
                rf_src_sel = 0;  // alu result
                mem_mode   = 0;
                dwe        = 1'b0;
            end

            `B_TYPE: begin
                rf_we       = 1'b0;
                branch      = 1;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b0;  // RS1, RS2
                alu_control = {1'b0, funct3};
                rf_src_sel  = 0;
                mem_mode    = 0;
                dwe         = 0;
            end

            `UL_TYPE: begin
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b0;  // RS1, RS2
                alu_control = 4'b0;
                rf_src_sel  = 3'b010;
                mem_mode = 0;
                dwe      = 0;
            end

            `UA_TYPE: begin  // AUIPC
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b1;
                alu_control = `ADD;
                rf_src_sel  = 3'b011;
                mem_mode    = 0;
                dwe         = 0;
            end

            `J_TYPE: begin  // JAL
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 1;
                jalr        = 0;
                alusrc_sel  = 1'b0;
                alu_control = 4'b0;
                rf_src_sel  = 3'b100;
                mem_mode    = 0;
                dwe         = 0;
            end

            `JL_TYPE: begin  // JALR
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 1;
                jalr        = 1;
                alusrc_sel  = 1'b1;
                alu_control = `ADD;
                rf_src_sel  = 3'b100;
                mem_mode    = 0;
                dwe         = 0;
            end


        endcase
    end
endmodule