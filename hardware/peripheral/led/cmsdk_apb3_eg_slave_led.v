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
//      Checked In          : $Date: 2012-07-31 10:47:23 +0100 (Tue, 31 Jul 2012) $
//
//      Revision            : $Revision: 217027 $
//
//      Release Information : Cortex-M System Design Kit-r1p0-00rel0
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Abstract : APB example slave, support AMBA APB3
//            slave is always ready and response is always OKAY.
//-----------------------------------------------------------------------------

module  cmsdk_apb3_eg_slave_led #(
  // parameter for address width
  parameter ADDRWIDTH = 12)
 (
  // IO declaration
  input  wire                    PCLK,     // pclk
  input  wire                    PRESETn,  // reset

  // apb interface inputs
  input  wire                    PSEL,
  input  wire  [ADDRWIDTH-1:0]   PADDR,
  input  wire                    PENABLE,
  input  wire                    PWRITE,
  input  wire  [31:0]            PWDATA,

  // Engineering-change-order revision bits
  input  wire  [3:0]             ECOREVNUM,

  // apb interface outputs
  output wire  [31:0]            PRDATA,
  output wire                    PREADY,
  output wire                    PSLVERR,
  
  // LED output
  output wire [3:0]              ledNumOut
  );

//------------------------------------------------------------------------------
//internal wires
//------------------------------------------------------------------------------
  // LED module interface signals
  wire  [31:0]          ledNumIn;


//------------------------------------------------------------------------------
// module logic start
//------------------------------------------------------------------------------
 // Interface to convert APB signals to simple read and write controls
 cmsdk_apb3_eg_slave_interface_led  #(.ADDRWIDTH (ADDRWIDTH))
   u_apb_eg_slave_interface_led(

  .pclk            (PCLK),     // pclk
  .presetn         (PRESETn),  // reset

  .psel            (PSEL),     // apb interface inputs
  .paddr           (PADDR),
  .penable         (PENABLE),
  .pwrite          (PWRITE),
  .pwdata          (PWDATA),

  .prdata          (PRDATA),   // apb interface outputs
  .pready          (PREADY),
  .pslverr         (PSLVERR),

  // LED interface
  .ledNumIn        (ledNumIn)

  );

  // LED
  custom_apb_led  u_custom_apb_led(
    .clk           (PCLK),
    .rst           (PRESETn),
    .ledNumIn      (ledNumIn),
    .ledNumOut     (ledNumOut)
  );

 //------------------------------------------------------------------------------
 // module logic end
 //------------------------------------------------------------------------------
`ifdef ARM_APB_ASSERT_ON

 `include "std_ovl_defines.h"
  // ------------------------------------------------------------
  // Assertions
  // ------------------------------------------------------------

   // Check the reg_write_en signal generated
    assert_implication
    #(`OVL_ERROR,
      `OVL_ASSERT,
      "Error! register write signal was not generated! "
      )
     u_ovl_apb3_eg_slave_reg_write
     (.clk             (PCLK),
      .reset_n         (PRESETn),
      .antecedent_expr ( (PSEL & (~PENABLE) & PWRITE) ),
      .consequent_expr ( reg_write_en == 1'b1)
      );



  // Check the reg_read_en signal generated
    assert_implication
    #(`OVL_ERROR,
      `OVL_ASSERT,
      "Error! register read signal was not generated! "
      )
     u_ovl_apb3_eg_slave_reg_read
     (.clk             (PCLK),
      .reset_n         (PRESETn),
      .antecedent_expr ( (PSEL & (~PENABLE) & (~PWRITE)) ),
      .consequent_expr ( reg_read_en == 1'b1)
      );


  // Check register read and write operation won't assert at the same cycle
    assert_never
     #(`OVL_ERROR,
       `OVL_ASSERT,
       "Error! register read and write active at the same cycle!")
     u_ovl_apb3_eg_slave_rd_wr_illegal
     (.clk        (PCLK),
      .reset_n    (PRESETn),
      .test_expr  ((reg_write_en & reg_read_en))
      );



`endif

endmodule
