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
//  Abstract            : BusMatrix is the top-level which connects together
//                        the required Input Stages, MatrixDecodes, Output
//                        Stages and Output Arbitration blocks.
//
//                        Supports the following configured options:
//
//                         - Architecture type 'ahb2',
//                         - 1 slave ports (connecting to masters),
//                         - 2 master ports (connecting to slaves),
//                         - Routing address width of 32 bits,
//                         - Routing data width of 32 bits,
//                         - xUSER signal width of 32 bits,
//                         - Arbiter type 'fixed',
//                         - Connectivity mapping:
//                             S<0..0> -> M<0..1>,
//                         - Connectivity type 'full'.
//
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module cmsdk_L1AhbMtx (

    // Common AHB signals
    HCLK,
    HRESETn,

    // System address remapping control
    REMAP,

    // Input port SI0 (inputs from master 0)
    HSELS0_SYS,
    HADDRS0_SYS,
    HTRANSS0_SYS,
    HWRITES0_SYS,
    HSIZES0_SYS,
    HBURSTS0_SYS,
    HPROTS0_SYS,
    HMASTERS0_SYS,
    HWDATAS0_SYS,
    HMASTLOCKS0_SYS,
    HREADYS0_SYS,
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
    HMASTERM0_DTCM,
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
    HMASTERM1_APB_BRIDGE,
    HWDATAM1_APB_BRIDGE,
    HMASTLOCKM1_APB_BRIDGE,
    HREADYMUXM1_APB_BRIDGE,
    HAUSERM1_APB_BRIDGE,
    HWUSERM1_APB_BRIDGE,

    // Input port SI0 (outputs to master 0)
    HRDATAS0_SYS,
    HREADYOUTS0_SYS,
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

    // System address remapping control
    input   [3:0] REMAP;           // REMAP input

    // Input port SI0 (inputs from master 0)
    input         HSELS0_SYS;          // Slave Select
    input  [31:0] HADDRS0_SYS;         // Address bus
    input   [1:0] HTRANSS0_SYS;        // Transfer type
    input         HWRITES0_SYS;        // Transfer direction
    input   [2:0] HSIZES0_SYS;         // Transfer size
    input   [2:0] HBURSTS0_SYS;        // Burst type
    input   [3:0] HPROTS0_SYS;         // Protection control
    input   [3:0] HMASTERS0_SYS;       // Master select
    input  [31:0] HWDATAS0_SYS;        // Write data
    input         HMASTLOCKS0_SYS;     // Locked Sequence
    input         HREADYS0_SYS;        // Transfer done
    input  [31:0] HAUSERS0_SYS;        // Address USER signals
    input  [31:0] HWUSERS0_SYS;        // Write-data USER signals

    // Output port MI0 (inputs from slave 0)
    input  [31:0] HRDATAM0_DTCM;        // Read data bus
    input         HREADYOUTM0_DTCM;     // HREADY feedback
    input   [1:0] HRESPM0_DTCM;         // Transfer response
    input  [31:0] HRUSERM0_DTCM;        // Read-data USER signals

    // Output port MI1 (inputs from slave 1)
    input  [31:0] HRDATAM1_APB_BRIDGE;        // Read data bus
    input         HREADYOUTM1_APB_BRIDGE;     // HREADY feedback
    input   [1:0] HRESPM1_APB_BRIDGE;         // Transfer response
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
    output  [3:0] HMASTERM0_DTCM;       // Master select
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
    output  [3:0] HMASTERM1_APB_BRIDGE;       // Master select
    output [31:0] HWDATAM1_APB_BRIDGE;        // Write data
    output        HMASTLOCKM1_APB_BRIDGE;     // Locked Sequence
    output        HREADYMUXM1_APB_BRIDGE;     // Transfer done
    output [31:0] HAUSERM1_APB_BRIDGE;        // Address USER signals
    output [31:0] HWUSERM1_APB_BRIDGE;        // Write-data USER signals

    // Input port SI0 (outputs to master 0)
    output [31:0] HRDATAS0_SYS;        // Read data bus
    output        HREADYOUTS0_SYS;     // HREADY feedback
    output  [1:0] HRESPS0_SYS;         // Transfer response
    output [31:0] HRUSERS0_SYS;        // Read-data USER signals

    // Scan test dummy signals; not connected until scan insertion
    output        SCANOUTHCLK;     // Scan Chain Output


// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    wire         HCLK;            // AHB System Clock
    wire         HRESETn;         // AHB System Reset

    // System address remapping control
    wire   [3:0] REMAP;           // REMAP signal

    // Input Port SI0
    wire         HSELS0_SYS;          // Slave Select
    wire  [31:0] HADDRS0_SYS;         // Address bus
    wire   [1:0] HTRANSS0_SYS;        // Transfer type
    wire         HWRITES0_SYS;        // Transfer direction
    wire   [2:0] HSIZES0_SYS;         // Transfer size
    wire   [2:0] HBURSTS0_SYS;        // Burst type
    wire   [3:0] HPROTS0_SYS;         // Protection control
    wire   [3:0] HMASTERS0_SYS;       // Master select
    wire  [31:0] HWDATAS0_SYS;        // Write data
    wire         HMASTLOCKS0_SYS;     // Locked Sequence
    wire         HREADYS0_SYS;        // Transfer done

    wire  [31:0] HRDATAS0_SYS;        // Read data bus
    wire         HREADYOUTS0_SYS;     // HREADY feedback
    wire   [1:0] HRESPS0_SYS;         // Transfer response
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
    wire   [3:0] HMASTERM0_DTCM;       // Master select
    wire  [31:0] HWDATAM0_DTCM;        // Write data
    wire         HMASTLOCKM0_DTCM;     // Locked Sequence
    wire         HREADYMUXM0_DTCM;     // Transfer done

    wire  [31:0] HRDATAM0_DTCM;        // Read data bus
    wire         HREADYOUTM0_DTCM;     // HREADY feedback
    wire   [1:0] HRESPM0_DTCM;         // Transfer response
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
    wire   [3:0] HMASTERM1_APB_BRIDGE;       // Master select
    wire  [31:0] HWDATAM1_APB_BRIDGE;        // Write data
    wire         HMASTLOCKM1_APB_BRIDGE;     // Locked Sequence
    wire         HREADYMUXM1_APB_BRIDGE;     // Transfer done

    wire  [31:0] HRDATAM1_APB_BRIDGE;        // Read data bus
    wire         HREADYOUTM1_APB_BRIDGE;     // HREADY feedback
    wire   [1:0] HRESPM1_APB_BRIDGE;         // Transfer response
    wire  [31:0] HAUSERM1_APB_BRIDGE;        // Address USER signals
    wire  [31:0] HWUSERM1_APB_BRIDGE;        // Write-data USER signals
    wire  [31:0] HRUSERM1_APB_BRIDGE;        // Read-data USER signals


// -----------------------------------------------------------------------------
// Signal declarations
// -----------------------------------------------------------------------------

    // Bus-switch input SI0
    wire         i_sel0;            // HSEL signal
    wire  [31:0] i_addr0;           // HADDR signal
    wire   [1:0] i_trans0;          // HTRANS signal
    wire         i_write0;          // HWRITE signal
    wire   [2:0] i_size0;           // HSIZE signal
    wire   [2:0] i_burst0;          // HBURST signal
    wire   [3:0] i_prot0;           // HPROTS signal
    wire   [3:0] i_master0;         // HMASTER signal
    wire         i_mastlock0;       // HMASTLOCK signal
    wire         i_active0;         // Active signal
    wire         i_held_tran0;       // HeldTran signal
    wire         i_readyout0;       // Readyout signal
    wire   [1:0] i_resp0;           // Response signal
    wire  [31:0] i_auser0;          // HAUSER signal

    // Bus-switch SI0 to MI0 signals
    wire         i_sel0to0;         // Routing selection signal
    wire         i_active0to0;      // Active signal

    // Bus-switch SI0 to MI1 signals
    wire         i_sel0to1;         // Routing selection signal
    wire         i_active0to1;      // Active signal

    wire         i_hready_mux_m0_dtcm;    // Internal HREADYMUXM for MI0
    wire         i_hready_mux_m1_apb_bridge;    // Internal HREADYMUXM for MI1


// -----------------------------------------------------------------------------
// Beginning of main code
// -----------------------------------------------------------------------------

  // Input stage for SI0
  cmsdk_MyInputName u_cmsdk_MyInputName_0 (

    // Common AHB signals
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),

    // Input Port Address/Control Signals
    .HSELS      (HSELS0_SYS),
    .HADDRS     (HADDRS0_SYS),
    .HTRANSS    (HTRANSS0_SYS),
    .HWRITES    (HWRITES0_SYS),
    .HSIZES     (HSIZES0_SYS),
    .HBURSTS    (HBURSTS0_SYS),
    .HPROTS     (HPROTS0_SYS),
    .HMASTERS   (HMASTERS0_SYS),
    .HMASTLOCKS (HMASTLOCKS0_SYS),
    .HREADYS    (HREADYS0_SYS),
    .HAUSERS    (HAUSERS0_SYS),

    // Internal Response
    .active_ip     (i_active0),
    .readyout_ip   (i_readyout0),
    .resp_ip       (i_resp0),

    // Input Port Response
    .HREADYOUTS (HREADYOUTS0_SYS),
    .HRESPS     (HRESPS0_SYS),

    // Internal Address/Control Signals
    .sel_ip        (i_sel0),
    .addr_ip       (i_addr0),
    .auser_ip      (i_auser0),
    .trans_ip      (i_trans0),
    .write_ip      (i_write0),
    .size_ip       (i_size0),
    .burst_ip      (i_burst0),
    .prot_ip       (i_prot0),
    .master_ip     (i_master0),
    .mastlock_ip   (i_mastlock0),
    .held_tran_ip   (i_held_tran0)

    );


  // Matrix decoder for SI0
  cmsdk_MyDecoderNameS0_SYS u_cmsdk_mydecodernames0_sys (

    // Common AHB signals
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),

    // Signals from Input stage SI0
    .HREADYS    (HREADYS0_SYS),
    .sel_dec        (i_sel0),
    .decode_addr_dec (i_addr0[31:10]),   // HADDR[9:0] is not decoded
    .trans_dec      (i_trans0),

    // Control/Response for Output Stage MI0
    .active_dec0    (i_active0to0),
    .readyout_dec0  (i_hready_mux_m0_dtcm),
    .resp_dec0      (HRESPM0_DTCM),
    .rdata_dec0     (HRDATAM0_DTCM),
    .ruser_dec0     (HRUSERM0_DTCM),

    // Control/Response for Output Stage MI1
    .active_dec1    (i_active0to1),
    .readyout_dec1  (i_hready_mux_m1_apb_bridge),
    .resp_dec1      (HRESPM1_APB_BRIDGE),
    .rdata_dec1     (HRDATAM1_APB_BRIDGE),
    .ruser_dec1     (HRUSERM1_APB_BRIDGE),

    .sel_dec0       (i_sel0to0),
    .sel_dec1       (i_sel0to1),

    .active_dec     (i_active0),
    .HREADYOUTS (i_readyout0),
    .HRESPS     (i_resp0),
    .HRUSERS    (HRUSERS0_SYS),
    .HRDATAS    (HRDATAS0_SYS)

    );


  // Output stage for MI0
  cmsdk_MyOutputName u_cmsdk_myoutputname_0 (

    // Common AHB signals
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),

    // Port 0 Signals
    .sel_op0       (i_sel0to0),
    .addr_op0      (i_addr0),
    .auser_op0     (i_auser0),
    .trans_op0     (i_trans0),
    .write_op0     (i_write0),
    .size_op0      (i_size0),
    .burst_op0     (i_burst0),
    .prot_op0      (i_prot0),
    .master_op0    (i_master0),
    .mastlock_op0  (i_mastlock0),
    .wdata_op0     (HWDATAS0_SYS),
    .wuser_op0     (HWUSERS0_SYS),
    .held_tran_op0  (i_held_tran0),

    // Slave read data and response
    .HREADYOUTM (HREADYOUTM0_DTCM),

    .active_op0    (i_active0to0),

    // Slave Address/Control Signals
    .HSELM      (HSELM0_DTCM),
    .HADDRM     (HADDRM0_DTCM),
    .HAUSERM    (HAUSERM0_DTCM),
    .HTRANSM    (HTRANSM0_DTCM),
    .HWRITEM    (HWRITEM0_DTCM),
    .HSIZEM     (HSIZEM0_DTCM),
    .HBURSTM    (HBURSTM0_DTCM),
    .HPROTM     (HPROTM0_DTCM),
    .HMASTERM   (HMASTERM0_DTCM),
    .HMASTLOCKM (HMASTLOCKM0_DTCM),
    .HREADYMUXM (i_hready_mux_m0_dtcm),
    .HWUSERM    (HWUSERM0_DTCM),
    .HWDATAM    (HWDATAM0_DTCM)

    );

  // Drive output with internal version
  assign HREADYMUXM0_DTCM = i_hready_mux_m0_dtcm;


  // Output stage for MI1
  cmsdk_MyOutputName u_cmsdk_myoutputname_1 (

    // Common AHB signals
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),

    // Port 0 Signals
    .sel_op0       (i_sel0to1),
    .addr_op0      (i_addr0),
    .auser_op0     (i_auser0),
    .trans_op0     (i_trans0),
    .write_op0     (i_write0),
    .size_op0      (i_size0),
    .burst_op0     (i_burst0),
    .prot_op0      (i_prot0),
    .master_op0    (i_master0),
    .mastlock_op0  (i_mastlock0),
    .wdata_op0     (HWDATAS0_SYS),
    .wuser_op0     (HWUSERS0_SYS),
    .held_tran_op0  (i_held_tran0),

    // Slave read data and response
    .HREADYOUTM (HREADYOUTM1_APB_BRIDGE),

    .active_op0    (i_active0to1),

    // Slave Address/Control Signals
    .HSELM      (HSELM1_APB_BRIDGE),
    .HADDRM     (HADDRM1_APB_BRIDGE),
    .HAUSERM    (HAUSERM1_APB_BRIDGE),
    .HTRANSM    (HTRANSM1_APB_BRIDGE),
    .HWRITEM    (HWRITEM1_APB_BRIDGE),
    .HSIZEM     (HSIZEM1_APB_BRIDGE),
    .HBURSTM    (HBURSTM1_APB_BRIDGE),
    .HPROTM     (HPROTM1_APB_BRIDGE),
    .HMASTERM   (HMASTERM1_APB_BRIDGE),
    .HMASTLOCKM (HMASTLOCKM1_APB_BRIDGE),
    .HREADYMUXM (i_hready_mux_m1_apb_bridge),
    .HWUSERM    (HWUSERM1_APB_BRIDGE),
    .HWDATAM    (HWDATAM1_APB_BRIDGE)

    );

  // Drive output with internal version
  assign HREADYMUXM1_APB_BRIDGE = i_hready_mux_m1_apb_bridge;


endmodule

// --================================= End ===================================--
