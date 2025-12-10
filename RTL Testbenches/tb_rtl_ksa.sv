`timescale 1ps/1ps
module tb_rtl_ksa();
    // DUT input and output signals:
    logic clk, rst_n, en, rdy, wren;
    logic [7:0] addr, rddata, wrdata;
    logic [23:0] key;

    // Debugging signals:
    logic err, totalerr;
    logic [3:0] s, t; // s = number of states passed tests, t = number of transitions passed tests
    logic [7:0] test_i, test_j; // for debugging loop
    logic [7:0] S_mem  [0:255];
    logic [7:0] expected_S [0:255];
    integer n, mismatch_count;

    // Instantiate DUT:
    ksa DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .key(key), .addr(addr), .rddata(rddata), .wrdata(wrdata), .wren(wren));

    // Declare state constants:
    localparam logic [4:0]
        IDLE = 5'd0,
        RDI1 = 5'd1,
        RDI2 = 5'd2,
        CALCJ = 5'd3,
        RDJ1 = 5'd4,
        RDJ2 = 5'd5,
        WRTI1 = 5'd6,
        WRTI2 = 5'd7,
        WRTJ1 = 5'd8, 
        WRTJ2 = 5'd9,
        INCREI = 5'd10,
        LOOP = 5'd11,
        START = 5'd12;
    
    // Checking current state:
    task checkstate;
    input [4:0] expected_state;
    begin
        assert(expected_state == DUT.present_state)
            else begin
                err = 1'b1;
                $display("Error: incorrect state - Expected: %b, Actual: %b", expected_state, DUT.present_state);
            end
    end
    endtask

    // Checking output signals - rdy, wren, addr, wrdata:
    task checkoutputs;
    input expected_rdy, expected_wren;
    input [7:0] expected_addr, expected_wrdata;
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
    end 
    endtask 

    // Checking internal signals - count_i, count_j
    task checksig;
    input [7:0] expected_i, expected_j;
    begin
        assert(expected_i == DUT.count_i)
            else begin
                err = 1'b1;
                $display("Error: incorrect i - Expected: %d, Actual: %d", expected_i, DUT.count_i);
            end

        assert(expected_j == DUT.count_j)
            else begin
                err = 1'b1;
                $display("Error: incorrect j - Expected: %d, Actual: %d", expected_j, DUT.count_j);
            end
    end
    endtask

    // Generate clock signal:
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // Simulate memory reads - combinational
    always_comb begin
        rddata = S_mem[addr];
    end

    // Update S_mem when DUT writes to memory - sequential
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            // Initialize memory during reset
            for (int i = 0; i < 256; i = i + 1) begin
                S_mem[i] <= i[7:0];
            end
        end else if (wren) begin
            S_mem[addr] <= wrdata;
        end
    end


    // Start tests: 
    initial begin
        // Initialize debugging signals:
        err = 1'b0;
        totalerr = 1'b0;
        s = 4'b0;
        t = 4'b0;

        // Initialize inputs:
        rst_n = 1'b1; // active-low
        en = 1'b0; #5;
        key = 24'b00000000_00000011_00111100; // set key input to the provided example

        // TEST 1: Check Reset and IDLE State
        rst_n = 1'b0; #5; // assert reset
        @(posedge clk);
        checkstate(IDLE);
        checkoutputs(1'b1, 1'b0, 8'd0, 8'd0);
        checksig(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 1 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 2: Check START State and IDLE -> START
        rst_n = 1'b1; #5; // de-assert reset
        en = 1'b1; #5; // assert en
        @(posedge clk);
        checkstate(START);
        checkoutputs(1'b1, 1'b0, 8'd0, 8'd0);
        checksig(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 2 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 3: Check RDI1 State and START -> RDI1
        rst_n = 1'b1; #5;// de-assert reset
        @(posedge clk);
        checkstate(RDI1);
        checkoutputs(1'b0, 1'b0, 8'd0, 8'd0);
        checksig(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 3 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
        
        en = 1'b0; // deassert en
        // TEST 4: Check RDI2 State and RDI1 -> RDI2
        @(posedge clk);
        checkstate(RDI2);
        checkoutputs(1'b0, 1'b0, 8'd0, 8'd0);
        checksig(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 4 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 4 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 5: Check CALCJ State and RDI2 -> CALCJ
        @(posedge clk);
        checkstate(CALCJ);
        checkoutputs(1'b0, 1'b0, 8'd0, 8'd0);
        checksig(8'd0, key[23:16]); // j = 0 + 0 + KEY[0] -- not sure if this is right
        if (~err) begin
            $display("TEST 5 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 5 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 6: Check RDJ1 and CALCJ -> RDJ1
        @(posedge clk);
        checkstate(RDJ1);
        checkoutputs(1'b0, 1'b0, key[23:16], 8'd0);
        checksig(8'd0, key[23:16]);
        if (~err) begin
            $display("TEST 6 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 6 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 7: Check RDJ2 and RDJ1 -> RDJ2
        @(posedge clk);
        checkstate(RDJ2);
        checkoutputs(1'b0, 1'b0, key[23:16], 8'd0);
        checksig(8'd0, key[23:16]);
        if (~err) begin
            $display("TEST 7 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 7 FAILED");
            err = 1'b0; 
            totalerr = 1'b1;
        end

        // TEST 8: Check WRTI1 and RDJ2 -> WRTI1
        @(posedge clk);
        checkstate(WRTI1);
        checkoutputs(1'b0, 1'b0, 8'd0, 8'd0); 
        checksig(8'd0, key[23:16]);
        if (~err) begin
            $display("TEST 8 PASSED");
            s = s + 4'd1;
            t = t + 4'd1; 
        end else begin
            $display("TEST 8 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 9: Check WRTI2 and WRTI1 -> WRTI2
        @(posedge clk);
        checkstate(WRTI2);
        checkoutputs(1'b0, 1'b1, 8'd0, 8'd0);
        checksig(8'd0, key[23:16]);
        if (~err) begin
            $display("TEST 9 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 9 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 10: Check WRTJ1 and WRTI2 -> WRTJ1
        @(posedge clk);
        checkstate(WRTJ1);
        checkoutputs(1'b0, 1'b0, 8'd0, 8'd0); // temp_i = s[0] = 0
        checksig(8'd0, key[23:16]);
        if (~err) begin
            $display("TEST 10 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 10 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 11: Check WRTJ2 and WRTJ1 -> WRTJ2
        @(posedge clk);
        checkstate(WRTJ2);
        checkoutputs(1'b0, 1'b1, 8'd0, 8'd0);
        checksig(8'd0, key[23:16]);
        if (~err) begin
            $display("TEST 11 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 11 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
        
        // TEST 12: Check INCREI and WRTJ2 -> INCREI
        @(posedge clk);
        checkstate(INCREI);
        @(posedge clk);
        checkoutputs(1'b0, 1'b0, 8'd0, 8'd0);
        checksig(8'd1, key[23:16]);
        if (~err) begin
            $display("TEST 12 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 12 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 13: Check INCREI -> LOOP
        checkstate(LOOP);
        checkoutputs(1'b0, 1'b0, 8'd0, 8'd0); // addr and wrdata are not updated in RDI1
        checksig(8'd1, key[23:16]);
        if (~err) begin
            $display("TEST 13 PASSED");
            t = t + 4'd1;
        end else begin
            $display("TEST 13 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end 

        // Loop through states until count_i = 255
        test_i = 8'd1;

        while(!(DUT.present_state == IDLE)) @(posedge clk);

    // TEST 14: Check LOOP -> IDLE
        @(posedge clk);
        checkstate(IDLE);
        checkoutputs(1'b1, 1'b0, 8'd0, 8'd0);
        checksig(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 14 PASSED"); 
            s = s+4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 14 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

    // TEST 15: stay in IDLE?
        @(posedge clk);
        checkstate(IDLE);
        checkoutputs(1'b1, 1'b0, 8'd0, 8'd0);
        checksig(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 15 PASSED"); 
        end else begin
            $display("TEST 15 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end 
        
    // TEST 16: Verify final S_mem contents
    // Initialize expected S array with the correct final values
    expected_S = '{
        8'hb4, 8'h04, 8'h2b, 8'he5, 8'h49, 8'h0a, 8'h90, 8'h9a, 8'he4, 8'h17, 8'hf4, 8'h10, 8'h3a, 8'h36, 8'h13, 8'h77,
        8'h11, 8'hc4, 8'hbc, 8'h38, 8'h4f, 8'h6d, 8'h98, 8'h06, 8'h6e, 8'h3d, 8'h2c, 8'hae, 8'hcd, 8'h26, 8'h40, 8'ha2,
        8'hc2, 8'hda, 8'h67, 8'h68, 8'h5d, 8'h3e, 8'h02, 8'h73, 8'h03, 8'haa, 8'h94, 8'h69, 8'h6a, 8'h97, 8'h6f, 8'h33,
        8'h63, 8'h5b, 8'h8a, 8'h58, 8'hd9, 8'h61, 8'hf5, 8'h46, 8'h96, 8'h55, 8'h7d, 8'h53, 8'h5f, 8'hab, 8'h07, 8'h9c,
        8'ha7, 8'h72, 8'h31, 8'ha9, 8'hc6, 8'h3f, 8'hf9, 8'h91, 8'hf2, 8'hf6, 8'h7c, 8'hc7, 8'hb3, 8'h1d, 8'h20, 8'h88,
        8'ha0, 8'hba, 8'h0c, 8'h85, 8'he1, 8'hcf, 8'hcb, 8'h51, 8'hc0, 8'h2e, 8'hef, 8'h80, 8'h76, 8'hb2, 8'hd6, 8'h71,
        8'h24, 8'had, 8'h6b, 8'hdb, 8'hff, 8'hfe, 8'hed, 8'h84, 8'h4e, 8'h8c, 8'hbb, 8'hd3, 8'ha5, 8'h2f, 8'hbe, 8'hc8,
        8'h0e, 8'h8f, 8'hd1, 8'ha6, 8'h86, 8'he3, 8'h62, 8'hb0, 8'h87, 8'hec, 8'hb9, 8'h78, 8'h81, 8'he0, 8'h4d, 8'h5a,
        8'h7a, 8'h79, 8'h14, 8'h29, 8'h56, 8'he8, 8'h4a, 8'h8e, 8'h18, 8'hc5, 8'hca, 8'hb7, 8'h25, 8'hde, 8'h99, 8'hc3,
        8'h2a, 8'h65, 8'h30, 8'h1a, 8'hea, 8'hfb, 8'ha1, 8'h89, 8'h35, 8'ha4, 8'h09, 8'ha3, 8'hc1, 8'hd8, 8'h2d, 8'hb8,
        8'h60, 8'h47, 8'h39, 8'hbd, 8'h1f, 8'h05, 8'h5e, 8'h43, 8'hb1, 8'hdd, 8'he9, 8'h1c, 8'haf, 8'h9b, 8'hfa, 8'h01,
        8'hf7, 8'h08, 8'h75, 8'hb6, 8'h82, 8'hce, 8'h42, 8'he2, 8'hcc, 8'h9e, 8'heb, 8'h27, 8'h22, 8'hdf, 8'hbf, 8'hfc,
        8'h0d, 8'hd0, 8'h95, 8'h23, 8'hd2, 8'ha8, 8'h7e, 8'h74, 8'h4c, 8'hd7, 8'h12, 8'h7f, 8'hfd, 8'h83, 8'h1e, 8'h28,
        8'h64, 8'h54, 8'h3c, 8'h21, 8'hdc, 8'hf3, 8'h93, 8'h59, 8'h8b, 8'h7b, 8'h00, 8'h48, 8'he7, 8'h6c, 8'hd5, 8'hc9,
        8'h70, 8'h9f, 8'hac, 8'h41, 8'h0b, 8'hf0, 8'h19, 8'hb5, 8'h8d, 8'h16, 8'hd4, 8'hf1, 8'h92, 8'h9d, 8'h66, 8'h44,
        8'h4b, 8'h15, 8'h45, 8'hf8, 8'h0f, 8'h57, 8'h34, 8'h32, 8'h50, 8'h52, 8'hee, 8'h3b, 8'h5c, 8'h37, 8'he6, 8'h1b
    };

    mismatch_count = 0;
    $display("\n=== Checking Final S_mem Contents ===");
    for (n = 0; n < 256; n = n + 1) begin
        if (S_mem[n] !== expected_S[n]) begin
            $display("Mismatch at S[%3d]: Expected %02h, Got %02h", n, expected_S[n], S_mem[n]);
            mismatch_count = mismatch_count + 1;
        end
    end

    if (mismatch_count == 0) begin
        $display("TEST 16 PASSED - All S_mem values match expected results");
    end else begin
        $display("TEST 16 FAILED - %d mismatches found in S_mem", mismatch_count);
        totalerr = 1'b1;
    end

        if (~totalerr) $display("ALL TESTS PASSED: %d / 13 States Passed, %d / 14 Transitions Passed", s, t);
        else $display("TESTS FAILED: %d / 13 States Passed, %d / 14 Transitions Passed", s, t);

    end

    
endmodule: tb_rtl_ksa
