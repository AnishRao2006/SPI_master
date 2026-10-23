`timescale 1ns/1ns

/*
    Building a SPI master from scartch
    following the Texas Instruments PDF 
*/

package SPI_pkg;
// main FSM
typedef enum logic [2:0]
{
IDLE = 0,
DATA_0 = 1,
DATA_1 = 2,
DATA_2 = 3,
DATA_3 = 4,
DONE = 5
}spi_state;
// button FSM
typedef enum logic [1:0]
{
NOT_PRESS = 0,
WAIT1 = 1,
WAIT2 = 2,
PRESS = 3
}button_state;
endpackage : SPI_pkg

module SPI_master
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
    output logic [DATA_WIDTH-1:0] out_data, // data recieved from slave
    // SPI protocol
    input logic MISO,
    output logic MOSI,
    output logic SS,
    output logic SCLK,
    // CLK types
    input logic CPOL,
    input logic CPHA,
    // Button to start 
    input logic SPIDAT,
    //signal to show end of transmission
    output logic SPIDONE
    );
    
import SPI_pkg :: *;

// detection of SPIDAT
logic [1:0] button_current,button_next;
logic DONE_SPI;
assign SPIDONE = DONE_SPI;

always_ff @(posedge clk or posedge reset) begin
if(reset) button_current <= NOT_PRESS;
else begin
button_current <= button_next;
end
end

always_comb begin
button_next = button_current;
case(button_current)
NOT_PRESS : begin
if(SPIDAT) button_next = WAIT1;
else button_next = NOT_PRESS;
end
WAIT1 : button_next = PRESS;
PRESS : begin
if(DONE_SPI) button_next = WAIT2;
else button_next = PRESS;
end
WAIT2 : button_next = NOT_PRESS;
default : button_next = button_current;
endcase
end

always_comb begin
case(button_current)
NOT_PRESS : begin
SS = 1;
end
WAIT1 : SS = 0;
PRESS : begin
SS = 0;
end
WAIT2 : SS = 0;
default : SS = 1;
endcase
end

// designing a clock divider to get SYS_SCLK from SYS_CLK
localparam value = SYS_CLK / SYS_SCLK;
logic [$clog2(value)-1:0] counter;
logic temp_sclk;

always_ff @(posedge clk or posedge reset) begin
if(reset) begin
counter <= 0;
end
else begin
if(button_current == PRESS) begin
if(counter >= value-1) counter <= 0;
else counter <= counter + 1;
end
else counter <= 0;
end
end

always_comb begin
case(button_current)
NOT_PRESS,WAIT1,WAIT2 : begin
if(CPOL) temp_sclk = 1;
else temp_sclk = 0;
end
PRESS : begin
if(counter > (value/2)-1) begin
if(CPHA) temp_sclk = 1;
else temp_sclk = 0;
end
else begin
if(CPHA) temp_sclk = 0;
else temp_sclk = 1;
end
end
default : temp_sclk = 0;
endcase
end

always_comb begin
if(CPOL) begin
case(button_current)
NOT_PRESS : SCLK = temp_sclk;
PRESS : SCLK = ~temp_sclk;
WAIT1 : SCLK = temp_sclk;
WAIT2 : SCLK = temp_sclk;
default : SCLK = temp_sclk;
endcase
end
else SCLK = temp_sclk;
end

// edge detector for SCLK
logic sclk_prev;
logic high_flag,low_flag;

always_ff @(posedge clk) begin
sclk_prev <= SCLK;
end

assign high_flag = (SCLK == 1 && sclk_prev == 0);
assign low_flag = (SCLK == 0 && sclk_prev == 1);

// Main FSM
logic [2:0] current_state,next_state;
logic [DATA_WIDTH-1:0] shift_in_data; // from slave to master
logic [DATA_WIDTH-1:0] shift_out_data;  // from master to slave
logic [$clog2(DATA_WIDTH):0] data_count;

// next state assignment and output logic 
always_ff @(posedge clk or posedge reset) begin
if(reset) begin
current_state <= IDLE;
shift_out_data <= 0;
shift_in_data <= 0;
DONE_SPI <= 0;
data_count <= 0;
end
else begin
current_state <= next_state;

// MAIN logic
case(current_state)
IDLE : begin
shift_out_data <= in_data;
shift_in_data <= 0;
DONE_SPI <= 0;
data_count <= 0;
end
DATA_0 : begin
if(high_flag) begin
data_count <= data_count + 1;
shift_in_data <= {1'b0,shift_in_data[DATA_WIDTH-1:1]};
end
else if(low_flag) begin
shift_out_data <= {1'b0,shift_out_data[DATA_WIDTH-1:1]};
shift_in_data[DATA_WIDTH-1] <= MISO;
end
end
DATA_1 : begin
if(high_flag) begin
shift_in_data[DATA_WIDTH-1] <= MISO;
shift_out_data <= {1'b0,shift_out_data[DATA_WIDTH-1:1]};
end
else if(low_flag) begin
shift_in_data <= {1'b0,shift_in_data[DATA_WIDTH-1:1]};
data_count <= data_count + 1;
end
end
DATA_2 : begin
if(high_flag) begin
shift_in_data[DATA_WIDTH-1] <= MISO;
shift_out_data <= {1'b0,shift_out_data[DATA_WIDTH-1:1]};
end
else if(low_flag) begin
data_count <= data_count + 1;
shift_in_data <= {1'b0,shift_in_data[DATA_WIDTH-1:1]};
end
end
DATA_3 : begin
if(high_flag) begin
data_count <= data_count + 1;
shift_in_data <= {1'b0,shift_in_data[DATA_WIDTH-1:1]};
end
else if(low_flag) begin
shift_out_data <= {1'b0,shift_out_data[DATA_WIDTH-1:1]};
shift_in_data[DATA_WIDTH-1] <= MISO;
end
end
DONE : begin
DONE_SPI <= 1;
out_data <= shift_in_data;
end
default : begin
shift_out_data <= 0;
shift_in_data <= 0;
DONE_SPI <= 0;
data_count <= 0;
end
endcase
end
end

// output for MOSI
always_ff @(posedge clk) begin
case(current_state)
DATA_0 : begin 
if(high_flag) MOSI <= shift_out_data[0];
else if(low_flag) MOSI <= shift_out_data[0];
else MOSI <= shift_out_data[0];
end
DATA_1 : begin
if(low_flag) MOSI <= shift_out_data[0];
else MOSI <= shift_out_data[0];
end
DATA_2 : begin 
if(low_flag) MOSI <= shift_out_data[0];
else if(low_flag) MOSI <= shift_out_data[0];
else MOSI <= shift_out_data[0];
end
DATA_3 : begin
if(high_flag) MOSI <= shift_out_data[0];
else MOSI <= shift_out_data[0];
end
default : MOSI <= 0;
endcase
end

// next state logic 
always_comb begin
next_state = current_state;
case(current_state)
IDLE : begin
if(SPIDAT) begin
case({CPOL,CPHA})
2'b00 : next_state = DATA_0;
2'b01 : next_state = DATA_1;
2'b10 : next_state = DATA_2;
2'b11 : next_state = DATA_3;
default : next_state = IDLE;
endcase
end
else next_state = IDLE;
end
DATA_0 : begin
if(data_count == DATA_WIDTH) next_state = DONE;
else next_state = DATA_0;
end
DATA_1 : begin
if(data_count == DATA_WIDTH-1) next_state = DONE;
else next_state = DATA_1;
end
DATA_2 : begin
if(data_count == DATA_WIDTH) next_state = DONE;
else next_state = DATA_2;
end
DATA_3 : begin
if(data_count == DATA_WIDTH-1) next_state = DONE;
else next_state = DATA_3;
end
DONE : begin
next_state = IDLE;
end
default : begin
next_state = current_state;
end
endcase
end

endmodule : SPI_master