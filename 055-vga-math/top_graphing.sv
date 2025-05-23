// Project F: Maths Demo - Graphing (Arty Pmod VGA)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_graphing (
    input  wire logic clk_10m,      // 10 MHz clock
    input  wire logic btn_rst_n,    // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_10m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       /* verilator lint_off PINCONNECTEMPTY */
       .clk_pix_5x(),  // not used for VGA output
       /* verilator lint_on PINCONNECTEMPTY */
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 12;
    logic hsync, vsync;
    logic [CORDW-1:0] sx, sy;
    logic de;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        /* verilator lint_off PINCONNECTEMPTY */
        .frame(),
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // signal when to draw mathematical function and axis
    logic draw, axes;

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= !de ? 4'h0 : (axes ? 4'hC : (draw ? 4'h3 : 4'h2));
        vga_g <= !de ? 4'h0 : (axes ? 4'hC : (draw ? 4'hB : 4'h2));
        vga_b <= !de ? 4'h0 : (axes ? 4'hC : (draw ? 4'hC : 4'h2));
    end


    //
    // Graphing Logic
    //

    // function coordinates
    logic signed [CORDW-1:0] x, y;

    // adjust screen coordinates so (0,0) is at centre of screen
    localparam X_OFFS = 320;
    localparam Y_OFFS = 239;
    always_ff @(posedge clk_pix) begin
        x <= sx - X_OFFS + 4;  // latency for function (+n) and offset calculation (+1)
        y <= Y_OFFS - sy;
    end

    // draw X and Y axes
    logic x_axis, y_axis;
    always_comb begin
        x_axis = (sy == Y_OFFS);
        y_axis = (sx == X_OFFS);
        axes = x_axis || y_axis;
    end

    // function to graph
    func_squared #(.CORDW(CORDW)) func_inst (
        .clk(clk_pix),
        .x,
        .y,
        .r(draw)
    );
endmodule
