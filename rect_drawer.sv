/* Given two points on the screen this module draws a line between
 * those two points by coloring necessary pixels
 *
 * Inputs:
 *   clk    - should be connected to a 50 MHz clock
 *   start  - starts the module and starts over the drawing process
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
module rect_drawer(clk, start, reset, x0, y0, x1, y1, x, y, done);
	input logic clk, start, reset;
	input logic signed [10:0] x0, y0, x1, y1;
	output logic done;
	output logic signed [10:0]	x, y;
	
	logic signed [10:0] x0_load, y0_load, x1_load, y1_load, next_x, next_y;
	logic sx, sy, load;

	enum {IDLE, DRAW, DONE} ps, ns;
	
	assign sx = (x1_load < x0_load);
	assign sy = (y1_load < y0_load);
	assign done = (ps == DONE);
	assign load = (ps==IDLE && ns==DRAW);
	assign next_x = (x == x1_load) ? x0_load : x+(sx ? -1 : 1);
	assign next_y = (x == x1_load) ? y+(sy ? -1 : 1) : y;

	always_comb begin
		case (ps)
			IDLE: ns = (start) ? DRAW : IDLE;
			DRAW: ns = (next_x == x1_load && next_y == y1_load) ? DONE : DRAW;
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
		end else if (ps == DRAW) begin
			x <= next_x;
			y <= next_y;
		end
	end 
endmodule 