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


//module handle_two_pos_sw_ary
//(
//  input clk,
//  input [DATA_WIDTH-1:0] sw_status[1:0],
//  output [DATA_WIDTH-1:0] o_state
//);
//
//parameter DATA_WIDTH = 1;
//
//
//genvar i;
//generate
//   for (i=0; i < DATA_WIDTH; i=i+1) begin : generate_block_identifier
//      handle_two_pos_sw #(.DATA_WIDTH(DATA_WIDTH)
//		) handle 
//		(
//		  .clk(clk), 
//        .sw_status(sw_status[i]), 
//		  .o_state(o_state[i])
//		);
//   end
//endgenerate
//
//endmodule

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
		output [0:7] sense_addr,
		output [0:7] data_addr,
		output on_off,
		output stop_run,
		output step,
		output examine,
		output examine_next,
		output deposit,
		output deposit_next,
		output reset,
		output clear,
		output protect,
		output unprotect,
		output aux1,
		output aux2
);

// LEDs
// 0 to 9 Status - INTE,PROT,MEMR,INP,M1,OUT,HLTA,STACK,WO,INT
// 10 to 17 Data
// 18 to 19 Wait HLDA
// 20 to 35 Address

// SWITCHEs
// 0 to 7 sense/addr
// 8 to 15 data/addr
// 16 to 24 control on/off, stop/run, single step, examine/ex next, deposit/dep next, rest/clear, protect/unprotect, aux, aux

localparam LEDS_TOTAL_NUMBER = 36;
localparam SWITCHES_TOTAL_NUMBER = 25;

integer index_led;
integer index_sw;

always @(posedge clk) begin

  // map LEDs
  if (on_off == 1'b1)
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

	
//	leds_status = '{
//	addr[0], 
//	addr[1], 
//	addr[2], 
//	addr[3], 
//	addr[4], 
//	addr[5], 
//	addr[6], 
//	addr[7], 
//	addr[8], 
//	addr[9], 
//	addr[10], 
//	addr[11], 
//	addr[12], 
//	addr[13], 
//	addr[14], 
//	addr[15], 
//	HLDA, WAIT, 
//	data[0], 
//	data[1], 
//	data[2], 
//	data[3], 
//	data[4], 
//	data[5], 
//	data[6], 
//	data[7], 
//	INT, WO, STACK, HLTA, OUT, M1, INP, MEMR, PROT, INTE};



	

  
//	for (index_sw = 0; index_sw < SWITCHES_TOTAL_NUMBER; index_sw = index_sw + 1) begin
//		
//		if(switches_status[index_sw] != 0) begin // Toggle switches - Addresses and On/Off
//			leds_status[index_sw] = 1;
//		end
//		else begin
//			leds_status[index_sw] = 0;
//		end
//	end
	
end

  // map SWITCHEs
  // 2 pos switch
  // 0 - down
  // 1 - up
  // 3 pos switch
  // 0 - middle
  // 1 - down
  // 2 - up
//	sense_addr = switches_status[0:7];
	handle_two_pos_sw sense_addr_h0 ( .clk(clk), .sw_status(switches_status[0]), .o_state(sense_addr[0]));
	handle_two_pos_sw sense_addr_h1 ( .clk(clk), .sw_status(switches_status[1]), .o_state(sense_addr[1]));
	handle_two_pos_sw sense_addr_h2 ( .clk(clk), .sw_status(switches_status[2]), .o_state(sense_addr[2]));
	handle_two_pos_sw sense_addr_h3 ( .clk(clk), .sw_status(switches_status[3]), .o_state(sense_addr[3]));
	handle_two_pos_sw sense_addr_h4 ( .clk(clk), .sw_status(switches_status[4]), .o_state(sense_addr[4]));
	handle_two_pos_sw sense_addr_h5 ( .clk(clk), .sw_status(switches_status[5]), .o_state(sense_addr[5]));
	handle_two_pos_sw sense_addr_h6 ( .clk(clk), .sw_status(switches_status[6]), .o_state(sense_addr[6]));
	handle_two_pos_sw sense_addr_h7 ( .clk(clk), .sw_status(switches_status[7]), .o_state(sense_addr[7]));
	
//	data_addr = switches_status[8:15];
	handle_two_pos_sw data_addr_h0 ( .clk(clk), .sw_status(switches_status[8]),  .o_state(data_addr[0]));
	handle_two_pos_sw data_addr_h1 ( .clk(clk), .sw_status(switches_status[9]),  .o_state(data_addr[1]));
	handle_two_pos_sw data_addr_h2 ( .clk(clk), .sw_status(switches_status[10]), .o_state(data_addr[2]));
	handle_two_pos_sw data_addr_h3 ( .clk(clk), .sw_status(switches_status[11]), .o_state(data_addr[3]));
	handle_two_pos_sw data_addr_h4 ( .clk(clk), .sw_status(switches_status[12]), .o_state(data_addr[4]));
	handle_two_pos_sw data_addr_h5 ( .clk(clk), .sw_status(switches_status[13]), .o_state(data_addr[5]));
	handle_two_pos_sw data_addr_h6 ( .clk(clk), .sw_status(switches_status[14]), .o_state(data_addr[6]));
	handle_two_pos_sw data_addr_h7 ( .clk(clk), .sw_status(switches_status[15]), .o_state(data_addr[7]));

//on_off = switches_status[16];
	handle_two_pos_sw on_off_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[16]), 
	  .o_state(on_off)
	);
//	stop_run = switches_status[17];
	handle_two_pos_sw stop_run_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[17]), 
	  .o_state(stop_run)
	);
//	step = switches_status[18];
	handle_two_pos_sw step_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[18]), 
	  .o_state(step)
	);
//	examine = switches_status[19];
//	examine_next = switches_status[19];
	handle_three_pos_sw examine_examine_next_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[19]), 
	  .o_state_up(examine),
	  .o_state_down(examine_next)
	);
//	deposit = switches_status[20];
//	deposit_next = switches_status[20];
	handle_three_pos_sw deposit_deposit_next_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[20]), 
	  .o_state_up(deposit),
	  .o_state_down(deposit_next)
	);
//	reset = switches_status[21];
//	clear = switches_status[21];
	handle_three_pos_sw reset_clear_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[21]), 
	  .o_state_up(reset),
	  .o_state_down(clear)
	);
//	protect = switches_status[22];
//	unprotect = switches_status[22];
	handle_three_pos_sw protect_unprotect_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[22]), 
	  .o_state_up(protect),
	  .o_state_down(unprotect)
	);
//	aux1 = switches_status[23];
	handle_two_pos_sw aux1_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[23]), 
	  .o_state(aux1)
	);
//	aux2 = switches_status[24];
	handle_two_pos_sw aux2_h
	(
	  .clk(clk), 
	  .sw_status(switches_status[24]), 
	  .o_state(aux2)
	);

endmodule