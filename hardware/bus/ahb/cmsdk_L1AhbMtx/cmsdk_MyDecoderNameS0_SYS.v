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
//-----------------------------------------------------------------------------
//  Abstract             : The MatrixDecode is used to determine which output
//                         stage is required for a particular access. Addresses
//                         that do not map to an Output port are diverted to
//                         the local default slave.
//
//  Notes               : The bus matrix has full connectivity.
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module cmsdk_MyDecoderNameS0_SYS (

    // Common AHB signals
    HCLK,
    HRESETn,

    // Signals from the Input stage
    HREADYS,
    sel_dec,
    decode_addr_dec,
    trans_dec,

    // Bus-switch output 0
    active_dec0,
    readyout_dec0,
    resp_dec0,
    rdata_dec0,
    ruser_dec0,

    // Bus-switch output 1
    active_dec1,
    readyout_dec1,
    resp_dec1,
    rdata_dec1,
    ruser_dec1,

    // Output port selection signals
    sel_dec0,
    sel_dec1,

    // Selected Output port data and control signals
    active_dec,
    HREADYOUTS,
    HRESPS,
    HRUSERS,
    HRDATAS

    );


// -----------------------------------------------------------------------------
// Input and Output declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    input         HCLK;           // AHB System Clock
    input         HRESETn;        // AHB System Reset

    // Signals from the Input stage
    input         HREADYS;        // Transfer done
    input         sel_dec;            // HSEL input
    input [31:10] decode_addr_dec;     // HADDR decoder input
    input   [1:0] trans_dec;          // Input port HTRANS signal

    // Bus-switch output MI0
    input         active_dec0;        // Output stage MI0 active_dec signal
    input         readyout_dec0;      // HREADYOUT input
    input   [1:0] resp_dec0;          // HRESP input
    input  [31:0] rdata_dec0;         // HRDATA input
    input  [31:0] ruser_dec0;         // HRUSER input

    // Bus-switch output MI1
    input         active_dec1;        // Output stage MI1 active_dec signal
    input         readyout_dec1;      // HREADYOUT input
    input   [1:0] resp_dec1;          // HRESP input
    input  [31:0] rdata_dec1;         // HRDATA input
    input  [31:0] ruser_dec1;         // HRUSER input

    // Output port selection signals
    output        sel_dec0;           // HSEL output
    output        sel_dec1;           // HSEL output

    // Selected Output port data and control signals
    output        active_dec;         // Combinatorial active_dec O/P
    output        HREADYOUTS;     // HREADY feedback output
    output  [1:0] HRESPS;         // Transfer response
    output [31:0] HRUSERS;        // User read Data
    output [31:0] HRDATAS;        // Read Data


// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    wire          HCLK;            // AHB System Clock
    wire          HRESETn;         // AHB System Reset

    // Signals from the Input stage
    wire          HREADYS;         // Transfer done
    wire          sel_dec;             // HSEL input
    wire  [31:10] decode_addr_dec;      // HADDR input
    wire    [1:0] trans_dec;           // Input port HTRANS signal

    // Bus-switch output MI0
    wire          active_dec0;         // active_dec signal
    wire          readyout_dec0;       // HREADYOUT input
    wire    [1:0] resp_dec0;           // HRESP input
    wire   [31:0] rdata_dec0;          // HRDATA input
    wire   [31:0] ruser_dec0;          // HRUSER input
    reg           sel_dec0;            // HSEL output

    // Bus-switch output MI1
    wire          active_dec1;         // active_dec signal
    wire          readyout_dec1;       // HREADYOUT input
    wire    [1:0] resp_dec1;           // HRESP input
    wire   [31:0] rdata_dec1;          // HRDATA input
    wire   [31:0] ruser_dec1;          // HRUSER input
    reg           sel_dec1;            // HSEL output


// -----------------------------------------------------------------------------
// Signal declarations
// -----------------------------------------------------------------------------

    // Selected Output port data and control signals
    reg           active_dec;          // Combinatorial active_dec O/P signal
    reg           HREADYOUTS;      // Combinatorial HREADYOUT signal
    reg     [1:0] HRESPS;          // Combinatorial HRESPS signal
    reg    [31:0] HRUSERS;
    reg    [31:0] HRDATAS;         // Read data bus

    reg     [1:0] addr_out_port;     // Address output ports
    reg     [1:0] data_out_port;     // Data output ports

    // Default slave signals
    reg           sel_dft_slv;       // HSEL signal
    wire          readyout_dft_slv;  // HREADYOUT signal
    wire    [1:0] resp_dft_slv;      // Combinatorial HRESPS signal


// -----------------------------------------------------------------------------
// Beginning of main code
// -----------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Default slave (accessed when HADDR is unmapped)
//------------------------------------------------------------------------------

  cmsdk_L1AhbMtx_default_slave u_cmsdk_L1AhbMtx_default_slave (

    // Common AHB signals
    .HCLK        (HCLK),
    .HRESETn     (HRESETn),

    // AHB Control signals
    .HSEL        (sel_dft_slv),
    .HTRANS      (trans_dec),
    .HREADY      (HREADYS),
    .HREADYOUT   (readyout_dft_slv),
    .HRESP       (resp_dft_slv)

    );


