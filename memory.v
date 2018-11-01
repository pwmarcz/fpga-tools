module memory(input wire        clk,
              input wire        read,
              input wire        write,
              input wire [15:0]  addr,
              input wire [7:0]  write_byte,
              output reg [7:0] read_byte);

  parameter size = 'h1000;
  parameter initialize = 0;

  reg [7:0] mem[0:size-1];

  integer   i;

  initial
    begin
      if (initialize)
        for (i = 0; i < size; i = i + 1)
          mem[i] = 0;
    end

  always @(posedge clk) begin
    if (read) begin
      read_byte <= mem[addr];
      $display($time, " memory: read  %H (%b) addr %H", mem[addr], mem[addr], addr);
    end
    if (write) begin
      mem[addr] <= write_byte;
      $display($time, " memory: write %H (%b) addr %H", write_byte, write_byte, addr);
    end
  end // always @ (posedge clk)
endmodule // memory
