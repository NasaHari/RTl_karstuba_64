module karatsuba32 (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [63:0] P,
    output logic        valid_out
);

    // --- Split inputs into 16-bit halves ---
    logic [15:0] A_hi, A_lo, B_hi, B_lo;
    logic [31:0] z0, z1, z2;
    logic d0, d1, d2;

    // Small multiplier start signals
    logic start_m0, start_m1, start_m2;

    // Assign halves
    assign A_hi = A[31:16];
    assign A_lo = A[15:0];
    assign B_hi = B[31:16];
    assign B_lo = B[15:0];

    // Instantiate mult16 units
    mult16 m0 (.clk(clk), .rst(rst), .start(start_m0), .A(A_lo), .B(B_lo), .P(z0), .done(d0));
    mult16 m1 (.clk(clk), .rst(rst), .start(start_m1), .A(A_hi), .B(B_hi), .P(z1), .done(d1));
    mult16 m2 (.clk(clk), .rst(rst), .start(start_m2), .A(A_lo + A_hi), .B(B_lo + B_hi), .P(z2), .done(d2));

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
    logic [63:0] P_reg;
    assign P = P_reg;
    logic valid_reg;
    assign valid_out = valid_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            P_reg <= 0;
            valid_reg <= 0;
            start_m0 <= 0;
            start_m1 <= 0;
            start_m2 <= 0;
        end else begin
            // default values
            start_m0 <= 0;
            start_m1 <= 0;
            start_m2 <= 0;
            valid_reg <= 0;

            case(state)
                IDLE: begin
                    if (start) state <= START_P0;
                end

                // --- Stage 0: start z0 = A_lo*B_lo ---
                START_P0: begin
                    start_m0 <= 1;
                    state <= WAIT_P0;
                end
                WAIT_P0: begin
                    if (d0) state <= START_P1;
                end

                // --- Stage 1: start z1 = A_hi*B_hi ---
                START_P1: begin
                    start_m1 <= 1;
                    state <= WAIT_P1;
                end
                WAIT_P1: begin
                    if (d1) state <= START_P2;
                end

                // --- Stage 2: start z2 = (A_hi+A_lo)*(B_hi+B_lo) ---
                START_P2: begin
                    start_m2 <= 1;
                    state <= WAIT_P2;
                end
                WAIT_P2: begin
                    if (d2) state <= COMBINE;
                end

                // --- Combine results ---
                COMBINE: begin
                    P_reg <= ( (64'(z1) << 32) + (64'((z2 - z1 - z0)) << 16) + z0 );
                    valid_reg <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
