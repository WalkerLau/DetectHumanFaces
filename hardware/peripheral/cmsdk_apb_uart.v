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
//      Checked In          : $Date: 2013-01-09 12:55:25 +0000 (Wed, 09 Jan 2013) $
//
//      Revision            : $Revision: 233070 $
//
//      Release Information : Cortex-M System Design Kit-r1p0-00rel0
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Abstract : Simple APB UART
//-----------------------------------------------------------------------------
//-------------------------------------
// Programmer's model
// 0x00 R     RXD[7:0]    Received Data
//      W     TXD[7:0]    Transmit data
// 0x04 RW    STAT[3:0]
//              [3] RX buffer overrun (write 1 to clear)
//              [2] TX buffer overrun (write 1 to clear)
//              [1] RX buffer full (Read only)
//              [0] TX buffer full (Read only)
// 0x08 RW    CTRL[3:0]   TxIntEn, RxIntEn, TxEn, RxEn
//              [6] High speed test mode Enable
//              [5] RX overrun interrupt enable
//              [4] TX overrun interrupt enable
//              [3] RX Interrupt Enable
//              [2] TX Interrupt Enable
//              [1] RX Enable
//              [0] TX Enable
// 0x0C R/Wc  intr_status/INTCLEAR
//              [3] RX overrun interrupt
//              [2] TX overrun interrupt
//              [1] RX interrupt
//              [0] TX interrupt
// 0x10 RW    BAUDDIV[19:0] Baud divider
//            (minimum value is 16)
// 0x3E0 - 0x3FC  ID registers
//-------------------------------------

module cmsdk_apb_uart (
// --------------------------------------------------------------------------
// Port Definitions
// --------------------------------------------------------------------------
  input  wire        PCLK,     // Clock
  input  wire        PCLKG,    // Gated Clock
  input  wire        PRESETn,  // Reset

  input  wire        PSEL,     // Device select
  input  wire [11:2] PADDR,    // Address
  input  wire        PENABLE,  // Transfer control
  input  wire        PWRITE,   // Write control
  input  wire [31:0] PWDATA,   // Write data

  input  wire [3:0]  ECOREVNUM,// Engineering-change-order revision bits

  output wire [31:0] PRDATA,   // Read data
  output wire        PREADY,   // Device ready
  output wire        PSLVERR,  // Device error response

  input  wire        RXD,      // Serial input
  output wire        TXD,      // Transmit data output
  output wire        TXEN,     // Transmit enabled
  output wire        BAUDTICK, // Baud rate (x16) Tick

  output wire        TXINT,    // Transmit Interrupt
  output wire        RXINT,    // Receive Interrupt
  output wire        TXOVRINT, // Transmit overrun Interrupt
  output wire        RXOVRINT, // Receive overrun Interrupt
  output wire        UARTINT); // Combined interrupt

// Local ID parameters, APB UART part number is 0x821
localparam  ARM_CMSDK_APB_UART_PID4 = 8'h04;
localparam  ARM_CMSDK_APB_UART_PID5 = 8'h00;
localparam  ARM_CMSDK_APB_UART_PID6 = 8'h00;
localparam  ARM_CMSDK_APB_UART_PID7 = 8'h00;
localparam  ARM_CMSDK_APB_UART_PID0 = 8'h21;
localparam  ARM_CMSDK_APB_UART_PID1 = 8'hB8;
localparam  ARM_CMSDK_APB_UART_PID2 = 8'h1B;
localparam  ARM_CMSDK_APB_UART_PID3 = 4'h0;
localparam  ARM_CMSDK_APB_UART_CID0 = 8'h0D;
localparam  ARM_CMSDK_APB_UART_CID1 = 8'hF0;
localparam  ARM_CMSDK_APB_UART_CID2 = 8'h05;
localparam  ARM_CMSDK_APB_UART_CID3 = 8'hB1;

  // --------------------------------------------------------------------------
  // Internal wires
  // --------------------------------------------------------------------------
// Signals for read/write controls
wire          read_enable;
wire          write_enable;
wire          write_enable00; // Write enable for data register
wire          write_enable04; // Write enable for Status register
wire          write_enable08; // Write enable for control register
wire          write_enable0c; // Write enable for interrupt status register
wire          write_enable10; // Write enable for Baud rate divider
reg     [7:0] read_mux_byte0; // Read data multiplexer for lower 8-bit
reg     [7:0] read_mux_byte0_reg; // Register read data for lower 8-bit
wire   [31:0] read_mux_word;  // Read data multiplexer for whole 32-bit
wire    [3:0] pid3_value;     // constant value for lower 4-bit in perpherial ID3

// Signals for Control registers
reg     [6:0] reg_ctrl;       // Control register
reg     [7:0] reg_tx_buf;     // Transmit data buffer
reg     [7:0] reg_rx_buf;     // Receive data buffer
reg    [19:0] reg_baud_div;   // Baud rate setting

// Internal signals
  // Baud rate divider
reg    [15:0] reg_baud_cntr_i; // baud rate divider counter i (integer)
wire   [15:0] nxt_baud_cntr_i;
reg     [3:0] reg_baud_cntr_f; // baud rate divider counter f (fraction)
wire    [3:0] nxt_baud_cntr_f;
wire    [3:0] mapped_cntr_f;   // remapped counter f value
reg           reg_baud_tick;   // Register baud rate tick (16 times of baud rate)
reg           baud_updated;    // baud rate value has bee updated from APB
wire          reload_i;        // baud rate divider counter i reload
wire          reload_f;        // baud rate divider counter f reload
wire          baud_div_en;     // enable baud rate counter

  // Status
