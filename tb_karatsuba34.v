module tb_karatsuba34;

    logic clk, rst, start;
    logic [33:0] A, B;
    logic [67:0] P;
    logic valid_out;

    // Instantiate the DUT
    karatsuba34 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .B(B),
        .P(P),
        .valid_out(valid_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz
logic [67:0] Pt ;
initial begin
    rst = 1;
    start = 0;
    A = 0;
    B = 0;
    #20;
    rst = 0;

    // Test1: large numbers
    A = 34'h0FFFFFFF; 
    B = 34'h0FFFFFFF;
    Pt=A*B;
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;
    wait(valid_out);
    $display("Test2: A=%h B=%h => P=%h =>Pt=%h", A, B, P,Pt);

    // // Test2: medium numbers
    // A = 34'h00000FFFF;
    // B = 34'h00000AAAA;
    // @(posedge clk);
    // start = 1;
    // @(posedge clk);
    // start = 0;
    // wait(valid_out);
    // $display("Test2: A=%h B=%h => P=%h =>Pt=%h", A, B, P,A*B);

    // // Test3: small numbers
    // A = 34'h000003FFF;
    // B = 34'h000002AAA;
    // @(posedge clk);
    // start = 1;
    // @(posedge clk);
    // start = 0;
    // wait(valid_out);
    // $display("Test3: A=%h B=%h => P=%h =>Pt=%h", A, B, P,A*B);

    $finish;
end


endmodule
