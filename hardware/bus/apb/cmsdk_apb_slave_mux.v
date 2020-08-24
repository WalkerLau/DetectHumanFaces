//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2010-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//      SVN Information
//
//      Checked In          : $Date: 2013-04-15 17:00:07 +0100 (Mon, 15 Apr 2013) $
//
//      Revision            : $Revision: 244029 $
//
//      Release Information : Cortex-M System Design Kit-r1p0-00rel0
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Abstract : APB slave multiplex
//-----------------------------------------------------------------------------
module cmsdk_apb_slave_mux #(
  // Parameters to enable/disable ports
  parameter PORT0_ENABLE  = 1,
  parameter PORT1_ENABLE  = 1,
  parameter PORT2_ENABLE  = 1,
  parameter PORT3_ENABLE  = 1,
  parameter PORT4_ENABLE  = 1,
  parameter PORT5_ENABLE  = 1,
  parameter PORT6_ENABLE  = 1,
  parameter PORT7_ENABLE  = 1,
  parameter PORT8_ENABLE  = 1,
  parameter PORT9_ENABLE  = 1,
  parameter PORT10_ENABLE = 1,
  parameter PORT11_ENABLE = 1,
  parameter PORT12_ENABLE = 1,
  parameter PORT13_ENABLE = 1,
  parameter PORT14_ENABLE = 1,
  parameter PORT15_ENABLE = 1)
 (
// --------------------------------------------------------------------------
// Port Definitions
// --------------------------------------------------------------------------
  input  wire  [3:0]  DECODE4BIT,
  input  wire         PSEL, 

  output wire         PSEL0,
  input  wire         PREADY0,
  input  wire [31:0]  PRDATA0,
  input  wire         PSLVERR0,

  output wire         PSEL1,  
  input  wire         PREADY1,
  input  wire [31:0]  PRDATA1,
  input  wire         PSLVERR1,

  output wire         PSEL2,
  input  wire         PREADY2,
  input  wire [31:0]  PRDATA2,
  input  wire         PSLVERR2,

  output wire         PSEL3,
  input  wire         PREADY3,
  input  wire [31:0]  PRDATA3,
  input  wire         PSLVERR3,

  output wire         PSEL4,
  input  wire         PREADY4,
  input  wire [31:0]  PRDATA4,
  input  wire         PSLVERR4,

  output wire         PSEL5,
  input  wire         PREADY5,
  input  wire [31:0]  PRDATA5,
  input  wire         PSLVERR5,

  output wire         PSEL6,
  input  wire         PREADY6,
  input  wire [31:0]  PRDATA6,
  input  wire         PSLVERR6,

  output wire         PSEL7,
  input  wire         PREADY7,
  input  wire [31:0]  PRDATA7,
  input  wire         PSLVERR7,

  output wire         PSEL8,
  input  wire         PREADY8,
  input  wire [31:0]  PRDATA8,
  input  wire         PSLVERR8,

  output wire         PSEL9,
  input  wire         PREADY9,
  input  wire [31:0]  PRDATA9,
  input  wire         PSLVERR9,

  output wire         PSEL10,
  input  wire         PREADY10,
  input  wire [31:0]  PRDATA10,
  input  wire         PSLVERR10,

  output wire         PSEL11,
  input  wire         PREADY11,
  input  wire [31:0]  PRDATA11,
  input  wire         PSLVERR11,

  output wire         PSEL12,
  input  wire         PREADY12,
  input  wire [31:0]  PRDATA12,
  input  wire         PSLVERR12,

  output wire         PSEL13,
  input  wire         PREADY13,
  input  wire [31:0]  PRDATA13,
  input  wire         PSLVERR13,

  output wire         PSEL14,
  input  wire         PREADY14,
  input  wire [31:0]  PRDATA14,
  input  wire         PSLVERR14,

  output wire         PSEL15,
  input  wire         PREADY15,
  input  wire [31:0]  PRDATA15,
  input  wire         PSLVERR15,

  output wire         PREADY,
  output wire [31:0]  PRDATA,
  output wire         PSLVERR);

  // --------------------------------------------------------------------------
  // Start of main code
  // --------------------------------------------------------------------------

  wire [15:0] en  = { (PORT15_ENABLE == 1), (PORT14_ENABLE == 1),
                      (PORT13_ENABLE == 1), (PORT12_ENABLE == 1),
                      (PORT11_ENABLE == 1), (PORT10_ENABLE == 1),
                      (PORT9_ENABLE  == 1), (PORT8_ENABLE  == 1),
                      (PORT7_ENABLE  == 1), (PORT6_ENABLE  == 1),
                      (PORT5_ENABLE  == 1), (PORT4_ENABLE  == 1),
                      (PORT3_ENABLE  == 1), (PORT2_ENABLE  == 1),
                      (PORT1_ENABLE  == 1), (PORT0_ENABLE  == 1) };

  wire [15:0] dec = { (DECODE4BIT == 4'd15), (DECODE4BIT == 4'd14),
                      (DECODE4BIT == 4'd13), (DECODE4BIT == 4'd12),
                      (DECODE4BIT == 4'd11), (DECODE4BIT == 4'd10),
                      (DECODE4BIT == 4'd9 ), (DECODE4BIT == 4'd8 ),
                      (DECODE4BIT == 4'd7 ), (DECODE4BIT == 4'd6 ),
                      (DECODE4BIT == 4'd5 ), (DECODE4BIT == 4'd4 ),
                      (DECODE4BIT == 4'd3 ), (DECODE4BIT == 4'd2 ),
                      (DECODE4BIT == 4'd1 ), (DECODE4BIT == 4'd0 ) };

  assign PSEL0   = PSEL & dec[ 0] & en[ 0];
  assign PSEL1   = PSEL & dec[ 1] & en[ 1];   
  assign PSEL2   = PSEL & dec[ 2] & en[ 2];
  assign PSEL3   = PSEL & dec[ 3] & en[ 3];
  assign PSEL4   = PSEL & dec[ 4] & en[ 4];
  assign PSEL5   = PSEL & dec[ 5] & en[ 5];
  assign PSEL6   = PSEL & dec[ 6] & en[ 6];
  assign PSEL7   = PSEL & dec[ 7] & en[ 7];
  assign PSEL8   = PSEL & dec[ 8] & en[ 8];
  assign PSEL9   = PSEL & dec[ 9] & en[ 9];
  assign PSEL10  = PSEL & dec[10] & en[10];
  assign PSEL11  = PSEL & dec[11] & en[11];
  assign PSEL12  = PSEL & dec[12] & en[12];
  assign PSEL13  = PSEL & dec[13] & en[13];
  assign PSEL14  = PSEL & dec[14] & en[14];
  assign PSEL15  = PSEL & dec[15] & en[15];

  assign PREADY  = ~PSEL |
                   ( dec[ 0]  & (PREADY0  | ~en[ 0]) ) |
                   ( dec[ 1]  & (PREADY1  | ~en[ 1]) ) |
                   ( dec[ 2]  & (PREADY2  | ~en[ 2]) ) |
                   ( dec[ 3]  & (PREADY3  | ~en[ 3]) ) |
                   ( dec[ 4]  & (PREADY4  | ~en[ 4]) ) |
                   ( dec[ 5]  & (PREADY5  | ~en[ 5]) ) |
                   ( dec[ 6]  & (PREADY6  | ~en[ 6]) ) |
                   ( dec[ 7]  & (PREADY7  | ~en[ 7]) ) |
                   ( dec[ 8]  & (PREADY8  | ~en[ 8]) ) |
                   ( dec[ 9]  & (PREADY9  | ~en[ 9]) ) |
                   ( dec[10]  & (PREADY10 | ~en[10]) ) |
                   ( dec[11]  & (PREADY11 | ~en[11]) ) |
                   ( dec[12]  & (PREADY12 | ~en[12]) ) |
                   ( dec[13]  & (PREADY13 | ~en[13]) ) |
                   ( dec[14]  & (PREADY14 | ~en[14]) ) |
                   ( dec[15]  & (PREADY15 | ~en[15]) );

  assign PSLVERR = ( PSEL0  & PSLVERR0  ) |
                   ( PSEL1  & PSLVERR1  ) |
                   ( PSEL2  & PSLVERR2  ) |
                   ( PSEL3  & PSLVERR3  ) |
                   ( PSEL4  & PSLVERR4  ) |
                   ( PSEL5  & PSLVERR5  ) |
                   ( PSEL6  & PSLVERR6  ) |
                   ( PSEL7  & PSLVERR7  ) |
                   ( PSEL8  & PSLVERR8  ) |
                   ( PSEL9  & PSLVERR9  ) |
                   ( PSEL10 & PSLVERR10 ) |
                   ( PSEL11 & PSLVERR11 ) |
                   ( PSEL12 & PSLVERR12 ) |
                   ( PSEL13 & PSLVERR13 ) |
                   ( PSEL14 & PSLVERR14 ) |
                   ( PSEL15 & PSLVERR15 );

  assign PRDATA  = ( {32{PSEL0 }} & PRDATA0  ) |
                   ( {32{PSEL1 }} & PRDATA1  ) |
                   ( {32{PSEL2 }} & PRDATA2  ) |
                   ( {32{PSEL3 }} & PRDATA3  ) |
                   ( {32{PSEL4 }} & PRDATA4  ) |
                   ( {32{PSEL5 }} & PRDATA5  ) |
                   ( {32{PSEL6 }} & PRDATA6  ) |
                   ( {32{PSEL7 }} & PRDATA7  ) |
                   ( {32{PSEL8 }} & PRDATA8  ) |
                   ( {32{PSEL9 }} & PRDATA9  ) |
                   ( {32{PSEL10}} & PRDATA10 ) |
                   ( {32{PSEL11}} & PRDATA11 ) |
                   ( {32{PSEL12}} & PRDATA12 ) |
                   ( {32{PSEL13}} & PRDATA13 ) |
                   ( {32{PSEL14}} & PRDATA14 ) |
                   ( {32{PSEL15}} & PRDATA15 );

endmodule
