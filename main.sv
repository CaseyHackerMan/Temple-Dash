module main(input logic clk, frame_clk, reset,
            input logic signed [7:0] joyX, joyY,
            output logic white,
            output logic signed [10:0] x, y,
			output logic game_over,
			output logic [9:0] LEDR,
			output logic [7:0] score);

	parameter signed [10:0] horizon_x = 320;
	parameter signed [10:0] horizon_y = 50;
	parameter signed [10:0] road_end = 480;
	parameter signed [10:0] road_width1 = 120;
	parameter signed [10:0] road_width2 = 80;
	parameter signed [10:0] road_width3 = 40;
	parameter [11:0] turn_depth = 100;
	parameter [10:0] wall_height = 32;
	parameter [10:0] coin_size = 8;

    logic start, reset_count, reset_draw, player_frame, last_frame_clk, point;
	logic line_done, rect_done, obj_done, draw_done, draw_src, draw_en;
	logic push, pop;
	logic [15:0] wr_obj, rd_obj;
    logic signed [10:0] x0, y0, x1, y1;
	logic [10:0] line_x, line_y, rect_x, rect_y, posX, posY;
    logic signed [10:0] player_posX, player_posY;
	logic signed [10:0] obj1_x, obj1_y, obj2_x, obj2_y;
	logic [4:0] draw_count;
    logic signed [11:0] obj_distance, player_dist;
    logic [1:0] player_lane;
	logic [4:0] obj_num, obj_count;
	logic [10:0] obj1_end_x, obj1_end_y, obj2_end_x, obj2_end_y;
	logic [19:0] rand_val;

	enum {IDLE, RECT, LINE, PLAYER, OBJ, DONE} ps, ns;

	localparam logic signed [0:3][10:0] player1 [0:6] = '{
		'{'d0, 'd7, -'d1, 'd6},
		'{'d0, 'd7, 'd1, 'd6},
		'{'d2, 'd2, -'d1, 'd6},
		'{-'d2, 'd2, 'd1, 'd6},
		'{-'d2, 'd2, 'd2, 'd2},
		'{-'d1, 'd2, -'d1, 'd1},
		'{'d1, 'd2, 'd1, 'd0}
	};
	localparam logic signed [0:3][10:0] player2 [0:6] = '{
		'{'d0, 'd7, -'d1, 'd6},
		'{'d0, 'd7, 'd1, 'd6},
		'{'d2, 'd2, -'d1, 'd6},
		'{-'d2, 'd2, 'd1, 'd6},
		'{-'d2, 'd2, 'd2, 'd2},
		'{-'d1, 'd2, -'d1, 'd0},
		'{'d1, 'd2, 'd1, 'd1}
	};

    assign start = frame_clk;
    assign player_posX = horizon_x + joyX;
	assign player_posY = 11'd470;
	assign player_lane[0] = (joyX > road_width3);
	assign player_lane[1] = (joyX < -road_width3);
    assign reset_draw = reset || draw_done || ~draw_en;
	assign obj_distance = rd_obj[11:0] - player_dist;
	assign x = draw_en ? (draw_src ? rect_x : line_x) : 0;
	assign y = draw_en ? (draw_src ? rect_y : line_y) : 0;

    always_ff @(posedge frame_clk) begin
		if (reset) begin
			player_dist <= 0;
			score <= 0;
		end else if (~game_over) begin
			player_frame <= ~player_frame;
			if (point) score++;
			player_dist++;
		end
	end

	assign LEDR[1:0] = player_lane;
	assign LEDR[5:2] = rd_obj[3:0];
	assign LEDR[9:6] = player_dist[3:0];

	LFSR randy (.val(rand_val), .seed(20'd696969), .*);
	obj_manager #(4) man (.clk(frame_clk), .rd_index(obj_count),.num(obj_num), .*);
	obj_generator gen (.clk(frame_clk), .reset(game_over || reset), .*);
	obj_handler handle (.*);
	
	line_drawer lines (.clk, .start(draw_en && ~draw_src && ~line_done), .reset(reset_draw), .done(line_done),
					   .x0, .y0, .x1, .y1, .x(line_x), .y(line_y));

	rect_drawer rects (.clk, .start(draw_en && draw_src && ~rect_done), .reset(reset_draw), .done(rect_done),
					   .x0, .y0, .x1, .y1, .x(rect_x), .y(rect_y));
    
    always_ff @(posedge clk) begin
		last_frame_clk <= frame_clk;
		if (reset || (~last_frame_clk && frame_clk)) ps <= IDLE;
		else ps <= ns;

		if (reset_draw) draw_count <= 0;
		else if ((draw_src) ? rect_done : line_done) draw_count++;

		if (ps != OBJ) obj_count <= 0;
		else if (draw_done) obj_count++;
	end

	always_comb begin
		case (ps)
			IDLE:   ns = (start) ? RECT : IDLE;
			RECT:   ns = (draw_done) ? LINE : RECT;
			LINE:   ns = (draw_done) ? PLAYER : LINE;
			PLAYER: ns = (draw_done) ? OBJ : PLAYER;
            OBJ:    ns = (obj_done) ? DONE : OBJ; 
			DONE:   ns = (start) ? DONE : IDLE;
		endcase
	end

	always_comb begin
		obj1_x = 0;
		obj1_y = 0;
		obj2_x = 0;
		obj2_y = 0;
		case(rd_obj[13:12])
			2'b00: begin // coins
				obj1_y = road_end - (obj_distance<<3);
				if (rd_obj[15:14] == 2'b10) obj1_x = horizon_x - road_width2;
				else if (rd_obj[15:14] == 2'b01) obj1_x = horizon_x + road_width2;
				else obj1_x = horizon_x;
			end
			2'b01: begin // turn
				obj1_x = horizon_x - road_width1;
				obj2_x = horizon_x + road_width1;
				if (rd_obj[15:14] == 2'b10) begin
					obj1_y = road_end - (obj_distance<<3);
					obj2_y = road_end - (obj_distance<<3) - turn_depth;
				end else begin
					obj1_y = road_end - (obj_distance<<3) - turn_depth;
					obj2_y = road_end - (obj_distance<<3);
				end
			end
			2'b10: begin // wall
				obj1_y = road_end - (obj_distance<<3) - wall_height;
				obj2_y = road_end - (obj_distance<<3);
				if (rd_obj[15:14] == 2'b10) begin
					obj1_x = horizon_x - road_width1;
					obj2_x = horizon_x - road_width3;
				end else if (rd_obj[15:14] == 2'b00) begin
					obj1_x = horizon_x - road_width3;
					obj2_x = horizon_x + road_width3;
				end else begin
					obj1_x = horizon_x + road_width3;
					obj2_x = horizon_x + road_width1;
				end
			end
			default: ;
		endcase
		{x0, y0, x1, y1} = 0;
		white = 0;
		obj_done = 0;
		draw_done = 0;
		draw_src = 0;
		draw_en = 0;
		case (ps)
			IDLE: ;
			RECT: begin
				draw_src = 1;
				draw_en = 1;
				draw_done = rect_done;
				x0 = 0;
				y0 = 0;
				x1 = 639;
				y1 = 479;
				// x1 = 2;
				// y1 = 3;
			end
			LINE:  begin 
				draw_en = 1;
				white = 1;
				draw_done = (draw_count >= 'd2);

				y0 = 0;
				y1 = road_end;
				// y1 = 3;

				if (draw_count == 0) begin
					x0 = horizon_x-road_width1;
					x1 = horizon_x-road_width1;
				end else begin
					x0 = horizon_x+road_width1;
					x1 = horizon_x+road_width1;
				end 
			end 
			PLAYER: begin
				draw_en = 1;
				draw_done = game_over ? (draw_count >= 'd5) : (draw_count >= 'd7);
				white = 1;
				if (player_frame) begin
					x0 =  (player1[draw_count][0]<<4) + player_posX;
					y0 = (-player1[draw_count][1]<<4) + player_posY;
					x1 =  (player1[draw_count][2]<<4) + player_posX;
					y1 = (-player1[draw_count][3]<<4) + player_posY;
				end else begin
					x0 =  (player2[draw_count][0]<<4) + player_posX;
					y0 = (-player2[draw_count][1]<<4) + player_posY;
					x1 =  (player2[draw_count][2]<<4) + player_posX;
					y1 = (-player2[draw_count][3]<<4) + player_posY;
				end
			end
            OBJ: begin
				draw_en = 1;
				obj_done = (obj_count >= obj_num);
				case (rd_obj[13:12])
					2'b00: begin // coin
						white = 1;
						case (draw_count)
                    		0: {x0, y0, x1, y1} = {obj1_x, obj1_y-(coin_size<<2), obj1_x+coin_size, obj1_y-(coin_size<<1)};
                    		1: {x0, y0, x1, y1} = {obj1_x, obj1_y-(coin_size<<2), obj1_x-coin_size, obj1_y-(coin_size<<1)};
                    		2: {x0, y0, x1, y1} = {obj1_x, obj1_y, obj1_x+coin_size, obj1_y-(coin_size<<1)};
                    		3: {x0, y0, x1, y1} = {obj1_x, obj1_y, obj1_x-coin_size, obj1_y-(coin_size<<1)};
                    		default: draw_done = 1;
						endcase
					end
					2'b01: begin // turn
						white = ~draw_count[2];
                    	case (draw_count)
                    		0: {x0, y0, x1, y1} = {((rd_obj[15:14] == 2'b01)?11'd640:11'd0), obj1_y, obj1_x, obj1_y};
                    		1: {x0, y0, x1, y1} = {horizon_x-road_width1, road_end, obj1_x, obj1_y};
                    		2: {x0, y0, x1, y1} = {((rd_obj[15:14] == 2'b01)?11'd640:11'd0), obj2_y, obj2_x, obj2_y};
                    		3: {x0, y0, x1, y1} = {horizon_x+road_width1, road_end, obj2_x, obj2_y};
							4: {x0, y0, x1, y1} = {horizon_x-road_width1, 11'd0, obj1_x, obj1_y};
							5: {x0, y0, x1, y1} = {horizon_x+road_width1, 11'd0, obj2_x, obj2_y};
                    		default: begin 
								obj_done = 1;
								draw_done = 1;
							end
						endcase
					end
					2'b10: begin // wall
						white = 1;
						draw_src = 1;
						draw_done = rect_done;
                    	{x0, y0, x1, y1} = {obj1_x, obj1_y, obj2_x, obj2_y};
					end           	
					default: draw_done = 1;
                endcase
            end
			DONE: ;
		endcase
	end

endmodule

// testbench
module main_testbench();

	logic clk, frame_clk, reset;
    logic signed [7:0] joyX, joyY;
    logic white, game_over;
    logic signed [10:0] x, y;
	logic [9:0] LEDR;
	logic [7:0] score;
	
	main dut (.*);
	
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
	end
	
	// test
	initial begin 
		// init
		@(posedge clk);
		reset = 1; frame_clk = 0; joyX = 0;@(posedge clk);
		frame_clk = 1; @(posedge clk);
		reset = 0; @(posedge clk);

		@(posedge (dut.ps==dut.DONE));
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		frame_clk = 0; @(posedge clk); @(posedge clk);
		frame_clk = 1; 
		
		$stop;
	end
endmodule