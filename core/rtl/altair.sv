//
// Global system clock
//
`define  SYS_CLOCK                  50000000

module altair(
  input clk,
  input pauseModeSW,
  input stepPB,
  input reset,
  input rx,
  input hold_in,
  input ready_in,
  output tx,
  output sync,
  output reg interrupt_ack,
  output reg n_memWR,
  output reg io_stack,
  output reg halt_ack,
  output reg ioWR,
  output reg m1,
  output reg ioRD,
  output reg memRD,
  output inte_o,
  output hlda_o,
  output wait_o,
  output reg [7:0] debugLED,
  output reg [7:0] dataLEDs,
  output reg [15:0] addrLEDs,
  input [7:0] dataOraddrIn,
  input [7:0] addrOrSenseIn,
  input examinePB,
  input examine_nextPB,
  input depositPB,
  input deposit_nextPB,
  input resetPB,
  input [2:0] prg_sel,
  input enable_turn_mon
);
  
  `include "common.sv"
  
  reg intr = 0;	
  reg [7:0] idata;
  wire [15:0] addr;
  wire wr_n;
  wire inta_n;
  wire [7:0] odata;
  reg f1, f2;
  reg  [2:0] div;
  reg [15:0] div1ms;
  reg ms, intrq;
  wire rst_n;


  ////////////////////   STEP & GO   ////////////////////
  reg		stepkey;
  reg		onestep;
  //reg cpu_flag;
  //reg[10:0] cpu_cnt;
  wire cpu_ce2;
  wire sio_clk;

  ///////// SINGLE STEP CONTROL ////////////
