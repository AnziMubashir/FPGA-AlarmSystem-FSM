`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 07:16:50 PM
// Design Name: 
// Module Name: seven_seg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seven_seg(
    input clk,
    input [3:0] digit1,
    input [3:0] digit0,
    output reg [6:0] seg,
    output dp,
    output reg [3:0] an
);

    assign dp = 1; // dot always off

    reg [16:0] refresh_counter = 0; // slower refresh for brighter segments
    wire [1:0] refresh = refresh_counter[16:15]; // top 2 bits used to select digit
    reg [3:0] value;

    // Slow refresh counter
    always @(posedge clk)
        refresh_counter <= refresh_counter + 1;

    // Select digit + activate correct AN line (active low anodes)
    always @(*) begin
        case (refresh)
            2'b00: begin an = 4'b1110; value = digit0; end
            2'b01: begin an = 4'b1101; value = digit1; end
            default: begin an = 4'b1111; value = 4'd0; end
        endcase
    end

    // Actual segment decoding (active low)
    always @(*) begin
        case(value)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
