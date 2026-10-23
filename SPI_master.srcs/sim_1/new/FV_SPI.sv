`timescale 1ns/1ns

/*
    FUNCTIONAL VERIFICATION OF THE SPI MASTER, TO CHECK FOR A HAPPY DATAPATH.
*/

module FV_SPI();

localparam DATA_WIDTH = 8;
localparam SYS_CLK = 100_000_000;
localparam SYS_SCLK = 25_000_000;

logic clk;
logic reset;
// data lines
logic [DATA_WIDTH-1:0] in_data;  // data to send to slave
logic [DATA_WIDTH-1:0] out_data; // data recieved from slave
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

initial clk = 0;
always #5 clk = ~clk;

SPI_master #(DATA_WIDTH,SYS_CLK,SYS_SCLK) DUT (.*);

initial begin
reset = 1;in_data = 0;CPOL = 0;CPHA = 0;SPIDAT = 0;MISO = 0;
#20 reset = 0;

#10;
in_data = 8'd99;

#10;
SPIDAT = 1;
#10;
SPIDAT = 0;

#1000;
$finish;
end

endmodule : FV_SPI