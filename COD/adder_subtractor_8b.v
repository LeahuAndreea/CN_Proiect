module rca_8b (
    input  wire [7:0] a, b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [6:0] c;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(cin),  .sum(sum[0]),.cout(c[0]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[0]), .sum(sum[1]),.cout(c[1]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[1]), .sum(sum[2]),.cout(c[2]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[2]), .sum(sum[3]),.cout(c[3]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(c[3]), .sum(sum[4]),.cout(c[4]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(c[4]), .sum(sum[5]),.cout(c[5]));
    full_adder fa6(.a(a[6]),.b(b[6]),.cin(c[5]), .sum(sum[6]),.cout(c[6]));
    full_adder fa7(.a(a[7]),.b(b[7]),.cin(c[6]), .sum(sum[7]),.cout(cout));
endmodule

module adder_subtractor_8b (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       sub,      // 0=adunare, 1=scadere
    output wire [7:0] result,
    output wire       cout,
    output wire       neg       // 1 daca rezultatul este negativ (MSB=1)
);
    wire [7:0] b_mod;   // b XOR sub : inverseaza b cand sub=1

    xor xb0(b_mod[0],b[0],sub);
    xor xb1(b_mod[1],b[1],sub);
    xor xb2(b_mod[2],b[2],sub);
    xor xb3(b_mod[3],b[3],sub);
    xor xb4(b_mod[4],b[4],sub);
    xor xb5(b_mod[5],b[5],sub);
    xor xb6(b_mod[6],b[6],sub);
    xor xb7(b_mod[7],b[7],sub);

    rca_8b rca(.a(a),.b(b_mod),.cin(sub),.sum(result),.cout(cout));

    assign neg = result[7];
endmodule
