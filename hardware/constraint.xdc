############## NET - IOSTANDARD ###################
set_property CFGBVS VCCO            [current_design]
set_property CONFIG_VOLTAGE 3.3     [current_design]

#############SPI Configurate Setting###############
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4    [current_design]
set_property CONFIG_MODE SPIx4                  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50     [current_design]

############## Clock ##############################
create_clock -period 20.000         [get_ports CLK50M]
set_property IOSTANDARD LVCMOS33    [get_ports CLK50M]
set_property PACKAGE_PIN P15        [get_ports CLK50M]

############## LEDs ###############################
set_property IOSTANDARD LVCMOS33    [get_ports {ledNumOut[3]}]
set_property IOSTANDARD LVCMOS33    [get_ports {ledNumOut[2]}]
set_property IOSTANDARD LVCMOS33    [get_ports {ledNumOut[1]}]
set_property IOSTANDARD LVCMOS33    [get_ports {ledNumOut[0]}]
set_property PACKAGE_PIN H16        [get_ports {ledNumOut[3]}]
set_property PACKAGE_PIN G16        [get_ports {ledNumOut[2]}]
set_property PACKAGE_PIN K15        [get_ports {ledNumOut[1]}]
set_property PACKAGE_PIN J15        [get_ports {ledNumOut[0]}]

############## UART ################################
set_property IOSTANDARD LVCMOS33    [get_ports TXD]
set_property IOSTANDARD LVCMOS33    [get_ports RXD]
set_property PACKAGE_PIN D11        [get_ports TXD]
set_property PACKAGE_PIN B16        [get_ports RXD]

############## Buttons #############################
set_property IOSTANDARD LVCMOS33    [get_ports RSTn]
set_property PACKAGE_PIN M15        [get_ports RSTn]

#############HDMI_O####################################
set_property IOSTANDARD LVTTL [get_ports tmds_clk_n]
set_property PACKAGE_PIN A20  [get_ports tmds_clk_n]

set_property PACKAGE_PIN B20  [get_ports tmds_clk_p]
set_property IOSTANDARD LVTTL [get_ports tmds_clk_p]

set_property IOSTANDARD LVTTL [get_ports {tmds_data_n[0]}]
set_property PACKAGE_PIN A17  [get_ports {tmds_data_n[0]}]

set_property PACKAGE_PIN A16  [get_ports {tmds_data_p[0]}]
set_property IOSTANDARD LVTTL [get_ports {tmds_data_p[0]}]

set_property IOSTANDARD LVTTL [get_ports {tmds_data_n[1]}]
set_property PACKAGE_PIN A13  [get_ports {tmds_data_n[1]}]

set_property PACKAGE_PIN B13  [get_ports {tmds_data_p[1]}]
set_property IOSTANDARD LVTTL [get_ports {tmds_data_p[1]}]

set_property IOSTANDARD LVTTL [get_ports {tmds_data_n[2]}]
set_property PACKAGE_PIN A12  [get_ports {tmds_data_n[2]}]

set_property PACKAGE_PIN A11  [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD LVTTL [get_ports {tmds_data_p[2]}]

############## CMOS define############################
set_property PACKAGE_PIN C22 [get_ports cmos_scl]
set_property PACKAGE_PIN D21 [get_ports cmos_sda]
set_property PACKAGE_PIN B22 [get_ports cmos_pclk]
set_property PACKAGE_PIN D18 [get_ports cmos_href]
set_property PACKAGE_PIN B21 [get_ports cmos_vsync]
set_property PACKAGE_PIN B19 [get_ports {cmos_db[7]}]
set_property PACKAGE_PIN C19 [get_ports {cmos_db[6]}]
set_property PACKAGE_PIN C16 [get_ports {cmos_db[5]}]
set_property PACKAGE_PIN D16 [get_ports {cmos_db[4]}]
set_property PACKAGE_PIN C20 [get_ports {cmos_db[3]}]
set_property PACKAGE_PIN D20 [get_ports {cmos_db[2]}]
set_property PACKAGE_PIN C15 [get_ports {cmos_db[1]}]
set_property PACKAGE_PIN C17 [get_ports {cmos_db[0]}]
set_property PACKAGE_PIN C18 [get_ports cmos_xclk]

set_property IOSTANDARD LVCMOS33 [get_ports cmos_sda]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_scl]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cmos_db[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_pclk]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_href]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports cmos_xclk]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cmos_pclk_IBUF]
