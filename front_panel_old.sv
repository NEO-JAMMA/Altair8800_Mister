// front_panel

module front_panel (
		input  [10:0] current_x,
		input  [10:0] current_y,
		input  [11:0] background_pixel_color,
		input [3:0] cursor_index_x,
		input [4:0] cursor_index_y,
		input cursor_action,
		input clk,
		input leds_status[0:35],
		output [1:0]switches_status[0:24],
		output reg [11:0] pixel_color
		
);

// Sprites VRAM frame buffers
localparam BACKGROUND_WIDTH = 1280;
localparam BACKGROUND_HEIGHT = 500;

localparam SPRITE_WIDTH = 32;
localparam SPRITE_HEIGHT = 32;
localparam SPRITES_WIDTH = 32;
localparam SPRITES_HEIGHT = 256;
localparam SPRITES_IMAGE_DEPTH = SPRITES_WIDTH * SPRITES_HEIGHT; 
localparam SPRITES_IMAGE_A_WIDTH = 13;  // 2^13 = 256 x 32
localparam SPRITES_IMAGE_D_WIDTH = 6;   // colour bits per pixel
localparam SPRITES_IMAGE_MEMFILE ="./graphics/sprites.mif";

localparam SPRITES_PALETTE_DEPTH = 64; 
localparam SPRITES_PALETTE_A_WIDTH = 6;   // colour bits per pixel
localparam SPRITES_PALETTE_D_WIDTH = 12;
localparam SPRITES_PALETTE_MEMFILE ="./graphics/sprites_palette.mif";

wire [SPRITES_IMAGE_D_WIDTH-1:0] sprites_dataout;
reg [SPRITES_IMAGE_A_WIDTH-1:0] sprites_address;
wire [11:0] sprite_pixel_color;

sram_image 
#(
	.ADDR_WIDTH(SPRITES_IMAGE_A_WIDTH), 
	.DATA_WIDTH(SPRITES_IMAGE_D_WIDTH), 
	.DEPTH(SPRITES_IMAGE_DEPTH), 
	.MEMFILE(SPRITES_IMAGE_MEMFILE)
) sprites
(
	.address(sprites_address), 
	.clock(clk), 
	.q(sprites_dataout)
);

sram_image 
#(
	.ADDR_WIDTH(SPRITES_PALETTE_A_WIDTH), 
	.DATA_WIDTH(SPRITES_PALETTE_D_WIDTH), 
	.DEPTH(SPRITES_PALETTE_DEPTH), 
	.MEMFILE(SPRITES_PALETTE_MEMFILE)
) sprites_palette
(
	.address(sprites_dataout), 
	.clock(clk), 
	.q(sprite_pixel_color)
);

localparam LEDS_TOTAL_NUMBER = 36;
localparam SWITCHES_TOTAL_NUMBER = 25;

reg [10:0] leds_x[0:LEDS_TOTAL_NUMBER-1]; //36 leds
reg [9:0]  leds_y[0:LEDS_TOTAL_NUMBER-1];  //36 leds

reg [10:0] switches_x[0:SWITCHES_TOTAL_NUMBER-1]; //25 switches
reg [9:0]  switches_y[0:SWITCHES_TOTAL_NUMBER-1];  //25 switches

reg [10:0] current_sprite_x;
reg [9:0] current_sprite_y;
reg [4:0] cursor_index;
reg [3:0] sprite_index;

integer index_led;
integer index_sw;
integer led_count;
integer switch_count;

reg is_sprites_pixel;

always @(posedge clk) begin
	is_sprites_pixel = 0;

	//Leds
	if	(background_pixel_color == 12'b111100000000) begin // Led indicator color f00 is detected trigger fill of the array of leds
		current_sprite_x = current_x;
		current_sprite_y = current_y;	
	end
	
	// Test if sprite pixel is at current position
	if (current_y >= current_sprite_y  && current_y < (current_sprite_y + (SPRITE_HEIGHT)) && current_x >= current_sprite_x  && current_x < (current_sprite_x + (SPRITES_WIDTH))) begin
		sprite_index = 0;
		sprites_address = ((current_x - current_sprite_x) + SPRITES_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
		is_sprites_pixel = 1;
	end
	
	
	if	(is_sprites_pixel && sprite_pixel_color != 12'b001100110011) begin // Sprites pixel && !Transparent (Background color 333;)
		pixel_color = sprite_pixel_color;
	end
	else if (background_pixel_color == 12'b111100000000 || background_pixel_color == 12'b000011110000) begin // remove led (f00;) and switch (f0;) indicator color.
		pixel_color = 12'b001100110011; // Default background color 333;
	end
	else if (current_y >= BACKGROUND_HEIGHT) begin
		pixel_color = 12'b000000000000; // Black color 000;
	end
	else begin
		pixel_color = background_pixel_color;
	end
end

endmodule