//  clk_divn_odd #(.N(25),.WIDTH(5)) cpu_clk_mod(.clk(clk), .reset(reset), .clk_out(cpu_ce2)); // 2 Mhz out
//  clk_div cpu_clk_mod(.clk(clk), .rst(reset), .clk_div(cpu_ce2)); // 2 Mhz out
//  clk_divn_odd #(.N(25),.WIDTH(5)) sio_clk_mod(.clk(clk), .reset(reset), .clk_out(sio_clk)); // 2 Mhz out
  frequency_divider #(.N(25),.WIDTH(20)) freq_cpu
  (
    .clk_in(clk),
    .clk_out(cpu_ce2),
    .rst(reset)
  );  
  
  frequency_divider #(.N(25),.WIDTH(20)) freq_sio
  (
    .clk_in(clk),
    .clk_out(sio_clk),
    .rst(reset)
  );  

  // for ce_2 this is 41 * 50,000,000 Mhz / 1024 = 2,001,953.125 Mhz
  always @(posedge clk) begin
    stepkey <= stepPB;
    onestep <= stepkey & ~stepPB;
    //cpu_cnt <= cpu_cnt + 11'd41;
    //cpu_flag <= cpu_flag^cpu_ce2;
  end
  //wire cpu_ce2 = (cpu_flag^cpu_cnt[10]);

  wire cpu_ce = onestep | (cpu_ce2 & examine_en) | (cpu_ce2 & reset_en) | (cpu_ce2 & examine_next_en) | (cpu_ce2 & deposit_examine_next_en) | (cpu_ce2 & ~pauseModeSW);

  reg[7:0] sysctl;

  wire [7:0] examine_out;
  wire [7:0] examine_next_out;
  wire [7:0] deposit_next_out;
  wire [7:0] reset_out;
  wire [7:0] sense_sw_out;
  wire [7:0] turnmon_out;
  wire [7:0] stack_out;
  wire [7:0] rammain_out;
  wire [7:0] boot_out;
  wire [7:0] sio_out;
  
  reg [7:0] sio_in;
  wire [7:0] deposit_in;
  wire [7:0] deposit_next_in;
  reg [7:0] stack_in;
  reg [7:0] rammain_in;

  wire boot;

  wire depositPB_DB;
  wire depositPB_OK;

  wire deposit_nextPB_DB;
  wire deposit_nextPB_OK;

  wire examinePB_DB;
  wire examinePB_OK;

  wire examine_nextPB_DB;
  wire examine_nextPB_OK;

  wire resetPB_DB;
  wire resetPB_OK;

  reg wr_stack;
  reg wr_rammain;
  reg wr_sio;

  wire rd;

  reg rd_boot;
  reg rd_stack;
  reg rd_rammain;
  reg rd_turnmon;
  reg rd_sio;
  reg rd_examine;
  reg rd_examine_next;
  reg rd_deposit_examine_next;
  reg rd_reset;
  reg rd_sense;
  
  wire deposit_latch;
  wire deposit_en;
  wire depositPB_DN;
  wire depositPB_UP;

  wire deposit_next_latch;
  wire deposit_next_examine_latch;
  wire deposit_next_en;
  wire deposit_examine_next_en;
  wire deposit_nextPB_DN;
  wire deposit_nextPB_UP;

  wire examine_latch;
  wire examine_en;
  wire examinePB_DN;
  wire examinePB_UP;

  wire examine_next_latch;
  wire examine_next_en;
  wire examinePB_next_DN;
  wire examinePB_next_UP;
  
  wire reset_latch;
  wire reset_en;
  wire resetPB_DN;
  wire resetPB_UP;

  reg  [7:0] rcnt = 8'h00;
  assign rst_n = (rcnt == 8'hFF);
  
  assign depositPB_OK = depositPB && pauseModeSW;
  assign deposit_en = deposit_latch && pauseModeSW;

  assign deposit_nextPB_OK = deposit_nextPB && pauseModeSW;
  assign deposit_next_en = deposit_next_latch && pauseModeSW;
  assign deposit_examine_next_en = deposit_next_examine_latch && pauseModeSW;

  assign examinePB_OK = examinePB && pauseModeSW;
  assign examine_en = examine_latch && pauseModeSW;

  assign examine_nextPB_OK = examine_nextPB && pauseModeSW;
  assign examine_next_en = examine_next_latch && pauseModeSW;

  assign resetPB_OK = resetPB && pauseModeSW;
  assign reset_en = reset_latch && pauseModeSW;

///////// CHIP SELECT - input to cpu////////////
  always @(*)
    begin
      rd_examine = 0;
      rd_examine_next = 0;
      rd_reset = 0;
      rd_boot = 0;
      rd_stack = 0;
      rd_rammain = 0;
      rd_turnmon = 0;
      rd_sio = 0;
		rd_sense = 0;
		
      casex ({boot, ioRD, examine_en, examine_next_en, deposit_examine_next_en, reset_en, addr[15:8]})
        // Deposit Examine Next
        {6'b000010,8'bxxxxxxxx}: begin idata = deposit_next_out; rd_deposit_examine_next = rd; end // any address
        // Examine
        {6'b001000,8'bxxxxxxxx}: begin idata = examine_out; rd_examine = rd; end                   // any address
        // Examine Next
        {6'b000100,8'bxxxxxxxx}: begin idata = examine_next_out; rd_examine_next = rd; end         // any address
        // Reset
        {6'b000001,8'bxxxxxxxx}: begin idata = reset_out; rd_reset = rd; end                       // any address
        // Turn-key BOOT
        {6'b100000,8'bxxxxxxxx}: begin idata = boot_out; rd_boot = rd; end                         // any address
        
		  // MEM MAP
        {6'b000000,8'b000xxxxx}: begin idata = rammain_out; rd_rammain = rd; end                   // 0x0000-0x1fff basic
		  
        {6'b000000,8'b11111011}: begin idata = stack_out; rd_stack = rd; end                       // 0xfb00-0xfbff stack
        {6'b000000,8'b11111101}: begin idata = turnmon_out; rd_turnmon = rd & enable_turn_mon; end // 0xfd00-0xfdff turn-key rom
      endcase

      casex ({ioRD, examine_en, examine_next_en, reset_en, addr[7:0]})
        // I/O MAP - addr[15:8] == addr[7:0] for this section
        {4'b1000,8'b000x000x}: begin idata = sio_out; rd_sio = rd; end                             // 0x00-0x01 0x10-0x11 
        {4'b1000,8'b11111111}: begin idata = sense_sw_out; rd_sense = rd; end                      // sense switch port at 0xff
      endcase

    end

///////// CHIP SELECT - output from cpu or deposit ////////////
  always @(*)
    begin
      wr_stack = 0;
      wr_sio = 0;
      wr_rammain = 0;

      casex ({ioWR, examine_en, examine_next_en, deposit_en, deposit_next_en, reset_en, addr[15:8]})
        
		  // MEM MAP
        {6'b000000,8'b000xxxxx}: begin rammain_in = odata; wr_rammain = ~wr_n; end      // 0x0000-0x1fff basic
        {6'b000000,8'b11111011}: begin stack_in = odata; wr_stack = ~wr_n; end          // 0xfb00-0xfbff
        {6'b000100,8'bxxxxxxxx}: 
		    begin 
			   casex({ioWR, deposit_en, addr[15:8]})
			     {2'b01,8'b000xxxxx}: begin rammain_in = deposit_in; wr_rammain = 1; end      // 0x0000-0x1fff
			     {2'b01,8'b11111011}: begin stack_in = deposit_in; wr_stack = 1; end          // 0xfb00-0xfbff
			   endcase
			 end
        {6'b000010,8'bxxxxxxxx}: 
		    begin 
			   casex({ioWR, deposit_next_en, addr[15:8]})
			     {2'b01,8'b000xxxxx}: begin rammain_in = deposit_next_in; wr_rammain = 1; end // 0x0000-0x1fff
			     {2'b01,8'b11111011}: begin stack_in = deposit_next_in; wr_stack = 1; end     // 0xfb00-0xfbff
			   endcase
			 end
        // 0xfd00-0xfdff read-only turn-key rom
      endcase
      casex ({ioWR, examine_en, examine_next_en, addr[7:0]})
        // I/O MAP - addr[15:8] == addr[7:0] for this section
        {3'b100,8'b000x000x}: begin sio_in = odata; wr_sio = ~wr_n; end                 // 0x00-0x01 0x10-0x11 
      endcase
	end

///////// CLOCKS and RESET ////////////
  always @(posedge clk)
    begin
      div <= div + 3'b001;
      f1  <= div[0];
      f2  <= ~div[0];

      if (div1ms == ((`SYS_CLOCK/1000)-1))
        begin
          div1ms <= 16'h0000;
          ms <= 1;
        end
      else
        begin
          div1ms <= div1ms + 16'h0001;
          ms <= 0;
        end

      if (ms) 
        intrq <= 1;
      if (interrupt_ack) 
        intrq <= 0;

      if (reset)
        begin 
          rcnt <= 8'h00; 
        end
      else
        if (rcnt != 8'hFF) 
          rcnt <= rcnt + 8'h01;
    end

///////// STATUS system control ////////////
  always @(posedge clk) 
    begin
      reg old_sync;
      old_sync <= sync;
      if(~old_sync & sync) 
        sysctl <= odata;
    end

  always @(*)
    begin
      interrupt_ack <= sysctl[0];
      n_memWR <= ~sysctl[1];
      io_stack <= sysctl[2];
      halt_ack <= sysctl[3];
      ioWR <= sysctl[4];
      m1 <= sysctl[5];
      ioRD <= sysctl[6];
      memRD <= sysctl[7];

      debugLED[0] <= rd_boot;
      debugLED[1] <= rd_turnmon;
      debugLED[2] <= rd_stack;
      debugLED[3] <= wr_stack;
      debugLED[4] <= rd_rammain;
      debugLED[5] <= wr_rammain;
      debugLED[6] <= rd_sio;
      debugLED[7] <= wr_sio;
		
      dataLEDs <= idata;
		  addrLEDs <= addr;
    end


///////// CPU ////////////
vm80a_core cpu
(
   .pin_clk(clk),
   .pin_f1(cpu_ce),
   .pin_f2(~cpu_ce),
   .pin_reset(~rst_n),
   .pin_a(addr),
   .pin_dout(odata),
   .pin_din(idata),
   .pin_hold(hold_in),
   .pin_ready(ready_in),
   .pin_int(intr),
   .pin_wr_n(wr_n),
   .pin_dbin(rd),
   .pin_inte(inte_o),
   .pin_hlda(hlda_o),
   .pin_wait(wait_o),
   .pin_sync(sync)
);


///////// BOOT ROM TURN-KEY ////////////
  jmp_boot boot_ff
  (
    .clk(clk),
    .reset(~rst_n),
    .rd(rd_boot),
    .lo_addr(8'h00), // if turnmon use FD00
    .hi_addr(enable_turn_mon ? 8'hfd : 8'h00), // if turnmon use FD00 else 0000
    .data_out(boot_out),
    .valid(boot)
  );


///////// DEPOSIT ////////////
  debounce_pb deposit_DB (
    .clk(clk), 
    .i_btn(depositPB_OK), 
    .o_state(depositPB_DB),
    .o_ondn(depositPB_DN),
    .o_onup(depositPB_UP)
  );  

  deposit deposit_ff
  (
    .clk(clk),
    .reset(~rst_n),
    .deposit(depositPB_DN),
    .data_sw(dataOraddrIn),
    .data_out(deposit_in),
	  .deposit_latch(deposit_latch)
  );
  
  
///////// DEPOSIT NEXT ////////////
  debounce_pb deposit_next_DB (
    .clk(clk), 
    .i_btn(deposit_nextPB_OK), 
    .o_state(deposit_nextPB_DB),
    .o_ondn(deposit_nextPB_DN),
    .o_onup(deposit_nextPB_UP)
  );  

  deposit_next deposit_next_ff
  (
    .clk(clk),
    .reset(~rst_n),
	  .rd(rd_deposit_examine_next),
    .deposit(deposit_nextPB_DN),
    .data_sw(dataOraddrIn),
    .deposit_out(deposit_next_in),
	  .deposit_latch(deposit_next_latch),
    .data_out(deposit_next_out),
	  .examine_latch(deposit_next_examine_latch)
  );
  
  
///////// EXAMINE ////////////
  debounce_pb examine_DB (
    .clk(clk), 
    .i_btn(examinePB_OK), 
    .o_state(examinePB_DB),
    .o_ondn(examinePB_DN),
    .o_onup(examinePB_UP)
  );  

  examine examine_ff
  (
    .clk(clk),
    .reset(~rst_n),
	  .rd(rd_examine),
    .examine(examinePB_DN),
    .data_out(examine_out),
    .lo_addr(dataOraddrIn),
    .hi_addr(addrOrSenseIn),
	  .examine_latch(examine_latch)
  );
  
///////// EXAMINE NEXT ////////////
  debounce_pb examine_next_DB (
    .clk(clk), 
    .i_btn(examine_nextPB_OK), 
    .o_state(examine_nextPB_DB),
    .o_ondn(examine_nextPB_DN),
    .o_onup(examine_nextPB_UP)
  );  

  examine_next examine_next_ff
  (
    .clk(clk),
    .reset(~rst_n),
	  .rd(rd_examine_next),
    .examine(examine_nextPB_DN),
    .data_out(examine_next_out),
	  .examine_latch(examine_next_latch)
  );
  
///////// RESET ////////////
  debounce_pb reset_DB (
    .clk(clk), 
    .i_btn(resetPB_OK), 
    .o_state(resetPB_DB),
    .o_ondn(resetPB_DN),
    .o_onup(resetPB_UP)
  );  

  reset reset_ff
  (
    .clk(clk),
    .reset(~rst_n),
	  .rd(rd_reset),
    .reset_in(resetPB_DN),
    .data_out(reset_out),
	  .reset_latch(reset_latch)
  );

///////// SENSE SWITCHES ////////////
  sense_switch sense_sw
  (
    .clk(clk),
	  .rd(rd_sense),
    .data_out(sense_sw_out),
    .switch_settings(addrOrSenseIn) // 0xFD for basic
  );

 
  //rom_memory #(.DATA_WIDTH(8),.ADDR_WIDTH(8),.FILENAME("../roms/altair/turnmon.bin.mem")) turnmon(.clk(clk),.addr(addr[7:0]),.rd(rd_turnmon),.data_out(turnmon_out));
  turnmon_mem #(.DATA_WIDTH(8),.ADDR_WIDTH(8)) turnmon(.clk(clk),.addr(addr[7:0]),.rd(rd_turnmon),.data_out(turnmon_out));

  ram_memory #(.DATA_WIDTH(8),.ADDR_WIDTH(8)) stack(.clk(clk),.addr(addr[7:0]),.data_in(stack_in),.rd(rd_stack),.we(wr_stack),.data_out(stack_out));

  //ram_memory #(.DATA_WIDTH(8),.ADDR_WIDTH(13),.FILENAME("../roms/altair/basic4k32.bin.mem")) mainmem(.clk(clk),.addr(addr[12:0]),.data_in(rammain_in),.rd(rd_rammain),.we(wr_rammain),.data_out(rammain_out));
  
  //basic4k32_mem #(.DATA_WIDTH(8),.ADDR_WIDTH(13)) mainmem(.clk(clk),.addr(addr[12:0]),.data_in(rammain_in),.rd(rd_rammain),.we(wr_rammain),.data_out(rammain_out));
  samples_mem #(.DATA_WIDTH(8),.ADDR_WIDTH(13)) mainmem(.prg_sel(prg_sel),.clk(clk),.addr(addr[12:0]),.data_in(rammain_in),.rd(rd_rammain),.we(wr_rammain),.data_out(rammain_out));
  //ram_memory #(.DATA_WIDTH(8),.ADDR_WIDTH(13),.FILENAME("../roms/altair/tinybasic-1.0.bin.mem")) mainmem(.clk(clk),.addr(addr[12:0]),.data_in(rammain_in),.rd(rd_rammain),.we(wr_rammain),.data_out(rammain_out));

  //ram_memory #(.DATA_WIDTH(8),.ADDR_WIDTH(13),.FILENAME("../roms/altair/serialporttest.bin.mem")) mainmem(.clk(clk),.addr(addr[12:0]),.data_in(rammain_in),.rd(rd_rammain),.we(wr_rammain),.data_out(rammain_out));

  reg [7:0] prg1_in;
  wire [7:0] prg1_out;
  reg wr_prg1;
  reg rd_prg1;
  prg_memory #(.DATA_WIDTH(8),.ADDR_WIDTH(8),.RAM_DATA_LEN(8),.RAM_DATA('{8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07})) prg_1(.clk(clk),.addr(addr[7:0]),.data_in(prg1_in),.rd(rd_prg1),.we(wr_prg1),.data_out(prg1_out));

///////// TERMINAL SERIAL ////////////
  mc6850 #(.CLOCK(2000000),.BAUD(19200)) sio
  (
    .clk(sio_clk),
    //.clk(cpu_ce2),
    .reset(~rst_n),
    .addr(addr[0]),
    .data_in(sio_in),
    .rd(rd_sio),
    .we(wr_sio),
    .data_out(sio_out),
    .ce(0),
    .rx(rx),
    .tx(tx)
  );

endmodule
