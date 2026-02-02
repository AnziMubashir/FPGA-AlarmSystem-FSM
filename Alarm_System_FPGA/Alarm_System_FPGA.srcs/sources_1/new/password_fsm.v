`timescale 1ns / 1ps

module password_fsm(
    input clk,
    input [3:0] digit_in,
    input enter,      
    input confirm,    
    input reset_req,  
    input newpass,    
    input stop_alarm,
    output reg [3:0] seg1,
    output reg [3:0] seg0,
    output reg alarm,
    output reg [15:0] led
);

    // Stored password (default = 42)
    reg [3:0] pass1 = 4'd4;
    reg [3:0] pass0 = 4'd2;

    // Input digits
    reg [3:0] inp1 = 4'd0;
    reg [3:0] inp0 = 4'd0;
    reg digit_count = 1'b0; 

    // FSM states
    localparam IDLE        = 3'd0,
               ENTER_DIGIT = 3'd1,
               VERIFY      = 3'd2,
               RESET_OLD   = 3'd3,
               RESET_NEW   = 3'd4,
               SAVE_NEW    = 3'd5,
               ALARM_STATE = 3'd6,
               UNLOCKED    = 3'd7; // ADDED THIS

    reg [2:0] st = IDLE;

    // Blink counter
    reg [25:0] blink = 26'd0;
    always @(posedge clk) blink <= blink + 1;

    // Stop switch sync
    reg stop_sync1 = 1'b0, stop_sync2 = 1'b0;
    always @(posedge clk) begin
        stop_sync1 <= stop_alarm;
        stop_sync2 <= stop_sync1;
    end

    // Main FSM
    always @(posedge clk) begin
        seg1 <= inp1;
        seg0 <= inp0;

        // GLOBAL RESET (Switch 15)
        if (stop_sync2) begin
            alarm <= 1'b0;
            led   <= 16'h0000;
            digit_count <= 1'b0;
            inp1  <= 4'd0;
            inp0  <= 4'd0;
            st    <= IDLE;
        end else begin

            case (st)
            // IDLE
            IDLE: begin
                led <= 16'h0001; 
                if (enter) st <= ENTER_DIGIT;
                else if (confirm) st <= VERIFY;
                else if (reset_req) begin
                    digit_count <= 1'b0;
                    led <= 16'h00FF;
                    st <= RESET_OLD;
                end
            end

            // ENTER_DIGIT
            ENTER_DIGIT: begin
                led <= 16'h000F; 
                if (digit_count == 1'b0) begin
                    inp1 <= digit_in;
                    digit_count <= 1'b1;
                end else begin
                    inp0 <= digit_in;
                    digit_count <= 1'b0;
                end
                st <= IDLE;
            end

            // VERIFY
            VERIFY: begin
                if ((inp1 == pass1) && (inp0 == pass0)) begin
                    alarm <= 1'b0;
                    led <= 16'hFFFF;    
                    st <= UNLOCKED;      // CHANGED: Go to UNLOCKED state
                end else begin
                    alarm <= 1'b1;
                    st <= ALARM_STATE;   
                end
            end

            // UNLOCKED STATE (NEW)
            UNLOCKED: begin
                led <= 16'hFFFF; // Keep LEDs Solid ON
                
                // Press CENTER button to lock it again
                if (enter) begin
                    inp1 <= 4'd0;
                    inp0 <= 4'd0;
                    st <= IDLE;
                end
            end

            // ALARM STATE
            ALARM_STATE: begin
                alarm <= 1'b1;
                led <= (blink[24] ? 16'hFFFF : 16'h0000); 
            end

            // RESET OLD
            RESET_OLD: begin
                led <= 16'hF0F0; 
                if (confirm) begin
                    if ((inp1 == pass1) && (inp0 == pass0)) begin
                        inp1 <= 4'd0;
                        inp0 <= 4'd0;
                        digit_count <= 1'b0;
                        st <= RESET_NEW;
                    end else begin
                        st <= ALARM_STATE;
                    end
                end
            end

            // RESET NEW
            RESET_NEW: begin
                led <= 16'h0FF0; 
                if (enter) begin
                    if (digit_count == 1'b0) begin
                        inp1 <= digit_in;
                        digit_count <= 1'b1;
                    end else begin
                        inp0 <= digit_in;
                        digit_count <= 1'b0;
                    end
                end 
                else if (newpass) begin
                    st <= SAVE_NEW;
                end
            end

            // SAVE NEW
            SAVE_NEW: begin
                pass1 <= inp1;
                pass0 <= inp0;
                inp1 <= 4'd0;
                inp0 <= 4'd0;
                digit_count <= 1'b0;
                alarm <= 1'b0;
                led <= 16'h0000; 
                st <= IDLE;
            end

            default: st <= IDLE;
            endcase
        end
    end
endmodule