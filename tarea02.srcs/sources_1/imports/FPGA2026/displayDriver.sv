`timescale 1ns / 1ps

module displayDriver (
	input logic clk, divClk,
	input logic[63:0] inSeg,
	output logic[7:0] anodes,
	output logic[7:0] outSeg
);

logic[2:0] displayCnt = 0;  // son 4 displays
logic[7:0] outComp;

always_ff @(posedge clk)
	if(divClk) displayCnt<= displayCnt+ 1;

always_comb
	case (displayCnt)
		3'd0: begin
			anodes = 8'b11111110;
			outSeg= inSeg[7:0];
		end
		3'd1: begin
			anodes= 8'b11111101;
			outSeg= inSeg[15:8];
		end
		3'd2: begin
			anodes= 8'b11111011;
			outSeg= inSeg[23:16];
		end
		3'd3: begin
			anodes= 8'b11110111;
			outSeg= inSeg[31:24];
		end
		3'd4: begin
			anodes= 8'b11101111;
			outSeg= inSeg[39:32];
		end
		3'd5: begin
			anodes= 8'b11011111;
			outSeg= inSeg[47:40];
		end
		3'd6: begin
			anodes= 8'b10111111;
			outSeg= inSeg[55:48];
		end
		3'd7: begin
			anodes= 8'b01111111;
			outSeg= inSeg[63:56];
		end
	endcase
endmodule: displayDriver

module binto7seg(input logic clk,input logic[11:0] result ,output logic [6:0] seg,output logic [3:0] an);
    
    
    
    logic clk_slow;
    logic [15:0] bcd_output;
    logic [27:0] seg_output;
    
    
    clockDivider clk_div (
	.clk (clk),
	.divClk (clk_slow)
    );
    
    bin2bcd_multi #(
	.N_DIGITS (4),
	.N_BITS (12)
    ) bin2bcd_multi1 (
	.clk (clk),
	.load (1'b1),
	.bin (result),
	.ready (),
	.bcd (bcd_output[15:0])
    );

    
    seven_seg seg1 (
	.clk (clk),
	.in (bcd_output[3:0]),
	.seg (seg_output[6:0])
);

seven_seg seg2 (
	.clk (clk),
	.in (bcd_output[7:4]),
	.seg (seg_output[13:7])
);

    seven_seg seg3 (
	.clk (clk),
	.in (bcd_output[11:8]),
	.seg (seg_output[20:14])
);

    seven_seg seg4 (
	.clk (clk),
	.in (1'b0),
	.seg (seg_output[27:21])
);
displayDriver disp_driver (
	.clk (clk),
	.divClk (clk_slow),
	.inSeg (seg_output),
	.anodes (an),
	.outSeg (seg)
);
    
    
endmodule
