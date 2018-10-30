module memory(input wire        clk,
              input wire        read,
              input wire        write,
              input wire [15:0]  addr,
              input wire [7:0]  write_byte,
              output wire [7:0] read_byte);

  parameter size = 'h1000;
  parameter initialize = 0;

  reg [7:0] mem[0:size-1];

  assign read_byte = read ? mem[addr] : 0;
  integer   i;

  initial
    begin
      if (initialize)
        for (i = 0; i < size; i = i + 1)
          mem[i] = 0;
    end

  always @(posedge clk) begin
    if (read) begin
      $display("Reading %H from %H", read_byte, addr);
    end
    if (write) begin
      $display("Storing %H at %H", write_byte, addr);
      mem[addr] <= write_byte;
    end
  end // always @ (posedge clk)
endmodule // memory
