`timescale 1ns / 1ps

module seven_seg (
	input logic clk,
	input logic [3:0] in,
	output logic [7:0] seg
);

	always_ff @(posedge clk) begin
		case (in)
			4'h0: seg <= 8'b11000000;
			4'h1: seg <= 8'b11111001;
			4'h2: seg <= 8'b10100100;
			4'h3: seg <= 8'b10110000;
			4'h4: seg <= 8'b10011001;
			4'h5: seg <= 8'b10010010;
			4'h6: seg <= 8'b10000010;
			4'h7: seg <= 8'b11111000;
			4'h8: seg <= 8'b10000000;
			4'h9: seg <= 8'b10010000;
			4'hA: seg <= 8'b10001000;
			4'hB: seg <= 8'b10000011;
			4'hC: seg <= 8'b11000110;
			4'hD: seg <= 8'b10100001;
			4'hE: seg <= 8'b10000110;
			4'hF: seg <= 8'b10001110;
		endcase
	end
endmodule

