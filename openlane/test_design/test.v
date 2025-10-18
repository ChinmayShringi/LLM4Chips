// Simple test design to verify OpenLane works
module test_design (
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);
    always @(posedge clk) begin
        if (rst)
            out <= 8'b0;
        else
            out <= in + 8'd1;
    end
endmodule
