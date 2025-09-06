module karatsuba34 (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [33:0] A,       // 34-bit input
    input  logic [33:0] B,       // 34-bit input
    output logic [67:0] P,       // 34x34 -> 68-bit product
    output logic        valid_out
);

    // --- Split inputs into 18-bit halves ---
    logic [17:0] A_hi, A_lo, B_hi, B_lo;
    logic [35:0] z0, z1, z2;     // 
    logic d0, d1, d2;

    // Small multiplier start signals
    logic start_m0, start_m1, start_m2;

    // Assign halves
    assign A_hi = A[33:17];       // upper 18 bits
    assign A_lo = A[16:0] ;
    assign B_hi = B[33:17];
    assign B_lo = B[16:0];

    logic [17:0] sumA;
    logic [17:0] sumB;
assign sumA = {1'b0, A_hi} + {1'b0, A_lo};
assign sumB = {1'b0, B_hi} + {1'b0, B_lo};

    // Display info
    always @(posedge clk) begin
        if (start) begin
            $display("----------------------------------------------------------------------------------");
            $display("[%0t]34 Input A=%d (%0d bits), B=%d (%0d bits)", 
                    $time, A, $bits(A), B, $bits(B));
            $display("[%0t]34 A_hi=%d (%0d bits), A_lo=%d (%0d bits), B_hi=%d (%0d bits), B_lo=%d (%0d bits)", 
                    $time, A_hi, $bits(A_hi), A_lo, $bits(A_lo), B_hi, $bits(B_hi), B_lo, $bits(B_lo));
            $display("[%0t]34 sumA=%d (%0d bits), sumB=%d (%0d bits)", 
                    $time, sumA, $bits(sumA), sumB, $bits(sumB));
            $display("----------------------------------------------------------------------------------");
        end
    end

    // Instantiate 18x18 multipliers
    mult18 m0 (.clk(clk), .rst(rst), .start(start_m0), .A(A_lo), .B(B_lo), .P(z0), .done(d0));
    mult18 m1 (.clk(clk), .rst(rst), .start(start_m1), .A(A_hi), .B(B_hi), .P(z1), .done(d1));
    mult18 m2 (.clk(clk), .rst(rst), .start(start_m2), .A(sumA), .B(sumB), .P(z2), .done(d2));

    // FSM states
    typedef enum logic [2:0] {
        IDLE,
        START_P0, WAIT_P0,
        START_P1, WAIT_P1,
        START_P2, WAIT_P2,
        COMBINE
    } state_t;

    state_t state;

    // Output register
    logic [71:0] P_reg;
    assign P = P_reg;
    logic valid_reg;
    assign valid_out = valid_reg;
    logic [100:0] P_full;
                    logic [71:0] z0_ext, z1_ext, mid_ext;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            P_reg <= 0;
            valid_reg <= 0;
            start_m0 <= 0;
            start_m1 <= 0;
            start_m2 <= 0;
        end else begin
            // default
            start_m0 <= 0;
            start_m1 <= 0;
            start_m2 <= 0;
            valid_reg <= 0;

            case(state)
                IDLE: begin
                    if (start) state <= START_P0;
                end

                START_P0: begin
                    start_m0 <= 1;
                    state <= WAIT_P0;
                end
                WAIT_P0: if (d0) state <= START_P1;

                START_P1: begin
                    start_m1 <= 1;
                    state <= WAIT_P1;
                end
                WAIT_P1: if (d1) state <= START_P2;

                START_P2: begin
                    start_m2 <= 1;
                    state <= WAIT_P2;
                end
                WAIT_P2: if (d2) state <= COMBINE;

                COMBINE: begin
                    
            z0_ext  = {{36{1'b0}}, z0};          // 36-bit z0 into 72 bits
        z1_ext  = {{36{1'b0}}, z1} << 34;    // 36-bit z1 shifted into upper half
        mid_ext = {{36{1'b0}}, (z2 - z1 - z0)} << 17;
                    

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
