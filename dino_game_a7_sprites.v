timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EE354 Dino Game - sprite-rendered branch version
//
// This is intentionally a NEW module so the partner-authored dino_game_a7.v
// remains untouched on main.
//
// Behavior retained from dino_game_a7:
//   - BTNL start/restart
//   - BTNU jump (debounced)
//   - BTND duck (debounced)
//   - BTNC reset
//   - SW0 reset
//   - same jump timing, score behavior, and obstacle speed
//
// Added here:
//   - 2-frame running dinosaur sprite
//   - 2-frame ducking dinosaur sprite
//   - cactus sprite
//   - 2-frame flying bird sprite
//   - obstacles alternate cactus / bird when they respawn
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

    localparam [9:0] CACTUS_W = 10'd28;
    localparam [9:0] CACTUS_H = 10'd46;
    localparam [9:0] CACTUS_Y = GROUND_Y - CACTUS_H;

    localparam [9:0] BIRD_W = 10'd46;
    localparam [9:0] BIRD_H = 10'd24;
    localparam [9:0] BIRD_Y = 10'd356;

    localparam [9:0] OBSTACLE_START_X = 10'd620;

    reg [9:0] cactus_speed = 10'd4;

    localparam [1:0] MENU      = 2'b00;
    localparam [1:0] PLAYING   = 2'b01;
    localparam [1:0] GAME_OVER = 2'b10;

    reg [1:0] game_state = MENU;

    reg [9:0] dino_y = DINO_GROUND_Y;
    reg [5:0] jump_phase = 6'd0;
    reg [9:0] obstacle_x = OBSTACLE_START_X;
    reg       obstacle_is_bird = 1'b0;
    reg [15:0] score = 16'd0;

    reg [2:0] anim_count = 3'd0;
    reg       anim_frame = 1'b0;

    reg btnL_prev = 1'b0;
    wire start_pressed = btnL & ~btnL_prev;

    wire [9:0] current_obstacle_w =
        obstacle_is_bird ? BIRD_W : CACTUS_W;

    wire [9:0] current_obstacle_h =
        obstacle_is_bird ? BIRD_H : CACTUS_H;

    wire [9:0] current_obstacle_y =
        obstacle_is_bird ? BIRD_Y : CACTUS_Y;

    wire collision =
        (DINO_X < (obstacle_x + current_obstacle_w)) &&
        ((DINO_X + current_dino_w) > obstacle_x) &&
        (current_dino_y < (current_obstacle_y + current_obstacle_h)) &&
        ((current_dino_y + current_dino_h) > current_obstacle_y);

    always @(posedge pixel_clk, posedge reset) begin
        if (reset) begin
            game_state <= MENU;
            dino_y <= DINO_GROUND_Y;
            jump_phase <= 6'd0;
            obstacle_x <= OBSTACLE_START_X;
            obstacle_is_bird <= 1'b0;
            score <= 16'd0;
            btnL_prev <= 1'b0;
            cactus_speed <= 10'd4;
            anim_count <= 3'd0;
            anim_frame <= 1'b0;
        end
        else if (frame_tick) begin
            btnL_prev <= btnL;

            case (game_state)

                MENU: begin
                    dino_y <= DINO_GROUND_Y;
                    jump_phase <= 6'd0;
                    obstacle_x <= OBSTACLE_START_X;
                    obstacle_is_bird <= 1'b0;
                    score <= 16'd0;
                    cactus_speed <= 10'd4;
                    anim_count <= 3'd0;
                    anim_frame <= 1'b0;

                    if (start_pressed)
                        game_state <= PLAYING;
                end

                PLAYING: begin
                    score <= score + 1'b1;

                    if (anim_count == 3'd7) begin
                        anim_count <= 3'd0;
                        anim_frame <= ~anim_frame;
                    end
                    else begin
                        anim_count <= anim_count + 1'b1;
                    end

                    if ((jump_phase == 0) && jump_DPB) begin
                        jump_phase <= 6'd1;
                    end
                    else if (jump_phase != 0) begin
                        if (jump_phase <= 6'd8) begin
                            dino_y <= dino_y - 10'd4;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd16) begin
                            dino_y <= dino_y - 10'd2;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd24) begin
                            dino_y <= dino_y + 10'd2;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd32) begin
                            dino_y <= dino_y + 10'd4;
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

                    if (obstacle_x <= cactus_speed) begin
                        obstacle_x <= OBSTACLE_START_X;
                        obstacle_is_bird <= ~obstacle_is_bird;
                    end
                    else begin
                        obstacle_x <= obstacle_x - cactus_speed;
                    end

                    if (collision)
                        game_state <= GAME_OVER;
                end

                GAME_OVER: begin
                    if (start_pressed) begin
                        game_state <= PLAYING;
                        dino_y <= DINO_GROUND_Y;
                        jump_phase <= 6'd0;
                        obstacle_x <= OBSTACLE_START_X;
                        obstacle_is_bird <= 1'b0;
                        score <= 16'd0;
                        anim_count <= 3'd0;
                        anim_frame <= 1'b0;
                    end
                end

                default: game_state <= MENU;

            endcase
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

    wire ground_on =
        (CounterY >= GROUND_Y) &&
        (CounterY < (GROUND_Y + 10'd4));

    wire dino_box_on =
        (CounterX >= DINO_X) &&
        (CounterX < (DINO_X + current_dino_w)) &&
        (CounterY >= current_dino_y) &&
        (CounterY < (current_dino_y + current_dino_h));

    wire obstacle_box_on =
        (CounterX >= obstacle_x) &&
        (CounterX < (obstacle_x + current_obstacle_w)) &&
        (CounterY >= current_obstacle_y) &&
        (CounterY < (current_obstacle_y + current_obstacle_h));

    wire menu_box =
        (CounterX >= 10'd180) && (CounterX < 10'd460) &&
        (CounterY >= 10'd180) && (CounterY < 10'd300);

    wire gameover_box =
        (CounterX >= 10'd160) && (CounterX < 10'd480) &&
        (CounterY >= 10'd170) && (CounterY < 10'd310);

    wire [6:0] dino_rel_x =
        dino_box_on ? (CounterX - DINO_X) : 7'd0;

    wire [6:0] dino_rel_y =
        dino_box_on ? (CounterY - current_dino_y) : 7'd0;

    wire [6:0] obstacle_rel_x =
        obstacle_box_on ? (CounterX - obstacle_x) : 7'd0;

    wire [6:0] obstacle_rel_y =
        obstacle_box_on ? (CounterY - current_obstacle_y) : 7'd0;

    wire [11:0] run_pixel_addr =
        (dino_rel_y * 12'd44) + dino_rel_x;

    wire [11:0] duck_pixel_addr =
        (dino_rel_y * 12'd59) + dino_rel_x;

    wire [10:0] cactus_pixel_addr =
        (obstacle_rel_y * 11'd28) + obstacle_rel_x;

    wire [10:0] bird_pixel_addr =
        (obstacle_rel_y * 11'd46) + obstacle_rel_x;

    wire [8:0] run_word_addr = run_pixel_addr[11:3];
    wire [7:0] duck_word_addr = duck_pixel_addr[11:3];
    wire [7:0] cactus_word_addr = cactus_pixel_addr[10:3];
    wire [7:0] bird_word_addr = bird_pixel_addr[10:3];

    wire [15:0] run_word =
        anim_frame ? dino_run1_mem[run_word_addr] : dino_run0_mem[run_word_addr];

    wire [15:0] duck_word =
        anim_frame ? dino_duck1_mem[duck_word_addr] : dino_duck0_mem[duck_word_addr];

    wire [15:0] cactus_word = cactus_mem[cactus_word_addr];

    wire [15:0] bird_word =
        anim_frame ? bird1_mem[bird_word_addr] : bird0_mem[bird_word_addr];

    wire [1:0] run_index =
        packed_pixel(run_word, run_pixel_addr[2:0]);

    wire [1:0] duck_index =
        packed_pixel(duck_word, duck_pixel_addr[2:0]);

    wire [1:0] cactus_index =
        packed_pixel(cactus_word, cactus_pixel_addr[2:0]);

    wire [1:0] bird_index =
        packed_pixel(bird_word, bird_pixel_addr[2:0]);

    wire [1:0] dino_index =
        duck_DPB ? duck_index : run_index;

    wire [1:0] obstacle_index =
        obstacle_is_bird ? bird_index : cactus_index;

    wire [11:0] dino_pixel = sprite_color(dino_index);
    wire [11:0] obstacle_pixel = sprite_color(obstacle_index);

    wire dino_sprite_on =
        dino_box_on && (dino_index != 2'b00);

    wire obstacle_sprite_on =
        obstacle_box_on && (obstacle_index != 2'b00);

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

                default: begin
                    vga_r <= 4'h0;
                    vga_g <= 4'h0;
                    vga_b <= 4'h0;
                end

            endcase
        end
    end

endmodule
