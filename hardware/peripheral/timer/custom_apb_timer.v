module custom_apb_timer #(
	parameter ADDRWIDTH = 12,
  parameter CLK_FREQ  = 32'd50000000
  )
	(
	
	//SYSTEM
	input wire                       pclk,
	input wire                       presetn,
	
	output reg	[31:0]				       cp_timerCnt, // ckp
  input                            ui_clk,
  output reg  [31:0]               ui_cnt,
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

	reg [31:0]	cnt;
	always @ (posedge pclk or negedge presetn) begin
		if(~presetn) begin
			cnt <= 32'd0;
		end
		else if(cnt >= CLK_FREQ/1000 - 1) begin // reset to zero every 1ms
			cnt <= 32'd0;
		end
		else begin
			cnt <= cnt + 32'd1;
		end
	end

	reg [31:0] ms_cnt;
	always @ (posedge pclk or negedge presetn) begin
		if(~presetn)begin
			ms_cnt <= 32'd0;
		end
		else if((write_en == 1'b1) && (pwdata == 32'd1514)) begin
			ms_cnt <= 32'd0;
		end
		else if(cnt == 32'd1) begin
			ms_cnt <= ms_cnt + 32'd1;
		end
	end

	always @ (posedge pclk or negedge presetn) begin
		if(~presetn)begin
			prdata <= 32'd0;
		end
		else begin
			prdata <= ms_cnt;
		end		
	end

	always @ (posedge pclk or negedge presetn) begin
		if(~presetn)begin
			cp_timerCnt <= 32'd0;
		end
		else if(read_en == 1'b1) begin
			cp_timerCnt <= ms_cnt;
		end
	end

  reg [31:0]    ui_reg;
  always @ (posedge ui_clk or negedge presetn) begin
    if(~presetn)begin
      ui_reg      <= 32'd0;
    end
    else begin
      if(cnt == 32'd1)begin
        ui_cnt <= ui_reg;
        ui_reg <= 32'd0; 
      end
      else begin
        ui_reg <= ui_reg + 32'd1;
      end
    end
  end


endmodule
 
  