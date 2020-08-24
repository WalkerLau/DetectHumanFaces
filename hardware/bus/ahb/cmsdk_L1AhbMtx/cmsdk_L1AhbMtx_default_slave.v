//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2001-2013-2020 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//      SVN Information
//
//      Checked In          : $Date: 2013-01-23 11:45:45 +0000 (Wed, 23 Jan 2013) $
//
//      Revision            : $Revision: 234562 $
//
//      Release Information : Cortex-M System Design Kit-r1p0-01rel0
//
//-----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------
// Abstract            : Default slave used to drive the slave response signals
//                       when there are no other slaves selected.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module cmsdk_L1AhbMtx_default_slave (

    // Common AHB signals
    HCLK,
    HRESETn,

    // AHB control input signals
    HSEL,
    HTRANS,
    HREADY,

    // AHB control output signals
    HREADYOUT,
    HRESP

    );


// -----------------------------------------------------------------------------
// Input and Output declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    input         HCLK;           // AHB System Clock
    input         HRESETn;        // AHB System Reset

    // AHB control input signals
    input         HSEL;           // Slave Select
    input  [1:0]  HTRANS;         // Transfer type
    input         HREADY;         // Transfer done

    // AHB control output signals
    output        HREADYOUT;      // HREADY feedback
    output  [1:0] HRESP;          // Transfer response


// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------

// HRESP transfer response signal encoding
`define RSP_OKAY    2'b00      // OKAY response
`define RSP_ERROR   2'b01     // ERROR response
`define RSP_RETRY   2'b10     // RETRY response
`define RSP_SPLIT   2'b11     // SPLIT response


// -----------------------------------------------------------------------------
// Input and Output declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    wire          HCLK;           // AHB System Clock
    wire          HRESETn;        // AHB System Reset

    // AHB control input signals
    wire          HSEL;           // Slave Select
    wire    [1:0] HTRANS;         // Transfer type
    wire          HREADY;         // Transfer done

    // AHB control output signals
    wire          HREADYOUT;      // HREADY feedback
    wire    [1:0] HRESP;          // Transfer response


// -----------------------------------------------------------------------------
// Signal declarations
// -----------------------------------------------------------------------------

    wire          invalid;    // Set during invalid transfer
    wire          hready_next; // Controls generation of HREADYOUT output
    reg           i_hreadyout; // HREADYOUT register
    wire    [1:0] hresp_next;  // Generated response
    reg     [1:0] i_hresp;     // HRESP register


// -----------------------------------------------------------------------------
// Beginning of main code
// -----------------------------------------------------------------------------

  assign invalid = ( HREADY & HSEL & HTRANS[1] );
  assign hready_next = i_hreadyout ?  ~invalid : 1'b1 ;
  assign hresp_next = invalid ? `RSP_ERROR : `RSP_OKAY;

  always @(negedge HRESETn or posedge HCLK)
    begin : p_resp_seq
      if (~HRESETn)
        begin
          i_hreadyout <= 1'b1;
          i_hresp     <= `RSP_OKAY;
        end
      else
        begin
          i_hreadyout <= hready_next;

          if (i_hreadyout)
            i_hresp <= hresp_next;
        end
    end

  // Drive outputs with internal versions
  assign HREADYOUT = i_hreadyout;
  assign HRESP     = i_hresp;


endmodule

// --================================= End ===================================--
