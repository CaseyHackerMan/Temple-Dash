/* Given two points on the screen this module draws a line between
 * those two points by coloring necessary pixels
 *
 * Inputs:
 *   clk    - should be connected to a 50 MHz clock
 *   reset  - resets the module and starts over the drawing process
 *	 x0 	- x coordinate of the first end point
 *   y0 	- y coordinate of the first end point
 *   x1 	- x coordinate of the second end point
 *   y1 	- y coordinate of the second end point
 *
 * Outputs:
 *   x 		- x coordinate of the pixel to color
 *   y 		- y coordinate of the pixel to color
 *   done	- flag that line has finished drawing
 *
 */
module line_drawer(clk, start, reset, x0, y0, x1, y1, x, y, done);
	input logic clk, start, reset;
	input logic signed [10:0] x0, y0, x1, y1;
	output logic done;
	output logic signed [10:0]	x, y;

	enum {IDLE, DRAW, DONE} ps, ns;

	logic signed [13:0] error;
	logic signed [11:0] dx, dy;
	logic signed [10:0] x0_load, y0_load, x1_load, y1_load, next_x, next_y;
	logic sx, sy, inc_x, inc_y, load;
	
	assign sx = (x1_load < x0_load);
	assign sy = (y1_load < y0_load);
	assign dx = sx ? x0_load-x1_load : x1_load-x0_load;
	assign dy = sy ? y1_load-y0_load : y0_load-y1_load;
	assign inc_x = (2*error >= dy);
	assign inc_y = (2*error <= dx);
	assign done = (ps == DONE);
	assign load = (ps == IDLE && ns == DRAW);
	assign next_x = x + (inc_x ? {{10{sx}}, 1'b1} : 11'b0);
	assign next_y = y + (inc_y ? {{10{sy}}, 1'b1} : 11'b0);

	always_comb begin
		case (ps)
			IDLE: ns = (start) ? DRAW : IDLE;
			DRAW: ns = (((sx) ? next_x <= x1_load : next_x >= x1_load) && ((sy) ? next_y <= y1_load : next_y >= y1_load)) ? DONE : DRAW;
			DONE: ns = (start) ? DONE : IDLE;
		endcase
	end
	
	always_ff @(posedge clk) begin
		if (reset) ps <= IDLE;
		else ps <= ns;
		
		if (load) begin
			y <= y0;
			x <= x0;
			x0_load <= x0;
			y0_load <= y0;
			x1_load <= x1;
			y1_load <= y1;
			error <= (x1 < x0 ? x0-x1 : x1-x0) + (y1 < y0 ? y1-y0 : y0-y1);
		end else if (ps == DRAW) begin
			error += (inc_x ? dy : 0) + (inc_y ? dx : 0);
			x = next_x;
			y = next_y;
		end
	end 
endmodule 

// testbench
module line_drawer_testbench();

	logic clk, start, reset, done;
	logic signed [10:0] x0, y0, x1, y1, x, y;
	
	line_drawer dut (.*);
	
	// clock setup
	parameter clock_period = 100;
	initial begin
		clk = 1;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
		repeat(250) #(clock_period/2) clk = ~clk;
	end
	
	// test
	initial begin 
		// init
		reset = 1; start = 0; {x0,y0,x1,y1} = 0; @(posedge clk);
		reset = 0; start = 1; 
		x0 = 10; y0 = 10;
		x1 = 20; y1 = 15;
		@(posedge done);
		start = 0; @(posedge clk);
		start = 1; 
		x0 = 13; y0 = 21;
		x1 = 10; y1 = 10;
		@(posedge clk); @(posedge clk); @(posedge clk);
		x0 = 30; y0 = 20;
		x1 = 20; y1 = 20;
		@(posedge done);
		start = 0; @(posedge clk);
		start = 1; 
		@(posedge done);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		$stop;
	end
endmodule