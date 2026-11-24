`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EE354 Dino Game - first playable VGA prototype
// Nexys A7, 640x480 VGA
//
// Controls:
//   BTNL : start / restart from menu or game-over
//   BTNU : jump
//   BTND : duck
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

    // score increment
    

    wire pixel_clk = DIV_CLK[1];
    wire game_tick = DIV_CLK[23];

    // Debounced button outputs
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

    // -------------------------------------------------------------------------
    // Button debouncers
    // -------------------------------------------------------------------------

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

    // One pulse per complete VGA frame (~60 Hz)
    wire frame_tick = (CounterX == 10'd799) && (CounterY == 10'd520);

    // -------------------------------------------------------------------------
    // Game constants
    // -------------------------------------------------------------------------
    localparam [9:0] GROUND_Y      = 10'd420; // ground y pos

    localparam [9:0] DINO_X        = 10'd80; // dino x, fixed cuz background moves
    // Normal dinosaur dimensions
    localparam [9:0] DINO_W = 10'd32;
    localparam [9:0] DINO_H = 10'd40;
    localparam [9:0] DINO_GROUND_Y = GROUND_Y - DINO_H; // top


    // Ducking dinosaur dimensions
    localparam [9:0] DINO_DUCK_W = 10'd40;
    localparam [9:0] DINO_DUCK_H = 10'd20;
    localparam [9:0] DINO_DUCK_GROUND_Y = GROUND_Y - DINO_DUCK_H; // top

    wire [9:0] current_dino_w =
        duck_DPB ? DINO_DUCK_W : DINO_W;

    wire [9:0] current_dino_h =
        duck_DPB ? DINO_DUCK_H : DINO_H;

    wire [9:0] current_dino_ground_y =
        duck_DPB ? DINO_DUCK_GROUND_Y : DINO_GROUND_Y;

    wire [9:0] current_dino_y =
        current_dino_ground_y - (DINO_GROUND_Y - dino_y);


    localparam [9:0] CACTUS_W      = 10'd20;
    localparam [9:0] CACTUS_H      = 10'd45;
    localparam [9:0] CACTUS_Y      = GROUND_Y - CACTUS_H; // top-left Y = 375
    localparam [9:0] CACTUS_START_X= 10'd620;

    reg [9:0] cactus_speed  = 10'd4; // varies

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

    // Simple edge detection for start button
    reg btnL_prev = 1'b0;

    wire start_pressed = btnL & ~btnL_prev;

    // Current-frame collision box overlap.
    wire collision =
        (DINO_X < (cactus_x + CACTUS_W)) && // ensures dino is on the left of cactus
        ((DINO_X + current_dino_w) > cactus_x) && // dino right > cactus left
        (current_dino_y < (CACTUS_Y + CACTUS_H)) && // dino top < cactus bottom (isn't already in cactus)
        ((current_dino_y + current_dino_h) > CACTUS_Y); // dino bottom > cactus top

    // -------------------------------------------------------------------------
    // Game update: once per VGA frame
    // -------------------------------------------------------------------------
    always @(posedge pixel_clk, posedge reset) begin
        if (reset) begin
            game_state <= MENU;
            dino_y <= DINO_GROUND_Y;
            jump_phase <= 6'd0;
            cactus_x <= CACTUS_START_X;
            score <= 16'd0;
            btnL_prev <= 1'b0;
            cactus_speed  <= 10'd4;
        end
        else if (frame_tick) begin
            // sample buttons once per frame
            btnL_prev <= btnL;

            case (game_state)

                MENU: begin
                    dino_y <= DINO_GROUND_Y;
                    jump_phase <= 6'd0;
                    cactus_x <= CACTUS_START_X;
                    score <= 16'd0;
                    cactus_speed  <= 10'd4;
                    if (start_pressed)
                        game_state <= PLAYING;
                end

                PLAYING: begin
                    // increment score 
                    score <= score + 1'b1;
                    // increment cactus_speed

                    // -------------------------
                    // Jump control - do a jump every time the button is pressed + continuously jump when held
                    // -------------------------
                    if ((jump_phase == 0) && jump_DPB) begin
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
                    if (cactus_x <= cactus_speed) begin
                        cactus_x <= CACTUS_START_X;
                    end
                    else begin
                        cactus_x <= cactus_x - cactus_speed;
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
        (CounterX < (DINO_X + current_dino_w)) &&
        (CounterY >= current_dino_y) &&
        (CounterY < (current_dino_y + current_dino_h));

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
