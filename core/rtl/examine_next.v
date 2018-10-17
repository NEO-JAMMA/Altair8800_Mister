/*
EXM NXT 
Examine Next operates in the same manner as Examine, except 
a NOP is strobed onto the data lines through 4 gates of IC D 
and 4 gates of ICE. This causes the processor to step the program counter. 

*/

module examine_next(
  input clk,
  input reset,
  input rd,
  input examine,
  input [7:0] lo_addr,
  input [7:0] hi_addr,
  output reg [7:0] data_out,
  output examine_latch
);

  reg [2:0] state = 3'b000;
  reg prev_rd = 1'b0;
  reg en_lt = 1'b0;
  
  always @(posedge clk)
    begin
      if (reset)
      begin
		  en_lt <= 1'b0;
		end  
      else if (examine)
      begin
		  state <= 3'b000;
        en_lt <= 1'b1;
		end  
      else
		begin
   	  if (rd && prev_rd==1'b0)
		  begin
          case (state)
            3'b000 : begin
              en_lt <= 1'b1;
              state <= 3'b001;
				end
            3'b001 : begin
              data_out <= 8'b11000011; // JMP
              state <= 3'b010;
            end
            3'b010 : begin
              data_out <= lo_addr;
              state <= 3'b011;
            end
            3'b011 : begin
              data_out <= hi_addr;
              state <= 3'b100;
            end
            3'b100 : begin						
              data_out <= 8'b00000000; // NOP
              state <= 3'b101;
            end
            3'b101 : begin						
              state <= 3'b101;
   		     en_lt <= 1'b0;
            end
          endcase
		  end
		  prev_rd = rd;  
      end
    end
	 assign examine_latch = en_lt;
endmodule