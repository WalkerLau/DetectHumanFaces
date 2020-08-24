module cmos_write_req_gen(
	input              rst,
	input              pclk,
	input              cmos_vsync,
	output reg         write_req,
	// output reg  	     write_addr_index,
	// output reg  	     read_addr_index,
	input              write_req_ack     
);
reg cmos_vsync_d0;
reg cmos_vsync_d1;
always@(posedge pclk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		cmos_vsync_d0 <= 1'b0;
		cmos_vsync_d1 <= 1'b0;
	end
	else
	begin
		cmos_vsync_d0 <= cmos_vsync;
		cmos_vsync_d1 <= cmos_vsync_d0;
	end
end

always@(posedge pclk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		write_req <= 1'b0;
	end
	else if(cmos_vsync_d0 == 1'b1 && cmos_vsync_d1 == 1'b0)
	begin
		write_req <= 1'b1;
	end
	else if(write_req_ack == 1'b1)
		write_req <= 1'b0;
end

// always@(posedge pclk or posedge rst)
// begin
// 	if(rst == 1'b1)
// 		write_addr_index <= 1'b0;
// 	else if(cmos_vsync_d0 == 1'b1 && cmos_vsync_d1 == 1'b0)
// 		write_addr_index <= write_addr_index + 1'd1;
// end

// always@(posedge pclk or posedge rst)
// begin
// 	if(rst == 1'b1)
// 		read_addr_index <= 1'b0;
// 	else if(cmos_vsync_d0 == 1'b1 && cmos_vsync_d1 == 1'b0)
// 		read_addr_index <= write_addr_index;
// end

endmodule 