`include "display_commands.v"


module display(input wire clk,
               output reg spi_din,
               output reg spi_clk,
               output reg spi_cs,
               output reg spi_dc,
               output reg spi_rst
               );

  localparam MAX_COMMAND = 9;
  localparam
    STATE_RESET = 0,
    STATE_INIT = 1,
    STATE_IDLE = 2;

  reg [23:0] divider;
  reg [7:0]  command;
  reg [7:0]  commands[0:MAX_COMMAND];
  reg [3:0]  command_counter = 8;
  reg [8:0]  command_idx = 0;

  reg [3:0]  state = STATE_RESET;

  initial begin
    spi_clk = 0;

    commands[0] = `SSD1306_DISPLAYOFF;
    commands[1] = `SSD1306_CHARGEPUMP;
    commands[2] = 'h14;
    commands[3] = `SSD1306_SETCONTRAST;
    commands[4] = 'h70;
    commands[5] = `SSD1306_SETPRECHARGE;
    commands[6] = 'hF1;
    commands[7] = `SSD1306_DISPLAYALLON_RESUME;
    commands[8] = `SSD1306_NORMALDISPLAY;
    commands[9] = `SSD1306_DISPLAYON;
    command = commands[0];
  end

  always @(posedge clk) begin
    if (divider == 10) begin
      divider <= 0;
      spi_clk <= ~spi_clk;
    end else begin
      divider <= divider + 1;
    end
  end

  always @(negedge spi_clk) begin
    case (state)
      STATE_RESET: begin
        spi_rst <= 0;
        state <= STATE_INIT;
      end
      STATE_INIT: begin
        spi_rst <= 1;

        if (command_counter > 0) begin
          command_counter <= command_counter - 1;
          spi_cs <= 0;
          spi_dc <= 0;
          spi_din <= command[7];
          command <= command << 1;
        end else begin
          spi_cs <= 1;
          if (command_idx < MAX_COMMAND) begin
            command_idx <= command_idx + 1;
            command <= commands[command_idx + 1];
            command_counter <= 8;
          end else begin
            state <= STATE_IDLE;
          end
        end // else: !if(command_counter > 0)
      end // case: STATE_INIT
      STATE_IDLE: begin
        spi_cs <= 1;
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

  display disp(iCE_CLK, PIO1_02, PIO1_03, PIO1_04, PIO1_05, PIO1_06);

  assign LED0 = 0;
  assign LED1 = 0;
  assign LED2 = 0;
  assign LED3 = 0;
  assign LED4 = 0;
endmodule // keyboard
