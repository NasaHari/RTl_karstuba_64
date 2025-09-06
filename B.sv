
`timescale 1ns/1ps

module B(
    input clk,
    input rst,
    input start,
    input  T_Ready,

    input [3:0] Data_in1,
    input [3:0] Data_in2,
    output reg [7:0] Data_out
);

    reg [63:0] number1;
    reg [63:0] number2;
    reg [5:0] bit_count;
    reg storing;
    reg [2:0] fifo_count;         // number of entries in FIFO

    // ---------- Stage 1 ----------
    reg [3:0] in1_stage1, in2_stage1;
    reg [5:0] count_stage1;
    reg valid_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in1_stage1   <= 4'b0;
            in2_stage1   <= 4'b0;
            count_stage1 <= 6'd0;
            storing      <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (start && fifo_count<4) begin
                // 🚀 First nibble captured immediately
                storing      <= 1'b1;
                count_stage1 <= 6'd1;   // first nibble index
                in1_stage1   <= Data_in1;
                in2_stage1   <= Data_in2;
                valid_stage1 <= 1'b1;
            end else if (storing) begin
                // 🚀 Subsequent nibbles
                in1_stage1   <= Data_in1;
                in2_stage1   <= Data_in2;
                count_stage1 <= count_stage1 + 1;
                valid_stage1 <= 1'b1;

                if (count_stage1 == 6'd15) begin
                    storing <= 1'b0;  // all 16 nibbles done
                end
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (valid_stage1) begin
            // $display("Stage1: count=%d in1=%h in2=%h",
            //           count_stage1, in1_stage1, in2_stage1);
        end
    end

    // ---------- Stage 2 ----------
    reg [63:0] shifted1_stage2, shifted2_stage2;
    reg [5:0] count_stage2;
    reg valid_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shifted1_stage2 <= 0; 
            shifted2_stage2 <= 0;
            count_stage2    <= 0; 
            valid_stage2    <= 0;
        end else if (valid_stage1) begin
          shifted1_stage2 <= in1_stage1 << ((16 - count_stage1) * 4);
          shifted2_stage2 <= in2_stage1 << ((16 - count_stage1) * 4);
            count_stage2    <= count_stage1;
            valid_stage2    <= 1;
        end else begin
            valid_stage2 <= 0;
        end
    end

    always @(posedge clk) begin
        if (valid_stage2) begin
            // $display("Stage2: count=%d shifted1=%h shifted2=%h",
            //           count_stage2, shifted1_stage2, shifted2_stage2);
        end
    end

    // ---------- Stage 3 ----------
    reg [63:0] number1_stage3, number2_stage3;
    reg [5:0] count_stage3;
    reg valid_stage3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            number1_stage3 <= 0; 
            number2_stage3 <= 0;
            count_stage3   <= 0; 
            valid_stage3   <= 0;
        end else if (valid_stage2) begin
          if (count_stage2 == 6'd1) begin
            // first nibble → reset accumulators
            number1_stage3 <= shifted1_stage2;
            number2_stage3 <= shifted2_stage2;
        end else begin
            number1_stage3 <= number1_stage3 | shifted1_stage2;
            number2_stage3 <= number2_stage3 | shifted2_stage2;
        end
            count_stage3   <= count_stage2;
            valid_stage3   <= 1;
        end else begin
            valid_stage3 <= 0;
        end
    end

    always @(posedge clk) begin
        if (valid_stage3) begin
            // $display("Stage3: count=%d num1=%h num2=%h",
            //           count_stage3, number1_stage3, number2_stage3);
        end
    end

  
// FIFO to hold assembled number pairs
reg [63:0] fifo_num1 [0:3];
reg [63:0] fifo_num2 [0:3];
reg [1:0]  fifo_wr_ptr;
reg [1:0]  fifo_rd_ptr; // depth=4 → 3 bits
typedef enum logic [1:0] {IDLE, START_MUL, WAIT_DONE, OUTPUT} mul_state_t;
mul_state_t mul_state;
// Unified FIFO owner: resets, write, read (both in one place)
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        fifo_wr_ptr <= 0;
        fifo_rd_ptr <= 0;
        fifo_count  <= 0;
    end else begin
        // ---------- WRITE from Stage3 ----------
        if (valid_stage3 && count_stage3 == 16 && fifo_count < 4) begin
            fifo_num1[fifo_wr_ptr] <= number1_stage3;
            fifo_num2[fifo_wr_ptr] <= number2_stage3;
            fifo_wr_ptr            <= fifo_wr_ptr + 1;
            fifo_count             <= fifo_count + 1;
        end

        // ---------- READ requested by FSM ----------
        // When the multiplier asserts valid_product, we consume one FIFO entry
        if (mul_state == WAIT_DONE && valid_product && fifo_count > 0) begin
            fifo_rd_ptr <= fifo_rd_ptr + 1;
            fifo_count  <= fifo_count - 1;
        end

        // If write & read happen in the same cycle, the two updates above
        // naturally keep the net fifo_count unchanged (one in, one out).
    end
end

  
    // Final output combine (optional)



// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         fifo_rd_ptr <= 0;
//         Data_out_reg <= 0;
//     end else if (fifo_count > 0) begin
//         // Example: multiply numbers and output
//      	 Data_out_reg <={ fifo_num1[fifo_rd_ptr] , fifo_num2[fifo_rd_ptr]};
//      	 $display("FIFO READ / Data_out: ptr=%d Data_out=%h count=%d",
//                   fifo_rd_ptr, Data_out_reg, fifo_count-1);
//         fifo_rd_ptr <= fifo_rd_ptr + 1;
//         fifo_count <= fifo_count - 1;
//     end
// end
logic [127:0] product;
logic valid_product;     // connected to kar_inst.valid_out
logic [63:0] kar_A, kar_B;
logic kar_start;
         // pulse driven by FSM
logic [127:0] cur_product;   // Current 128-bit product being sent
logic [3:0] byte_idx;        // Which byte of cur_product we are sending
logic sending;               // Are we currently sending a product?


// Output product FIFO must buffer up to 96 cycles of stall
localparam PROD_FIFO_DEPTH = 8;   // ≥6 required, use 8 for simplicity

logic [127:0] product_fifo[PROD_FIFO_DEPTH-1:0];
logic [$clog2(PROD_FIFO_DEPTH)-1:0] prod_wr_ptr, prod_rd_ptr;
logic [$clog2(PROD_FIFO_DEPTH):0]   prod_count;  // needs +1 bit for full/empty


// connect kar_inst to kar_start and captured operands
karatsuba64 kar_inst (
    .clk(clk),
    .rst(rst),
    .start(kar_start),
    .A(kar_A),
    .B(kar_B),
    .P(product),
    .valid_out(valid_product)
);

// FSM type


// initialize in reset
always @(posedge clk or posedge rst) begin
    if (rst) begin
        mul_state   <= IDLE;
        kar_start   <= 1'b0;
        kar_A       <= 64'd0;
        kar_B       <= 64'd0;
      
    end else begin
        // default: no start pulse unless we assert explicitly in START_MUL
        kar_start <= 1'b0;

        case (mul_state)
            IDLE: begin
                // only detect available data here and move to START_MUL;
                // do not read FIFO in the same cycle; read when in START_MUL.
                if (fifo_count > 0) begin
                //>     $display("[FSM] %0t IDLE -> START_MUL (rd_ptr=%0d count=%0d)", $time, fifo_rd_ptr, fifo_count);
                    mul_state <= START_MUL;
                end
            end

            START_MUL: begin
                // capture FIFO head into local regs (freeze inputs)
                kar_A <= fifo_num1[fifo_rd_ptr];
                kar_B <= fifo_num2[fifo_rd_ptr];

                // pulse start for one cycle
                kar_start <= 1'b1;

                //> $display("[FSM] %0t START_MUL: captured A=%h B=%h ptr=%0d", $time, fifo_num1[fifo_rd_ptr], fifo_num2[fifo_rd_ptr], fifo_rd_ptr);

                // move to wait state
                mul_state <= WAIT_DONE;
            end

            WAIT_DONE: begin
                // we already pulsed kar_start for 1 cycle in previous state; here we wait
                   //> $display("[FSM] %0t WAIT_DONE: waiting for valid_product=%b", $time, valid_product);              
                      if (valid_product) begin
                    // latch product into output register
                   

                    
                   //> $display("[FSM] %0t PRODUCT READY: product=%h (old_rd=%0d) fifo_count(before)=%0d",$time, product, fifo_rd_ptr, fifo_count);

                    // go back to IDLE to process next FIFO entry
                    mul_state <= IDLE;
                end
            end

            default: mul_state <= IDLE;
        endcase
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        sending <= 0;
        prod_rd_ptr <= 0;
        prod_wr_ptr <= 0;
        prod_count  <= 0;
       cur_product <= 0;

        byte_idx <= 0;
        Data_out <= 0;
    end else begin
    if (mul_state == WAIT_DONE && valid_product) begin
            product_fifo[prod_wr_ptr] <= product;
            prod_wr_ptr <= prod_wr_ptr + 1;
            prod_count  <= prod_count + 1;
        end
        if (!sending) begin
            // Start sending next product if FIFO not empty
            if (prod_count > 0) begin
                cur_product <= product_fifo[prod_rd_ptr];
                prod_rd_ptr <= prod_rd_ptr + 1;
                prod_count <= prod_count - 1;
                sending <= 1;
                byte_idx <= 0;
            end
            else if (T_Ready) begin
                Data_out <= 8'hFF; // No data → send idle token
            end
        end else if (T_Ready) begin
            // Send next byte of current product
            Data_out <= cur_product[byte_idx*8 +: 8];
            if (byte_idx == 15) sending <= 0;  // all bytes sent
            else byte_idx <= byte_idx + 1;
        end
    end
end

endmodule