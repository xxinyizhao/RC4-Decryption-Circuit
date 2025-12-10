/* To test tasks 3, 4, and 5 with sample .mif ct_mem files, 
these two lines in ct_mem.v were included: */
// altsyncram_component.init_file = "demo.mif",
// altsyncram_component.init_file_layout = "PORT_A";
/* This testbench displays the pt_mem contents to be verified qualitatively to ensure 
that there is a valid ASCII message. */
`timescale 1ps/1ps
module tb_rtl_task4();

    // DUT input and output signals:
    logic clk;
    logic [3:0] KEY;
    logic [9:0] SW, LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // instantiate DUT
    task4 DUT(.CLOCK_50(clk), .KEY(KEY), .SW(SW), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
             .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .LEDR(LEDR));

    // Debugging signals:
    logic err, totalerr;
    logic [2:0] s, t;
    
    // Declare state constants: 
    localparam logic [1:0]
        IDLE = 2'b00,
        WORKING = 2'b01,
        DONE = 2'b10,
        START = 2'b11;

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

    task checksig;  
    input expected_en;
    begin
        assert(expected_en == DUT.en)
            else begin
                err = 1'b1;
                $display("Error: incorrect en signal - Expected: %d, Actual: %d", expected_en, DUT.en);
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
        SW[9:0] = 10'b0000011000; // set key
        KEY[3] = 1'b1; #5; // active-low reset

        // TEST 1: Check reset and IDLE State
        KEY[3] = 1'b0; #5; // assert reset
        repeat(3) @(posedge clk);
        checkstate(IDLE);
        checksig(1'b0); 
        if (~err) begin
            $display("TEST 1 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
 
        KEY[3] = 1'b1; #5; //de-assert reset
        
        // TEST 2: Check START 
        @(posedge clk); #5;
        checkstate(START);
        checksig(1'b1);
        if (~err) begin
            $display("TEST 2 PASSED"); 
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 3: Check WORKING
        while(DUT.rdy) @(posedge clk);
        @(posedge clk);
        checkstate(WORKING);
        checksig(1'b0);
        if (~err) begin
            $display("TEST 3 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
 
        // TEST 4: Check DONE
        while(~DUT.rdy) @(posedge clk);
        @(posedge clk);
        checkstate(DONE);
        checksig(1'b0);
        if (~err) begin
            $display("TEST 4 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 4 FAILED"); 
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 5: CHeck if it stays in DONE
        @(posedge clk);
        @(posedge clk);
        checkstate(DONE);
        checksig(1'b0);
        if (~err) begin
            $display("TEST 5 PASSED");
            t = t + 3'd1;
        end else begin
            $display("TEST 5 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 6: Print output
        $display("Decrypted code: %p", DUT.c.pt.altsyncram_component.m_default.altsyncram_inst.mem_data);
        $display("Decrypted key: %h", DUT.c.key);
        $display("KEY_VALID = %b", DUT.c.key_valid);

        if (~totalerr) $display("ALL TESTS PASSED: %d / 4 States Passed, %d / 5 Transitions Passed", s, t);
        else $display("TESTS FAILED: %d / 4 States Passed, %d / 5 Transitions Passed", s, t);

    end


endmodule: tb_rtl_task4