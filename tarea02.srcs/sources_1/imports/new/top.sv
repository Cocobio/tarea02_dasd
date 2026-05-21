

module top (input logic clk, reset, start, D0s_in, D1_in, input logic [1:0] select_display, input logic [9:0] N, output logic SCLK_in, CS_in, output logic [6:0] seg, output logic [3:0] an, output logic dp);


  logic divClk;
  clockDivider #(.TC(5)) cd1 (.clk, .divClk); // 33MHz​



  logic ready_in, resetPulse;
  buttonEdgeDetect edet (.button(reset), .clk, .divClk(clk), .edgeDet(resetPulse)); 

  AD1_drv ad1(.start(), .reset(resetPulse), .clk, .divClk, .ready(ready_in), .data0(data0_in), .data1(data1_in),.D0(D0_in), .D1(D1_in), .CS(CS_in), .SCLK(SCLK_in));

  binto7seg b7seg(.clk(clk),.result() ,.seg(seg),.an(an)); //result es de 12 bits



endmodule : top



