module obj_generator (input logic clk, reset,
                      input logic signed [11:0] player_dist, 
                      input logic [19:0] rand_val,
                      output logic push,
                      output logic [15:0] wr_obj);

    parameter COIN = 2'b00;
    parameter TURN = 2'b01;
    parameter WALL = 2'b10;

    parameter LEFT = 2'b10;
    parameter MID = 2'b00;
    parameter RIGHT = 2'b01;

    logic ready;
    
    always_ff @(posedge clk) begin
        if (~reset && ready) push = 1;
        else push = 0;
    end
        
    always_comb begin
        if (rand_val[3:0] == 0) begin
            wr_obj[13:12] = TURN;
            wr_obj[15:14] = rand_val[5] ? LEFT : RIGHT;
        end else begin 
            wr_obj[13:12] = (rand_val[3:0] < 5) ? WALL : COIN;
            case(rand_val[7:5])
                0: wr_obj[15:14] = LEFT;
                1: wr_obj[15:14] = LEFT;
                2: wr_obj[15:14] = LEFT;
                3: wr_obj[15:14] = MID;
                4: wr_obj[15:14] = MID;
                5: wr_obj[15:14] = RIGHT;
                6: wr_obj[15:14] = RIGHT;
                7: wr_obj[15:14] = RIGHT;
            endcase
        end

        wr_obj[11:0] = player_dist + 12'd80;

        if (player_dist[2:0] == 3'b000 && rand_val[8]) ready = 1;
        else ready = 0;
    end

endmodule