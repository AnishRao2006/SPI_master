`timescale 1ns/1ns

/*
    This is the complete UVM verification environment for a SPI master, which tests for all clock types (CPOL and CPHA) and 
    some corner data cases. SCLK is a 25Mhz clock generated from the SYSTEM clock which is a 100Mhz clock.
*/

// header files
`include "uvm_macros.svh"
import uvm_pkg :: *;

/*
    INTERFACE
*/
interface spi_inf 
    #(
    parameter DATA_WIDTH = 8,
    parameter SYS_CLK = 100_000_000,
    parameter SYS_SCLK = 25_000_000
    )(
    input logic clk
    );

logic reset;
// data lines
logic [DATA_WIDTH-1:0] in_data;  // data to send to slave.
logic [DATA_WIDTH-1:0] out_data; // data recieved from slave (Using it as a Slave Data).
// SPI protocol
logic MISO;
logic MOSI;
logic SS;
logic SCLK;
// CLK types
logic CPOL;
logic CPHA;
// Button to start 
logic SPIDAT;
// signal to show end of tranmission
logic SPIDONE;

endinterface : spi_inf

/*
    TRANSACTION
*/
class transaction extends uvm_sequence_item;

`uvm_object_utils_begin(transaction);
`uvm_field_int(CPOL, UVM_ALL_ON)
`uvm_field_int(CPHA, UVM_ALL_ON)
`uvm_field_int(in_data, UVM_ALL_ON)    
`uvm_object_utils_end    

function new(string name = "transaction");
super.new(name);
endfunction

localparam DATA_WIDTH = 8;

rand logic reset;
// data lines
rand logic [DATA_WIDTH-1:0] in_data;  // data to send to slave
logic [DATA_WIDTH-1:0] out_data; // data recieved from slave
// SPI protocol
logic MISO;
logic MOSI;
logic SS;
logic SCLK;
// CLK types
rand logic CPOL;
rand logic CPHA;
// Button to start 
logic SPIDAT;
// signal to show end of tranmission
logic SPIDONE;

endclass : transaction

/*
    SEQUENCES
*/
class base_seq extends uvm_sequence #(transaction);

`uvm_object_utils(base_seq);

function new(string name = "base_seq");
super.new(name);
endfunction

endclass : base_seq

class reset_sequence extends base_seq;

`uvm_object_utils(reset_sequence);

function new(string name = "reset_sequence");
super.new(name);
endfunction

task body();
transaction tx;
`uvm_do_with(tx, {reset == 1;CPOL == 0;CPHA == 0;})
endtask

endclass : reset_sequence

class data_0 extends base_seq;

`uvm_object_utils(data_0);

function new(string name = "data_0");
super.new(name);
endfunction

task body();
transaction tx;
`uvm_do_with(tx, {reset == 0;CPHA == 0;CPOL == 0;})
endtask

endclass : data_0

class data_1 extends base_seq;

`uvm_object_utils(data_1);

function new(string name = "data_1");
super.new(name);
endfunction

task body();
transaction tx;
`uvm_do_with(tx, {reset == 0;CPHA == 1;CPOL == 0;})
endtask

endclass : data_1

class data_2 extends base_seq;

`uvm_object_utils(data_2);

function new(string name = "data_2");
super.new(name);
endfunction

task body();
transaction tx;
`uvm_do_with(tx, {reset == 0;CPHA == 0;CPOL == 1;})
endtask

endclass : data_2

class data_3 extends base_seq;

`uvm_object_utils(data_3);

function new(string name = "data_3");
super.new(name);
endfunction

task body();
transaction tx;
`uvm_do_with(tx, {reset == 0;CPHA == 1;CPOL == 1;})
endtask

endclass : data_3

/*
    DRIVER AND MONITORS
*/
class driver extends uvm_driver #(transaction);

`uvm_component_utils(driver);

function new(string name = "driver", uvm_component parent);
super.new(name,parent);
endfunction

virtual spi_inf in;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(virtual spi_inf) :: get(this,"","vif",in))
`uvm_fatal("DRV", $sformatf("No virtual interface specified for this driver instance"));
endfunction

task run_phase(uvm_phase phase);
transaction tx;
forever begin
seq_item_port.get_next_item(tx);

// driving data
@(negedge in.clk);
if(tx.reset) begin
in.reset = 1;
@(negedge in.clk);
in.reset = 0;
end 

@(negedge in.clk);
in.reset = 0;
in.in_data = tx.in_data;
in.CPOL = tx.CPOL;
in.CPHA = tx.CPHA;
in.MISO = 1'b0;

