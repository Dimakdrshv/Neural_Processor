create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports {i_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_clk}]
set_property PACKAGE_PIN E3 [get_ports {i_clk}]

set_property PACKAGE_PIN D4 [get_ports {o_uart_tx}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_uart_tx}]
set_property PACKAGE_PIN C4 [get_ports {i_uart_rx}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_uart_rx}]
