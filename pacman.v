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
		HEX3
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
	output [6:0] HEX0, HEX1, HEX3;
	wire resetn;
	assign resetn = SW[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire [7:0] result;
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
		.up(~KEY[2]),
		.down(~KEY[1]),
		.left(~KEY[3]),
		.right(~KEY[0]),
		.out_x(x),
		.out_y(y),
		.out_colour(colour),
		.plot(writeEn),
		.result(result),
		.life(life)
	);
	
	seg7 s0(
        .in(result[3:0]), 
        .out(HEX0)
        );
        
    seg7 s1(
        .in(result[7:4]), 
        .out(HEX1)
        );
		  
	 seg7 s2(
        .in(life), 
        .out(HEX3)
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
		life,
		ghost,
		ghost_clean
	);
	
	
	input clean, draw, up, down, left ,right, ghost, ghost_clean;
	input clock, resetn;
	
	output reg [7:0] out_x;
	output reg [6:0] out_y;
	output reg [2:0] out_colour;
	output  [7:0] result;
	output  [3:0] life;
	
	reg [7:0] x;
	reg [6:0] y;
	reg [7:0] x_last;
	reg [6:0] y_last;
	reg [2:0] colour;
	reg [7:0] ghost1_x;
	reg [6:0] ghost1_y;
	reg [7:0] ghost1_x_last;
	reg [6:0] ghost1_y_last;
	reg [7:0] result0;
	reg [3:0] life0;
	//The registers which store the current moving direction of pacman
   reg go_up, go_down, go_left, go_right;
	//The registers which indicate if pacaman can go up,down,left,right.
	reg forbid_up, forbid_down, forbid_left, forbid_right;
	
	
	//The coordinates of white pixels which stand for scoring objects	
	reg [7:0] x1 = 8'd112;
	reg [6:0] y1 = 7'd37;
	reg [7:0]x2 = 8'd130;
	reg [6:0] y2 = 7'd37;
	reg [7:0] x3 = 8'd130;
	reg [6:0] y3 = 7'd21;
	reg [7:0] x4 = 8'd130;
	reg [6:0] y4 = 7'd51;
	
	
	
	//The coordinates of red pixels which stand for extra lives objects.
	reg [7:0] rx1 = 8'd113;
	reg [6:0] ry1 = 8'd88;
	
	
	always @(posedge clock)
	begin: load
		if (!resetn) begin
			go_up = 0;
			go_down = 0;
			go_left = 0;
			go_right = 0;
			forbid_up = 0;
			forbid_down = 0;
			forbid_left = 0;
			forbid_right = 0;
			x <= 8'd80;
			y <= 7'd60;
			ghost1_x <= 8'd15;
			ghost1_y <= 7'd61;
			colour <= 3'b110;
			result0 <= 8'd0;
			life0  <= 4'd1;
			end
		else 
			begin
					x_last <= x;
					y_last <= y;
					ghost1_x_last <= ghost1_x;
					ghost1_y_last <= ghost1_y;
					forbid_up = 0;
					forbid_down = 0;
					forbid_left = 0;
					forbid_right = 0;
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
					  (y == 89 && x > 42 && x< 73)||(y == 89 && x > 85 && x< 118)||
					  (y == 105 && x > 20 && x< 64)||(y == 105 && x > 95 && x< 139)
					  )begin
						forbid_up = 1;
						end
				//If pacman can not go down anymore because of the maze		
				if((y == 15 && x > 21 && x< 64) ||(y == 15 && x > 74 && x< 86) ||
						(y == 15 && x > 95 && x< 138) ||(y == 31 && x > 42 && x< 74) ||
						(y == 31 && x > 85 && x< 117) ||(y == 47 && x > 21 && x< 41) ||
						(y == 47 && x > 53 && x< 72) || (y == 47 && x > 84 && x< 106) ||
						(y == 47 && x > 117 && x< 138) || (y == 62 && x > 20 && x< 42) ||
						(y == 62 && x > 64 && x< 95) || (y == 62 && x > 117 && x< 138) ||
						(y == 79 && x > 21 && x< 31) || (y == 79 && x > 42 && x< 117) ||
						(y == 79 && x > 127 && x< 138) || (y == 95 && x > 31 && x< 63) ||
						(y == 95 && x > 96 && x< 127) ||(y == 111 && x > 9 && x< 74) ||
						(y == 64 && x > 149 && x< 160)||(y == 111 && x > 85 && x< 149))
						begin
						forbid_down = 1;
						end
					if((x == 10 && x > 7 && x< 56)||(x == 10 && x > 64 && x< 112))begin
					 forbid_left = 1;
					end
