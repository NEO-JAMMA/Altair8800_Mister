// pulse generator
module pulse_gen(
  input clk, 
  input trigger_in, 
  output pulse_out);

  parameter PULSE_LEN = 128;

  reg	[7:0] cnt;
  initial begin 
    cnt = 0;
  end

  always @(posedge clk)
    if(trigger_in && cnt == 0) begin 
      cnt <= 1; 
      end
    else if(!trigger_in && cnt >= PULSE_LEN) begin 
      cnt <= 0; 
      end
    else if(cnt != 0) begin 
      cnt <= cnt + 1; 
      end

  assign pulse_out = (cnt != 0);

endmodule
