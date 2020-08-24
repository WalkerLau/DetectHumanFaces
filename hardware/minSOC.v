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

module minSOC #(
    parameter                   SimPresent = 0
)   (
    input       wire            CLK50M,
    input       wire            RSTn,

    // UART
    output      wire            TXD,
    input       wire            RXD,

    // LED
    output      wire [3:0]      ledNumOut,

    // Button
    //input       wire            Btn,

    // SD card SPI
    //output                           sd_ncs,                 //SD card chip select (SPI mode)
    //output                           sd_dclk,                //SD card clock
    //output                           sd_mosi,                //SD card controller data output
    //input                            sd_miso,                //SD card controller data input

    // CMOS
    inout                            cmos_scl,               //cmos i2c clock
    inout                            cmos_sda,               //cmos i2c data
    input                            cmos_vsync,             //cmos vsync
    input                            cmos_href,              //cmos hsync refrence,data valid
    input                            cmos_pclk,              //cmos pxiel clock
    output                           cmos_xclk,              //cmos externl clock
    input   [7:0]                    cmos_db,                //cmos data  

    // HDMI
    //hdmi output        
    output                           tmds_clk_p,             //HDMI differential clock positive
    output                           tmds_clk_n,             //HDMI differential clock negative
    output[2:0]                      tmds_data_p,            //HDMI differential data positive
    output[2:0]                      tmds_data_n,             //HDMI differential data negative

    // DDR3
    inout [31:0]                     ddr3_dq,                //ddr3 data
    inout [3:0]                      ddr3_dqs_n,             //ddr3 dqs negative
    inout [3:0]                      ddr3_dqs_p,             //ddr3 dqs positive
    output [14:0]                    ddr3_addr,              //ddr3 address
    output [2:0]                     ddr3_ba,                //ddr3 bank
    output                           ddr3_ras_n,             //ddr3 ras_n
    output                           ddr3_cas_n,             //ddr3 cas_n
    output                           ddr3_we_n,              //ddr3 write enable
    output                           ddr3_reset_n,           //ddr3 reset,
    output [0:0]                     ddr3_ck_p,              //ddr3 clock negative
    output [0:0]                     ddr3_ck_n,              //ddr3 clock positive
    output [0:0]                     ddr3_cke,               //ddr3_cke,
    output [0:0]                     ddr3_cs_n,              //ddr3 chip select,
    output [3:0]                     ddr3_dm,                //ddr3_dm
    output [0:0]                     ddr3_odt                //ddr3_odt
);

//------------------------------------------------------------------------------
// GLOBAL CLOCK
//------------------------------------------------------------------------------
// BUFG BUFG_inst (
//    .O               (clk_buf),          // 1-bit output: Clock output
//    .I               (CLK50M)        // 1-bit input: Clock input
// );

//------------------------------------------------------------------------------
// RESET
//------------------------------------------------------------------------------

wire            SYSRESETREQ;
reg             cpuresetn;

always @(posedge clk or negedge RSTn)begin
    if (~RSTn) 
        cpuresetn <= 1'b0;
    else if (SYSRESETREQ) 
        cpuresetn <= 1'b0;
    else 
        cpuresetn <= 1'b1;
end

wire        SLEEPing;

//------------------------------------------------------------------------------
// DEBUG CONFIG
//------------------------------------------------------------------------------


wire            CDBGPWRUPREQ;
reg             CDBGPWRUPACK;

always @(posedge clk or negedge RSTn)begin
    if (~RSTn) 
        CDBGPWRUPACK <= 1'b0;
    else 
        CDBGPWRUPACK <= CDBGPWRUPREQ;
end

//------------------------------------------------------------------------------
// INTERRUPT 
//------------------------------------------------------------------------------

wire    [239:0] IRQ;


//------------------------------------------------------------------------------
// CORE BUS 
//------------------------------------------------------------------------------

// CPU I-Code 
wire    [31:0]  HADDRI;
wire    [1:0]   HTRANSI;
wire    [2:0]   HSIZEI;
wire    [2:0]   HBURSTI;
wire    [3:0]   HPROTI;
wire    [31:0]  HRDATAI;
wire            HREADYI;
wire    [1:0]   HRESPI;

// CPU D-Code 
wire    [31:0]  HADDRD;
wire    [1:0]   HTRANSD;
wire    [2:0]   HSIZED;
wire    [2:0]   HBURSTD;
wire    [3:0]   HPROTD;
wire    [31:0]  HWDATAD;
wire            HWRITED;
wire    [31:0]  HRDATAD;
wire            HREADYD;
wire    [1:0]   HRESPD;
wire    [1:0]   HMASTERD;

// CPU System bus 
wire    [31:0]  HADDRS;
wire    [1:0]   HTRANSS;
wire            HWRITES;
wire    [2:0]   HSIZES;
wire    [31:0]  HWDATAS;
wire    [2:0]   HBURSTS;
wire    [3:0]   HPROTS;
wire            HREADYS;
wire    [31:0]  HRDATAS;
wire    [1:0]   HRESPS;
wire    [1:0]   HMASTERS;
wire            HMASTERLOCKS;


//------------------------------------------------------------------------------
// CODE BUS MUX & CONNECTION
//------------------------------------------------------------------------------

// CODE BUS MUX 
wire    [31:0]  HADDRC     = HTRANSD[1] ? HADDRD  : HADDRI;
wire    [2:0]   HBURSTC    = HTRANSD[1] ? HBURSTD : HBURSTI;
wire            HMASTLOCKS = 1'b0;
wire    [3:0]   HPROTC     = HTRANSD[1] ? HPROTD  : HPROTI;
wire    [2:0]   HSIZEC     = HTRANSD[1] ? HSIZED  : HSIZEI;
wire    [1:0]   HTRANSC    = HTRANSD[1] ? HTRANSD : HTRANSI;
wire    [31:0]  HWDATAC    = HWDATAD;
wire            HWRITEC    = HTRANSD[1] ? HWRITED : 1'b0;
wire    [31:0]  HRDATAC; 
wire            HREADYC; 

assign          HREADYI    = HREADYC;
assign          HREADYD    = HREADYC;
assign          HRDATAI    = HRDATAC;
assign          HRDATAD    = HRDATAC;

