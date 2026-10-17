## EDGE Artix-7 kit pin mapping from the user-supplied XDC PDF.
## Clock frequency is NOT stated in that PDF. This assumes 100 MHz / 10 ns;
## confirm the exact board revision/manual before using this timing constraint.
set_property -dict { PACKAGE_PIN N11 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -name sys_clk -period 10.000 [get_ports { clk }]

## USB-UART: FPGA TX to bridge RX; bridge TX to FPGA RX
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { usb_uart_txd }]
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports { usb_uart_rxd }]

## Center push button, treated as active-high reset
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { rst_btn }]

## LEDs [7:0]
set_property -dict { PACKAGE_PIN J3 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN H3 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN K1 IOSTANDARD LVCMOS33 } [get_ports { led[3] }]
set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 } [get_ports { led[4] }]
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports { led[5] }]
set_property -dict { PACKAGE_PIN K3 IOSTANDARD LVCMOS33 } [get_ports { led[6] }]
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports { led[7] }]
