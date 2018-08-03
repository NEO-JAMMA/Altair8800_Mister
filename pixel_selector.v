// pixel_selector

module	pixel_selector	(
		input  [10:0] current_x,
		input  [10:0] current_y,
		input [10:0] current_sprite_x,
		input [9:0] current_sprite_y,
		input [3:0] sprite_index,
		input  [11:0] background_color,
		input clk,
		output reg [11:0] color
);


localparam BACKGROUND_WIDTH = 1280;
localparam BACKGROUND_HEIGHT = 500;

// Sprites VRAM frame buffers


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

always @(posedge clk) begin
	if (current_y >= current_sprite_y  && 
	current_y < (current_sprite_y + SPRITE_HEIGHT) && 
	current_x >= current_sprite_x  && 
	current_x < (current_sprite_x + SPRITES_WIDTH))begin
		sprites_adress = ((current_x - current_sprite_x) + SPRITES_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
		if	(sprite_color == 12'b001100110011) begin //Transparent
			color = background_color;
		end
		else begin
			color = sprite_color;
		end
	end
	else if (current_y >= BACKGROUND_HEIGHT) begin
		color = 12'b000000000000;
	end
	else begin
		color = background_color;
	end
end

endmodule