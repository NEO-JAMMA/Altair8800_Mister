//============================================================================
//  Grant’s multi computer
// 
//  Port to MiSTer.
//
//  Based on Grant’s multi computer
//  http://searle.hostei.com/grant/
//  http://searle.hostei.com/grant/Multicomp/index.html
//	 and WiSo's collector blog (MiST port)
//	 https://ws0.org/building-your-own-custom-computer-with-the-mist-fpga-board-part-1/
//	 https://ws0.org/building-your-own-custom-computer-with-the-mist-fpga-board-part-2/
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

//TO DO
// fix edge background right / Pixel left
// Use Param for LEDS_TOTAL_NUMBER and SWITCHES_TOTAL_NUMBER
// Move background code to front_panel.sv



module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE
);

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;

assign LED_USER  = 0;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign VIDEO_ARX = 16;
assign VIDEO_ARY = 9;


`include "build_id.v"
localparam CONF_STR = {
	"Altair8800;;",
	"-;",
	"O78,Program,Prg1,Prg2,Prg3,Prg4;",
	"-;",
	"V,v1.1.",`BUILD_DATE
};

////////////////////   MACHINE   ///////////////////

wire rx; // serial rcv
wire tx; // serial xmt
wire sync; // cpu sync
wire interrupt_ack; // cpu
wire n_memWR; // cpu
wire io_stack; // cpu
wire halt_ack; // cpu
wire ioWR; // cpu
wire m1; // cpu
wire ioRD; // cpu
wire memRD; // cpu
wire inte_led; // cpu
wire [7:0] debugLED;
wire pauseModeSW; // run/stop
wire stepPB; // single step
wire [7:0] dataLEDs;  // display on data LEDs shows input data to processor
wire [15:0] addrLEDs; // display on addr LEDS
wire [7:0] dataOraddrIn;    // input switches for data bus and low addr bus
wire [7:0] addrOrSenseIn;   // input switches for high address bus and Sense SWitches
wire examinePB;       // show data on data LEDs for addrIn - momentary pos edge
wire examine_nextPB;   // show data on data LEDs for addrIn = addrIn + 1 - momentary pos edge
wire depositPB;       // write data selected on dataOraddrIn Switches to address on addrOut LEDS - momentary pos edge
wire deposit_nextPB;    // write data selected on dataOraddrIn Switches to address+1 on addrOut LEDS - momentary pos edge
wire resetPB;           // set PC to 0


altair machine
(
 .clk(CLK_50M & ~on_off),
 .reset(reset_machine),
 .rx(rx),
 .tx(tx),
 .sync(sync),
 .interrupt_ack(interrupt_ack),
 .n_memWR(n_memWR),
 .io_stack(io_stack),
 .halt_ack(halt_ack),
 .ioWR(ioWR),
 .m1(m1),
 .ioRD(ioRD),
 .memRD(memRD),
 .inte_o(inte_led),
 .hlda_o(hold_ack_led),
 .wait_o(wait_led),
 .debugLED(debugLED),
 .pauseModeSW(pauseModeSW),
 .stepPB(stepPB),
 .dataLEDs(dataLEDs),
 .addrLEDs(addrLEDs),
 .dataOraddrIn(dataOraddrIn),
 .addrOrSenseIn(addrOrSenseIn),
 .examinePB(examinePB),
 .examine_nextPB(examine_nextPB),
 .depositPB(depositPB),
 .deposit_nextPB(deposit_nextPB),
 .resetPB(resetPB)
);

////////////////////   CLOCKS   ///////////////////

wire locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(CLK_VIDEO),
	.locked(locked)
);


//////////////////   HPS I/O   ///////////////////
wire  [1:0] buttons;
wire [31:0] status;

wire [10:0] ps2_key;

wire forced_scandoubler;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(CLK_VIDEO),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.ps2_key(ps2_key),
	
	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler)
);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1];

wire reset_machine;

pulse_gen reset_pulse
(
  .clk(CLK_50M),
  .trigger_in( reset | on_off),
  .pulse_out(reset_machine)
);


typedef enum {prg1='b00, prg2='b01, prg3='b10, prg4='b11} prg_type_enum;
wire [1:0] prg_type = status[8:7];

///////////////////////////////////////////////////
// 0 to 9 Status
// 10 to 17 Data
// 18 to 19 Wait HLDA
// 20 to 35 Address
reg [0:35] leds_status;
reg [1:0]  switches_status[0:24];
reg aux1;
reg aux2;
reg on_off;
reg protect;
reg unprotect;
reg clear;
reg prot_led;
reg wait_led;
reg hold_ack_led;

front_panel_mapping	front_panel_mapping	
(
	.clk(CLK_50M),
	.leds_status(leds_status),
	.switches_status(switches_status),
		
		// altair front panel LEDS from machine
		.data(dataLEDs),
	   .addr(addrLEDs),
	   .INTE(inte_led),
		.PROT(prot_led),
		.MEMR(memRD),
		.INP(ioRD),
		.M1(m1),
		.OUT(ioWR),
		.HLTA(halt_ack),
		.STACK(io_stack),
		.WO(~n_memWR),
		.INT(interrupt_ack),
		.WAIT(wait_led),
		.HLDA(hold_ack_led),
		
		// altair front panel SWITCHES to machine
		.sense_addr(addrOrSenseIn),
		.data_addr(dataOraddrIn),
		.on_off(on_off),
		.stop_run(pauseModeSW),
		.step(stepPB),
		.examine(examinePB),
		.examine_next(examine_nextPB),
		.deposit(depositPB),
		.deposit_next(deposit_nextPB),
		.reset(resetPB),
		.clear(clear),
		.protect(protect),
		.unprotect(unprotect),
		.aux1(aux1),
		.aux2(aux2)
);


front_panel front_panel	
(
	.reset(reset),
	.clk(CLK_VIDEO),
	.leds_status_in(leds_status),
	.switches_status(switches_status),
	.ps2_key(ps2_key),
	.vga_r(R),
	.vga_g(G),
	.vga_b(B),
	.vga_hs(HS),
	.vga_vs(VS),
	.vga_h_blank(HBlank),
	.vga_v_blank(VBlank)
);


assign CE_PIXEL = 1;
wire HBlank, VBlank;

wire [7:0] R,G,B;
wire HS,VS;

video_cleaner video_cleaner
(
	.clk_vid(CLK_VIDEO),
	.ce_pix(CE_PIXEL),
	.R(R),
	.G(G),
	.B(B),
	.HSync(HS),
	.VSync(VS),
	.HBlank(HBlank),
	.VBlank(VBlank),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(VGA_DE)
);

endmodule
