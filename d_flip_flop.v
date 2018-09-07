// D flip-flop
module d_flip_flop (
  input clk, 
  input reset,
  input [DATA_WIDTH-1:0] d, 
  output reg [DATA_WIDTH-1:0] q);
  
  parameter DATA_WIDTH = 1;
  

  always @(posedge clk or posedge reset)
  begin
    if (reset) begin
      q = 0;
    end else begin
      q = d;
    end
  end
endmodule