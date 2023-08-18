`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2020 01:10:07 PM
// Design Name: 
// Module Name: main
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


module Digital_Clock(
    input clk, // FPGA clock signal, 100 MHz
    input reset,
    input IO_BTN_C,IO_BTN_U, IO_BTN_L, IO_BTN_R, IO_BTN_D, // FPGA IO pushbuttons
    input [0:0] IO_SWITCH,//IO Switch 0 toggles between 24 Hours and AM/PM
    output [6:0] IO_SSEG, output [3:0] IO_SSEG_SEL, // FPGA 7-Segment Display
    output [0:0] IO_LED, //LED 0 is AM/PM LED
    output change_time,
    output alarm,
    output reg speaker,
    output led_reset
    );
    
    assign led_reset = 1;
    
    /* Timing parameters */
    reg [31:0] counter = 0;
    //parameter max_counter = 100000; // 100 MHz / 100000 = 1 kHz
    parameter max_counter = 100000000; // 100 MHz / 100000000 = 1 Hz => 1 second per second
    
    /* Data registers */
    reg [5:0] Hours, Minutes, Seconds = 0; 
    reg [3:0] Digit_0,Digit_1, Digit_2, Digit_3 = 0;
    reg [5:0] Hours_alarm=0, Minutes_alarm = 5'd1; 
    //reg [3:0] Digit_0_alarm,Digit_1_alarm, Digit_2_alarm, Digit_3_alarm = 0;  
    reg [0:0] current_bit = 0;      // Currently only minutes and hours
    
    reg AMPM = 0; // 0 = AM/PM, 1 = 24H Time
    
    reg AM_PM = 0;  // AM = 0/off , PM = 1/on
    reg mode_ct = 0;
    reg mode_al = 0;
    assign IO_LED[0] = AM_PM;
    assign change_time = mode_ct;
    assign alarm = mode_al;
    
    /* Seven Segment Display */
    sevseg display(.clk(clk),       // Initialize 7-segment display module
        .binary_input_0(Digit_0),
        .binary_input_1(Digit_1),
        .binary_input_2(Digit_2),
        .binary_input_3(Digit_3),
        .IO_SSEG_SEL(IO_SSEG_SEL),
        .IO_SSEG(IO_SSEG));
     
    
    /* Modes */
    parameter Hours_And_Minutes = 2'b00; // Clock mode - 12:00AM to 11:59PM
    parameter Set_Clock = 2'b01;         // Set time mode
    parameter Set_alarm = 2'b10;         // Set alarm mode
    reg [1:0] Current_Mode = Set_Clock; //Start in set time mode by default
    
    
    always @(posedge clk) begin
        if(reset)
            begin
                Hours <= 0;
                Minutes <= 0;
            end
        case(Current_Mode)
            Hours_And_Minutes: begin // Clock mode - 12:00AM to 11:59PM
                mode_ct <= 0;
                mode_al <= 0;
                if({Hours, Minutes} == {Hours_alarm,Minutes_alarm})
                    speaker <= 1;
                else
                    speaker <= 0;
                if (IO_BTN_C) begin
                    Current_Mode <= Set_Clock; // Swap modes when you push the center button 
                    // Reset variables to prepare for set time mode 
                    counter <= 0;
                    current_bit <= 0;
                    Seconds <= 0; 
                end
                
                if (counter < max_counter) begin // time
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    Seconds <= Seconds + 1;
                end                                
            end //Hours_And_Minutes
            Set_Clock: begin
                mode_ct <= 1;
                mode_al <= 0; 
                if (IO_BTN_C) begin // Push center button to commit time set and return to Clock mode
                    Current_Mode <= Set_alarm;
                end
                
                if (counter < (25000000)) begin // different clock speed when setting - 4 Hz
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    case (current_bit)
                        1'b0: begin //minutes
                            if (IO_BTN_U) begin // Increment minutes when you push up
                                Minutes <= Minutes + 1;
                            end
                            if (IO_BTN_D) begin // Decrement minutes when you push down
                                if (Minutes > 0) begin
                                    Minutes <= Minutes - 1;
                                end else if (Hours > 1) begin
                                    Hours <= Hours - 1;
                                    Minutes <= 59;
                                end else if (Hours == 1) begin
                                    Hours <= 12;
                                    Minutes <= 59;
                                end
                            end
                            if (IO_BTN_L || IO_BTN_R) begin // Push left/right button to swap between hours/minutes
                                current_bit <= 1;
                            end
                        end // end 1'b0
                        1'b1: begin //hours
                            if (IO_BTN_U) begin // Increment hours when you push up
                                Hours <= Hours + 1;
                            end
                            if (IO_BTN_D) begin // Decrement minutes when you push down
                                if (Hours > 1) begin
                                    Hours <= Hours - 1;
                                end else if (Hours == 1) begin
                                    Hours <= 12;
                                    //AM_PM <= ~AM_PM;
                                end
                            end
                            if (IO_BTN_R || IO_BTN_L) begin // Push left/right button to swap between hours/minutes
                                current_bit <= 0;
                            end
                        end // end 1'b1                       
                endcase   // end case (current_bit)            
                end                    
            end // end Set_Clock
            Set_alarm: begin
                mode_ct <= 0;
                mode_al <= 1; 
                if (IO_BTN_C) begin // Push center button to commit time set and return to Clock mode
                    Current_Mode <= Hours_And_Minutes;
                end
                
                if (counter < (25000000)) begin // different clock speed when setting - 4 Hz
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    case (current_bit)
                        1'b0: begin //minutes_alarm
                            if (IO_BTN_U) begin // Increment minutes when you push up
                                Minutes_alarm <= Minutes_alarm + 1;
                            end
                            if (IO_BTN_D) begin // Decrement minutes when you push down
                                if (Minutes_alarm > 0) begin
                                    Minutes_alarm <= Minutes_alarm - 1;
                                end else if (Hours_alarm > 1) begin
                                    Hours_alarm <= Hours_alarm - 1;
                                    Minutes_alarm <= 59;
                                end else if (Hours_alarm == 1) begin
                                    Hours_alarm <= 12;
                                    Minutes_alarm <= 59;
                                end
                            end
                            if (IO_BTN_L || IO_BTN_R) begin // Push left/right button to swap between hours/minutes
                                current_bit <= 1;
                            end
                        end // end 1'b0
                        1'b1: begin //hours
                            if (IO_BTN_U) begin // Increment hours when you push up
                                Hours_alarm <= Hours_alarm + 1;
                            end
                            if (IO_BTN_D) begin // Decrement minutes when you push down
                                if (Hours_alarm > 1) begin
                                    Hours_alarm <= Hours_alarm - 1;
                                end else if (Hours_alarm == 1) begin
                                    Hours_alarm <= 12;
                                    //AM_PM <= ~AM_PM;
                                end
                            end
                            if (IO_BTN_R || IO_BTN_L) begin // Push left/right button to swap between hours/minutes
                                current_bit <= 0;
                            end
                        end // end 1'b1                       
                endcase   // end case (current_bit)            
                end                    
            end // end Set_alarm
        endcase // end case(Current_Mode)
        
        /* Clock Stuff */
        if (Seconds >= 60) begin // After 60 seconds, increment minutes
                Seconds <= 0;
                Minutes <= Minutes + 1;
        end
        if (Minutes >= 60) begin // After 60 minutes, increment hours
                Minutes <= 0;
                Hours <= Hours + 1;
        end
        if (Hours >= 24) begin // After 12 hours, swap between AM and PM
            Hours <= 0;
        end
        
        /* Alarm Stuff */
        if (Minutes_alarm >= 60) begin // After 60 minutes, increment hours
                Minutes_alarm <= 0;
                Hours_alarm <= Hours_alarm + 1;
        end
        if (Hours_alarm >= 24) begin // After 12 hours, swap between AM and PM
            Hours_alarm <= 0;
        end
        
        /* Clock Display */
        AMPM <= IO_SWITCH[0];

        
        
    if(Current_Mode == Set_alarm)
        begin
        /* 24H */
        if (AMPM) begin // 1 = 24H
            Digit_0 <= Minutes_alarm % 10;  // 1's of minutes_alarm
            Digit_1 <= Minutes_alarm / 10;  // 10's of minutes_alarm
            Digit_2 <= Hours_alarm % 10;    // 1's of hours_alarm
            Digit_3 <= Hours_alarm / 10;    // 10's of hours_alarm
            AM_PM <= 0;
        end 
        /* AM PM time */
        else begin              // 0 = AM PM Time
            Digit_0 <= Minutes_alarm % 10;  // 1's of minutes_alarm
            Digit_1 <= Minutes_alarm / 10;  // 10's of minutes_alarm           
            if (Hours_alarm < 12) begin
                if (Hours_alarm == 0) begin // 00:00 24H = 12:00 AM
                    Digit_2 <= 2;
                    Digit_3 <= 1;
                end else begin
                    Digit_2 <= Hours_alarm % 10;    // 1's of hours_alarm
                    Digit_3 <= Hours_alarm / 10;    // 10's of hours_alarm
                end
                AM_PM <= 0;
            end else begin // end Hours_alarm < 12
                if (Hours_alarm == 12) begin //12:00 24H = 12:00 PM
                    Digit_2 <= 2;
                    Digit_3 <= 1;
                end else begin
                    Digit_2 <= (Hours_alarm - 12) % 10;    // 1's of hours_alarm
                    Digit_3 <= (Hours_alarm - 12) / 10;    // 10's of hours_alarm
                end
                AM_PM <= 1;                        
            end // end Hours_alarm >= 12           
        end // end Clock Display_alarm           
        end //end if Current_Mode == Set_alarm
        else
        begin
        /* 24H time */
        if (AMPM) begin // 1 = 24H Time
            Digit_0 <= Minutes % 10;  // 1's of minutes
            Digit_1 <= Minutes / 10;  // 10's of minutes
            Digit_2 <= Hours % 10;    // 1's of hours
            Digit_3 <= Hours / 10;    // 10's of hours
            AM_PM <= 0;
        end 
        /* AM PM time */
        else begin              // 0 = AM PM Time
            Digit_0 <= Minutes % 10;  // 1's of minutes
            Digit_1 <= Minutes / 10;  // 10's of minutes           
            if (Hours < 12) begin
                if (Hours == 0) begin // 00:00 24H= 12:00 AM
                    Digit_2 <= 2;
                    Digit_3 <= 1;
                end else begin
                    Digit_2 <= Hours % 10;    // 1's of hours
                    Digit_3 <= Hours / 10;    // 10's of hours
                end
                AM_PM <= 0;
            end else begin // end Hours < 12
                if (Hours == 12) begin //12:00 24H = 12:00 PM
                    Digit_2 <= 2;
                    Digit_3 <= 1;
                end else begin
                    Digit_2 <= (Hours - 12) % 10;    // 1's of hours
                    Digit_3 <= (Hours - 12) / 10;    // 10's of hours
                end
                AM_PM <= 1;                        
            end // end Hours >= 12           
        end // end Clock Display
        end //end if Current_Mode != Set_alarm
    end //end always @(posedge clk)
endmodule