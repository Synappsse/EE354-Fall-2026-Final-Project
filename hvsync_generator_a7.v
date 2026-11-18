//////////////////////////////////////////////////////////////////////////////////
// 640x480 VGA sync generator for 25 MHz pixel clock
// Course timing:
// Horizontal total = 800 clocks: 640 display + 16 front + 96 sync + 48 back
// Vertical total   = 521 lines:  480 display + 10 front + 2 sync + 29 back
//////////////////////////////////////////////////////////////////////////////////

module hvsync_generator(
    input  wire       clk,
    input  wire       reset,
    output wire       vga_h_sync,
    output wire       vga_v_sync,
    output reg        inDisplayArea,
    output reg  [9:0] CounterX,
    output reg  [9:0] CounterY
);

    reg vga_HS;
    reg vga_VS;

    // Horizontal: 0..799
    always @(posedge clk) begin
        if (reset)
            CounterX <= 10'd0;
        else if (CounterX == 10'd799)
            CounterX <= 10'd0;
        else
            CounterX <= CounterX + 1'b1;
    end

    // Vertical: 0..520, advance once per completed horizontal line
    always @(posedge clk) begin
        if (reset)
            CounterY <= 10'd0;
        else if (CounterX == 10'd799) begin
            if (CounterY == 10'd520)
                CounterY <= 10'd0;
            else
                CounterY <= CounterY + 1'b1;
        end
    end

    // Active-low sync outputs:
    // HS low for x = 656..751 (96 pixel clocks)
    // VS low for y = 490..491 (2 lines)
    always @(posedge clk) begin
        if (reset) begin
            vga_HS <= 1'b0;
            vga_VS <= 1'b0;
        end
        else begin
            vga_HS <= (CounterX >= 10'd656 && CounterX <= 10'd751);
            vga_VS <= (CounterY >= 10'd490 && CounterY <= 10'd491);
        end
    end

    always @(posedge clk) begin
        if (reset)
            inDisplayArea <= 1'b0;
        else
            inDisplayArea <= (CounterX < 10'd640) && (CounterY < 10'd480);
    end

    assign vga_h_sync = ~vga_HS;
    assign vga_v_sync = ~vga_VS;

endmodule