// CODE bus connection
AHB2ROM #(
    .MEMWIDTH                           (15)        // Size = 32KB
)
    ITCM(     
    .HSEL                               (1'b1),     
    .HCLK                               (clk),      
    .HRESETn                            (cpuresetn),
    .HREADY                             (HREADYC),  
    .HADDR                              (HADDRC),   
    .HTRANS                             (HTRANSC),  
    .HWRITE                             (HWRITEC),  
    .HSIZE                              (HSIZEC),   
    .HWDATA                             (HWDATAC),  
    .HREADYOUT                          (HREADYC),  
    .HRDATA                             (HRDATAC)   
);

//------------------------------------------------------------------------------
// Instantiate Cortex-M3 processor 
//------------------------------------------------------------------------------
cortexm3ds_logic ulogic(
    // PMU
    .ISOLATEn                           (1'b1),
    .RETAINn                            (1'b1),

    // RESETS
    .PORESETn                           (RSTn), //(corerstn), //chg: (RSTn),
    .SYSRESETn                          (cpuresetn), //(corerstn), //chg: (cpuresetn),
    .SYSRESETREQ                        (SYSRESETREQ),
    .RSTBYPASS                          (1'b0),
    .CGBYPASS                           (1'b0),
    .SE                                 (1'b0),

    // CLOCKS
    .FCLK                               (clk),
    .HCLK                               (clk),
    .TRACECLKIN                         (clk),//chg:.TRACECLKIN                         (1'b0),

    // SYSTICK chg
    //.STCLK                              (1'b0),
    //.STCALIB                            (26'b0),
    //.AUXFAULT                           (32'b0),
    .STCLK                              (1'b1),         
                                
    .STCALIB                            ({1'b1,         
                                          1'b0,         
                                          24'h003D08F}),
    .AUXFAULT                           ({32{1'b0}}),   

    // CONFIG - SYSTEM
    .BIGEND                             (1'b0),
    .DNOTITRANS                         (1'b1),
    
    // SWJDAP
    .nTRST                              (1'b1),
    .SWDITMS                            (SWDI),
    .SWCLKTCK                           (swck),
    .TDI                                (),//.TDI                                (1'b0),
    .CDBGPWRUPACK                       (CDBGPWRUPACK),
    .CDBGPWRUPREQ                       (CDBGPWRUPREQ),
    .SWDO                               (SWDO),
    .SWDOEN                             (SWDOEN),

    // IRQS
    .INTISR                             (IRQ),
    .INTNMI                             (1'b0),
    
    // I-CODE BUS
    .HREADYI                            (HREADYI),
    .HRDATAI                            (HRDATAI),
    .HRESPI                             (HRESPI),
    .IFLUSH                             (1'b0),
    .HADDRI                             (HADDRI),
    .HTRANSI                            (HTRANSI),
    .HSIZEI                             (HSIZEI),
    .HBURSTI                            (HBURSTI),
    .HPROTI                             (HPROTI),

    // D-CODE BUS
    .HREADYD                            (HREADYD),
    .HRDATAD                            (HRDATAD),
    .HRESPD                             (HRESPD),
    .EXRESPD                            (1'b0),
    .HADDRD                             (HADDRD),
    .HTRANSD                            (HTRANSD),
    .HSIZED                             (HSIZED),
    .HBURSTD                            (HBURSTD),
    .HPROTD                             (HPROTD),
    .HWDATAD                            (HWDATAD),
    .HWRITED                            (HWRITED),
    .HMASTERD                           (HMASTERD),

    // SYSTEM BUS
    .HREADYS                            (HREADYS),
    .HRDATAS                            (HRDATAS),
    .HRESPS                             (HRESPS),
    .EXRESPS                            (1'b0),
    .HADDRS                             (HADDRS),
    .HTRANSS                            (HTRANSS),
    .HSIZES                             (HSIZES),
    .HBURSTS                            (HBURSTS),
    .HPROTS                             (HPROTS),
    .HWDATAS                            (HWDATAS),
    .HWRITES                            (HWRITES),
    .HMASTERS                           (HMASTERS),
    .HMASTLOCKS                         (HMASTERLOCKS),

    // SLEEP
    .RXEV                               (1'b0),
    .SLEEPHOLDREQn                      (1'b1),
    .SLEEPING                           (SLEEPing),
    
    // EXTERNAL DEBUG REQUEST
    .EDBGRQ                             (1'b0),
    .DBGRESTART                         (1'b0),
    
    // DAP HMASTER OVERRIDE
    .FIXMASTERTYPE                      (1'b0),

    // WIC
    .WICENREQ                           (1'b0),

    // TIMESTAMP INTERFACE
    .TSVALUEB                           (48'b0),

    // CONFIG - DEBUG
    .DBGEN                              (1'b1),
    .NIDEN                              (1'b1),
    .MPUDISABLE                         (1'b0)
);

//------------------------------------------------------------------------------
// AHB L1 BUS MATRIX
//------------------------------------------------------------------------------


// DMA MASTER
wire    [31:0]  HADDRDM;
wire    [1:0]   HTRANSDM;
wire            HWRITEDM;
wire    [2:0]   HSIZEDM;
wire    [31:0]  HWDATADM;
wire    [2:0]   HBURSTDM;
wire    [3:0]   HPROTDM;
wire            HREADYDM;
wire    [31:0]  HRDATADM;
wire    [1:0]   HRESPDM;
wire    [1:0]   HMASTERDM;
wire            HMASTERLOCKDM;

assign  HADDRDM         =   32'b0;
assign  HTRANSDM        =   2'b0;
assign  HWRITEDM        =   1'b0;
assign  HSIZEDM         =   3'b0;
assign  HWDATADM        =   32'b0;
assign  HBURSTDM        =   3'b0;
assign  HPROTDM         =   4'b0;
assign  HMASTERDM       =   2'b0;
assign  HMASTERLOCKDM   =   1'b0;

// RESERVED MASTER 
wire    [31:0]  HADDRR;
wire    [1:0]   HTRANSR;
wire            WRITER;
wire    [2:0]   HSIZER;
wire    [31:0]  HWDATAR;
wire    [2:0]   HBURSTR;
wire    [3:0]   HPROTR;
wire            HREADYR;
wire    [31:0]  HRDATAR;
wire    [1:0]   HRESPR;
wire    [1:0]   HMASTERR;
wire            HMASTERLOCKR;

assign  HADDRR          =   32'b0;
assign  HTRANSR         =   2'b0;
assign  HWRITER         =   1'b0;
assign  HSIZER          =   3'b0;
assign  HWDATAR         =   32'b0;
assign  HBURSTR         =   3'b0;
assign  HPROTR          =   4'b0;
assign  HMASTERR        =   2'b0;
assign  HMASTERLOCKR    =   1'b0;


wire    [31:0]  HADDR_AHBL1P0;
wire    [1:0]   HTRANS_AHBL1P0;
wire            HWRITE_AHBL1P0;
wire    [2:0]   HSIZE_AHBL1P0;
wire    [31:0]  HWDATA_AHBL1P0;
wire    [2:0]   HBURST_AHBL1P0;
wire    [3:0]   HPROT_AHBL1P0;
wire            HREADY_AHBL1P0;
wire    [31:0]  HRDATA_AHBL1P0;
wire    [1:0]   HRESP_AHBL1P0;
wire            HREADYOUT_AHBL1P0;
wire            HSEL_AHBL1P0;
wire    [3:0]   HMASTER_AHBL1P0;
wire            HMASTERLOCK_AHBL1P0;

wire    [31:0]  HADDR_AHBL1P1;
wire    [1:0]   HTRANS_AHBL1P1;
wire            HWRITE_AHBL1P1;
wire    [2:0]   HSIZE_AHBL1P1;
wire    [31:0]  HWDATA_AHBL1P1;
wire    [2:0]   HBURST_AHBL1P1;
wire    [3:0]   HPROT_AHBL1P1;
wire            HREADY_AHBL1P1;
wire    [31:0]  HRDATA_AHBL1P1;
wire    [1:0]   HRESP_AHBL1P1;
wire            HREADYOUT_AHBL1P1;
wire            HSEL_AHBL1P1;
wire    [3:0]   HMASTER_AHBL1P1;
wire            HMASTERLOCK_AHBL1P1;


cmsdk_L1AhbMtx    L1AhbMtx(
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),

    .REMAP                              (4'b0),

    .HSELS0_SYS                         (1'b1),
    .HADDRS0_SYS                        (HADDRS),
    .HTRANSS0_SYS                       (HTRANSS),
    .HWRITES0_SYS                       (HWRITES),
    .HSIZES0_SYS                        (HSIZES),
    .HBURSTS0_SYS                       (HBURSTS),
    .HPROTS0_SYS                        (HPROTS),
    .HMASTERS0_SYS                      ({2'b0,HMASTERS}),
    .HWDATAS0_SYS                       (HWDATAS),
    .HMASTLOCKS0_SYS                    (HMASTERLOCKS),
    .HREADYS0_SYS                       (HREADYS),
    .HAUSERS0_SYS                       (32'b0),
    .HWUSERS0_SYS                       (32'b0),
    .HREADYOUTS0_SYS                    (HREADYS),
    .HRESPS0_SYS                        (HRESPS),
    .HRUSERS0_SYS                       (),
    .HRDATAS0_SYS                       (HRDATAS),    

    .HSELM0_DTCM                        (HSEL_AHBL1P0),
    .HADDRM0_DTCM                       (HADDR_AHBL1P0),
    .HTRANSM0_DTCM                      (HTRANS_AHBL1P0),
    .HWRITEM0_DTCM                      (HWRITE_AHBL1P0),
    .HSIZEM0_DTCM                       (HSIZE_AHBL1P0),
    .HBURSTM0_DTCM                      (HBURST_AHBL1P0),
    .HPROTM0_DTCM                       (HPROT_AHBL1P0),
    .HMASTERM0_DTCM                     (HMASTER_AHBL1P0),
    .HWDATAM0_DTCM                      (HWDATA_AHBL1P0),
    .HMASTLOCKM0_DTCM                   (HMASTERLOCK_AHBL1P0),
    .HREADYMUXM0_DTCM                   (HREADY_AHBL1P0),
    .HAUSERM0_DTCM                      (),
    .HWUSERM0_DTCM                      (),
    .HRDATAM0_DTCM                      (HRDATA_AHBL1P0),
    .HREADYOUTM0_DTCM                   (HREADYOUT_AHBL1P0),
    .HRESPM0_DTCM                       (HRESP_AHBL1P0),
    .HRUSERM0_DTCM                      (32'b0),
    
    .HSELM1_APB_BRIDGE                  (HSEL_AHBL1P1),
    .HADDRM1_APB_BRIDGE                 (HADDR_AHBL1P1),
    .HTRANSM1_APB_BRIDGE                (HTRANS_AHBL1P1),
    .HWRITEM1_APB_BRIDGE                (HWRITE_AHBL1P1),
    .HSIZEM1_APB_BRIDGE                 (HSIZE_AHBL1P1),
    .HBURSTM1_APB_BRIDGE                (HBURST_AHBL1P1),
    .HPROTM1_APB_BRIDGE                 (HPROT_AHBL1P1),
    .HMASTERM1_APB_BRIDGE               (HMASTER_AHBL1P1),
    .HWDATAM1_APB_BRIDGE                (HWDATA_AHBL1P1),
    .HMASTLOCKM1_APB_BRIDGE             (HMASTERLOCK_AHBL1P1),
    .HREADYMUXM1_APB_BRIDGE             (HREADY_AHBL1P1),
    .HAUSERM1_APB_BRIDGE                (),
    .HWUSERM1_APB_BRIDGE                (),
    .HRDATAM1_APB_BRIDGE                (HRDATA_AHBL1P1),
    .HREADYOUTM1_APB_BRIDGE             (HREADYOUT_AHBL1P1),
    .HRESPM1_APB_BRIDGE                 (HRESP_AHBL1P1),
    .HRUSERM1_APB_BRIDGE                (32'b0),

    .SCANENABLE                         (1'b0),
    .SCANINHCLK                         (1'b0),
    .SCANOUTHCLK                        ()
);


wire    [15:0]  PADDR;    
wire            PENABLE;  
wire            PWRITE;   
wire    [3:0]   PSTRB;    
wire    [2:0]   PPROT;    
wire    [31:0]  PWDATA;   
wire            PSEL;     
wire            APBACTIVE;                  
wire    [31:0]  PRDATA;   
wire            PREADY;  
wire            PSLVERR; 

cmsdk_ahb_to_apb #(
    .ADDRWIDTH                          (16),
    .REGISTER_RDATA                     (1),    
    .REGISTER_WDATA                     (1)
)    ApbBridge  (
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .PCLKEN                             (1'b1),
    .HSEL                               (HSEL_AHBL1P1),
    .HADDR                              (HADDR_AHBL1P1),
    .HTRANS                             (HTRANS_AHBL1P1),
    .HSIZE                              (HSIZE_AHBL1P1),
    .HPROT                              (HPROT_AHBL1P1),
    .HWRITE                             (HWRITE_AHBL1P1),
    .HREADY                             (HREADY_AHBL1P1),
    .HWDATA                             (HWDATA_AHBL1P1),
    .HREADYOUT                          (HREADYOUT_AHBL1P1),
    .HRDATA                             (HRDATA_AHBL1P1),
    .HRESP                              (HRESP_AHBL1P1[0]),        
    .PADDR                              (PADDR),
    .PENABLE                            (PENABLE),
    .PWRITE                             (PWRITE),
    .PSTRB                              (PSTRB),
    .PPROT                              (PPROT),
    .PWDATA                             (PWDATA),
    .PSEL                               (PSEL),
    .APBACTIVE                          (APBACTIVE),
    .PRDATA                             (PRDATA),
    .PREADY                             (PREADY),
    .PSLVERR                            (PSLVERR)                      
);
assign  HRESP_AHBL1P1[1]    =   1'b0;

wire            PSEL_APBP0;
wire            PREADY_APBP0;
wire    [31:0]  PRDATA_APBP0;
wire            PSLVERR_APBP0;
wire            PSEL_APBP1;
wire            PREADY_APBP1;
wire    [31:0]  PRDATA_APBP1;
wire            PSLVERR_APBP1;
wire            PSEL_APBP2;
wire            PREADY_APBP2;
wire    [31:0]  PRDATA_APBP2;
wire            PSLVERR_APBP2;
wire            PSEL_APBP3;
wire            PREADY_APBP3;
wire    [31:0]  PRDATA_APBP3;
wire            PSLVERR_APBP3;
wire            PSEL_APBP4;
wire            PREADY_APBP4;
wire    [31:0]  PRDATA_APBP4;
wire            PSLVERR_APBP4;


cmsdk_apb_slave_mux #(
    .PORT0_ENABLE                       (1),    // LEDS
    .PORT1_ENABLE                       (0),    // BUTTON
    .PORT2_ENABLE                       (1),    // UART
    .PORT3_ENABLE                       (1),    // TIMER
    .PORT4_ENABLE                       (1),    // IGNITER
    .PORT5_ENABLE                       (0),
    .PORT6_ENABLE                       (0),
    .PORT7_ENABLE                       (0),
    .PORT8_ENABLE                       (0),
    .PORT9_ENABLE                       (0),
    .PORT10_ENABLE                      (0),
    .PORT11_ENABLE                      (0),
    .PORT12_ENABLE                      (0),
    .PORT13_ENABLE                      (0),
    .PORT14_ENABLE                      (0),
    .PORT15_ENABLE                      (0)
)   ApbSystem   (
    .DECODE4BIT                         (PADDR[15:12]),
    .PSEL                               (PSEL),

    .PSEL0                              (PSEL_APBP0),
    .PREADY0                            (PREADY_APBP0),
    .PRDATA0                            (PRDATA_APBP0),
    .PSLVERR0                           (PSLVERR_APBP0),
    
    .PSEL1                              (PSEL_APBP1),
    .PREADY1                            (PREADY_APBP1),
    .PRDATA1                            (PRDATA_APBP1),
    .PSLVERR1                           (PSLVERR_APBP1),

    .PSEL2                              (PSEL_APBP2),
    .PREADY2                            (PREADY_APBP2),
    .PRDATA2                            (PRDATA_APBP2),
    .PSLVERR2                           (PSLVERR_APBP2),

    .PSEL3                              (PSEL_APBP3),
    .PREADY3                            (PREADY_APBP3),
    .PRDATA3                            (PRDATA_APBP3),
    .PSLVERR3                           (PSLVERR_APBP3),

    .PSEL4                              (PSEL_APBP4),
    .PREADY4                            (PREADY_APBP4),
    .PRDATA4                            (PRDATA_APBP4),
    .PSLVERR4                           (PSLVERR_APBP4),

    .PSEL5                              (),
    .PREADY5                            (1'b0),
    .PRDATA5                            (32'b0),
    .PSLVERR5                           (1'b0),

    .PSEL6                              (),
    .PREADY6                            (1'b0),
    .PRDATA6                            (32'b0),
    .PSLVERR6                           (1'b0),

    .PSEL7                              (),
    .PREADY7                            (1'b0),
    .PRDATA7                            (32'b0),
    .PSLVERR7                           (1'b0),

    .PSEL8                              (),
    .PREADY8                            (1'b0),
    .PRDATA8                            (32'b0),
    .PSLVERR8                           (1'b0),

    .PSEL9                              (),
    .PREADY9                            (1'b0),
    .PRDATA9                            (32'b0),
    .PSLVERR9                           (1'b0),

    .PSEL10                             (),
    .PREADY10                           (1'b0),
    .PRDATA10                           (32'b0),
    .PSLVERR10                          (1'b0),

    .PSEL11                             (),
    .PREADY11                           (1'b0),
    .PRDATA11                           (32'b0),
    .PSLVERR11                          (1'b0),

    .PSEL12                             (),
    .PREADY12                           (1'b0),
    .PRDATA12                           (32'b0),
    .PSLVERR12                          (1'b0),
    
    .PSEL13                             (),
    .PREADY13                           (1'b0),
    .PRDATA13                           (32'b0),
    .PSLVERR13                          (1'b0),

    .PSEL14                             (),
    .PREADY14                           (1'b0),
    .PRDATA14                           (32'b0),
    .PSLVERR14                          (1'b0),

    .PSEL15                             (),
    .PREADY15                           (1'b0),
    .PRDATA15                           (32'b0),
    .PSLVERR15                          (1'b0),

    .PREADY                             (PREADY),
    .PRDATA                             (PRDATA),
    .PSLVERR                            (PSLVERR)

);


//------------------------------------------------------------------------------
// AHB DTCM
//------------------------------------------------------------------------------
ahblite_axi_bridge_0 AHB2AXI_bridge(
    .s_ahb_hclk                         (clk                    ),
    .s_ahb_hresetn                      (cpuresetn              ),
    .s_ahb_hsel                         (HSEL_AHBL1P0           ),
    .s_ahb_haddr                        (HADDR_AHBL1P0          ),
    .s_ahb_hprot                        (HPROT_AHBL1P0          ),
    .s_ahb_htrans                       (HTRANS_AHBL1P0         ),
    .s_ahb_hsize                        (HSIZE_AHBL1P0          ),
    .s_ahb_hwrite                       (HWRITE_AHBL1P0         ),
    .s_ahb_hburst                       (HBURST_AHBL1P0         ),
    .s_ahb_hwdata                       (HWDATA_AHBL1P0         ),
    .s_ahb_hready_out                   (HREADYOUT_AHBL1P0      ),
    .s_ahb_hready_in                    (HREADYOUT_AHBL1P0      ),
    .s_ahb_hrdata                       (HRDATA_AHBL1P0         ),
    .s_ahb_hresp                        (HRESP_AHBL1P0[0]       ),

    .m_axi_awlen                        (ITCN_S00_AXI_AWLEN     ),
    .m_axi_awsize                       (ITCN_S00_AXI_AWSIZE    ),
    .m_axi_awburst                      (ITCN_S00_AXI_AWBURST   ),
    .m_axi_awcache                      (ITCN_S00_AXI_AWCACHE   ),
    .m_axi_awaddr                       (ITCN_S00_AXI_AWADDR    ),
    .m_axi_awprot                       (ITCN_S00_AXI_AWPROT    ),
    .m_axi_awvalid                      (ITCN_S00_AXI_AWVALID   ),
    .m_axi_awready                      (ITCN_S00_AXI_AWREADY   ),
    .m_axi_awlock                       (ITCN_S00_AXI_AWLOCK    ),
    .m_axi_wdata                        (ITCN_S00_AXI_WDATA     ),
    .m_axi_wstrb                        (ITCN_S00_AXI_WSTRB     ),
    .m_axi_wlast                        (ITCN_S00_AXI_WLAST     ),
    .m_axi_wvalid                       (ITCN_S00_AXI_WVALID    ),
    .m_axi_wready                       (ITCN_S00_AXI_WREADY    ),
    .m_axi_bresp                        (ITCN_S00_AXI_BRESP     ),
    .m_axi_bvalid                       (ITCN_S00_AXI_BVALID    ),
    .m_axi_bready                       (ITCN_S00_AXI_BREADY    ),
    .m_axi_arlen                        (ITCN_S00_AXI_ARLEN     ), 
    .m_axi_arsize                       (ITCN_S00_AXI_ARSIZE    ),
    .m_axi_arburst                      (ITCN_S00_AXI_ARBURST   ), 
    .m_axi_arprot                       (ITCN_S00_AXI_ARPROT    ),
    .m_axi_arcache                      (ITCN_S00_AXI_ARCACHE   ), 
    .m_axi_arvalid                      (ITCN_S00_AXI_ARVALID   ),
    .m_axi_araddr                       (ITCN_S00_AXI_ARADDR    ), 
    .m_axi_arlock                       (ITCN_S00_AXI_ARLOCK    ),
    .m_axi_arready                      (ITCN_S00_AXI_ARREADY   ), 
    .m_axi_rdata                        (ITCN_S00_AXI_RDATA     ),
    .m_axi_rresp                        (ITCN_S00_AXI_RRESP     ),
    .m_axi_rvalid                       (ITCN_S00_AXI_RVALID    ),
    .m_axi_rlast                        (ITCN_S00_AXI_RLAST     ),
    .m_axi_rready                       (ITCN_S00_AXI_RREADY    )
);
assign  HRESP_AHBL1P0[1]    =   1'b0;

// axi interconnect signals
wire                        ITCN_S00_AXI_ARESET_OUT_N;
wire                        ITCN_S00_AXI_AWID;
wire [31:0]                 ITCN_S00_AXI_AWADDR;
wire [7:0]                  ITCN_S00_AXI_AWLEN;
wire [2:0]                  ITCN_S00_AXI_AWSIZE;
wire [1:0]                  ITCN_S00_AXI_AWBURST;
wire                        ITCN_S00_AXI_AWLOCK;
wire [3:0]                  ITCN_S00_AXI_AWCACHE;
wire [2:0]                  ITCN_S00_AXI_AWPROT;
wire [3:0]                  ITCN_S00_AXI_AWQOS;
wire                        ITCN_S00_AXI_AWVALID;
wire                        ITCN_S00_AXI_AWREADY;
wire [31:0]                 ITCN_S00_AXI_WDATA;
wire [3:0]                  ITCN_S00_AXI_WSTRB;
wire                        ITCN_S00_AXI_WLAST;
wire                        ITCN_S00_AXI_WVALID;
wire                        ITCN_S00_AXI_WREADY;
wire                        ITCN_S00_AXI_BID;
wire [1:0]                  ITCN_S00_AXI_BRESP;
wire                        ITCN_S00_AXI_BVALID;
wire                        ITCN_S00_AXI_BREADY;
wire                        ITCN_S00_AXI_ARID;
wire [31:0]                 ITCN_S00_AXI_ARADDR;
wire [7:0]                  ITCN_S00_AXI_ARLEN;
wire [2:0]                  ITCN_S00_AXI_ARSIZE;
wire [1:0]                  ITCN_S00_AXI_ARBURST;
wire                        ITCN_S00_AXI_ARLOCK;
wire [3:0]                  ITCN_S00_AXI_ARCACHE;
wire [2:0]                  ITCN_S00_AXI_ARPROT;
wire [3:0]                  ITCN_S00_AXI_ARQOS;
wire                        ITCN_S00_AXI_ARVALID;
wire                        ITCN_S00_AXI_ARREADY;
wire                        ITCN_S00_AXI_RID;
wire [31:0]                 ITCN_S00_AXI_RDATA;
wire [1:0]                  ITCN_S00_AXI_RRESP;
wire                        ITCN_S00_AXI_RLAST;
wire                        ITCN_S00_AXI_RVALID;
wire                        ITCN_S00_AXI_RREADY;

wire                        ITCN_S01_AXI_ARESET_OUT_N;
wire                        ITCN_S01_AXI_AWID;
wire [31:0]                 ITCN_S01_AXI_AWADDR;
wire [7:0]                  ITCN_S01_AXI_AWLEN;
wire [2:0]                  ITCN_S01_AXI_AWSIZE;
wire [1:0]                  ITCN_S01_AXI_AWBURST;
wire                        ITCN_S01_AXI_AWLOCK;
wire [3:0]                  ITCN_S01_AXI_AWCACHE;
wire [2:0]                  ITCN_S01_AXI_AWPROT;
wire [3:0]                  ITCN_S01_AXI_AWQOS;
wire                        ITCN_S01_AXI_AWVALID;
wire                        ITCN_S01_AXI_AWREADY;
wire [MEM_DATA_BITS-1:0]    ITCN_S01_AXI_WDATA; // 
wire [3:0]                  ITCN_S01_AXI_WSTRB;
wire                        ITCN_S01_AXI_WLAST;
wire                        ITCN_S01_AXI_WVALID;
wire                        ITCN_S01_AXI_WREADY;
wire                        ITCN_S01_AXI_BID;
wire [1:0]                  ITCN_S01_AXI_BRESP;
wire                        ITCN_S01_AXI_BVALID;
wire                        ITCN_S01_AXI_BREADY;
wire                        ITCN_S01_AXI_ARID;
wire [31:0]                 ITCN_S01_AXI_ARADDR;
wire [7:0]                  ITCN_S01_AXI_ARLEN;
wire [2:0]                  ITCN_S01_AXI_ARSIZE;
wire [1:0]                  ITCN_S01_AXI_ARBURST;
wire                        ITCN_S01_AXI_ARLOCK;
wire [3:0]                  ITCN_S01_AXI_ARCACHE;
wire [2:0]                  ITCN_S01_AXI_ARPROT;
wire [3:0]                  ITCN_S01_AXI_ARQOS;
wire                        ITCN_S01_AXI_ARVALID;
wire                        ITCN_S01_AXI_ARREADY;
wire                        ITCN_S01_AXI_RID;
wire [MEM_DATA_BITS-1:0]    ITCN_S01_AXI_RDATA; // 
wire [1:0]                  ITCN_S01_AXI_RRESP;
wire                        ITCN_S01_AXI_RLAST;
wire                        ITCN_S01_AXI_RVALID;
wire                        ITCN_S01_AXI_RREADY;

wire                        ITCN_S02_AXI_ARESET_OUT_N;
wire                        ITCN_S02_AXI_AWID;
wire [31:0]                 ITCN_S02_AXI_AWADDR;
wire [7:0]                  ITCN_S02_AXI_AWLEN;
wire [2:0]                  ITCN_S02_AXI_AWSIZE;
wire [1:0]                  ITCN_S02_AXI_AWBURST;
wire                        ITCN_S02_AXI_AWLOCK;
wire [3:0]                  ITCN_S02_AXI_AWCACHE;
wire [2:0]                  ITCN_S02_AXI_AWPROT;
wire [3:0]                  ITCN_S02_AXI_AWQOS;
wire                        ITCN_S02_AXI_AWVALID;
wire                        ITCN_S02_AXI_AWREADY;
wire [MEM_DATA_BITS-1:0]    ITCN_S02_AXI_WDATA; // 
wire [3:0]                  ITCN_S02_AXI_WSTRB;
wire                        ITCN_S02_AXI_WLAST;
wire                        ITCN_S02_AXI_WVALID;
wire                        ITCN_S02_AXI_WREADY;
wire                        ITCN_S02_AXI_BID;
wire [1:0]                  ITCN_S02_AXI_BRESP;
wire                        ITCN_S02_AXI_BVALID;
wire                        ITCN_S02_AXI_BREADY;
wire                        ITCN_S02_AXI_ARID;
wire [31:0]                 ITCN_S02_AXI_ARADDR;
wire [7:0]                  ITCN_S02_AXI_ARLEN;
wire [2:0]                  ITCN_S02_AXI_ARSIZE;
wire [1:0]                  ITCN_S02_AXI_ARBURST;
wire                        ITCN_S02_AXI_ARLOCK;
wire [3:0]                  ITCN_S02_AXI_ARCACHE;
wire [2:0]                  ITCN_S02_AXI_ARPROT;
wire [3:0]                  ITCN_S02_AXI_ARQOS;
wire                        ITCN_S02_AXI_ARVALID;
wire                        ITCN_S02_AXI_ARREADY;
wire                        ITCN_S02_AXI_RID;
wire [MEM_DATA_BITS-1:0]    ITCN_S02_AXI_RDATA; // 
wire [1:0]                  ITCN_S02_AXI_RRESP;
wire                        ITCN_S02_AXI_RLAST;
wire                        ITCN_S02_AXI_RVALID;
wire                        ITCN_S02_AXI_RREADY;

wire                        ITCN_S03_AXI_ARESET_OUT_N;
wire                        ITCN_S03_AXI_AWID;
wire [31:0]                 ITCN_S03_AXI_AWADDR;
wire [7:0]                  ITCN_S03_AXI_AWLEN;
wire [2:0]                  ITCN_S03_AXI_AWSIZE;
wire [1:0]                  ITCN_S03_AXI_AWBURST;
wire                        ITCN_S03_AXI_AWLOCK;
wire [3:0]                  ITCN_S03_AXI_AWCACHE;
wire [2:0]                  ITCN_S03_AXI_AWPROT;
wire [3:0]                  ITCN_S03_AXI_AWQOS;
wire                        ITCN_S03_AXI_AWVALID;
wire                        ITCN_S03_AXI_AWREADY;
wire [MEM_DATA_BITS-1:0]    ITCN_S03_AXI_WDATA; // 
wire [3:0]                  ITCN_S03_AXI_WSTRB;
wire                        ITCN_S03_AXI_WLAST;
wire                        ITCN_S03_AXI_WVALID;
wire                        ITCN_S03_AXI_WREADY;
wire                        ITCN_S03_AXI_BID;
wire [1:0]                  ITCN_S03_AXI_BRESP;
wire                        ITCN_S03_AXI_BVALID;
wire                        ITCN_S03_AXI_BREADY;
wire                        ITCN_S03_AXI_ARID;
wire [31:0]                 ITCN_S03_AXI_ARADDR;
wire [7:0]                  ITCN_S03_AXI_ARLEN;
wire [2:0]                  ITCN_S03_AXI_ARSIZE;
wire [1:0]                  ITCN_S03_AXI_ARBURST;
wire                        ITCN_S03_AXI_ARLOCK;
wire [3:0]                  ITCN_S03_AXI_ARCACHE;
wire [2:0]                  ITCN_S03_AXI_ARPROT;
wire [3:0]                  ITCN_S03_AXI_ARQOS;
wire                        ITCN_S03_AXI_ARVALID;
wire                        ITCN_S03_AXI_ARREADY;
wire                        ITCN_S03_AXI_RID;
wire [MEM_DATA_BITS-1:0]    ITCN_S03_AXI_RDATA; // 
wire [1:0]                  ITCN_S03_AXI_RRESP;
wire                        ITCN_S03_AXI_RLAST;
wire                        ITCN_S03_AXI_RVALID;
wire                        ITCN_S03_AXI_RREADY;

wire                        ITCN_M00_AXI_ARESET_OUT_N;
wire [3:0]                  ITCN_M00_AXI_AWID;
wire [31:0]                 ITCN_M00_AXI_AWADDR;
wire [7:0]                  ITCN_M00_AXI_AWLEN;
wire [2:0]                  ITCN_M00_AXI_AWSIZE;
wire [1:0]                  ITCN_M00_AXI_AWBURST;
wire                        ITCN_M00_AXI_AWLOCK;
wire [3:0]                  ITCN_M00_AXI_AWCACHE;
wire [2:0]                  ITCN_M00_AXI_AWPROT;
wire [3:0]                  ITCN_M00_AXI_AWQOS;
wire                        ITCN_M00_AXI_AWVALID;
wire                        ITCN_M00_AXI_AWREADY;
wire [31:0]                 ITCN_M00_AXI_WDATA;
wire [3:0]                  ITCN_M00_AXI_WSTRB;
wire                        ITCN_M00_AXI_WLAST;
wire                        ITCN_M00_AXI_WVALID;
wire                        ITCN_M00_AXI_WREADY;
wire [3:0]                  ITCN_M00_AXI_BID;
wire [1:0]                  ITCN_M00_AXI_BRESP;
wire                        ITCN_M00_AXI_BVALID;
wire                        ITCN_M00_AXI_BREADY;
wire [3:0]                  ITCN_M00_AXI_ARID;
wire [31:0]                 ITCN_M00_AXI_ARADDR;
wire [7:0]                  ITCN_M00_AXI_ARLEN;
wire [2:0]                  ITCN_M00_AXI_ARSIZE;
wire [1:0]                  ITCN_M00_AXI_ARBURST;
wire                        ITCN_M00_AXI_ARLOCK;
wire [3:0]                  ITCN_M00_AXI_ARCACHE;
wire [2:0]                  ITCN_M00_AXI_ARPROT;
wire [3:0]                  ITCN_M00_AXI_ARQOS;
wire                        ITCN_M00_AXI_ARVALID;
wire                        ITCN_M00_AXI_ARREADY;
wire [3:0]                  ITCN_M00_AXI_RID;
wire [31:0]                 ITCN_M00_AXI_RDATA;
wire [1:0]                  ITCN_M00_AXI_RRESP;
wire                        ITCN_M00_AXI_RLAST;
wire                        ITCN_M00_AXI_RVALID;
wire                        ITCN_M00_AXI_RREADY;
axi_interconnect_0  AXI_interconnect(
    .INTERCONNECT_ACLK                  (ui_clk                         ),
    .INTERCONNECT_ARESETN               (cpuresetn                      ), //mnd: low for at least 16 cycles

    .S00_AXI_ARESET_OUT_N               (ITCN_S00_AXI_ARESET_OUT_N      ), // 
    .S00_AXI_ACLK                       (clk                            ),
    .S00_AXI_AWID                       (ITCN_S00_AXI_AWID              ), //
    .S00_AXI_AWADDR                     (ITCN_S00_AXI_AWADDR            ),
    .S00_AXI_AWLEN                      (ITCN_S00_AXI_AWLEN             ),
    .S00_AXI_AWSIZE                     (ITCN_S00_AXI_AWSIZE            ),
    .S00_AXI_AWBURST                    (ITCN_S00_AXI_AWBURST           ),
    .S00_AXI_AWLOCK                     (ITCN_S00_AXI_AWLOCK            ),
    .S00_AXI_AWCACHE                    (ITCN_S00_AXI_AWCACHE           ),
    .S00_AXI_AWPROT                     (ITCN_S00_AXI_AWPROT            ),
    .S00_AXI_AWQOS                      (ITCN_S00_AXI_AWQOS             ), // 
    .S00_AXI_AWVALID                    (ITCN_S00_AXI_AWVALID           ),
    .S00_AXI_AWREADY                    (ITCN_S00_AXI_AWREADY           ),
    .S00_AXI_WDATA                      (ITCN_S00_AXI_WDATA             ),
    .S00_AXI_WSTRB                      (ITCN_S00_AXI_WSTRB             ),
    .S00_AXI_WLAST                      (ITCN_S00_AXI_WLAST             ),
    .S00_AXI_WVALID                     (ITCN_S00_AXI_WVALID            ),
    .S00_AXI_WREADY                     (ITCN_S00_AXI_WREADY            ),
    .S00_AXI_BID                        (ITCN_S00_AXI_BID               ), //
    .S00_AXI_BRESP                      (ITCN_S00_AXI_BRESP             ),
    .S00_AXI_BVALID                     (ITCN_S00_AXI_BVALID            ),
    .S00_AXI_BREADY                     (ITCN_S00_AXI_BREADY            ),
    .S00_AXI_ARID                       (ITCN_S00_AXI_ARID              ), //
    .S00_AXI_ARADDR                     (ITCN_S00_AXI_ARADDR            ),
    .S00_AXI_ARLEN                      (ITCN_S00_AXI_ARLEN             ),
    .S00_AXI_ARSIZE                     (ITCN_S00_AXI_ARSIZE            ),
    .S00_AXI_ARBURST                    (ITCN_S00_AXI_ARBURST           ),
    .S00_AXI_ARLOCK                     (ITCN_S00_AXI_ARLOCK            ),
    .S00_AXI_ARCACHE                    (ITCN_S00_AXI_ARCACHE           ),
    .S00_AXI_ARPROT                     (ITCN_S00_AXI_ARPROT            ),
    .S00_AXI_ARQOS                      (ITCN_S00_AXI_ARQOS             ), //
    .S00_AXI_ARVALID                    (ITCN_S00_AXI_ARVALID           ),
    .S00_AXI_ARREADY                    (ITCN_S00_AXI_ARREADY           ),
    .S00_AXI_RID                        (ITCN_S00_AXI_RID               ), //
    .S00_AXI_RDATA                      (ITCN_S00_AXI_RDATA             ),
    .S00_AXI_RRESP                      (ITCN_S00_AXI_RRESP             ),
    .S00_AXI_RLAST                      (ITCN_S00_AXI_RLAST             ),
    .S00_AXI_RVALID                     (ITCN_S00_AXI_RVALID            ),
    .S00_AXI_RREADY                     (ITCN_S00_AXI_RREADY            ),

    .S01_AXI_ARESET_OUT_N               (ITCN_S01_AXI_ARESET_OUT_N      ), 
    .S01_AXI_ACLK                       (ui_clk                         ),
    .S01_AXI_AWID                       (ITCN_S01_AXI_AWID              ), 
    .S01_AXI_AWADDR                     (ITCN_S01_AXI_AWADDR            ),
    .S01_AXI_AWLEN                      (ITCN_S01_AXI_AWLEN             ),
    .S01_AXI_AWSIZE                     (ITCN_S01_AXI_AWSIZE            ),
    .S01_AXI_AWBURST                    (ITCN_S01_AXI_AWBURST           ),
    .S01_AXI_AWLOCK                     (ITCN_S01_AXI_AWLOCK            ),
    .S01_AXI_AWCACHE                    (ITCN_S01_AXI_AWCACHE           ),
    .S01_AXI_AWPROT                     (ITCN_S01_AXI_AWPROT            ),
    .S01_AXI_AWQOS                      (ITCN_S01_AXI_AWQOS             ), 
    .S01_AXI_AWVALID                    (ITCN_S01_AXI_AWVALID           ),
    .S01_AXI_AWREADY                    (ITCN_S01_AXI_AWREADY           ),
    .S01_AXI_WDATA                      (ITCN_S01_AXI_WDATA             ),
    .S01_AXI_WSTRB                      (ITCN_S01_AXI_WSTRB             ),
    .S01_AXI_WLAST                      (ITCN_S01_AXI_WLAST             ),
    .S01_AXI_WVALID                     (ITCN_S01_AXI_WVALID            ),
    .S01_AXI_WREADY                     (ITCN_S01_AXI_WREADY            ),
    .S01_AXI_BID                        (ITCN_S01_AXI_BID               ), 
    .S01_AXI_BRESP                      (ITCN_S01_AXI_BRESP             ),
    .S01_AXI_BVALID                     (ITCN_S01_AXI_BVALID            ),
    .S01_AXI_BREADY                     (ITCN_S01_AXI_BREADY            ),
    .S01_AXI_ARID                       (ITCN_S01_AXI_ARID              ), 
    .S01_AXI_ARADDR                     (ITCN_S01_AXI_ARADDR            ),
    .S01_AXI_ARLEN                      (ITCN_S01_AXI_ARLEN             ),
    .S01_AXI_ARSIZE                     (ITCN_S01_AXI_ARSIZE            ),
    .S01_AXI_ARBURST                    (ITCN_S01_AXI_ARBURST           ),
    .S01_AXI_ARLOCK                     (ITCN_S01_AXI_ARLOCK            ),
    .S01_AXI_ARCACHE                    (ITCN_S01_AXI_ARCACHE           ),
    .S01_AXI_ARPROT                     (ITCN_S01_AXI_ARPROT            ),
    .S01_AXI_ARQOS                      (ITCN_S01_AXI_ARQOS             ), 
    .S01_AXI_ARVALID                    (ITCN_S01_AXI_ARVALID           ),
    .S01_AXI_ARREADY                    (ITCN_S01_AXI_ARREADY           ),
    .S01_AXI_RID                        (ITCN_S01_AXI_RID               ), 
    .S01_AXI_RDATA                      (ITCN_S01_AXI_RDATA             ),
    .S01_AXI_RRESP                      (ITCN_S01_AXI_RRESP             ),
    .S01_AXI_RLAST                      (ITCN_S01_AXI_RLAST             ),
    .S01_AXI_RVALID                     (ITCN_S01_AXI_RVALID            ),
    .S01_AXI_RREADY                     (ITCN_S01_AXI_RREADY            ),

    .S02_AXI_ARESET_OUT_N               (ITCN_S02_AXI_ARESET_OUT_N      ), 
    .S02_AXI_ACLK                       (ui_clk                         ),
    .S02_AXI_AWID                       (ITCN_S02_AXI_AWID              ), 
    .S02_AXI_AWADDR                     (ITCN_S02_AXI_AWADDR            ),
    .S02_AXI_AWLEN                      (ITCN_S02_AXI_AWLEN             ),
    .S02_AXI_AWSIZE                     (ITCN_S02_AXI_AWSIZE            ),
    .S02_AXI_AWBURST                    (ITCN_S02_AXI_AWBURST           ),
    .S02_AXI_AWLOCK                     (ITCN_S02_AXI_AWLOCK            ),
    .S02_AXI_AWCACHE                    (ITCN_S02_AXI_AWCACHE           ),
    .S02_AXI_AWPROT                     (ITCN_S02_AXI_AWPROT            ),
    .S02_AXI_AWQOS                      (ITCN_S02_AXI_AWQOS             ), 
    .S02_AXI_AWVALID                    (ITCN_S02_AXI_AWVALID           ),
    .S02_AXI_AWREADY                    (ITCN_S02_AXI_AWREADY           ),
    .S02_AXI_WDATA                      (ITCN_S02_AXI_WDATA             ),
    .S02_AXI_WSTRB                      (ITCN_S02_AXI_WSTRB             ),
    .S02_AXI_WLAST                      (ITCN_S02_AXI_WLAST             ),
    .S02_AXI_WVALID                     (ITCN_S02_AXI_WVALID            ),
    .S02_AXI_WREADY                     (ITCN_S02_AXI_WREADY            ),
    .S02_AXI_BID                        (ITCN_S02_AXI_BID               ), 
    .S02_AXI_BRESP                      (ITCN_S02_AXI_BRESP             ),
    .S02_AXI_BVALID                     (ITCN_S02_AXI_BVALID            ),
    .S02_AXI_BREADY                     (ITCN_S02_AXI_BREADY            ),
    .S02_AXI_ARID                       (ITCN_S02_AXI_ARID              ), 
    .S02_AXI_ARADDR                     (ITCN_S02_AXI_ARADDR            ),
    .S02_AXI_ARLEN                      (ITCN_S02_AXI_ARLEN             ),
    .S02_AXI_ARSIZE                     (ITCN_S02_AXI_ARSIZE            ),
    .S02_AXI_ARBURST                    (ITCN_S02_AXI_ARBURST           ),
    .S02_AXI_ARLOCK                     (ITCN_S02_AXI_ARLOCK            ),
    .S02_AXI_ARCACHE                    (ITCN_S02_AXI_ARCACHE           ),
    .S02_AXI_ARPROT                     (ITCN_S02_AXI_ARPROT            ),
    .S02_AXI_ARQOS                      (ITCN_S02_AXI_ARQOS             ), 
    .S02_AXI_ARVALID                    (ITCN_S02_AXI_ARVALID           ),
    .S02_AXI_ARREADY                    (ITCN_S02_AXI_ARREADY           ),
    .S02_AXI_RID                        (ITCN_S02_AXI_RID               ), 
    .S02_AXI_RDATA                      (ITCN_S02_AXI_RDATA             ),
    .S02_AXI_RRESP                      (ITCN_S02_AXI_RRESP             ),
    .S02_AXI_RLAST                      (ITCN_S02_AXI_RLAST             ),
    .S02_AXI_RVALID                     (ITCN_S02_AXI_RVALID            ),
    .S02_AXI_RREADY                     (ITCN_S02_AXI_RREADY            ),

    .S03_AXI_ARESET_OUT_N               (ITCN_S03_AXI_ARESET_OUT_N      ), 
    .S03_AXI_ACLK                       (ui_clk                         ),
    .S03_AXI_AWID                       (ITCN_S03_AXI_AWID              ), 
    .S03_AXI_AWADDR                     (ITCN_S03_AXI_AWADDR            ),
    .S03_AXI_AWLEN                      (ITCN_S03_AXI_AWLEN             ),
    .S03_AXI_AWSIZE                     (ITCN_S03_AXI_AWSIZE            ),
    .S03_AXI_AWBURST                    (ITCN_S03_AXI_AWBURST           ),
    .S03_AXI_AWLOCK                     (ITCN_S03_AXI_AWLOCK            ),
    .S03_AXI_AWCACHE                    (ITCN_S03_AXI_AWCACHE           ),
    .S03_AXI_AWPROT                     (ITCN_S03_AXI_AWPROT            ),
    .S03_AXI_AWQOS                      (ITCN_S03_AXI_AWQOS             ), 
    .S03_AXI_AWVALID                    (ITCN_S03_AXI_AWVALID           ),
    .S03_AXI_AWREADY                    (ITCN_S03_AXI_AWREADY           ),
    .S03_AXI_WDATA                      (ITCN_S03_AXI_WDATA             ),
    .S03_AXI_WSTRB                      (ITCN_S03_AXI_WSTRB             ),
    .S03_AXI_WLAST                      (ITCN_S03_AXI_WLAST             ),
    .S03_AXI_WVALID                     (ITCN_S03_AXI_WVALID            ),
    .S03_AXI_WREADY                     (ITCN_S03_AXI_WREADY            ),
    .S03_AXI_BID                        (ITCN_S03_AXI_BID               ), 
    .S03_AXI_BRESP                      (ITCN_S03_AXI_BRESP             ),
    .S03_AXI_BVALID                     (ITCN_S03_AXI_BVALID            ),
    .S03_AXI_BREADY                     (ITCN_S03_AXI_BREADY            ),
    .S03_AXI_ARID                       (ITCN_S03_AXI_ARID              ), 
    .S03_AXI_ARADDR                     (ITCN_S03_AXI_ARADDR            ),
    .S03_AXI_ARLEN                      (ITCN_S03_AXI_ARLEN             ),
    .S03_AXI_ARSIZE                     (ITCN_S03_AXI_ARSIZE            ),
    .S03_AXI_ARBURST                    (ITCN_S03_AXI_ARBURST           ),
    .S03_AXI_ARLOCK                     (ITCN_S03_AXI_ARLOCK            ),
    .S03_AXI_ARCACHE                    (ITCN_S03_AXI_ARCACHE           ),
    .S03_AXI_ARPROT                     (ITCN_S03_AXI_ARPROT            ),
    .S03_AXI_ARQOS                      (ITCN_S03_AXI_ARQOS             ), 
    .S03_AXI_ARVALID                    (ITCN_S03_AXI_ARVALID           ),
    .S03_AXI_ARREADY                    (ITCN_S03_AXI_ARREADY           ),
    .S03_AXI_RID                        (ITCN_S03_AXI_RID               ), 
    .S03_AXI_RDATA                      (ITCN_S03_AXI_RDATA             ),
    .S03_AXI_RRESP                      (ITCN_S03_AXI_RRESP             ),
    .S03_AXI_RLAST                      (ITCN_S03_AXI_RLAST             ),
    .S03_AXI_RVALID                     (ITCN_S03_AXI_RVALID            ),
    .S03_AXI_RREADY                     (ITCN_S03_AXI_RREADY            ),

    .M00_AXI_ARESET_OUT_N               (ITCN_M00_AXI_ARESET_OUT_N      ),
    .M00_AXI_ACLK                       (ui_clk                         ),
    .M00_AXI_AWID                       (ITCN_M00_AXI_AWID              ),
    .M00_AXI_AWADDR                     (ITCN_M00_AXI_AWADDR            ),
    .M00_AXI_AWLEN                      (ITCN_M00_AXI_AWLEN             ),
    .M00_AXI_AWSIZE                     (ITCN_M00_AXI_AWSIZE            ),
    .M00_AXI_AWBURST                    (ITCN_M00_AXI_AWBURST           ),
    .M00_AXI_AWLOCK                     (ITCN_M00_AXI_AWLOCK            ),
    .M00_AXI_AWCACHE                    (ITCN_M00_AXI_AWCACHE           ),
    .M00_AXI_AWPROT                     (ITCN_M00_AXI_AWPROT            ),
    .M00_AXI_AWQOS                      (ITCN_M00_AXI_AWQOS             ),
    .M00_AXI_AWVALID                    (ITCN_M00_AXI_AWVALID           ),
    .M00_AXI_AWREADY                    (ITCN_M00_AXI_AWREADY           ),
    .M00_AXI_WDATA                      (ITCN_M00_AXI_WDATA             ),
    .M00_AXI_WSTRB                      (ITCN_M00_AXI_WSTRB             ),
    .M00_AXI_WLAST                      (ITCN_M00_AXI_WLAST             ),
    .M00_AXI_WVALID                     (ITCN_M00_AXI_WVALID            ),
    .M00_AXI_WREADY                     (ITCN_M00_AXI_WREADY            ),
    .M00_AXI_BID                        (ITCN_M00_AXI_BID               ),
    .M00_AXI_BRESP                      (ITCN_M00_AXI_BRESP             ),
    .M00_AXI_BVALID                     (ITCN_M00_AXI_BVALID            ),
    .M00_AXI_BREADY                     (ITCN_M00_AXI_BREADY            ),
    .M00_AXI_ARID                       (ITCN_M00_AXI_ARID              ),
    .M00_AXI_ARADDR                     (ITCN_M00_AXI_ARADDR            ),
    .M00_AXI_ARLEN                      (ITCN_M00_AXI_ARLEN             ),
    .M00_AXI_ARSIZE                     (ITCN_M00_AXI_ARSIZE            ),
    .M00_AXI_ARBURST                    (ITCN_M00_AXI_ARBURST           ),
    .M00_AXI_ARLOCK                     (ITCN_M00_AXI_ARLOCK            ),
    .M00_AXI_ARCACHE                    (ITCN_M00_AXI_ARCACHE           ),
    .M00_AXI_ARPROT                     (ITCN_M00_AXI_ARPROT            ),
    .M00_AXI_ARQOS                      (ITCN_M00_AXI_ARQOS             ),
    .M00_AXI_ARVALID                    (ITCN_M00_AXI_ARVALID           ),
    .M00_AXI_ARREADY                    (ITCN_M00_AXI_ARREADY           ),
    .M00_AXI_RID                        (ITCN_M00_AXI_RID               ),
    .M00_AXI_RDATA                      (ITCN_M00_AXI_RDATA             ),
    .M00_AXI_RRESP                      (ITCN_M00_AXI_RRESP             ),
    .M00_AXI_RLAST                      (ITCN_M00_AXI_RLAST             ),
    .M00_AXI_RVALID                     (ITCN_M00_AXI_RVALID            ),
    .M00_AXI_RREADY                     (ITCN_M00_AXI_RREADY            )
);

wire                            ui_clk;                  //MIG master clock
wire                            ui_clk_sync_rst;         //MIG master reset
ddr3 u_ddr3 
(
// Memory interface ports
.ddr3_addr                      (ddr3_addr                 ), 
.ddr3_ba                        (ddr3_ba                   ),
.ddr3_ras_n                     (ddr3_ras_n                ), 
.ddr3_cas_n                     (ddr3_cas_n                ),
.ddr3_we_n                      (ddr3_we_n                 ), 
.ddr3_reset_n                   (ddr3_reset_n              ),
.ddr3_ck_p                      (ddr3_ck_p                 ),
.ddr3_ck_n                      (ddr3_ck_n                 ),
.ddr3_cke                       (ddr3_cke                  ),  
.ddr3_cs_n                      (ddr3_cs_n                 ), 
.ddr3_dm                        (ddr3_dm                   ),  
.ddr3_odt                       (ddr3_odt                  ), 
.ddr3_dq                        (ddr3_dq                   ),  
.ddr3_dqs_n                     (ddr3_dqs_n                ),  
.ddr3_dqs_p                     (ddr3_dqs_p                ),  
.init_calib_complete            (                          ),   
// Application interface ports
.ui_clk                         (ui_clk                    ), 
.ui_clk_sync_rst                (ui_clk_sync_rst           ),  // output	    ui_clk_sync_rst
.mmcm_locked                    (                          ),  // output	    mmcm_locked
.aresetn                        (1'b1                      ),  // input			aresetn
.app_sr_req                     (1'b0                      ),  // input			app_sr_req
.app_ref_req                    (1'b0                      ),  // input			app_ref_req
.app_zq_req                     (1'b0                      ),  // input			app_zq_req
.app_sr_active                  (                          ),  // output	    app_sr_active
.app_ref_ack                    (                          ),  // output		app_ref_ack
.app_zq_ack                     (                          ),  // output		app_zq_ack
// Slave Interface Write Address Ports
.s_axi_awid                     (ITCN_M00_AXI_AWID              ),  // input [0:0]	s_axi_awid
.s_axi_awaddr                   (ITCN_M00_AXI_AWADDR            ),  // input [29:0]	s_axi_awaddr
.s_axi_awlen                    (ITCN_M00_AXI_AWLEN             ),  // input [7:0]	s_axi_awlen
.s_axi_awsize                   (ITCN_M00_AXI_AWSIZE            ),  // input [2:0]	s_axi_awsize
.s_axi_awburst                  (ITCN_M00_AXI_AWBURST           ),  // input [1:0]	s_axi_awburst
.s_axi_awlock                   (ITCN_M00_AXI_AWLOCK            ),  // input [0:0]	s_axi_awlock
.s_axi_awcache                  (ITCN_M00_AXI_AWCACHE           ),  // input [3:0]	s_axi_awcache
.s_axi_awprot                   (ITCN_M00_AXI_AWPROT            ),  // input [2:0]	s_axi_awprot
.s_axi_awqos                    (ITCN_M00_AXI_AWQOS             ),  // input [3:0]	s_axi_awqos
.s_axi_awvalid                  (ITCN_M00_AXI_AWVALID           ),  // input		s_axi_awvalid
.s_axi_awready                  (ITCN_M00_AXI_AWREADY           ),  // output	    s_axi_awready
// Slave Interface Write Data Ports
.s_axi_wdata                    (ITCN_M00_AXI_WDATA             ),  // input [63:0]	s_axi_wdata
.s_axi_wstrb                    (ITCN_M00_AXI_WSTRB             ),  // input [7:0]	s_axi_wstrb
.s_axi_wlast                    (ITCN_M00_AXI_WLAST             ),  // input		s_axi_wlast
.s_axi_wvalid                   (ITCN_M00_AXI_WVALID            ),  // input		s_axi_wvalid
.s_axi_wready                   (ITCN_M00_AXI_WREADY            ),  // output		s_axi_wready
// Slave Interface Write Response Ports
.s_axi_bid                      (ITCN_M00_AXI_BID               ),  // output [0:0]	s_axi_bid
.s_axi_bresp                    (ITCN_M00_AXI_BRESP             ),  // output [1:0]	s_axi_bresp
.s_axi_bvalid                   (ITCN_M00_AXI_BVALID            ),  // output		s_axi_bvalid
.s_axi_bready                   (ITCN_M00_AXI_BREADY            ),  // input		s_axi_bready
// Slave Interface Read Address Ports
.s_axi_arid                     (ITCN_M00_AXI_ARID              ),  // input [0:0]	s_axi_arid
.s_axi_araddr                   (ITCN_M00_AXI_ARADDR            ),  // input [29:0]	s_axi_araddr
.s_axi_arlen                    (ITCN_M00_AXI_ARLEN             ),  // input [7:0]	s_axi_arlen
.s_axi_arsize                   (ITCN_M00_AXI_ARSIZE            ),  // input [2:0]	s_axi_arsize
.s_axi_arburst                  (ITCN_M00_AXI_ARBURST           ),  // input [1:0]	s_axi_arburst
.s_axi_arlock                   (ITCN_M00_AXI_ARLOCK            ),  // input [0:0]	s_axi_arlock
.s_axi_arcache                  (ITCN_M00_AXI_ARCACHE           ),  // input [3:0]	s_axi_arcache
.s_axi_arprot                   (ITCN_M00_AXI_ARPROT            ),  // input [2:0]	s_axi_arprot
.s_axi_arqos                    (ITCN_M00_AXI_ARQOS             ),  // input [3:0]	s_axi_arqos
.s_axi_arvalid                  (ITCN_M00_AXI_ARVALID           ),  // input		s_axi_arvalid
.s_axi_arready                  (ITCN_M00_AXI_ARREADY           ),  // output		s_axi_arready
// Slave Interface Read Data Ports
.s_axi_rid                      (ITCN_M00_AXI_RID               ),  // output [0:0]	s_axi_rid
.s_axi_rdata                    (ITCN_M00_AXI_RDATA             ),  // output [63:0]s_axi_rdata
.s_axi_rresp                    (ITCN_M00_AXI_RRESP             ),  // output [1:0]	s_axi_rresp
.s_axi_rlast                    (ITCN_M00_AXI_RLAST             ),  // output	    s_axi_rlast
.s_axi_rvalid                   (ITCN_M00_AXI_RVALID            ),  // output		s_axi_rvalid
.s_axi_rready                   (ITCN_M00_AXI_RREADY            ),  // input		s_axi_rready
// System Clock Ports
.sys_clk_i                      (clk_200MHz                     ),  // MIG clock
.sys_rst                        (cpuresetn                      )   // input sys_rst
);


//------------------------------------------------------------------------------
// CMOS
//------------------------------------------------------------------------------
parameter MEM_DATA_BITS         = 32  ;                 //external memory user interface data width
parameter ADDR_BITS             = 28  ;                 //external memory user interface address width
parameter BUSRT_BITS            = 10  ;                 //external memory user interface burst width

wire                            wr_burst_data_req_cam;      // write burst data request       
wire                            wr_burst_finish_cam;        // write burst finish flag
wire                            wr_burst_req_cam;           //write burst request
wire[BUSRT_BITS - 1:0]          wr_burst_len_cam;           //write burst length
wire[ADDR_BITS - 1:0]           wr_burst_addr_cam;          //write burst address
wire[MEM_DATA_BITS - 1 : 0]     wr_burst_data_cam;          //write burst data 
wire                            write_en_cam;               //write enable
wire[15:0]                      write_data_cam;             //write data
wire                            write_req_cam;              //write request
wire                            write_req_ack_cam;          //write request response

wire                            rd_burst_data_valid_cam;    //read burst data valid
wire                            rd_burst_finish_cam;        //read burst finish flag
wire                            rd_burst_req_cam;           //read burst request
wire[BUSRT_BITS - 1:0]          rd_burst_len_cam;           //read burst length
wire[ADDR_BITS - 1:0]           rd_burst_addr_cam;          //read burst address
wire[MEM_DATA_BITS - 1 : 0]     rd_burst_data_cam;          //read burst data
wire                            read_en_cam;                //read enable
wire[15:0]                      read_data_cam;              //read data
wire                            read_req_cam;               //read request
wire                            read_req_ack_cam;           //read request response  

wire[15:0]                      cmos_16bit_data;         //camera  data
wire                            cmos_16bit_wr;           //camera  write enable
wire                            write_addr_index;        //write address index
wire                            read_addr_index;         //write address index
wire[9:0]                       lut_index;               //camera  look up table address
wire[31:0]                      lut_data;                //camera device address,register address, register data

reg  [31:0]                     req_count;
wire [31:0]                     write_num_cam;
wire                            CAM_IRQ;

wire                            video_clk;              //video pixel clock
wire                            video_clk5x;            //video 5 x pixel clock
wire                            hdmi_hs;
wire                            hdmi_vs;
wire                            hdmi_de;
wire[7:0]                       hdmi_r;
wire[7:0]                       hdmi_g;
wire[7:0]                       hdmi_b;
wire[31:0]                      vout_data;              //video data
assign hdmi_hs     = hs;
assign hdmi_vs     = vs;
assign hdmi_de     = de;
assign hdmi_r      = {vout_data[15:11],3'd0};
assign hdmi_g      = {vout_data[10:5],2'd0};
assign hdmi_b      = {vout_data[4:0],3'd0};

assign write_en_cam = cmos_16bit_wr;
assign write_data_cam = {cmos_16bit_data[4:0],cmos_16bit_data[10:5],cmos_16bit_data[15:11]};

localparam      CLK_FREQ = 32'd50_000_000;  // freq of "clk"
clk_200M PLL200M(
.clk_in1                            (CLK50M                 ),
.clk_out1                           (clk_200MHz             ),
.clk_out2                           (clk                    ),       
.reset                              (1'b0                   ),
.locked                             (                       )  
);

sys_pll sys_pll_m0(
.clk_in1                        (clk_200MHz               ),
.clk_out1                       (clk_50m                  ),
.clk_out2                       (cmos_xclk                ),
.reset                          (1'b0                     ),
.locked                         (                         )
);

video_pll video_pll_m0
(
.clk_in1                        (clk_50m                  ),
.clk_out1                       (video_clk                ),
.clk_out2                       (video_clk5x              ),
.reset                          (1'b0                     ),
.locked                         (                         )
);

i2c_config i2c_config_m0
(
.rst                            (~cpuresetn               ),
.clk                            (clk_50m                  ),
.clk_div_cnt                    (16'd99                   ),
.i2c_addr_2byte                 (1'b1                     ),
.lut_index                      (lut_index                ),
.lut_dev_addr                   (lut_data[31:24]          ),
.lut_reg_addr                   (lut_data[23:8]           ),
.lut_reg_data                   (lut_data[7:0]            ),
.error                          (                         ),
.done                           (                         ),
.i2c_scl                        (cmos_scl                 ),
.i2c_sda                        (cmos_sda                 )
);

lut_ov5640_rgb565_640_480 lut_ov5640_rgb565_640_480_m0(
.lut_index                      (lut_index                ),
.lut_data                       (lut_data                 )
);

dvi_encoder dvi_encoder_m0
(
.pixelclk                       (video_clk                 ),// system clock
.pixelclk5x                     (video_clk5x               ),// system clock x5
.rstin                          (~cpuresetn                ),// reset
.blue_din                       (hdmi_b                    ),// Blue data in
.green_din                      (hdmi_g                    ),// Green data in
.red_din                        (hdmi_r                    ),// Red data in
.hsync                          (hdmi_hs                   ),// hsync data
.vsync                          (hdmi_vs                   ),// vsync data
.de                             (hdmi_de                   ),// data enable
.tmds_clk_p                     (tmds_clk_p                ),
.tmds_clk_n                     (tmds_clk_n                ),
.tmds_data_p                    (tmds_data_p               ),//rgb
.tmds_data_n                    (tmds_data_n               ) //rgb
);

cmos_8_16bit cmos_8_16bit_m0(
.rst                            (~cpuresetn               ),
.pclk                           (cmos_pclk                ),
.pdata_i                        (cmos_db                  ),
.de_i                           (cmos_href                ),
.pdata_o                        (cmos_16bit_data          ),
.hblank                         (                         ),
.de_o                           (cmos_16bit_wr            )
);

cmos_write_req_gen cmos_write_req_gen_m0(
.rst                            (~cpuresetn               ),
.pclk                           (cmos_pclk                ),
.cmos_vsync                     (cmos_vsync               ),
.write_req                      (write_req_cam            ),
.write_req_ack                  (write_req_ack_cam        )
);

video_timing_data video_timing_data_m0
(
.video_clk                      (video_clk                 ),
.rst                            (~cpuresetn                ),
.read_req                       (read_req_cam              ),
.read_req_ack                   (read_req_ack_cam          ),
.read_en                        (read_en_cam               ),
.read_data                      (read_data_cam             ),
.hs                             (hs                        ),
.vs                             (vs                        ),
.de                             (de                        ),
.vout_data                      (vout_data                 )
);

frame_read_write_cam frame_read_write_cam_m0(
.rst                            (~cpuresetn                ),
.mem_clk                        (ui_clk                    ),
.data_process_flag              (data_process_flag         ),
.ignite_cam_ready               (ignite_cam_ready          ),
.CAM_IRQ                        (CAM_IRQ                   ),

.rd_burst_req                   (rd_burst_req_cam          ),
.rd_burst_len                   (rd_burst_len_cam          ),
.rd_burst_addr                  (rd_burst_addr_cam         ),
.rd_burst_data_valid            (rd_burst_data_valid_cam   ),
.rd_burst_data                  (rd_burst_data_cam         ),
.rd_burst_finish                (rd_burst_finish_cam       ),
.read_clk                       (video_clk                 ),
.read_req                       (read_req_cam              ),
.read_req_ack                   (read_req_ack_cam          ),
.read_finish                    (                          ),
.read_addr_0                    (28'haf00000               ), //The first frame address
.read_addr_1                    (28'haf80000               ),
.read_addr_2                    (                          ),
.read_addr_3                    (                          ),
.read_addr_index                (read_addr_index           ),
.read_len                       (28'd153600                ), //frame size
.read_en                        (read_en_cam               ),
.read_data                      (read_data_cam             ),

.wr_burst_req                   (wr_burst_req_cam          ),
.wr_burst_len                   (wr_burst_len_cam          ),
.wr_burst_addr                  (wr_burst_addr_cam         ),
.wr_burst_data_req              (wr_burst_data_req_cam     ),
.wr_burst_data                  (wr_burst_data_cam         ),
.wr_burst_finish                (wr_burst_finish_cam       ),
.write_clk                      (cmos_pclk                 ),
.write_req                      (write_req_cam             ),
.write_req_ack                  (write_req_ack_cam         ),
.write_addr_0                   (28'haf00000               ), //700MB, each address value here maps to 32 bits
.write_addr_1                   (28'haf80000               ), //702MB
.write_addr_2                   (                          ),
.write_addr_3                   (                          ),
.write_addr_index               (write_addr_index          ),
.write_len                      (28'd153600                ), //frame size  640 * 480 * 16 / 32
.write_en                       (write_en_cam              ),
.write_data                     (write_data_cam            )
);

aq_axi_master_cam u_aq_axi_master_cam(
.ARESETN                        (~ui_clk_sync_rst         ),
.ACLK                           (ui_clk                   ),
.M_AXI_AWID                     (ITCN_S01_AXI_AWID        ),
.M_AXI_AWADDR                   (ITCN_S01_AXI_AWADDR      ),
.M_AXI_AWLEN                    (ITCN_S01_AXI_AWLEN       ),
.M_AXI_AWSIZE                   (ITCN_S01_AXI_AWSIZE      ),
.M_AXI_AWBURST                  (ITCN_S01_AXI_AWBURST     ),
.M_AXI_AWLOCK                   (ITCN_S01_AXI_AWLOCK      ),
.M_AXI_AWCACHE                  (ITCN_S01_AXI_AWCACHE     ),
.M_AXI_AWPROT                   (ITCN_S01_AXI_AWPROT      ),
.M_AXI_AWQOS                    (ITCN_S01_AXI_AWQOS       ),
.M_AXI_AWUSER                   (                         ),
.M_AXI_AWVALID                  (ITCN_S01_AXI_AWVALID     ),
.M_AXI_AWREADY                  (ITCN_S01_AXI_AWREADY     ),
.M_AXI_WDATA                    (ITCN_S01_AXI_WDATA       ),
.M_AXI_WSTRB                    (ITCN_S01_AXI_WSTRB       ),
.M_AXI_WLAST                    (ITCN_S01_AXI_WLAST       ),
.M_AXI_WUSER                    (                         ),
.M_AXI_WVALID                   (ITCN_S01_AXI_WVALID      ),
.M_AXI_WREADY                   (ITCN_S01_AXI_WREADY      ),
.M_AXI_BID                      (ITCN_S01_AXI_BID         ),
.M_AXI_BRESP                    (ITCN_S01_AXI_BRESP       ),
.M_AXI_BUSER                    (                         ),
.M_AXI_BVALID                   (ITCN_S01_AXI_BVALID      ),
.M_AXI_BREADY                   (ITCN_S01_AXI_BREADY      ),
.M_AXI_ARID                     (ITCN_S01_AXI_ARID        ),
.M_AXI_ARADDR                   (ITCN_S01_AXI_ARADDR      ),
.M_AXI_ARLEN                    (ITCN_S01_AXI_ARLEN       ),
.M_AXI_ARSIZE                   (ITCN_S01_AXI_ARSIZE      ),
.M_AXI_ARBURST                  (ITCN_S01_AXI_ARBURST     ),
.M_AXI_ARLOCK                   (ITCN_S01_AXI_ARLOCK      ),
.M_AXI_ARCACHE                  (ITCN_S01_AXI_ARCACHE     ),
.M_AXI_ARPROT                   (ITCN_S01_AXI_ARPROT      ),
.M_AXI_ARQOS                    (ITCN_S01_AXI_ARQOS       ),
.M_AXI_ARUSER                   (                         ),
.M_AXI_ARVALID                  (ITCN_S01_AXI_ARVALID     ),
.M_AXI_ARREADY                  (ITCN_S01_AXI_ARREADY     ),
.M_AXI_RID                      (ITCN_S01_AXI_RID         ),
.M_AXI_RDATA                    (ITCN_S01_AXI_RDATA       ),
.M_AXI_RRESP                    (ITCN_S01_AXI_RRESP       ),
.M_AXI_RLAST                    (ITCN_S01_AXI_RLAST       ),
.M_AXI_RUSER                    (                         ),
.M_AXI_RVALID                   (ITCN_S01_AXI_RVALID      ),
.M_AXI_RREADY                   (ITCN_S01_AXI_RREADY      ),
.MASTER_RST                     (1'b0                     ),

.WR_START                       (wr_burst_req_cam         ),
.WR_ADRS                        ({wr_burst_addr_cam,2'd0} ),
.WR_LEN                         ({wr_burst_len_cam,3'd0}  ),
.WR_READY                       (                         ),
.WR_FIFO_RE                     (wr_burst_data_req_cam    ),
.WR_FIFO_EMPTY                  (1'b0                     ),
.WR_FIFO_AEMPTY                 (1'b0                     ),
.WR_FIFO_DATA                   (wr_burst_data_cam        ),
.WR_DONE                        (wr_burst_finish_cam      ),

.RD_START                       (rd_burst_req_cam         ),
.RD_ADRS                        ({rd_burst_addr_cam,2'd0} ),
.RD_LEN                         ({rd_burst_len_cam,3'd0}  ),
.RD_READY                       (                         ),
.RD_FIFO_WE                     (rd_burst_data_valid_cam  ), 
.RD_FIFO_FULL                   (1'b0                     ),
.RD_FIFO_AFULL                  (1'b0                     ),
.RD_FIFO_DATA                   (rd_burst_data_cam        ),
.RD_DONE                        (rd_burst_finish_cam      ),   

.DEBUG                          (                         )
);

//------------------------------------------------------------------------------
// APB LED
//------------------------------------------------------------------------------

cmsdk_apb3_eg_slave_led #(
    .ADDRWIDTH                      (12)
)  
    APB_LED(
    .PCLK                           (clk),
    .PRESETn                        (cpuresetn),
    .PSEL                           (PSEL_APBP0),
    .PADDR                          (PADDR[11:2]),
    .PENABLE                        (PENABLE),
    .PWRITE                         (PWRITE),
    .PWDATA                         (PWDATA),
    .PRDATA                         (PRDATA_APBP0),
    .PREADY                         (PREADY_APBP0),
    .PSLVERR                        (PSLVERR_APBP0),
    .ledNumOut                      (ledNumOut) //(led_wire) //chg: (ledNumOut)
    );

//------------------------------------------------------------------------------
// APB BTN
//------------------------------------------------------------------------------

// custom_apb_button #(
//     .ADDRWIDTH                      (12)
// )
//     APB_BTN(
//     .pclk                           (clk),
//     .presetn                        (cpuresetn),
//     .psel                           (PSEL_APBP1),
//     .paddr                          (PADDR[11:2]),
//     .penable                        (PENABLE),
//     .pwrite                         (PWRITE),
//     .pwdata                         (PWDATA),
//     .prdata                         (PRDATA_APBP1),
//     .pready                         (PREADY_APBP1),
//     .pslverr                        (PSLVERR_APBP1),
//     .state1                         (Btn)
//     );

//------------------------------------------------------------------------------
// APB UART
//------------------------------------------------------------------------------

wire            TXINT;
wire            RXINT;
wire            TXOVRINT;
wire            RXOVRINT;
wire            UARTINT;      

cmsdk_apb_uart UART(
    .PCLK                               (clk),
    .PCLKG                              (clk),
    .PRESETn                            (cpuresetn),
    .PSEL                               (PSEL_APBP2),
    .PADDR                              (PADDR[11:2]),
    .PENABLE                            (PENABLE), 
    .PWRITE                             (PWRITE),
    .PWDATA                             (PWDATA),
    .ECOREVNUM                          (4'b0),
    .PRDATA                             (PRDATA_APBP2),
    .PREADY                             (PREADY_APBP2),
    .PSLVERR                            (PSLVERR_APBP2),
    .RXD                                (RXD),
    .TXD                                (TXD),
    .TXEN                               (TXEN),
    .BAUDTICK                           (BAUDTICK),
    .TXINT                              (TXINT),
    .RXINT                              (RXINT),
    .TXOVRINT                           (TXOVRINT),
    .RXOVRINT                           (RXOVRINT),
    .UARTINT                            (UARTINT)
);

//------------------------------------------------------------------------------
// APB TIMER
//------------------------------------------------------------------------------
wire [31:0]     ui_cnt;
custom_apb_timer #(
    .ADDRWIDTH                      (12),
    .CLK_FREQ                       (CLK_FREQ)
)
    APB_TIMER(
    .pclk                           (clk),
    .presetn                        (cpuresetn),

    .cp_timerCnt                    (cp_timerCnt), // ckp
    .ui_clk                         (ui_clk),
    .ui_cnt                         (ui_cnt),

    .psel                           (PSEL_APBP3),
    .paddr                          (PADDR[11:2]),
    .penable                        (PENABLE),
    .pwrite                         (PWRITE),
    .pwdata                         (PWDATA),
    .prdata                         (PRDATA_APBP3),
    .pready                         (PREADY_APBP3),
    .pslverr                        (PSLVERR_APBP3)
    );

//------------------------------------------------------------------------------
// ACCELEATOR 
//------------------------------------------------------------------------------
wire            ignite_acc, ignite_ready, data_process_flag, ignite_cam_ready;
wire            ACC_IRQ1, ACC_IRQ2;
wire            mem_rd_ready_1, mem_rd_ready_2, mem_rd_ready_3, mem_rd_ready_4;
wire            mem_rd_1, mem_rd_2, mem_rd_3, mem_rd_4;
wire            mem_rd_ack_1, mem_rd_ack_2, mem_rd_ack_3, mem_rd_ack_4;
wire [31:0]     MEM_RDATA_1, MEM_RDATA_2;
wire            MEM_VALID;
wire [15:0]     MEM_ADRS1, MEM_ADRS2, MEM_ADRS3, MEM_ADRS4;

igniter #(
    .ADDRWIDTH                      (12)
)
    igniter_inst(
    .pclk                           (clk),
    .presetn                        (cpuresetn),

    .ignite_acc                     (ignite_acc), 
    .ignite_ready                   (ignite_ready),
    .ignite_cam                     (data_process_flag),
    .ignite_cam_ready               (ignite_cam_ready),
    .write_addr_index               (write_addr_index),
    .read_addr_index                (read_addr_index),

    .psel                           (PSEL_APBP4),
    .paddr                          (PADDR[11:2]),
    .penable                        (PENABLE),
    .pwrite                         (PWRITE),
    .pwdata                         (PWDATA),
    .prdata                         (PRDATA_APBP4),
    .pready                         (PREADY_APBP4),
    .pslverr                        (PSLVERR_APBP4)      
    );

blk_mem_gen_0 blk_mem_gen_0(
    .clka                           (ui_clk),
    .addra                          (MEM_ADRS1),
    .douta                          (MEM_RDATA_1),
    .clkb                           (ui_clk),
    .addrb                          (MEM_ADRS2),
    .doutb                          (MEM_RDATA_2)
);

reg           ACC_IRQ_READY;
always @ (posedge ui_clk or negedge cpuresetn)begin
  if(~cpuresetn)begin
    ACC_IRQ_READY <= 1'b0;
  end
  else begin
    if(ACC_IRQ1 & ACC_IRQ2)begin
      ACC_IRQ_READY <= 1'b1;
    end
    else begin
      ACC_IRQ_READY <= 1'b0;
    end
  end
end

accelerator #(
    .RCS_ADDR                   (32'h28400000), 
    .CONF_ADDR                  (32'h28500000), 
    .RETURN_ADDR                (32'h28500004)
)
accelerator_1(
.ARESETN                        (~ui_clk_sync_rst           ),
.ACLK                           (ui_clk                     ),

.M_AXI_AWID                     (ITCN_S02_AXI_AWID          ),
.M_AXI_AWADDR                   (ITCN_S02_AXI_AWADDR        ),
.M_AXI_AWLEN                    (ITCN_S02_AXI_AWLEN         ),
.M_AXI_AWSIZE                   (ITCN_S02_AXI_AWSIZE        ),
.M_AXI_AWBURST                  (ITCN_S02_AXI_AWBURST       ),
.M_AXI_AWLOCK                   (ITCN_S02_AXI_AWLOCK        ),
.M_AXI_AWCACHE                  (ITCN_S02_AXI_AWCACHE       ),
.M_AXI_AWPROT                   (ITCN_S02_AXI_AWPROT        ),
.M_AXI_AWQOS                    (ITCN_S02_AXI_AWQOS         ),
.M_AXI_AWUSER                   (                           ),
.M_AXI_AWVALID                  (ITCN_S02_AXI_AWVALID       ),
.M_AXI_AWREADY                  (ITCN_S02_AXI_AWREADY       ),

.M_AXI_WDATA                    (ITCN_S02_AXI_WDATA         ),
.M_AXI_WSTRB                    (ITCN_S02_AXI_WSTRB         ),
.M_AXI_WLAST                    (ITCN_S02_AXI_WLAST         ),
.M_AXI_WUSER                    (                           ),
.M_AXI_WVALID                   (ITCN_S02_AXI_WVALID        ),
.M_AXI_WREADY                   (ITCN_S02_AXI_WREADY        ),

.M_AXI_BID                      (ITCN_S02_AXI_BID           ),
.M_AXI_BRESP                    (ITCN_S02_AXI_BRESP         ),
.M_AXI_BUSER                    (                           ),
.M_AXI_BVALID                   (ITCN_S02_AXI_BVALID        ),
.M_AXI_BREADY                   (ITCN_S02_AXI_BREADY        ),

.M_AXI_ARID                     (ITCN_S02_AXI_ARID          ),
.M_AXI_ARADDR                   (ITCN_S02_AXI_ARADDR        ),
.M_AXI_ARLEN                    (ITCN_S02_AXI_ARLEN         ),
.M_AXI_ARSIZE                   (ITCN_S02_AXI_ARSIZE        ),
.M_AXI_ARBURST                  (ITCN_S02_AXI_ARBURST       ),
.M_AXI_ARLOCK                   (ITCN_S02_AXI_ARLOCK        ),
.M_AXI_ARCACHE                  (ITCN_S02_AXI_ARCACHE       ),
.M_AXI_ARPROT                   (ITCN_S02_AXI_ARPROT        ),
.M_AXI_ARQOS                    (ITCN_S02_AXI_ARQOS         ),
.M_AXI_ARUSER                   (                           ),
.M_AXI_ARVALID                  (ITCN_S02_AXI_ARVALID       ),
.M_AXI_ARREADY                  (ITCN_S02_AXI_ARREADY       ),

.M_AXI_RID                      (ITCN_S02_AXI_RID           ),
.M_AXI_RDATA                    (ITCN_S02_AXI_RDATA         ),
.M_AXI_RRESP                    (ITCN_S02_AXI_RRESP         ),
.M_AXI_RLAST                    (ITCN_S02_AXI_RLAST         ),
.M_AXI_RUSER                    (                           ),
.M_AXI_RVALID                   (ITCN_S02_AXI_RVALID        ),
.M_AXI_RREADY                   (ITCN_S02_AXI_RREADY        ),

.write_addr_index               (write_addr_index           ),
.ignite_acc                     (ignite_acc                 ),
.ignite_ready                   (ignite_ready               ),
.ACC_IRQ                        (ACC_IRQ1                   ),
.ACC_IRQ_READY                  (ACC_IRQ_READY              ),

// local memory
.MEM_RDATA                      (MEM_RDATA_1                ),   
.MEM_ADRS                       (MEM_ADRS1                  )

);

accelerator #(
    .RCS_ADDR                   (32'h28400010), 
    .CONF_ADDR                  (32'h28500010), 
    .RETURN_ADDR                (32'h28500014)
)
accelerator_2(
.ARESETN                        (~ui_clk_sync_rst           ),
.ACLK                           (ui_clk                     ),

.M_AXI_AWID                     (ITCN_S03_AXI_AWID          ),
.M_AXI_AWADDR                   (ITCN_S03_AXI_AWADDR        ),
.M_AXI_AWLEN                    (ITCN_S03_AXI_AWLEN         ),
.M_AXI_AWSIZE                   (ITCN_S03_AXI_AWSIZE        ),
.M_AXI_AWBURST                  (ITCN_S03_AXI_AWBURST       ),
.M_AXI_AWLOCK                   (ITCN_S03_AXI_AWLOCK        ),
.M_AXI_AWCACHE                  (ITCN_S03_AXI_AWCACHE       ),
.M_AXI_AWPROT                   (ITCN_S03_AXI_AWPROT        ),
.M_AXI_AWQOS                    (ITCN_S03_AXI_AWQOS         ),
.M_AXI_AWUSER                   (                           ),
.M_AXI_AWVALID                  (ITCN_S03_AXI_AWVALID       ),
.M_AXI_AWREADY                  (ITCN_S03_AXI_AWREADY       ),

.M_AXI_WDATA                    (ITCN_S03_AXI_WDATA         ),
.M_AXI_WSTRB                    (ITCN_S03_AXI_WSTRB         ),
.M_AXI_WLAST                    (ITCN_S03_AXI_WLAST         ),
.M_AXI_WUSER                    (                           ),
.M_AXI_WVALID                   (ITCN_S03_AXI_WVALID        ),
.M_AXI_WREADY                   (ITCN_S03_AXI_WREADY        ),

.M_AXI_BID                      (ITCN_S03_AXI_BID           ),
.M_AXI_BRESP                    (ITCN_S03_AXI_BRESP         ),
.M_AXI_BUSER                    (                           ),
.M_AXI_BVALID                   (ITCN_S03_AXI_BVALID        ),
.M_AXI_BREADY                   (ITCN_S03_AXI_BREADY        ),

.M_AXI_ARID                     (ITCN_S03_AXI_ARID          ),
.M_AXI_ARADDR                   (ITCN_S03_AXI_ARADDR        ),
.M_AXI_ARLEN                    (ITCN_S03_AXI_ARLEN         ),
.M_AXI_ARSIZE                   (ITCN_S03_AXI_ARSIZE        ),
.M_AXI_ARBURST                  (ITCN_S03_AXI_ARBURST       ),
.M_AXI_ARLOCK                   (ITCN_S03_AXI_ARLOCK        ),
.M_AXI_ARCACHE                  (ITCN_S03_AXI_ARCACHE       ),
.M_AXI_ARPROT                   (ITCN_S03_AXI_ARPROT        ),
.M_AXI_ARQOS                    (ITCN_S03_AXI_ARQOS         ),
.M_AXI_ARUSER                   (                           ),
.M_AXI_ARVALID                  (ITCN_S03_AXI_ARVALID       ),
.M_AXI_ARREADY                  (ITCN_S03_AXI_ARREADY       ),

.M_AXI_RID                      (ITCN_S03_AXI_RID           ),
.M_AXI_RDATA                    (ITCN_S03_AXI_RDATA         ),
.M_AXI_RRESP                    (ITCN_S03_AXI_RRESP         ),
.M_AXI_RLAST                    (ITCN_S03_AXI_RLAST         ),
.M_AXI_RUSER                    (                           ),
.M_AXI_RVALID                   (ITCN_S03_AXI_RVALID        ),
.M_AXI_RREADY                   (ITCN_S03_AXI_RREADY        ),

.write_addr_index               (write_addr_index           ),
.ignite_acc                     (ignite_acc                 ),
.ignite_ready                   (                           ),
.ACC_IRQ                        (ACC_IRQ2                   ),
.ACC_IRQ_READY                  (ACC_IRQ_READY              ),

// local memory
.MEM_RDATA                      (MEM_RDATA_2                ),   
.MEM_ADRS                       (MEM_ADRS2                  )

);

//------------------------------------------------------------------------------
// INTERRUPT 
//------------------------------------------------------------------------------

assign  IRQ     =   {235'b0,CAM_IRQ,ACC_IRQ_READY,TXOVRINT|RXOVRINT,TXINT,RXINT};

//------------------------------------------------------------------------------
// ILA DEBUG
//------------------------------------------------------------------------------
wire [31:0]     cp_timerCnt;
wire [31:0]     write_num, read_num_cam;
wire [31:0]     read_data_1, read_data_2, read_data_3, read_data_4, read_data_5;
wire [31:0]     read_addr_1, read_addr_2, read_addr_3, read_addr_4, read_addr_5;
wire [7:0]      am_state;
wire [5:0]      state_1, state_2; 
wire            add_result_valid, comp_result_valid, sub_result_valid;
wire [8:0]      counter_1;
wire [2:0]      counter_2;
wire [31:0]     idx, ptree_addr, o, thr, lut, tcode_reg, RD_ADRS;
wire [7:0]      tcodes_1, tcodes_2, tcodes_3, tcodes_4, pixels_1, pixels_2;
wire [31:0]     remainder_1, r_new, c_new, s_new, fullNum;
wire [3:0]      m_state;  
wire [31:0]     DEBUG;
// ila_0  ila_inst(
//     .clk                (ui_clk),
//     .probe0             (write_addr_index),
//     .probe1             (read_addr_index),
//     .probe2             (state_1),
//     .probe3             (DEBUG),
//     .probe4             (ui_cnt),
//     .probe5             (state_2)
// );

endmodule