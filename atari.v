`timescale 1ns / 1ps

module block_controller(
	input fst_CLK,
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input rst,
	input up, input down, input left, input right,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background,
	output qS, q0, q15, q30, q45, q60, q75, q90, q105, q120, q135, q150, q165, q180, q195, q210, q225, q240, q255, q270, q285, q300, q315, q330, q345
   );

   	reg [2:0] cnt;
	wire r1;
	wire r2;
	wire r3;
	wire r4;
	wire r5;
	wire r6;
	wire r7;
	wire r8;
	wire r9;
	wire ball_fill;
	wire plat_fill;
	wire plat_ball_collision_v;
	wire plat_ball_collision_h;
	wire plat_ball_collision_fifteen;
	wire plat_ball_collision_thirty;
	wire plat_ball_collision_fifteen_neg;
	wire plat_ball_collision_thirty_neg;
	reg block_fill[3:0][15:0];
	reg visible[3:0][15:0];
	reg block_collision_v[3:0][15:0];
	reg block_collision_h[3:0][15:0];
	reg writeBlock_one;
	reg writeBlock_two;
	reg collisionV;
	reg collisionH;

	reg [24:0] trajectory;
	assign {qS, q0, q15, q30, q45, q60, q75, q90, q105, q120, q135, q150, q165, q180, q195, q210, q225, q240, q255, q270, q285, q300, q315, q330, q345} = trajectory;

	localparam
		QS    = 25'b1000000000000000000000000,
		Q0    = 25'b0100000000000000000000000,
		Q15   = 25'b0010000000000000000000000,
		Q30   = 25'b0001000000000000000000000,	
		Q45   = 25'b0000100000000000000000000,
		Q60   = 25'b0000010000000000000000000, 
		Q75   = 25'b0000001000000000000000000,  
		Q90   = 25'b0000000100000000000000000, 
		Q105  = 25'b0000000010000000000000000, 
		Q120  = 25'b0000000001000000000000000, 
		Q135  = 25'b0000000000100000000000000, 
		Q150  = 25'b0000000000010000000000000, 
		Q165  = 25'b0000000000001000000000000, 
		Q180  = 25'b0000000000000100000000000, 
		Q195  = 25'b0000000000000010000000000, 
		Q210  = 25'b0000000000000001000000000, 
		Q225  = 25'b0000000000000000100000000, 
		Q240  = 25'b0000000000000000010000000, 
		Q255  = 25'b0000000000000000001000000, 
		Q270  = 25'b0000000000000000000100000, 
		Q285  = 25'b0000000000000000000010000, 
		Q300  = 25'b0000000000000000000001000, 
		Q315  = 25'b0000000000000000000000100,
		Q330  = 25'b0000000000000000000000010, 
		Q345  = 25'b0000000000000000000000001,
	     X0 =   8'b11111111,
	    X15 =   8'b11111111,
	    X30	=   8'b11101111,
	    X45	=   8'b11011101,
	    X60	=   8'b00100010,
	    X75	=   8'b00010000,
	    X90	=   8'b00000000,
		Y90  =  8'b11111111,
	    Y75 =   8'b11111111,
	    Y60	=   8'b11101111,
	    Y45	=   8'b11011101,
	    Y30	=   8'b00100010,
	    Y15	=   8'b00010000,
	    Y0	=   8'b00000000,
	    UNK   = 24'bXXXXXXXXXXXXXXXXXXXXXXXX;
	   
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg [9:0] xpos, ypos, xplatpos, yplatpos;

	reg [9:0] xblk_pos [15:0];
	reg [9:0] yblk_pos [3:0];
	
	parameter BLACK = 12'b0000_0000_0000;
	parameter BLUE = 12'b0000_0000_1111;

	parameter GREY = 12'b1010_1010_1011;
	parameter LIGHTBLUE = 12'b0111_1100_1101;

	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/

	
	always@ (posedge fst_CLK) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (plat_fill)
			rgb = BLUE;
		else if (writeBlock_one)
			begin
				rgb = GREY;
			end
		else if (writeBlock_two)
			begin
				rgb = LIGHTBLUE;
			end
		else if (ball_fill) 
			rgb = BLACK; 
		else	
			rgb=background;
	end
	
		//fills in the rows for the ball.
	assign r1 = vCount==(ypos + 4) && hCount <= (xpos+2) && hCount >= (xpos-2);
	assign r2 = vCount==(ypos + 3) && hCount <= (xpos+3) && hCount >= (xpos-3);
	assign r3 = vCount==(ypos + 2) && hCount <= (xpos+4) && hCount >= (xpos-4);
	assign r4 = vCount==(ypos + 1) && hCount <= (xpos+4) && hCount >= (xpos-4);
	assign r5 = vCount==(ypos + 0) && hCount <= (xpos+4) && hCount >= (xpos-4);
	assign r6 = vCount==(ypos - 1) && hCount <= (xpos+4) && hCount >= (xpos-4);
	assign r7 = vCount==(ypos - 2) && hCount <= (xpos+4) && hCount >= (xpos-4);
	assign r8 = vCount==(ypos - 3) && hCount <= (xpos+3) && hCount >= (xpos-3);
	assign r9 = vCount==(ypos - 4) && hCount <= (xpos+2) && hCount >= (xpos-2);
	assign ball_fill = r1 || r2|| r3 || r4 || r5 || r6 || r7 || r8 || r9;

	//create platform
	assign plat_fill= vCount>=(yplatpos - 20) && hCount>=(xplatpos-50) && hCount<=(xplatpos+50);

	assign plat_ball_collision_v = ypos==(yplatpos-24) && (xpos>=(xplatpos-16) && xpos<=(xplatpos+16));
	assign plat_ball_collision_h = ypos>=(yplatpos-24) && ypos<=(yplatpos) && (xpos==(xplatpos+54) || xpos==(xplatpos-54));
	assign plat_ball_collision_fifteen = ypos==(yplatpos-24) && (xpos>=(xplatpos+16) && xpos<=(xplatpos+33));
	assign plat_ball_collision_thirty = ypos==(yplatpos-24) && (xpos>=(xplatpos+33) && xpos<=(xplatpos+51));
	assign plat_ball_collision_fifteen_neg = ypos==(yplatpos-24) && (xpos>=(xplatpos-33) && xpos<=(xplatpos-16));
	assign plat_ball_collision_thirty_neg = ypos==(yplatpos-24) && (xpos>=(xplatpos-51) && xpos<=(xplatpos-33));

	always@(posedge clk, posedge rst) 
	begin
		if(rst || ypos == 511)
		begin 
			//rough values for center of screen
			xplatpos <= 463;
			yplatpos <= 515;
		end
		else if (clk) begin
		
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/
			if(right) begin
				xplatpos<=xplatpos+1; //change the amount you increment to make the speed faster 
				if(xplatpos >= 733) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					xplatpos <= 733;
			end
			else if(left) begin
				xplatpos <= xplatpos-1;
				if(xplatpos <=194)
					xplatpos<=194;
			end
		end
	end
    
    
    
	always@(posedge clk, posedge rst) 
	begin
		if(rst || ypos == 511)
		begin 
			//rough values for center of screen
			trajectory <= QS;
			xpos<=450;
			ypos<=490;
			cnt <= 0;
		end
		else if (clk) begin
		
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/
			if(up)
			begin
				trajectory <= Q60;
			end
			cnt <= cnt+1;
			case(trajectory)
				Q0: 
				    begin
					   xpos <= xpos + X0[cnt];
					   ypos <= ypos - Y0[cnt];
				    end
				Q15: 
				    begin
					   xpos <= xpos + X15[cnt];
					   ypos <= ypos - Y15[cnt];
				    end
				Q30: 
				    begin
					   xpos <= xpos + X30[cnt];
					   ypos <= ypos - Y30[cnt];
				    end
				Q45: 
				    begin
					   xpos <= xpos + X45[cnt];
					   ypos <= ypos - Y45[cnt];
				    end
				Q60: 
				    begin
					   xpos <= xpos + X60[cnt];
					   ypos <= ypos - Y60[cnt];
				    end
				Q75: 
				    begin
					   xpos <= xpos + X75[cnt];
					   ypos <= ypos - Y75[cnt];
				    end
				Q90: 
				    begin
					   xpos <= xpos + X90[cnt];
					   ypos <= ypos - Y90[cnt];
				    end
				Q105: 
				    begin
					   xpos <= xpos - X75[cnt];
					   ypos <= ypos - Y75[cnt];
				    end
				Q120: 
				    begin
					   xpos <= xpos - X60[cnt];
					   ypos <= ypos - Y60[cnt];
				    end
				Q135: 
				    begin
					   xpos <= xpos - X45[cnt];
					   ypos <= ypos - Y45[cnt];
				    end
				Q150: 
				    begin
					   xpos <= xpos - X30[cnt];
					   ypos <= ypos - Y30[cnt];
				    end
				Q165: 
				    begin
					   xpos <= xpos - X15[cnt];
					   ypos <= ypos - Y15[cnt];
				    end
				Q180: 
				    begin
					   xpos <= xpos - X0[cnt];
					   ypos <= ypos + Y0[cnt];
				    end
				Q195: 
				    begin
					   xpos <= xpos - X15[cnt];
					   ypos <= ypos + Y15[cnt];
				    end
				Q210: 
				    begin
					   xpos <= xpos - X30[cnt];
					   ypos <= ypos + Y30[cnt];
				    end
				Q225: 
				    begin
					   xpos <= xpos - X45[cnt];
					   ypos <= ypos + Y45[cnt];
				    end
				Q240: 
				    begin
					   xpos <= xpos - X60[cnt];
					   ypos <= ypos + Y60[cnt];
				    end
				Q255: 
				    begin
					   xpos <= xpos - X75[cnt];
					   ypos <= ypos + Y75[cnt];
				    end
				Q270: 
				    begin
					   xpos <= xpos - X90[cnt];
					   ypos <= ypos + Y90[cnt];
				    end
				Q285: 
				    begin
					   xpos <= xpos + X75[cnt];
					   ypos <= ypos + Y75[cnt];
				    end
				Q300: 
				    begin
					   xpos <= xpos + X60[cnt];
					   ypos <= ypos + Y60[cnt];
				    end
				Q315: 
				    begin
					   xpos <= xpos + X45[cnt];
					   ypos <= ypos + Y45[cnt];
				    end
				Q330: 
				    begin
					   xpos <= xpos + X30[cnt];
					   ypos <= ypos + Y30[cnt];
				    end
				Q345: 
				    begin
					   xpos <= xpos + X15[cnt];
					   ypos <= ypos + Y15[cnt];
				    end
				default: trajectory <= UNK;
			endcase
			if(ypos == 39 || plat_ball_collision_v || collisionV)
			begin
				case(trajectory)
					Q15: 
						begin
						trajectory <= Q345;
						ypos <= ypos + 1;
						end
					Q30:
						begin
							trajectory <= Q330;
							ypos <= ypos + 1;
						end
					Q45:
						begin
							trajectory <= Q315;
							ypos <= ypos + 1;
						end
					Q60:
						begin
							trajectory <= Q300;
							ypos <= ypos + 1;
						end
					Q75:
						begin
							trajectory <= Q285;
							ypos <= ypos + 1;
						end
					Q90:
						begin
							trajectory <= Q270;
							ypos <= ypos + 1;
						end
					Q105: 
						begin
						trajectory <= Q255;
						ypos <= ypos + 1;
						end
					Q120:
						begin
							trajectory <= Q240;
							ypos <= ypos + 1;
						end
					Q135:
						begin
							trajectory <= Q225;
							ypos <= ypos + 1;
						end
					Q150:
						begin
							trajectory <= Q210;
							ypos <= ypos + 1;
						end
					Q165:
						begin
							trajectory <= Q195;
							ypos <= ypos + 1;
						end
					Q345:
						begin
							trajectory <= Q15;
							ypos <= ypos - 1;
						end
					Q330:
						begin
							trajectory <= Q30;
							ypos <= ypos - 1;
						end
					Q315:
						begin
							trajectory <= Q45;
							ypos <= ypos - 1;
						end
					Q300:
						begin
							trajectory <= Q60;
							ypos <= ypos - 1;
						end
					Q285:
						begin
							trajectory <= Q75;
							ypos <= ypos - 1;
						end
					Q270: 
						begin
						trajectory <= Q90;
						ypos <= ypos - 1;
						end
					Q255:
						begin
							trajectory <= Q105;
							ypos <= ypos - 1;
						end
					Q240:
						begin
							trajectory <= Q120;
							ypos <= ypos - 1;
						end
					Q225:
						begin
							trajectory <= Q135;
							ypos <= ypos - 1;
						end
					Q210:
						begin
							trajectory <= Q150;
							ypos <= ypos - 1;
						end
					Q195:
						begin
							trajectory <= Q165;
							ypos <= ypos - 1;
						end
					default: trajectory <= UNK;
				endcase
			end
			else if(xpos == 149 || xpos == 778 || collisionH || plat_ball_collision_h)
			begin
				case(trajectory)
					Q0:
						begin
							trajectory <= Q180;
							xpos <= xpos - 1;
						end
					Q15: 
						begin
						trajectory <= Q165;
						xpos <= xpos - 1;
						end
					Q30:
						begin
							trajectory <= Q150;
							xpos <= xpos - 1;
						end
					Q45:
						begin
							trajectory <= Q135;
							xpos <= xpos - 1;
						end
					Q60:
						begin
							trajectory <= Q120;
							xpos <= xpos - 1;
						end
					Q75:
						begin
							trajectory <= Q105;
							xpos <= xpos - 1;
						end
					Q105: 
						begin
						trajectory <= Q75;
						xpos <= xpos + 1;
						end
					Q120:
						begin
							trajectory <= Q60;
							xpos <= xpos + 1;
						end
					Q135:
						begin
							trajectory <= Q45;
							xpos <= xpos + 1;
						end
					Q150:
						begin
							trajectory <= Q30;
							xpos <= xpos + 1;
						end
					Q165:
						begin
							trajectory <= Q15;
							xpos <= xpos + 1;
						end
					Q180:
						begin
							trajectory <= Q0;
							xpos <= xpos + 1;
						end
					Q195:
						begin
							trajectory <= Q345;
							xpos <= xpos + 1;
						end
					Q210:
						begin
							trajectory <= Q330;
							xpos <= xpos + 1;
						end
					Q225:
						begin
							trajectory <= Q315;
							xpos <= xpos + 1;
						end
					Q240:
						begin
							trajectory <= Q300;
							xpos <= xpos + 1;
						end
					Q255:
						begin
							trajectory <= Q285;
							xpos <= xpos + 1;
						end
					Q285: 
						begin
						trajectory <= Q255;
						xpos <= xpos - 1;
						end
					Q300:
						begin
							trajectory <= Q240;
							xpos <= xpos - 1;
						end
					Q315:
						begin
							trajectory <= Q225;
							xpos <= xpos - 1;
						end
					Q330:
						begin
							trajectory <= Q210;
							xpos <= xpos - 1;
						end
					Q345:
						begin
							trajectory <= Q195;
							xpos <= xpos - 1;
						end
					default: trajectory <= UNK;
				endcase
			end
			else if(plat_ball_collision_fifteen_neg)
			begin
				case(trajectory)
					Q195:
						begin
							trajectory <= Q165;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q210:
						begin
							trajectory <= Q150;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q225:
						begin
							trajectory <= Q135;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q240:
						begin
							trajectory <= Q120;
							xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q255:
						begin
							trajectory <= Q105;
							xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q270:
						begin
							trajectory <= Q105;
							xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q285: 
						begin
                            trajectory <= Q90;
							ypos <= ypos - 1;
						end
					Q300:
						begin
							trajectory <= Q75;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q315:
						begin
							trajectory <= Q60;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q330:
						begin
							trajectory <= Q45;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q345:
						begin
							trajectory <= Q45;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					default: trajectory <= UNK;
				endcase
			end
			else if(plat_ball_collision_thirty_neg)
			begin
				case(trajectory)
					Q195:
						begin
							trajectory <= Q165;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q210:
						begin
							trajectory <= Q165;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q225:
						begin
							trajectory <= Q150;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q240:
						begin
							trajectory <= Q150;
							xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q255:
						begin
							trajectory <= Q135;
							xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q270:
						begin
							trajectory <= Q135;
							xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q285: 
						begin
                            trajectory <= Q120;
                            xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q300:
						begin
							trajectory <= Q105;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q315:
						begin
							trajectory <= Q90;
							ypos <= ypos - 1;
						end
					Q330:
						begin
							trajectory <= Q75;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q345:
						begin
							trajectory <= Q75;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					default: trajectory <= UNK;
				endcase
			end
			else if(plat_ball_collision_fifteen)
			begin
				case(trajectory)
					Q195:
						begin
							trajectory <= Q135;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q210:
						begin
							trajectory <= Q135;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q225:
						begin
							trajectory <= Q120;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q240:
						begin
							trajectory <= Q105;
							xpos <= xpos - 1;
						    ypos <= ypos - 1;
						end
					Q255:
						begin
							trajectory <= Q90;
						    ypos <= ypos - 1;
						end
					Q270:
						begin
							trajectory <= Q75;
							xpos <= xpos + 1;
						    ypos <= ypos - 1;
						end
					Q285: 
						begin
                            trajectory <= Q75;
                            xpos <= xpos + 1;
                            ypos <= ypos - 1;
						end
					Q300:
						begin
							trajectory <= Q60;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q315:
						begin
							trajectory <= Q45;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q330:
						begin
							trajectory <= Q30;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q345:
						begin
							trajectory <= Q15;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					default: trajectory <= UNK;
				endcase
			end
			else if(plat_ball_collision_thirty)
			begin
				case(trajectory)
					Q195:
						begin
							trajectory <= Q105;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q210:
						begin
							trajectory <= Q105;
							xpos <= xpos - 1;
							ypos <= ypos - 1;
						end
					Q225:
						begin
							trajectory <= Q90;
							ypos <= ypos - 1;
						end
					Q240:
						begin
							trajectory <= Q75;
						    xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q255:
						begin
							trajectory <= Q60;
							xpos <= xpos + 1;
						    ypos <= ypos - 1;
						end
					Q270:
						begin
							trajectory <= Q45;
							xpos <= xpos + 1;
						    ypos <= ypos - 1;
						end
					Q285: 
						begin
                            trajectory <= Q45;
                            xpos <= xpos + 1;
                            ypos <= ypos - 1;
						end
					Q300:
						begin
							trajectory <= Q30;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q315:
						begin
							trajectory <= Q30;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q330:
						begin
							trajectory <= Q15;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					Q345:
						begin
							trajectory <= Q15;
							xpos <= xpos + 1;
							ypos <= ypos - 1;
						end
					default: trajectory <= UNK;
				endcase
			end
		end
					
	end

	integer i;
	integer j;
	always@(posedge fst_CLK, posedge rst) 
	begin
		if(rst || ypos == 511)
		begin 
			for(i = 0; i<16; i = i+1)
			begin
				xblk_pos[i] <= 144 + (i * 40);
			end
			for(j = 0; j < 4; j= j+1)
			begin
				yblk_pos[j] <= 150 + (j * 30);
			end
		end
		else if (fst_CLK) begin
			if(writeBlock_one)
			begin
				writeBlock_one = 0;
			end
			if(writeBlock_two)
			begin
				writeBlock_two = 0;
			end
			for(j = 0; j < 4; j= j+1)
			begin
				for(i = 0; i<16; i = i+1)
				begin
					block_fill[j][i] = vCount >= (yblk_pos[j]) && vCount <= (yblk_pos[j] + 29) && hCount >= (xblk_pos[i]) && hCount <= (xblk_pos[i] + 39) && visible[j][i];
					if(block_fill[j][i])
					begin
						if(i %2)
						begin
							if(j % 2)
							begin
								writeBlock_one = 1;
							end
							else
							begin
								writeBlock_two = 1;
							end
						end
						else
						begin
							if(j % 2)
							begin
								writeBlock_two =1;
							end
							else
							begin
								writeBlock_one = 1;
							end
						end
					end
				end
			end	
		end
	end

	always@(posedge clk, posedge rst)
	begin
		if(rst || ypos == 511)
		begin
			for(i = 0; i<4; i = i+1)
			begin
				for(j = 0; j<16; j = j+1)
				begin
					visible[i][j] = 1;
				end
			end
		end
		else if(clk)
		begin
			collisionV = 0;
			collisionH = 0;
			for(j = 0; j<4; j = j+1)
			begin
				for(i = 0; i<16; i = i+1)
				begin
					block_collision_v[j][i] = (ypos == (yblk_pos[j]-4) || ypos == (yblk_pos[j] + 34)) && xpos >= (xblk_pos[i]-3) && xpos <= (xblk_pos[i] + 43) && visible[j][i];
					collisionV = collisionV || block_collision_v[j][i];
					if(block_collision_v[j][i])
					begin
						visible[j][i] = 0;
					end

					block_collision_h[j][i] = ypos >= (yblk_pos[j]-3) && ypos <= (yblk_pos[j] + 33) && (xpos == (xblk_pos[i] -4) || xpos == (xblk_pos[i] + 44)) && visible[j][i];
					collisionH = collisionH || block_collision_h[j][i];
					if(block_collision_h[j][i])
					begin
                        visible[j][i] = 0;
					end
				end
			end	
		end
	end	

	
	//the background color reflects the most recent button press
	always@(posedge rst) begin
		background <= 12'b1111_1111_1111;
	end	
endmodule