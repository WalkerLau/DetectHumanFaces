/* *****************************************************************
 *  This code is released under the MIT License.
 *  Copyright (c) 2020 Xuanzhi LIU, Qiao HU, Zongwu HE
 *  
 *  For latest version of this code or to issue a problem, 
 *  please visit: <https://github.com/WalkerLau/DetectHumanFaces>
 *  
 *  Note: the above information must be kept whenever or wherever the codes are used.
 *  
 * *****************************************************************/
module accelerator #(
  parameter RCS_ADDR                =32'h0,
  parameter CONF_ADDR               =32'h0,
  parameter RETURN_ADDR             =32'h0
)
(
  // Reset, Clock
  input           ARESETN,
  input           ACLK,

  // Master Write Address
  output [0:0]  M_AXI_AWID,
  output [31:0] M_AXI_AWADDR,
  output [7:0]  M_AXI_AWLEN,    // Burst Length: 0-255
  output [2:0]  M_AXI_AWSIZE,   // Burst Size: Fixed 2'b011
  output [1:0]  M_AXI_AWBURST,  // Burst Type: Fixed 2'b01(Incremental Burst)
  output        M_AXI_AWLOCK,   // Lock: Fixed 2'b00
  output [3:0]  M_AXI_AWCACHE,  // Cache: Fiex 2'b0011
  output [2:0]  M_AXI_AWPROT,   // Protect: Fixed 2'b000
  output [3:0]  M_AXI_AWQOS,    // QoS: Fixed 2'b0000
  output [0:0]  M_AXI_AWUSER,   // User: Fixed 1'b0
  output        M_AXI_AWVALID,
  input         M_AXI_AWREADY,

  // Master Write Data
  output [31:0] M_AXI_WDATA,
  output [3:0]  M_AXI_WSTRB,
  output        M_AXI_WLAST,
  output [0:0]  M_AXI_WUSER,
  output        M_AXI_WVALID,
  input         M_AXI_WREADY,

  // Master Write Response
  input [0:0]   M_AXI_BID,
  input [1:0]   M_AXI_BRESP,
  input [0:0]   M_AXI_BUSER,
  input         M_AXI_BVALID,
  output        M_AXI_BREADY,
    
  // Master Read Address
  output [0:0]  M_AXI_ARID,
  output [31:0] M_AXI_ARADDR,
  output [7:0]  M_AXI_ARLEN,
  output [2:0]  M_AXI_ARSIZE,
  output [1:0]  M_AXI_ARBURST,
  output [1:0]  M_AXI_ARLOCK,
  output [3:0]  M_AXI_ARCACHE,
  output [2:0]  M_AXI_ARPROT,
  output [3:0]  M_AXI_ARQOS,
  output [0:0]  M_AXI_ARUSER,
  output        M_AXI_ARVALID,
  input         M_AXI_ARREADY,
    
  // Master Read Data 
  input [0:0]   M_AXI_RID,
  input [31:0]  M_AXI_RDATA,
  input [1:0]   M_AXI_RRESP,
  input         M_AXI_RLAST,
  input [0:0]   M_AXI_RUSER,
  input         M_AXI_RVALID,
  output        M_AXI_RREADY,

  input             write_addr_index,
  input             ignite_acc,
  output            ignite_ready,
  output            ACC_IRQ,
  input             ACC_IRQ_READY,
  
  // LocalMem
  input [31:0]      MEM_RDATA,
  output reg[15:0]  MEM_ADRS
  
);

  // AXI write channel fixed ports
  assign M_AXI_AWID         = 1'b0;
  assign M_AXI_AWADDR[31:0] = reg_wr_adrs[31:0];
  assign M_AXI_AWLEN[7:0]   = reg_w_len[7:0];
  assign M_AXI_AWSIZE[2:0]  = 2'b010;
  assign M_AXI_AWBURST[1:0] = 2'b01;
  assign M_AXI_AWLOCK       = 1'b0;
  assign M_AXI_AWCACHE[3:0] = 4'b0011;
  assign M_AXI_AWPROT[2:0]  = 3'b000;
  assign M_AXI_AWQOS[3:0]   = 4'b0000;
  assign M_AXI_AWUSER[0]    = 1'b0;
  assign M_AXI_AWVALID      = reg_awvalid;
  assign M_AXI_WDATA[31:0]  = wr_data;
  assign M_AXI_WSTRB[3:0]   = (reg_wvalid)?4'hF:4'h0;
  assign M_AXI_WLAST        = (reg_w_len[7:0] == 8'd0)?1'b1:1'b0;
  assign M_AXI_WUSER        = 1'b0;
  assign M_AXI_WVALID       = reg_wvalid;
  assign M_AXI_BREADY       = M_AXI_BVALID;
  //AXI read channel fixed ports
  assign M_AXI_ARID         = 1'b0;
  assign M_AXI_ARADDR[31:0] = reg_rd_adrs[31:0];
  assign M_AXI_ARLEN[7:0]   = reg_r_len[7:0];
  assign M_AXI_ARSIZE[2:0]  = 3'b010;
  assign M_AXI_ARBURST[1:0] = 2'b01;
  assign M_AXI_ARLOCK       = 1'b0;
  assign M_AXI_ARCACHE[3:0] = 4'b0011;
  assign M_AXI_ARPROT[2:0]  = 3'b000;
  assign M_AXI_ARQOS[3:0]   = 4'b0000;
  assign M_AXI_ARUSER[0]    = 1'b0;
  assign M_AXI_ARVALID      = reg_arvalid;
  assign M_AXI_RREADY       = M_AXI_RVALID;

  localparam AM_WAIT    = 8'd0;
  localparam S_RA_START = 8'd1;
  localparam S_RD_WAIT  = 8'd2;
  localparam S_RD_PROC  = 8'd3;
  localparam S_RD_DONE  = 8'd4;
  localparam S_WA_WAIT  = 8'd5;
  localparam S_WA_START = 8'd6;
  localparam S_WD_WAIT  = 8'd7;
  localparam S_WD_PROC  = 8'd8;
  localparam S_WR_WAIT  = 8'd9;
  localparam S_WR_DONE  = 8'd10;
  //
  localparam M_NONE         = 2'b00;
  localparam M_READ         = 2'b01;
  localparam M_WRITE        = 2'b10;

  // Access Mode control
  reg [1:0]           AccessMode;
  always @ (posedge ACLK or negedge ARESETN)begin
    if(!ARESETN)begin
      AccessMode      <= M_NONE;
    end
    else begin
      if(am_r_valid)begin
        AccessMode      <= M_READ;
      end
      else if(am_w_valid)begin
        AccessMode      <= M_WRITE;
      end
      else begin
        AccessMode      <= M_NONE;
      end
    end
  end

  // ALL-IN-ONE AXI ACCESS STATE MACHINE
  reg [7:0]           am_state;
  reg [31:0]          reg_rd_adrs;
  reg                 reg_arvalid;
  reg [7:0]           reg_r_len;
  reg                 am_r_ready;
  reg [31:0]          reg_wr_adrs;
  reg                 reg_awvalid, reg_wvalid;
  reg [7:0]           reg_w_len;
  reg                 am_w_ready;  
  reg [1:0]           reg_wr_status;
  always @(posedge ACLK or negedge ARESETN) begin
    if(!ARESETN) begin
      am_state            <= AM_WAIT;
      reg_rd_adrs[31:0]   <= 32'd0;
      reg_arvalid         <= 1'b0;
      reg_wr_adrs[31:0]   <= 32'd0;
      reg_awvalid         <= 1'b0;
      reg_wvalid          <= 1'b0;
      reg_w_len[7:0]      <= 8'd0;
      reg_wr_status[1:0]  <= 2'd0;
      am_r_ready          <= 1'b0;
      am_w_ready          <= 1'b0;
    end else begin
      case(am_state)
        AM_WAIT: begin
          if(AccessMode == M_WRITE)begin
            am_state          <= S_WA_START;
            reg_wr_adrs[31:0] <= WR_ADRS[31:0]; 
          end
          else if(AccessMode == M_READ)begin
            am_state          <= S_RA_START; 
            reg_rd_adrs[31:0] <= RD_ADRS[31:0];  
            reg_r_len[7:0]    <= RD_LEN - 8'd1; // AXI Burst_Length = AxLEN[7:0] + 1 
          end else begin
            reg_arvalid         <= 1'b0;
            reg_awvalid         <= 1'b0;
            reg_wvalid          <= 1'b0;
            reg_w_len[7:0]      <= 8'd0;
            reg_wr_status[1:0]  <= 2'd0;
            am_r_ready          <= 1'b0;
            am_w_ready          <= 1'b0;            
          end
        end
        S_RA_START: begin // this is an important state, cannot be removed!
          reg_arvalid       <= 1'b1;
          am_r_ready        <= 1'b1;
          am_state          <= S_RD_WAIT;
        end
        S_RD_WAIT: begin
          if(M_AXI_ARREADY) begin
            am_state        <= S_RD_PROC;
            reg_arvalid     <= 1'b0;
            am_r_ready      <= 1'b0;
          end
        end
        S_RD_PROC: begin
          if(M_AXI_RVALID) begin
            if(M_AXI_RLAST) begin             
              am_state          <= S_RD_DONE;
            end else begin
              reg_r_len[7:0]    <= reg_r_len[7:0] -8'd1;
            end
          end
        end
		    S_RD_DONE: begin
          am_state          <= AM_WAIT;  
		    end
        S_WA_START: begin
          am_state            <= S_WD_WAIT;
          reg_awvalid         <= 1'b1;
          reg_w_len[7:0]      <= WR_LEN - 8'd1; // AXI Burst_Length = AxLEN[7:0] + 1, this line shouldn't be placed in S_WR_IDLE
          am_w_ready          <= 1'b1;
        end
        S_WD_WAIT: begin
          if(M_AXI_AWREADY) begin
            am_state        <= S_WD_PROC;
            reg_awvalid     <= 1'b0;
            reg_wvalid      <= 1'b1;
            am_w_ready      <= 1'b0;
          end
        end
        S_WD_PROC: begin
          if(M_AXI_WREADY) begin
            if(M_AXI_WLAST) begin
              am_state        <= S_WR_WAIT;
              reg_wvalid      <= 1'b0;
            end else begin
              reg_w_len[7:0]  <= reg_w_len[7:0] - 8'd1;
            end
          end
        end
        S_WR_WAIT: begin
          if(M_AXI_BVALID) begin
            reg_wr_status[1:0]  <= M_AXI_BRESP[1:0];
            am_state          <= S_WR_DONE;
          end
        end
        S_WR_DONE: begin
            am_state <= AM_WAIT;
        end

        default: begin
          am_state <= AM_WAIT;
        end
      endcase
    end
  end
  
//////////////////////////////////////////////////////////////////////////////////////////////////
  parameter NROWS                   =480;
  parameter NCOLS                   =640;
  parameter TDEPTH                  =6;
  parameter NTREES                  =468;
  parameter OFFSET                  =128;
  parameter PIC_ADDR_1              =32'h2bc00000;
  parameter PIC_ADDR_2              =32'h2be00000;
  //parameter CASCADE_ADDR            =32'h28000000;

  localparam IDLE                   = 6'd0;         
  localparam RCS_S1                 = 6'd1;
  localparam RCS_S2                 = 6'd2;
  localparam LOAD_RCS               = 6'd3; 
  localparam CHECK_BOUNDRY          = 6'd4;       
  localparam WRITE_RETURN1_S1       = 6'd5;         
  localparam WRITE_RETURN1_S2       = 6'd6;         
  localparam FORLOOP1               = 6'd7; 
  localparam F1_IDLE                = 6'd8; 
  localparam FORLOOP2               = 6'd9; 
  localparam TCODE_S1               = 6'd10;  
  localparam TCODE_S2               = 6'd11;
  localparam TCODE_S3               = 6'd12; 
  localparam LOAD_TCODE             = 6'd13;   
  localparam CAL_REMAINDER          = 6'd14;     
  localparam READ_PIX1_S1           = 6'd15;     
  localparam READ_PIX1_S2           = 6'd16;     
  localparam LOAD_PIX1              = 6'd17;   
  localparam READ_PIX2_S1           = 6'd18;     
  localparam READ_PIX2_S2           = 6'd19;     
  localparam LOAD_PIX2              = 6'd20;   
  localparam F1_PIX_COMP            = 6'd21;    
  localparam F1_IDX_ADD             = 6'd22;  
  localparam LUT_S1                 = 6'd23;
  localparam LUT_S2                 = 6'd24;
  localparam LUT_S3                 = 6'd25;
  localparam F1_CONF_ADD            = 6'd26;    
  localparam THR_S1                 = 6'd27;
  localparam THR_S2                 = 6'd28;
  localparam THR_S3                 = 6'd29;
  localparam F1_CONF_COMP           = 6'd30;     
  localparam WRITE_RETURN2_S1       = 6'd31;         
  localparam WRITE_RETURN2_S2       = 6'd32;         
  localparam CONF_SUB               = 6'd33; 
  localparam WRITE_CONF_S1          = 6'd34;       
  localparam WRITE_CONF_S2          = 6'd35;       
  localparam WRITE_RETURN3_S1       = 6'd36;         
  localparam WRITE_RETURN3_S2       = 6'd37;        
  localparam RETURN_VAL1            = 6'd38;     
  localparam RETURN_VAL2            = 6'd39;
  localparam RETURN_VAL3            = 6'd40;
  localparam RETURN_VAL4            = 6'd41;
  localparam RETURN_VAL5            = 6'd42;
  localparam RETURN_VAL6            = 6'd43;

  reg [5:0] state;

  reg signed [31:0] r_new;
  reg signed [31:0] c_new;
  reg signed [31:0] s_new;

  reg [15:0] ptree_addr;
  reg signed [31:0] pixels_addr;

  reg [8:0] counter_1;
  reg [2:0] counter_2;

  reg [31:0]  idx;
  reg [15:0]  tcodes_addr;
  reg [15:0]  lut_addr;
  reg [15:0]  thr_addr;

  reg [7:0] pixels_1;
  reg [7:0] pixels_2;
  reg pixels_flag;

  reg[31:0] o;

  reg [31:0]          RD_ADRS;
  reg [7:0]           RD_LEN;
  reg                 am_r_valid;
  reg [31:0]          WR_ADRS;
  reg [7:0]           WR_LEN;
  reg                 am_w_valid;

  reg [95:0]          rcs_reg;
  reg [31:0]          tcode_reg;
  reg [31:0]          wr_data;

  reg signed [7:0]          tcodes_1;
  reg signed [7:0]          tcodes_2;
  reg signed [7:0]          tcodes_3;
  reg signed [7:0]          tcodes_4;

  reg [31:0]          lut;
  reg [31:0]          thr;
  reg [31:0]          thr_last;

  reg signed [31:0]          remainder_1;
  reg signed [31:0]          remainder_2;
  reg [31:0]          pixels_1_1;
  reg [31:0]          pixels_2_2;

  reg                 ignite_ready;
  reg                 ACC_IRQ;

  reg                 result;

  always@(posedge ACLK or negedge ARESETN)
  begin
    if(ARESETN == 1'b0)
    begin
      result <= 1'd0;
      state <= IDLE;
      RD_ADRS         <= 32'd0;
      RD_LEN          <= 8'd0;
      WR_ADRS         <= 32'd0;
      WR_LEN          <= 8'd0;
      am_r_valid      <= 1'b0;
      am_w_valid      <= 1'b0;
      ignite_ready    <= 1'b0;
      ACC_IRQ         <= 1'b0;
      rcs_reg         <= 96'd0;
      tcode_reg       <= 32'd0;
      tcodes_1        <= 8'd0;
      tcodes_2        <= 8'd0;
      tcodes_3        <= 8'd0;
      tcodes_4        <= 8'd0;
      lut             <= 32'd0;
      thr             <= 32'd0;
      thr_last        <= 32'd0;
      MEM_ADRS        <= 0;
    end
    else
    begin
      case(state)
        IDLE: begin
          if(ignite_acc)begin
            state          <= RCS_S1;
          end
          ACC_IRQ             <= 1'b0;
          ptree_addr <= 0;
          //ptree_addr <= CASCADE_ADDR + 16;      //cascade是参数文件首地址
          o <= 0;
          counter_1 <= 0;
          counter_2 <= 0;
          if(write_addr_index == 1'b0)begin
            pixels_addr <= PIC_ADDR_1;
          end
          else if(write_addr_index == 1'b1)begin
            pixels_addr <= PIC_ADDR_2;
          end
        end
        RCS_S1:
        begin
          if(am_r_ready == 1'b1)begin
            state           <= RCS_S2;
            am_r_valid      <= 1'b0;
          end 
          else if(am_state == AM_WAIT)begin
            RD_ADRS         <= RCS_ADDR; //RCS的地址
            RD_LEN          <= 8'd3;
            am_r_valid      <= 1'b1;          
          end
        end
        RCS_S2: 
        begin
          if(am_state == S_RD_DONE)begin
            state          <= LOAD_RCS;
          end
          else if(M_AXI_RVALID && M_AXI_RREADY)begin
            rcs_reg          = {rcs_reg[31:0], rcs_reg[95:32]};
            rcs_reg[95: 64]  = M_AXI_RDATA;
          end
        end
        LOAD_RCS:
        begin
          ignite_ready      <= 1'b1; // ignite_ready should stay high for at least 4 cycles
          r_new <= rcs_reg[31:0]  * 256;
          c_new <= rcs_reg[63:32] * 256;
          s_new <= rcs_reg[95:64];
          state <= CHECK_BOUNDRY;
        end
        CHECK_BOUNDRY:
        begin
          if( ((r_new+(s_new*128))/256)>=NROWS || ((r_new-(s_new*128))/256)<0 || ((c_new+(s_new*128))/256)>=NCOLS || ((c_new-(s_new*128))/256)<0 )
          begin
            result <= 0;
            state <= WRITE_RETURN1_S1;
          end
          else
          state <= FORLOOP1;
        end
        WRITE_RETURN1_S1:
        begin
          if(am_w_ready == 1'b1)begin
            state      <= WRITE_RETURN1_S2;
            am_w_valid    <= 1'b0;
          end 
          else if(am_state == AM_WAIT)begin
            WR_ADRS         <= RETURN_ADDR; 
            WR_LEN          <= 8'd1;
            wr_data         <= result;
            am_w_valid      <= 1'b1;
          end
        end
        WRITE_RETURN1_S2:
        begin
          if(am_state == S_WR_DONE)begin
            state           <= RETURN_VAL1;
          end
        end
        FORLOOP1:
        begin
          if(counter_1 < NTREES)
          begin
            state <= F1_IDLE;
            counter_1 <= counter_1 + 1;
          end
          else
          begin
            thr_last <= thr;
            sub_start <= 1;
            state <= CONF_SUB;
            counter_1 <= 0;
          end
        end
        // INIT_PTREE:
        // begin
        //   if (counter_1 == 235) begin
        //     ptree_addr <= 0;
        //     state <= F1_IDLE;
        //   end else begin
        //     state <= F1_IDLE;
        //   end
        // end
        F1_IDLE:
        begin
          tcodes_addr <= ptree_addr ;
          lut_addr <= ptree_addr + 63;
          thr_addr <= ptree_addr + 127;
          idx <= 1;
          state <= FORLOOP2;
        end
        FORLOOP2: 
        begin
          if(counter_2 < TDEPTH)
          begin
            state <= TCODE_S1;
            counter_2 <= counter_2 + 1;
          end
          else
          begin
            state <= LUT_S1;
            counter_2 <= 0;
          end
        end
        // ADDR_SEL:
        // begin
        //   if(counter_1 <=234)
        //   begin
        //     OR_reg <= 32'h80000000;
        //     state <= TCODE_S1;
        //   end
        //   else
        //   begin
        //     OR_reg <= 32'h00000000;
        //     state <= TCODE_S1;
        //   end
        // end
        TCODE_S1:
        begin
          state           <= TCODE_S2;
          MEM_ADRS        <= tcodes_addr + idx[15:0] - 1;
        end
        TCODE_S2:begin  // wait for MEM_RDATA to be stable
          state <= TCODE_S3;
        end 
        TCODE_S3:
        begin
          tcode_reg[31: 0] <= MEM_RDATA;
          state            <= LOAD_TCODE;
        end
        LOAD_TCODE:
        begin
          tcodes_1        <= tcode_reg[31:24];
          tcodes_2        <= tcode_reg[23:16];
          tcodes_3        <= tcode_reg[15:8];
          tcodes_4        <= tcode_reg[7:0];
          // tcodes_1        <= tcode_reg[7:0];
          // tcodes_2        <= tcode_reg[15:8];
          // tcodes_3        <= tcode_reg[23:16];
          // tcodes_4        <= tcode_reg[31:24];
          state           <= CAL_REMAINDER;
        end
        CAL_REMAINDER:
        begin
          remainder_1     <= (((r_new + tcodes_1*s_new) >>> 8) * NCOLS + (c_new + tcodes_2*s_new)/256)*2 % 4;
          remainder_2     <= (((r_new + tcodes_3*s_new) >>> 8) * NCOLS + (c_new + tcodes_4*s_new)/256)*2 % 4;
          state           <= READ_PIX1_S1;
        end
        READ_PIX1_S1:
        begin
          if(am_r_ready == 1'b1)begin
            state        <= READ_PIX1_S2;
            am_r_valid      <= 1'b0;
          end 
          else if(am_state == AM_WAIT)begin
            RD_ADRS         <= pixels_addr + (((r_new + tcodes_1*s_new) >>> 8) * NCOLS + (c_new + tcodes_2*s_new)/256)*2 - remainder_1;
            RD_LEN          <= 8'd1;
            am_r_valid      <= 1'b1;          
          end
        end
        READ_PIX1_S2: 
        begin
          if(am_state == S_RD_DONE)begin
            state          <= LOAD_PIX1;
          end
          else if(M_AXI_RVALID && M_AXI_RREADY)begin
            pixels_1_1[31:0] <= M_AXI_RDATA;
          end
        end 
        LOAD_PIX1: // convert RGB565 to Gray
        begin
          case (remainder_1)
            32'd0: begin pixels_1 <= ((pixels_1_1[15:11]*76) + (pixels_1_1[10: 5]*150) + (pixels_1_1[ 4: 0]*30)) >> 8; state  <= READ_PIX2_S1; end
            32'd2: begin pixels_1 <= ((pixels_1_1[31:27]*76) + (pixels_1_1[26:21]*150) + (pixels_1_1[20:16]*30)) >> 8; state  <= READ_PIX2_S1; end 
            default: state <= IDLE;
          endcase
        end
        READ_PIX2_S1:
        begin
          if(am_r_ready == 1'b1)begin
            state        <= READ_PIX2_S2;
            am_r_valid      <= 1'b0;
          end 
          else if(am_state == AM_WAIT)begin
            RD_ADRS         <= pixels_addr + (((r_new + tcodes_3*s_new) >>> 8) * NCOLS + (c_new + tcodes_4*s_new)/256)*2 - remainder_2;
            RD_LEN          <= 8'd1;
            am_r_valid      <= 1'b1;          
          end
        end
        READ_PIX2_S2: 
        begin
          if(am_state == S_RD_DONE)begin
            state          <= LOAD_PIX2;
          end
          else if(M_AXI_RVALID && M_AXI_RREADY)begin
            pixels_2_2[31:0] <= M_AXI_RDATA;
          end
        end 
        LOAD_PIX2: // convert RGB565 to Gray
        begin
          case (remainder_2)
            32'd0: begin pixels_2 <= ((pixels_2_2[15:11]*76) + (pixels_2_2[10: 5]*150) + (pixels_2_2[ 4: 0]*30)) >> 8; state  <= F1_PIX_COMP; end
            32'd2: begin pixels_2 <= ((pixels_2_2[31:27]*76) + (pixels_2_2[26:21]*150) + (pixels_2_2[20:16]*30)) >> 8; state  <= F1_PIX_COMP; end 
            default: state <= IDLE;
          endcase
        end
        F1_PIX_COMP:
        begin
          if (pixels_1<=pixels_2) begin
            pixels_flag <= 1;
            state <= F1_IDX_ADD;
          end else begin
            pixels_flag <= 0;
            state <= F1_IDX_ADD;
          end
        end
        F1_IDX_ADD:
        begin
          idx <= idx*2 + pixels_flag;
          state <= FORLOOP2;
        end
        LUT_S1:
        begin
          state           <= LUT_S2;                
          MEM_ADRS        <= lut_addr + idx[15:0] - 64;         
        end
        LUT_S2:begin // wait for MEM_RDATA to be stable
          state <= LUT_S3;
        end
        LUT_S3: 
        begin
            lut[31: 0]       <= {MEM_RDATA[7:0],MEM_RDATA[15:8],MEM_RDATA[23:16],MEM_RDATA[31:24]};
            add_start        <= 1;
            state            <= F1_CONF_ADD;
        end
        F1_CONF_ADD:
        begin 
          if (add_result_valid) begin
            o <= add_result_wire;
            state <= THR_S1;
            add_start  <= 0;
          end
        end
       THR_S1:
        begin
            state        <= THR_S2;          
            MEM_ADRS        <= thr_addr;                       
        end
        THR_S2:// wait for MEM_RDATA to be stable
        begin
          state <= THR_S3;
        end
        THR_S3: 
        begin
          thr[31: 0]       <= {MEM_RDATA[7:0],MEM_RDATA[15:8],MEM_RDATA[23:16],MEM_RDATA[31:24]};
          comp_start       <= 1;
          state            <= F1_CONF_COMP;
        end
        F1_CONF_COMP:
        begin
          if(comp_result_valid)
          begin
            if (comp_result) begin
              result <= 0;
              state <= WRITE_RETURN2_S1;
              comp_start <= 0;
            end else begin
              ptree_addr <= ptree_addr + OFFSET;
              comp_start <= 0;
              state <= FORLOOP1;
            end
          end
        end
        WRITE_RETURN2_S1:
        begin
          if(am_w_ready == 1'b1)begin
            state      <= WRITE_RETURN2_S2;
            am_w_valid    <= 1'b0;
          end 
          else if(am_state == AM_WAIT)begin
            WR_ADRS         <= RETURN_ADDR;
            WR_LEN          <= 8'd1;
            wr_data         <= result;
            am_w_valid      <= 1'b1;
          end
        end
        WRITE_RETURN2_S2:
        begin
          if(am_state == S_WR_DONE)begin
            state        <= RETURN_VAL1;
          end
        end
        CONF_SUB:
        begin
          if (sub_result_valid) begin
            o <= sub_result;
            result <= 1;
            state <= WRITE_CONF_S1;
            sub_start <= 0;
          end
        end
        WRITE_CONF_S1:
        begin
          if(am_w_ready == 1'b1)begin
            state         <= WRITE_CONF_S2;
            am_w_valid    <= 1'b0;
          end 
          else if(am_state == AM_WAIT)begin
            WR_ADRS         <= CONF_ADDR;
            WR_LEN          <= 8'd1;
            wr_data         <= o;
            am_w_valid      <= 1'b1;
          end
        end
        WRITE_CONF_S2:
        begin
          if(am_state == S_WR_DONE)begin
            state        <= WRITE_RETURN3_S1;
          end
        end       
        WRITE_RETURN3_S1:
        begin
          if(am_w_ready == 1'b1)begin
            state      <= WRITE_RETURN3_S2;
            am_w_valid    <= 1'b0;
          end 
          else if(am_state == AM_WAIT)begin
            WR_ADRS         <= RETURN_ADDR;
            WR_LEN          <= 8'd1;
            wr_data         <= result;
            am_w_valid      <= 1'b1;
          end
        end
        WRITE_RETURN3_S2:
        begin
          if(am_state == S_WR_DONE)begin
            state        <= RETURN_VAL1;
          end
        end       
        RETURN_VAL1: begin
          state             <= RETURN_VAL2;
          ACC_IRQ           <= 1'b1;
          ignite_ready      <= 1'b0; // ignite_ready should stay high for at least 4 cycles
        end
        RETURN_VAL2:begin
          if(ACC_IRQ_READY)begin
            state             <= RETURN_VAL3;
          end
        end
        RETURN_VAL3:begin
          state             <= RETURN_VAL4;
        end
        RETURN_VAL4:begin
          state             <= RETURN_VAL5;
        end
        RETURN_VAL5:begin
          state             <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

  wire[31:0]    sub_result;
  wire          comp_result;
  wire[31:0]    add_result_wire;
  wire[31:0]    add_result_wire;

  reg add_start;
  reg comp_start;
  reg sub_start;

  wire add_result_valid;
  wire comp_result_valid;
  wire sub_result_valid;

  floating_point_add floating_point_add(
    .aclk                            (ACLK),
    .s_axis_a_tdata                  (lut),
    .s_axis_a_tvalid                 (add_start),
    .s_axis_b_tdata                  (o),
    .s_axis_b_tvalid                 (add_start),
    .m_axis_result_tdata             (add_result_wire),
    .m_axis_result_tvalid            (add_result_valid)     
  );

  floating_point_comp floating_point_comp(
    .aclk                            (ACLK),
    .s_axis_a_tdata                  (o),
    .s_axis_a_tvalid                 (comp_start),
    .s_axis_b_tdata                  (thr),
    .s_axis_b_tvalid                 (comp_start),
    .m_axis_result_tdata             (comp_result),
    .m_axis_result_tvalid            (comp_result_valid)
  );

  floating_point_sub floating_point_sub(
    .aclk                            (ACLK),
    .s_axis_a_tdata                  (o),
    .s_axis_a_tvalid                 (sub_start),
    .s_axis_b_tdata                  (thr_last),
    .s_axis_b_tvalid                 (sub_start),   
    .m_axis_result_tdata             (sub_result),
    .m_axis_result_tvalid            (sub_result_valid)     
  );

endmodule