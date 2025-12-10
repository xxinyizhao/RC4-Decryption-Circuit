`timescale 1ps/1ps
module tb_syn_crack();
    // DUT input and output signals:
    logic clk, rst_n, en, rdy, key_valid;
    logic [7:0] ct_rddata, ct_addr;
    logic [23:0] key;

    //Instantiate DUT
    crack DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .key(key), .key_valid(key_valid),
              .ct_addr(ct_addr), .ct_rddata(ct_rddata));

    // debugging signals:
    logic err, totalerr;
    logic [3:0] t;
    logic [23:0] expected_key = 24'h000001;
    logic [7:0] test_ct [0:255] = 
        '{8'h56, 8'hC1, 8'hD4, 8'h8C, 8'h33, 8'hC5, 8'h52, 8'h01, 8'h04, 8'hDE, 8'hCF, 8'h12, 8'h22, 8'h51, 8'hFF, 8'h1B,
        8'h36, 8'h81, 8'hC7, 8'hFD, 8'hC4, 8'hF2, 8'h88, 8'h5E, 8'h16, 8'h9A, 8'hB5, 8'hD3, 8'h15, 8'hF3, 8'h24, 8'h7E,
        8'h4A, 8'h8A, 8'h2C, 8'hB9, 8'h43, 8'h18, 8'h2C, 8'hB5, 8'h91, 8'h7A, 8'hE7, 8'h43, 8'h0D, 8'h27, 8'hF6, 8'h8E,
        8'hF9, 8'h18, 8'h79, 8'h70, 8'h91, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00};

    // Checking output signals - rdy, key_valid:
    task checkoutputs;
    input expected_rdy, expected_key_valid;
    begin
        assert(expected_rdy == rdy)
            else begin
                err = 1'b1;
                $display("Error: incorrect rdy - Expected: %d, Actual: %d", expected_rdy, rdy);
            end
        
        assert(expected_key_valid === key_valid)
            else begin
                err = 1'b1;
                $display("Error: incorrect key_valid - Expected: %d, Actual: %d", expected_key_valid, key_valid);
            end
    end 
    endtask 

    // simulating reading from test_ct
    always_comb begin
        ct_rddata = test_ct[ct_addr];
    end

    // Generate clock signal:
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    initial begin
        // Initialize debugging signals:
        err = 1'b0;
        totalerr = 1'b0;
        t = 4'b0;

        // Initialize inputs:
        rst_n = 1'b1; // active-low
        en = 1'b0; #5;

        // TEST 1: Check Reset and IDLE State
        rst_n = 1'b0; #5; // assert reset
        @(posedge clk);
        checkoutputs(1'b1, 1'bx); // key_valid should be unknown here
        if (~err) begin
            $display("TEST 1 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 2: IDLE -> START A4
        rst_n = 1'b1; #5; // de-assert reset
        en = 1'b1; #5; // assert en

        @(posedge clk);
        checkoutputs(1'b0, 1'bx);
        if (~err) begin
            $display("TEST 2 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 3: STARTA4 -> ARC4
        repeat(2) @(posedge clk);
        checkoutputs(1'b0, 1'bx);
        if (~err) begin
            $display("TEST 3 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 4: ARC4 -> RDLEN1
        while(~DUT.a_rdy) @(posedge clk);
        @(posedge clk);
        checkoutputs(1'b0, 1'bx); 
        if (~err) begin
            $display("TEST 4 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 4 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 5: RDLEN1 -> RDLEN2
        @(posedge clk);
        checkoutputs(1'b0, 1'bx); 
        if (~err) begin
            $display("TEST 5 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 5 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 6: RDLEN2 -> RDP1
        @(posedge clk);
        checkoutputs(1'b0, 1'b1); // key_valid = 1 here
        if (~err) begin
            $display("TEST 6 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 6 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 7: RDP1 -> RDP2
        @(posedge clk);
        checkoutputs(1'b0, 1'b1); 
        if (~err) begin
            $display("TEST 7 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 7 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 8: RDP2 -> INCRA
        @(posedge clk);
        checkoutputs(1'b0, 1'b1); 
        if (~err) begin
            $display("TEST 8 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 8 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 9: INCRA -> CHECKA
        @(posedge clk);
        checkoutputs(1'b0, 1'b0); // key_valid = 0 after check
        if (~err) begin
            $display("TEST 9 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 9 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 10: CHECKA -> INCRK
        @(posedge clk);
        checkoutputs(1'b0, 1'b0); 
        if (~err) begin
            $display("TEST 10 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 10 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 11: INCRK -> CHECKK
        @(posedge clk);
        checkoutputs(1'b0, 1'b0); 
        if (~err) begin
            $display("TEST 11 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 11 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 12: CHECKK -> STARTA4
        @(posedge clk);
        checkoutputs(1'b0, 1'b0); 
        if (~err) begin
            $display("TEST 12 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 12 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // Go back to IDLE
        while(~key_valid) @(posedge clk);
        repeat(2) @(posedge clk);

        // check final key:
        if (key != expected_key) begin
            $display("INCORRECT KEY - Expected: %h, actual: %h", expected_key, key);
            err = err + 1'b1;
            totalerr = 1'b1;
        end else $display("CORRECT KEY");

        if (~totalerr) $display("ALL TESTS PASSED: %d / 12 Transitions Passed", s, t);
        else $display("TESTS FAILED: %d / 12 Transitions Passed", s, t);

    end



endmodule: tb_syn_crack