//					if()begin
//					 forbid_right = 1;
//					end
					
				if (go_right && draw && ~forbid_right ) begin
					x <= x + 1;
					end
				if (go_left && draw && ~forbid_left) begin
					x <= x - 1;
					end
				if (go_up && draw && ~forbid_up) begin
					y <= y - 1;
					end
				if (go_down && draw && ~forbid_down)begin
					y <= y + 1;
				    
					end
				// When the pacman eats the white block
				if  (x == x1 && y == y1)begin 
					result0 <= result0 + 1;
					x1 = 8'd80;
					y1 = 7'd60;
					
					end
				if (x == x2 && y == y2)begin 
					result0 <= result0 + 1;
					x2 = 8'd80;
					y2 = 7'd60;
					
					end
				if (x == x3 && y == y3)begin 
					result0 <= result0 + 1;
					x3 = 8'd80;
					y3 = 7'd60;
					
					end
				if (x == x4 && y == y4)begin 
					result0 <= result0 + 1;
					x4 = 8'd80;
					y4 = 7'd60;
					
					end
				if (x == rx1 && y == ry1)begin 
					life0 <= life0 + 1;
					rx1 = 8'd80;
					ry1 = 7'd60;
					
					end
				
				if(ghost)begin
					out_x = ghost1_x;
					out_y = ghost1_y;
					out_colour = 3'b011;
					end
				if(ghost_clean)begin
					out_x = ghost1_x_last;
					out_y = ghost1_y_last;
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
				if (go_right && ghost && ~forbid_right ) begin
					ghost1_x <= ghost1_x + 1;
					end
				if (go_left && ghost && ~forbid_left) begin
					ghost1_x <= ghost1_x - 1;
					end
				if (go_up && ghost && ~forbid_up) begin
					ghost1_y <= ghost1_y - 1;
					end
				if (go_down && ghost && ~forbid_down)begin
					ghost1_y <= ghost1_y + 1;
				    
					end
			end
	end
	
//	assign out_x = ((draw) ? x : x_last);
//	assign out_y = ((draw) ? y : y_last);
//	assign out_colour = (draw) ? colour : 3'b000;
	assign result = result0;
	assign life = life0;

	
	//assign out_colour = 3'b100;
	
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
		ghost_clean
	);
	
	input resetn, clock, up, down, left, right;
	output reg  draw, clean, plot, ghost, ghost_clean;

	reg [2:0] current_state, next_state;
	
	localparam Start = 3'd0,
					Draw = 3'd1,
					Clean = 3'd2,
					Ghost_draw = 3'd3,
					Ghost_clean = 3'd4;

	always @(*)
	begin: state_table
		case (current_state)
			Start: next_state <= Draw;
			Draw: next_state <= Clean;
			Clean: next_state <= Ghost_draw;
			Ghost_draw: next_state <= Ghost_clean;
				Ghost_clean: next_state <=  Draw;

			default: next_state = Start;
		endcase
	end
	
	always @(*)
	begin: signals

		draw = 1'b0;
		clean = 1'b0;
		plot = 1'b0;
		ghost = 1'b0;
		ghost_clean = 1'b0;
		case (current_state)
		Ghost_draw: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b1;
			ghost_clean = 1'b0;
			plot = 1'b1;
			end
		Ghost_clean: begin
			draw = 1'b0;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b1;
			plot = 1'b1;
			end
		Draw: begin
			draw = 1'b1;
			clean = 1'b0;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
			end
		Clean: begin
			draw = 1'b0;
			clean = 1'b1;
			ghost = 1'b0;
			ghost_clean = 1'b0;
			plot = 1'b1;
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
		life
	);
	
	input up; 
	input down; 
	input left;
   input right;
	input clock;
	input resetn;

	
	output [7:0] out_x;
	output [6:0] out_y;
	output [2:0] out_colour;
	output plot;
	output [7:0] result;
	output [3:0] life;
	
	wire  draw, clean, ghost, ghost_clean, clko;
	
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
		
		.out_x(out_x),
		.out_y(out_y),
		.out_colour(out_colour),
		.result(result),
		.life(life)
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
		.ghost_clean(ghost_clean)
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
		if (count == 3500000) begin
			clkout <= 1'b1;
			count <= 22'b0;
		end else begin
			clkout <= 1'b0;
			count <= count + 1'b1;
		end
	end
endmodule


//Seven segment decoder
module seg7(in, out);
	input [3:0] in;
	output [6:0] out;
	
	assign out[0] = (~in[3] & in[2] & ~in[1] & ~in[0]) | 
						 (~in[3] & ~in[2] & ~in[1] & in[0]) | 
						 (in[3] & in[2] & ~in[1] & in[0]) | 
						 (in[3] & ~in[2] & in[1] & in[0]);
	assign out[1] = (~in[3] & in[2] & ~in[1] & in[0]) | 
						 (in[3] & in[2] & ~in[0]) | 
						 (in[3] & in[1] & in[0]) | 
						 (in[2] & in[1] & ~in[0]);
	assign out[2] = (in[3] & in[2] & ~in[0]) | 
					    (in[3] & in[2] & in[1]) | 
						 (~in[3] & ~in[2] & in[1] & ~in[0]);
	assign out[3] = (~in[3] & in[2] & ~in[1] & ~in[0]) |
					    (~in[2] & ~in[1] & in[0]) |
						 (in[2] & in[1] & in[0]) |
						 (in[3] & ~in[2] & in[1] & ~in[0]);
	assign out[4] = (~in[3] & in[2] & ~in[1] & ~in[0]) |
						 (~in[2] & ~in[1] & in[0]) |
						 (~in[3] & in[0]);
	assign out[5] = (in[3] & in[2] & ~in[1] & in[0]) |
						 (~in[3] & ~in[2] & in[0]) |
						 (~in[3] & in[1] & in[0]) |
						 (~in[3] & ~in[2] & in[1]);
	assign out[6] = (in[3] & in[2] & ~in[1] & ~in[0]) |
					    (~in[3] & in[2] & in[1] & in[0]) |
						 (~in[3] & ~in[2] & ~in[1]);
endmodule



