module full_adder (
    input  wire a, b, cin,
    output wire sum, cout
);
    wire w1, w2, w3;
    xor g1 (w1,   a,  b);
    xor g2 (sum,  w1, cin);
    and g3 (w2,   a,  b);
    and g4 (w3,   w1, cin);
    or  g5 (cout, w2, w3);
endmodule
