`timescale 1ns / 1ps

module bin2bcd (
	input logic clk, init, modIn,
	output logic [3:0] q,
	output logic modOut
);

assign modOut = (q < 5) ? 0 : 1;

always_ff@ (posedge clk) begin
	if (init)
		q <= 4'd0;
	else begin
		case (q)
			4'd5:    q <= {3'd0, modIn};
			4'd6:    q <= {3'd1, modIn};
			4'd7:    q <= {3'd2, modIn};
			4'd8:    q <= {3'd3, modIn};
			4'd9:    q <= {3'd4, modIn};
			default: q <= {q[2:0],modIn};
		endcase
	end
end

endmodule: bin2bcd

