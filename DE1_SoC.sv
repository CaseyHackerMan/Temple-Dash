/* Top level module of the FPGA that takes the onboard resources 
 * as input and outputs the lines drawn from the VGA port.
 *
 * Inputs:
 *   KEY 			- On board keys of the FPGA
 *   SW 			- On board switches of the FPGA
 *   CLOCK_50 		- On board 50 MHz clock of the FPGA
 *
 * Outputs:
 *   HEX 			- On board 7 segment displays of the FPGA
 *   LEDR 			- On board LEDs of the FPGA
 *   VGA_R 			- Red data of the VGA connection
 *   VGA_G 			- Green data of the VGA connection
 *   VGA_B 			- Blue data of the VGA connection
 *   VGA_BLANK_N 	- Blanking interval of the VGA connection
 *   VGA_CLK 		- VGA's clock signal
 *   VGA_HS 		- Horizontal Sync of the VGA connection
 *   VGA_SYNC_N 	- Enable signal for the sync of the VGA connection
 *   VGA_VS 		- Vertical Sync of the VGA connection
 */

`timescale 1 ps / 1 ps
module DE1_SoC (output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
	            output [9:0] LEDR,
				input CLOCK_50, 
				inout [35:0] V_GPIO,
				// input [35:0] V_GPIO,
				output [7:0] VGA_R, VGA_G, VGA_B,
				output VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS);
	
	logic reset, white, frame_clk, fb1q, fb2q, buf_sel, in_bounds, frame, game_over;
	logic signed [10:0] x, y, pre_x, pre_y;
	logic [7:0] vga_red, vga_green, vga_blue;
	logic signed [7:0] joyX, joyY;
	logic [9:0] vga_x;
	logic [8:0] vga_y;
	logic [7:0] score;
	logic [1:0] speed_sel;
	logic [31:0] divided_clocks;

	assign speed_sel = |score[7:4] ? 2'd0 : (|score[3:2] ? 2'd1 : 2'd2);

	always_ff @(posedge CLOCK_50) frame = (vga_y == 0);

	framebuf1 fb1 (.clock(CLOCK_50), .data(white), .rdaddress(19'(vga_y)*640+19'(vga_x)),
				   .wraddress(19'(y)*640+19'(x)), .wren(buf_sel), .q(fb1q));
	framebuf2 fb2 (.clock(CLOCK_50), .data(white), .rdaddress(19'(vga_y)*640+19'(vga_x)),
				   .wraddress(19'(y)*640+19'(x)), .wren(~buf_sel), .q(fb2q));

	// main main (.clk(CLOCK_50), .frame_clk(CLOCK_50), .x(pre_x), .y(pre_y), .*);
	main main (.clk(CLOCK_50), .frame_clk(divided_clocks[speed_sel]), .x(pre_x), .y(pre_y), .*);

	clock_divider cdiv (.clock(frame), .divided_clocks);
	assign buf_sel = divided_clocks[speed_sel+1];

	assign vga_red   = (buf_sel ? fb2q : fb1q) ? 8'hFF : 8'h53;
	assign vga_green = (buf_sel ? fb2q : fb1q) ? 8'hFF : 8'h4A;
	assign vga_blue  = (buf_sel ? fb2q : fb1q) ? 8'hFF : 8'hBC;
	
	video_driver vga (.reset(0), .x(vga_x), .y(vga_y), .r(vga_red), .g(vga_green), .b(vga_blue), .*);

	assign in_bounds = (pre_x[10:5] < 6'b010100 && pre_y[10:5] < 6'b001111);
	assign {x,y} = in_bounds ? {pre_x, pre_y} : '0;
	assign reset = ~V_GPIO[0];

	joystick_driver jdriver(
    	.clk(CLOCK_50),
    	.data_in(V_GPIO[28]),
    	.latch(V_GPIO[26]),
    	.pulse(V_GPIO[27]),
    	.positionX(joyX),
    	.positionY(joyY)
	);

	seg7 hex0 (.hex(score[3:0]), .leds(HEX0));
	seg7 hex1 (.hex(score[7:4]), .leds(HEX1));

	assign HEX5 = (game_over) ? 7'b0000110 : 7'b1111111;
	assign HEX4 = (game_over) ? 7'b0101011 : 7'b1111111;
	assign HEX3 = (game_over) ? 7'b0100001 : 7'b1111111;
	assign HEX2 = 7'b1111111;
endmodule  // DE1_SoC


// testbench
module DE1_SoC_testbench();

	logic clk;
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR;
	logic [7:0] VGA_R, VGA_G, VGA_B;
	logic VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS;
	logic [35:0] V_GPIO;
	reg reset, restart;

	assign V_GPIO[0] = ~reset;
	
	DE1_SoC dut (.CLOCK_50(clk),.*);
	
	// clock setup
	parameter clock_period = 100;
	initial begin
		clk = 1;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
	end
	
	// test
	initial begin 
		// init
		@(posedge clk);
		reset = 1'b1; @(posedge clk);
		reset = 1'b0;
		
		repeat(100) @(posedge clk);
		
		$stop;
	end
endmodule