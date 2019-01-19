`include "../components/uart.v"

/*
 A demo of SB_MAC16 cell in 16x16 signed multiply mode.

 See also:

 https://github.com/YosysHQ/yosys/blob/master/techlibs/ice40/cells_sim.v
 (parameter definition)

 https://github.com/cliffordwolf/icestorm/blob/master/icefuzz/tests/sb_mac16.v
 (simple test)

 */

module multiply(input wire [15:0] a,
                input wire [15:0] b,
                output wire [31:0] result);
  SB_MAC16
    #(.A_SIGNED(1'b1),
      .B_SIGNED(1'b1),
      .TOPOUTPUT_SELECT(2'b11),
      .BOTOUTPUT_SELECT(2'b11)
    )
    i_sbmac16
    (
        .A(a),
        .B(b),
        .C(8'd0),
        .D(8'd0),
        .O(result),
        .CLK(1'b1),
        .IRSTTOP(1'b0),
        .IRSTBOT(1'b0),
        .ORSTTOP(1'b0),
        .ORSTBOT(1'b0),
        .AHOLD(1'b0),
        .BHOLD(1'b0),
        .CHOLD(1'b0),
        .DHOLD(1'b0),
        .OHOLDTOP(1'b0),
        .OHOLDBOT(1'b0),
        .OLOADTOP(1'b0),
        .OLOADBOT(1'b0),
        .ADDSUBTOP(1'b0),
        .ADDSUBBOT(1'b0),
        .CO(),
        .CI(1'b0),
        .ACCUMCI(),
        .ACCUMCO(),
        .SIGNEXTIN(),
        .SIGNEXTOUT()
     );
endmodule

module uart_node(input wire clk,
                 input wire [31:0] data,
                 input wire is_receiving,
                 input wire is_transmitting,
                 output reg transmit = 0,
                 output reg [7:0] tx_byte,
                 input wire received,
                 input wire [7:0] rx_byte);

  parameter digits = 8;
  reg [3:0] idx = 0;
  wire [3:0] digit = (data >> (4*(digits-1-idx)));
  reg [7:0] digit_ascii;

  always @(*) begin
    if (digit < 'hA)
      digit_ascii <= "0" + {4'b0, digit};
    else
      digit_ascii <= "A" - 8'hA + {4'b0, digit};
  end

  always @(posedge clk) begin
    // Only raise transmit for 1 cycle
    if (transmit)
      transmit <= 0;

    if (!transmit && !is_transmitting) begin
      transmit <= 1;
      tx_byte <= digit_ascii;
      if (idx == digits) begin
        tx_byte <= "\n";
        idx <= 0;
      end else
        idx <= idx + 1;
    end
  end

endmodule


module top(input wire  CLK,
           input wire  RX,
           output wire TX,
           output wire LED4);

  parameter baud_rate = 9600;

  wire       reset = 0;
  wire        transmit;
  wire [7:0]  tx_byte;
  wire       received;
  wire [7:0] rx_byte;
  wire       is_receiving;
  wire       is_transmitting;
  wire       recv_error;

  uart #(.baud_rate(9600), .sys_clk_freq(12000000))
  uart0(.clk(CLK),                        // The master clock for this module
        .rst(reset),                      // Synchronous reset
        .rx(RX),                // Incoming serial line
        .tx(TX),                // Outgoing serial line
        .transmit(transmit),              // Signal to transmit
        .tx_byte(tx_byte),                // Byte to transmit
        .received(received),              // Indicated that a byte has been received
        .rx_byte(rx_byte),                // Byte received
        .is_receiving(is_receiving),      // Low when receive line is idle
        .is_transmitting(is_transmitting),// Low when transmit line is idle
        .recv_error(recv_error)           // Indicates error in receiving packet.
        );

  wire [15:0] a = -300;
  wire [15:0] b = -300;
  wire [31:0] result;
  // should give 9000, or 32'h00015F90
  multiply m(a, b, result);

  uart_node un(.clk(CLK),
               .data(result),
               .is_receiving(is_receiving),
               .is_transmitting(is_transmitting),
               .transmit(transmit),
               .tx_byte(tx_byte),
               .received(received),
               .rx_byte(rx_byte));

  assign LED4 = (is_transmitting);
endmodule
