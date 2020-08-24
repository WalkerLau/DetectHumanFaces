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
module custom_apb_led(
    //led core ports
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] ledNumIn,
    output reg  [3:0]  ledNumOut    // When high, the LED on board turns off
);

always @ (posedge clk or negedge rst)
begin
    if(~rst)
        ledNumOut <= 4'b1111;
    else if(ledNumIn >= 4'b1111)
        ledNumOut <= 4'b0000;
    else
        ledNumOut <= ~ledNumIn;
end

endmodule