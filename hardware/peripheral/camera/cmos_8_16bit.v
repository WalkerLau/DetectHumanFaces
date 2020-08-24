module cmos_8_16bit(
	input              rst,
	input              pclk,
	input [7:0]        pdata_i,
	input              de_i,
	output reg[15:0]   pdata_o,
	output reg         hblank,
	output reg         de_o
);
reg[7:0] pdata_i_d0;
reg[11:0] x_cnt;
always@(posedge pclk)
begin
	pdata_i_d0 <= pdata_i;
end

always@(posedge pclk or posedge rst)
begin
	if(rst)
		x_cnt <= 12'd0;
	else if(de_i)
		x_cnt <= x_cnt + 12'd1;
	else
		x_cnt <= 12'd0;
end

always@(posedge pclk or posedge rst)
begin
	if(rst)
		de_o <= 1'b0;
	else if(de_i && x_cnt[0])
		de_o <= 1'b1;
	else
		de_o <= 1'b0;
end

always@(posedge pclk or posedge rst)
begin
	if(rst)
		hblank <= 1'b0;
	else
		hblank <= de_i;
end

always@(posedge pclk or posedge rst)
begin
	if(rst)
		pdata_o <= 16'd0;
	else if(de_i && x_cnt[0])
		pdata_o <= {pdata_i_d0,pdata_i};
	else
		pdata_o <= 16'd0;
end

endmodule 