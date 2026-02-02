`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 07:20:21 PM
// Design Name: 
// Module Name: debounce
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


module debounce(
    input clk,
    input btn,
    output reg clean
);

    reg sync0, sync1;
    reg [19:0] counter = 0;

    // 2-stage synchronizer (safe)
    always @(posedge clk) begin
        sync0 <= btn;
        sync1 <= sync0;
    end

    // Debounce logic
    always @(posedge clk) begin
        if (sync1 == clean) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 20'hFFFFF)
                clean <= sync1;
        end
    end
endmodule


