// 32-bit clock divider
module clock_divider (clock, divided_clocks);
 
	input  logic clock;
	output logic  [31:0]  divided_clocks = 0;
	always_ff @(posedge clock) begin
		divided_clocks <= divided_clocks + 1;
	end
	
endmodule