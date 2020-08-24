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
//      Checked In          : $Date: 2012-10-15 18:01:36 +0100 (Mon, 15 Oct 2012) $
//
//      Revision            : $Revision: 225465 $
//
//      Release Information : Cortex-M System Design Kit-r1p0-01rel0
//
//-----------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
//  Abstract            : The Output Arbitration is used to determine which
//                        of the input stages will be given access to the
//                        shared slave.
//
//  Notes               : The bus matrix has full connectivity.
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module cmsdk_MyArbiterName (

    // Common AHB signals
    HCLK ,
    HRESETn,

    // Input port request signals
    req_port0,

    HREADYM,
    HSELM,
    HTRANSM,
    HBURSTM,
    HMASTLOCKM,

    // Arbiter outputs
    addr_in_port,
    no_port

    );


// -----------------------------------------------------------------------------
// Input and Output declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    input        HCLK;         // AHB system clock
    input        HRESETn;      // AHB system reset

    input        req_port0;     // Port 0 request signal

    input        HREADYM;      // Transfer done
    input        HSELM;        // Slave select line
    input  [1:0] HTRANSM;      // Transfer type
    input  [2:0] HBURSTM;      // Burst type
    input        HMASTLOCKM;   // Locked transfer

    output [0:0] addr_in_port;   // Port address input
    output       no_port;       // No port selected signal


// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------
    wire       HCLK;           // AHB system clock
    wire       HRESETn;        // AHB system reset
    wire       req_port0;       // Port 0 request signal
    wire       HREADYM;        // Transfer done
    wire       HSELM;          // Slave select line
    wire [1:0] HTRANSM;        // Transfer type
    wire       HMASTLOCKM;     // Locked transfer
    wire [0:0] addr_in_port;     // Port address input
    reg        no_port;         // No port selected signal


// -----------------------------------------------------------------------------
// Signal declarations
// -----------------------------------------------------------------------------
    reg  [0:0] addr_in_port_next; // D-input of addr_in_port
    reg  [0:0] iaddr_in_port;    // Internal version of addr_in_port
    reg        no_port_next;     // D-input of no_port


// -----------------------------------------------------------------------------
// Beginning of main code
// -----------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Port Selection
//------------------------------------------------------------------------------
// The Output Arbitration function looks at all the requests to use the
//  output port and determines which is the highest priority request. This
//  version of the arbitration logic uses a fixed priority scheme where input
//  port 0 is the highest priority, input port 1 is the second highest
//  priority, etc.
// If none of the input ports are requesting then the current port will
//  remain active if it is performing IDLE transfers to the selected slave. If
//  this is not the case then the no_port signal will be asserted which
//  indicates that no input port should be selected.

  always @ (
             req_port0 or
             HSELM or HTRANSM or HMASTLOCKM or iaddr_in_port
           )

  begin : p_sel_port_comb
    // Default values are used for addr_in_port_next and no_port_next
    no_port_next     = 1'b0;
    addr_in_port_next = iaddr_in_port;

    if (HMASTLOCKM)
      addr_in_port_next = iaddr_in_port;
    else if ( req_port0 | ( (iaddr_in_port == 1'b0) & HSELM &
                            (HTRANSM != 2'b00) ) )
      addr_in_port_next = 1'b0;
    else if (HSELM)
      addr_in_port_next = iaddr_in_port;
    else
      no_port_next = 1'b1;
  end // block: p_sel_port_comb


  // Sequential process
  always @ (negedge HRESETn or posedge HCLK)
  begin : p_addr_in_port_reg
    if (~HRESETn)
      begin
        no_port      <= 1'b1;
        iaddr_in_port <= {1{1'b0}};
      end
    else
      if (HREADYM)
        begin
          no_port      <= no_port_next;
          iaddr_in_port <= addr_in_port_next;
        end
  end // block: p_addr_in_port_reg

  // Drive output with internal version
  assign addr_in_port = iaddr_in_port;


endmodule

// --================================= End ===================================--
