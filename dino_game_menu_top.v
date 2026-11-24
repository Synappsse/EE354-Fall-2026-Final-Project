`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EE354 Dino Jump - menu wrapper
//
// IMPORTANT:
//   This module does not modify dino_game_a7.v.
//   It sits in front of the existing game, displays the hand-drawn menu image,
//   and uses BTNC to enter/return to the menu.
//
// Vivado top module: dino_game_menu_top
//
// Existing controls inside dino_game_a7 remain unchanged:
//   BTNU = jump
//   BTND = duck
//   BTNL = restart from game-over
//   SW0  = hardware reset
//
// Wrapper behavior:
//   Power-up / SW0 -> hand-drawn menu
//   BTNC on menu   -> start the existing game
//   BTNC in game   -> return to the hand-drawn menu
//////////////////////////////////////////////////////////////////////////////////

module dino_game_menu_top(
    input  wire       ClkPort,
    input  wire       Sw0,
    input  wire       btnU,
    input  wire       btnD,
    input  wire       btnL,
    input  wire       btnC,

    output wire       vga_h_sync,
    output wire       vga_v_sync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);

    // -------------------------------------------------------------------------
    // Debounce BTNC without changing the existing game's source.
    // -------------------------------------------------------------------------
    wire btnC_DPB;

    ee354_debouncer #(.N_dc(28)) menu_button_debouncer (
        .CLK(ClkPort),
        .RESET(Sw0),
        .PB(btnC),
        .DPB(btnC_DPB),
        .SCEN(),
        .MCEN(),
        .CCEN()
    );

    // -------------------------------------------------------------------------
    // Wrapper state
    // -------------------------------------------------------------------------
    localparam [1:0] WRAP_MENU       = 2'd0;
    localparam [1:0] WRAP_STARTING   = 2'd1;
    localparam [1:0] WRAP_GAME       = 2'd2;
    localparam [1:0] WRAP_MENU_RESET = 2'd3;

    reg [1:0] wrapper_state = WRAP_MENU;
    reg [22:0] start_hold_count = 23'd0;

    // Hold the injected start level for at least 30 ms.
    // This guarantees dino_game_a7 sees it on a ~60 Hz frame tick.
    localparam [22:0] START_HOLD_CYCLES = 23'd3000000;

    always @(posedge ClkPort or posedge Sw0) begin
        if (Sw0) begin
            wrapper_state <= WRAP_MENU;
            start_hold_count <= 23'd0;
        end
        else begin
            case (wrapper_state)
                WRAP_MENU: begin
                    start_hold_count <= 23'd0;
                    if (btnC_DPB)
                        wrapper_state <= WRAP_STARTING;
                end

                WRAP_STARTING: begin
                    if (start_hold_count < START_HOLD_CYCLES)
                        start_hold_count <= start_hold_count + 1'b1;
                    else if (!btnC_DPB)
                        wrapper_state <= WRAP_GAME;
                end

                WRAP_GAME: begin
                    start_hold_count <= 23'd0;
                    if (btnC_DPB)
                        wrapper_state <= WRAP_MENU_RESET;
                end

                WRAP_MENU_RESET: begin
                    start_hold_count <= 23'd0;
                    if (!btnC_DPB)
                        wrapper_state <= WRAP_MENU;
                end

                default: begin
                    wrapper_state <= WRAP_MENU;
                    start_hold_count <= 23'd0;
                end
            endcase
        end
    end

    wire show_menu = (wrapper_state == WRAP_MENU) ||
                     (wrapper_state == WRAP_STARTING) ||
                     (wrapper_state == WRAP_MENU_RESET);

    // While starting, drive the existing game's normal BTNL input high.
    // No changes are needed inside dino_game_a7.
    wire game_btnL = btnL | (wrapper_state == WRAP_STARTING);

    // When returning to the menu, pulse/hold the existing game's BTNC reset.
    // This resets the existing game back to its own MENU state so it is ready
    // for the next start.
    wire game_btnC = (wrapper_state == WRAP_MENU_RESET) ? btnC_DPB : 1'b0;

    // -------------------------------------------------------------------------
    // Existing game - instantiated unchanged.
    // -------------------------------------------------------------------------
    wire       game_h_sync;
    wire       game_v_sync;
    wire [3:0] game_r;
    wire [3:0] game_g;
    wire [3:0] game_b;

    dino_game_a7 existing_game (
        .ClkPort(ClkPort),
        .Sw0(Sw0),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(game_btnL),
        .btnC(game_btnC),
        .vga_h_sync(game_h_sync),
        .vga_v_sync(game_v_sync),
        .vga_r(game_r),
        .vga_g(game_g),
        .vga_b(game_b)
    );

    // -------------------------------------------------------------------------
    // Menu VGA scan generator.
    // It uses the same 25 MHz timing as the existing game.
    // -------------------------------------------------------------------------
    wire menu_scan_reset = Sw0;

    reg [27:0] MENU_DIV_CLK = 28'd0;

    always @(posedge ClkPort or posedge menu_scan_reset) begin
        if (menu_scan_reset)
            MENU_DIV_CLK <= 28'd0;
        else
            MENU_DIV_CLK <= MENU_DIV_CLK + 1'b1;
    end

    wire menu_pixel_clk = MENU_DIV_CLK[1];

    wire       menu_inDisplayArea;
    wire [9:0] menu_x;
    wire [9:0] menu_y;
    wire       menu_h_sync;
    wire       menu_v_sync;

    hvsync_generator menu_syncgen (
        .clk(menu_pixel_clk),
        .reset(menu_scan_reset),
        .vga_h_sync(menu_h_sync),
        .vga_v_sync(menu_v_sync),
        .inDisplayArea(menu_inDisplayArea),
        .CounterX(menu_x),
        .CounterY(menu_y)
    );

    // -------------------------------------------------------------------------
    // Hand-drawn menu image ROM
    //
    // Source is reduced to 160x120 and shown 4x larger -> 640x480.
    // Four 4-bit palette indices are packed into every 16-bit ROM word.
    // 160*120/4 = 4800 words = 76,800 bits.
    // -------------------------------------------------------------------------
    // Split into three ROM banks so the image data stays manageable.
    reg [15:0] menu_mem0 [0:2047];
    reg [15:0] menu_mem1 [0:2047];
    reg [15:0] menu_mem2 [0:703];

    initial begin
        $readmemh("menu_palette_bank0.mem", menu_mem0);
        $readmemh("menu_palette_bank1.mem", menu_mem1);
        $readmemh("menu_palette_bank2.mem", menu_mem2);
    end

    wire [7:0] menu_row = menu_y[9:2];
    wire [7:0] menu_col = menu_x[9:2];

    // row*160 + col = row*128 + row*32 + col
    wire [14:0] menu_pixel_addr =
        ({7'd0, menu_row} << 7) +
        ({7'd0, menu_row} << 5) +
        {7'd0, menu_col};

    wire [12:0] menu_word_addr = menu_pixel_addr[14:2];
    wire [1:0]  menu_nibble_sel = menu_pixel_addr[1:0];

    reg [15:0] menu_word;
    reg [1:0]  menu_nibble_sel_d;

    always @(posedge menu_pixel_clk) begin
        if (menu_word_addr < 13'd2048)
            menu_word <= menu_mem0[menu_word_addr[10:0]];
        else if (menu_word_addr < 13'd4096)
            menu_word <= menu_mem1[menu_word_addr[10:0]];
        else
            menu_word <= menu_mem2[menu_word_addr - 13'd4096];

        menu_nibble_sel_d <= menu_nibble_sel;
    end

    reg [3:0] menu_palette_index;

    always @(*) begin
        case (menu_nibble_sel_d)
            2'd0: menu_palette_index = menu_word[15:12];
            2'd1: menu_palette_index = menu_word[11:8];
            2'd2: menu_palette_index = menu_word[7:4];
            2'd3: menu_palette_index = menu_word[3:0];
            default: menu_palette_index = 4'd0;
        endcase
    end

    reg [11:0] menu_color;

    // 12-bit VGA palette: RRRR_GGGG_BBBB
    always @(*) begin
        case (menu_palette_index)
            4'h0: menu_color = 12'hC96;
            4'h1: menu_color = 12'hB66;
            4'h2: menu_color = 12'hB48;
            4'h3: menu_color = 12'h748;
            4'h4: menu_color = 12'h839;
            4'h5: menu_color = 12'h639;
            4'h6: menu_color = 12'h639;
            4'h7: menu_color = 12'h639;
            4'h8: menu_color = 12'h639;
            4'h9: menu_color = 12'h929;
            4'hA: menu_color = 12'h719;
            4'hB: menu_color = 12'h719;
            4'hC: menu_color = 12'h619;
            4'hD: menu_color = 12'h518;
            4'hE: menu_color = 12'h418;
            4'hF: menu_color = 12'h418;
            default: menu_color = 12'h000;
        endcase
    end

    wire [3:0] menu_r = menu_inDisplayArea ? menu_color[11:8] : 4'h0;
    wire [3:0] menu_g = menu_inDisplayArea ? menu_color[7:4]  : 4'h0;
    wire [3:0] menu_b = menu_inDisplayArea ? menu_color[3:0]  : 4'h0;

    // -------------------------------------------------------------------------
    // Final VGA mux
    // -------------------------------------------------------------------------
    assign vga_h_sync = show_menu ? menu_h_sync : game_h_sync;
    assign vga_v_sync = show_menu ? menu_v_sync : game_v_sync;

    assign vga_r = show_menu ? menu_r : game_r;
    assign vga_g = show_menu ? menu_g : game_g;
    assign vga_b = show_menu ? menu_b : game_b;

endmodule