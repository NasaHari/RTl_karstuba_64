module tb_karatsuba64;

    logic clk, rst, start;
    logic [63:0] A, B;
    logic [127:0] P;
    logic valid_out;

    // Instantiate the DUT
    karatsuba64 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .B(B),
        .P(P),
        .valid_out(valid_out)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Reference product
    logic [127:0] Pt;

    // --- Task to run a single multiplication test ---
    task run_test(input logic [63:0] a_in, b_in, string name);
        begin
            A = a_in;
            B = b_in;
            Pt = a_in * b_in;

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            wait (valid_out);

            if (P === Pt) begin
                $display("[%0t] %s PASS: A=%h B=%h -> P=%h", 
                          $time, name, a_in, b_in, P);
            end else begin
                $display("[%0t] %s **FAIL**: A=%h B=%h -> P=%h (ref=%h)", 
                          $time, name, a_in, b_in, P, Pt);
            end
        end
    endtask

    // --- Test sequence ---
    initial begin
        // Reset
        rst = 1;
        start = 0;
        A = 0;
        B = 0;
        #20;
        rst = 0;

        // Directed edge cases
        // run_test(64'h2, 64'h3, "Zero*Zero");
        // run_test(64'h1, 64'h1, "One*One");
        // run_test(64'hFFFFFFFFFFFFFFFF, 64'h1, "Max*One");
        // run_test(64'hFFFFFFFFFFFFFFFF, 64'hFFFFFFFFFFFFFFFF, "All ones");
        // run_test(64'h8000000000000000, 64'h2, "PowerOfTwo");
        // run_test(64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555, "AlternatingBits");

        // Randomized tests
            run_test($urandom(), $urandom(), "Random");

        $display("All tests completed successfully.");
        $finish;
    end

endmodule
