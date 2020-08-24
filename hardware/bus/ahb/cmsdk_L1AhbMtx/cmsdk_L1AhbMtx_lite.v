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
//  Abstract            : BusMatrixLite is a wrapper module that wraps around
//                        the BusMatrix module to give AHB Lite compliant
//                        slave and master interfaces.
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module cmsdk_L1AhbMtx_lite (

    // Common AHB signals
    HCLK,
    HRESETn,

    // System Address Remap control
    REMAP,

    // Input port SI0 (inputs from master 0)
    HADDRS0_SYS,
    HTRANSS0_SYS,
    HWRITES0_SYS,
    HSIZES0_SYS,
    HBURSTS0_SYS,
    HPROTS0_SYS,
    HWDATAS0_SYS,
    HMASTLOCKS0_SYS,
    HAUSERS0_SYS,
    HWUSERS0_SYS,

    // Output port MI0 (inputs from slave 0)
    HRDATAM0_DTCM,
    HREADYOUTM0_DTCM,
    HRESPM0_DTCM,
    HRUSERM0_DTCM,

    // Output port MI1 (inputs from slave 1)
    HRDATAM1_APB_BRIDGE,
    HREADYOUTM1_APB_BRIDGE,
    HRESPM1_APB_BRIDGE,
    HRUSERM1_APB_BRIDGE,

    // Scan test dummy signals; not connected until scan insertion
    SCANENABLE,   // Scan Test Mode Enable
    SCANINHCLK,   // Scan Chain Input


    // Output port MI0 (outputs to slave 0)
    HSELM0_DTCM,
    HADDRM0_DTCM,
    HTRANSM0_DTCM,
    HWRITEM0_DTCM,
    HSIZEM0_DTCM,
    HBURSTM0_DTCM,
    HPROTM0_DTCM,
    HWDATAM0_DTCM,
    HMASTLOCKM0_DTCM,
    HREADYMUXM0_DTCM,
    HAUSERM0_DTCM,
    HWUSERM0_DTCM,

    // Output port MI1 (outputs to slave 1)
    HSELM1_APB_BRIDGE,
    HADDRM1_APB_BRIDGE,
    HTRANSM1_APB_BRIDGE,
    HWRITEM1_APB_BRIDGE,
    HSIZEM1_APB_BRIDGE,
    HBURSTM1_APB_BRIDGE,
    HPROTM1_APB_BRIDGE,
    HWDATAM1_APB_BRIDGE,
    HMASTLOCKM1_APB_BRIDGE,
    HREADYMUXM1_APB_BRIDGE,
    HAUSERM1_APB_BRIDGE,
    HWUSERM1_APB_BRIDGE,

    // Input port SI0 (outputs to master 0)
    HRDATAS0_SYS,
    HREADYS0_SYS,
    HRESPS0_SYS,
    HRUSERS0_SYS,

    // Scan test dummy signals; not connected until scan insertion
    SCANOUTHCLK   // Scan Chain Output

    );

