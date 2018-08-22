// front_panel

module front_panel (
		input  [10:0] current_x,
		input  [10:0] current_y,
		input [3:0] cursor_index_x,
		input [4:0] cursor_index_y,
		input cursor_action,
		input clk,
		input clk_sram,
		input leds_status[0:35],
		output [1:0]switches_status[0:24],
		output reg [11:0] pixel_color
		
);


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
reg [BACKGROUND_PALETTE_D_WIDTH-1:0] background_pixel_color;

sram_image 
#(
	.ADDR_WIDTH(BACKGROUND_IMAGE_A_WIDTH), 
	.DATA_WIDTH(BACKGROUND_IMAGE_D_WIDTH), 
	.DEPTH(BACKGROUND_IMAGE_DEPTH), 
	.MEMFILE(BACKGROUND_IMAGE_MEMFILE)
) background
(
	.address((current_y * BACKGROUND_WIDTH + current_x) - BACKGROUND_WIDTH -1), // -1 for sram_image access take 1 clock
	.clock(clk_sram), 
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
	.clock(clk_sram), 
	.q(background_pixel_color)
);


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
wire [SPRITES_PALETTE_D_WIDTH-1:0] sprite_pixel_color;

sram_image 
#(
	.ADDR_WIDTH(SPRITES_IMAGE_A_WIDTH), 
	.DATA_WIDTH(SPRITES_IMAGE_D_WIDTH), 
	.DEPTH(SPRITES_IMAGE_DEPTH), 
	.MEMFILE(SPRITES_IMAGE_MEMFILE)
) sprites
(
	.address(sprites_address), 
	.clock(clk_sram), 
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
	.clock(clk_sram), 
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
	cursor_index = cursor_index_x + cursor_index_y;

	//Leds
	if	(background_pixel_color == 12'b111100000000 && led_count < LEDS_TOTAL_NUMBER) begin // Led indicator color f00 is detected trigger fill of the array of leds
		leds_x[led_count] = current_x;
		leds_y[led_count] = current_y;
		led_count = led_count + 1;
	end
	else begin
		for (index_led = 0; index_led < LEDS_TOTAL_NUMBER; index_led = index_led + 1) begin // The array is complete so paint the sprites pixels
			current_sprite_y = leds_y[index_led] - 6;  // Adjust sprites to background.
			current_sprite_x = leds_x[index_led] - 10; // The pixel indicator color is at the top of a 22*22 square.
			
			// Test if sprite pixel is at current position
			if (current_y >= current_sprite_y  && current_y < (current_sprite_y + (SPRITE_HEIGHT)) && current_x >= current_sprite_x  && current_x < (current_sprite_x + (SPRITES_WIDTH))) begin
				if (leds_status[index_led] == 1) begin
					sprite_index = 3;
				end
				else begin
					sprite_index = 4;
				end
				

				sprites_address = ((current_x - current_sprite_x) + SPRITES_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
				is_sprites_pixel = 1;
			end
		end
	end
	
	//Switches
	if	(background_pixel_color == 12'b000011110000 && switch_count < SWITCHES_TOTAL_NUMBER) begin // Switch indicator color 0f0 or f0 is detected trigger fill of the array of switches
		switches_x[switch_count] = current_x;
		switches_y[switch_count] = current_y;
		switch_count = switch_count + 1;
	end
	else begin
		for (index_sw = 0; index_sw < SWITCHES_TOTAL_NUMBER; index_sw = index_sw + 1) begin // The array is complete so paint the sprites pixels
			current_sprite_y = switches_y[index_sw] - 6;
			current_sprite_x = switches_x[index_sw] - 10;
			
			// Test if sprite pixel is at current position
			if (current_y >= current_sprite_y  && current_y < (current_sprite_y + (SPRITE_HEIGHT)) && current_x >= current_sprite_x  && current_x < (current_sprite_x + (SPRITES_WIDTH))) begin
				if(index_sw < 17) begin // Toggle switches - Addresses and On/Off
					sprite_index = 1;
				end
				else begin // On/Off/On switches
					sprite_index = 0;
				end
				
				if (cursor_action != 0 && index_sw == cursor_index) begin // Change switch on current cursor if needed
					sprite_index = sprite_index + cursor_action;
					switches_status[index_sw] = 1;
				end
				else begin
					switches_status[index_sw] = 0;
				end

				sprites_address = ((current_x - current_sprite_x) + SPRITES_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
				
				if (sprite_pixel_color != 12'b000110111111 || index_sw == cursor_index) begin // Remove cursor indicator if cursor is not needed (cursor 1bf);
					is_sprites_pixel = 1;
				end
			end
		end
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