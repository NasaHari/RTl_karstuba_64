`timescale 1ns/1ps

module tb_mult16;

    logic clk, rst, start;
    logic [15:0] A, B;
    logic [31:0] P;
    logic done;

    // Instantiate DUT
    mult16 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .B(B),
        .done(done),
        .P(P)
    );

    // Clock generator
    always #5 clk = ~clk; // 100 MHz clock

    task run_test(input [15:0] a, input [15:0] b);
        begin
            @(negedge clk);
            A = a;
            B = b;
            start = 1;
            @(negedge clk);   // hold start at least 1 cycle
            start = 0;

            // Wait for done
            wait (done == 1);
            @(posedge clk);

            // Check result
            if (P !== (a * b)) begin
                $display("❌ ERROR: %0d * %0d = %0d (got %0d)", a, b, a*b, P);
            end else begin
                $display("✅ PASS: %0d * %0d = %0d", a, b, P);
            end

            // Wait for done to clear
            wait (done == 0);
        end
    endtask

    initial begin
        // Init signals
        clk = 0; rst = 1; start = 0; A = 0; B = 0;
        #20 rst = 0;

        // Run tests
        run_test(16'h0003, 16'h0004); // 3*4=12
        run_test(16'h00FF, 16'h0002); // 255*2=510
        run_test(16'hFFFF, 16'h0001); // 65535*1
        run_test(16'h1234, 16'h5678); // Random test
        run_test(16'hABCD, 16'hDCBA); // Random test

        $display("All tests finished ✅");
        $finish;
    end

endmodule
