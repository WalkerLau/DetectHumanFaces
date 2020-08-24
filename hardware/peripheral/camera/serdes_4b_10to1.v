`timescale 1ns/1ps

module serdes_4b_10to1 (
	input          clk,           // clock input
	input          clkx5,         // 5x clock input
	input [9:0]    datain_0,      // input data for serialisation
	input [9:0]    datain_1,      // input data for serialisation
	input [9:0]    datain_2,      // input data for serialisation
	input [9:0]    datain_3,      // input data for serialisation
	output         dataout_0_p,   // out DDR data
	output         dataout_0_n,   // out DDR data
	output         dataout_1_p,   // out DDR data
	output         dataout_1_n,   // out DDR data
	output         dataout_2_p,   // out DDR data
	output         dataout_2_n,   // out DDR data
	output         dataout_3_p,   // out DDR data
	output         dataout_3_n    // out DDR data
  ) ;   
  
reg [2:0] TMDS_mod5 = 0;  // modulus 5 counter

reg [4:0] TMDS_shift_0h = 0, TMDS_shift_0l = 0;
reg [4:0] TMDS_shift_1h = 0, TMDS_shift_1l = 0;
reg [4:0] TMDS_shift_2h = 0, TMDS_shift_2l = 0;
reg [4:0] TMDS_shift_3h = 0, TMDS_shift_3l = 0;

wire [4:0] TMDS_0_l = {datain_0[9],datain_0[7],datain_0[5],datain_0[3],datain_0[1]};
wire [4:0] TMDS_0_h = {datain_0[8],datain_0[6],datain_0[4],datain_0[2],datain_0[0]};

wire [4:0] TMDS_1_l = {datain_1[9],datain_1[7],datain_1[5],datain_1[3],datain_1[1]};
wire [4:0] TMDS_1_h = {datain_1[8],datain_1[6],datain_1[4],datain_1[2],datain_1[0]};

wire [4:0] TMDS_2_l = {datain_2[9],datain_2[7],datain_2[5],datain_2[3],datain_3[1]};
wire [4:0] TMDS_2_h = {datain_2[8],datain_2[6],datain_2[4],datain_2[2],datain_3[0]};

wire [4:0] TMDS_3_l = {datain_3[9],datain_3[7],datain_3[5],datain_3[3],datain_3[1]};
wire [4:0] TMDS_3_h = {datain_3[8],datain_3[6],datain_3[4],datain_3[2],datain_3[0]};

always @(posedge clkx5)
begin
	TMDS_shift_0h  <= TMDS_mod5[2] ? TMDS_0_h : TMDS_shift_0h[4:1];
	TMDS_shift_0l  <= TMDS_mod5[2] ? TMDS_0_l : TMDS_shift_0l[4:1];
	TMDS_shift_1h  <= TMDS_mod5[2] ? TMDS_1_h : TMDS_shift_1h[4:1];
	TMDS_shift_1l  <= TMDS_mod5[2] ? TMDS_1_l : TMDS_shift_1l[4:1];
	TMDS_shift_2h  <= TMDS_mod5[2] ? TMDS_2_h : TMDS_shift_2h[4:1];
	TMDS_shift_2l  <= TMDS_mod5[2] ? TMDS_2_l : TMDS_shift_2l[4:1];
	TMDS_shift_3h  <= TMDS_mod5[2] ? TMDS_3_h : TMDS_shift_3h[4:1];
	TMDS_shift_3l  <= TMDS_mod5[2] ? TMDS_3_l : TMDS_shift_3l[4:1];	
	TMDS_mod5 <= (TMDS_mod5[2]) ? 3'd0 : TMDS_mod5 + 3'd1;
end

//-p
ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U1_ODDR2
(
.Q(dataout_3_p),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(TMDS_shift_3h[0]), // 1-bit data input (associated with C0)
.D1(TMDS_shift_3l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);

ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U2_ODDR2
(
.Q(dataout_2_p),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(TMDS_shift_2h[0]), // 1-bit data input (associated with C0)
.D1(TMDS_shift_2l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);

ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U3_ODDR2
(
.Q(dataout_1_p),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(TMDS_shift_1h[0]), // 1-bit data input (associated with C0)
.D1(TMDS_shift_1l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);
ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U4_ODDR2
(
.Q(dataout_0_p),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(TMDS_shift_0h[0]), // 1-bit data input (associated with C0)
.D1(TMDS_shift_0l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);

//-n           
ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U5_ODDR2
(
.Q(dataout_3_n),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(~TMDS_shift_3h[0]), // 1-bit data input (associated with C0)
.D1(~TMDS_shift_3l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);

ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U6_ODDR2
(
.Q(dataout_2_n),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(~TMDS_shift_2h[0]), // 1-bit data input (associated with C0)
.D1(~TMDS_shift_2l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);

ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U7_ODDR2
(
.Q(dataout_1_n),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(~TMDS_shift_1h[0]), // 1-bit data input (associated with C0)
.D1(~TMDS_shift_1l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);
ODDR2 #(
.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) U8_ODDR2
(
.Q(dataout_0_n),   // 1-bit DDR output data
.C0(clkx5),   // 1-bit clock input
.C1(~clkx5),   // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(~TMDS_shift_0h[0]), // 1-bit data input (associated with C0)
.D1(~TMDS_shift_0l[0]), // 1-bit data input (associated with C1)
.R(1'b0),   // 1-bit reset input
.S(1'b0)    // 1-bit set input
);
endmodule