`uvm_info("DRV", $sformatf("Pressing Button!!!"), UVM_LOW);
@(negedge in.clk);
in.SPIDAT = 1'b1;
@(negedge in.clk);
in.SPIDAT = 1'b0;

// Waiting for transmission to end
wait(in.SPIDONE == 1'b1);
@(negedge in.clk);

seq_item_port.item_done();
end
endtask

endclass : driver

class input_monitor extends uvm_monitor;

`uvm_component_utils(input_monitor);

function new(string name = "input_monitor", uvm_component parent);
super.new(name,parent);
endfunction

uvm_analysis_port #(transaction) bp;
virtual spi_inf in;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
bp = new("bp",this);
if(!uvm_config_db #(virtual spi_inf) :: get(this,"","vif",in))
`uvm_fatal("IMON", $sformatf("No virtual interface specified for this monitor instance"));
endfunction

task run_phase(uvm_phase phase);
transaction tx;
forever begin

// monitoring data
@(posedge in.clk);
if(in.SPIDAT) begin
`uvm_info("IMON", $sformatf("Monitoring Input Side"), UVM_LOW);
tx = transaction :: type_id :: create("tx");
tx.in_data = in.in_data;
tx.CPOL = in.CPOL;
tx.CPHA = in.CPHA;
bp.write(tx);
end

end
endtask

endclass : input_monitor

class output_monitor extends uvm_monitor;

`uvm_component_utils(output_monitor);

function new(string name = "output_monitor", uvm_component parent);
super.new(name,parent);
endfunction

uvm_analysis_port #(transaction) ap;
virtual spi_inf out;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
ap = new("ap",this);
if(!uvm_config_db #(virtual spi_inf) :: get(this,"","vif",out))
`uvm_fatal("OMON", $sformatf("No virtual interface specified for this monitor instance"));
endfunction

task run_phase(uvm_phase phase);
transaction tx;
forever begin
@(posedge out.clk);

// Only if transmission is Started.
wait(out.SS == 1'b0);
tx = transaction :: type_id :: create("tx");

// To Simulate a Slave that samples the MOSI line.
// (PS : NOT AN ACTUAL SLAVE JUST SAMPLING THE OUT-GOING DATA).
`uvm_info("OMON", $sformatf("Monitoring Output Side"), UVM_LOW);

for(int i = 0; i < out.DATA_WIDTH; i++) begin
case({out.CPOL,out.CPHA})
2'b00 : begin
@(negedge out.SCLK);
tx.out_data = {out.MOSI,tx.out_data[out.DATA_WIDTH-1:1]};
end
2'b01 : begin
@(posedge out.SCLK);
tx.out_data = {out.MOSI,tx.out_data[out.DATA_WIDTH-1:1]};
end
2'b10 : begin
@(posedge out.SCLK);
tx.out_data = {out.MOSI,tx.out_data[out.DATA_WIDTH-1:1]};
end
2'b11 : begin
@(negedge out.SCLK);
tx.out_data = {out.MOSI,tx.out_data[out.DATA_WIDTH-1:1]};
end
endcase
end

// Transmission Done
wait(out.SS == 1'b1);
ap.write(tx);

end
endtask

endclass : output_monitor

/*
    AGENT FOR CONNECTION
*/
class agent extends uvm_agent;

`uvm_component_utils(agent);

function new(string name = "agent", uvm_component parent);
super.new(name,parent);
endfunction

driver drv;
uvm_sequencer #(transaction) sqr;
input_monitor imon;
output_monitor omon;

uvm_active_passive_enum is_active = UVM_ACTIVE;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
void'(uvm_config_db #(uvm_active_passive_enum) :: get(this,"","is_active",is_active));

imon = input_monitor :: type_id :: create("imon",this);
omon = output_monitor :: type_id :: create("omon",this);

if(is_active == UVM_ACTIVE) begin
drv = driver :: type_id :: create("drv",this);
sqr = uvm_sequencer #(transaction) :: type_id :: create("sqr",this);
end
endfunction

function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
drv.seq_item_port.connect(sqr.seq_item_export);
endfunction

endclass : agent

/*
    SCOREBOARD
*/
class scoreboard extends uvm_scoreboard;

`uvm_component_utils(scoreboard);

function new(string name = "scoreboard", uvm_component parent);
super.new(name,parent);
endfunction

uvm_tlm_analysis_fifo #(transaction) exp_fifo;
uvm_tlm_analysis_fifo #(transaction) act_fifo;

int fail_cnt,pass_cnt;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
exp_fifo = new("exp_fifo",this);
act_fifo = new("act_fifo",this);
endfunction

task run_phase(uvm_phase phase);
transaction tx_act,tx_exp;
forever begin
exp_fifo.get(tx_exp);
act_fifo.get(tx_act);

// data comparing 
if(tx_exp.in_data == tx_act.out_data) begin
pass_cnt++;
`uvm_info("SCR", $sformatf("Data Matched!"), UVM_LOW);
end
else begin
fail_cnt++;
`uvm_error("SCR", $sformatf("Mismatch! Exp: %h, Act: %h", tx_exp.in_data, tx_act.out_data));
end

end
endtask

function void check_phase(uvm_phase phase);
super.check_phase(phase);
if(fail_cnt > 0) `uvm_error("SCR", $sformatf("TEST FAILED"))
else `uvm_info("SCR", $sformatf("TEST PASSED"), UVM_LOW)
endfunction

endclass : scoreboard

/*
    COVERAGE
*/
class coverage extends uvm_subscriber #(transaction);

`uvm_component_utils(coverage);

function new(string name = "coverage", uvm_component parent);
super.new(name,parent);
cg_spi = new();
endfunction

transaction tx;
real final_cover;
covergroup cg_spi;
option.per_instance = 1;
cpha : coverpoint tx.CPHA;
cpol : coverpoint tx.CPOL;
data : coverpoint tx.in_data;
cross_cpol_cpha : cross cpha, cpol;
endgroup 

function void write(transaction t);
$cast(tx,t.clone());
cg_spi.sample();
endfunction

function void report_phase(uvm_phase phase);
super.report_phase(phase);
final_cover = cg_spi.get_inst_coverage();
`uvm_info("CVR", $sformatf("code coverage = %.2f%%",final_cover), UVM_LOW);
endfunction

endclass : coverage

/*
    ENVIRONMENT
*/
class env extends uvm_env;

`uvm_component_utils(env);

agent agt;
scoreboard scr;
coverage cvr;

function new(string name = "env", uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
agt = agent :: type_id :: create("agt",this);
scr = scoreboard :: type_id :: create("scr",this);
cvr = coverage :: type_id :: create("cvr",this);
endfunction

function void connect_phase(uvm_phase phase);
super.connect_phase(phase);

// monitors connection
agt.imon.bp.connect(scr.exp_fifo.analysis_export);
agt.omon.ap.connect(scr.act_fifo.analysis_export);

// coverage connection
agt.imon.bp.connect(cvr.analysis_export);

endfunction

endclass : env

/*
    TESTS
*/
class base_test extends uvm_test;

`uvm_component_utils(base_test);

function new(string name = "base_test", uvm_component parent);
super.new(name,parent);
endfunction

env e;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
uvm_config_db #(uvm_active_passive_enum) :: set(null,"e.agt","is_active",UVM_ACTIVE);
e = env :: type_id :: create("e",this);
endfunction

endclass : base_test

class test extends base_test;

`uvm_component_utils(test);

function new(string name = "test", uvm_component parent);
super.new(name,parent);
endfunction

task run_phase(uvm_phase phase);
reset_sequence rst_seq;
data_0 d0;
data_1 d1;
data_2 d2;
data_3 d3;
phase.raise_objection(this);
begin
rst_seq = reset_sequence :: type_id :: create("rst_seq");
rst_seq.start(e.agt.sqr);
end
#50;
begin
d0 = data_0 :: type_id :: create("d0");
d0.start(e.agt.sqr);
end
#50;
begin
d1 = data_1 :: type_id :: create("d1");
d1.start(e.agt.sqr);
end
#50;
begin
d2 = data_2 :: type_id :: create("d2");
d2.start(e.agt.sqr);
end
#50;
begin
d3 = data_3 :: type_id :: create("d3");
d3.start(e.agt.sqr);
end
#50;
phase.drop_objection(this);
endtask

endclass : test

/*
    TOP MODULE
*/
module UVM_SPI();

logic clk = 0;
always #5 clk = ~clk;

spi_inf phy_if(clk);

localparam DATA_WIDTH = 8;
localparam SYS_CLK = 100_000_000;
localparam SYS_SCLK = 25_000_000;

SPI_master #(DATA_WIDTH,SYS_CLK,SYS_SCLK) DUT (
    .clk(phy_if.clk),
    .reset(phy_if.reset),
    .in_data(phy_if.in_data),
    .out_data(phy_if.out_data),
    .SS(phy_if.SS),
    .MOSI(phy_if.MOSI),
    .MISO(phy_if.MISO),
    .SCLK(phy_if.SCLK),
    .CPOL(phy_if.CPOL),
    .CPHA(phy_if.CPHA),
    .SPIDAT(phy_if.SPIDAT),
    .SPIDONE(phy_if.SPIDONE)
);

initial begin
phy_if.reset = 1;
#10;
phy_if.reset = 0;
end

initial begin
uvm_config_db #(virtual spi_inf) :: set(null,"*","vif",phy_if);
run_test("test");
end

endmodule : UVM_SPI