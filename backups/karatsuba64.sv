module karatsuba64 (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [63:0] A,
    input  logic [63:0] B,
    output logic [127:0] P,
    output logic        valid_out
);

    // Split 64-bit inputs
    logic [33:0] A_hi, A_lo, B_hi, B_lo;
    assign A_hi = A[63:32];
    assign A_lo = A[31:0];
    assign B_hi = B[63:32];
    assign B_lo = B[31:0];
    logic [33:0] sumA, sumB;  // 32+1 bits to avoid overflow

    assign sumA = A[63:32] + A[31:0];
    assign sumB = B[63:32] + B[31:0];
    // Outputs of 32x32 Karatsuba units
    logic [67:0] z0, z1, z2;
    logic v0, v1, v2;

    // Start signals
    logic start_z0, start_z1, start_z2;
     always @(posedge clk) begin
        if (start) begin
            $display("----------------------------------------------------------------------------------");
            $display("[%0t]64 Input A=%d (%0d bits), B=%d (%0d bits)", 
                    $time, A, $bits(A), B, $bits(B));
            $display("[%0t]64 A_hi=%d (%0d bits), A_lo=%d (%0d bits), B_hi=%d (%0d bits), B_lo=%d (%0d bits)", 
                    $time, A_hi, $bits(A_hi), A_lo, $bits(A_lo), B_hi, $bits(B_hi), B_lo, $bits(B_lo));
            $display("[%0t]64 sumA=%d (%0d bits), sumB=%d (%0d bits)", 
                    $time, sumA, $bits(sumA), sumB, $bits(sumB));
            $display("----------------------------------------------------------------------------------");
        end
    end

    // Instantiate three karatsuba32 units
    karatsuba34 k0 (.clk(clk), .rst(rst), .start(start_z0),
                    .A(A_lo), .B(B_lo), .P(z0), .valid_out(v0));

    karatsuba34 k1 (.clk(clk), .rst(rst), .start(start_z1),
                    .A(A_hi), .B(B_hi), .P(z1), .valid_out(v1));

    karatsuba34 k2 (.clk(clk), .rst(rst), .start(start_z2),
                    .A(A_lo + A_hi), .B(B_lo + B_hi), .P(z2), .valid_out(v2));

    // FSM states
    typedef enum logic [2:0] {
        IDLE,
        START_P0, WAIT_P0,
        START_P1, WAIT_P1,
        START_P2, WAIT_P2,
        COMBINE
    } state_t;

    state_t state;

    logic [127:0] P_reg;
    assign P = P_reg;
    logic valid_reg;
    assign valid_out = valid_reg;
logic [100:0] P_full;
                    logic [200:0] z0_ext, z1_ext, mid_ext;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            P_reg <= 0;
            valid_reg <= 0;
            start_z0 <= 0;
            start_z1 <= 0;
            start_z2 <= 0;
        end else begin
            // defaults
            start_z0 <= 0;
            start_z1 <= 0;
            start_z2 <= 0;
            valid_reg <= 0;

            case(state)
                IDLE: if (start) state <= START_P0;

                // Stage 0: compute z0 = A_lo*B_lo
                START_P0: begin start_z0 <= 1; state <= WAIT_P0; end
                WAIT_P0: if (v0) state <= START_P1;

                // Stage 1: compute z1 = A_hi*B_hi
                START_P1: begin start_z1 <= 1; state <= WAIT_P1; end
                WAIT_P1: if (v1) state <= START_P2;

                // Stage 2: compute z2 = (A_hi+A_lo)*(B_hi+B_lo)
                START_P2: begin start_z2 <= 1; state <= WAIT_P2; end
                WAIT_P2: if (v2) state <= COMBINE;

                // Combine results
  COMBINE: begin
                    
            z0_ext  = {{36{1'b0}}, z0};          // 36-bit z0 into 72 bits
        z1_ext  = {{36{1'b0}}, z1} << 64;    // 36-bit z1 shifted into upper half
        mid_ext = {{36{1'b0}}, (z2 - z1 - z0)} << 32;
                    

    $display("[%0t] --- COMBINE STAGE ---", $time);
    $display("   z0   = %d", z0);
    $display("   z1   = %d", z1);
    $display("   z2   = %d", z2);
    $display("   mid  = %d (before shift)", (z2 - z1 - z0));
    $display("   z0_ext  = %d", z0_ext);
    $display("   z1_ext  = %d", z1_ext);
    $display("   mid_ext = %d", mid_ext);
    P_full = z1_ext + mid_ext + z0_ext;

    $display("   --> Combined P = %h", P_full);
                    P_reg <= z1_ext + mid_ext + z0_ext;
                    valid_reg <= 1;
                end
            endcase
        end
    end
endmodule
