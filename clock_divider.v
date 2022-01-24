`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:50:16 12/01/2011 
// Design Name: 
// Module Name:    clock_divider 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clock_divider(
	input	wire	clk,
	input	wire	rst,
	input wire [31:0] period, // period of divided clock
	input wire [31:0] width, // width of divided clock, must be less than period
	output reg clk_div	// divided clock
    );

reg [31:0]	count;

always @(posedge clk, posedge rst)
if (rst == 1'b1)
begin
	count <= 32'b0;
	clk_div <= 1'b0;
end 
else if (count >= period -1)
begin
	count <= 32'b0;
	clk_div <= 1'b1;
end
else 
begin
	count <= count +1;
	if (count >= width-1)
		clk_div <= 1'b0;
end

endmodule
