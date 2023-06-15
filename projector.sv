module projector #(parameter S = 20) (distance, x0, y0, x1, y1, x, y, size);
	input logic [10:0] x0, y0, x1, y1;
    input logic [11:0] distance;
	output logic [10:0]	x, y;
    output logic [7:0] size;

    // always_comb begin
    //     size <= S*24/(distance+S);
    //     if (y0 <= y1) begin
    //         y = y0 + S*(16'(y1-y0))/(distance+S);
    //         if (x0 <= x1)
    //             x = x0 + 20'(x1-x0)*(y-y0)/(y1-y0);
    //         else
    //             x = x0 - 20'(x0-x1)*(y-y0)/(y1-y0);
    //     end else begin
    //         y = y0 - S*(16'(y0-y1))/(distance+S);
    //         if (x0 <= x1)
    //             x = x0 + 20'(x1-x0)*(y0-y)/(y0-y1);
    //         else
    //             x = x0 - 20'(x0-x1)*(y0-y)/(y0-y1);
    //     end
    // end

    always_comb begin
        size <= 20;
        x <= x1;
        y <= y1-(distance<<2);
    end

endmodule
    

