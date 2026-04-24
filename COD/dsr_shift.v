module dsr_shift (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,
    input  wire       clr,
    input  wire       shr,
    input  wire       shl,
    input  wire       set_lsb,  
    input  wire [7:0] d,       
    input  wire       sin_r,    
    input  wire       sin_l,    
    input  wire       lsb_val,  
    output wire [7:0] q,
    output wire       sout_r,   
    output wire       sout_l    
);
    reg [7:0] q_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            q_reg <= 8'b0;
        else if (clr)
            q_reg <= 8'b0;
        else if (load)
            q_reg <= d;
        else if (shr)
            q_reg <= {sin_r, q_reg[7:1]};
        else if (shl)
            q_reg <= {q_reg[6:0], sin_l};
        else if (set_lsb)
            q_reg <= {q_reg[7:1], lsb_val};
    end

    assign q      = q_reg;
    assign sout_r = q_reg[0];  
    assign sout_l = q_reg[7];   

endmodule
