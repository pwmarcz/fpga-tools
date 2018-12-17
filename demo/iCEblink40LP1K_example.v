`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// CAPACTIVE TOUCH BUTTON demo for iCEblink40 board, LP1K version
//
// Version 1.1
// Date:  1-MAR-2012
// ===============================================================================
// Description:
//
// When board powers on, the green LEDs along the right edge scroll upward.
// If any button is pressed, the LEDs instead display the current toggle state of
// the buttons.  If no button is pressed in five seconds, then the LEDs return to
// displaying the upward-scrolling pattern.
//////////////////////////////////////////////////////////////////////////////////

module iceblink40_demo(
     input  CLK_3P3_MHZ,					  // 3.3 MHz clock from LTC1799 oscillator (pin A9)
     inout  BTN1,							  // Connection to cap-sense button BTN1 (pin B22)
     inout  BTN2,							  // Connection to cap-sense button BTN2 (pin B21)
     inout  BTN3,							  // Connection to cap-sense button BTN2 (pin A27)
     inout  BTN4,							  // Connection to cap-sense button BTN3 (pin A26)
     output LED1,                             // Drives LED LD2 (pin A29)
     output LED2,                             // Drives LED LD3 (pin B20)
     output LED3,                             // Drives LED LD4 (pin B19)
     output LED4,                             // Drives LED LD5 (pin A25)
);
   wire LED_CLOCK ;                         // Controls the flashing rate of LEDs in scroll mode (about 0.8 seconds)
   wire BTN_SAMPLE ;                        // Controls how often the capacitive-sense buttons are sampled
   wire [3:0] ROTATER ;                     // Generates the scrolling pattern for the LEDs
   wire [3:0] TIMEOUT_COUNT ;               // Counter that tracks last time any button was pressed
   wire TIMEOUT ;                           // Generates a time-out signal after 5 seconds if no button is pressed
   
   wire DIVIDER_TC ;                        // ???
   wire ANY_BTN_CHANGED ;                        // ???
   wire MODE ;                        // ???

   wire BTN1_TOGGLE_STATUS ;                // Holds current toggle status of BTN1
   wire BTN2_TOGGLE_STATUS ;                // Holds current toggle status of BTN2
   wire BTN3_TOGGLE_STATUS ;                // Holds current toggle status of BTN3
   wire BTN4_TOGGLE_STATUS ;                // Holds current toggle status of BTN4
   
   // Generates the LED_CLOCK and the BTN_SAMPLE signals
   // Also provides the prescaler for the 5 second time-out counter
   CLK_DIVIDER_3P3MHz CLK_DIV (
      .CLK_3P3MHz(CLK_3P3_MHZ),
      .LED_CLOCK(LED_CLOCK),
      .BTN_SAMPLE(BTN_SAMPLE),
      .TC(DIVIDER_TC)
   );
   
   // Simply scrolls the LEDs in one direction
   ROTATE_LED BLINKY (
      .CLK(LED_CLOCK),
      .LED(ROTATER)
   );
   
   // Chooses whether to scroll or to toggle the buttons
   DISPLAY_MODE SELECT_OUTPUT(
      .CLK(CLK_3P3_MHZ),
      .BTN_CHANGED(ANY_BTN_CHANGED),
      .TIMEOUT(TIMEOUT),
      .MODE(MODE)
   );
   
   // Generates a time-out reset signal if no button is pressed within last 5 seconds
   TIMEOUT_COUNTER DELAY_5_SECONDS (
      .CLK(CLK_3P3_MHZ) ,
      .ENABLE(DIVIDER_TC) ,
      .RESET(ANY_BTN_CHANGED) ,
      .TIMEOUT_COUNT(TIMEOUT_COUNT) ,
      .TIMEOUT(TIMEOUT)
   );

   // Capacitive-sense button controller
   CAPSENSEBUTTONS BUTTONS (
      .CLK(CLK_3P3_MHZ) ,
      .BTN1(BTN1) ,
      .BTN2(BTN2) ,
      .BTN3(BTN3) ,
      .BTN4(BTN4) ,
      .BTN_SAMPLE(BTN_SAMPLE),
      .ANY_BTN_CHANGED(ANY_BTN_CHANGED),
      .BTN1_TOGGLE_STATUS(BTN1_TOGGLE_STATUS) ,
      .BTN2_TOGGLE_STATUS(BTN2_TOGGLE_STATUS) ,
      .BTN3_TOGGLE_STATUS(BTN3_TOGGLE_STATUS) ,
      .BTN4_TOGGLE_STATUS(BTN4_TOGGLE_STATUS)
   );

   // Depending on the operating mode, the LEDs either scroll or can be individually toggled   
   assign LED1 = ( (MODE) ? BTN1_TOGGLE_STATUS : ROTATER[0] );		  
   assign LED2 = ( (MODE) ? BTN2_TOGGLE_STATUS : ROTATER[1] );		  
   assign LED3 = ( (MODE) ? BTN3_TOGGLE_STATUS : ROTATER[2] );		  
   assign LED4 = ( (MODE) ? BTN4_TOGGLE_STATUS : ROTATER[3] );

endmodule

module CAPSENSEBUTTONS (
    inout BTN1 ,
    inout BTN2 ,
    inout BTN3 ,
    inout BTN4 ,
    input BTN_SAMPLE ,
    input CLK ,
    output ANY_BTN_CHANGED ,
    output reg BTN1_TOGGLE_STATUS ,
    output reg BTN2_TOGGLE_STATUS ,
    output reg BTN3_TOGGLE_STATUS ,
    output reg BTN4_TOGGLE_STATUS
);

   reg STATUS_ALL_BUTTONS = 1'b0 ;          // Indicates the status of all four buttons
   reg STATUS_ALL_BUTTONS_LAST = 1'b0 ;     // Indicates the status during the last clock cycle
   reg SAMPLE_BTN1 = 1'b0 ;				  // Captures the value on BTN1 
   reg SAMPLE_BTN2 = 1'b0 ;				  // Captures the value on BTN2
   reg SAMPLE_BTN3 = 1'b0 ;				  // Captures the value on BTN3
   reg SAMPLE_BTN4 = 1'b0 ;				  // Captures the value on BTN4
   reg SAMPLE_BTN1_LAST = 1'b0 ;            // Hold the previous value of BNT1
   reg SAMPLE_BTN2_LAST = 1'b0 ;            // Hold the previous value of BNT2
   reg SAMPLE_BTN3_LAST = 1'b0 ;            // Hold the previous value of BNT3
   reg SAMPLE_BTN4_LAST = 1'b0 ;            // Hold the previous value of BNT4
   reg BTN1_TOGGLE_STATUS = 1'b0 ;          // Holds current toggle status of BTN1
   reg BTN2_TOGGLE_STATUS = 1'b0 ;          // Holds current toggle status of BTN2
   reg BTN3_TOGGLE_STATUS = 1'b0 ;          // Holds current toggle status of BTN3
   reg BTN4_TOGGLE_STATUS = 1'b0 ;          // Holds current toggle status of BTN4

   wire BTN1_CHANGED ;                      // Indicates that the value on BTN1 changed from the previous sample
   wire BTN2_CHANGED ;                      // Indicates that the value on BTN2 changed from the previous sample
   wire BTN3_CHANGED ;                      // Indicates that the value on BTN3 changed from the previous sample
   wire BTN4_CHANGED ;                      // Indicates that the value on BTN4 changed from the previous sample

   // Capacitive buttons are driven to a steady Low value to bleed off any charge, 
   // then allowed to float High.  An external resistor pulls each button pad High.
   assign BTN1 = ( (BTN_SAMPLE) ? 1'bZ : 1'b0 ) ;
   assign BTN2 = ( (BTN_SAMPLE) ? 1'bZ : 1'b0 ) ;
   assign BTN3 = ( (BTN_SAMPLE) ? 1'bZ : 1'b0 ) ;
   assign BTN4 = ( (BTN_SAMPLE) ? 1'bZ : 1'b0 ) ;
	 
   // Indicates when ANY of the four buttons goes High
   always @(posedge CLK)
      if (~BTN_SAMPLE) // Clear status when buttons driven low
         STATUS_ALL_BUTTONS <= 1'b0 ;
      else
         // Trigger whenever any button goes High, but only during first incident
         STATUS_ALL_BUTTONS <= (BTN1 | BTN2 | BTN3 | BTN4) & ~STATUS_ALL_BUTTONS_LAST ;
         
   // Indicates the last status of all four buttons
   always @(posedge CLK)
      if (~BTN_SAMPLE) // Clear status when buttons driven low
         STATUS_ALL_BUTTONS_LAST <= 1'b0 ;
      else if (STATUS_ALL_BUTTONS)
         STATUS_ALL_BUTTONS_LAST <= STATUS_ALL_BUTTONS ;

   always @(posedge CLK)
      if (STATUS_ALL_BUTTONS) // If any button went High after driving it low ...
      begin                   //    ... wait one clock cycle before re-sampling the pin value
         SAMPLE_BTN1 <= ~BTN1 ; // Invert polarity to make buttons active-High
         SAMPLE_BTN2 <= ~BTN2 ;
         SAMPLE_BTN3 <= ~BTN3 ;
         SAMPLE_BTN4 <= ~BTN4 ;
         SAMPLE_BTN1_LAST <= SAMPLE_BTN1 ; // Save last sample to see if the value changed
         SAMPLE_BTN2_LAST <= SAMPLE_BTN2 ;
         SAMPLE_BTN3_LAST <= SAMPLE_BTN3 ;
         SAMPLE_BTN4_LAST <= SAMPLE_BTN4 ;
      end

   // Toggle switch effect		  
   assign BTN1_CHANGED = ( SAMPLE_BTN1 & !SAMPLE_BTN1_LAST ) ; // Sampled pin value changed  
   assign BTN2_CHANGED = ( SAMPLE_BTN2 & !SAMPLE_BTN2_LAST ) ;	  
   assign BTN3_CHANGED = ( SAMPLE_BTN3 & !SAMPLE_BTN3_LAST ) ;	  
   assign BTN4_CHANGED = ( SAMPLE_BTN4 & !SAMPLE_BTN4_LAST ) ;	  

   // Indicates that one of the buttons was pressed
   assign ANY_BTN_CHANGED = ( BTN1_CHANGED | BTN2_CHANGED | BTN3_CHANGED | BTN4_CHANGED ) ;

   // If any button is pressed, toggle the button's current value    	 
   always @(posedge CLK)
   begin
      if (BTN1_CHANGED)
         BTN1_TOGGLE_STATUS <= ~(BTN1_TOGGLE_STATUS) ;
      if (BTN2_CHANGED)
         BTN2_TOGGLE_STATUS <= ~(BTN2_TOGGLE_STATUS) ;
      if (BTN3_CHANGED)
         BTN3_TOGGLE_STATUS <= ~(BTN3_TOGGLE_STATUS) ;
      if (BTN4_CHANGED)
         BTN4_TOGGLE_STATUS <= ~(BTN4_TOGGLE_STATUS) ;
end
   
endmodule

// The clock divider to generate the LED_CLOCK and BTN_SAMPLE signals
module CLK_DIVIDER_3P3MHz (
   input        CLK_3P3MHz,
   output       LED_CLOCK ,
   output       BTN_SAMPLE,
   output       TC
);

   reg [19:0] COUNTER = 20'b0 ;

   always @(posedge CLK_3P3MHz)
      COUNTER <= COUNTER + 1;
   
   assign LED_CLOCK = COUNTER[18] ;

   assign BTN_SAMPLE = COUNTER[19] ;
   
   assign TC = (COUNTER == 20'b11111111111111111111) ;
   
endmodule

// Generates a time-out reset signal if no button pressed within 5 seconds
module TIMEOUT_COUNTER (
   input CLK ,
   input ENABLE ,
   input RESET ,
   output reg [3:0] TIMEOUT_COUNT = 4'b0 ,
   output TIMEOUT
);
   
   always @(posedge CLK)
       if (RESET)
          TIMEOUT_COUNT <= 4'b0 ;
       else if (ENABLE)
          TIMEOUT_COUNT <= TIMEOUT_COUNT + 4'b0001 ;

   assign TIMEOUT = (TIMEOUT_COUNT == 4'b1111) ;           

endmodule

// Scrolls the LEDs
module ROTATE_LED (
   input        CLK,
   output [3:0] LED
);

reg [5:0] ROTATE = 8'b0 ;

always @(posedge CLK)
   ROTATE = ({ROTATE[4:0], ~ROTATE[5]}); 
   // ROTATE = ({~ROTATE[0], ROTATE[5:1]});   

   
assign LED = ROTATE[3:0] ;

endmodule

// Controls whether the LEDs scroll or show the current toggle state of the buttons
module DISPLAY_MODE (
   input CLK,
   input BTN_CHANGED,
   input TIMEOUT,
   output reg MODE
);

   always @(posedge CLK)
       // Enter toggle mode if BTN2 or BTN3 is pressed
      if ( BTN_CHANGED )
         MODE <= 1'b1 ;
      // If all the buttons are turned off, then re-enter scroll mode       
      else if ( TIMEOUT )
         MODE <= 1'b0 ;
   
endmodule
