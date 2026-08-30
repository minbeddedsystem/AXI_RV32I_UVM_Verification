`timescale 1ns / 1ps
`include "define.vh"

module data_mem (
    input  logic        clk,
    input  logic        dwe,
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] daddr,
    input  logic [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] data_ram [0:63];
    logic [31:0] raw_word;

    initial begin
        for (int i = 0; i < 64; i++) begin
            data_ram[i] = 32'd0;
        end

        data_ram[0] = 32'h0000_0004;  // address 0
        data_ram[1] = 32'h0000_0002;  // address 4
        data_ram[2] = 32'h0000_0003;  // address 8
    end

    always @(posedge clk) begin
        if (dwe) begin
            case (mem_mode)
                `SW: data_ram[daddr[31:2]] <= dwdata;
                `SH: begin
                    if (daddr[1]) data_ram[daddr[31:2]][31:16] <= dwdata[15:0];
                    else data_ram[daddr[31:2]][15:0] <= dwdata[15:0];
                end
                `SB: begin
                    case (daddr[1:0])
                        2'b00: data_ram[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: data_ram[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: data_ram[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: data_ram[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end
            endcase
        end
    end

    assign raw_word = data_ram[daddr[31:2]];

    load_mapper U_LOAD_MAPPER (
        .mem_mode(mem_mode),
        .daddr   (daddr),
        .raw_word(raw_word),
        .drdata  (drdata)
    );

endmodule


module load_mapper (
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] daddr,
    input  logic [31:0] raw_word,
    output logic [31:0] drdata
);

    always_comb begin
        drdata = 32'd0;
        case (mem_mode)
            `LW: drdata = raw_word;

            `LH:
            drdata = daddr[1] ? {{16{raw_word[31]}}, raw_word[31:16]}
                                     : {{16{raw_word[15]}}, raw_word[15: 0]};

            `LHU: drdata = daddr[1] ? {16'h0, raw_word[31:16]} : {16'h0, raw_word[15:0]};

            `LB: begin
                case (daddr[1:0])
                    2'b00: drdata = {{24{raw_word[7]}}, raw_word[7:0]};
                    2'b01: drdata = {{24{raw_word[15]}}, raw_word[15:8]};
                    2'b10: drdata = {{24{raw_word[23]}}, raw_word[23:16]};
                    2'b11: drdata = {{24{raw_word[31]}}, raw_word[31:24]};
                endcase
            end

            `LBU: begin
                case (daddr[1:0])
                    2'b00: drdata = {24'h0, raw_word[7:0]};
                    2'b01: drdata = {24'h0, raw_word[15:8]};
                    2'b10: drdata = {24'h0, raw_word[23:16]};
                    2'b11: drdata = {24'h0, raw_word[31:24]};
                endcase
            end
        endcase
    end

endmodule
