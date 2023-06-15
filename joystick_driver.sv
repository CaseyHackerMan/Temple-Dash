module joystick_driver
(
    input clk,
    input data_in,
    output reg latch,
    output reg pulse,
    output reg [7:0] positionX,
    output reg [7:0] positionY
);

    reg[15:0] data_out;
    

    serial_driver #(.BITS(16)) driver (
        .clk(clk),
        .data_in(data_in),
        .latch(latch),
        .pulse(pulse),
        .data_out(data_out)
    );
    
    assign positionX = data_out[15:8];
    assign positionY = data_out[7:0];
    
endmodule