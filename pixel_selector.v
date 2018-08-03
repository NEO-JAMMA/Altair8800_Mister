// pixel_selector

module	pixel_selector	(
		input  [10:0] current_x,
		input  [10:0] current_y,
		input  [11:0] background_color,
		input [10:0] cursor_x,
		input [9:0] cursor_y,
		input cursor_clicked,
		input clk,
		output reg [11:0] color
);

localparam LEDS_TOTAL_NUMBER = 36;
localparam SWITCHES_TOTAL_NUMBER = 25;

reg [3:0] sprite_index = 0;
reg [5:0] led_count = 0;
reg [4:0] switch_count = 0;
reg [10:0] leds_x[0:LEDS_TOTAL_NUMBER-1]; //36 leds
reg [9:0]  leds_y[0:LEDS_TOTAL_NUMBER-1];  //36 leds

reg [10:0] switches_x[0:SWITCHES_TOTAL_NUMBER-1]; //25 switches
reg [9:0]  switches_y[0:SWITCHES_TOTAL_NUMBER-1];  //25 switches

localparam BACKGROUND_WIDTH = 1280;
localparam BACKGROUND_HEIGHT = 500;

// Sprites VRAM frame buffers

reg [10:0] current_sprite_x;
reg [9:0] current_sprite_y;
reg [3:0] current_sprite_index;

wire [11:0] sprite_color;

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
reg [SPRITES_IMAGE_A_WIDTH-1:0] sprites_adress;

sram_image 
#(
	.ADDR_WIDTH(SPRITES_IMAGE_A_WIDTH), 
	.DATA_WIDTH(SPRITES_IMAGE_D_WIDTH), 
	.DEPTH(SPRITES_IMAGE_DEPTH), 
	.MEMFILE(SPRITES_IMAGE_MEMFILE)
) sprites
(
	.address(sprites_adress), 
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
	.q(sprite_color)
);

//SW 0f0
//LED f00

//always @(posedge clk) begin
//	if (current_y >= current_sprite_y  && 
//	current_y < (current_sprite_y + SPRITE_HEIGHT) && 
//	current_x >= current_sprite_x  && 
//	current_x < (current_sprite_x + SPRITES_WIDTH)) begin
//		sprites_adress = ((current_x - current_sprite_x) + SPRITES_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
//		if	(sprite_color == 12'b001100110011) begin //Transparent
//			color = background_color;
//		end
//		else begin
//			color = sprite_color;
//		end
//	end
//	else if (current_y >= BACKGROUND_HEIGHT) begin
//		color = 12'b000000000000;
//	end
//	else begin
//		color = background_color;
//	end
//end
integer index;
reg is_sprites;


always @(posedge clk) begin
	is_sprites = 0;
	
	//leds
	if	(background_color == 12'b111100000000 && led_count < LEDS_TOTAL_NUMBER) begin //led f00;
		leds_x[led_count] = current_x;
		leds_y[led_count] = current_y;
		led_count = led_count + 1;
	end
	else begin
		for (index = 0; index < LEDS_TOTAL_NUMBER; index=index+1) begin
			current_sprite_y = leds_y[index];
			current_sprite_x = leds_x[index];
			
			if (current_y >= current_sprite_y  && 
			current_y < (current_sprite_y + (SPRITE_HEIGHT/2)) && 
			current_x >= current_sprite_x  && 
			current_x < (current_sprite_x + (SPRITES_WIDTH/2))) begin
				sprite_index = 4;
				sprites_adress = ((current_x - current_sprite_x) + SPRITES_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
				is_sprites = 1;
			end
		end
	end
	
	//switches
	if	(background_color == 12'b000011110000 && switch_count < SWITCHES_TOTAL_NUMBER) begin //switch f00;
		switches_x[switch_count] = current_x;
		switches_y[switch_count] = current_y;
		switch_count = switch_count + 1;
	end
	else begin
		for (index = 0; index < SWITCHES_TOTAL_NUMBER; index=index+1) begin
			current_sprite_y = switches_y[index];
			current_sprite_x = switches_x[index];
			
			if (current_y >= current_sprite_y  && 
			current_y < (current_sprite_y + (SPRITE_HEIGHT/2)) && 
			current_x >= current_sprite_x  && 
			current_x < (current_sprite_x + (SPRITES_WIDTH/2))) begin
				sprite_index = 0;
				sprites_adress = ((current_x - current_sprite_x) + SPRITES_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
				is_sprites = 1;
			end
		end
	end
	
	if	(is_sprites && sprite_color != 12'b001100110011) begin //is_sprites && !Transparent
		color = sprite_color;
	end
	else if (background_color == 12'b111100000000 || background_color == 12'b000011110000) begin // remove led and switch indicator color.
		color = 12'b001100110011;
	end
	else begin
		color = background_color;
	end
	
end

endmodule