`timescale 1ns/1ns

/*
    SVA for the SPI master, to catch any protocol violations.
*/

module SVA_SPI
    #(
    parameter DATA_WIDTH = 8,
    parameter SYS_CLK = 100_000_000,
    parameter SYS_SCLK = 25_000_000
    )(
    // system inputs
    input logic clk,
    input logic reset,
    // data lines
    input logic [DATA_WIDTH-1:0] in_data,  // data to send to slave
    input logic [DATA_WIDTH-1:0] out_data, // data recieved from slave
    // SPI protocol
    input logic MISO,
    input logic MOSI,
    input logic SS,
    input logic SCLK,
    // CLK types
    input logic CPOL,
    input logic CPHA,
    // Button to start 
    input logic SPIDAT,
    //signal to show end of transmission
    input logic SPIDONE,
    //internal signals from SPI_master
    input logic [1:0] button_current,button_next,
    input logic high_flag,low_flag,
    // Main FSM
    input logic [2:0] current_state,next_state,
    input logic [DATA_WIDTH-1:0] shift_in_data, // from slave to master
    input logic [DATA_WIDTH-1:0] shift_out_data,  // from master to slave
    input logic [$clog2(DATA_WIDTH):0] data_count
    );
    
initial begin
$display("SVA SPI is alive");
end    

import SPI_pkg :: *;

// modes 00/11 sample on rising, 01/10 sample on falling
wire sample_edge;
wire shift_edge;

// helper signals
logic sclk_q;
wire sclk_rise;
wire sclk_fall;

assign sample_edge = (CPOL == CPHA) ? sclk_fall : sclk_rise;
assign shift_edge  = (CPOL == CPHA) ? sclk_rise : sclk_fall;
assign sclk_rise = SCLK && !sclk_q;
assign sclk_fall = !SCLK && sclk_q;

always_ff @(posedge clk) begin
sclk_q <= SCLK;
end

int pulses;

always_ff @(posedge clk or posedge reset) begin
if(reset || SS) pulses <= 0;
else begin
if(high_flag || low_flag) pulses <= pulses + 1;
else pulses <= pulses;
end
end

/*
    RESET PROPERTIES
*/
property r1;
@(posedge clk) (reset) |=> (button_current == NOT_PRESS);
endproperty : r1
assert property(r1) else $display("r1 assertion failed");

property r2;
@(posedge clk) (reset) |=> (current_state == IDLE);
endproperty : r2
assert property(r2) else $display("r2 assertion failed");

property r3;
@(posedge clk) (reset) |=> ((shift_in_data | shift_out_data | SPIDONE | data_count) == 0);
endproperty : r3
assert property(r3) else $display("r3 assertion failed");

/*
    SS and SCLK relation checks
*/
property s1;
@(posedge clk) disable iff (reset)
(SS) |-> (SCLK == CPOL);
endproperty : s1
assert property(s1) else $display("s1 assertion failed");

property s2;
@(posedge clk) disable iff (reset)
(SS && $past(SS)) |-> $stable(SCLK);
endproperty : s2
assert property(s2) else $display("s2 assertion failed");

property s3;
@(posedge clk) disable iff (reset)
(SPIDONE) |=> (!SPIDONE);
endproperty : s3
assert property(s3) else $display("s3 assertion failed");

property s4;
@(posedge clk) disable iff (reset)
(SPIDONE && current_state == DONE) |-> ##[1:2](!SPIDONE);
endproperty : s4
assert property(s4) else $display("s4 assertion failed");

property s5;
@(posedge clk) disable iff (reset)
!(SS) |-> $stable({CPOL,CPHA});
endproperty : s5
assert property(s5) else $display("s5 assertion failed");

property s6;
@(posedge clk) disable iff (reset)
!(SS) |-> !($isunknown({SS, SCLK, MOSI, SPIDONE})); 
endproperty : s6
assert property(s6) else $display("s6 assertion failed");

/*
    DATA FRAMING
*/
property d1;
@(posedge clk) disable iff (reset || SS)
$changed(MOSI) |-> (shift_edge);
endproperty : d1
assert property(d1) else $display("d1 assertion failed");

property d2;
@(posedge clk) disable iff (reset || SS)
sample_edge |-> $stable(MOSI);
endproperty : d2
assert property(d2) else $display("d2 assertion failed");

property d3;
@(posedge clk) disable iff (reset)
$rose(SS) |-> (pulses == 2 * DATA_WIDTH);   // cause we are couting both the sclk edges
endproperty : d3
assert property(d3) else $display("d3 assertion failed");

property d4;
@(posedge clk) disable iff (reset)
$rose(SPIDONE) |-> (data_count == DATA_WIDTH);
endproperty : d4
assert property(d4) else $display("d4 assertion failed");

/*
    COVER PROPERTIES
*/
property c1;
@(posedge clk) disable iff (reset)
(SPIDAT) |=> ({CPOL,CPHA} == 2'b00);
endproperty : c1
cover property(c1);

property c2;
@(posedge clk) disable iff (reset)
(SPIDAT) |=> ({CPOL,CPHA} == 2'b01);
endproperty : c2
cover property(c2);

property c3;
@(posedge clk) disable iff (reset)
(SPIDAT) |=> ({CPOL,CPHA} == 2'b10);
endproperty : c3
cover property(c3);

property c4;
@(posedge clk) disable iff (reset)
(SPIDAT) |=> ({CPOL,CPHA} == 2'b11);
endproperty : c4
cover property(c4);

endmodule : SVA_SPI