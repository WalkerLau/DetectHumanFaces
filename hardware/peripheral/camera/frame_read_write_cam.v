`timescale 1ns/1ps
module frame_read_write_cam
#
(
	parameter MEM_DATA_BITS          = 32,
	parameter READ_DATA_BITS         = 16,
	parameter WRITE_DATA_BITS        = 16,
	parameter ADDR_BITS              = 28,
	parameter BUSRT_BITS             = 10,
	parameter BURST_SIZE             = 128
)               
(
	input                            rst,                  
	input                            mem_clk,                    // external memory controller user interface clock
	input							 							 data_process_flag,
	output wire						 					 ignite_cam_ready,
	output wire 					 					 CAM_IRQ,

	output                           rd_burst_req,               // to external memory controller,send out a burst read request
	output[BUSRT_BITS - 1:0]         rd_burst_len,               // to external memory controller,data length of the burst read request, not bytes
	output[ADDR_BITS - 1:0]          rd_burst_addr,              // to external memory controller,base address of the burst read request 
	input                            rd_burst_data_valid,        // from external memory controller,read data valid 
	input[MEM_DATA_BITS - 1:0]       rd_burst_data,              // from external memory controller,read request data
	input                            rd_burst_finish,            // from external memory controller,burst read finish
	input                            read_clk,                   // data read module clock
	input                            read_req,                   // data read module read request,keep '1' until read_req_ack = '1'
	output                           read_req_ack,               // data read module read request response
	output                           read_finish,                // data read module read request finish
	input[ADDR_BITS - 1:0]           read_addr_0,                // data read module read request base address 0, used when read_addr_index = 0
	input[ADDR_BITS - 1:0]           read_addr_1,                // data read module read request base address 1, used when read_addr_index = 1
	input[ADDR_BITS - 1:0]           read_addr_2,                // data read module read request base address 1, used when read_addr_index = 2
	input[ADDR_BITS - 1:0]           read_addr_3,                // data read module read request base address 1, used when read_addr_index = 3
	input                            read_addr_index,            // select valid base address from read_addr_0 read_addr_1
	input[ADDR_BITS - 1:0]           read_len,                   // data read module read request data length
	input                            read_en,                    // data read module read request for one data, read_data valid next clock
	output[READ_DATA_BITS  - 1:0]    read_data,                  // read data

	output                           wr_burst_req,               // to external memory controller,send out a burst write request
	output[BUSRT_BITS - 1:0]         wr_burst_len,               // to external memory controller,data length of the burst write request, not bytes
	output[ADDR_BITS - 1:0]          wr_burst_addr,              // to external memory controller,base address of the burst write request 
	input                            wr_burst_data_req,          // from external memory controller,write data request ,before data 1 clock
	output[MEM_DATA_BITS - 1:0]  	 	 wr_burst_data,          	 	 // to external memory controller,write data
	input                            wr_burst_finish,            // from external memory controller,burst write finish
	input                            write_clk,                  // data write module clock
	input                            write_req,                  // data write module write request,keep '1' until read_req_ack = '1'
	output                           write_req_ack,              // data write module write request response
	input[ADDR_BITS - 1:0]           write_addr_0,               // data write module write request base address 0, used when write_addr_index = 0
	input[ADDR_BITS - 1:0]           write_addr_1,               // data write module write request base address 1, used when write_addr_index = 1
	input[ADDR_BITS - 1:0]           write_addr_2,               // data write module write request base address 1, used when write_addr_index = 2
	input[ADDR_BITS - 1:0]           write_addr_3,               // data write module write request base address 1, used when write_addr_index = 3
	input                            write_addr_index,           // select valid base address from write_addr_0 write_addr_1
	input[ADDR_BITS - 1:0]           write_len,                  // data write module write request data length
	input                            write_en,                   // data write module write request for one data
	input[WRITE_DATA_BITS - 1:0]     write_data                  // write data
);
wire[15:0]                           wrusedw;                    // write used words
wire[15:0]                           rdusedw;                    // read used words
wire                                 read_fifo_aclr;             // fifo Asynchronous clear
wire                                 write_fifo_aclr;            // fifo Asynchronous clear

//instantiate an asynchronous FIFO 
afifo_16i_32o_512 write_buf (
	.rst                         (write_fifo_aclr         ),
	.wr_clk                      (write_clk               ),
	.rd_clk                      (mem_clk                 ),
	.din                         (write_data              ),
	.wr_en                       (write_en                ),
	.rd_en                       (wr_burst_data_req       ),
	.dout                        (wr_burst_data		      	),
	.full                        (                        ),
	.empty                       (                        ),
	.rd_data_count               (rdusedw                 ), // number of data used seen from the FIFO read side
	.wr_data_count               (                        )
);

frame_fifo_write_cam
#
(
	.MEM_DATA_BITS              (MEM_DATA_BITS            ),    //32
	.ADDR_BITS                  (ADDR_BITS                ),    //28
	.BUSRT_BITS                 (BUSRT_BITS               ),    //10
	.BURST_SIZE                 (BURST_SIZE               )     //128
) 
frame_fifo_write_cam_m0              
(  
	.rst                        (rst                      ),
	.mem_clk                    (mem_clk                  ),
	.wr_burst_req               (wr_burst_req             ),
	.wr_burst_len               (wr_burst_len             ),
	.wr_burst_addr              (wr_burst_addr            ),
	.wr_burst_finish            (wr_burst_finish          ),
	.write_req                  (write_req                ),
	.write_req_ack              (write_req_ack            ),
	.write_addr_0               (write_addr_0             ),
	.write_addr_1               (write_addr_1             ),
	.write_addr_2               (write_addr_2             ),
	.write_addr_3               (write_addr_3             ), 
	.write_addr_index           (write_addr_index         ), 
	.write_len                  (write_len                ),
	.fifo_aclr                  (write_fifo_aclr          ),
	.rdusedw                    (rdusedw                  ),
	.data_process_flag          (data_process_flag        ),
	.ignite_cam_ready						(ignite_cam_ready		  		),
	.CAM_IRQ										(CAM_IRQ				  				)
);

//instantiate an asynchronous FIFO
afifo_32i_16o_256 read_buf (
	.rst                         (read_fifo_aclr          ),                     
	.wr_clk                      (mem_clk                 ),               
	.rd_clk                      (read_clk                ),               
	.din                         (rd_burst_data           ),                     
	.wr_en                       (rd_burst_data_valid     ),                 
	.rd_en                       (read_en                 ),                 
	.dout                        (read_data               ),                   
	.full                        (                        ),                   
	.empty                       (                        ),                 
	.rd_data_count               (                        ), 
	.wr_data_count               (wrusedw                 )  
);

frame_fifo_read_cam
#
(
	.MEM_DATA_BITS              (MEM_DATA_BITS            ),
	.ADDR_BITS                  (ADDR_BITS                ),
	.BUSRT_BITS                 (BUSRT_BITS               ),
	.FIFO_DEPTH                 (256                      ),
	.BURST_SIZE                 (BURST_SIZE               )
)
frame_fifo_read_cam_m0
(
	.rst                        (rst                      ),
	.mem_clk                    (mem_clk                  ),
	.rd_burst_req               (rd_burst_req             ),   
	.rd_burst_len               (rd_burst_len             ),  
	.rd_burst_addr              (rd_burst_addr            ),
	.rd_burst_data_valid        (rd_burst_data_valid      ),    
	.rd_burst_finish            (rd_burst_finish          ),
	.read_req                   (read_req                 ),
	.read_req_ack               (read_req_ack             ),
	.read_finish                (read_finish              ),
	.read_addr_0                (read_addr_0              ),
	.read_addr_1                (read_addr_1              ),
	.read_addr_2                (read_addr_2              ),
	.read_addr_3                (read_addr_3              ),
	.read_addr_index            (read_addr_index          ),  
	.read_len                   (read_len                 ),
	.fifo_aclr                  (read_fifo_aclr           ),
	.wrusedw                    (wrusedw                  )
);

endmodule
