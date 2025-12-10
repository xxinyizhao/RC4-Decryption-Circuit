`timescale 1ps/1ps

module tb_syn_prga();

//vsim -t 1ps -L cyclonev_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate_ver -L altera_lnsim_ver work.tb_syn_prga used in modelsim to run syntheis
    // DUT signals
 
    logic clk, rst_n, en, s_wren, pt_wren, rdy;
    logic err, totalerr;
    logic [15:0] s_count, t_count;
    
    logic [7:0] s_addr, s_wrdata;
    logic [7:0] ct_addr;
    logic [7:0] pt_addr, pt_wrdata;
    logic [7:0] ct_rddata, s_rddata, pt_rddata;
    logic [23:0] key;

    // Memories
    logic [7:0] S_mem  [0:255];
    logic [7:0] CT_mem [0:255];
    logic [7:0] PT_mem [0:255];
    
    // Expected model variables this is what we should be getting if algorithm works fine
    logic [7:0] exp_S [0:255];
    logic [7:0] exp_i, exp_j, exp_temp_i, exp_temp_j, exp_pad, exp_pt, exp_ct;
    logic [7:0] mlen;
    
    // Expected output signals
    logic [7:0] exp_s_addr, exp_s_wrdata, exp_pt_addr, exp_pt_wrdata, exp_ct_addr;

    integer n, k;

    // State parameters
    localparam logic [4:0]
        IDLE = 5'd0,
        RDLEN = 5'd1,
        WRLEN = 5'd2,
        CALCI = 5'd3,
        RDI1 = 5'd4,
        RDI2 = 5'd5,
        CALCJ = 5'd6,
        RDJ1 = 5'd7,
        RDJ2 = 5'd8,
        WRI = 5'd9,
        WRJ = 5'd10,
        RDSP1 = 5'd11, 
        RDSP2 = 5'd12,
        RDC1 = 5'd13,
        RDC2 = 5'd14,
        XOR = 5'd15,
        INCR = 5'd16,  
        LOOP = 5'd17;

    // Instantiate DUT
    prga DUT(.clk(clk), .rst_n(rst_n),
            .en(en), .rdy(rdy),
            .key(key),
            .s_addr(s_addr), .s_rddata(s_rddata), .s_wrdata(s_wrdata), .s_wren(s_wren),
            .ct_addr(ct_addr), .ct_rddata(ct_rddata),
            .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

    // Clock generation
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // Memory connections
    assign ct_rddata = CT_mem[ct_addr];
    assign s_rddata  = S_mem[s_addr];
    assign pt_rddata = PT_mem[pt_addr];

    always @(posedge clk) begin
        if (s_wren)
            S_mem[s_addr] <= s_wrdata;
        if (pt_wren)
            PT_mem[pt_addr] <= pt_wrdata;
    end

    // ========== CHECK TASKS ==========

    task check_1bit_signals;
        input expected_rdy, expected_s_wren, expected_pt_wren;
        begin
            if (expected_rdy !== rdy) begin
                err = 1'b1;
                $display("Error: incorrect rdy - Expected: %d, Actual: %d", expected_rdy, rdy);
            end
            if (expected_s_wren !== s_wren) begin
                err = 1'b1;
                $display("Error: incorrect s_wren - Expected: %d, Actual: %d", expected_s_wren, s_wren);
            end
            if (expected_pt_wren !== pt_wren) begin
                err = 1'b1;
                $display("Error: incorrect pt_wren - Expected: %d, Actual: %d", expected_pt_wren, pt_wren);
            end
        end
    endtask

    task checkoutputsignals;
        input [7:0] expected_s_addr, expected_s_wrdata, expected_pt_addr, expected_pt_wrdata, expected_ct_addr;
        begin
            if (expected_s_addr !== s_addr) begin
                err = 1'b1;
                $display("Error: incorrect s_addr - Expected: %d, Actual: %d", expected_s_addr, s_addr);
            end
            if (expected_s_wrdata !== s_wrdata) begin
                err = 1'b1;
                $display("Error: incorrect s_wrdata - Expected: %d, Actual: %d", expected_s_wrdata, s_wrdata);
            end
            if (expected_pt_addr !== pt_addr) begin
                err = 1'b1;
                $display("Error: incorrect pt_addr - Expected: %d, Actual: %d", expected_pt_addr, pt_addr);
            end
            if (expected_pt_wrdata !== pt_wrdata) begin
                err = 1'b1;
                $display("Error: incorrect pt_wrdata - Expected: %d, Actual: %d", expected_pt_wrdata, pt_wrdata);
            end
            if (expected_ct_addr !== ct_addr) begin
                err = 1'b1;
                $display("Error: incorrect ct_addr - Expected: %d, Actual: %d", expected_ct_addr, ct_addr);
            end
        end
    endtask

    // ========== MAIN TEST ==========
    initial begin
        err = 1'b0;
        totalerr = 1'b0;
        s_count = 8'd0;
        t_count = 8'd0;

        // Initialize memories
        for (n = 0; n < 256; n = n + 1) begin
            S_mem[n]  = n[7:0];
            CT_mem[n] = 8'h00;
            PT_mem[n] = 8'h00;
            exp_S[n] = n[7:0];
        end

        // Load ciphertext
        $readmemh("test1.memh", CT_mem);
        
        // Initialize expected model
        exp_i = 8'd0;
        exp_j = 8'd0;
        
        // Initialize expected output signals
        exp_s_addr = 8'd0;
        exp_s_wrdata = 8'd0;
        exp_pt_addr = 8'd0;
        exp_pt_wrdata = 8'd0;
        exp_ct_addr = 8'd0;

        // Initialize inputs
        rst_n = 1'b1;
        en = 1'b0;
        
        // ===== TEST 1=====
        rst_n = 1'b0; #5;
        @(posedge clk); #5;
       
        check_1bit_signals(1'b1, 1'b0, 1'b0);
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0, 8'd0);
        if (~err) begin
            $display("TEST 1 PASSED");
            s_count = s_count + 8'd1;
            t_count = t_count + 8'd1;
        end else begin 
            $display("TEST 1 FAILED"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        rst_n = 1'b1; #5;
        
        // ===== TEST 2 =====
        @(posedge clk); #5;
        
        check_1bit_signals(1'b1, 1'b0, 1'b0);
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0, 8'd0);
        if (~err) begin
            $display("TEST 2 PASSED");
            t_count = t_count + 8'd1;
        end else begin 
            $display("TEST 2 FAILED"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        // ===== TEST 3 =====
        en = 1'b1; #5; //enable set high
        @(posedge clk); #5;
        exp_ct_addr = 8'd0;
       
        check_1bit_signals(1'b0, 1'b0, 1'b0);
        checkoutputsignals(exp_s_addr, exp_s_wrdata, exp_pt_addr, exp_pt_wrdata, exp_ct_addr);
        if (~err) begin
            $display("TEST 3 PASSED");
            s_count = s_count + 8'd1;
            t_count = t_count + 8'd1;
        end else begin 
            $display("TEST 3 FAILED"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        mlen = CT_mem[0];

        // ===== TEST 4 ===== pt_wrdata = mlen pt_wren=1
        @(posedge clk); #5;   
        exp_pt_addr = 8'd0;
        exp_pt_wrdata = 8'd0; //read mlength in the previous state RDLEN so now just write it to memory
   
        check_1bit_signals(1'b0, 1'b0, 1'b0); //pt_wren is high
        checkoutputsignals(exp_s_addr, exp_s_wrdata, exp_pt_addr, exp_pt_wrdata, exp_ct_addr);
        if (~err) begin
            $display("TEST 4 PASSED");
            s_count = s_count + 8'd1;
            t_count = t_count + 8'd1;
        end else begin 
            $display("TEST 4 FAILED"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end


    end 
endmodule: tb_syn_prga
