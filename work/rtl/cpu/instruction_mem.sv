// instruction mem by me....
`timescale 1ns / 1ps
module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_code
);

    logic [31:0] instr_rom[0:127];

    //`ifdef TEST_SIMULATION
    initial begin

        //── R-TYPE : ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND ─────────
        //초기값: x1=1, x2=2, x3=3, x4=4
        instr_rom[0]  = 32'h0020_82B3;  // ADD  x5,  x1, x2    → x5  = 1+2 = 3
        instr_rom[1]  = 32'h4022_0333;  // SUB  x6,  x4, x2    → x6  = 4-2 = 2
        instr_rom[2]  = 32'h0020_93B3;  // SLL  x7,  x1, x2    → x7  = 1<<2 = 4
        instr_rom[3]  = 32'h0041_2433;  // SLT  x8,  x2, x4    → x8  = (2<4)?1:0 = 1
        instr_rom[4]  = 32'h0041_34B3;  // SLTU x9,  x2, x4    → x9  = (2<4u)?1:0 = 1
        instr_rom[5]  = 32'h0022_4533;  // XOR  x10, x4, x2    → x10 = 4^2 = 6
        instr_rom[6]  = 32'h0022_55B3;  // SRL  x11, x4, x2    → x11 = 4>>2 = 1
        instr_rom[7]  = 32'h4022_5633;  // SRA  x12, x4, x2    → x12 = 4>>>2 = 1
        instr_rom[8]  = 32'h0022_66B3;  // OR   x13, x4, x2    → x13 = 4|2 = 6
        instr_rom[9]  = 32'h0022_7733;  // AND  x14, x4, x2    → x14 = 4&2 = 0

        //── I-TYPE : ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI ────
        instr_rom[10] = 32'h0050_8793;  // ADDI  x15, x1,  5   → x15 = 1+5 = 6
        instr_rom[11] = 32'h00A1_2813;  // SLTI  x16, x2, 10   → x16 = (2<10)?1:0 = 1
        instr_rom[12] = 32'h00A1_3893;  // SLTIU x17, x2, 10   → x17 = (2<10u)?1:0 = 1
        instr_rom[13] = 32'h00F2_4913;  // XORI  x18, x4, 15   → x18 = 4^15 = 11
        instr_rom[14] = 32'h00F2_6993;  // ORI   x19, x4, 15   → x19 = 4|15 = 15
        instr_rom[15] = 32'h00F2_7A13;  // ANDI  x20, x4, 15   → x20 = 4&15 = 4
        instr_rom[16] = 32'h0020_9A93;  // SLLI  x21, x1,  2   → x21 = 1<<2 = 4
        instr_rom[17] = 32'h0012_5B13;  // SRLI  x22, x4,  1   → x22 = 4>>1 = 2
        instr_rom[18] = 32'h4012_5B93;  // SRAI  x23, x4,  1   → x23 = 4>>>1 = 2

        // ── S-TYPE : SW/SH/SB ─────────────────────────────────────────
        instr_rom[19] = 32'h0040_2023;  // SW   x4,  0(x0)     → M[0]        = 0x0000_0004
        instr_rom[20] = 32'h0020_1223;  // SH   x2,  4(x0)     → M[4][15:0]  = 0x0002
        instr_rom[21] = 32'h0030_0423;  // SB   x3,  8(x0)     → M[8][7:0]   = 0x03

        // ── IL-TYPE : LW/LH/LHU/LB/LBU ───────────────────────────────
        instr_rom[22] = 32'h0000_2C03;  // LW   x24, 0(x0)     → x24 = 0x0000_0004
        instr_rom[23] = 32'h0040_1C83;  // LH   x25, 4(x0)     → x25 = sign_ext(0x0002) = 2
        instr_rom[24] = 32'h0040_5D03;  // LHU  x26, 4(x0)     → x26 = zero_ext(0x0002) = 2
        instr_rom[25] = 32'h0080_0D83;  // LB   x27, 8(x0)     → x27 = sign_ext(0x03)   = 3
        instr_rom[26] = 32'h0080_4E03;  // LBU  x28, 8(x0)     → x28 = zero_ext(0x03)   = 3

        // ── B-TYPE : BEQ/BNE/BLT/BGE/BLTU/BGEU ───────────────────────
        // x1=1, x4=4 → 모두 taken → 각 NOP 슬롯 skip
        instr_rom[27] = 32'h0010_8463;  // BEQ  x1, x1, +8     → taken (1==1)  skip [28]
        instr_rom[28] = 32'h0000_0013;  // NOP                  → (skip)
        instr_rom[29] = 32'h0040_9463;  // BNE  x1, x4, +8     → taken (1!=4)  skip [30]
        instr_rom[30] = 32'h0000_0013;  // NOP                  → (skip)
        instr_rom[31] = 32'h0040_C463;  // BLT  x1, x4, +8     → taken (1<4)   skip [32]
        instr_rom[32] = 32'h0000_0013;  // NOP                  → (skip)
        instr_rom[33] = 32'h0012_5463;  // BGE  x4, x1, +8     → taken (4>=1)  skip [34]
        instr_rom[34] = 32'h0000_0013;  // NOP                  → (skip)
        instr_rom[35] = 32'h0040_E463;  // BLTU x1, x4, +8     → taken (1<4u)  skip [36]
        instr_rom[36] = 32'h0000_0013;  // NOP                  → (skip)
        instr_rom[37] = 32'h0012_7463;  // BGEU x4, x1, +8     → taken (4>=1u) skip [38]
        instr_rom[38] = 32'h0000_0013;  // NOP                  → (skip)

        // ── U-TYPE : LUI / AUIPC ──────────────────────────────────────
        instr_rom[39] = 32'h1234_5EB7;  // LUI   x29, 0x12345  → x29 = 0x1234_5000
        instr_rom[40] = 32'h0000_1F17;  // AUIPC x30, 1        → x30 = PC + 0x0000_1000

        // ── J-TYPE : JAL / JALR ───────────────────────────────────────
        instr_rom[41] = 32'h0080_0F6F;
        instr_rom[42] = 32'h0000_0013;
        instr_rom[43] = 32'h000F_82E7;  // JALR x5, x31, 0

        // ── [44]~[63] : JAL x0, 0 무한루프 ───────────────────────────
        instr_rom[44] = 32'h0000_006F;
        instr_rom[45] = 32'h0000_006F;
        instr_rom[46] = 32'h0000_006F;
        instr_rom[47] = 32'h0000_006F;
        instr_rom[48] = 32'h0000_006F;
        instr_rom[49] = 32'h0000_006F;
        instr_rom[50] = 32'h0000_006F;
        instr_rom[51] = 32'h0000_006F;
        instr_rom[52] = 32'h0000_006F;
        instr_rom[53] = 32'h0000_006F;
        instr_rom[54] = 32'h0000_006F;
        instr_rom[55] = 32'h0000_006F;
        instr_rom[56] = 32'h0000_006F;
        instr_rom[57] = 32'h0000_006F;
        instr_rom[58] = 32'h0000_006F;
        instr_rom[59] = 32'h0000_006F;
        instr_rom[60] = 32'h0000_006F;
        instr_rom[61] = 32'h0000_006F;
        instr_rom[62] = 32'h0000_006F;
        instr_rom[63] = 32'h0000_006F;

    end
    //`endif
    initial begin
        $readmemh("instruction_mem_sort.mem", instr_rom);
    end

    assign instr_code = instr_rom[instr_addr[31:2]];
endmodule
