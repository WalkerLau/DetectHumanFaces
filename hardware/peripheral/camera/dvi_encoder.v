`timescale 1 ps / 1ps
module dvi_encoder
(
input           pixelclk,       // system clock
input           pixelclk5x,     // system clock x5
input           rstin,          // reset
input[7:0]      blue_din,       // Blue data in
input[7:0]      green_din,      // Green data in
input[7:0]      red_din,        // Red data in
input           hsync,          // hsync data
input           vsync,          // vsync data
input           de,             // data enable
output          tmds_clk_p,
output          tmds_clk_n,
output[2:0]     tmds_data_p,    //rgb
output[2:0]     tmds_data_n     //rgb
);

wire    [9:0]   red ;
wire    [9:0]   green ;
wire    [9:0]   blue ;

encode encb (
.clkin      (pixelclk),
.rstin      (rstin),
.din        (blue_din),
.c0         (hsync),
.c1         (vsync),
.de         (de),
.dout       (blue)) ;

encode encr (
.clkin      (pixelclk),
.rstin      (rstin),
.din        (green_din),
.c0         (1'b0),
.c1         (1'b0),
.de         (de),
.dout       (green)) ;

encode encg (
.clkin      (pixelclk),
.rstin      (rstin),
.din        (red_din),
.c0         (1'b0),
.c1         (1'b0),
.de         (de),
.dout       (red)) ;
serdes_4b_10to1 serdes_4b_10to1_m0(
.clk           (pixelclk        ),// clock input
.clkx5         (pixelclk5x      ),// 5x clock input
.datain_0      (blue            ),// input data for serialisation
.datain_1      (green         ),// input data for serialisation
.datain_2      (red             ),// input data for serialisation
.datain_3      (10'b1111100000  ),// input data for serialisation
.dataout_0_p   (tmds_data_p[0]  ),// out DDR data
.dataout_0_n   (tmds_data_n[0]  ),// out DDR data
.dataout_1_p   (tmds_data_p[1]  ),// out DDR data
.dataout_1_n   (tmds_data_n[1]  ),// out DDR data
.dataout_2_p   (tmds_data_p[2]  ),// out DDR data
.dataout_2_n   (tmds_data_n[2]  ),// out DDR data
.dataout_3_p   (tmds_clk_p      ),// out DDR data
.dataout_3_n   (tmds_clk_n      ) // out DDR data
) ; 

endmodule
