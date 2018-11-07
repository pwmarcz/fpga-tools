`include "display_commands.v"

`define CMD_NONE          2'b00
`define CMD_RESET         2'b01
`define CMD_SEND_COMMAND  2'b10
`define CMD_SEND_DATA     2'b11

module display_spi(input wire clk,
                   input wire [2:0] cmd,
                   input wire [7:0] tx_byte,

                   output wire      ready,
                   output reg       spi_din,
                   output reg       spi_clk,
                   output reg       spi_cs,
                   output reg       spi_dc,
                   output reg       spi_rst);
  reg [4:0] divider;
  reg [7:0] data;
  reg [3:0] data_counter = 0;

  reg reset = 0;
  reg send = 0;
  assign ready = !reset && !send && cmd == `CMD_NONE;

  initial begin
    spi_clk = 0;
    spi_rst = 1;
    spi_cs = 1;
  end

  always @(posedge clk) begin
    if (!reset && !send) begin
      case (cmd)
        `CMD_RESET: begin
          reset <= 1;
          spi_rst <= 0;
        end
        `CMD_SEND_COMMAND, `CMD_SEND_DATA: begin
          send <= 1;
          spi_dc <= (cmd == `CMD_SEND_DATA);
          data <= tx_byte;
          data_counter <= 8;
        end
      endcase
    end // if (!reset && !send)

    if (divider < 10) begin
      divider <= divider + 1;
    end else begin
      divider <= 0;
      spi_clk <= ~spi_clk;

      if (spi_clk) begin
        if (reset) begin
          spi_rst <= 1;
          if (spi_rst == 1) begin
            reset <= 0;
          end
        end

        if (send) begin
          if (data_counter > 0) begin
            spi_cs <= 0;
            spi_din <= data[7];
            data <= data << 1;
            data_counter <= data_counter - 1;
          end else begin
            spi_cs <= 1;
            send <= 0;
          end
        end
      end
    end
  end
endmodule // display_spi


module display(input wire clk,
               input wire ready,
               output reg [2:0] cmd,
               output reg [7:0] tx_byte);

  localparam MAX_COMMAND = 9;
  localparam
    STATE_RESET = 0,
    STATE_INIT = 1,
    STATE_IDLE = 2;

  reg [7:0] commands[0:MAX_COMMAND];
  reg [8:0] command_idx = 0;

  reg [3:0] state = STATE_RESET;

  initial begin
    cmd = `CMD_RESET;

    commands[0] <= `SSD1306_DISPLAYOFF;
    commands[1] <= `SSD1306_CHARGEPUMP;
    commands[2] <= 'h14;
    commands[3] <= `SSD1306_SETCONTRAST;
    commands[4] <= 'h70;
    commands[5] <= `SSD1306_SETPRECHARGE;
    commands[6] <= 'hF1;
    commands[7] <= `SSD1306_DISPLAYALLON_RESUME;
    commands[8] <= `SSD1306_NORMALDISPLAY;
    commands[9] <= `SSD1306_DISPLAYON;
  end

  always @(posedge clk) begin
    case (state)
      STATE_RESET: begin
        cmd <= `CMD_NONE;
        if (ready) begin
          state <= STATE_INIT;
        end
      end
      STATE_INIT: begin
        cmd <= `CMD_NONE;
        if (ready) begin
          cmd <= `CMD_SEND_COMMAND;
          tx_byte <= commands[command_idx];

          if (command_idx < MAX_COMMAND) begin
            command_idx <= command_idx + 1;
          end else begin
            state <= STATE_IDLE;
          end
        end
      end
      STATE_IDLE: begin
        cmd <= `CMD_NONE;
      end
    endcase // case (state)
  end
endmodule // display


module display_demo(input wire  iCE_CLK,
                    output wire PIO1_02,
                    output wire PIO1_03,
                    output wire PIO1_04,
                    output wire PIO1_05,
                    output wire PIO1_06,
                    output wire LED0,
	            output wire LED1,
	            output wire LED2,
	            output wire LED3,
                    output wire LED4);

  wire ready;
  wire [2:0] cmd;
  wire [7:0] tx_byte;

  display_spi dspi(.clk(iCE_CLK),
                   .ready(ready),
                   .cmd(cmd),
                   .tx_byte(tx_byte),
                   .spi_din(PIO1_02),
                   .spi_clk(PIO1_03),
                   .spi_cs(PIO1_04),
                   .spi_dc(PIO1_05),
                   .spi_rst(PIO1_06));

  display d(.clk(iCE_CLK),
            .ready(ready),
            .cmd(cmd),
            .tx_byte(tx_byte));

  assign LED0 = 0;
  assign LED1 = 0;
  assign LED2 = 0;
  assign LED3 = 0;
  assign LED4 = 0;
endmodule // keyboard
