`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EE354 Dino Game - sprite-rendered fixed-map branch version
//
// This is intentionally a NEW module so partner-authored dino_game_a7.v stays
// untouched on main.
//
// Retained behavior:
//   BTNL start/restart
//   BTNU jump (debounced)
//   BTND duck (debounced)
//   BTNC reset
//   SW0  reset
//
// Added here:
//   2-frame running Dino sprite
//   2-frame ducking Dino sprite
//   cactus + double-cactus sprites
//   2-frame high/low bird sprite
//   fixed 64-segment map, 225 pixels per segment
//////////////////////////////////////////////////////////////////////////////////

module dino_game_a7_sprites(
    input  wire       ClkPort,
    input  wire       Sw0,
    input  wire       btnU,
    input  wire       btnD,
    input  wire       btnL,
    input  wire       btnC,

    output wire       vga_h_sync,
    output wire       vga_v_sync,
    output reg  [3:0] vga_r,
    output reg  [3:0] vga_g,
    output reg  [3:0] vga_b
);

    wire reset = Sw0 | btnC;
    wire board_clk = ClkPort;

    reg [27:0] DIV_CLK = 28'd0;

    always @(posedge board_clk or posedge reset) begin
        if (reset)
            DIV_CLK <= 28'd0;
        else
            DIV_CLK <= DIV_CLK + 1'b1;
    end

    wire pixel_clk = DIV_CLK[1];
    wire game_tick = DIV_CLK[23];

    wire jump_DPB;
    wire duck_DPB;

    wire       inDisplayArea;
    wire [9:0] CounterX;
    wire [9:0] CounterY;

    hvsync_generator syncgen(
        .clk(pixel_clk),
        .reset(reset),
        .vga_h_sync(vga_h_sync),
        .vga_v_sync(vga_v_sync),
        .inDisplayArea(inDisplayArea),
        .CounterX(CounterX),
        .CounterY(CounterY)
    );

    ee354_debouncer #(.N_dc(28)) jump_debouncer (
        .CLK(board_clk),
        .RESET(reset),
        .PB(btnU),
        .DPB(jump_DPB),
        .SCEN(),
        .MCEN(),
        .CCEN()
    );

    ee354_debouncer #(.N_dc(28)) duck_debouncer (
        .CLK(board_clk),
        .RESET(reset),
        .PB(btnD),
        .DPB(duck_DPB),
        .SCEN(),
        .MCEN(),
        .CCEN()
    );

    wire frame_tick = (CounterX == 10'd799) && (CounterY == 10'd520);

    // Partner timing logic: count gameplay frames for score/speed/win timing.
    reg [11:0] frame_counter = 12'd0;

    localparam [9:0] GROUND_Y = 10'd420;

    localparam [9:0] DINO_X = 10'd80;
    localparam [9:0] DINO_W = 10'd44;
    localparam [9:0] DINO_H = 10'd47;
    localparam [9:0] DINO_GROUND_Y = GROUND_Y - DINO_H;

    localparam [9:0] DINO_DUCK_W = 10'd59;
    localparam [9:0] DINO_DUCK_H = 10'd30;
    localparam [9:0] DINO_DUCK_GROUND_Y = GROUND_Y - DINO_DUCK_H;

    wire [9:0] current_dino_w =
        duck_DPB ? DINO_DUCK_W : DINO_W;

    wire [9:0] current_dino_h =
        duck_DPB ? DINO_DUCK_H : DINO_H;

    wire [9:0] current_dino_ground_y =
        duck_DPB ? DINO_DUCK_GROUND_Y : DINO_GROUND_Y;

    wire [9:0] current_dino_y =
        current_dino_ground_y - (DINO_GROUND_Y - dino_y);

    localparam [8:0] SEGMENT_WIDTH = 9'd225;

    localparam [2:0] EMPTY         = 3'd0;
    localparam [2:0] CACTUS        = 3'd1;
    localparam [2:0] DOUBLE_CACTUS = 3'd2;
    localparam [2:0] HIGH_BIRD     = 3'd3;
    localparam [2:0] LOW_BIRD      = 3'd4;

    localparam [9:0] CACTUS_W = 10'd28;
    localparam [9:0] CACTUS_H = 10'd46;
    localparam [9:0] CACTUS_Y = GROUND_Y - CACTUS_H;

    localparam [9:0] DOUBLE_CACTUS_W = 10'd60;

    localparam [9:0] BIRD_W = 10'd46;
    localparam [9:0] BIRD_H = 10'd24;
    localparam [9:0] HIGH_BIRD_Y = 10'd330;
    localparam [9:0] LOW_BIRD_Y  = 10'd356;

    reg [9:0] cactus_speed = 10'd4;

    localparam [1:0] MENU      = 2'b00;
    localparam [1:0] PLAYING   = 2'b01;
    localparam [1:0] GAME_OVER = 2'b10;
    localparam [1:0] WIN       = 2'b11;

    reg [1:0] game_state = MENU;

    reg [9:0] dino_y = DINO_GROUND_Y;
    reg [5:0] jump_phase = 6'd0;
    reg [15:0] score = 16'd0;

    reg [5:0] map_segment = 6'd0;
    reg [8:0] map_offset = 9'd0;

    reg [2:0] anim_count = 3'd0;
    reg       anim_frame = 1'b0;

    reg btnL_prev = 1'b0;
    reg jump_prev = 1'b0;

    wire start_pressed = btnL & ~btnL_prev;
    wire jump_pressed  = jump_DPB & ~jump_prev;

    // Partner restart detection used by score/timing logic.
    wire start_game = start_pressed &&
                ((game_state == MENU) ||
                 (game_state == GAME_OVER) ||
                 (game_state == WIN));

    wire [5:0] seg0_num = map_segment;
    wire [5:0] seg1_num = map_segment + 6'd1;
    wire [5:0] seg2_num = map_segment + 6'd2;
    wire [5:0] seg3_num = map_segment + 6'd3;

    wire [2:0] s0_t1, s0_t2, s1_t1, s1_t2;
    wire [2:0] s2_t1, s2_t2, s3_t1, s3_t2;
    wire [7:0] s0_o1, s0_o2, s1_o1, s1_o2;
    wire [7:0] s2_o1, s2_o2, s3_o1, s3_o2;

    dino_map map0(.segment_num(seg0_num), .obs1_type(s0_t1), .obs1_offset(s0_o1),
                  .obs2_type(s0_t2), .obs2_offset(s0_o2));
    dino_map map1(.segment_num(seg1_num), .obs1_type(s1_t1), .obs1_offset(s1_o1),
                  .obs2_type(s1_t2), .obs2_offset(s1_o2));
    dino_map map2(.segment_num(seg2_num), .obs1_type(s2_t1), .obs1_offset(s2_o1),
                  .obs2_type(s2_t2), .obs2_offset(s2_o2));
    dino_map map3(.segment_num(seg3_num), .obs1_type(s3_t1), .obs1_offset(s3_o1),
                  .obs2_type(s3_t2), .obs2_offset(s3_o2));

    wire signed [12:0] x0a = 13'sd0   + $signed({5'd0,s0_o1}) - $signed({4'd0,map_offset});
    wire signed [12:0] x0b = 13'sd0   + $signed({5'd0,s0_o2}) - $signed({4'd0,map_offset});
    wire signed [12:0] x1a = 13'sd225 + $signed({5'd0,s1_o1}) - $signed({4'd0,map_offset});
    wire signed [12:0] x1b = 13'sd225 + $signed({5'd0,s1_o2}) - $signed({4'd0,map_offset});
    wire signed [12:0] x2a = 13'sd450 + $signed({5'd0,s2_o1}) - $signed({4'd0,map_offset});
    wire signed [12:0] x2b = 13'sd450 + $signed({5'd0,s2_o2}) - $signed({4'd0,map_offset});
    wire signed [12:0] x3a = 13'sd675 + $signed({5'd0,s3_o1}) - $signed({4'd0,map_offset});
    wire signed [12:0] x3b = 13'sd675 + $signed({5'd0,s3_o2}) - $signed({4'd0,map_offset});

    function [9:0] obstacle_width;
        input [2:0] t;
        begin
            case (t)
                CACTUS:        obstacle_width = CACTUS_W;
                DOUBLE_CACTUS: obstacle_width = DOUBLE_CACTUS_W;
                HIGH_BIRD:     obstacle_width = BIRD_W;
                LOW_BIRD:      obstacle_width = BIRD_W;
                default:       obstacle_width = 10'd0;
            endcase
        end
    endfunction

    function [9:0] obstacle_y;
        input [2:0] t;
        begin
            case (t)
                CACTUS:        obstacle_y = CACTUS_Y;
                DOUBLE_CACTUS: obstacle_y = CACTUS_Y;
                HIGH_BIRD:     obstacle_y = HIGH_BIRD_Y;
                LOW_BIRD:      obstacle_y = LOW_BIRD_Y;
                default:       obstacle_y = 10'd0;
            endcase
        end
    endfunction

    function [9:0] obstacle_height;
        input [2:0] t;
        begin
            case (t)
                CACTUS:        obstacle_height = CACTUS_H;
                DOUBLE_CACTUS: obstacle_height = CACTUS_H;
                HIGH_BIRD:     obstacle_height = BIRD_H;
                LOW_BIRD:      obstacle_height = BIRD_H;
                default:       obstacle_height = 10'd0;
            endcase
        end
    endfunction

    // Conservative collision boxes matched to the visible gray body pixels.
    // White sprite outlines and transparent padding do NOT count as a hit.
    function obstacle_collides;
        input signed [12:0] ox;
        input [2:0] t;
        input [9:0] dy;
        input [9:0] dh;
        reg [9:0] dx_left;
        reg [9:0] dx_right;
        reg [9:0] dy_top;
        reg [9:0] dy_bottom;
        reg signed [12:0] ox_left;
        reg signed [12:0] ox_right;
        reg [9:0] oy_top;
        reg [9:0] oy_bottom;
        begin
            if (duck_DPB) begin
                dx_left   = DINO_X + 10'd10;
                dx_right  = DINO_X + 10'd47;
                dy_top    = dy + 10'd8;
                dy_bottom = dy + 10'd25;
            end
            else begin
                dx_left   = DINO_X + 10'd10;
                dx_right  = DINO_X + 10'd33;
                dy_top    = dy + 10'd8;
                dy_bottom = dy + 10'd42;
            end

            case (t)
                CACTUS: begin
                    ox_left   = ox + 13'sd9;
                    ox_right  = ox + 13'sd19;
                    oy_top    = CACTUS_Y + 10'd9;
                    oy_bottom = CACTUS_Y + 10'd43;
                end

                DOUBLE_CACTUS: begin
                    ox_left   = ox + 13'sd9;
                    ox_right  = ox + 13'sd51;
                    oy_top    = CACTUS_Y + 10'd9;
                    oy_bottom = CACTUS_Y + 10'd43;
                end

                HIGH_BIRD: begin
                    ox_left   = ox + 13'sd7;
                    ox_right  = ox + 13'sd38;
                    oy_top    = HIGH_BIRD_Y + 10'd10;
                    oy_bottom = HIGH_BIRD_Y + 10'd18;
                end

                LOW_BIRD: begin
                    ox_left   = ox + 13'sd7;
                    ox_right  = ox + 13'sd38;
                    oy_top    = LOW_BIRD_Y + 10'd10;
                    oy_bottom = LOW_BIRD_Y + 10'd18;
                end

                default: begin
                    ox_left   = 13'sd0;
                    ox_right  = 13'sd0;
                    oy_top    = 10'd0;
                    oy_bottom = 10'd0;
                end
            endcase

            obstacle_collides =
                (t != EMPTY) &&
                ($signed({3'd0,dx_left}) < ox_right) &&
                ($signed({3'd0,dx_right}) > ox_left) &&
                (dy_top < oy_bottom) &&
                (dy_bottom > oy_top);
        end
    endfunction

    wire collision =
        obstacle_collides(x0a, s0_t1, current_dino_y, current_dino_h) ||
        obstacle_collides(x0b, s0_t2, current_dino_y, current_dino_h) ||
        obstacle_collides(x1a, s1_t1, current_dino_y, current_dino_h) ||
        obstacle_collides(x1b, s1_t2, current_dino_y, current_dino_h) ||
        obstacle_collides(x2a, s2_t1, current_dino_y, current_dino_h) ||
        obstacle_collides(x2b, s2_t2, current_dino_y, current_dino_h) ||
        obstacle_collides(x3a, s3_t1, current_dino_y, current_dino_h) ||
        obstacle_collides(x3b, s3_t2, current_dino_y, current_dino_h);

    always @(posedge pixel_clk, posedge reset) begin
        if (reset) begin
            game_state <= MENU;
            dino_y <= DINO_GROUND_Y;
            jump_phase <= 6'd0;
            map_segment <= 6'd0;
            map_offset <= 9'd0;
            btnL_prev <= 1'b0;
            jump_prev <= 1'b0;
            anim_count <= 3'd0;
            anim_frame <= 1'b0;
        end
        else if (frame_tick) begin
            btnL_prev <= btnL;
            jump_prev <= jump_DPB;

            case (game_state)
                MENU: begin
                    dino_y <= DINO_GROUND_Y;
                    jump_phase <= 6'd0;
                    map_segment <= 6'd0;
                    map_offset <= 9'd0;
                    anim_count <= 3'd0;
                    anim_frame <= 1'b0;

                    if (start_pressed)
                        game_state <= PLAYING;
                end

                PLAYING: begin
                    if (anim_count == 3'd7) begin
                        anim_count <= 3'd0;
                        anim_frame <= ~anim_frame;
                    end
                    else begin
                        anim_count <= anim_count + 1'b1;
                    end

                    if ((jump_phase == 0) && jump_pressed) begin
                        jump_phase <= 6'd1;
                    end
                    else if (jump_phase != 0) begin
                        if (jump_phase <= 6'd8) begin
                            dino_y <= dino_y - 10'd12;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd16) begin
                            dino_y <= dino_y - 10'd6;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd24) begin
                            dino_y <= dino_y + 10'd6;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd32) begin
                            dino_y <= dino_y + 10'd12;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else begin
                            dino_y <= DINO_GROUND_Y;
                            jump_phase <= 6'd0;
                        end
                    end
                    else begin
                        dino_y <= DINO_GROUND_Y;
                    end

                    if ((map_offset + cactus_speed) >= SEGMENT_WIDTH) begin
                        map_offset <= (map_offset + cactus_speed) - SEGMENT_WIDTH;
                        map_segment <= map_segment + 1'b1;
                    end
                    else begin
                        map_offset <= map_offset + cactus_speed;
                    end

                    if (collision)
                        game_state <= GAME_OVER;
                    else if (score >= 16'd60)
                        game_state <= WIN;
                end

                GAME_OVER: begin
                    if (start_pressed) begin
                        game_state <= PLAYING;
                        dino_y <= DINO_GROUND_Y;
                        jump_phase <= 6'd0;
                        map_segment <= 6'd0;
                        map_offset <= 9'd0;
                        anim_count <= 3'd0;
                        anim_frame <= 1'b0;
                    end
                end

                WIN: begin
                    if (start_pressed) begin
                        game_state <= PLAYING;
                        dino_y <= DINO_GROUND_Y;
                        jump_phase <= 6'd0;
                        map_segment <= 6'd0;
                        map_offset <= 9'd0;
                        anim_count <= 3'd0;
                        anim_frame <= 1'b0;
                    end
                end

                default: game_state <= MENU;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Partner score + speed management merged into sprite/map game.
    // Score increments once per second; map speed increases every 15 seconds.
    // -------------------------------------------------------------------------
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            frame_counter <= 12'd0;
            score         <= 16'd0;
            cactus_speed  <= 10'd4;
        end
        else if (start_game && frame_tick) begin
            frame_counter <= 12'd0;
            score         <= 16'd0;
            cactus_speed  <= 10'd4;
        end
        else if ((game_state == PLAYING) && frame_tick) begin
            frame_counter <= frame_counter + 1'b1;

            if ((frame_counter % 60) == 59)
                score <= score + 1'b1;

            if (((frame_counter % 900) == 899) && (cactus_speed < 10'd8))
                cactus_speed <= cactus_speed + 1'b1;
        end
    end

    reg [15:0] dino_run0_mem  [0:258];
    reg [15:0] dino_run1_mem  [0:258];
    reg [15:0] dino_duck0_mem [0:221];
    reg [15:0] dino_duck1_mem [0:221];
    reg [15:0] cactus_mem     [0:160];
    reg [15:0] bird0_mem      [0:137];
    reg [15:0] bird1_mem      [0:137];

    initial begin
        $readmemh("dino_run0.mem",  dino_run0_mem);
        $readmemh("dino_run1.mem",  dino_run1_mem);
        $readmemh("dino_duck0.mem", dino_duck0_mem);
        $readmemh("dino_duck1.mem", dino_duck1_mem);
        $readmemh("cactus.mem",     cactus_mem);
        $readmemh("bird0.mem",      bird0_mem);
        $readmemh("bird1.mem",      bird1_mem);
    end

    function [1:0] packed_pixel;
        input [15:0] word;
        input [2:0] select;
        begin
            case (select)
                3'd0: packed_pixel = word[15:14];
                3'd1: packed_pixel = word[13:12];
                3'd2: packed_pixel = word[11:10];
                3'd3: packed_pixel = word[9:8];
                3'd4: packed_pixel = word[7:6];
                3'd5: packed_pixel = word[5:4];
                3'd6: packed_pixel = word[3:2];
                3'd7: packed_pixel = word[1:0];
                default: packed_pixel = 2'b00;
            endcase
        end
    endfunction

    function [11:0] sprite_color;
        input [1:0] index;
        begin
            case (index)
                2'b01: sprite_color = 12'h555;
                2'b10: sprite_color = 12'hFFF;
                default: sprite_color = 12'h000;
            endcase
        end
    endfunction

    function obstacle_box_pixel;
        input [9:0] px;
        input [9:0] py;
        input signed [12:0] ox;
        input [2:0] t;
        reg [9:0] ow;
        reg [9:0] oy;
        reg [9:0] oh;
        reg signed [12:0] pxs;
        begin
            ow = obstacle_width(t);
            oy = obstacle_y(t);
            oh = obstacle_height(t);
            pxs = $signed({3'd0,px});

            obstacle_box_pixel =
                (t != EMPTY) &&
                (pxs >= ox) &&
                (pxs < (ox + $signed({3'd0,ow}))) &&
                (py >= oy) &&
                (py < (oy + oh));
        end
    endfunction

    wire ground_on =
        (CounterY >= GROUND_Y) &&
        (CounterY < (GROUND_Y + 10'd4));

    wire dino_box_on =
        (CounterX >= DINO_X) &&
        (CounterX < (DINO_X + current_dino_w)) &&
        (CounterY >= current_dino_y) &&
        (CounterY < (current_dino_y + current_dino_h));

    wire menu_box =
        (CounterX >= 10'd180) && (CounterX < 10'd460) &&
        (CounterY >= 10'd180) && (CounterY < 10'd300);

    wire gameover_box =
        (CounterX >= 10'd160) && (CounterX < 10'd480) &&
        (CounterY >= 10'd170) && (CounterY < 10'd310);

    reg       render_obs_box_on;
    reg [2:0] render_obs_type;
    reg [6:0] render_obs_rel_x;
    reg [6:0] render_obs_rel_y;

    always @(*) begin
        render_obs_box_on = 1'b0;
        render_obs_type = EMPTY;
        render_obs_rel_x = 7'd0;
        render_obs_rel_y = 7'd0;

        if (obstacle_box_pixel(CounterX, CounterY, x0a, s0_t1)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s0_t1;
            render_obs_rel_x = CounterX - x0a;
            render_obs_rel_y = CounterY - obstacle_y(s0_t1);
        end
        else if (obstacle_box_pixel(CounterX, CounterY, x0b, s0_t2)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s0_t2;
            render_obs_rel_x = CounterX - x0b;
            render_obs_rel_y = CounterY - obstacle_y(s0_t2);
        end
        else if (obstacle_box_pixel(CounterX, CounterY, x1a, s1_t1)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s1_t1;
            render_obs_rel_x = CounterX - x1a;
            render_obs_rel_y = CounterY - obstacle_y(s1_t1);
        end
        else if (obstacle_box_pixel(CounterX, CounterY, x1b, s1_t2)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s1_t2;
            render_obs_rel_x = CounterX - x1b;
            render_obs_rel_y = CounterY - obstacle_y(s1_t2);
        end
        else if (obstacle_box_pixel(CounterX, CounterY, x2a, s2_t1)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s2_t1;
            render_obs_rel_x = CounterX - x2a;
            render_obs_rel_y = CounterY - obstacle_y(s2_t1);
        end
        else if (obstacle_box_pixel(CounterX, CounterY, x2b, s2_t2)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s2_t2;
            render_obs_rel_x = CounterX - x2b;
            render_obs_rel_y = CounterY - obstacle_y(s2_t2);
        end
        else if (obstacle_box_pixel(CounterX, CounterY, x3a, s3_t1)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s3_t1;
            render_obs_rel_x = CounterX - x3a;
            render_obs_rel_y = CounterY - obstacle_y(s3_t1);
        end
        else if (obstacle_box_pixel(CounterX, CounterY, x3b, s3_t2)) begin
            render_obs_box_on = 1'b1;
            render_obs_type = s3_t2;
            render_obs_rel_x = CounterX - x3b;
            render_obs_rel_y = CounterY - obstacle_y(s3_t2);
        end
    end

    wire [6:0] dino_rel_x =
        dino_box_on ? (CounterX - DINO_X) : 7'd0;

    wire [6:0] dino_rel_y =
        dino_box_on ? (CounterY - current_dino_y) : 7'd0;

    wire [11:0] run_pixel_addr =
        (dino_rel_y * 12'd44) + dino_rel_x;

    wire [11:0] duck_pixel_addr =
        (dino_rel_y * 12'd59) + dino_rel_x;

    wire [8:0] run_word_addr = run_pixel_addr[11:3];
    wire [7:0] duck_word_addr = duck_pixel_addr[11:3];

    wire [15:0] run_word =
        anim_frame ? dino_run1_mem[run_word_addr] : dino_run0_mem[run_word_addr];

    wire [15:0] duck_word =
        anim_frame ? dino_duck1_mem[duck_word_addr] : dino_duck0_mem[duck_word_addr];

    wire [1:0] run_index =
        packed_pixel(run_word, run_pixel_addr[2:0]);

    wire [1:0] duck_index =
        packed_pixel(duck_word, duck_pixel_addr[2:0]);

    wire [1:0] dino_index =
        duck_DPB ? duck_index : run_index;

    wire [11:0] dino_pixel = sprite_color(dino_index);
    wire dino_sprite_on = dino_box_on && (dino_index != 2'b00);

    wire render_single_cactus = (render_obs_type == CACTUS);
    wire render_double_left =
        (render_obs_type == DOUBLE_CACTUS) && (render_obs_rel_x < 7'd28);
    wire render_double_right =
        (render_obs_type == DOUBLE_CACTUS) &&
        (render_obs_rel_x >= 7'd32) && (render_obs_rel_x < 7'd60);
    wire render_cactus = render_single_cactus || render_double_left || render_double_right;

    wire [5:0] cactus_rel_x =
        render_double_right ? (render_obs_rel_x - 7'd32) : render_obs_rel_x[5:0];

    wire [10:0] cactus_pixel_addr =
        (render_obs_rel_y * 11'd28) + cactus_rel_x;

    wire [7:0] cactus_word_addr = cactus_pixel_addr[10:3];
    wire [15:0] cactus_word = cactus_mem[cactus_word_addr];
    wire [1:0] cactus_index = packed_pixel(cactus_word, cactus_pixel_addr[2:0]);

    wire render_bird =
        (render_obs_type == HIGH_BIRD) || (render_obs_type == LOW_BIRD);

    wire [10:0] bird_pixel_addr =
        (render_obs_rel_y * 11'd46) + render_obs_rel_x;

    wire [7:0] bird_word_addr = bird_pixel_addr[10:3];
    wire [15:0] bird_word =
        anim_frame ? bird1_mem[bird_word_addr] : bird0_mem[bird_word_addr];
    wire [1:0] bird_index = packed_pixel(bird_word, bird_pixel_addr[2:0]);

    wire [1:0] obstacle_index =
        render_bird ? bird_index :
        render_cactus ? cactus_index : 2'b00;

    wire [11:0] obstacle_pixel = sprite_color(obstacle_index);
    wire obstacle_sprite_on =
        render_obs_box_on && (obstacle_index != 2'b00);

    always @(posedge pixel_clk) begin
        if (!inDisplayArea) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
        else begin
            case (game_state)
                MENU: begin
                    if (menu_box) begin
                        vga_r <= 4'h2;
                        vga_g <= 4'h6;
                        vga_b <= 4'hF;
                    end
                    else begin
                        vga_r <= 4'hF;
                        vga_g <= 4'hF;
                        vga_b <= 4'hF;
                    end
                end

                PLAYING: begin
                    vga_r <= 4'hF;
                    vga_g <= 4'hF;
                    vga_b <= 4'hF;

                    if (dino_sprite_on) begin
                        vga_r <= dino_pixel[11:8];
                        vga_g <= dino_pixel[7:4];
                        vga_b <= dino_pixel[3:0];
                    end
                    else if (obstacle_sprite_on) begin
                        vga_r <= obstacle_pixel[11:8];
                        vga_g <= obstacle_pixel[7:4];
                        vga_b <= obstacle_pixel[3:0];
                    end
                    else if (ground_on) begin
                        vga_r <= 4'h7;
                        vga_g <= 4'h7;
                        vga_b <= 4'h7;
                    end
                end

                GAME_OVER: begin
                    if (dino_sprite_on) begin
                        vga_r <= dino_pixel[11:8];
                        vga_g <= dino_pixel[7:4];
                        vga_b <= dino_pixel[3:0];
                    end
                    else if (obstacle_sprite_on) begin
                        vga_r <= obstacle_pixel[11:8];
                        vga_g <= obstacle_pixel[7:4];
                        vga_b <= obstacle_pixel[3:0];
                    end
                    else if (ground_on) begin
                        vga_r <= 4'h7;
                        vga_g <= 4'h7;
                        vga_b <= 4'h7;
                    end
                    else if (gameover_box) begin
                        vga_r <= 4'hA;
                        vga_g <= 4'h0;
                        vga_b <= 4'h0;
                    end
                    else begin
                        vga_r <= 4'hF;
                        vga_g <= 4'h9;
                        vga_b <= 4'h9;
                    end
                end

                WIN: begin
                    if (gameover_box) begin
                        vga_r <= 4'h0;
                        vga_g <= 4'h8;
                        vga_b <= 4'h0;
                    end
                    else begin
                        vga_r <= 4'h9;
                        vga_g <= 4'hF;
                        vga_b <= 4'h9;
                    end
                end

                default: begin
                    vga_r <= 4'h0;
                    vga_g <= 4'h0;
                    vga_b <= 4'h0;
                end
            endcase
        end
    end

endmodule
