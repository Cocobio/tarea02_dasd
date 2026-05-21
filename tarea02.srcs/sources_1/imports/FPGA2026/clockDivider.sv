`timescale 1ns / 1ps

module clockDivider(
	input logic clk,
	output divClk
);

parameter TC = 2000;
localparam nBits= $clog2(TC) + 1;  // $clog2 calcula el techo del log2 del argumento
                                   // El " + 1" es para permitir dividir por 2

logic [nBits-1: 0] counter = 0;    // " + 1" garantiza un registro de minimo 2 bits
assign divClk = (counter == TC - 1);
always_ff @(posedge clk)
	if (divClk)
		counter<= 0;
	else
		counter<= counter+ 1;

endmodule: clockDivider

module buttonEdgeDetect (input logic button, clk, divClk, output logic edgeDet);

  logic n1=0, n2=0;


  always_ff @(posedge clk) begin  // sincronizador con antirrebote​

    if (divClk)                   // muestreo a frecuencia dividida​

      n1 <= button;               // muestreo​

    n2 <= n1;                     // sincronización​

  end


  assign edgeDet = ~n2 & n1;      // detector de cantos vale 1 durante 1 ciclo de clk​


endmodule : buttonEdgeDetect

