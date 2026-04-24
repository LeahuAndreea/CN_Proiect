module mux_2to1_1b (
    input  wire a,    // Intrare 0 (sel=0)
    input  wire b,    // Intrare 1 (sel=1)
    input  wire sel,
    output wire y
);
    wire ns, wa, wb;
    not g0 (ns, sel);
    and g1 (wa, a, ns);
    and g2 (wb, b, sel);
    or  g3 (y,  wa, wb);
endmodule

module mux_2to1_8b (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       sel,
    output wire [7:0] y
);
    mux_2to1_1b m0(.a(a[0]),.b(b[0]),.sel(sel),.y(y[0]));
    mux_2to1_1b m1(.a(a[1]),.b(b[1]),.sel(sel),.y(y[1]));
    mux_2to1_1b m2(.a(a[2]),.b(b[2]),.sel(sel),.y(y[2]));
    mux_2to1_1b m3(.a(a[3]),.b(b[3]),.sel(sel),.y(y[3]));
    mux_2to1_1b m4(.a(a[4]),.b(b[4]),.sel(sel),.y(y[4]));
    mux_2to1_1b m5(.a(a[5]),.b(b[5]),.sel(sel),.y(y[5]));
    mux_2to1_1b m6(.a(a[6]),.b(b[6]),.sel(sel),.y(y[6]));
    mux_2to1_1b m7(.a(a[7]),.b(b[7]),.sel(sel),.y(y[7]));
endmodule
