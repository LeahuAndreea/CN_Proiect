module control_unit (
    input  wire       clk, rst,
    input  wire       start,
    input  wire [1:0] opcode,       // 00=ADD 01=SUB 10=MUL 11=DIV

    input  wire       s_q0,         // Q[0] curent
    input  wire       s_q_neg1,     // Q_1 curent
    input  wire       s_b_cnt_zero,

    input  wire       s_a_neg,      // A[7] = 1 (A negativ dupa shift)
    input  wire       s_d_cnt_zero, // counter DIV = 0
    input  wire       s_div_zero,   // divisor = 0

    output reg        c_load_ops,   // incarca reg_A si reg_B din INBUS

    output reg        c_b_load_M,   // C0
    output reg        c_b_load_AQ,  // C1
    output reg        c_b_add,      // C2
    output reg        c_b_sub,      // C3
    output reg        c_b_shift,    // C4
    output reg        c_b_cnt_load, //
    output reg        c_b_cnt_dec,  // C7

    output reg        c_d_load,     // C0
    output reg        c_d_shift,    // C5
    output reg        c_d_add,      // C2
    output reg        c_d_sub,      // C3
    output reg        c_d_set_q0,   // C6
    output reg        c_d_correct,  // C8
    output reg        c_d_cnt_load, //
    output reg        c_d_cnt_dec,  // C7

    output reg        done,         // C9/C10: calculul s-a terminat
    output reg        err_div_zero  // eroare impartire la zero
);

    localparam IDLE        = 5'd0;
    localparam LOAD_OPS    = 5'd1;
    localparam ADD_EXEC    = 5'd2;
    localparam SUB_EXEC    = 5'd3;
    localparam MUL_LOAD_M  = 5'd4;
    localparam MUL_LOAD_AQ = 5'd5;
    localparam MUL_CHK     = 5'd6;
    localparam MUL_ADD     = 5'd7;
    localparam MUL_SUB     = 5'd8;
    localparam MUL_SHIFT   = 5'd9;
    localparam DIV_LOAD    = 5'd10;
    localparam DIV_SHIFT   = 5'd11;
    localparam DIV_ARITH   = 5'd12;
    localparam DIV_SET_Q0  = 5'd13;
    localparam DIV_CORRECT = 5'd14;
    localparam DONE_ST     = 5'd15;
    localparam ERROR       = 5'd16;

    reg [4:0] state, nxt;

   
    always @(posedge clk or posedge rst)
        if (rst) state <= IDLE;
        else     state <= nxt;

    always @(*) begin
        nxt = state;  // implicit: ramane in aceeasi stare
        case (state)
            IDLE:
                nxt = start ? LOAD_OPS : IDLE;

            LOAD_OPS:
                case (opcode)
                    2'b00: nxt = ADD_EXEC;
                    2'b01: nxt = SUB_EXEC;
                    2'b10: nxt = MUL_LOAD_M;
                    2'b11: nxt = DIV_LOAD;
                endcase


            ADD_EXEC: nxt = DONE_ST;
            SUB_EXEC: nxt = DONE_ST;

            MUL_LOAD_M:  nxt = MUL_LOAD_AQ;

            MUL_LOAD_AQ: nxt = MUL_CHK;

            MUL_CHK:
                if      (s_q0 & ~s_q_neg1) nxt = MUL_SUB;  
                else if (~s_q0 & s_q_neg1) nxt = MUL_ADD;  
                else                       nxt = MUL_SHIFT; 

            MUL_ADD: nxt = MUL_SHIFT;
            MUL_SUB: nxt = MUL_SHIFT;

            MUL_SHIFT:
                nxt = s_b_cnt_zero ? DONE_ST : MUL_CHK;

            DIV_LOAD:
                nxt = s_div_zero ? ERROR : DIV_SHIFT;

            DIV_SHIFT: nxt = DIV_ARITH;

            DIV_ARITH: nxt = DIV_SET_Q0;

            DIV_SET_Q0:
                nxt = s_d_cnt_zero ? DIV_CORRECT : DIV_SHIFT;

            DIV_CORRECT: nxt = DONE_ST;

            DONE_ST: nxt = start ? DONE_ST : IDLE;
            ERROR:   nxt = start ? ERROR   : IDLE;

            default: nxt = IDLE;
        endcase
    end

    always @(*) begin
        // Toate semnalele dezactivate implicit
        c_load_ops    = 1'b0;
        c_b_load_M    = 1'b0;
        c_b_load_AQ   = 1'b0;
        c_b_add       = 1'b0;
        c_b_sub       = 1'b0;
        c_b_shift     = 1'b0;
        c_b_cnt_load  = 1'b0;
        c_b_cnt_dec   = 1'b0;
        c_d_load      = 1'b0;
        c_d_shift     = 1'b0;
        c_d_add       = 1'b0;
        c_d_sub       = 1'b0;
        c_d_set_q0    = 1'b0;
        c_d_correct   = 1'b0;
        c_d_cnt_load  = 1'b0;
        c_d_cnt_dec   = 1'b0;
        done          = 1'b0;
        err_div_zero  = 1'b0;

        case (state)
            LOAD_OPS:
                c_load_ops   = 1'b1;         

            MUL_LOAD_M: begin
                c_b_load_M   = 1'b1;         
            end

            MUL_LOAD_AQ: begin
                c_b_load_AQ  = 1'b1;        
                c_b_cnt_load = 1'b1;         
            end

            MUL_ADD: begin
                c_b_add      = 1'b1;         
            end

            MUL_SUB: begin
                c_b_sub      = 1'b1;        
            end

            MUL_SHIFT: begin
                c_b_shift    = 1'b1;        
                c_b_cnt_dec  = 1'b1;        
            end

            DIV_LOAD: begin
                c_d_load     = 1'b1;         
                c_d_cnt_load = 1'b1;         
            end

            DIV_SHIFT: begin
                c_d_shift    = 1'b1;         
            end

            DIV_ARITH: begin
                if (s_a_neg)
                    c_d_add  = 1'b1;         // C2: A era negativ - aduna M
                else
                    c_d_sub  = 1'b1;         // C3: A era pozitiv - scade M
            end

            DIV_SET_Q0: begin
                c_d_set_q0   = 1'b1;         // C6: Q[0] - ~A[7]
                c_d_cnt_dec  = 1'b1;         // C7: dec counter
            end

            DIV_CORRECT: begin
                if (s_a_neg)
                    c_d_correct = 1'b1;      // C8: A<0 - A = A + M
            end

            DONE_ST: begin
                done         = 1'b1;         // C9, C10: rezultat disponibil
            end

            ERROR: begin
                done         = 1'b1;
                err_div_zero = 1'b1;
            end
        endcase
    end

endmodule
