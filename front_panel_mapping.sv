// front_panel_mapping

module	front_panel_mapping (
		input clk,
		input [1:0]switches_status[0:24],	
		output leds_status[0:35]
);

// 0 to 9 Status
// 10 to 17 Data
// 18 to 19 Wait HLDA
// 20 to 35 Address

localparam LEDS_TOTAL_NUMBER = 36;
localparam SWITCHES_TOTAL_NUMBER = 25;

integer index_led;
integer index_sw;

always @(posedge clk) begin
	for (index_sw = 0; index_sw < SWITCHES_TOTAL_NUMBER; index_sw = index_sw + 1) begin
		
		if(switches_status[index_sw] == 1) begin // Toggle switches - Addresses and On/Off
			leds_status[index_sw] = 1;
		end
		else begin
			leds_status[index_sw] = 0;
		end
	end
	
end

endmodule