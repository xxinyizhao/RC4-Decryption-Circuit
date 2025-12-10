`timescale 1ps/1ps

// vsim -t 1ps -L cyclonev_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate_ver -L altera_lnsim_ver work.tb_syn_arc4

module tb_syn_arc4();
    // DUT input and output signals
    logic clk, rst_n, en, rdy, pt_wren;
    logic [7:0] ct_addr, ct_rddata, pt_addr, pt_rddata, pt_wrdata;
    logic [23:0] key;

    // Debugging signals
    logic err, totalerr;

    // Memories
    logic [7:0] CT_mem [0:255];
    logic [7:0] PT_mem [0:255];
    logic [7:0] Expected_PT [0:255];

    integer i, n;
    integer timeout_counter;

    // Instantiate DUT
    arc4 DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .key(key), 
             .ct_addr(ct_addr), .ct_rddata(ct_rddata),
             .pt_addr(pt_addr), .pt_rddata(pt_rddata), 
             .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

    // Clock generation
    initial clk = 1'b0;
    always #10 clk = ~clk;  // 20ps period

    // Memory connections
    assign ct_rddata = CT_mem[ct_addr];
    assign pt_rddata = PT_mem[pt_addr];

    always @(posedge clk) begin
        if (pt_wren)
            PT_mem[pt_addr] <= pt_wrdata;
    end

    // ========== CHECK TASKS ==========
    
    task check_rdy;
        input expected_rdy;
        begin
            if (rdy !== expected_rdy) begin
                err = 1'b1;
                $display("Error: rdy - Expected: %b, Actual: %b", expected_rdy, rdy);
            end
        end
    endtask

    // ========== MAIN TEST ==========
    
    initial begin
        err = 1'b0;
        totalerr = 1'b0;

        // Initialize memories
        for (n = 0; n < 256; n = n + 1) begin
            CT_mem[n] = 8'h00;
            PT_mem[n] = 8'h00;
            Expected_PT[n] = 8'h00;
        end

        // Load ciphertext
        $readmemh("test1.memh", CT_mem);
        
        // Load expected plaintext (you need to create this file)
        $readmemh("test1_pt.memh", Expected_PT);

        // Initialize inputs
        rst_n = 1'b1;
        en = 1'b0;
        key = 24'b000000000000001100111100;
 
        // ===== TEST 1: Reset =====
        $display("\n=== TEST 1: Reset ===");
        rst_n = 1'b0;
        repeat(5) @(posedge clk);
        @(posedge clk); #15;
        
        check_rdy(1'b1);

        if (~err) begin
            $display("TEST 1 PASSED: Reset - rdy is high");
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // ===== TEST 2: Start processing =====
        $display("\n=== TEST 2: Start ARC4 processing ===");
        rst_n = 1'b1;
        en = 1'b1;
        @(posedge clk); #15;
        
        // rdy should go low indicating processing has started
        check_rdy(1'b0);

        if (~err) begin
            $display("TEST 2 PASSED: Processing started - rdy went low");
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        en = 1'b0;

        // ===== TEST 3: Wait for completion =====
        $display("\n=== TEST 3: Wait for ARC4 to complete ===");
        $display("Waiting for processing to complete...");
        
        timeout_counter = 0;
        while (rdy == 1'b0 && timeout_counter < 100000) begin
            @(posedge clk);
            timeout_counter = timeout_counter + 1;
            if (timeout_counter % 1000 == 0) begin
                $display("  Still processing... (%0d cycles)", timeout_counter);
            end
        end
        
        @(posedge clk); #15;

        if (timeout_counter >= 100000) begin
            $display("ERROR: Timeout waiting for completion");
            totalerr = 1'b1;
        end else begin
            check_rdy(1'b1);
            if (~err) begin
                $display("TEST 3 PASSED: Processing completed in %0d cycles - rdy went high", 
                         timeout_counter);
            end else begin
                $display("TEST 3 FAILED");
                err = 1'b0;
                totalerr = 1'b1;
            end
        end

        // ===== TEST 4: Verify plaintext output =====
        $display("\n=== TEST 4: Verify decrypted plaintext ===");
        
        for (i = 0; i < 256; i = i + 1) begin
            if (PT_mem[i] !== Expected_PT[i]) begin
                $display("ERROR: PT_mem[%0d] = %02h, expected %02h", 
                         i, PT_mem[i], Expected_PT[i]);
                err = 1'b1;
                // Only show first 10 errors to avoid flooding
                if (err) break;
            end
        end
        
        if (~err) begin
            $display("TEST 4 PASSED: Plaintext matches expected output");
        end else begin
            $display("TEST 4 FAILED: Plaintext mismatch");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // ===== TEST 5: Stay in IDLE when en=0 =====
        $display("\n=== TEST 5: Stay in IDLE ===");
        repeat(10) @(posedge clk);
        @(posedge clk); #15;
        
        check_rdy(1'b1);
        
        if (~err) begin
            $display("TEST 5 PASSED: Stays in IDLE with en=0");
        end else begin
            $display("TEST 5 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // ===== Summary =====
        $display("\n=== SUMMARY ===");
        $display("Total cycles: %0d", timeout_counter);
        
        if (~totalerr) 
            $display("\n=== ALL TESTS PASSED ===");
        else 
            $display("\n=== TESTS FAILED ===");
            
        $stop;
    end
    
endmodule: tb_syn_arc4
