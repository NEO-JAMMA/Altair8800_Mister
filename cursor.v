module cursor
(
  input  reset,
  input  clk,
  input  [10:0] ps2_key,
  output reg [4:0] cursor_index,
  output reg [1:0] cursor_action
);

	parameter SWITCHES_ST_COUNT = 18;
	parameter SWITCHES_ST_AUX1_INDEX = 23;
	parameter SWITCHES_ST_AUX2_INDEX = 24;

	//Keyboard
	// ps2_key[7:0] - scancode 
	// ps2_key[8]   - extended
	// ps2_key[9]   - pressed true-down(make), false up(break)
	// ps2_key[10]  - toggles with every press/release

	reg [3:0] cursor_index_x;
	reg [4:0] cursor_index_y;
	
	reg pressed;
	reg key_toggle;

	always @(posedge clk) begin
		reg old_key_toggle;

		pressed <= ps2_key[9];
		key_toggle <= ps2_key[10];
		old_key_toggle <= key_toggle;
		cursor_index <= cursor_index_x + cursor_index_y;
		
		if (reset) begin // reset switches to startup state
      cursor_action = 0;
      cursor_index_x = 0;
      cursor_index_y = 0;
		end
		else if(old_key_toggle != key_toggle && pressed) begin
			case(ps2_key[7:0])
				8'h75 :	// Up Arrow
				begin 
					cursor_action = 3; cursor_index_y = 0;
				end
				8'h6b :	// Left Arrow
				begin 
					cursor_action = 3;
					cursor_index_x = cursor_index_x - 1;
					if	(cursor_index_y == 16 && cursor_index_x == 15)
						cursor_index_x = 8;
				end
				8'h72 :  // Down Arrow
				begin 
					cursor_action = 3; 
					cursor_index_y = 16;
					if (cursor_index_x > 8)
						cursor_index_x = 8;
				end
				8'h74 :	// Right Arrow
					begin cursor_action = 3;
					cursor_index_x = cursor_index_x + 1;
					if	(cursor_index_y == 16 && cursor_index_x > 8)
						cursor_index_x = 0;
				end
				8'h45 :	// 0
				begin 
					cursor_action = 0;
				end
				8'h16 :	// 1
				begin 
					cursor_action = 1;
				end
				8'h1e :	// 2
				begin 
					if (cursor_index >= SWITCHES_ST_COUNT)
						cursor_action = 2;
					else
						cursor_action = 0;
				end
			endcase
		end
		else if(old_key_toggle != key_toggle && ~pressed) begin
		  if (cursor_index >= SWITCHES_ST_COUNT && cursor_index != SWITCHES_ST_AUX1_INDEX && cursor_index != SWITCHES_ST_AUX2_INDEX) begin
			case(ps2_key[7:0])
				8'h16 : cursor_action = 0; 	// 1
				8'h1e : cursor_action = 0; 	// 2
			endcase
		  end	
		end
	end
endmodule

