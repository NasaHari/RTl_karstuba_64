`timescale 1ns/1ps

module tb_B;

    // Signals
    reg clk;
    reg rst;
    reg start;
    reg [3:0] Data_in1;
    reg [3:0] Data_in2;
    wire [7:0] Data_out;
    reg t_ready;
    reg [127:0] result;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate the B module
    B uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .T_Ready(t_ready),
        .Data_in1(Data_in1),
        .Data_in2(Data_in2),
        .Data_out(Data_out)
    );

    // Dump waves
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_B);
    end

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to send 64-bit numbers as nibbles
    task send_64bit(input [63:0] num1, input [63:0] num2);
        integer i;
        begin
            rst = 1;
        start = 0;
       
        @(posedge clk);  // hold reset at least 1 clock
        rst = 0;
        @(posedge clk);  // give FSM a clock to exit reset

            for (i = 15; i >= 0; i = i - 1) begin
                Data_in1 = num1[i*4 +: 4];
                Data_in2 = num2[i*4 +: 4];
                start = (i == 15); // only first nibble pulses 'start'
                @(posedge clk);
            end
            Data_in1 = 0;
            Data_in2 = 0;
            start = 0;
        end
    endtask

    // Task to receive 128-bit product
    task receive_product(output reg [127:0] product);
        integer i;
        begin
            product = 0;

            // Wait for first valid byte
            i = 0;
            do begin
                @(posedge clk);
            end while (!(t_ready && Data_out !== 8'hFF));

            product[0 +: 8] = Data_out;

            // Capture remaining 15 bytes
            for (i = 1; i < 16; ) begin
                @(posedge clk);
                if (t_ready) begin
                    product[i*8 +: 8] = Data_out;
                    i = i + 1;
                end
            end
        end
    endtask

    // Task to receive and check product automatically
    task receive_and_check(input [127:0] expected_product);
        reg [127:0] product;
        begin
            receive_product(product);
            $display("TB:[%0t] Received product = %032h (expected %032h)",$time, product, expected_product);
            if (product === expected_product) begin
                $display("TB: PASS ✅");
                pass_count = pass_count + 1;
            end else begin
                $display("TB: FAIL ❌");
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Initialize ready signal
    initial t_ready = 1;

    // Main test sequence
    initial begin
        // Reset
        rst = 1;
        start = 0;
        Data_in1 = 0;
        Data_in2 = 0;
        t_ready = 1;
        #20;
        @(posedge clk);
        rst = 0;

        // ---- Test 1: 1*8 ----
        send_64bit(64'h0000000000000001, 64'h0000000000000008);
        receive_and_check(128'd8);

        // ---- Test 2: 2*3 ----
        send_64bit(64'h0000000000000002, 64'h0000000000000003);
        receive_and_check(128'd6);

        // Uncomment for additional edge cases or regression tests
        
        send_64bit(64'hFAFAFAFAFAFAFAFA, 64'hFAFAFAFAFAFAFAFA);
        receive_and_check(128'hFAFAFAFAFAFAFAFA * 128'hFAFAFAFAFAFAFAFA);

        send_64bit(64'hFFFFFFFFFFFFFFFF, 64'hFFFFFFFFFFFFFFFF);
        receive_and_check(128'hFFFFFFFFFFFFFFFF * 128'hFFFFFFFFFFFFFFFF);

        send_64bit(64'h1000000000000000, 64'h1000000000000000);
        receive_and_check(128'd0);

        repeat (20) begin
            automatic bit [63:0] A = $urandom();
            automatic bit [63:0] B = $urandom();
            $display("TB: Sending random A=%h, B=%h", A, B);
            send_64bit(A, B);
            receive_and_check(128'(A) * 128'(B));
        end
        

        // Finish
        $display("TB: All done at time %0t", $time);
        $display("TB: Total PASS = %0d, Total FAIL = %0d", pass_count, fail_count);
        $finish;
    end

endmodule
