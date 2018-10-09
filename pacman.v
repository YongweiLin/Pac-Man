//The part about VGA is given by as the starter code by the CSC258 course instructor
module pacman
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
		  SW,
        
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX0,
		HEX1,
		HEX2,
		HEX4
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0] SW;
	input   [8:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [6:0] HEX0, HEX1, HEX2, HEX4;
	wire resetn;
	assign resetn = SW[0];
	assign restart = SW[1];
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire [7:0] result;
	wire [3:0]result_100th;
	wire [3:0] life;
	wire writeEn;
	wire draw;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "pac_man_map.mif";

		
//The part above is given by the CSC258 course instructor
    
    combined c0 (
		.clock(CLOCK_50),
		.resetn(resetn),
		.restart(restart),
		.up(~KEY[2]),
		.down(~KEY[1]),
		.left(~KEY[3]),
		.right(~KEY[0]),
		.out_x(x),
		.out_y(y),
		.out_colour(colour),
		.plot(writeEn),
		.result(result),
		.result_100th(result_100th),
		.life(life)
	);
	
	
	
	//Display score
	seven_seg s0(
        .digit(result[3:0]), 
        .segments(HEX0)
        );
        
   seven_seg s1(
        .digit(result[7:4]), 
        .segments(HEX1)
        );
		  
		  
	seven_seg s2(
        .digit(result_100th[3:0]), 
        .segments(HEX2)
        );
		  
	//Display life count
		  
	seven_seg s4(
        .digit(life), 
        .segments(HEX4)
        );

    
endmodule


module datapath
	(
		clean,
		draw,
		up,
		down,
		left,
		right,
		clock,
		resetn,
		out_x,
		out_y,
		out_colour,
		result,
		result_100th,
		life,
		ghost,
		ghost_clean,
		re,
		ready,
		restart,
		ghost2,
		ghost2_clean,
		ghost3,
		ghost3_clean
	);
	
	
	input clean, draw, up, down, left ,right, ghost, ghost_clean, re, ghost2, 
			ghost2_clean, ghost3, ghost3_clean;
	input clock, resetn, restart;
	
	output reg [7:0] out_x;
	output reg [6:0] out_y;
	output reg [2:0] out_colour;
	output  [7:0] result;
	output  [3:0] result_100th;
	output  [3:0] life;
	output reg ready;
	reg [7:0] x;
	reg [6:0] y;
	reg [7:0] x_last;
	reg [6:0] y_last;
	reg [2:0] colour;
	
	//Create three enemies, ghost1 will be able to chase pacman, 
	//ghost2 and 3 only roam
	reg [7:0] ghost1_x;
	reg [6:0] ghost1_y;
	reg [7:0] ghost1_x_last;
	reg [6:0] ghost1_y_last;
	
	reg [7:0] ghost2_x;
	reg [6:0] ghost2_y;
	reg [7:0] ghost2_x_last;
	reg [6:0] ghost2_y_last;
	
	reg [7:0] ghost3_x;
	reg [6:0] ghost3_y;
	reg [7:0] ghost3_x_last;
	reg [6:0] ghost3_y_last;
	
	// life count and score count
	reg [7:0] result0;
	reg [3:0] result100; 
	reg [3:0] life0;
	
	//The registers which store the current moving direction of pacman
   reg go_up, go_down, go_left, go_right;
	//The registers which indicate if pacaman can go up,down,left,right.
	reg forbid_up, forbid_down, forbid_left, forbid_right;
	
	reg g1_forbid_up, g1_forbid_down, g1_forbid_left, g1_forbid_right;
	//The coordinates of special item pixels which stand for 153 scoring items
	// [152:0]and 3 extra lives items [155:153]
	reg [7:0] x_coordinates [155:0];
	reg [6:0] y_coordinates [155:0];
	
	//change ghost 2 and 3 direction
	reg ghost23_change; 

	//weather the special item pixel is eaten
	reg  item_eaten [155:0];

	// Slow down the motion of pacman
	reg [7:0] slow_down_count_pac = 8'd0;

	
	// Slow down the motion of ghost
	reg [7:0] slow_down_count = 8'd0;

	
	// See if the redrawing of map is down
	reg [7:0] re_count = 8'd0;

	    
	always @(posedge clock)
	begin: load
		if (!resetn || restart) begin
			integer i;
			ready = 0;
			//set coordinate for special items
			for(i = 0; i <156; i = i + 1) begin
				item_eaten[i] = 0;
			end
			
			
			for(i = 0; i < 10; i = i + 1) begin
			x_coordinates[i] = 8'd15;
			y_coordinates[i] = 7'd11 + i * (7'd5);
			end
		   
			for(i = 10; i < 20; i = i + 1) begin
			x_coordinates[i] = 8'd15;
			y_coordinates[i] = 7'd13 + i * (7'd5);
			end
			
			for(i = 20; i < 30; i = i + 1) begin
			x_coordinates[i] = 8'd143;
			y_coordinates[i] = i * (7'd5) - 7'd89;
			end
			
			for(i = 30; i < 40; i = i + 1) begin
			x_coordinates[i] = 8'd143;
			y_coordinates[i] = i * (7'd5) - 7'd87;
			end
			
			for(i = 40; i < 45; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd178);
			y_coordinates[i] = 7'd11;
			end
			
			for(i = 45; i < 50; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd177);
			y_coordinates[i] = 7'd11;
			end
			
			for(i = 50; i < 55; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd159);
			y_coordinates[i] = 7'd11;
			end
			
			for(i = 55; i < 60; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd158);
			y_coordinates[i] = 7'd11;
			end
			
			
			for(i = 60; i < 65; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd278);
			y_coordinates[i] = 7'd43;
			end
			
			for(i = 65; i < 70; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd277);
			y_coordinates[i] = 7'd43;
			end
			
			for(i = 70; i < 75; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd259);
			y_coordinates[i] = 7'd42;
			end
			
			for(i = 75; i < 80; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd258);
			y_coordinates[i] = 7'd42;
			end
			
			
			for(i = 80; i < 85; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd378);
			y_coordinates[i] = 7'd76;
			end
			
			for(i = 85; i < 90; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd377);
			y_coordinates[i] = 7'd76;
			end
			
			for(i = 90; i < 95; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd359);
			y_coordinates[i] = 7'd75;
			end
			
			for(i = 95; i < 100; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd358);
			y_coordinates[i] = 7'd75;
			end
			
			
			for(i = 100; i < 105; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd478);
			y_coordinates[i] = 7'd108;
			end
			
			for(i = 105; i < 110; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd477);
			y_coordinates[i] = 7'd108;
			end
			
			for(i = 110; i < 115; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd459);
			y_coordinates[i] = 7'd108;
			end
			
			for(i = 115; i < 120; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd458);
			y_coordinates[i] = 7'd108;
			end
			
			for(i = 120; i < 125; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd552);
			y_coordinates[i] = 7'd26;
			end
			
			
			for(i = 125; i < 130; i = i + 1) begin
			x_coordinates[i] = i * (8'd5) - (8'd524);
			y_coordinates[i] = 7'd26;
			end
			
			for(i = 130; i < 135; i = i + 1) begin
			x_coordinates[i] = 8'd48;
			y_coordinates[i] = i * (7'd5) - (7'd602);
			end
			
			for(i = 135; i < 140; i = i + 1) begin
			x_coordinates[i] = 8'd111;
			y_coordinates[i] = i * (7'd5) - (7'd627);
			end
			
			x_coordinates[140] = 8'd69;
			y_coordinates[140] = 7'd60;
			
			x_coordinates[141] = 8'd74;
			y_coordinates[141] = 7'd60;
			
			x_coordinates[142] = 8'd86;
			y_coordinates[142] = 7'd60;
			
			x_coordinates[143] = 8'd91;
			y_coordinates[143] = 7'd60;
			
			x_coordinates[144] = 8'd95;
			y_coordinates[144] = 7'd26;
			
			
			x_coordinates[145] = 8'd80;
			y_coordinates[145] = 7'd76;
			
			
			
			x_coordinates[146] = 8'd80;
			y_coordinates[146] = 7'd44;
			
			x_coordinates[147] = 8'd80;
			y_coordinates[147] = 7'd48;
			
			x_coordinates[148] = 8'd80;
			y_coordinates[148] = 7'd51;
			
			x_coordinates[149] = 8'd80;
			y_coordinates[149] = 7'd10;
			
			
			x_coordinates[150] = 8'd37;
			y_coordinates[150] = 7'd26;
			
			x_coordinates[151] = 8'd42;
			y_coordinates[151] = 7'd26;
			
			x_coordinates[152] = 8'd90;
			y_coordinates[152] = 7'd26;
			
			
			//Set coordinates for red dots
			
			x_coordinates[153] = 8'd31;
			y_coordinates[153] = 7'd59;
			
			x_coordinates[154] = 8'd129;
			y_coordinates[154] = 7'd59;
			
			x_coordinates[155] = 8'd80;
			y_coordinates[155] = 7'd108;
			
			
			go_up = 0;
			go_down = 0;
			go_left = 0;
			go_right = 0;
			forbid_up = 0;
			forbid_down = 0;
			forbid_left = 0;
			forbid_right = 0;
			
			g1_forbid_up = 0;
			g1_forbid_down = 0;
			g1_forbid_left = 0;
			g1_forbid_right = 0;
			x <= 8'd80;
			y <= 7'd60;
			ghost1_x <= 8'd15;
			ghost1_y <= 7'd61;
			
			ghost2_x <= 8'd80;
			ghost2_y <= 7'd13;
			
			ghost3_x <= 8'd80;
			ghost3_y <= 7'd106;
			
			ghost23_change <= 0; 
			colour <= 3'b110;
			result0 <= 8'b00000000;
			result100 <= 4'b0000;
			life0  <= 4'd1;
			end
		else 
			begin
				   integer i;
					x_last <= x;
					y_last <= y;
					ghost1_x_last <= ghost1_x;
					ghost1_y_last <= ghost1_y;
					
					ghost2_x_last <= ghost2_x;
					ghost2_y_last <= ghost2_y;
					
					ghost3_x_last <= ghost3_x;
					ghost3_y_last <= ghost3_y;
					
					forbid_up = 0;
					forbid_down = 0;
					forbid_left = 0;
					forbid_right = 0;
					g1_forbid_up = 0;
					g1_forbid_down = 0;
					g1_forbid_left = 0;
					g1_forbid_right = 0;
					
					if(up)begin
					go_up = 1;
					go_down = 0;
					go_left = 0;
					go_right = 0;
					end
					if(down)begin
					go_up = 0;
					go_down = 1;
					go_left = 0;
					go_right = 0;
					end
					if(left)begin
					go_up = 0;
					go_down = 0;
					go_left = 1;
					go_right = 0;
					end
					if(right)begin
					go_up = 0;
					go_down = 0;
					go_left = 0;
					go_right = 1;
					end
					
				//If pacman can not go up anymore because of the maze
				if ((y == 9 && x > 9 && x< 75) || (y == 9 && x > 85 && x< 150)||
					 (y == 57 && x > 0 && x< 10)||(y == 57 && x > 149 && x< 160)||
					 (y == 41 && x > 21 && x< 31)||(y == 41	 && x > 128 && x< 139)||
					  (y == 41 && x > 42 && x< 117)||(y == 25 && x > 31 && x< 63)||
					  (y == 25 && x > 96 && x< 128)|| (y == 57 && x > 21 && x< 42)||
					  (y == 57 && x > 62 && x< 74)||(y == 57 && x > 85 && x< 96)||
					  (y == 57 && x > 117 && x< 138)||(y == 73 && x > 21 && x< 42)||
					  (y == 73 && x > 53 && x< 106)|| (y == 73 && x > 117 && x< 138)||
					  (y == 89 && x > 42 && x< 76)||(y == 89 && x > 85 && x< 118)||
					  (y == 105 && x > 20 && x< 64)||(y == 105 && x > 95 && x< 139) ||
					  (y == 0)||(y == 105 && x > 74 && x< 104)
					  )begin
						forbid_up = 1;
						end
				//If pacman can not go down anymore because of the maze		
				if((y == 15 && x > 21 && x< 64) ||(y == 15 && x > 74 && x< 86) ||
						(y == 15 && x > 95 && x< 138) ||(y == 31 && x > 42 && x< 76) ||
						(y == 31 && x > 83 && x< 117) ||(y == 47 && x > 21 && x< 43) ||
						(y == 47 && x > 53 && x< 72) || (y == 47 && x > 84 && x< 107) ||
						(y == 47 && x > 117 && x< 138) || (y == 63 && x > 20 && x< 42) ||
						(y == 63 && x > 63 && x< 96) || (y == 63 && x > 117 && x< 138) ||
						(y == 79 && x > 21 && x< 31) || (y == 79 && x > 42 && x< 117) ||
						(y == 79 && x > 127 && x< 138) || (y == 95 && x > 31 && x< 63) ||
						(y == 95 && x > 96 && x< 127) ||(y == 111 && x > 9 && x< 74) ||
						(y == 64 && x > 149 && x< 160)||(y == 111 && x > 85 && x< 151) || (y == 120))
						begin
						forbid_down = 1;
						end
				//If pacman can not go left anymore because of the maze		
					if((x == 10 && y > 7 && y< 56)||(x == 10 && y > 64 && y< 112) ||
						(x == 32 && y > 24 && y< 41)|| (x == 32 && y > 80 && y< 96)||
						(x == 42 && y > 48 && y< 57)||(x == 42 && y > 63 && y< 72)||
						(x == 64 && y > 15 && y< 24)|| (x == 64 && y > 55 && y< 64)||
						(x == 64 && y > 95 && y< 104)|| (x == 74 && y > 47 && y< 56)||
						(x == 74 && y > 111 && y< 121)||(x == 74 && y > 0 && y< 8)||
						(x == 85 && y > 16 && y< 33)|| (x == 85 && y > 88 && y< 105)|| 
						(x == 106 && y > 46 && y< 72)|| (x == 117 && y > 31 && y< 40)|| 
						(x == 117 && y > 80 && y< 89)|| (x == 138 && y > 16 && y< 41)|| 
						(x == 138 && y > 47 && y< 56)|| (x == 138 && y > 63 && y< 73)||
						(x == 138 && y > 80 && y< 105) || (x == 0))
						begin
						forbid_left = 1;
						end
				//If pacman can not go right anymore because of the maze		
					if((x == 149 && y > 7 && y< 56)||(x == 149 && y > 64 && y< 112) ||
						(x == 127 && y > 24 && y< 41)|| (x == 127 && y > 80 && y< 96)||
						(x == 117 && y > 48 && y< 57)||(x == 117 && y > 63 && y< 72)||
						(x == 95 && y > 15 && y< 24)|| (x == 95 && y > 55 && y< 64)||
						(x == 95 && y > 95 && y< 104)|| (x == 85 && y > 47 && y< 56)||
						(x == 85 && y > 111 && y< 121)||(x == 85 && y > 47 && y< 56)|| 
						(x == 74 && y > 16 && y< 33)|| (x == 74 && y > 88 && y< 105)||
						(x == 52 && y > 48 && y< 72)|| (x == 42 && y > 31 && y< 40)||
						(x == 42 && y > 80 && y< 89)|| (x == 21 && y > 16 && y< 41)||
						(x == 21 && y > 47 && y< 56)|| (x == 21 && y > 63 && y< 73)||
						(x == 21 && y > 80 && y< 105) || (x == 160))
						begin
						forbid_right = 1;
						end
						
				//If ghost1 can not go up anymore because of the maze			
				if ((ghost1_y == 9 && ghost1_x > 9 && ghost1_x< 75) || (ghost1_y == 9 && ghost1_x > 85 && ghost1_x< 150)||
					 (ghost1_y == 57 && ghost1_x > 0 && ghost1_x< 10)||(ghost1_y == 57 && ghost1_x > 149 && ghost1_x< 160)||
					 (ghost1_y == 41 && ghost1_x > 21 && ghost1_x< 31)||(ghost1_y == 41	 && ghost1_x > 128 && ghost1_x< 139)||
					  (ghost1_y == 41 && ghost1_x > 42 && ghost1_x< 117)||(ghost1_y == 25 && ghost1_x > 31 && ghost1_x< 63)||
					  (ghost1_y == 25 && ghost1_x > 96 && ghost1_x< 128)|| (ghost1_y == 57 && ghost1_x > 21 && ghost1_x< 42)||
					  (ghost1_y == 57 && ghost1_x > 62 && ghost1_x< 74)||(ghost1_y == 57 && ghost1_x > 85 && ghost1_x< 96)||
					  (ghost1_y == 57 && ghost1_x > 117 && ghost1_x< 138)||(ghost1_y == 72 && ghost1_x > 21 && ghost1_x< 42)||
					  (ghost1_y == 72 && ghost1_x > 53 && ghost1_x< 106)|| (ghost1_y == 72 && ghost1_x > 117 && ghost1_x< 138)||
					  (ghost1_y == 89 && ghost1_x > 42 && ghost1_x< 76)||(ghost1_y == 89 && ghost1_x > 85 && ghost1_x< 118)||
					  (ghost1_y == 105 && ghost1_x > 20 && ghost1_x< 64)||(ghost1_y == 105 && ghost1_x > 95 && ghost1_x< 139)||
					  (ghost1_y == 105 && ghost1_x > 74 && ghost1_x< 104)
					  )begin
						g1_forbid_up = 1;
						end
				//If ghost1 can not go down anymore because of the maze		
				if((ghost1_y == 15 && ghost1_x > 21 && ghost1_x< 64) ||(ghost1_y == 15 && ghost1_x > 74 && ghost1_x< 86) ||
						(ghost1_y == 15 && ghost1_x > 95 && ghost1_x< 138) ||(ghost1_y == 31 && ghost1_x > 42 && ghost1_x< 76) ||
						(ghost1_y == 31 && ghost1_x > 84 && ghost1_x< 117) ||(ghost1_y == 47 && ghost1_x > 21 && ghost1_x< 43) ||
						(ghost1_y == 47 && ghost1_x > 53 && ghost1_x< 72) || (ghost1_y == 47 && ghost1_x > 84 && ghost1_x< 107) ||
						(ghost1_y == 47 && ghost1_x > 117 && ghost1_x< 138) || (ghost1_y == 63 && ghost1_x > 20 && ghost1_x< 42) ||
						(ghost1_y == 63 && ghost1_x > 63 && ghost1_x< 96) || (ghost1_y == 63 && ghost1_x > 117 && ghost1_x< 138) ||
						(ghost1_y == 79 && ghost1_x > 21 && ghost1_x< 31) || (ghost1_y == 79 && ghost1_x > 42 && ghost1_x< 117) ||
						(ghost1_y == 79 && ghost1_x > 127 && ghost1_x< 138) || (ghost1_y == 95 && ghost1_x > 31 && ghost1_x< 63) ||
						(ghost1_y == 95 && ghost1_x > 96 && ghost1_x< 127) ||(ghost1_y == 111 && ghost1_x > 9 && ghost1_x< 74) ||
						(ghost1_y == 64 && ghost1_x > 149 && ghost1_x< 160)||(ghost1_y == 111 && ghost1_x > 85 && ghost1_x< 149))
						begin
						g1_forbid_down = 1;
						end
				//If ghost1 can not go left anymore because of the maze		
					if((ghost1_x == 10 && ghost1_y > 7 && ghost1_y< 56)||(ghost1_x == 10 && ghost1_y > 64 && ghost1_y< 112) ||
						(ghost1_x == 32 && ghost1_y > 24 && ghost1_y< 41)|| (ghost1_x == 32 && ghost1_y > 80 && ghost1_y< 96)||
						(ghost1_x == 42 && ghost1_y > 48 && ghost1_y< 57)||(ghost1_x == 42 && ghost1_y > 63 && ghost1_y< 72)||
						(ghost1_x == 64 && ghost1_y > 15 && ghost1_y< 24)|| (ghost1_x == 64 && ghost1_y > 55 && ghost1_y< 64)||
						(ghost1_x == 64 && ghost1_y > 95 && ghost1_y< 104)|| (ghost1_x == 74 && ghost1_y > 47 && ghost1_y< 56)||
						(ghost1_x == 74 && ghost1_y > 111 && ghost1_y< 121)||(ghost1_x == 74 && ghost1_y > 0 && ghost1_y< 8)||
						(ghost1_x == 85 && ghost1_y > 16 && ghost1_y< 33)|| (ghost1_x == 85 && ghost1_y > 88 && ghost1_y< 105)|| 
						(ghost1_x == 106 && ghost1_y > 46 && ghost1_y< 72)|| (ghost1_x == 117 && ghost1_y > 31 && ghost1_y< 40)|| 
						(ghost1_x == 117 && ghost1_y > 80 && ghost1_y< 89)|| (ghost1_x == 138 && ghost1_y > 16 && ghost1_y< 41)|| 
						(ghost1_x == 138 && ghost1_y > 47 && ghost1_y< 56)|| (ghost1_x == 138 && ghost1_y > 63 && ghost1_y< 73)||
						(ghost1_x == 138 && ghost1_y > 80 && ghost1_y< 105))
						begin
						g1_forbid_left = 1;
						end
				//If ghost1 can not go right anymore because of the maze		
					if((ghost1_x == 149 && ghost1_y > 7 && ghost1_y< 56)||(ghost1_x == 149 && ghost1_y > 64 && ghost1_y< 112) ||
						(ghost1_x == 127 && ghost1_y > 24 && ghost1_y< 41)|| (ghost1_x == 127 && ghost1_y > 80 && ghost1_y< 96)||
						(ghost1_x == 117 && ghost1_y > 48 && ghost1_y< 57)||(ghost1_x == 117 && ghost1_y > 63 && ghost1_y< 72)||
						(ghost1_x == 95 && ghost1_y > 15 && ghost1_y< 24)|| (ghost1_x == 95 && ghost1_y > 55 && ghost1_y< 64)||
						(ghost1_x == 95 && ghost1_y > 95 && ghost1_y< 104)|| (ghost1_x == 85 && ghost1_y > 47 && ghost1_y< 56)||
						(ghost1_x == 85 && ghost1_y > 111 && ghost1_y< 121)||(ghost1_x == 85 && ghost1_y > 47 && ghost1_y< 56)|| 
						(ghost1_x == 74 && ghost1_y > 16 && ghost1_y< 33)|| (ghost1_x == 74 && ghost1_y > 88 && ghost1_y< 105)||
						(ghost1_x == 52 && ghost1_y > 48 && ghost1_y< 72)|| (ghost1_x == 42 && ghost1_y > 31 && ghost1_y< 40)||
						(ghost1_x == 42 && ghost1_y > 80 && ghost1_y< 89)|| (ghost1_x == 21 && ghost1_y > 16 && ghost1_y< 41)||
						(ghost1_x == 21 && ghost1_y > 47 && ghost1_y< 57)|| (ghost1_x == 21 && ghost1_y > 63 && ghost1_y< 73)||
						(ghost1_x == 21 && ghost1_y > 80 && ghost1_y< 105))
						begin
						g1_forbid_right = 1;
						end
						
				if (go_right && ~forbid_right && slow_down_count_pac == 8'd20) begin
					x <= x + 1;
					end
				if (go_left && ~forbid_left && slow_down_count_pac == 8'd20) begin
					x <= x - 1;
					end
				if (go_up && ~forbid_up && slow_down_count_pac == 8'd20) begin
					y <= y - 1;
					end
				if (go_down && ~forbid_down && slow_down_count_pac == 8'd20)begin
					y <= y + 1;
				    
				end
				
				
				// When the pacman eats the white dots
				for(i = 0; i < 153; i = i + 1) begin
					if( (x == x_coordinates[i]) && ( y == y_coordinates[i]) && ( ~ item_eaten[i])) begin
						result0 <= result0 + 8'b00000001; 
						
						//Make the seven seg decoder decimal
						
						if(result0 == 8'b10011001) begin
							result0 <= result0 - 8'b10011001;
							result100 <= 4'b0001;
						end
						
						if(result0[3:0]== 4'b1001 && (!(result0 == 8'b10011001))) begin
							result0 <= result0 + 8'b00000111;
						end
						
						item_eaten[i] = 1; 
						end
				end
				
				// When the pacman eats the red dots
				for(i = 153; i < 156; i = i + 1) begin
					if( (x == x_coordinates[i]) && ( y == y_coordinates[i]) && ( ~ item_eaten[i])) begin
						life0 <= life0 + 1; 
						item_eaten[i] = 1; 
						end
				end
				
				
				// if the player restarts
				if(re)begin
					out_x = x_coordinates[re_count];
					out_y = y_coordinates[re_count[7:0]];
					if(re_count < 8'd153) begin
						out_colour = 3'b111;
						re_count <= re_count + 1;
					end
					if(re_count > 8'd152 && re_count < 8'd156) begin
						out_colour = 3'b100;
						re_count <= re_count + 1;
					end
					
					if(re_count == 8'd156) begin
						out_x = x;
						out_y = y;
						out_colour = 3'b000;
						re_count <= re_count + 1;
					end
					
					if(re_count == 8'd157) begin
						out_x = ghost1_x;
						out_y = ghost1_y;
						out_colour = 3'b000;
						re_count <= 0;
						ready = 1;
					end
				end
				if(ghost)begin
					out_x = ghost1_x;
					out_y = ghost1_y;
					out_colour = 3'b101;
					end
				if(ghost_clean)begin
					out_x = ghost1_x_last;
					out_y = ghost1_y_last;
					out_colour = 3'b000;
					// When the ghost counters the white dots
					for(i = 0; i < 153; i = i + 1) begin
						if( (ghost1_x_last == x_coordinates[i]) && ( ghost1_y_last == y_coordinates[i]) && ( ~ item_eaten[i])) begin
							out_colour = 3'b111;
						end
					end
				
					// When the ghost counters the red dots
					for(i = 153; i < 156; i = i + 1) begin
						if( (ghost1_x_last == x_coordinates[i]) && ( ghost1_y_last == y_coordinates[i]) && ( ~ item_eaten[i])) begin
							out_colour = 3'b100;
						end
					end
				end
				
				if(ghost2)begin
					out_x = ghost2_x;
					out_y = ghost2_y;
					out_colour = 3'b010;
				end
				
				if(ghost2_clean)begin
					out_x = ghost2_x_last;
					out_y = ghost2_y_last;
					out_colour = 3'b000;
				end
				
				if(ghost3)begin
					out_x = ghost3_x;
					out_y = ghost3_y;
					out_colour = 3'b010;
				end
				
				if(ghost3_clean)begin
					out_x = ghost3_x_last;
					out_y = ghost3_y_last;
					out_colour = 3'b000;
				end
				
				if (draw)begin
					out_x = x;
					out_y = y;
					out_colour = colour;
				end
				if (clean)begin
					out_x =  x_last;
					out_y =  y_last;
					out_colour = 3'b000;
				end
				if (x > ghost1_x && ~g1_forbid_right && slow_down_count == 8'd60) begin
					ghost1_x <= ghost1_x + 1;
					end
				if (x < ghost1_x && ~g1_forbid_left && slow_down_count == 8'd60) begin
					ghost1_x <= ghost1_x - 1;
					end
				if (y < ghost1_y && ~g1_forbid_up && slow_down_count == 8'd60) begin
					ghost1_y <= ghost1_y - 1;
					end
				if (y > ghost1_y && ~g1_forbid_down && slow_down_count == 8'd60)begin
					ghost1_y <= ghost1_y + 1;
					end
				if ((!(ghost2_y == 60)) && ghost2_x < 8'd148 && ghost23_change == 0 && slow_down_count == 8'd60)begin
					ghost2_x <= ghost2_x + 1;
					end
				if (ghost2_x > 8'd145) begin
					ghost23_change <= 1;
					end
				if ((!(ghost2_y == 60)) && ghost2_x > 8'd11 && ghost23_change == 1 && slow_down_count == 8'd60)begin
					ghost2_x <= ghost2_x - 1;
					end
				if (ghost2_x < 8'd14) begin
					ghost23_change <= 0;
					end
				if (!(ghost3_y == 60) && ghost3_x < 8'd148 && ghost23_change == 0 && slow_down_count == 8'd60)begin
					ghost3_x <= ghost3_x + 1;
					end
				if (!(ghost3_y == 60) && ghost3_x > 8'd11 && ghost23_change == 1 && slow_down_count == 8'd60)begin
					ghost3_x <= ghost3_x - 1;
					end

				
				if(slow_down_count < 8'd60)begin
					slow_down_count <= slow_down_count + 8'd1;
				end
				
				if(slow_down_count == 8'd60)begin
					slow_down_count <= 8'd0;
				end
				
				if(slow_down_count_pac < 8'd20)begin
					slow_down_count_pac <= slow_down_count_pac + 8'd1;
				end
				
				if(slow_down_count_pac == 8'd20)begin
					slow_down_count_pac <= 8'd0;
				end
				
				//If the ghosts catch pacman
				if((ghost1_x == x && ghost1_y == y) || (ghost2_x == x && ghost2_y == y)||
				(ghost3_x == x && ghost3_y == y))begin
					life0 <= life0 - 1;
					x <= 8'd80;
					y <= 7'd60;
				end
				if(life0 == 0 || ((result100 == 4'b0001 && result0 == 8'b01010011) && clean))begin
					ghost1_x <= 8'd80;
					ghost1_y <= 7'd60;
					ghost2_x <= 8'd80;
					ghost2_y <= 7'd60;
					ghost3_x <= 8'd80;
					ghost3_y <= 7'd60;
					x <= 8'd80;
					y <= 7'd60;
				end
				
			end
	end

	assign result = result0;
	assign result_100th = result100;
	assign life = life0;


endmodule


module control
	(
		clock,
		resetn,
		up,
		down,
		left,
		right,
		draw,
		clean,
		plot,
		ghost,
		ghost_clean,
		ready,
		re,
		restart,
		ghost2,
		ghost2_clean,
		ghost3,
		ghost3_clean
	);
	
	input resetn, clock, up, down, left, right, ready, restart;
	output reg  draw, clean, plot, ghost, ghost_clean, re, ghost2, ghost2_clean, ghost3, ghost3_clean;

	reg [3:0] current_state, next_state;
	
	localparam Start = 4'd0,
					Draw = 4'd1,
					Clean = 4'd2,
					Ghost_draw = 4'd3,
					Ghost_clean = 4'd4,
					Restart = 4'd5,
					Ghost2_draw = 4'd6,
					Ghost2_clean = 4'd7,
					Ghost3_draw = 4'd8,
					Ghost3_clean = 4'd9;


	always @(*)
	begin: state_table
		case (current_state)
			Start: next_state <= restart ? Restart : Draw;
			Draw: next_state <= restart ? Restart : Clean;
			Clean: next_state <= restart ? Restart : Ghost_draw;
			Ghost_draw: next_state <= restart ? Restart : Ghost_clean;
			Ghost_clean: next_state <= restart ? Restart : Ghost2_draw;
			Ghost2_draw: next_state <= restart ? Restart : Ghost2_clean;
			Ghost2_clean: next_state <= restart ? Restart : Ghost3_draw;
			Ghost3_draw: next_state <= restart ? Restart : Ghost3_clean;
			Ghost3_clean: next_state <= restart ? Restart : Draw;
			Restart: next_state <= ready ? Draw : Restart;
			default: next_state = Draw;
		endcase
	end
	
	always @(*)
	begin: signals

		draw = 1'b0;
		clean = 1'b0;
		plot = 1'b0;
		ghost = 1'b0;
		ghost_clean = 1'b0;
		ghost2 = 1'b0;
		ghost2_clean = 1'b0;
		ghost3 = 1'b0;
		ghost3_clean = 1'b0;
		re = 1'b0;
		case (current_state)
		Ghost_draw: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b1;
			ghost_clean = 1'b0;
			plot = 1'b1;
			ghost2 = 1'b0;
			ghost2_clean = 1'b0;
			ghost3 = 1'b0;
			ghost3_clean = 1'b0;
			re = 1'b0;
			end
		Ghost_clean: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b1;
			plot = 1'b1;
			ghost2 = 1'b0;
			ghost2_clean = 1'b0;
			ghost3 = 1'b0;
			ghost3_clean = 1'b0;
			re = 1'b0;
			end
		Draw: begin
			draw = 1'b1;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			re = 1'b0;
			ghost2 = 1'b0;
			ghost2_clean = 1'b0;
			ghost3 = 1'b0;
			ghost3_clean = 1'b0;
			end
		Clean: begin
			draw = 1'b0;
			clean = 1'b1;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			re = 1'b0;
			ghost2 = 1'b0;
			ghost2_clean = 1'b0;
			ghost3 = 1'b0;
			ghost3_clean = 1'b0;
			end
		Restart: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			re = 1'b1;
			ghost2 = 1'b0;
			ghost2_clean = 1'b0;
			ghost3 = 1'b0;
			ghost3_clean = 1'b0;
			end
		Ghost2_draw: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			re = 1'b0;
			ghost2 = 1'b1;
			ghost2_clean = 1'b0;
			ghost3 = 1'b0;
			ghost3_clean = 1'b0;
			end
		Ghost2_clean: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			re = 1'b0;
			ghost2 = 1'b0;
			ghost2_clean = 1'b1;
			ghost3 = 1'b0;
			ghost3_clean = 1'b0;
			end
		Ghost3_draw: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			re = 1'b0;
			ghost2 = 1'b0;
			ghost2_clean = 1'b0;
			ghost3 = 1'b1;
			ghost3_clean = 1'b0;
			end
		Ghost3_clean: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			re = 1'b0;
			ghost2 = 1'b0;
			ghost2_clean = 1'b0;
			ghost3 = 1'b0;
			ghost3_clean = 1'b1;
			end
		endcase
	end
	
always@(posedge clock)
    begin: state_FFs
        if(!resetn)
            current_state <= Start;
        else
            current_state <= next_state;
    end 
endmodule




module combined
	(	clock,
		resetn,
		up,
		down,
		left,
		right,
		out_x,
		out_y,
		out_colour,
		plot,
		result,
		result_100th,
		life,
		restart
	);
	
	input up; 
	input down; 
	input left;
   input right;
	input clock;
	input resetn;
	input restart;

	
	output [7:0] out_x;
	output [6:0] out_y;
	output [2:0] out_colour;
	output plot;
	output [7:0] result;
	output [3:0] result_100th;
	output [3:0] life;
	
	wire  draw, clean, ghost, ghost_clean, clko, ready, re, ghost2, ghost2_clean, ghost3, ghost3_clean;
	
	//create rate_divider
	rate_divider r0(
		.clkin(clock),
		.clkout(clko));
	
	//create datapath
	datapath d0(
		.resetn(resetn),
		.clock(clko),
		 .up(up),
		.down(down),
		.left(left),
		.right(right),
		.draw(draw),
		.clean(clean),
		.ghost(ghost),
		.ghost_clean(ghost_clean),
		.ghost2(ghost2),
		.ghost2_clean(ghost2_clean),
		.ghost3(ghost3),
		.ghost3_clean(ghost3_clean),
		.out_x(out_x),
		.out_y(out_y),
		.out_colour(out_colour),
		.result(result),
		.result_100th(result_100th),
		.life(life),
		.ready(ready),
		.re(re),
		.restart(restart)
	);

    //create FSM control
   control c0(
		.clock(clko),
		.resetn(resetn),
		.up(up),
		.down(down),
		.left(left),
		.right(right),
		.draw(draw),
		.clean(clean),
		.plot(plot),
		.ghost(ghost),
		.ghost_clean(ghost_clean),
		.ready(ready),
		.re(re),
		.restart(restart),
		.ghost2(ghost2), 
		.ghost2_clean(ghost2_clean),
		.ghost3(ghost3), 
		.ghost3_clean(ghost3_clean)
		);
	
endmodule

//rate divider to slow the clock 
module rate_divider(clkin,clkout);
  input clkin;
  output reg clkout;
  reg [21:0] count;
  initial begin
		clkout <= 1'b0;
		count <= 22'b0;
  end
  
  
	always@(posedge clkin) begin
		if (count == 200000) begin
			clkout <= 1'b1;
			count <= 22'b0;
		end else begin
			clkout <= 1'b0;
			count <= count + 1'b1;
		end
	end
endmodule


//Seven segment decoder in decimal
module seven_seg(digit, segments);
    input [3:0] digit;
    output reg [6:0] segments;
   
    always @(*)
        case (digit)
            4'd0: segments = 7'b100_0000;
            4'd1: segments = 7'b111_1001;
            4'd2: segments = 7'b010_0100;
            4'd3: segments = 7'b011_0000;
            4'd4: segments = 7'b001_1001;
            4'd5: segments = 7'b001_0010;
            4'd6: segments = 7'b000_0010;
            4'd7: segments = 7'b111_1000;
            4'd8: segments = 7'b000_0000;
            4'd9: segments = 7'b001_1000;
            default: segments = 7'b100_0000;
        endcase
endmodule