// -----------------------------------------------------------------------------
// Input and Output declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    input         HCLK;            // AHB System Clock
    input         HRESETn;         // AHB System Reset

    // System Address Remap control
    input   [3:0] REMAP;           // System Address REMAP control

    // Input port SI0 (inputs from master 0)
    input  [31:0] HADDRS0_SYS;         // Address bus
    input   [1:0] HTRANSS0_SYS;        // Transfer type
    input         HWRITES0_SYS;        // Transfer direction
    input   [2:0] HSIZES0_SYS;         // Transfer size
    input   [2:0] HBURSTS0_SYS;        // Burst type
    input   [3:0] HPROTS0_SYS;         // Protection control
    input  [31:0] HWDATAS0_SYS;        // Write data
    input         HMASTLOCKS0_SYS;     // Locked Sequence
    input  [31:0] HAUSERS0_SYS;        // Address USER signals
    input  [31:0] HWUSERS0_SYS;        // Write-data USER signals

    // Output port MI0 (inputs from slave 0)
    input  [31:0] HRDATAM0_DTCM;        // Read data bus
    input         HREADYOUTM0_DTCM;     // HREADY feedback
    input         HRESPM0_DTCM;         // Transfer response
    input  [31:0] HRUSERM0_DTCM;        // Read-data USER signals

    // Output port MI1 (inputs from slave 1)
    input  [31:0] HRDATAM1_APB_BRIDGE;        // Read data bus
    input         HREADYOUTM1_APB_BRIDGE;     // HREADY feedback
    input         HRESPM1_APB_BRIDGE;         // Transfer response
    input  [31:0] HRUSERM1_APB_BRIDGE;        // Read-data USER signals

    // Scan test dummy signals; not connected until scan insertion
    input         SCANENABLE;      // Scan enable signal
    input         SCANINHCLK;      // HCLK scan input


    // Output port MI0 (outputs to slave 0)
    output        HSELM0_DTCM;          // Slave Select
    output [31:0] HADDRM0_DTCM;         // Address bus
    output  [1:0] HTRANSM0_DTCM;        // Transfer type
    output        HWRITEM0_DTCM;        // Transfer direction
    output  [2:0] HSIZEM0_DTCM;         // Transfer size
    output  [2:0] HBURSTM0_DTCM;        // Burst type
    output  [3:0] HPROTM0_DTCM;         // Protection control
    output [31:0] HWDATAM0_DTCM;        // Write data
    output        HMASTLOCKM0_DTCM;     // Locked Sequence
    output        HREADYMUXM0_DTCM;     // Transfer done
    output [31:0] HAUSERM0_DTCM;        // Address USER signals
    output [31:0] HWUSERM0_DTCM;        // Write-data USER signals

    // Output port MI1 (outputs to slave 1)
    output        HSELM1_APB_BRIDGE;          // Slave Select
    output [31:0] HADDRM1_APB_BRIDGE;         // Address bus
    output  [1:0] HTRANSM1_APB_BRIDGE;        // Transfer type
    output        HWRITEM1_APB_BRIDGE;        // Transfer direction
    output  [2:0] HSIZEM1_APB_BRIDGE;         // Transfer size
    output  [2:0] HBURSTM1_APB_BRIDGE;        // Burst type
    output  [3:0] HPROTM1_APB_BRIDGE;         // Protection control
    output [31:0] HWDATAM1_APB_BRIDGE;        // Write data
    output        HMASTLOCKM1_APB_BRIDGE;     // Locked Sequence
    output        HREADYMUXM1_APB_BRIDGE;     // Transfer done
    output [31:0] HAUSERM1_APB_BRIDGE;        // Address USER signals
    output [31:0] HWUSERM1_APB_BRIDGE;        // Write-data USER signals

    // Input port SI0 (outputs to master 0)
    output [31:0] HRDATAS0_SYS;        // Read data bus
    output        HREADYS0_SYS;     // HREADY feedback
    output        HRESPS0_SYS;         // Transfer response
    output [31:0] HRUSERS0_SYS;        // Read-data USER signals

    // Scan test dummy signals; not connected until scan insertion
    output        SCANOUTHCLK;     // Scan Chain Output

// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    wire         HCLK;            // AHB System Clock
    wire         HRESETn;         // AHB System Reset

    // System Address Remap control
    wire   [3:0] REMAP;           // System REMAP signal

    // Input Port SI0
    wire  [31:0] HADDRS0_SYS;         // Address bus
    wire   [1:0] HTRANSS0_SYS;        // Transfer type
    wire         HWRITES0_SYS;        // Transfer direction
    wire   [2:0] HSIZES0_SYS;         // Transfer size
    wire   [2:0] HBURSTS0_SYS;        // Burst type
    wire   [3:0] HPROTS0_SYS;         // Protection control
    wire  [31:0] HWDATAS0_SYS;        // Write data
    wire         HMASTLOCKS0_SYS;     // Locked Sequence

    wire  [31:0] HRDATAS0_SYS;        // Read data bus
    wire         HREADYS0_SYS;     // HREADY feedback
    wire         HRESPS0_SYS;         // Transfer response
    wire  [31:0] HAUSERS0_SYS;        // Address USER signals
    wire  [31:0] HWUSERS0_SYS;        // Write-data USER signals
    wire  [31:0] HRUSERS0_SYS;        // Read-data USER signals

    // Output Port MI0
    wire         HSELM0_DTCM;          // Slave Select
    wire  [31:0] HADDRM0_DTCM;         // Address bus
    wire   [1:0] HTRANSM0_DTCM;        // Transfer type
    wire         HWRITEM0_DTCM;        // Transfer direction
    wire   [2:0] HSIZEM0_DTCM;         // Transfer size
    wire   [2:0] HBURSTM0_DTCM;        // Burst type
    wire   [3:0] HPROTM0_DTCM;         // Protection control
    wire  [31:0] HWDATAM0_DTCM;        // Write data
    wire         HMASTLOCKM0_DTCM;     // Locked Sequence
    wire         HREADYMUXM0_DTCM;     // Transfer done

    wire  [31:0] HRDATAM0_DTCM;        // Read data bus
    wire         HREADYOUTM0_DTCM;     // HREADY feedback
    wire         HRESPM0_DTCM;         // Transfer response
    wire  [31:0] HAUSERM0_DTCM;        // Address USER signals
    wire  [31:0] HWUSERM0_DTCM;        // Write-data USER signals
    wire  [31:0] HRUSERM0_DTCM;        // Read-data USER signals

    // Output Port MI1
    wire         HSELM1_APB_BRIDGE;          // Slave Select
    wire  [31:0] HADDRM1_APB_BRIDGE;         // Address bus
    wire   [1:0] HTRANSM1_APB_BRIDGE;        // Transfer type
    wire         HWRITEM1_APB_BRIDGE;        // Transfer direction
    wire   [2:0] HSIZEM1_APB_BRIDGE;         // Transfer size
    wire   [2:0] HBURSTM1_APB_BRIDGE;        // Burst type
    wire   [3:0] HPROTM1_APB_BRIDGE;         // Protection control
    wire  [31:0] HWDATAM1_APB_BRIDGE;        // Write data
    wire         HMASTLOCKM1_APB_BRIDGE;     // Locked Sequence
    wire         HREADYMUXM1_APB_BRIDGE;     // Transfer done

    wire  [31:0] HRDATAM1_APB_BRIDGE;        // Read data bus
    wire         HREADYOUTM1_APB_BRIDGE;     // HREADY feedback
    wire         HRESPM1_APB_BRIDGE;         // Transfer response
    wire  [31:0] HAUSERM1_APB_BRIDGE;        // Address USER signals
    wire  [31:0] HWUSERM1_APB_BRIDGE;        // Write-data USER signals
    wire  [31:0] HRUSERM1_APB_BRIDGE;        // Read-data USER signals


// -----------------------------------------------------------------------------
// Signal declarations
// -----------------------------------------------------------------------------
    wire   [3:0] tie_hi_4;
    wire         tie_hi;
    wire         tie_low;
    wire   [1:0] i_hrespS0_SYS;

    wire   [3:0]        i_hmasterM0_DTCM;
    wire   [1:0] i_hrespM0_DTCM;
    wire   [3:0]        i_hmasterM1_APB_BRIDGE;
    wire   [1:0] i_hrespM1_APB_BRIDGE;

// -----------------------------------------------------------------------------
// Beginning of main code
// -----------------------------------------------------------------------------

    assign tie_hi   = 1'b1;
    assign tie_hi_4 = 4'b1111;
    assign tie_low  = 1'b0;


    assign HRESPS0_SYS  = i_hrespS0_SYS[0];

    assign i_hrespM0_DTCM = {tie_low, HRESPM0_DTCM};
    assign i_hrespM1_APB_BRIDGE = {tie_low, HRESPM1_APB_BRIDGE};

