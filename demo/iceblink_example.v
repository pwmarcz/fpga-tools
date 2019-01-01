`timescale 1ns / 1ps

module iceblink40_demo(
     input  CLK_3P3_MHZ,   // 3.3 MHz clock from LTC1799 oscillator (pin A9)
     output LED1,          // Drives LED LD1 (pin A29)
     output LED2,          // Drives LED LD2 (pin B20)
     output LED3,          // Drives LED LD3 (pin B19)
     output LED4,          // Drives LED LD4 (pin A25)
);
   wire LED_CLOCK;      // Controls the flashing rate of LEDs in scroll mode (about 0.8 seconds)
   wire [3:0] ROTATER;  // Generates the scrolling pattern for the LEDs

   // Generates the LED_CLOCK signal
   CLK_DIVIDER_3P3MHz CLK_DIV (
      .CLK_3P3MHz(CLK_3P3_MHZ),
      .LED_CLOCK(LED_CLOCK),
   );

   // Simply scrolls the LEDs in one direction
   ROTATE_LED BLINKY (
      .CLK(LED_CLOCK),
      .LED(ROTATER)
   );

   // Depending on the operating mode, the LEDs either scroll or can be individually toggled
   assign LED1 = ROTATER[0];
   assign LED2 = ROTATER[1];
   assign LED3 = ROTATER[2];
   assign LED4 = ROTATER[3];

endmodule

// The clock divider to generate the LED_CLOCK signal
module CLK_DIVIDER_3P3MHz (
   input        CLK_3P3MHz,
   output       LED_CLOCK
);
   reg [18:0] COUNTER = 19'b0 ;

   always @(posedge CLK_3P3MHz)
      COUNTER <= COUNTER + 1;

   assign LED_CLOCK = COUNTER[18];
endmodule

// Scrolls the LEDs
module ROTATE_LED (
   input        CLK,
   output [3:0] LED
);
   reg [5:0] ROTATE = 8'b0 ;

   always @(posedge CLK)
      ROTATE = ({ROTATE[4:0], ~ROTATE[5]});
   assign LED = ROTATE[3:0] ;

endmodule
