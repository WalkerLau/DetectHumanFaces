module custom_apb_button #(
	parameter ADDRWIDTH = 12)
	(
	
	//SYSTEM
	input wire                       pclk,
	input wire                       presetn,
	
	//APB
	input  wire                      psel,
	input  wire [ADDRWIDTH-1:0]      paddr,
	input  wire                      penable,
	input  wire                      pwrite,
	input  wire [31:0]               pwdata,
	output reg  [31:0]               prdata,
	output wire                      pready,
	output wire                      pslverr,
	
	//INTERFACE
	input wire                       state1       
	
	);

  	assign   pready  = 1'b1;	//always ready. Can be customized to support waitstate if required.
  	assign   pslverr = 1'b0;	//alwyas OKAY. Can be customized to support error response if required.

	reg		[31:0]		btn_reg;
	always @ (posedge pclk or negedge presetn)
	begin
		if(~presetn) begin
			btn_reg <= 32'h1;
		end else begin
			btn_reg <= {{31{1'b0}},state1}; 
		end
	end	

  	always @(posedge pclk or negedge presetn)
	begin
		if (~presetn) begin
			prdata <= 32'h01;
		end else begin
			prdata <= btn_reg;
		end
	end

endmodule
 
  