module delay
(
  input clk,
  input reset,
  input [DATA_WIDTH-1:0] data_in,
  output [DATA_WIDTH-1:0] data_out
);

parameter DEPTH = 5;
parameter DATA_WIDTH = 1;
wire [DATA_WIDTH-1:0] connect_wire [DEPTH:0];

assign data_out = connect_wire[DEPTH];
assign connect_wire[0] = data_in;

genvar i;
generate
   for (i=1; i <= DEPTH; i=i+1) begin : generate_block_identifier
      d_flip_flop #(.DATA_WIDTH(DATA_WIDTH)
		) DFF 
		(
		  .clk(clk), 
		  .reset(reset),
      .d(connect_wire[i-1]), 
		  .q(connect_wire[i])
		);
   end
endgenerate

endmodule