// BusMatrix instance
  cmsdk_L1AhbMtx ucmsdk_L1AhbMtx (
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),
    .REMAP      (REMAP),

    // Input port SI0 signals
    .HSELS0_SYS       (tie_hi),
    .HADDRS0_SYS      (HADDRS0_SYS),
    .HTRANSS0_SYS     (HTRANSS0_SYS),
    .HWRITES0_SYS     (HWRITES0_SYS),
    .HSIZES0_SYS      (HSIZES0_SYS),
    .HBURSTS0_SYS     (HBURSTS0_SYS),
    .HPROTS0_SYS      (HPROTS0_SYS),
    .HWDATAS0_SYS     (HWDATAS0_SYS),
    .HMASTLOCKS0_SYS  (HMASTLOCKS0_SYS),
    .HMASTERS0_SYS    (tie_hi_4),
    .HREADYS0_SYS     (HREADYS0_SYS),
    .HAUSERS0_SYS     (HAUSERS0_SYS),
    .HWUSERS0_SYS     (HWUSERS0_SYS),
    .HRDATAS0_SYS     (HRDATAS0_SYS),
    .HREADYOUTS0_SYS  (HREADYS0_SYS),
    .HRESPS0_SYS      (i_hrespS0_SYS),
    .HRUSERS0_SYS     (HRUSERS0_SYS),


    // Output port MI0 signals
    .HSELM0_DTCM       (HSELM0_DTCM),
    .HADDRM0_DTCM      (HADDRM0_DTCM),
    .HTRANSM0_DTCM     (HTRANSM0_DTCM),
    .HWRITEM0_DTCM     (HWRITEM0_DTCM),
    .HSIZEM0_DTCM      (HSIZEM0_DTCM),
    .HBURSTM0_DTCM     (HBURSTM0_DTCM),
    .HPROTM0_DTCM      (HPROTM0_DTCM),
    .HWDATAM0_DTCM     (HWDATAM0_DTCM),
    .HMASTERM0_DTCM    (i_hmasterM0_DTCM),
    .HMASTLOCKM0_DTCM  (HMASTLOCKM0_DTCM),
    .HREADYMUXM0_DTCM  (HREADYMUXM0_DTCM),
    .HAUSERM0_DTCM     (HAUSERM0_DTCM),
    .HWUSERM0_DTCM     (HWUSERM0_DTCM),
    .HRDATAM0_DTCM     (HRDATAM0_DTCM),
    .HREADYOUTM0_DTCM  (HREADYOUTM0_DTCM),
    .HRESPM0_DTCM      (i_hrespM0_DTCM),
    .HRUSERM0_DTCM     (HRUSERM0_DTCM),

    // Output port MI1 signals
    .HSELM1_APB_BRIDGE       (HSELM1_APB_BRIDGE),
    .HADDRM1_APB_BRIDGE      (HADDRM1_APB_BRIDGE),
    .HTRANSM1_APB_BRIDGE     (HTRANSM1_APB_BRIDGE),
    .HWRITEM1_APB_BRIDGE     (HWRITEM1_APB_BRIDGE),
    .HSIZEM1_APB_BRIDGE      (HSIZEM1_APB_BRIDGE),
    .HBURSTM1_APB_BRIDGE     (HBURSTM1_APB_BRIDGE),
    .HPROTM1_APB_BRIDGE      (HPROTM1_APB_BRIDGE),
    .HWDATAM1_APB_BRIDGE     (HWDATAM1_APB_BRIDGE),
    .HMASTERM1_APB_BRIDGE    (i_hmasterM1_APB_BRIDGE),
    .HMASTLOCKM1_APB_BRIDGE  (HMASTLOCKM1_APB_BRIDGE),
    .HREADYMUXM1_APB_BRIDGE  (HREADYMUXM1_APB_BRIDGE),
    .HAUSERM1_APB_BRIDGE     (HAUSERM1_APB_BRIDGE),
    .HWUSERM1_APB_BRIDGE     (HWUSERM1_APB_BRIDGE),
    .HRDATAM1_APB_BRIDGE     (HRDATAM1_APB_BRIDGE),
    .HREADYOUTM1_APB_BRIDGE  (HREADYOUTM1_APB_BRIDGE),
    .HRESPM1_APB_BRIDGE      (i_hrespM1_APB_BRIDGE),
    .HRUSERM1_APB_BRIDGE     (HRUSERM1_APB_BRIDGE),


    // Scan test dummy signals; not connected until scan insertion
    .SCANENABLE            (SCANENABLE),
    .SCANINHCLK            (SCANINHCLK),
    .SCANOUTHCLK           (SCANOUTHCLK)
  );


endmodule
