`timescale 1ns / 1ps

module bin2bcd_multi #(N_DIGITS = 4, N_BITS = 8) (
	input logic clk, load,
	input [N_BITS-1 : 0] bin,
	output logic ready,
	output logic [N_DIGITS*4-1 : 0] bcd
);

logic [N_DIGITS*4-1:0] bcdTmp;
logic [N_BITS-1:0]     shiftReg;
logic                  reset;
logic [N_DIGITS:0]     carry;

assign carry[0] = shiftReg[N_BITS-1];

bin2bcd dig [N_DIGITS-1:0] (
	.clk(clk),
	.modIn(carry[N_DIGITS-1:0]),
	.init(reset),
	.q(bcdTmp),
	.modOut(carry[N_DIGITS:1])
);

logic [N_BITS-1:0] state = 0;

always_ff @(posedge clk)
	if(state == 0) begin
		if (load) begin
			reset <= 0;
			shiftReg <= bin;
			state <= 1;
			ready <= 0;
			end
		else begin
			reset <= 1;
			state <= 0;
			ready <= 0;
		end
	end
	else if (state < N_BITS + 1) begin
		reset <= 0;
		shiftReg <= (shiftReg<< 1);
		state <= state + 1;
		ready <= 0;
	end
	else begin
		reset <= 1;
		state <= 0;
		ready <= 1;
		bcd<= bcdTmp;
	end

endmodule:bin2bcd_multi

