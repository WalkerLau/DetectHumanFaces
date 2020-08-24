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
// Abstract : AMBA APB3 example slave interface module.
//            Convert APB BUS protocol to simple register read write protocol
//-----------------------------------------------------------------------------
module cmsdk_apb3_eg_slave_interface_led #(
  // parameter for address width
  parameter ADDRWIDTH = 12)
 (
  // IO declaration

  input  wire                    pclk,     // pclk
  input  wire                    presetn,  // reset

  // apb interface inputs
  input  wire                    psel,
  input  wire [ADDRWIDTH-1:0]    paddr,
  input  wire                    penable,
  input  wire                    pwrite,
  input  wire [31:0]             pwdata,

  // apb interface outputs
  output wire [31:0]             prdata,
  output wire                    pready,
  output wire                    pslverr,

  // LED write interface
  output wire [31:0]             ledNumIn
 );

 //------------------------------------------------------------------------------
 // module logic start
 //------------------------------------------------------------------------------

reg  [31:0]     Reg2LED;
wire            write_en;

// APB interface
assign   prdata  = 32'b0;
assign   pready  = 1'b1; //always ready. Can be customized to support waitstate if required.
assign   pslverr = 1'b0; //alwyas OKAY. Can be customized to support error response if required.


// LED write signal
//assign  write_en = psel & (~penable) & pwrite; // assert for 1st cycle of write transfer
        // It is also possible to change the design to perform the write in the 2nd
        // APB cycle.   E.g.
        //   assign write_en = psel & penable & pwrite;
        // However, if the design generate waitstate, this expression will result
        // in write_en being asserted for multiple cycles.
assign write_en = psel & penable & pwrite;

// enable write transfer without wait signal
always @ (posedge pclk or negedge presetn)
begin
    if(~presetn)
      Reg2LED <= 0;
    else if(write_en == 1'b1)
      Reg2LED <= pwdata;
    else
      Reg2LED <= Reg2LED;
end

assign ledNumIn = Reg2LED;



`ifdef ARM_APB_ASSERT_ON

 `include "std_ovl_defines.h"
  // ------------------------------------------------------------
  // Assertions
  // ------------------------------------------------------------

  // Check error response should not be generated if not selected
    assert_never
     #(`OVL_ERROR,
       `OVL_ASSERT,
       "Error! Should not generate error response if not selected")
     u_ovl_apb3_eg_slave_response_illegal
     (.clk        (pclk),
      .reset_n    (presetn),
      .test_expr  (pslverr & pready & (~psel))
      );

`endif

 //------------------------------------------------------------------------------
 // module logic end
 //------------------------------------------------------------------------------

endmodule


