## ========== CLOCK ==========
# 100 MHz clock on pin Y9
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk -period 9.600 [get_ports clk]

## ========== RESET ==========
# BTN0 (active low reset)
set_property PACKAGE_PIN T18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## ========== OUTPUT (example) ==========
# Tie Data_out[0] to LED0 (to prevent optimization away)
set_property PACKAGE_PIN T22 [get_ports {Data_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Data_out[0]}]
