`timescale 1ns / 1ps
module menu_rules_overlay(
    input wire [9:0] x,
    input wire [9:0] y,
    output reg on,
    output reg [11:0] color
);

function [4:0] glyph_row;
    input [7:0] ch; input [2:0] row; begin
        case (ch)
            8'd48: begin case(row)
                3'd0: glyph_row = 5'b01110;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10011;
                3'd3: glyph_row = 5'b10101;
                3'd4: glyph_row = 5'b11001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b01110;
                default: glyph_row = 5'b00000; endcase end
            8'd54: begin case(row)
                3'd0: glyph_row = 5'b01110;
                3'd1: glyph_row = 5'b10000;
                3'd2: glyph_row = 5'b10000;
                3'd3: glyph_row = 5'b11110;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b01110;
                default: glyph_row = 5'b00000; endcase end
            8'd65: begin case(row)
                3'd0: glyph_row = 5'b01110;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b11111;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b10001;
                default: glyph_row = 5'b00000; endcase end
            8'd66: begin case(row)
                3'd0: glyph_row = 5'b11110;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b11110;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b11110;
                default: glyph_row = 5'b00000; endcase end
            8'd67: begin case(row)
                3'd0: glyph_row = 5'b01111;
                3'd1: glyph_row = 5'b10000;
                3'd2: glyph_row = 5'b10000;
                3'd3: glyph_row = 5'b10000;
                3'd4: glyph_row = 5'b10000;
                3'd5: glyph_row = 5'b10000;
                3'd6: glyph_row = 5'b01111;
                default: glyph_row = 5'b00000; endcase end
            8'd68: begin case(row)
                3'd0: glyph_row = 5'b11110;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b10001;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b11110;
                default: glyph_row = 5'b00000; endcase end
            8'd69: begin case(row)
                3'd0: glyph_row = 5'b11111;
                3'd1: glyph_row = 5'b10000;
                3'd2: glyph_row = 5'b10000;
                3'd3: glyph_row = 5'b11110;
                3'd4: glyph_row = 5'b10000;
                3'd5: glyph_row = 5'b10000;
                3'd6: glyph_row = 5'b11111;
                default: glyph_row = 5'b00000; endcase end
            8'd72: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b11111;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b10001;
                default: glyph_row = 5'b00000; endcase end
            8'd73: begin case(row)
                3'd0: glyph_row = 5'b11111;
                3'd1: glyph_row = 5'b00100;
                3'd2: glyph_row = 5'b00100;
                3'd3: glyph_row = 5'b00100;
                3'd4: glyph_row = 5'b00100;
                3'd5: glyph_row = 5'b00100;
                3'd6: glyph_row = 5'b11111;
                default: glyph_row = 5'b00000; endcase end
            8'd74: begin case(row)
                3'd0: glyph_row = 5'b00111;
                3'd1: glyph_row = 5'b00010;
                3'd2: glyph_row = 5'b00010;
                3'd3: glyph_row = 5'b00010;
                3'd4: glyph_row = 5'b10010;
                3'd5: glyph_row = 5'b10010;
                3'd6: glyph_row = 5'b01100;
                default: glyph_row = 5'b00000; endcase end
            8'd75: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b10010;
                3'd2: glyph_row = 5'b10100;
                3'd3: glyph_row = 5'b11000;
                3'd4: glyph_row = 5'b10100;
                3'd5: glyph_row = 5'b10010;
                3'd6: glyph_row = 5'b10001;
                default: glyph_row = 5'b00000; endcase end
            8'd76: begin case(row)
                3'd0: glyph_row = 5'b10000;
                3'd1: glyph_row = 5'b10000;
                3'd2: glyph_row = 5'b10000;
                3'd3: glyph_row = 5'b10000;
                3'd4: glyph_row = 5'b10000;
                3'd5: glyph_row = 5'b10000;
                3'd6: glyph_row = 5'b11111;
                default: glyph_row = 5'b00000; endcase end
            8'd77: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b11011;
                3'd2: glyph_row = 5'b10101;
                3'd3: glyph_row = 5'b10101;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b10001;
                default: glyph_row = 5'b00000; endcase end
            8'd78: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b11001;
                3'd2: glyph_row = 5'b10101;
                3'd3: glyph_row = 5'b10011;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b10001;
                default: glyph_row = 5'b00000; endcase end
            8'd79: begin case(row)
                3'd0: glyph_row = 5'b01110;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b10001;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b01110;
                default: glyph_row = 5'b00000; endcase end
            8'd80: begin case(row)
                3'd0: glyph_row = 5'b11110;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b11110;
                3'd4: glyph_row = 5'b10000;
                3'd5: glyph_row = 5'b10000;
                3'd6: glyph_row = 5'b10000;
                default: glyph_row = 5'b00000; endcase end
            8'd82: begin case(row)
                3'd0: glyph_row = 5'b11110;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b11110;
                3'd4: glyph_row = 5'b10100;
                3'd5: glyph_row = 5'b10010;
                3'd6: glyph_row = 5'b10001;
                default: glyph_row = 5'b00000; endcase end
            8'd83: begin case(row)
                3'd0: glyph_row = 5'b01111;
                3'd1: glyph_row = 5'b10000;
                3'd2: glyph_row = 5'b10000;
                3'd3: glyph_row = 5'b01110;
                3'd4: glyph_row = 5'b00001;
                3'd5: glyph_row = 5'b00001;
                3'd6: glyph_row = 5'b11110;
                default: glyph_row = 5'b00000; endcase end
            8'd84: begin case(row)
                3'd0: glyph_row = 5'b11111;
                3'd1: glyph_row = 5'b00100;
                3'd2: glyph_row = 5'b00100;
                3'd3: glyph_row = 5'b00100;
                3'd4: glyph_row = 5'b00100;
                3'd5: glyph_row = 5'b00100;
                3'd6: glyph_row = 5'b00100;
                default: glyph_row = 5'b00000; endcase end
            8'd85: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b10001;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b10001;
                3'd6: glyph_row = 5'b01110;
                default: glyph_row = 5'b00000; endcase end
            8'd86: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b10001;
                3'd4: glyph_row = 5'b10001;
                3'd5: glyph_row = 5'b01010;
                3'd6: glyph_row = 5'b00100;
                default: glyph_row = 5'b00000; endcase end
            8'd87: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b10001;
                3'd3: glyph_row = 5'b10101;
                3'd4: glyph_row = 5'b10101;
                3'd5: glyph_row = 5'b11011;
                3'd6: glyph_row = 5'b10001;
                default: glyph_row = 5'b00000; endcase end
            8'd89: begin case(row)
                3'd0: glyph_row = 5'b10001;
                3'd1: glyph_row = 5'b10001;
                3'd2: glyph_row = 5'b01010;
                3'd3: glyph_row = 5'b00100;
                3'd4: glyph_row = 5'b00100;
                3'd5: glyph_row = 5'b00100;
                3'd6: glyph_row = 5'b00100;
                default: glyph_row = 5'b00000; endcase end
            8'd32: begin case(row)
                3'd0: glyph_row = 5'b00000;
                3'd1: glyph_row = 5'b00000;
                3'd2: glyph_row = 5'b00000;
                3'd3: glyph_row = 5'b00000;
                3'd4: glyph_row = 5'b00000;
                3'd5: glyph_row = 5'b00000;
                3'd6: glyph_row = 5'b00000;
                default: glyph_row = 5'b00000; endcase end
            default: glyph_row = 5'b00000;
        endcase
    end endfunction

function [7:0] line_char;
    input [2:0] line; input [3:0] col; begin
        line_char = 8'd32;
        case (line)
            3'd0: begin case(col)
                4'd0: line_char = 8'd72;
                4'd1: line_char = 8'd79;
                4'd2: line_char = 8'd87;
                4'd3: line_char = 8'd32;
                4'd4: line_char = 8'd84;
                4'd5: line_char = 8'd79;
                4'd6: line_char = 8'd32;
                4'd7: line_char = 8'd80;
                4'd8: line_char = 8'd76;
                4'd9: line_char = 8'd65;
                4'd10: line_char = 8'd89;
                default: line_char = 8'd32; endcase end
            3'd1: begin case(col)
                4'd0: line_char = 8'd85;
                4'd1: line_char = 8'd80;
                4'd2: line_char = 8'd32;
                4'd3: line_char = 8'd74;
                4'd4: line_char = 8'd85;
                4'd5: line_char = 8'd77;
                4'd6: line_char = 8'd80;
                default: line_char = 8'd32; endcase end
            3'd2: begin case(col)
                4'd0: line_char = 8'd68;
                4'd1: line_char = 8'd79;
                4'd2: line_char = 8'd87;
                4'd3: line_char = 8'd78;
                4'd4: line_char = 8'd32;
                4'd5: line_char = 8'd68;
                4'd6: line_char = 8'd85;
                4'd7: line_char = 8'd67;
                4'd8: line_char = 8'd75;
                default: line_char = 8'd32; endcase end
            3'd3: begin case(col)
                4'd0: line_char = 8'd67;
                4'd1: line_char = 8'd69;
                4'd2: line_char = 8'd78;
                4'd3: line_char = 8'd84;
                4'd4: line_char = 8'd69;
                4'd5: line_char = 8'd82;
                4'd6: line_char = 8'd32;
                4'd7: line_char = 8'd77;
                4'd8: line_char = 8'd69;
                4'd9: line_char = 8'd78;
                4'd10: line_char = 8'd85;
                default: line_char = 8'd32; endcase end
            3'd4: begin case(col)
                4'd0: line_char = 8'd65;
                4'd1: line_char = 8'd86;
                4'd2: line_char = 8'd79;
                4'd3: line_char = 8'd73;
                4'd4: line_char = 8'd68;
                4'd5: line_char = 8'd32;
                4'd6: line_char = 8'd67;
                4'd7: line_char = 8'd65;
                4'd8: line_char = 8'd67;
                4'd9: line_char = 8'd84;
                4'd10: line_char = 8'd73;
                default: line_char = 8'd32; endcase end
            3'd5: begin case(col)
                4'd0: line_char = 8'd65;
                4'd1: line_char = 8'd86;
                4'd2: line_char = 8'd79;
                4'd3: line_char = 8'd73;
                4'd4: line_char = 8'd68;
                4'd5: line_char = 8'd32;
                4'd6: line_char = 8'd66;
                4'd7: line_char = 8'd73;
                4'd8: line_char = 8'd82;
                4'd9: line_char = 8'd68;
                4'd10: line_char = 8'd83;
                default: line_char = 8'd32; endcase end
            3'd6: begin case(col)
                4'd0: line_char = 8'd83;
                4'd1: line_char = 8'd85;
                4'd2: line_char = 8'd82;
                4'd3: line_char = 8'd86;
                4'd4: line_char = 8'd73;
                4'd5: line_char = 8'd86;
                4'd6: line_char = 8'd69;
                4'd7: line_char = 8'd32;
                4'd8: line_char = 8'd54;
                4'd9: line_char = 8'd48;
                default: line_char = 8'd32; endcase end
            default: line_char = 8'd32;
        endcase
    end endfunction

reg [2:0] line_idx;
reg [7:0] ch;
reg [4:0] bits;
integer rx, ry, char_col, glyph_col, glyph_row_i;
always @(*) begin
    on = 1'b0;
    color = 12'h000;
    if ((x >= 10'd340) && (x < 10'd636) && (y >= 10'd20) && (y < 10'd238)) begin
        on = 1'b1;
        color = 12'h51A;
        if ((x < 10'd344) || (x >= 10'd632) || (y < 10'd24) || (y >= 10'd234))
            color = 12'hFD9;
        rx = x - 10'd354;
        ry = y - 10'd36;
        line_idx = 3'd7;
        if ((ry >= 0) && (ry < 28)) line_idx = 3'd0;
        else if ((ry >= 28) && (ry < 56)) line_idx = 3'd1;
        else if ((ry >= 56) && (ry < 84)) line_idx = 3'd2;
        else if ((ry >= 84) && (ry < 112)) line_idx = 3'd3;
        else if ((ry >= 112) && (ry < 140)) line_idx = 3'd4;
        else if ((ry >= 140) && (ry < 168)) line_idx = 3'd5;
        else if ((ry >= 168) && (ry < 196)) line_idx = 3'd6;
        if (line_idx < 3'd7) begin
            char_col = rx / 24;
            glyph_col = (rx % 24) / 4;
            glyph_row_i = (ry % 28) / 4;
            ch = line_char(line_idx, char_col[3:0]);
            bits = glyph_row(ch, glyph_row_i[2:0]);
            if ((glyph_col < 5) && (glyph_row_i < 7) && bits[4-glyph_col])
                color = 12'hFFF;
        end
    end
end
endmodule