//------------------------------------------------------------------------------
// Address phase signals
//------------------------------------------------------------------------------

// The address decode is done in two stages. This is so that the address
//  decode occurs in only one process, p_addr_out_portComb, and then the select
//  signal is factored in.
//
// Note that the hexadecimal address values are reformatted to align with the
//  lower bound of decode_addr_dec[31:10], which is not a hex character boundary

  always @ (
             decode_addr_dec or data_out_port or trans_dec
           )
    begin : p_addr_out_port_comb
      // Address region 0x20000000-0x3fffffff
      if (((decode_addr_dec >= 22'h080000) & (decode_addr_dec <= 22'h0fffff))
                           | ((data_out_port == 2'b00) & (trans_dec == 2'b00)))
        addr_out_port = 2'b00;  // Select Output port MI0

      // Address region 0x40000000-0x4fffffff
      else if (((decode_addr_dec >= 22'h100000) & (decode_addr_dec <= 22'h13ffff))
                           | ((data_out_port == 2'b01) & (trans_dec == 2'b00)))
        addr_out_port = 2'b01;  // Select Output port MI1

      else
        addr_out_port = 2'b10;   // Select the default slave
    end // block: p_addr_out_port_comb

  // Select signal decode
  always @ (sel_dec or addr_out_port)
    begin : p_sel_comb
      sel_dec0 = 1'b0;
      sel_dec1 = 1'b0;
      sel_dft_slv = 1'b0;

      if (sel_dec)
        case (addr_out_port)
          2'b00 : sel_dec0 = 1'b1;
          2'b01 : sel_dec1 = 1'b1;
          2'b10 : sel_dft_slv = 1'b1;    // Select the default slave
          default : begin
            sel_dec0 = 1'bx;
            sel_dec1 = 1'bx;
            sel_dft_slv = 1'bx;
          end
        endcase // case(addr_out_port)
    end // block: p_sel_comb

// The decoder selects the appropriate active_dec signal depending on which
//  output stage is required for the transfer.
  always @ (
             active_dec0 or
             active_dec1 or
             addr_out_port
           )
    begin : p_active_comb
      case (addr_out_port)
        2'b00 : active_dec = active_dec0;
        2'b01 : active_dec = active_dec1;
        2'b10 : active_dec = 1'b1;         // Select the default slave
        default : active_dec = 1'bx;
      endcase // case(addr_out_port)
    end // block: p_active_comb


//------------------------------------------------------------------------------
// Data phase signals
//------------------------------------------------------------------------------

// The data_out_port needs to be updated when HREADY from the input stage is high.
//  Note: HREADY must be used, not HREADYOUT, because there are occaisions
//  (namely when the holding register gets loaded) when HREADYOUT may be low
//  but HREADY is high, and in this case it is important that the data_out_port
//  gets updated.

  always @ (negedge HRESETn or posedge HCLK)
    begin : p_data_out_port_seq
      if (~HRESETn)
        data_out_port <= {2{1'b0}};
      else
        if (HREADYS)
          data_out_port <= addr_out_port;
    end // block: p_data_out_port_seq

  // HREADYOUTS output decode
  always @ (
             readyout_dft_slv or
             readyout_dec0 or
             readyout_dec1 or
             data_out_port
           )
  begin : p_ready_comb
    case (data_out_port)
      2'b00 : HREADYOUTS = readyout_dec0;
      2'b01 : HREADYOUTS = readyout_dec1;
      2'b10 : HREADYOUTS = readyout_dft_slv;    // Select the default slave
      default : HREADYOUTS = 1'bx;
    endcase // case(data_out_port)
  end // block: p_ready_comb

  // HRESPS output decode
  always @ (
             resp_dft_slv or
             resp_dec0 or
             resp_dec1 or
             data_out_port
           )
  begin : p_resp_comb
    case (data_out_port)
      2'b00 : HRESPS = resp_dec0;
      2'b01 : HRESPS = resp_dec1;
      2'b10 : HRESPS = resp_dft_slv;     // Select the default slave
      default : HRESPS = {2{1'bx}};
    endcase // case (data_out_port)
  end // block: p_resp_comb

  // HRDATAS output decode
  always @ (
             rdata_dec0 or
             rdata_dec1 or
             data_out_port
           )
  begin : p_rdata_comb
    case (data_out_port)
      2'b00 : HRDATAS = rdata_dec0;
      2'b01 : HRDATAS = rdata_dec1;
      2'b10 : HRDATAS = {32{1'b0}};   // Select the default slave
      default : HRDATAS = {32{1'bx}};
    endcase // case (data_out_port)
  end // block: p_rdata_comb

  // HRUSERS output decode
  always @ (
             ruser_dec0 or
             ruser_dec1 or
             data_out_port
           )
  begin : p_ruser_comb
    case (data_out_port)
      2'b00 : HRUSERS = ruser_dec0;
      2'b01 : HRUSERS = ruser_dec1;
      2'b10 : HRUSERS = {32{1'b0}};   // Select the default slave
      default : HRUSERS = {32{1'bx}};
    endcase // case (data_out_port)
  end // block: p_ruser_comb


endmodule

// --================================= End ===================================--