wire    [3:0] uart_status;     // UART status
reg           reg_rx_overrun;  // Receive overrun status register
wire          rx_overrun;      // Receive overrun detection
reg           reg_tx_overrun;  // Transmit overrun status register
wire          tx_overrun;      // Transmit overrun detection
wire          nxt_rx_overrun;  // next state for reg_rx_overrun
wire          nxt_tx_overrun;  // next state for reg_tx_overrun
  // Interrupts
reg           reg_txintr;      // Transmit interrupt register
reg           reg_rxintr;      // Receive interrupt register
wire          tx_overflow_intr;// Transmit overrun/overflow interrupt
wire          rx_overflow_intr;// Receive overrun/overflow interrupt
wire    [3:0] intr_state;      // UART interrupt status
wire    [1:0] intr_stat_set;   // Set TX/RX interrupt
wire    [1:0] intr_stat_clear; // Clear TX/RX interrupt

  // transmit
reg     [3:0] tx_state;    // Transmit FSM state
reg     [4:0] nxt_tx_state;
wire          tx_state_update;
wire          tx_state_inc; // Bit pulse
reg     [3:0] tx_tick_cnt;  // Transmit Tick counter
wire    [4:0] nxt_tx_tick_cnt;
reg     [7:0] tx_shift_buf;      // Transmit shift register
wire    [7:0] nxt_tx_shift_buf;  // next state    for tx_shift_buf
wire          tx_buf_ctrl_shift; // shift control for tx_shift_buf
wire          tx_buf_ctrl_load;  // load  control for tx_shift_buf
reg           tx_buf_full;  // TX Buffer full
reg           reg_txd;      // Tx Data
wire          nxt_txd;      // next state of reg_txd
wire          update_reg_txd; // update reg_txd
wire          tx_buf_clear; // Clear buffer full status when data is load into TX shift register

  // Receive data sync and filter
reg           rxd_sync_1;  // Double flip-flop syncrhoniser
reg           rxd_sync_2;  // Double flip-flop syncrhoniser
reg     [2:0] rxd_lpf;     // Averaging Low Pass Filter
wire    [2:0] nxt_rxd_lpf;
wire          rx_shift_in; // Shift Register Input

  // Receiver
reg     [3:0] rx_state;   // Receiver FSM state
reg     [4:0] nxt_rx_state;
wire          rx_state_update;
reg     [3:0] rx_tick_cnt; // Receiver Tick counter
wire    [4:0] nxt_rx_tick_cnt;
wire          update_rx_tick_cnt;
wire          rx_state_inc;// Bit pulse
reg     [6:0] rx_shift_buf;// Receiver shift data register
wire    [6:0] nxt_rx_shift_buf;
reg           rx_buf_full;  // Receive buffer full status
wire          nxt_rx_buf_full;
wire          rxbuf_sample; // Sample received data into receive data buffer
wire          rx_data_read; // Receive data buffer read by APB interface
wire    [7:0] nxt_rx_buf;

