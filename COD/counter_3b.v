module counter_3b (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,
    input  wire [2:0] load_val,
    input  wire       dec,
    output wire [2:0] count,
    output wire       zero
);
    reg [2:0] cnt;

    always @(posedge clk or posedge rst) begin
        if      (rst)  cnt <= 3'b000;
        else if (load) cnt <= load_val;
        else if (dec)  cnt <= cnt - 3'b001;
    end

    assign count = cnt;

    wire n0, n1, n2;
    not g0(n0, cnt[0]);
    not g1(n1, cnt[1]);
    not g2(n2, cnt[2]);
    and g3(zero, n0, n1, n2);
endmodule
