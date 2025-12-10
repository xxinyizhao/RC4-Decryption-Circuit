// vsim -L altera_mf_ver work.tb_task1
`timescale 1ps/1ps
module tb_rtl_init();
    // DUT input and output signals:
    logic clk, rst_n, en, rdy, wren;
    logic [7:0] addr, wrdata; 
 
    // Debugging signals:
    logic err, totalerr;
    logic [2:0] s, t; // s = number of states passed tests, t = number of transitions passed tests
    logic [7:0] test_addr, test_wrdata; // for debugging loop

    // Instantiate DUT: 
    init DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .addr(addr), .wrdata(wrdata), .wren(wren));
    
    // Declare state constants: 
    localparam logic [1:0]
        IDLE = 2'b0,
        WRITE = 2'b1;

    // Checking current state:
    task checkstate;
    input [1:0] expected_state;
    begin
        assert(expected_state == DUT.present_state)
            else begin
                err = 1'b1;
                $display("Error: incorrect state - Expected: %b, Actual: %b", expected_state, DUT.present_state);
            end
    end
    endtask

    // Checking output signals - address and data:
    task checkoutputs;
    input [7:0] expected_addr, expected_wrdata;
    begin
        assert(expected_addr == addr)
            else begin
                err = 1'b1;
                $display("Error: incorrect address - Expected: %d, Actual: %d", expected_addr, addr);
            end

        assert(expected_wrdata == wrdata)
            else begin
                err = 1'b1;
                $display("Error: incorrect wrdata - Expected: %d, Actual: %d", expected_wrdata, wrdata);
            end

        // check if wrdata == addr (should be equal)
        assert (wrdata == addr)
            else begin
                err = 1'b1;
                $display("Error: addr and wrdata mismatch - addr: %d, wrdata: %d", addr, wrdata);
            end
    end
    endtask 

    // Checking output signals - rdy and wren
    task checksig;
    input expected_rdy, expected_wren;
    begin
        assert(expected_rdy == rdy)
            else begin
                err = 1'b1;
                $display("Error: incorrect rdy - Expected: %d, Actual: %d", expected_rdy, rdy);
            end
        
        assert(expected_wren == wren)
            else begin
                err = 1'b1;
                $display("Error: incorrect wren - Expected: %d, Actual: %d", expected_wren, wren);
            end
    end
    endtask

    // Generate clock signal:
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // Start tests:
    initial begin
                // Initialize debugging signals:
        err = 1'b0;
        totalerr = 1'b0;
        s = 3'b0;
        t = 3'b0;

        // Initialize inputs:
        rst_n = 1'b1; // active-low
        en = 1'b0; #5;
 
        // TEST 1: Check Reset and IDLE State
        rst_n = 1'b0; #5; // assert reset
        @(posedge clk);
        checkstate(IDLE);
        checksig(1'b1, 1'b0);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 1 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 2: Check WRITE State and IDLE -> WRITE
        rst_n = 1'b1; #5;// de-assert reset
        en = 1'b1; #5;// assert en
        @(posedge clk);
        checkstate(WRITE);
        checksig(1'b0, 1'b1);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 2 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        en = 1'b0; #5; // de-assert en

        while(rdy != 1'b1) @(posedge clk);
        @(posedge clk);

        // TEST 3: Loop through all states for 255 increments
        test_addr = 8'd0;
        test_wrdata = 8'd0;

        while(rdy != 1'b1) begin
            @(posedge clk);
            checkstate(WRITE);
            checksig(1'b0, 1'b0);
            checkoutputs(test_addr, test_wrdata);
            test_addr = test_addr + 8'd1;
            test_wrdata = test_wrdata + 8'd1;
        end

        if (~err) $display("TEST 3 PASSED -- all increments correct");
        else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end
  
        // TEST 4: Check return to IDLE State
        @(posedge clk);
        checkstate(IDLE);
        checksig(1'b1, 1'b0);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 4 PASSED");
            t = t + 3'd1;
        end else begin
            $display("TEST 4 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        if (~totalerr) $display("ALL TESTS PASSED: %d / 2 States Passed, %d / 3 Transitions Passed", s, t);
        else $display("TESTS FAILED: %d / 2 States Passed, %d / 3 Transitions Passed", s, t);

    end

endmodule: tb_rtl_init
