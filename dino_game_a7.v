`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EE354 Dino Game - first playable VGA prototype
// Nexys A7, 640x480 VGA
//
// Controls:
//   BTNL : start / restart from menu or game-over
//   BTNU : jump
//   BTNC : reset to menu
//   SW0  : reset to menu (kept from the VGA demo)
//
// This version intentionally uses simple rectangles.
// Once gameplay works, sprites can replace the rectangle renderer.
//////////////////////////////////////////////////////////////////////////////////

module dino_game_a7(
    input  wire       ClkPort,
    input  wire       Sw0,
    input  wire       btnU,
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

    // -------------------------------------------------------------------------
    // VGA clock generation
    // 100 MHz board clock / 4 = 25 MHz VGA pixel clock
    // -------------------------------------------------------------------------
    reg [27:0] DIV_CLK = 28'd0;

    always @(posedge board_clk or posedge reset) begin
        if (reset)
            DIV_CLK <= 28'd0;
        else
            DIV_CLK <= DIV_CLK + 1'b1;
    end

    wire pixel_clk = DIV_CLK[1];

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

    // One pulse per complete VGA frame (~60 Hz)
    wire frame_tick = (CounterX == 10'd799) && (CounterY == 10'd520);

    // -------------------------------------------------------------------------
    // Game constants
    // -------------------------------------------------------------------------
    localparam [9:0] GROUND_Y      = 10'd420;

    localparam [9:0] DINO_X        = 10'd80;
    localparam [9:0] DINO_W        = 10'd32;
    localparam [9:0] DINO_H        = 10'd40;
    localparam [9:0] DINO_GROUND_Y = GROUND_Y - DINO_H;   // top-left Y = 380

    localparam [9:0] CACTUS_W      = 10'd20;
    localparam [9:0] CACTUS_H      = 10'd45;
    localparam [9:0] CACTUS_Y      = GROUND_Y - CACTUS_H; // top-left Y = 375
    localparam [9:0] CACTUS_START_X= 10'd620;

    localparam [9:0] CACTUS_SPEED  = 10'd4;

    // -------------------------------------------------------------------------
    // Game states
    // -------------------------------------------------------------------------
    localparam [1:0] MENU      = 2'b00;
    localparam [1:0] PLAYING   = 2'b01;
    localparam [1:0] GAME_OVER = 2'b10;

    reg [1:0] game_state = MENU;

    // -------------------------------------------------------------------------
    // Dino / obstacle registers
    // -------------------------------------------------------------------------
    reg [9:0] dino_y = DINO_GROUND_Y;
    reg [5:0] jump_phase = 6'd0;   // 0 = not jumping
    reg [9:0] cactus_x = CACTUS_START_X;
    reg [15:0] score = 16'd0;

    // Button history for simple edge detection.
    // Sampling once per frame also acts as a crude debounce for this prototype.
    reg btnU_prev = 1'b0;
    reg btnL_prev = 1'b0;

    wire jump_pressed  = btnU & ~btnU_prev;
    wire start_pressed = btnL & ~btnL_prev;

    // Current-frame collision box overlap.
    wire collision =
        (DINO_X < (cactus_x + CACTUS_W)) &&
        ((DINO_X + DINO_W) > cactus_x) &&
        (dino_y < (CACTUS_Y + CACTUS_H)) &&
        ((dino_y + DINO_H) > CACTUS_Y);

    // -------------------------------------------------------------------------
    // Game update: once per VGA frame
    // -------------------------------------------------------------------------
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            game_state <= MENU;
            dino_y <= DINO_GROUND_Y;
            jump_phase <= 6'd0;
            cactus_x <= CACTUS_START_X;
            score <= 16'd0;
            btnU_prev <= 1'b0;
            btnL_prev <= 1'b0;
        end
        else if (frame_tick) begin
            // sample buttons once per frame
            btnU_prev <= btnU;
            btnL_prev <= btnL;

            case (game_state)

                MENU: begin
                    dino_y <= DINO_GROUND_Y;
                    jump_phase <= 6'd0;
                    cactus_x <= CACTUS_START_X;
                    score <= 16'd0;

                    if (start_pressed)
                        game_state <= PLAYING;
                end

                PLAYING: begin
                    // -------------------------
                    // Jump control
                    // -------------------------
                    if ((jump_phase == 0) && jump_pressed) begin
                        jump_phase <= 6'd1;
                    end
                    else if (jump_phase != 0) begin
                        if (jump_phase <= 6'd8) begin
                            // rise quickly
                            dino_y <= dino_y - 10'd4;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd16) begin
                            // rise slowly near the top
                            dino_y <= dino_y - 10'd2;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd24) begin
                            // fall slowly
                            dino_y <= dino_y + 10'd2;
                            jump_phase <= jump_phase + 1'b1;
                        end
                        else if (jump_phase <= 6'd32) begin
                            // fall quickly
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

                    // -------------------------
                    // Cactus movement
                    // -------------------------
                    if (cactus_x <= CACTUS_SPEED) begin
                        cactus_x <= CACTUS_START_X;
                        score <= score + 1'b1;
                    end
                    else begin
                        cactus_x <= cactus_x - CACTUS_SPEED;
                    end

                    // -------------------------
                    // Lose condition
                    // -------------------------
                    if (collision)
                        game_state <= GAME_OVER;
                end

                GAME_OVER: begin
                    // Freeze the scene until BTNL is pressed again.
                    if (start_pressed) begin
                        game_state <= PLAYING;
                        dino_y <= DINO_GROUND_Y;
                        jump_phase <= 6'd0;
                        cactus_x <= CACTUS_START_X;
                        score <= 16'd0;
                    end
                end

                default: game_state <= MENU;

            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Pixel renderer
    // -------------------------------------------------------------------------
    wire ground_on =
        (CounterY >= GROUND_Y) &&
        (CounterY < (GROUND_Y + 10'd4));

    wire dino_on =
        (CounterX >= DINO_X) &&
        (CounterX < (DINO_X + DINO_W)) &&
        (CounterY >= dino_y) &&
        (CounterY < (dino_y + DINO_H));

    wire cactus_on =
        (CounterX >= cactus_x) &&
        (CounterX < (cactus_x + CACTUS_W)) &&
        (CounterY >= CACTUS_Y) &&
        (CounterY < (CACTUS_Y + CACTUS_H));

    // Simple menu/game-over boxes so state changes are obvious without font ROM.
    wire menu_box =
        (CounterX >= 10'd180) && (CounterX < 10'd460) &&
        (CounterY >= 10'd180) && (CounterY < 10'd300);

    wire gameover_box =
        (CounterX >= 10'd160) && (CounterX < 10'd480) &&
        (CounterY >= 10'd170) && (CounterY < 10'd310);

    always @(posedge pixel_clk) begin
        if (!inDisplayArea) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
        else begin
            case (game_state)

                MENU: begin
                    // white background, blue menu rectangle
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
                    // white background
                    vga_r <= 4'hF;
                    vga_g <= 4'hF;
                    vga_b <= 4'hF;

                    // black/dark dinosaur
                    if (dino_on) begin
                        vga_r <= 4'h1;
                        vga_g <= 4'h1;
                        vga_b <= 4'h1;
                    end
                    // green cactus
                    else if (cactus_on) begin
                        vga_r <= 4'h1;
                        vga_g <= 4'hA;
                        vga_b <= 4'h2;
                    end
                    // gray ground
                    else if (ground_on) begin
                        vga_r <= 4'h7;
                        vga_g <= 4'h7;
                        vga_b <= 4'h7;
                    end
                end

                GAME_OVER: begin
                    // light red background with dark red center box
                    if (gameover_box) begin
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
