
module top(input wire  CLK,
           output wire P1A1,
           output wire P1A2,
           output wire P1A3,
           output wire P1A4,
           output wire P1A7,
           output wire P1A8,
           output wire P1A9,
           output wire P1A10,

           output wire LED1,
           output wire LED2,
           output wire LED3,
           output wire LED4);

  parameter n = 26;
  reg [n-1:0] clk_counter = 0;

  wire [7:0] ss_top;
  assign { P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 } = ss_top;

  always @(posedge CLK) begin
    clk_counter <= clk_counter + 1;
  end

  // Display 5 highest bits of counter with LEDs.
  assign LED1 = clk_counter[n-4];
  assign LED2 = clk_counter[n-3];
  assign LED3 = clk_counter[n-2];
  assign LED4 = clk_counter[n-1];

  assign ss_top = 0; //8'b11111111;
endmodule