// Start of main code
// Read and write control signals
assign  read_enable  = PSEL & (~PWRITE); // assert for whole APB read transfer
assign  write_enable = PSEL & (~PENABLE) & PWRITE; // assert for 1st cycle of write transfer
assign  write_enable00 = write_enable & (PADDR[11:2] == 10'h000);
assign  write_enable04 = write_enable & (PADDR[11:2] == 10'h001);
assign  write_enable08 = write_enable & (PADDR[11:2] == 10'h002);
assign  write_enable0c = write_enable & (PADDR[11:2] == 10'h003);
assign  write_enable10 = write_enable & (PADDR[11:2] == 10'h004);

// Write operations
  // Transmit data register
  always @(posedge PCLKG or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_tx_buf <= {8{1'b0}};
    else if (write_enable00)
      reg_tx_buf <= PWDATA[7:0];
  end

  // Status register overrun registers
  assign nxt_rx_overrun = (reg_rx_overrun & (~((write_enable04|write_enable0c) & PWDATA[3]))) | rx_overrun;
  assign nxt_tx_overrun = (reg_tx_overrun & (~((write_enable04|write_enable0c) & PWDATA[2]))) | tx_overrun;

  // RX OverRun status
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_rx_overrun <= 1'b0;
    else if (rx_overrun | write_enable04 | write_enable0c)
      reg_rx_overrun <= nxt_rx_overrun;
  end

  // TX OverRun status
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_tx_overrun <= 1'b0;
    else if (tx_overrun | write_enable04 | write_enable0c)
      reg_tx_overrun <= nxt_tx_overrun;
  end

  // Control register
  always @(posedge PCLKG or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_ctrl <= {7{1'b0}};
    else if (write_enable08)
      reg_ctrl <= PWDATA[6:0];
  end

  // Baud rate divider - integer
  always @(posedge PCLKG or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_baud_div <= {20{1'b0}};
    else if (write_enable10)
      reg_baud_div <= PWDATA[19:0];
  end

// Read operation
  assign uart_status = {reg_rx_overrun, reg_tx_overrun, rx_buf_full, tx_buf_full};

  assign pid3_value  = ARM_CMSDK_APB_UART_PID3;

  // First level of read mux
 always @(PADDR or reg_rx_buf or uart_status or reg_ctrl or intr_state or reg_baud_div
   or ECOREVNUM or pid3_value)
  begin
   if (PADDR[11:5] == 7'h00) begin
     case (PADDR[4:2])
     3'h0: read_mux_byte0 =  reg_rx_buf;
     3'h1: read_mux_byte0 =  {{4{1'b0}},uart_status};
     3'h2: read_mux_byte0 =  {{1{1'b0}},reg_ctrl};
     3'h3: read_mux_byte0 =  {{4{1'b0}},intr_state};
     3'h4: read_mux_byte0 =  reg_baud_div[7:0];
     3'h5, 3'h6, 3'h7: read_mux_byte0 =   {8{1'b0}};     //default read out value
     default:  read_mux_byte0 =   {8{1'bx}};// x propogation
     endcase
   end
   else if (PADDR[11:6] == 6'h3F) begin
     case  (PADDR[5:2])
       4'h0, 4'h1,4'h2,4'h3: read_mux_byte0 =   {8{1'b0}}; //default read out value
   // ID register - constant values
       4'h4: read_mux_byte0 = ARM_CMSDK_APB_UART_PID4; // 0xFD0 : PID 4
       4'h5: read_mux_byte0 = ARM_CMSDK_APB_UART_PID5; // 0xFD4 : PID 5
       4'h6: read_mux_byte0 = ARM_CMSDK_APB_UART_PID6; // 0xFD8 : PID 6
       4'h7: read_mux_byte0 = ARM_CMSDK_APB_UART_PID7; // 0xFDC : PID 7
       4'h8: read_mux_byte0 = ARM_CMSDK_APB_UART_PID0; // 0xFE0 : PID 0  APB UART part number[7:0]
       4'h9: read_mux_byte0 = ARM_CMSDK_APB_UART_PID1; // 0xFE0 : PID 1 [7:4] jep106_id_3_0. [3:0] part number [11:8]
       4'hA: read_mux_byte0 = ARM_CMSDK_APB_UART_PID2; // 0xFE0 : PID 2 [7:4] revision, [3] jedec_used. [2:0] jep106_id_6_4
       4'hB: read_mux_byte0 = {ECOREVNUM[3:0],pid3_value[3:0]};
                                                       // 0xFE0 : PID 3 [7:4] ECO revision, [3:0] modification number
       4'hC: read_mux_byte0 = ARM_CMSDK_APB_UART_CID0; // 0xFF0 : CID 0
       4'hD: read_mux_byte0 = ARM_CMSDK_APB_UART_CID1; // 0xFF4 : CID 1 PrimeCell class
       4'hE: read_mux_byte0 = ARM_CMSDK_APB_UART_CID2; // 0xFF8 : CID 2
       4'hF: read_mux_byte0 = ARM_CMSDK_APB_UART_CID3; // 0xFFC : CID 3
       default : read_mux_byte0 = {8{1'bx}}; // x propogation
      endcase
    end
    else begin
       read_mux_byte0 =   {8{1'b0}};     //default read out value
    end
  end



  // Register read data
  always @(posedge PCLKG or negedge PRESETn)
  begin
    if (~PRESETn)
      read_mux_byte0_reg      <= {8{1'b0}};
    else if (read_enable)
      read_mux_byte0_reg      <= read_mux_byte0;
  end

  // Second level of read mux
  assign read_mux_word[ 7: 0] = read_mux_byte0_reg;
  assign read_mux_word[19: 8] = (PADDR[11:2]==10'h004) ? reg_baud_div[19:8] : {12{1'b0}};
  assign read_mux_word[31:20] = {12{1'b0}};


  // Output read data to APB
  assign PRDATA[31: 0] = (read_enable) ? read_mux_word : {32{1'b0}};
  assign PREADY  = 1'b1; // Always ready
  assign PSLVERR = 1'b0; // Always okay

// --------------------------------------------
// Baud rate generator
  // Baud rate generator enable
  assign baud_div_en    = (reg_ctrl[1:0] != 2'b00);
  assign mapped_cntr_f  = {reg_baud_cntr_f[0],reg_baud_cntr_f[1],
                           reg_baud_cntr_f[2],reg_baud_cntr_f[3]};
  // Reload Integer divider
  // when UART enabled and (reg_baud_cntr_f < reg_baud_div[3:0])
  // then count to 1, or
  // when UART enabled then count to 0
  assign reload_i      = (baud_div_en &
         (((mapped_cntr_f >= reg_baud_div[3:0]) &
         (reg_baud_cntr_i[15:1] == {15{1'b0}})) |
         (reg_baud_cntr_i[15:0] == {16{1'b0}})));

  // Next state for Baud rate divider
  assign nxt_baud_cntr_i = (baud_updated | reload_i) ? reg_baud_div[19:4] :
                           (reg_baud_cntr_i - 16'h0001);
  // Update at reload or decrement
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_baud_cntr_i   <= {16{1'b0}};
    else if (baud_updated | baud_div_en)
      reg_baud_cntr_i   <= nxt_baud_cntr_i;
  end

  // Reload fraction divider
  assign reload_f      = baud_div_en & (reg_baud_cntr_f==4'h0) &
                        reload_i;
  // Next state for fraction part of Baud rate divider
  assign nxt_baud_cntr_f =
                        (reload_f|baud_updated) ? 4'hF :
                        (reg_baud_cntr_f - 4'h1);

  // Update at reload or decrement
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_baud_cntr_f   <= {4{1'b0}};
    else if (baud_updated | reload_f | reload_i)
      reg_baud_cntr_f   <= nxt_baud_cntr_f;
  end

  // Generate control signal to update baud rate counters
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      baud_updated    <= 1'b0;
    else if (write_enable10 | baud_updated)
      // Baud rate updated - to load new value to counters
      baud_updated    <= write_enable10;
  end

  // Generate Tick signal for external logic
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_baud_tick    <= 1'b0;
    else if (reload_i | reg_baud_tick)
      reg_baud_tick    <= reload_i;
  end

  // Connect to external
  assign BAUDTICK = reg_baud_tick;

// --------------------------------------------
// Transmit

  // Buffer full status
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      tx_buf_full     <= 1'b0;
    else if (write_enable00 | tx_buf_clear)
      tx_buf_full     <= write_enable00;
  end

  // Increment TickCounter
  assign nxt_tx_tick_cnt = ((tx_state==4'h1) & reg_baud_tick) ? {5{1'b0}} :
                        tx_tick_cnt + {{3{1'b0}},reg_baud_tick};

  // Registering TickCounter
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      tx_tick_cnt     <= {4{1'b0}};
    else if (reg_baud_tick)
      tx_tick_cnt     <= nxt_tx_tick_cnt[3:0];
  end

  // Increment state (except Idle(0) and Wait for Tick(1))
  assign tx_state_inc   = (((&tx_tick_cnt)|(tx_state==4'h1)) & reg_baud_tick)|reg_ctrl[6];
          // state increment every cycle of high speed test mode is enabled
  // Clear buffer full status when data is load into shift register
  assign tx_buf_clear   = ((tx_state==4'h0) & tx_buf_full) |
                        ((tx_state==4'hB) & tx_buf_full & tx_state_inc);

  // tx_state machine
  // 0 = Idle, 1 =  Wait for Tick,
  // 2 = Start bit, 3 = D0 .... 10 = D7
  // 11 = Stop bit
  always @(tx_state or tx_buf_full or tx_state_inc or reg_ctrl)
  begin
  case (tx_state)
    0: begin
       nxt_tx_state = (tx_buf_full & reg_ctrl[0]) ? 5'h01 : 5'h00;  // New data is written to buffer
       end
    1,                         // State 1   : Wait for next Tick
    2,3,4,5,6,7,8,9,10: begin  // State 2-10: Start bit, D0 - D7
       nxt_tx_state = tx_state + {3'b000,tx_state_inc};
       end
    11: begin // Stop bit , goto next start bit or Idle
       nxt_tx_state = (tx_state_inc) ? ( tx_buf_full ? 5'h02:5'h00) : {1'b0, tx_state};
       end
    default:
       nxt_tx_state = {5{1'bx}};
  endcase
  end

  assign tx_state_update = tx_state_inc | ((tx_state==4'h0) & tx_buf_full & reg_ctrl[0]) | (tx_state>4'd11);

  // Registering outputs
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      tx_state        <= {4{1'b0}};
    else if (tx_state_update)
      tx_state        <= nxt_tx_state[3:0];
  end

  // Load/shift TX register
  assign tx_buf_ctrl_load  = (((tx_state==4'h0) & tx_buf_full) |
                              ((tx_state==4'hB) & tx_buf_full & tx_state_inc));
  assign tx_buf_ctrl_shift =  ((tx_state>4'h2) & tx_state_inc);

  assign nxt_tx_shift_buf = tx_buf_ctrl_load ? reg_tx_buf : {1'b1,tx_shift_buf[7:1]};

  // Registering TX shift register
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      tx_shift_buf    <= {8{1'b0}};
    else if (tx_buf_ctrl_shift | tx_buf_ctrl_load)
      tx_shift_buf    <= nxt_tx_shift_buf;
  end

  // Data output
  assign nxt_txd = (tx_state==4'h2) ? 1'b0 :
                   (tx_state>4'h2) ? tx_shift_buf[0] : 1'b1;

  assign update_reg_txd = (nxt_txd != reg_txd);

  // Registering outputs
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_txd         <= 1'b1;
    else if (update_reg_txd)
      reg_txd         <= nxt_txd;
  end

  // Generate TX overrun error status
  assign tx_overrun = tx_buf_full & (~tx_buf_clear) & write_enable00;

  // Connect to external
  assign TXD  = reg_txd;
  assign TXEN = reg_ctrl[0];

// --------------------------------------------
// Receive synchronizer and low pass filter

  // Doubling Flip-flop synxt_rx_tick_cntnchroniser
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      begin
      rxd_sync_1 <= 1'b1;
      rxd_sync_2 <= 1'b1;
      end
    else if (reg_ctrl[1]) // Turn off synchronizer if receive is not enabled
      begin
      rxd_sync_1 <= RXD;
      rxd_sync_2 <= rxd_sync_1;
      end
  end

  // Averaging low pass filter
  assign nxt_rxd_lpf = {rxd_lpf[1:0], rxd_sync_2};
  // Registering stage for low pass filter
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      rxd_lpf <= 3'b111;
    else if (reg_baud_tick)
      rxd_lpf <= nxt_rxd_lpf;
  end

  // Averaging values
  assign rx_shift_in = (rxd_lpf[1] & rxd_lpf[0]) |
                       (rxd_lpf[1] & rxd_lpf[2]) |
                       (rxd_lpf[0] & rxd_lpf[2]);

// --------------------------------------------
// Receive

  // Increment TickCounter
  assign nxt_rx_tick_cnt = ((rx_state==4'h0) & (~rx_shift_in)) ? 5'h08 :
                        rx_tick_cnt + {{3{1'b0}},reg_baud_tick};

  assign update_rx_tick_cnt = ((rx_state==4'h0) & (~rx_shift_in)) | reg_baud_tick;

  // Registering other register
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      rx_tick_cnt    <= {4{1'b0}};
    else if (update_rx_tick_cnt)
      rx_tick_cnt    <= nxt_rx_tick_cnt[3:0];
  end

  // Increment state
  assign rx_state_inc   = ((&rx_tick_cnt) & reg_baud_tick);
  // Buffer full status
  assign nxt_rx_buf_full = rxbuf_sample | (rx_buf_full & (~rx_data_read));

  // Sample shift register when D7 is sampled
  assign rxbuf_sample  = ((rx_state==4'h9) & rx_state_inc);

  // Reading receive buffer (Set at 1st cycle of APB transfer
  // because read mux is registered before output)
  assign rx_data_read   = (PSEL & (~PENABLE) & (PADDR[11:2]==10'h000) & (~PWRITE));
  // Generate RX overrun error status
  assign rx_overrun = rx_buf_full & rxbuf_sample & (~rx_data_read);

  // rx_state machine
  // 0 = Idle, 1 =  Start of Start bit detected
  // 2 = Sample Start bit, 3 = D0 .... 10 = D7
  // 11 = Stop bit
  // 11, 12, 13, 14, 15: illegal/unused states
  always @(rx_state or rx_shift_in or rx_state_inc or reg_ctrl)
  begin
  case (rx_state)
    0: begin
       nxt_rx_state = ((~rx_shift_in) & reg_ctrl[1]) ? 5'h01 : 5'h00;  // Wait for Start bit
       end
    1,                      // State 1  : Wait for middle of start bit
    2,3,4,5,6,7,8,9: begin  // State 2-9: D0 - D7
       nxt_rx_state = rx_state + {3'b000,rx_state_inc};
       end
    10: begin // Stop bit , goto back to Idle
       nxt_rx_state = (rx_state_inc) ? 5'h00 : 5'h0A;
       end
    default:
       nxt_rx_state = {5{1'bx}};
  endcase
  end

  assign rx_state_update = rx_state_inc |  ((~rx_shift_in) & reg_ctrl[1]);

  // Registering rx_state
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      rx_state       <= {4{1'b0}};
    else if (rx_state_update)
      rx_state       <= nxt_rx_state[3:0];
  end

  // Buffer full status
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      rx_buf_full     <= 1'b0;
    else if (rxbuf_sample | rx_data_read)
      rx_buf_full     <= nxt_rx_buf_full;
  end

  // Sample receive buffer
  assign nxt_rx_buf     = {rx_shift_in, rx_shift_buf};
  // Registering receive data buffer
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_rx_buf      <= {8{1'b0}};
    else if  (rxbuf_sample)
      reg_rx_buf      <= nxt_rx_buf;
  end

  // Shift register
  assign nxt_rx_shift_buf= {rx_shift_in, rx_shift_buf[6:1]};
  // Registering shift buffer
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      rx_shift_buf    <= {7{1'b0}};
    else if (rx_state_inc)
      rx_shift_buf    <= nxt_rx_shift_buf;
  end



// --------------------------------------------
// Interrupts
  // Set by event
  assign intr_stat_set[1] = reg_ctrl[3] & rxbuf_sample; // A new receive data is sampled
  assign intr_stat_set[0] = reg_ctrl[2] & reg_ctrl[0] & tx_buf_full & tx_buf_clear;
                            // Falling edge of buffer full
  // Clear by write to IntClear register
  assign intr_stat_clear[1:0] = {2{write_enable0c}} & PWDATA[1:0];

  // Registering outputs
  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_txintr    <= 1'b0;
    else if (intr_stat_set[0] | intr_stat_clear[0])
      reg_txintr    <= intr_stat_set[0];
  end

  always @(posedge PCLK or negedge PRESETn)
  begin
    if (~PRESETn)
      reg_rxintr    <= 1'b0;
    else if (intr_stat_set[1] | intr_stat_clear[1])
      reg_rxintr    <= intr_stat_set[1];
  end

  assign rx_overflow_intr = reg_rx_overrun & reg_ctrl[5];
  assign tx_overflow_intr = reg_tx_overrun & reg_ctrl[4];

  // Interrupt status for read back
  assign intr_state = {rx_overflow_intr, tx_overflow_intr, reg_rxintr, reg_txintr};

  // Connect to external
  assign TXINT    = reg_txintr;
  assign RXINT    = reg_rxintr;
  assign TXOVRINT = tx_overflow_intr;
  assign RXOVRINT = rx_overflow_intr;
  assign UARTINT  = reg_txintr | reg_rxintr | tx_overflow_intr | rx_overflow_intr;


`ifdef ARM_APB_ASSERT_ON
   // ------------------------------------------------------------
   // Assertions
   // ------------------------------------------------------------
`include "std_ovl_defines.h"

   // Prepare signals for OVL checking
   reg [15:0] ovl_last_reg_baud_cntr_i;
   reg  [3:0] ovl_last_reg_baud_cntr_f;
   reg        ovl_last_baud_div_en;
   reg        ovl_last_baud_updated;
   always @(posedge PCLK or negedge PRESETn)
   begin
     if (~PRESETn)
       begin
       ovl_last_reg_baud_cntr_i <= {16{1'b0}};
       ovl_last_reg_baud_cntr_f <= {4{1'b0}};
       ovl_last_baud_div_en     <= 1'b0;
       ovl_last_baud_updated    <= 1'b0;
       end
     else
       begin
       ovl_last_reg_baud_cntr_i <= reg_baud_cntr_i;
       ovl_last_reg_baud_cntr_f <= reg_baud_cntr_f;
       ovl_last_baud_div_en     <= baud_div_en;
       ovl_last_baud_updated    <= baud_updated;
       end
   end

   reg        ovl_reg_hs_test_mode_triggered; // Indicate if HighSpeed testmode has been activated
   wire       ovl_nxt_hs_test_mode_triggered;
   reg  [7:0] ovl_reg_tx_tick_count;  // For measuring width of TX state
   wire [7:0] ovl_nxt_tx_tick_count;
   reg  [7:0] ovl_reg_rx_tick_count;  // For measuring width of RX state
   wire [7:0] ovl_nxt_rx_tick_count;
   reg  [3:0] ovl_reg_last_tx_state;  // last state
   reg  [3:0] ovl_reg_last_rx_state;
   reg  [6:0] ovl_last_reg_ctrl;

   // Clear test mode indicator each time state is changed, set to 1 if high speed test mode is
   // enabled
   assign ovl_nxt_hs_test_mode_triggered =
     (tx_state!=ovl_reg_last_tx_state) ? reg_ctrl[6]: (reg_ctrl[6] | ovl_reg_hs_test_mode_triggered);

   // Counter clear at each state change, increasement at each reg_baud_tick
   assign ovl_nxt_tx_tick_count = (tx_state!=ovl_reg_last_tx_state) ? (8'h00) :
     (ovl_reg_tx_tick_count + {{7{1'b0}}, reg_baud_tick});

   // Counter clear at each state change, increasement at each reg_baud_tick
   assign ovl_nxt_rx_tick_count = (rx_state!=ovl_reg_last_rx_state) ? (8'h00) :
     (ovl_reg_rx_tick_count + {{7{1'b0}}, reg_baud_tick});

   always@(posedge PCLK or negedge PRESETn)
     begin
     if (~PRESETn)
       begin
       ovl_reg_hs_test_mode_triggered <= 1'b0;
       ovl_reg_last_tx_state          <= 4'h0;
       ovl_reg_last_rx_state          <= 4'h0;
       ovl_reg_tx_tick_count          <= 8'h00;
       ovl_reg_rx_tick_count          <= 8'h00;
       ovl_last_reg_ctrl              <= 7'h00;
       end
     else
       begin
       ovl_reg_hs_test_mode_triggered <= ovl_nxt_hs_test_mode_triggered;
       ovl_reg_last_tx_state          <= tx_state;
       ovl_reg_last_rx_state          <= rx_state;
       ovl_reg_tx_tick_count          <= ovl_nxt_tx_tick_count;
       ovl_reg_rx_tick_count          <= ovl_nxt_rx_tick_count;
       ovl_last_reg_ctrl              <= reg_ctrl;
       end
     end

   // Signals for checking clearing of interrupts
   reg          ovl_last_txint;
   reg          ovl_last_rxint;
   reg          ovl_last_psel;
   reg          ovl_last_penable;
   reg          ovl_last_pwrite;
   reg  [31:0]  ovl_last_pwdata;
   reg  [11:2]  ovl_last_paddr;
   reg          ovl_last_rx_buf_full;
   reg          ovl_last_tx_shift_buf_0;


   always@(posedge PCLK or negedge PRESETn)
     begin
     if (~PRESETn)
       begin
       ovl_last_txint   <= 1'b0;
       ovl_last_rxint   <= 1'b0;
       ovl_last_psel    <= 1'b0;
       ovl_last_penable <= 1'b0;
       ovl_last_pwrite  <= 1'b0;
       ovl_last_paddr   <= {10{1'b0}};
       ovl_last_pwdata  <= {32{1'b0}};
       ovl_last_rx_buf_full  <= 1'b0;
       ovl_last_tx_shift_buf_0 <= 1'b0;
       end
     else
       begin
       ovl_last_txint   <= TXINT;
       ovl_last_rxint   <= RXINT;
       ovl_last_psel    <= PSEL;
       ovl_last_penable <= PENABLE;
       ovl_last_pwrite  <= PWRITE;
       ovl_last_paddr   <= PADDR;
       ovl_last_pwdata  <= PWDATA;
       ovl_last_rx_buf_full  <= rx_buf_full;
       ovl_last_tx_shift_buf_0 <= tx_shift_buf[0];
       end
     end

   // Ensure rx_state must not be 11, 12, 13, 14, 15
   assert_never
     #(`OVL_ERROR,`OVL_ASSERT,
       "rx_state in illegal state")
   u_ovl_rx_state_illegal
     (.clk(PCLK), .reset_n(PRESETn),
      .test_expr((rx_state==4'hB)|(rx_state==4'hC)|(rx_state==4'hD)|
      (rx_state==4'hE)|(rx_state==4'hF)));

   // Ensure tx_state must not be 12, 13, 14, 15
   assert_never
     #(`OVL_ERROR,`OVL_ASSERT,
       "tx_state in illegal state")
   u_ovl_tx_state_illegal
     (.clk(PCLK), .reset_n(PRESETn),
      .test_expr((tx_state==4'hC)|(tx_state==4'hD)|
      (tx_state==4'hE)|(tx_state==4'hF)));

   // Ensure reg_baud_cntr_i change only if UART is enabled
   // or if write to baud rate divider
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
       "Unexpected baud rate divider change")
   u_ovl_reg_baud_cntr_i_change
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr(ovl_last_reg_baud_cntr_i!=reg_baud_cntr_i),
      .consequent_expr(ovl_last_baud_div_en | ovl_last_baud_updated )
      );

   // Ensure reg_baud_div[19:4] >= reg_baud_cntr_i unless reg_baud_div just been programmed
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
       "Unexpected baud rate divided change")
   u_ovl_reg_baud_cntr_i_range
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr(reg_baud_cntr_i>reg_baud_div[19:4]),
      .consequent_expr(baud_updated)
      );

   // Ensure reg_baud_cntr_f change only if UART is enabled
   // or if write to baud rate divider
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
       "Unexpected baud rate divider change")
   u_ovl_reg_baud_cntr_f_change
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr(ovl_last_reg_baud_cntr_f!=reg_baud_cntr_f),
      .consequent_expr(ovl_last_baud_div_en | ovl_last_baud_updated )
      );

   // Ensure tx_buf_full is set to 1 after write to TX buffer (PADDR[11:2]==0)
   assert_next
     #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
      "tx_buf_full should be asserted after write to TX buffer")
   u_ovl_tx_buf_full
    (.clk(PCLK),  .reset_n(PRESETn),
     .start_event (PSEL & (~PENABLE) & PWRITE & (PADDR[11:2] == 10'h000)),
     .test_expr   (tx_buf_full)
     );

   // If last tx_state=0 (idle) or 1 (wait for tick), TXD = 1.
   assert_next
     #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
      "TXD should be 1 when idle or just before data transmission")
   u_ovl_txd_state_0_1
    (.clk(PCLK),  .reset_n(PRESETn),
     .start_event ((tx_state==4'd0)|(tx_state==4'd1)),
     .test_expr   (TXD==1'b1)
     );

   // If last tx_state=2 (start bit), TXD = 0.
   assert_next
     #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
      "TXD should be 0 when output start bit")
   u_ovl_txd_state_2
    (.clk(PCLK),  .reset_n(PRESETn),
     .start_event (tx_state==4'd2),
     .test_expr   (TXD==1'b0)
     );

   // If last tx_state=3-10 (D0 to D7), TXD = anything (tx_shift_buf[0]).
   assert_next
     #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
      "TXD should be same as first bit of shift register during transfer")
   u_ovl_txd_state_3_to_10
    (.clk(PCLK),  .reset_n(PRESETn),
     .start_event ((tx_state>4'd2) & (tx_state<4'd11)),
     .test_expr   (TXD==ovl_last_tx_shift_buf_0)
     );

   // If last tx_state=11 (stop bit), TXD = 1.
   assert_next
     #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
      "TXD should be 1 when output stop bit")
   u_ovl_txd_state_11
    (.clk(PCLK),  .reset_n(PRESETn),
     .start_event (tx_state==4'd11),
     .test_expr   (TXD==1'b1)
     );

   // Duration of tx_state in 2 to 11 must have 16 reg_baud_tick
   // (unless high speed test mode has been active)
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "Duration of tx_state when in state 2 to state 11 should have 16 ticks")
   u_ovl_width_of_tx_state
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr((tx_state!=ovl_reg_last_tx_state) &      // at state change
       (ovl_reg_last_tx_state>4'd1)&(ovl_reg_last_tx_state<4'd12) & // from state 2 to 11
       (ovl_reg_hs_test_mode_triggered==1'b0)), // high speed test mode not triggered
      .consequent_expr((ovl_reg_tx_tick_count==8'd15) | (ovl_reg_tx_tick_count==8'd16))
        // count from 0 to 15 (16 ticks)
     );


   // In high speed test mode, tx_state must change if it is in range of 2 to 11
   assert_next
     #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
       "Duration of tx_state should be 1 cycle if high speed test mode is enabled")
   u_ovl_width_of_tx_state_in_high_speed_test_mode
     (.clk(PCLK), .reset_n(PRESETn),
      .start_event((tx_state>4'd1)&(tx_state<4'd12) & reg_ctrl[6]),
      .test_expr  (tx_state != ovl_reg_last_tx_state)
      );

   // Duration of rx_state in 1 must have 8 reg_baud_tick
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "Duration of rx_state when state 1 should have 8 ticks")
   u_ovl_width_of_rx_state_1
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr((rx_state!=ovl_reg_last_rx_state) & // at state change
       (ovl_reg_last_rx_state==4'd1)), // last state was state 1
      .consequent_expr((ovl_reg_rx_tick_count==8'd7)|(ovl_reg_rx_tick_count==8'd8))
        // count from 0 to 7 (8 ticks)
     );

   // Duration of rx_state in 2 to 10 must have 16 reg_baud_tick
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "Duration of rx_state when in state 2 to state 10 should have 16 ticks")
   u_ovl_width_of_rx_state_data
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr((rx_state!=ovl_reg_last_rx_state) &    // at state change
       (ovl_reg_last_rx_state>4'd1)&(ovl_reg_last_rx_state<4'd11)),  // from state 2 to 9
      .consequent_expr((ovl_reg_rx_tick_count==8'd15)|(ovl_reg_rx_tick_count==8'd16))
         // count from 0 to 15 (16 ticks)
     );

   // UARTINT must be 0 if TXINT, RXINT, TXOVRINT and RXOVRINT are all 0
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "UARTINT must be 0 if TXINT, RXINT, TXOVRINT and RXOVRINT are all 0")
   u_ovl_uartint_mismatch
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr((TXINT | RXINT | TXOVRINT | RXOVRINT) == 1'b0), // No interrupt
      .consequent_expr(UARTINT==1'b0) // Combined interrupt = 0
     );

    // TXINT should be asserted when TX interrupt enabled and transmit buffer is available
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "TXINT should be triggered when enabled")
    u_ovl_txint_enable
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (reg_ctrl[0] & reg_ctrl[2] & tx_buf_full & tx_buf_clear),
     .test_expr   (TXINT == 1'b1)
     );

   // There should be no rising edge of TXINT if transmit is disabled or transmit interrupt is disabled
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "TXINT should not be triggered when disabled")
    u_ovl_txint_disable
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (((reg_ctrl[0]==1'b0) | (reg_ctrl[2]==1'b0)) & (TXINT == 1'b0)),
     .test_expr   (TXINT == 1'b0)
     );

   // if TXINT falling edge, there must has been a write to INTCLEAR register with bit[0]=1
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "When there is a falling edge of TXINT, there must has been a write to INTCLEAR")
   u_ovl_txint_clear
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr(ovl_last_txint & (~TXINT)), // Falling edge of TXINT
      .consequent_expr(ovl_last_psel & ovl_last_pwrite &
      (ovl_last_paddr==10'h003) & (ovl_last_pwdata[0]) ) // There must has been a write to INTCLEAR
     );

    // RXINT should be asserted when RX interrupt enabled and a new data is received
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "RXINT should be triggered when enabled")
    u_ovl_rxint_enable
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (reg_ctrl[3] & (rx_state==9) & (nxt_rx_state==10)),
     .test_expr   (RXINT == 1'b1)
     );

   // There should be no rising edge of RXINT if receive interrupt is disabled
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "RXINT should not be triggered when disabled")
    u_ovl_rxint_disable
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event ((reg_ctrl[3]==1'b0) & (RXINT == 1'b0)),
     .test_expr   (RXINT == 1'b0)
     );

   // if RXINT falling edge, there must has been a write to INTCLEAR register with bit[1]=1
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "When there is a falling edge of RXINT, there must has been a write to INTCLEAR")
   u_ovl_rxint_clear
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr(ovl_last_rxint & (~RXINT)), // Falling edge of TXINT
      .consequent_expr(ovl_last_psel & ovl_last_pwrite &
      (ovl_last_paddr==10'h003) & (ovl_last_pwdata[1]) ) // There must has been a write to INTCLEAR
     );

   // rx_buf_full should rise if rx_state change from 9 to 10
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "rx_buf_full should be asserted when a new character is received")
    u_ovl_rx_buf_full
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event ((rx_state==9) & (nxt_rx_state==10)),
     .test_expr   (rx_buf_full == 1'b1)
     );

   // if rx_buf_full falling edge, there must has been a read to the receive buffer
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "When there is a falling edge of RXINT, there must has been a read to receive buffer")
   u_ovl_rx_buf_full_clear
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr((~rx_buf_full) & ovl_last_rx_buf_full), // Falling edge of rx_buf_full
      .consequent_expr(ovl_last_psel & (~ovl_last_pwrite) &
      (ovl_last_paddr==10'h000)  ) // There must has been a read to rx data
     );

   // TXOVRINT must be 0 if reg_ctrl[4]=0
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "When there is a falling edge of RXINT, there must has been a write to INTCLEAR")
   u_ovl_txovrint_disable
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr(~reg_ctrl[4]),
      .consequent_expr(~TXOVRINT)
     );

   // RXOVRINT must be 0 if reg_ctrl[5]=0
   assert_implication
     #(`OVL_ERROR,`OVL_ASSERT,
     "When there is a falling edge of RXINT, there must has been a write to INTCLEAR")
   u_ovl_rxovrint_disable
     (.clk(PCLK), .reset_n(PRESETn),
      .antecedent_expr(~reg_ctrl[5]),
      .consequent_expr(~RXOVRINT)
     );

   // if a write take place to TX data buffer and tx_buf_full was 1, reg_tx_overrun will be set
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "tx buffer overrun should be asserted when a new character is write to buffer and buffer is already full")
    u_ovl_tx_buffer_overrun
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (write_enable00 & tx_buf_full & (~tx_buf_clear)),
     .test_expr   (reg_tx_overrun == 1'b1)
     );

   // if rx_buf_full is high and rx_state change from 9 to 10, reg_rx_overrun will be set
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "rx buffer overrun should be asserted when a new character is received and rx buffer is already full")
    u_ovl_rx_buffer_overrun
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (rx_buf_full & (~rx_data_read) & (rx_state==9) & (nxt_rx_state==10)),
     .test_expr   (reg_rx_overrun == 1'b1)
     );

   // if write to INTCLEAR  with bit[2]=1, reg_tx_overrun will be cleared,
    // Cannot have new overrun at the same time because the APB can only do onething at a time
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "tx buffer overrun should be clear when write to INTCLEAR")
    u_ovl_tx_buffer_overrun_clear_a
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (write_enable0c & (PWDATA[2])),
     .test_expr   (reg_tx_overrun==1'b0)
     );

   // if write to STATUS  with bit[2]=1, reg_tx_overrun will be cleared,
    // Cannot have new overrun at the same time because the APB can only do onething at a time
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "tx buffer overrun should be clear when write to INTCLEAR")
    u_ovl_tx_buffer_overrun_clear_b
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (write_enable04 & (PWDATA[2])),
     .test_expr   (reg_tx_overrun==1'b0)
     );

   // if write to INTCLEAR  with bit[3]=1, reg_rx_overrun will be cleared, unless a new overrun take place
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "rx buffer overrun should be clear when write to INTCLEAR, unless new overrun")
    u_ovl_rx_buffer_overrun_clear_a
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event (write_enable0c & (PWDATA[3]) & (~(rx_buf_full & (rx_state==9) & (nxt_rx_state==10)))),
     .test_expr   (reg_rx_overrun==1'b0)
     );

   // If rx buffer is not full, it cannot have new overrun
    assert_next
    #(`OVL_ERROR, 1,1,0, `OVL_ASSERT,
    "rx buffer overrun should be clear when write to INTCLEAR, unless new overrun")
    u_ovl_rx_buffer_overrun_when_empty
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event ((~rx_buf_full) & (reg_rx_overrun==1'b0)),
     .test_expr   (reg_rx_overrun==1'b0)
     );


   // Reading of reg_baud_div (worth checking due to two stage read mux)
    assert_next
    #(`OVL_ERROR, 1, 1, 0, `OVL_ASSERT,
    "Reading of baud rate divider value")
    u_ovl_read_baud_rate_divide_cfg
      (.clk(PCLK ), .reset_n (PRESETn),
     .start_event   (PSEL & (~PENABLE) & (~PWRITE) & (PADDR[11:2]==10'h004)),
     .test_expr     (PRDATA=={{12{1'b0}}, reg_baud_div})
     );

   // Recommended Baud Rate divider value is at least 16
   assert_never
     #(`OVL_ERROR,`OVL_ASSERT,
       "UART enabled with baud rate less than 16")
   u_ovl_baud_rate_divider_illegal
     (.clk(PCLK), .reset_n(PRESETn),
      .test_expr(((reg_ctrl[0]) & (reg_ctrl[6]==1'b0) & (reg_baud_div[19:4]=={16{1'b0}}) ) |
                 ((reg_ctrl[1]) &                       (reg_baud_div[19:4]=={16{1'b0}}) ) )
      );

   // Test mode never changes from hi-speed to normal speed unless TX is idle
   assert_never
     #(`OVL_ERROR,`OVL_ASSERT,
       "High speed test mode has been changed when TX was not idle")
   u_ovl_change_speed_tx_illegal
     (.clk(PCLK), .reset_n(PRESETn),
      .test_expr((tx_state != 4'd00) & (reg_ctrl[6] != ovl_last_reg_ctrl[6]))
      );

`endif

endmodule
