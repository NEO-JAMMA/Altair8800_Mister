module handle_two_pos_sw(
    input clk,
    input [1:0] sw_status,
    output reg o_state
    );

  // 2 pos switch
  // 0 - down
  // 1 - up
    always @(posedge clk)
    begin
        if (sw_status == 0) begin o_state <= 0; end
        if (sw_status == 1) begin o_state <= 1; end
    end

endmodule

module handle_three_pos_sw(
    input clk,
    input [1:0] sw_status,
    output reg o_state_up,
    output reg o_state_down
    );

  // 3 pos switch
  // 0 - middle
  // 1 - up
  // 2 - down
    always @(posedge clk)
    begin
        if (sw_status == 0) begin o_state_up <= 0; o_state_down <= 0; end
        if (sw_status == 1) begin o_state_up <= 0; o_state_down <= 1; end
        if (sw_status == 2) begin o_state_up <= 1; o_state_down <= 0; end
    end

endmodule


// front_panel_mapping
module	front_panel_mapping (
		input reset,
		input clk,
		input  [1:0] switches_status[0:24],	
		output [0:35] leds_status,
		// altair front panel LEDS from machine
		input [0:7] data,
	   input [0:15] addr,
	   input INTE,
		input PROT,
		input MEMR,
		input INP,
		input M1,
		input OUT,
		input HLTA,
		input STACK,
		input WO,
		input INT,
		input WAIT,
		input HLDA,
		// altair front panel SWITCHES to machine
		output [0:7] sense_addr_sw,
		output [0:7] data_addr_sw,
		output on_off_sw,
		output stop_run_sw,
		output step_sw,
		output examine_sw,
		output examine_next_sw,
		output deposit_sw,
		output deposit_next_sw,
		output reset_sw,
		output clear_sw,
		output protect_sw,
		output unprotect_sw,
		output aux1_sw,
		output aux2_sw
);

// LEDs
// 0 to 9 Status - INTE,PROT,MEMR,INP,M1,OUT,HLTA,STACK,WO,INT
// 10 to 17 Data
// 18 to 19 Wait HLDA
// 20 to 35 Address

// SWITCHEs
// 0 to 7 sense/addr
// 8 to 15 data/addr
// 16 to 24 control on/off, stop/run, single step_sw, examine_sw/ex next, deposit_sw/dep next, rest/clear_sw, protect_sw/unprotect_sw, aux, aux

localparam LEDS_TOTAL_NUMBER = 36;
localparam SWITCHES_TOTAL_NUMBER = 25;

integer index_led;
integer index_sw;

always @(posedge clk) begin

  // map LEDs
  if (on_off_sw == 1'b1)
    begin
      leds_status = 1'b000000000000000000000000000000000000;
    end
  else
    begin
      leds_status[0] = INTE;
      leds_status[1] = PROT;
      leds_status[2] = MEMR;
      leds_status[3] = INP;
      leds_status[4] = M1;
      leds_status[5] = OUT;
      leds_status[6] = HLTA;
      leds_status[7] = STACK;
      leds_status[8] = WO;
      leds_status[9] = INT;
      leds_status[10:17] = data;
      leds_status[18] = WAIT;
      leds_status[19] = HLDA;
      leds_status[20:35] = addr;  
    end
end

  // map SWITCHEs
  // 2 pos switch
  // 0 - down
  // 1 - up
  // 3 pos switch
  // 0 - middle
  // 1 - down
  // 2 - up
	handle_two_pos_sw sense_addr_sw_h0 ( .clk(clk), .sw_status(switches_status[0]), .o_state(sense_addr_sw[0]));
	handle_two_pos_sw sense_addr_sw_h1 ( .clk(clk), .sw_status(switches_status[1]), .o_state(sense_addr_sw[1]));
	handle_two_pos_sw sense_addr_sw_h2 ( .clk(clk), .sw_status(switches_status[2]), .o_state(sense_addr_sw[2]));
	handle_two_pos_sw sense_addr_sw_h3 ( .clk(clk), .sw_status(switches_status[3]), .o_state(sense_addr_sw[3]));
	handle_two_pos_sw sense_addr_sw_h4 ( .clk(clk), .sw_status(switches_status[4]), .o_state(sense_addr_sw[4]));
	handle_two_pos_sw sense_addr_sw_h5 ( .clk(clk), .sw_status(switches_status[5]), .o_state(sense_addr_sw[5]));
	handle_two_pos_sw sense_addr_sw_h6 ( .clk(clk), .sw_status(switches_status[6]), .o_state(sense_addr_sw[6]));
	handle_two_pos_sw sense_addr_sw_h7 ( .clk(clk), .sw_status(switches_status[7]), .o_state(sense_addr_sw[7]));
	
	handle_two_pos_sw data_addr_sw_h0 ( .clk(clk), .sw_status(switches_status[8]),  .o_state(data_addr_sw[0]));
	handle_two_pos_sw data_addr_sw_h1 ( .clk(clk), .sw_status(switches_status[9]),  .o_state(data_addr_sw[1]));
	handle_two_pos_sw data_addr_sw_h2 ( .clk(clk), .sw_status(switches_status[10]), .o_state(data_addr_sw[2]));
	handle_two_pos_sw data_addr_sw_h3 ( .clk(clk), .sw_status(switches_status[11]), .o_state(data_addr_sw[3]));
	handle_two_pos_sw data_addr_sw_h4 ( .clk(clk), .sw_status(switches_status[12]), .o_state(data_addr_sw[4]));
	handle_two_pos_sw data_addr_sw_h5 ( .clk(clk), .sw_status(switches_status[13]), .o_state(data_addr_sw[5]));
	handle_two_pos_sw data_addr_sw_h6 ( .clk(clk), .sw_status(switches_status[14]), .o_state(data_addr_sw[6]));
	handle_two_pos_sw data_addr_sw_h7 ( .clk(clk), .sw_status(switches_status[15]), .o_state(data_addr_sw[7]));

	handle_two_pos_sw on_off_sw_h ( .clk(clk), .sw_status(switches_status[16]), .o_state(on_off_sw));
	
	handle_two_pos_sw stop_run_sw_h ( .clk(clk), .sw_status(switches_status[17]), .o_state(stop_run_sw));
	
	handle_two_pos_sw step_sw_h ( .clk(clk), .sw_status(switches_status[18]), .o_state(step_sw));
	
	handle_three_pos_sw examine_sw_examine_next_sw_h ( .clk(clk), .sw_status(switches_status[19]), .o_state_up(examine_sw), .o_state_down(examine_next_sw));
	
	handle_three_pos_sw deposit_sw_deposit_next_sw_h ( .clk(clk), .sw_status(switches_status[20]), .o_state_up(deposit_sw), .o_state_down(deposit_next_sw));

	handle_three_pos_sw reset_clear_sw_h ( .clk(clk), .sw_status(switches_status[21]), .o_state_up(reset_sw), .o_state_down(clear_sw));
	
	handle_three_pos_sw protect_sw_unprotect_sw_h ( .clk(clk), .sw_status(switches_status[22]), .o_state_up(protect_sw), .o_state_down(unprotect_sw));
	
	handle_two_pos_sw aux1_sw_h ( .clk(clk), .sw_status(switches_status[23]), .o_state(aux1_sw));
	
	handle_two_pos_sw aux2_sw_h ( .clk(clk), .sw_status(switches_status[24]), .o_state(aux2_sw));

endmodule
