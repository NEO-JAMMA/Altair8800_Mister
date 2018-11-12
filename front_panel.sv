// front_panel

module front_panel (
  input  reset,
  input  clk,
  input  [0:35] leds_status_in,
  output [1:0] switches_status[0:24],
  input  [10:0] ps2_key,
  output [7:0] vga_r,
  output [7:0] vga_g,
  output [7:0] vga_b ,
  output vga_hs,
  output vga_vs,
  output vga_blank, 
  output vga_h_blank, 
  output vga_v_blank
);

	localparam BACKGROUND_WIDTH = 1280;
	localparam BACKGROUND_HEIGHT = 500;
	localparam BACKGROUND_IMAGE_DEPTH = BACKGROUND_WIDTH * BACKGROUND_HEIGHT; 
	localparam BACKGROUND_IMAGE_A_WIDTH = 20;  // 2^20 > 1280 x 500
	localparam BACKGROUND_IMAGE_D_WIDTH = 4;   // colour bits per pixel
	localparam BACKGROUND_IMAGE_MEMFILE ="./graphics/background.mif";

	localparam BACKGROUND_PALETTE_DEPTH = 16; 
	localparam BACKGROUND_PALETTE_A_WIDTH = 4;   // colour bits per pixel
	localparam BACKGROUND_PALETTE_D_WIDTH = 12;
	localparam BACKGROUND_PALETTE_MEMFILE ="./graphics/background_palette.mif";

	  // Sprites VRAM frame buffers
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

	wire [SPRITES_IMAGE_A_WIDTH-1:0] sprites_address;
	wire [SPRITES_IMAGE_D_WIDTH-1:0] sprites_dataout;
	wire [11:0] sprite_pixel_color;

	wire [BACKGROUND_IMAGE_A_WIDTH-1:0] background_address;
	wire [BACKGROUND_IMAGE_D_WIDTH-1:0] background_dataout;
	wire [11:0] background_pixel_color;

	reg [11:0]  pixel_color;
	wire [10:0] current_x;  // current pixel x position: 11-bit value: 0-2048
	wire [9:0]  current_y;  // current pixel y position: 10-bit value: 0-1024
	
	reg [0:35] leds_status;
	
	d_flip_flop #(.DATA_WIDTH(36)) DFF_LED 
		(
		  .clk(vga_v_blank), 
		  .reset(reset),
        .d(leds_status_in), 
		  .q(leds_status)
		);

	sram_image 
	#(
		.ADDR_WIDTH(BACKGROUND_IMAGE_A_WIDTH), 
		.DATA_WIDTH(BACKGROUND_IMAGE_D_WIDTH), 
		.DEPTH(BACKGROUND_IMAGE_DEPTH), 
		.MEMFILE(BACKGROUND_IMAGE_MEMFILE)
	) background
	(
		.address(background_address), 
		.clock(clk), 
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
		.clock(clk), 
		.q(background_pixel_color)
	);


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


	localparam LEDS_COUNT = 36;
	localparam SWITCHES_COUNT = 25;
	localparam SWITCHES_ST_COUNT = 18;
	localparam SWITCHES_ST_AUX1_INDEX = 23;
	localparam SWITCHES_ST_AUX2_INDEX = 24;
	localparam SWITCHES_ON_OFF_INDEX = 16;
	localparam SWITCHES_STOP_RUN_INDEX = 17;

	reg [10:0] leds_x[0:LEDS_COUNT-1]; //36 leds
	reg [9:0]  leds_y[0:LEDS_COUNT-1];  //36 leds

	reg [10:0] switches_x[0:SWITCHES_COUNT-1]; //25 switches
	reg [9:0]  switches_y[0:SWITCHES_COUNT-1];  //25 switches


	wire [10:0] current_sprite_x = 0;
	wire [9:0] current_sprite_y = 0;
	//wire [5:0] sprite_index = 0;

	integer index_led;
	integer index_sw;
	integer led_count;
	integer switch_count;

	wire useSpriteColor;
	wire useSpriteColorDelayed;
	wire cursorSelectedDelayed;
	  
	wire [4:0] cursor_index;
	wire [5:0] sprite_index;
	wire [5:0] sw_sprite_index[0:24];
	wire [1:0] cursor_action;
	  
	cursor 
	#(
	 .SWITCHES_ST_COUNT(SWITCHES_ST_COUNT),
	 .SWITCHES_ST_AUX1_INDEX(SWITCHES_ST_AUX1_INDEX),
	 .SWITCHES_ST_AUX2_INDEX(SWITCHES_ST_AUX2_INDEX)
	) cursor
	(
	 .clk(clk),
	 .reset(reset),
	 .ps2_key(ps2_key),
	 .cursor_index(cursor_index),
	 .cursor_action(cursor_action)
	);
	  
	delay
	#(
	 .DEPTH(4),
	 .DATA_WIDTH(11)
	)  x_delay
	(
	 .clk(clk),
	 .reset(reset),
	 .data_in(cnt_h),
	 .data_out(h_cntr)
	);

	delay
	#(
	 .DEPTH(4),
	 .DATA_WIDTH(11)
	)  y_delay
	(
	 .clk(clk),
	 .reset(reset),
	 .data_in(cnt_v),
	 .data_out(v_cntr)
	);

	delay
	#(
	 .DEPTH(4),
	 .DATA_WIDTH(1)
	)  useSpriteColor_delay
	(
	 .clk(clk),
	 .reset(reset),
	 .data_in(useSpriteColor),
	 .data_out(useSpriteColorDelayed)
	);

	delay
	#(
	 .DEPTH(4),
	 .DATA_WIDTH(1)
	)  cursorSelected_delay
	(
	 .clk(clk),
	 .reset(reset),
	 .data_in(cursorSelected),
	 .data_out(cursorSelectedDelayed)
	);

	always @(posedge clk) begin
		background_address = current_y * BACKGROUND_WIDTH + current_x;
		useSpriteColor = 0;
		cursorSelected = 0;

		if	(reset) begin // reset switches to startup state
      switch_count = 0;
      led_count = 0;
		end

		//Leds
		if	(background_pixel_color == 12'b111100000000 && led_count < LEDS_COUNT) begin // Led indicator color f00 is detected trigger fill of the array of leds
			leds_x[led_count] = current_x;
			leds_y[led_count] = current_y;
			led_count = led_count + 1;
		end
		else begin
			for (index_led = 0; index_led < LEDS_COUNT; index_led = index_led + 1) begin // The array is complete so paint the sprites pixels
				current_sprite_y = leds_y[index_led] - 6;  // Adjust sprites to background.
				current_sprite_x = leds_x[index_led] - 10; // The pixel indicator color is at the top of a 22*22 square.

				// Test if sprite pixel is at current position
				if (current_y >= current_sprite_y  && current_y < (current_sprite_y + SPRITE_HEIGHT) && current_x >= current_sprite_x  && current_x < (current_sprite_x + SPRITE_WIDTH))begin
					if (leds_status[index_led] == 1) begin
					  sprite_index = 3;
					end
					else begin
					  sprite_index = 4;
					end

					sprites_address = ((current_x - current_sprite_x) + SPRITE_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sprite_index);
					useSpriteColor = 1;
				end
			end
		end


		//Switches
		if	(background_pixel_color == 12'b000011110000 && switch_count < SWITCHES_COUNT) begin // Switch indicator color 0f0 or f0 is detected trigger fill of the array of switches
			switches_x[switch_count] = current_x;
			switches_y[switch_count] = current_y;
			if(switch_count < SWITCHES_ST_COUNT || switch_count == SWITCHES_ST_AUX1_INDEX || switch_count == SWITCHES_ST_AUX2_INDEX) begin 	// Single Throw switches - Addresses and On/Off
				if (switch_count == SWITCHES_ON_OFF_INDEX || switch_count == SWITCHES_STOP_RUN_INDEX) begin
          sw_sprite_index[switch_count] = 2;
          switches_status[switch_count] = 1;
        end
        else begin
          sw_sprite_index[switch_count] = 1;
          switches_status[switch_count] = 0;
        end
			end
			else begin 												// Double Throw Toggle switches On/Off/On
				sw_sprite_index[switch_count] = 0;
			end
			switch_count = switch_count + 1;
		end
		else begin
			for (index_sw = 0; index_sw < SWITCHES_COUNT; index_sw = index_sw + 1) begin // The array is complete so paint the sprites pixels
				current_sprite_y = switches_y[index_sw] - 6;
				current_sprite_x = switches_x[index_sw] - 10;
				
				// Test if sprite pixel is at current position
				if (current_y >= current_sprite_y  && current_y < (current_sprite_y + (SPRITE_HEIGHT)) && current_x >= current_sprite_x  && current_x < (current_sprite_x + (SPRITE_WIDTH))) begin
					
					if (cursor_action == 1 && index_sw == cursor_index && (cursor_index < SWITCHES_ST_COUNT || cursor_index == SWITCHES_ST_AUX1_INDEX || cursor_index == SWITCHES_ST_AUX2_INDEX)) begin // Single Throw Switch Up
						sw_sprite_index[index_sw] = 2;
						switches_status[index_sw] = 1;
					end
					else if (cursor_action == 0 && index_sw == cursor_index && (cursor_index < SWITCHES_ST_COUNT || cursor_index == SWITCHES_ST_AUX1_INDEX || cursor_index == SWITCHES_ST_AUX2_INDEX)) begin // Single Throw Switch Down
						sw_sprite_index[index_sw] = 1;
						switches_status[index_sw] = 0;
					end
					else if (cursor_action == 1 && index_sw == cursor_index && (cursor_index >= SWITCHES_ST_COUNT && cursor_index != SWITCHES_ST_AUX1_INDEX && cursor_index != SWITCHES_ST_AUX2_INDEX)) begin // Double Throw Toggle switches Up
						sw_sprite_index[index_sw] = 2;
						switches_status[index_sw] = 2;
					end
					else if (cursor_action == 2 && index_sw == cursor_index && (cursor_index >= SWITCHES_ST_COUNT && cursor_index != SWITCHES_ST_AUX1_INDEX && cursor_index != SWITCHES_ST_AUX2_INDEX)) begin // Double Throw Toggle switches Down
						sw_sprite_index[index_sw] = 1;
						switches_status[index_sw] = 1;
					end
					else if (cursor_action == 0 && index_sw == cursor_index && (cursor_index >= SWITCHES_ST_COUNT && cursor_index != SWITCHES_ST_AUX1_INDEX && cursor_index != SWITCHES_ST_AUX2_INDEX)) begin // Double Throw Toggle switches middle
						sw_sprite_index[index_sw] = 0;
						switches_status[index_sw] = 0;
					end

					sprites_address = ((current_x - current_sprite_x) + SPRITE_WIDTH * (current_y - current_sprite_y)) + ((SPRITE_WIDTH * SPRITE_HEIGHT) * sw_sprite_index[index_sw]);
					useSpriteColor = 1;
					
					if (index_sw == cursor_index) begin
						cursorSelected = 1;
					end
				end
			end
		end
		 
		if	(useSpriteColorDelayed && sprite_pixel_color != 12'b001100110011) begin // Sprites pixel && !Transparent (Background color 333;)
			if (cursorSelectedDelayed) begin
			  pixel_color = sprite_pixel_color;
			end
			else if (sprite_pixel_color == 12'b000110111111) begin // Remove cursor indicator if cursor is not selected (cursor 1bf);
			  pixel_color = background_pixel_color;
			end
			else begin
			  pixel_color = sprite_pixel_color;
			end
		end
		else if (background_pixel_color == 12'b111100000000 || background_pixel_color == 12'b000011110000) begin // remove led (f00) and switch (0f0) indicator color.
			pixel_color = 12'b001100110011; // Default background color 333;
		end
		else if (current_y >= BACKGROUND_HEIGHT) begin
			pixel_color = 12'b000000000000; // Black color 000;
		end
		else begin
			pixel_color = background_pixel_color;
		end
	end

	assign vga_r = {8{pixel_color[11:8]}};
	assign vga_g = {8{pixel_color[7:4]}};
	assign vga_b = {8{pixel_color[3:0]}};

	////////////////////////////////////////////////////////////

	//	Horizontal	Timing
	localparam	H_FRONT	=	76;
	localparam	H_SYNC	=	80;
	localparam	H_BACK	=	212;
	localparam	H_ACT		=	1280;
	localparam	H_BLANK	=	H_FRONT+H_SYNC+H_BACK;
	localparam	H_TOTAL	=	H_FRONT+H_SYNC+H_BACK+H_ACT;

	//	Vertical Timing
	localparam	V_FRONT	=	3;
	localparam	V_SYNC	=	5;
	localparam	V_BACK	=	22;
	localparam	V_ACT		=	720;
	localparam	V_BLANK	=	V_FRONT+V_SYNC+V_BACK;
	localparam	V_TOTAL	=	V_FRONT+V_SYNC+V_BACK+V_ACT;


	////////////////////////////////////////////////////////////

	reg [10:0] cnt_h;
	reg [10:0] cnt_v;
	always @(posedge clk or posedge reset) begin

	 if (reset)
		begin
		  cnt_h = 0;
		  cnt_v = 0;
		end
	 else
		begin
		  if (cnt_h >= H_TOTAL-1)
			 begin
				cnt_v = cnt_v + 1;
				cnt_h = 0;
			 end
		  else
			 begin
				cnt_h = cnt_h + 1;
			 end	 
		  if (cnt_v >= V_TOTAL)
			 begin
				cnt_h = 0;
				cnt_v = 0;
			 end
		end	 
	end

	reg [10:0] h_cntr;
	reg [10:0] v_cntr;
	reg h_active;
	reg v_active;
	reg h_ndly_active;
	reg v_ndly_active;
	reg request;

	assign	vga_blank = h_active & v_active;
	assign	vga_v_blank = ~v_active;
	assign	vga_h_blank = ~h_active;
	assign	request	= ((h_cntr>=H_BLANK && h_cntr<H_TOTAL)	&&
							  (v_cntr>=V_BLANK && v_cntr<V_TOTAL));

	always @(posedge clk) begin
	 if(reset) begin
		vga_hs <= 1'b1;
		vga_vs <= 1'b1;
		current_x <= 0;
		current_y <= 0;
		h_active <= 1'b0;
		v_active <= 1'b0;
		h_ndly_active <= 1'b0;
		v_ndly_active <= 1'b0;
	 end
	 else begin
		if(cnt_h != H_TOTAL-1) begin
		  if (h_ndly_active) current_x <= current_x + 1'b1;
		  if (cnt_h == H_BLANK-1) h_ndly_active <= 1'b1;
		end
		else begin
		  h_ndly_active <= 1'b0;
		  current_x <= 0;
		end

		if(h_cntr != H_TOTAL-1) begin
		  if (h_cntr == H_BLANK-1) h_active <= 1'b1;
		end
		else begin
		  h_active <= 1'b0;
		end

		if(h_cntr == H_FRONT-1) begin
		  vga_hs <= 1'b0;
		end		

		if (cnt_h == H_FRONT+H_SYNC-1) begin

		  if(cnt_v != V_TOTAL-1) begin
			 if (v_ndly_active) current_y <= current_y + 1'b1;
			 if (cnt_v == V_BLANK-1) v_ndly_active <= 1'b1;
		  end
		  else begin
			 current_y <= 0;
			 v_ndly_active <= 1'b0;
		  end
		end

		if (h_cntr == H_FRONT+H_SYNC-1) begin
		  vga_hs <= 1'b1;

		  if(v_cntr != V_TOTAL-1) begin
			 if (v_cntr == V_BLANK-1) v_active <= 1'b1;
		  end
		  else begin
			 v_active <= 1'b0;
		  end
		  if(v_cntr == V_FRONT-1) vga_vs <= 1'b0;
		  if(v_cntr == V_FRONT+V_SYNC-1) vga_vs <= 1'b1;
		end
	 end
end

endmodule