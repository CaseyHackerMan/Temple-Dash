// fifo queue, adapted from EE 371 fifo.sv + fifo_ctrl.sv + reg_file.sv
module obj_manager #(ADDR_WIDTH=4) (input clk, reset, push, pop,
                                    input [ADDR_WIDTH-1:0] rd_index, 
                                    input [15:0] wr_obj, 
                                    output [15:0] rd_obj, 
                                    output logic [ADDR_WIDTH:0] num);

    logic [15:0] obj_array [0:2**ADDR_WIDTH-1];
    logic [ADDR_WIDTH-1:0] front_ptr, front_ptr_next;
	logic [ADDR_WIDTH:0] num_next;
	logic w_en;
	
	assign w_en = push & ((num < 2**ADDR_WIDTH) | pop);	

    initial begin // SIM ONLY
        obj_array[0][11:0] = 12'd100; obj_array[0][13:12] = 2'b00; obj_array[0][15:14] = 2'b00;
        obj_array[1][11:0] = 12'd90;  obj_array[1][13:12] = 2'b10; obj_array[1][15:14] = 2'b10;
        obj_array[2][11:0] = 12'd80;  obj_array[2][13:12] = 2'b00; obj_array[2][15:14] = 2'b01;
    end
	
	// write operation (synchronous)
	always_ff @(posedge clk)
	   if (w_en) obj_array[front_ptr + num] <= wr_obj;
	
	assign rd_obj = (rd_index < num) ? obj_array[front_ptr + rd_index] : 16'hF7FF;
	
	// fifo controller logic
	always_ff @(posedge clk) begin
		if (reset) begin
			front_ptr <= 0;
			num <= 0;
		end else begin
			front_ptr <= front_ptr_next;
			num <= num_next;
		end
	end  // always_ff
	
	// next state logic
	always_comb begin
		// default to keeping the current values
		front_ptr_next = front_ptr;
		num_next = num;
		case ({pop, push})

			2'b11:  // read and write
				front_ptr_next = front_ptr + 1;

			2'b10:  // read
				if (num != 4'b0) begin
					front_ptr_next = front_ptr + 1;
					num_next = num - 1;
				end

			2'b01:  // write
				if (num < 2**ADDR_WIDTH)
					num_next = num + 1;
		
			2'b00: ; // no change
		endcase
	end  // always_comb

endmodule

// testbench
module obj_manager_testbench();

	logic clk, reset, push, pop;
    logic [4:0] num, rd_index;
    logic [15:0] wr_obj, rd_obj;
	
	obj_manager dut (.*);
	
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
		@(posedge clk); reset = 1'b1;
        wr_obj = 69; rd_index = 0;
        push = 0; pop = 0; @(posedge clk);

		reset = 1'b0; @(posedge clk);

        push = 1; @(posedge clk);
        @(posedge clk);
        wr_obj = 420; @(posedge clk);
        @(posedge clk);
        push = 0; 
        repeat(5) begin
            rd_index++; @(posedge clk);
        end
        rd_index = 0; pop = 1; @(posedge clk);
        repeat(5) @(posedge clk);
        push = 1; pop = 0; @(posedge clk);
        @(posedge clk);
		
		$stop;
	end
endmodule