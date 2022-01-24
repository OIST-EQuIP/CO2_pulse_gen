`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:43:58 07/12/2012 
// Design Name: 
// Module Name:    CO2_pulse_control 
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
module CO2_pulse_control(
	input		wire [7:0]  hi_in,
	output	wire [1:0]  hi_out,
	inout		wire [15:0] hi_inout,
	
	input  	wire clk_pll,
	output	reg	laser_gate,
	output	reg	shutter
    );

localparam num_ok_out = 2;
localparam STATE_INI = 2'd0,
	STATE_IDLE = 2'd1,
	STATE_SHOOT = 2'd2,
	STATE_PH = 2'd3;

// Target interface bus:
wire    ti_clk;
wire [30:0] ok1;
wire [16:0]  ok2;
wire [17*num_ok_out-1:0] ok2s;

// Wire in
wire [15:0] ep00wire; //shoot-trigger delay
wire [15:0] ep01wire; //trigger-pulse delay
wire [15:0] ep02wire; //laser-shutter delay
wire [15:0] ep03wire; //laser low time
wire [15:0] ep04wire; //laser width
wire [15:0] ep05wire; //end_delay
wire [15:0] ep06wire; //default logics

// Wire Out
wire [15:0] ep20wire; //state machine monitor
wire [15:0] ep21wire; //counter

// Trigger in
wire [15:0] ep40trig; //bit 0 is reset, bit 1 is state-machine reset, bit2 is shoot trigger

//Signals
wire				clk_div;
reg	[15:0]	counter;
reg	[1:0]		current_state;
wire	shoot_trig;
reg	shoot_done;

//Parameters
wire	[15:0]	shoot_trig_delay;
wire	[15:0]	trig_pulse_delay;
wire	[15:0]	laser_shutter_delay;
wire	[15:0]	laser_low_time;
wire	[15:0]	laser_width;
wire	[15:0]	end_delay;
wire	[15:0]	gate_width;
wire	[15:0]	T0;
wire	[15:0]	Tend;
wire				laser_default;
wire				shutter_default;

assign rst = ep40trig[0];
assign rst_sm = ep40trig[1];
assign shoot_trig = ep40trig[2];
assign laser_default = ep06wire[0];
assign shutter_default = ep06wire[1];

assign ep20wire[1:0] = current_state;
assign ep21wire = counter;

assign shoot_trig_delay = ep00wire;
assign trig_pulse_delay = ep01wire;
assign laser_shutter_delay = ep02wire;
assign laser_low_time = ep03wire;
assign laser_width = ep04wire;
assign end_delay = ep05wire;

assign gate_width = laser_width+2*laser_low_time-2*laser_shutter_delay;
assign T0 = shoot_trig_delay+trig_pulse_delay;
assign Tend = T0 + 2*laser_low_time + laser_width;

// Divide the clock by a factor of 10000 to produce 0.1 ms clock, assuming clk_pll at 100 MHz 
clock_divider clkdiv1(.clk(clk_pll), .rst(rst), .period(10000), .width(10), .clk_div(clk_div));

// State machine: combinational part
function [1:0] next_state
 (input [1:0]	state,
 input trig,
 input done);
begin
 next_state = state;
 case(state)
	STATE_INI:
		next_state = STATE_IDLE;
	STATE_IDLE:
		if (trig) next_state = STATE_SHOOT;
	STATE_SHOOT:
		if (done) next_state = STATE_INI;
	STATE_PH:
		next_state = STATE_INI;
	endcase
end
endfunction

always @(posedge clk_div, posedge rst_sm)
	if (rst_sm)
	begin
		current_state <= STATE_INI;
		laser_gate <= laser_default;
		shutter <= shutter_default;
	end
	else
	begin
		current_state <= next_state(current_state, shoot_trig, shoot_done);
		case (current_state)
			STATE_INI:
			begin
				counter <= 16'd0;
				shoot_done <= 1'b0;
			end
			
			STATE_IDLE:
			begin
			end
			
			STATE_SHOOT:
			begin
				counter <= counter + 1;
				if (counter < T0)
					laser_gate <= 1'b1;
				else if (counter < T0 + laser_low_time)
					laser_gate <= 1'b0;
				else if (counter < T0 + laser_low_time + laser_width)
					laser_gate <= 1'b1;
				else if (counter < Tend)
					laser_gate <= 1'b0;
				else if (counter < Tend + end_delay)
					laser_gate <= 1'b1;
				
				if (counter < T0 + laser_shutter_delay)
					shutter <= 1'b0;
				else if (counter < T0 + laser_shutter_delay + gate_width)
					shutter <= 1'b1;
				else if (counter < Tend + end_delay)
					shutter <= 1'b0;
				
				if (counter == Tend + end_delay)
					shoot_done <= 1'b1;
			end
			
			STATE_PH:
			begin
			end
		endcase
	end

// OK interface
okHost okHI(
 .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
 .ok1(ok1), .ok2(ok2));
okWireOR #(.N(num_ok_out)) okWireOR (.ok2(ok2), .ok2s(ok2s));
okTriggerIn  ep40 (.ok1(ok1), .ep_addr(8'h40), .ep_clk(clk_div), .ep_trigger(ep40trig));

okWireIn  ep00 (.ok1(ok1),  .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn  ep01 (.ok1(ok1),  .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn  ep02 (.ok1(ok1),  .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn  ep03 (.ok1(ok1),  .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn  ep04 (.ok1(ok1),  .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn  ep05 (.ok1(ok1),  .ep_addr(8'h05), .ep_dataout(ep05wire));
okWireIn  ep06 (.ok1(ok1),  .ep_addr(8'h06), .ep_dataout(ep06wire));
okWireOut ep20 (.ok1(ok1), .ok2(ok2s[ 0*17 +: 17 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut ep21 (.ok1(ok1), .ok2(ok2s[ 1*17 +: 17 ]), .ep_addr(8'h21), .ep_datain(ep21wire));

endmodule
