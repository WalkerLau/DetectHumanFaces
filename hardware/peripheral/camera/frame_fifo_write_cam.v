//利用fifo进行cmos得到的16位数的写入。在对应的地址写过一帧后，对该帧是否写入的标志赋值。
//读出的部分是持续读出（对该帧是否写入的标志）特定内容，进而可以在cmos写请求函数中对地址index产生影响。
`timescale 1ns/1ps
module frame_fifo_write_cam
#
(
	parameter MEM_DATA_BITS          = 32,
	parameter ADDR_BITS              = 28,
	parameter BUSRT_BITS             = 10,
	parameter BURST_SIZE             = 128
)               
(
	input                            rst,                  
	input                            mem_clk,                    // external memory controller user interface clock
	output reg                       wr_burst_req,               // to external memory controller,send out a burst write request  
	output reg[BUSRT_BITS - 1:0]     wr_burst_len,               // to external memory controller,data length of the burst write request, not bytes 
	output reg[ADDR_BITS - 1:0]      wr_burst_addr,              // to external memory controller,base address of the burst write request 
	input                            wr_burst_finish,            // from external memory controller,burst write finish
	input                            write_req,                  // data write module write request,keep '1' until read_req_ack = '1'
	output reg                       write_req_ack,              // data write module write request response
	//output                           write_finish,               // data write module write request finish
	input[ADDR_BITS - 1:0]           write_addr_0,               // data write module write request base address 0, used when write_addr_index = 0
	input[ADDR_BITS - 1:0]           write_addr_1,               // data write module write request base address 1, used when write_addr_index = 1
	input[ADDR_BITS - 1:0]           write_addr_2,               // data write module write request base address 1, used when write_addr_index = 2
	input[ADDR_BITS - 1:0]           write_addr_3,               // data write module write request base address 1, used when write_addr_index = 3
	input                            write_addr_index,           // select valid base address from write_addr_0 write_addr_1
	input[ADDR_BITS - 1:0]           write_len,                  // data write module write request data length
	output reg                       fifo_aclr,                  // to fifo asynchronous clear
	input[15:0]                      rdusedw,                     // from fifo read used words
	input                            data_process_flag,
	//output reg[0:0]				     		   flag_ready,
	output reg 					     				 ignite_cam_ready,
	output reg						 					 CAM_IRQ
);
localparam ONE                       = 256'd1;    
               //256 bit '1'   you can use ONE[n-1:0] for n bit '1'
localparam ZERO                      = 256'd0;                   //256 bit '0'
//write state machine code
localparam S_IDLE                    = 0;                        //idle state,waiting for write
localparam S_ACK                     = 1;                        //written request response
localparam S_CHECK_FIFO              = 2;                        //check the FIFO status, ensure that there is enough space to burst write
localparam S_WRITE_BURST             = 3;                        //begin a burst write
localparam S_WRITE_BURST_END         = 4;                        //a burst write complete
localparam S_END1                    = 5;                        //a frame of data is written to complete
localparam S_END2					           = 6;
localparam S_END3					           = 7;
localparam S_END4					           = 8;

reg                                 write_req_d0;                //asynchronous write request, synchronize to 'mem_clk' clock domain,first beat
reg                                 write_req_d1;                //the second
reg                                 write_req_d2;                //third,Why do you need 3 ? Here's the design habit
reg[ADDR_BITS - 1:0]                write_len_d0;                //asynchronous write_len(write data length), synchronize to 'mem_clk' clock domain first
reg[ADDR_BITS - 1:0]                write_len_d1;                //second
reg[ADDR_BITS - 1:0]                write_len_latch;             //lock write data length
reg[ADDR_BITS - 1:0]                write_cnt;                   //write data counter
reg                                 write_addr_index_d0;
reg                                 write_addr_index_d1;
reg[3:0]                            state;                       //state machine
reg[3:0]                            tag_state;                   //tag_state machine

//assign write_finish = (state == S_END) ? 1'b1 : 1'b0;            //write finish at state 'S_END'
always@(posedge mem_clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		write_req_d0    <=  1'b0;
		write_req_d1    <=  1'b0;
		write_req_d2    <=  1'b0;
		write_len_d0    <=  ZERO[ADDR_BITS - 1:0];              //equivalent to write_len_d0 <= 0;
		write_len_d1    <=  ZERO[ADDR_BITS - 1:0];              //equivalent to write_len_d1 <= 0;
		write_addr_index_d0    <=  1'b0;
		write_addr_index_d1    <=  1'b0;
	end
	else
	begin
		write_req_d0    <=  write_req;
		write_req_d1    <=  write_req_d0;
		write_req_d2    <=  write_req_d1;
		write_len_d0    <=  write_len;
		write_len_d1    <=  write_len_d0;
		write_addr_index_d0 <= write_addr_index;
		write_addr_index_d1 <= write_addr_index_d0;
	end 
end


always@(posedge mem_clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		state <= S_IDLE;
		write_len_latch <= ZERO[ADDR_BITS - 1:0];
		wr_burst_addr <= ZERO[ADDR_BITS - 1:0];
		wr_burst_req <= 1'b0;
		write_cnt <= ZERO[ADDR_BITS - 1:0];
		fifo_aclr <= 1'b0;
		write_req_ack <= 1'b0;
		wr_burst_len <= ZERO[BUSRT_BITS - 1:0];
		//flag_ready <= 1'b0;
		ignite_cam_ready <= 1'b0;
		CAM_IRQ	<= 1'b0;
	end
	else
	begin
		case(state)
			//idle state,waiting for write write_req_d2 == '1' goto the 'S_ACK'
			S_IDLE:
			begin
				if((write_req_d2 == 1'b1) && (data_process_flag == 1'b1))
				begin
					state <= S_ACK;
					ignite_cam_ready <= 1'b1;
				end
				write_req_ack <= 1'b0;
				CAM_IRQ	<= 1'b0;
			end
			//'S_ACK' state completes the write request response, the FIFO reset, the address latch, and the data length latch
			S_ACK:
			begin
				//after write request revocation(write_req_d2 == '0'),goto 'S_CHECK_FIFO',write_req_ack goto '0'
				if(write_req_d2 == 1'b0)
				begin
					state <= S_CHECK_FIFO;
					fifo_aclr <= 1'b0;
					write_req_ack <= 1'b0;
					//ignite_cam_ready <= 1'b0;
				end
				else
				begin					
					//write request response
					write_req_ack <= 1'b1;
					//FIFO reset
					fifo_aclr <= 1'b1;
					//set write burst address	
					//select valid base address from write_addr_0 write_addr_1 write_addr_2 write_addr_3
					if(write_addr_index_d1 == 1'd0)
						wr_burst_addr <= write_addr_0;
					else if(write_addr_index_d1 == 1'd1)
						wr_burst_addr <= write_addr_1;
					//latch data length
					write_len_latch <= write_len_d1;                    
				end
				//write data counter reset, write_cnt <= 0;
				write_cnt <= ZERO[ADDR_BITS - 1:0];
			end
			S_CHECK_FIFO:
			begin
        ignite_cam_ready <= 1'b0;
				//if there is a write request at this time, enter the 'S_ACK' state
				if(write_req_d2 == 1'b1)
				begin
					state <= S_ACK;
				end
				//if the FIFO space is a burst write request, goto burst write state
				else if(rdusedw >= BURST_SIZE)
				begin
					state <= S_WRITE_BURST;
					wr_burst_len <= BURST_SIZE[BUSRT_BITS - 1:0];
					wr_burst_req <= 1'b1;
				end
			end
			S_WRITE_BURST:
			begin
				//burst finish
				if(wr_burst_finish == 1'b1)
				begin
					wr_burst_req <= 1'b0;
					state <= S_WRITE_BURST_END;
					//write counter + burst length
					write_cnt <= write_cnt + BURST_SIZE[ADDR_BITS - 1:0];
					//the next burst write address is generated
					wr_burst_addr <= wr_burst_addr + BURST_SIZE[ADDR_BITS - 1:0];
				end     
			end
			S_WRITE_BURST_END:
			begin
				//if there is a write request at this time, enter the 'S_ACK' state
				if(write_req_d2 == 1'b1)
				begin
					state <= S_ACK;
				end
				//if the write counter value is less than the frame length, continue writing,
				//otherwise the writing is complete
				else if(write_cnt < write_len_latch)
				begin
					state <= S_CHECK_FIFO;
				end
				else
				begin
					state <= S_END1;
					CAM_IRQ	<= 1'b1;
				end
			end
			S_END1:
			begin
				state   <= S_END2;
			end
			S_END2:
			begin
				state   <= S_END3;
			end
			S_END3:
			begin
				state   <= S_END4;
			end
			S_END4:
			begin
				state   <= S_IDLE;
			end
			// S_END:
			// begin
			// 	state 			<= T_ACK;
			// 	flag_ready 		<= 1'b1;
			// end
			// T_ACK:   
			// begin
			// 	state 			<= T_WRITE_BURST;
			// 	wr_burst_addr 	<= write_addr_3;
			// 	wr_burst_len 	<= ONE[BUSRT_BITS - 1:0];
			// 	wr_burst_req 	<= 1'b1;
			// end
			// T_WRITE_BURST:
			// begin
			// 	//burst finish
			// 	if(wr_burst_finish == 1'b1)
			// 	begin
			// 		wr_burst_req 	<= 1'b0;
			// 		state 			<= T_END;
			// 	end     
			// end
			// T_END:
			// begin
			// 	flag_ready 	<= 1'b0;
			// 	state 		<= S_IDLE;
			// end
			default:
				state <= S_IDLE;
		endcase
	end
end
endmodule
