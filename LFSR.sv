module LFSR (input logic clk, reset,
			 input logic [19:0] seed,
			 output logic [19:0] val);
	
	always_ff @(posedge clk) begin
		if  (reset) val <= seed;
		else begin
			val <<= 1;	
			val[0] <= ~(val[19] ^ val[16]);
		end
	end
endmodule