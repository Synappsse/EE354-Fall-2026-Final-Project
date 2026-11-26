`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EE354 Dino Jump - fixed 64-segment map
// 64 segments * 225 pixels = 14,400 world pixels
//
// obstacle type:
//   0 = empty
//   1 = single cactus
//   2 = double cactus
//   3 = high bird
//   4 = low bird
//////////////////////////////////////////////////////////////////////////////////

module dino_map(
    input  wire [5:0] segment_num,
    output reg  [2:0] obs1_type,
    output reg  [7:0] obs1_offset,
    output reg  [2:0] obs2_type,
    output reg  [7:0] obs2_offset
);

    always @(*) begin
        obs1_type   = 3'd0;
        obs1_offset = 8'd0;
        obs2_type   = 3'd0;
        obs2_offset = 8'd0;

        case (segment_num)
            6'd0:  begin end
            6'd1:  begin end
            6'd2:  begin obs1_type=3'd1; obs1_offset=8'd100; end
            6'd3:  begin end
            6'd4:  begin obs1_type=3'd1; obs1_offset=8'd125; end
            6'd5:  begin end
            6'd6:  begin obs1_type=3'd1; obs1_offset=8'd80;  end
            6'd7:  begin end
            6'd8:  begin obs1_type=3'd1; obs1_offset=8'd65;  end
            6'd9:  begin obs1_type=3'd1; obs1_offset=8'd145; end
            6'd10: begin end
            6'd11: begin obs1_type=3'd2; obs1_offset=8'd110; end
            6'd12: begin end
            6'd13: begin obs1_type=3'd1; obs1_offset=8'd150; end
            6'd14: begin end
            6'd15: begin obs1_type=3'd3; obs1_offset=8'd100; end

            6'd16: begin end
            6'd17: begin obs1_type=3'd1; obs1_offset=8'd75;  end
            6'd18: begin obs1_type=3'd3; obs1_offset=8'd155; end
            6'd19: begin end
            6'd20: begin obs1_type=3'd2; obs1_offset=8'd95;  end
            6'd21: begin end
            6'd22: begin obs1_type=3'd1; obs1_offset=8'd60;  end
            6'd23: begin obs1_type=3'd1; obs1_offset=8'd150; end
            6'd24: begin end
            6'd25: begin obs1_type=3'd4; obs1_offset=8'd105; end
            6'd26: begin end
            6'd27: begin obs1_type=3'd1; obs1_offset=8'd80;  end
            6'd28: begin end
            6'd29: begin obs1_type=3'd2; obs1_offset=8'd120; end
            6'd30: begin obs1_type=3'd3; obs1_offset=8'd170; end
            6'd31: begin end

            // Easier back half: one obstacle about every other segment,
            // no cactus+bird combo traps, and more recovery space.
            6'd32: begin obs1_type=3'd1; obs1_offset=8'd100; end
            6'd33: begin end
            6'd34: begin obs1_type=3'd4; obs1_offset=8'd140; end
            6'd35: begin end
            6'd36: begin obs1_type=3'd1; obs1_offset=8'd120; end
            6'd37: begin end
            6'd38: begin obs1_type=3'd3; obs1_offset=8'd120; end
            6'd39: begin end
            6'd40: begin obs1_type=3'd1; obs1_offset=8'd80;  end
            6'd41: begin end
            6'd42: begin obs1_type=3'd4; obs1_offset=8'd130; end
            6'd43: begin end
            6'd44: begin obs1_type=3'd2; obs1_offset=8'd115; end
            6'd45: begin end
            6'd46: begin obs1_type=3'd1; obs1_offset=8'd140; end
            6'd47: begin end

            6'd48: begin obs1_type=3'd3; obs1_offset=8'd110; end
            6'd49: begin end
            6'd50: begin obs1_type=3'd1; obs1_offset=8'd100; end
            6'd51: begin end
            6'd52: begin obs1_type=3'd4; obs1_offset=8'd145; end
            6'd53: begin end
            6'd54: begin obs1_type=3'd2; obs1_offset=8'd120; end
            6'd55: begin end
            6'd56: begin obs1_type=3'd1; obs1_offset=8'd85;  end
            6'd57: begin end
            6'd58: begin obs1_type=3'd3; obs1_offset=8'd140; end
            6'd59: begin end
            6'd60: begin obs1_type=3'd1; obs1_offset=8'd120; end
            6'd61: begin end
            6'd62: begin obs1_type=3'd4; obs1_offset=8'd150; end
            6'd63: begin end

            default: begin end
        endcase
    end

endmodule
