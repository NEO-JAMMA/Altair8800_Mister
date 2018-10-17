module rom_memory(
  input clk,
  input [ADDR_WIDTH-1:0] addr,
  input rd,
  output reg [DATA_WIDTH-1:0] data_out
);
  parameter FILENAME = "";

  parameter integer ADDR_WIDTH = 8;
  parameter integer DATA_WIDTH = 8;

  reg [DATA_WIDTH-1:0] rom[0:(2 ** ADDR_WIDTH)-1];
  
  initial
  begin
    if (FILENAME!="")
      $readmemh(FILENAME, rom);
  end

  always @(posedge clk)
  begin
	if (rd)
	  data_out <= rom[addr];
  end
endmodule
