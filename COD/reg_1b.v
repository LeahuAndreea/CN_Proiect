// =============================================================================
// reg_1b.v
// Registru 1 bit - D Flip-Flop cu reset asincron activ pe 1
// =============================================================================
module reg_1b (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output reg  q
);
    always @(posedge clk or posedge rst)
        if (rst) q <= 1'b0;
        else     q <= d;
endmodule
