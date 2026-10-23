create_clock -period 10.000 -name clk_100Mhz -waveform {0.000 5.000} -add [get_ports clk]
create_generated_clock -name clk_spi -source [get_ports *clk*] -divide_by 4 -add -master_clock clk_100Mhz [get_ports *SCLK*]

set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {clk}]

## Custom SPI Mapping on Boolean Board PMOD Port A (Header J1, Pins 1-4)
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports {SS}]; # Pin 1
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports {MOSI}]; # Pin 2
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports {MISO}]; # Pin 3
set_property -dict { PACKAGE_PIN V9    IOSTANDARD LVCMOS33 } [get_ports {SCLK}]; # Pin 4

set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports {reset}]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {SPIDAT}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports {CPOL}]
set_property -dict {PACKAGE_PIN T2 IOSTANDARD LVCMOS33} [get_ports {CPHA}]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {in_data[0]}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {in_data[1]}]
set_property -dict {PACKAGE_PIN R1 IOSTANDARD LVCMOS33} [get_ports {in_data[2]}]
set_property -dict {PACKAGE_PIN P2 IOSTANDARD LVCMOS33} [get_ports {in_data[3]}]
set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS33} [get_ports {in_data[4]}]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS33} [get_ports {in_data[5]}]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports {in_data[6]}]
set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVCMOS33} [get_ports {in_data[7]}]

set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports {SPIDONE}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {out_data[0]}]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33} [get_ports {out_data[1]}]
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS33} [get_ports {out_data[2]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {out_data[3]}]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {out_data[4]}]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {out_data[5]}]
set_property -dict {PACKAGE_PIN E5 IOSTANDARD LVCMOS33} [get_ports {out_data[6]}]
set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS33} [get_ports {out_data[7]}]
