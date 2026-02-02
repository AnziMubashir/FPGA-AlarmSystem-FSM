`timescale 1ns / 1ps

module top(
    input clk,                   // 100 MHz main clock
    input [15:0] sw,             // switches
    input btnC, btnU, btnL, btnR,// pushbuttons
    output [15:0] led,           // LEDs
    output [6:0] seg,            // seven-seg segments
    output dp,                   // seven-seg dot
    output [3:0] an,             // digit enables
    output buzzer                // piezo buzzer pin
);

    // ===========================================================================
    // 1. DEBOUNCE
    // ===========================================================================
    wire db_enter_level, db_confirm_level, db_reset_level, db_newpass_level;

    // Note: Removed "_n" naming because debounce outputs High when pressed
    debounce d0(clk, btnC, db_enter_level);
    debounce d1(clk, btnU, db_confirm_level);
    debounce d2(clk, btnL, db_reset_level);
    debounce d3(clk, btnR, db_newpass_level);

    // ===========================================================================
    // 2. EDGE DETECTION (One-Shot Pulse)
    // We must turn the long button press into a single 1-clock-cycle pulse
    // ===========================================================================
    reg enter_prev, confirm_prev, reset_prev, newpass_prev;
    wire enter_pulse, confirm_pulse, reset_pulse, newpass_pulse;

    always @(posedge clk) begin
        enter_prev   <= db_enter_level;
        confirm_prev <= db_confirm_level;
        reset_prev   <= db_reset_level;
        newpass_prev <= db_newpass_level;
    end

    // Pulse is high ONLY when (Current is 1) AND (Previous was 0)
    assign enter_pulse   = db_enter_level   & ~enter_prev;
    assign confirm_pulse = db_confirm_level & ~confirm_prev;
    assign reset_pulse   = db_reset_level   & ~reset_prev;
    assign newpass_pulse = db_newpass_level & ~newpass_prev;

    // ===========================================================================
    // 3. MAIN FSM
    // ===========================================================================
    wire alarm_on;
    wire [3:0] disp1, disp0;

    password_fsm core (
        .clk(clk),
        .digit_in(sw[3:0]),
        .enter(enter_pulse),     // <--- Use the PULSE signal here
        .confirm(confirm_pulse), // <--- and here
        .reset_req(reset_pulse), // <--- and here
        .newpass(newpass_pulse), // <--- and here
        .stop_alarm(sw[15]),
        .seg1(disp1),
        .seg0(disp0),
        .alarm(alarm_on),
        .led(led)
    );

    // ===========================================================================
    // 4. DISPLAY CONTROLLER
    // ===========================================================================
    seven_seg display (
        .clk(clk),
        .digit1(disp1),
        .digit0(disp0),
        .seg(seg),
        .dp(dp),
        .an(an)
    );

    // ===========================================================================
    // 5. BUZZER DRIVER
    // Passive buzzers need a square wave (frequency) to make sound.
    // This creates a ~1kHz tone when alarm_on is High.
    // ===========================================================================
    reg [16:0] buzz_cnt = 0;
    reg buzz_wave = 0;

    always @(posedge clk) begin
        if (alarm_on) begin
            // Toggle every 50,000 cycles (100MHz / 50k = 2kHz toggle = 1kHz wave)
            if (buzz_cnt >= 50000) begin 
                buzz_wave <= ~buzz_wave;
                buzz_cnt <= 0;
            end else begin
                buzz_cnt <= buzz_cnt + 1;
            end
        end else begin
            buzz_cnt <= 0;
            buzz_wave <= 0;
        end
    end

    assign buzzer = buzz_wave;

endmodule