module obj_handler (input logic clk, reset,
                    input logic signed [11:0] obj_distance, 
                    input logic [1:0] player_lane, 
                    input logic [15:0] rd_obj,
                    output logic pop, game_over, point);

    logic wall, coin, turn, back, hit;

    assign hit = (player_lane == rd_obj[15:14]) && (obj_distance < 16);
    assign back = obj_distance == 0;
    assign coin = rd_obj[13:12] == 2'b00;
    assign wall = rd_obj[13:12] == 2'b10;
    assign turn = rd_obj[13:12] == 2'b01;

    always_ff @(posedge clk) begin
        if (reset) begin
            game_over <= 0;
            point <= 0;
            pop <= 0;
        end else begin
            game_over <= (back && turn) || (wall && hit) || game_over;
            point <= (coin && hit);
            pop <= ~reset && (back || hit || game_over);
        end
    end
endmodule