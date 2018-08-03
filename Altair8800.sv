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
// 1024*768
// altair 1/2
// fix edge
//increase color to 8 bits

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
	"V,v1.1.",`BUILD_DATE
};

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
	.forced_scandoubler(forced_scandoubler),


);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1];

///////////////////////////////////////////////////


wire [10:0] x;  // current pixel x position: 11-bit value: 0-2048
wire [9:0] y;  // current pixel y position: 10-bit value: 0-1024
reg [11:0] color;
reg [11:0] background_color;

//wire sq_a = ((x > 120) & (y >  40) & (x < 280) & (y < 200));
//wire sq_b = ((x > 200) & (y > 120) & (x < 360) & (y < 280));
//wire sq_c = ((x > 280) & (y > 200) & (x < 440) & (y < 360));
//wire sq_d = ((x > 360) & (y > 280) & (x < 520) & (y < 440));

//		.r({8{sq_b}}),
//		.g({8{sq_a | sq_d}}),
//		.b({8{sq_c}}),
///////////////////////////////////////////////////


// Background VRAM frame buffers
localparam BACKGROUND_WIDTH = 1280;
localparam BACKGROUND_HEIGHT = 500;
localparam BACKGROUND_IMAGE_DEPTH = BACKGROUND_WIDTH * BACKGROUND_HEIGHT; 
localparam BACKGROUND_IMAGE_A_WIDTH = 20;  // 2^20 > 1280 x 500
localparam BACKGROUND_IMAGE_D_WIDTH = 6;   // colour bits per pixel
localparam BACKGROUND_IMAGE_MEMFILE ="./graphics/background.mif";

localparam BACKGROUND_PALETTE_DEPTH = 64; 
localparam BACKGROUND_PALETTE_A_WIDTH = 6;   // colour bits per pixel
localparam BACKGROUND_PALETTE_D_WIDTH = 12;
localparam BACKGROUND_PALETTE_MEMFILE ="./graphics/background_palette.mif";

reg [BACKGROUND_IMAGE_D_WIDTH-1:0] background_dataout;


sram_image 
#(
	.ADDR_WIDTH(BACKGROUND_IMAGE_A_WIDTH), 
	.DATA_WIDTH(BACKGROUND_IMAGE_D_WIDTH), 
	.DEPTH(BACKGROUND_IMAGE_DEPTH), 
	.MEMFILE(BACKGROUND_IMAGE_MEMFILE)
) background
(
	.address(y * BACKGROUND_WIDTH + x), 
	.clock(CLK_VIDEO), 
	.q(background_dataout)
);

sram_image 
#(
	.ADDR_WIDTH(BACKGROUND_PALETTE_A_WIDTH), 
	.DATA_WIDTH(BACKGROUND_PALETTE_D_WIDTH), 
	.DEPTH(BACKGROUND_PALETTE_DEPTH), 
	.MEMFILE(BACKGROUND_PALETTE_MEMFILE)
) background_palette
(
	.address(background_dataout), 
	.clock(CLK_VIDEO), 
	.q(background_color)
);

reg [10:0] current_sprite_x = 100;
reg [9:0] current_sprite_y = 100;
reg [3:0] sprite_index = 0;

always @(negedge CLK_VIDEO) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10] && ~ps2_key[9]) begin
		case(ps2_key[7:0])
			8'h1d : current_sprite_y = current_sprite_y - 1; // W
			8'h1c : current_sprite_x = current_sprite_x - 1; // A
			8'h1b : current_sprite_y = current_sprite_y + 1; // s
			8'h23 : current_sprite_x = current_sprite_x + 1; // D
			8'h29 : sprite_index = sprite_index + 1; // SPACE
		endcase
	end
end

pixel_selector pixel_selector	
(
		.current_x(x),
		.current_y(y),
		.current_sprite_x(current_sprite_x),
		.current_sprite_y(current_sprite_y),
		.sprite_index(sprite_index),
		.background_color(background_color),
		.clk(CLK_VIDEO),
		.color(color)

);

assign CE_PIXEL = 1;
wire HBlank, VBlank;

wire [7:0] R,G,B;
wire HS,VS;

vga_driver vga_driver	
(
		.clk(CLK_VIDEO),
		.reset(reset),
		.r({8{color[11:8]}}),
		.g({8{color[7:4]}}),
		.b({8{color[3:0]}}),
		.current_x(x),
		.current_y(y),
		.vga_r(R),
		.vga_g(G),
		.vga_b(B),
		.vga_hs(HS),
		.vga_vs(VS),
		.vga_h_blank(HBlank),
		.vga_v_blank(VBlank)

);

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
