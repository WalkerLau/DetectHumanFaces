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
module igniter #(
	parameter ADDRWIDTH = 12)
	(
	
	//SYSTEM
	input wire                       pclk,
	input wire                       presetn,
	
	output reg					     				 ignite_acc,
  input                            ignite_ready,
	output reg 						 					 ignite_cam,
	input							 							 ignite_cam_ready,
  output reg                       write_addr_index,
  output reg                       read_addr_index,
	//APB
	input  wire                      psel,
	input  wire [ADDRWIDTH-1:0]      paddr,
	input  wire                      penable,
	input  wire                      pwrite,
	input  wire [31:0]               pwdata,
	output reg  [31:0]               prdata,
	output wire                      pready,
	output wire                      pslverr	
	);

  	assign	pready  = 1'b1;	//always ready. Can be customized to support waitstate if required.
  	assign	pslverr = 1'b0;	//alwyas OKAY. Can be customized to support error response if required.

	assign	write_en = psel & penable & pwrite;
	assign	read_en  = psel & penable & (~pwrite);

	// Camera Igniter
	always @ (posedge pclk or negedge presetn) begin
		if(~presetn)begin
			ignite_cam <= 1'b0;
    end 
    else begin
			if(ignite_cam_ready == 1'b1) begin
				ignite_cam <= 1'b0; 
			end
			else if((write_en == 1'b1) && (pwdata == 32'hca)) begin
				ignite_cam <= 1'b1;
			end
    end
	end

	// Accelerator Igniter
	always @ (posedge pclk or negedge presetn) begin
		if(~presetn)begin
			ignite_acc <= 1'b0;
        end 
        else begin
		    if(ignite_ready == 1'b1) begin
		    	ignite_acc <= 1'b0; 
		    end
		    else if((write_en == 1'b1) && (pwdata == 32'd1514)) begin
				ignite_acc <= 1'b1;
		    end
        end
	end

  // pixel address index
  always @ (posedge pclk or negedge presetn) begin
    if(~presetn)begin
      prdata <= 32'd0;
    end
		else if(read_en == 1'b1) begin
			prdata <= {31'b0, write_addr_index};
		end
  end

  // draw kuangkuang
  always @ (posedge pclk or negedge presetn) begin
    if(~presetn)begin
      write_addr_index  <= 1'd0;
      read_addr_index   <= 1'd1;
    end
		else begin
      if((write_en == 1'b1) && (pwdata == 32'hda)) begin
        read_addr_index   = write_addr_index;
        write_addr_index  = write_addr_index + 1'd1;
      end
		end
  end

endmodule
 
  