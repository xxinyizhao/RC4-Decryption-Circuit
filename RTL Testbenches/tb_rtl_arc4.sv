`timescale 1ps/1ps

module tb_rtl_arc4();
    // DUT input and output signals:
    logic clk, rst_n, en, rdy, pt_wren;
    logic [7:0] ct_addr, ct_rddata, pt_addr, pt_rddata, pt_wrdata;
    logic [23:0] key;

    // Debugging signals:
    logic err, totalerr;
    logic [2:0] s, t;

    // Memories
    logic [7:0] CT_mem [0:255];
    logic [7:0] PT_mem [0:255];

    logic [8:0] i,j,n;
    int timeout_counter;

    byte expected_S [0:255] = '{
        // expected_S array after KSA runs
        8'hb4, 8'h04, 8'h2b, 8'he5, 8'h49, 8'h0a, 8'h90, 8'h9a,
        8'he4, 8'h17, 8'hf4, 8'h10, 8'h3a, 8'h36, 8'h13, 8'h77,
        8'h11, 8'hc4, 8'hbc, 8'h38, 8'h4f, 8'h6d, 8'h98, 8'h06,
        8'h6e, 8'h3d, 8'h2c, 8'hae, 8'hcd, 8'h26, 8'h40, 8'ha2,
        8'hc2, 8'hda, 8'h67, 8'h68, 8'h5d, 8'h3e, 8'h02, 8'h73,
        8'h03, 8'haa, 8'h94, 8'h69, 8'h6a, 8'h97, 8'h6f, 8'h33,
        8'h63, 8'h5b, 8'h8a, 8'h58, 8'hd9, 8'h61, 8'hf5, 8'h46,
        8'h96, 8'h55, 8'h7d, 8'h53, 8'h5f, 8'hab, 8'h07, 8'h9c,
        8'ha7, 8'h72, 8'h31, 8'ha9, 8'hc6, 8'h3f, 8'hf9, 8'h91,
        8'hf2, 8'hf6, 8'h7c, 8'hc7, 8'hb3, 8'h1d, 8'h20, 8'h88,
        8'ha0, 8'hba, 8'h0c, 8'h85, 8'he1, 8'hcf, 8'hcb, 8'h51,
        8'hc0, 8'h2e, 8'hef, 8'h80, 8'h76, 8'hb2, 8'hd6, 8'h71,
        8'h24, 8'had, 8'h6b, 8'hdb, 8'hff, 8'hfe, 8'hed, 8'h84,
        8'h4e, 8'h8c, 8'hbb, 8'hd3, 8'ha5, 8'h2f, 8'hbe, 8'hc8,
        8'h0e, 8'h8f, 8'hd1, 8'ha6, 8'h86, 8'he3, 8'h62, 8'hb0,
        8'h87, 8'hec, 8'hb9, 8'h78, 8'h81, 8'he0, 8'h4d, 8'h5a,
        8'h7a, 8'h79, 8'h14, 8'h29, 8'h56, 8'he8, 8'h4a, 8'h8e,
        8'h18, 8'hc5, 8'hca, 8'hb7, 8'h25, 8'hde, 8'h99, 8'hc3,
        8'h2a, 8'h65, 8'h30, 8'h1a, 8'hea, 8'hfb, 8'ha1, 8'h89,
        8'h35, 8'ha4, 8'h09, 8'ha3, 8'hc1, 8'hd8, 8'h2d, 8'hb8,
        8'h60, 8'h47, 8'h39, 8'hbd, 8'h1f, 8'h05, 8'h5e, 8'h43,
        8'hb1, 8'hdd, 8'he9, 8'h1c, 8'haf, 8'h9b, 8'hfa, 8'h01,
        8'hf7, 8'h08, 8'h75, 8'hb6, 8'h82, 8'hce, 8'h42, 8'he2,
        8'hcc, 8'h9e, 8'heb, 8'h27, 8'h22, 8'hdf, 8'hbf, 8'hfc,
        8'h0d, 8'hd0, 8'h95, 8'h23, 8'hd2, 8'ha8, 8'h7e, 8'h74,
        8'h4c, 8'hd7, 8'h12, 8'h7f, 8'hfd, 8'h83, 8'h1e, 8'h28,
        8'h64, 8'h54, 8'h3c, 8'h21, 8'hdc, 8'hf3, 8'h93, 8'h59,
        8'h8b, 8'h7b, 8'h00, 8'h48, 8'he7, 8'h6c, 8'hd5, 8'hc9,
        8'h70, 8'h9f, 8'hac, 8'h41, 8'h0b, 8'hf0, 8'h19, 8'hb5,
        8'h8d, 8'h16, 8'hd4, 8'hf1, 8'h92, 8'h9d, 8'h66, 8'h44,
        8'h4b, 8'h15, 8'h45, 8'hf8, 8'h0f, 8'h57, 8'h34, 8'h32,
        8'h50, 8'h52, 8'hee, 8'h3b, 8'h5c, 8'h37, 8'he6, 8'h1b
    };

    arc4 DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .key(key), .ct_addr(ct_addr), 
            .ct_rddata(ct_rddata),.pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));
    
    // initialize states
    localparam logic [2:0]
        IDLE = 3'd0,
        INIT = 3'd1,
        INIT_WAIT = 3'd2,
        KSA = 3'd3,
        KSA_WAIT = 3'd4,
        PGRA = 3'd5,
        PGRA_WAIT = 3'd6;

    task checkstate;
        input [2:0] expected_state;  
        begin
            if (expected_state !== DUT.present_state) begin
                err = 1'b1;
                $display("Error: incorrect state - Expected: %d, Actual: %d", expected_state, DUT.present_state);
            end
        end
    endtask

    task check_en_rdy_signals;
        input expected_i_en, expected_i_rdy;
        input expected_k_en, expected_k_rdy;
        input expected_p_en, expected_p_rdy;
        begin
            if (DUT.i_en !== expected_i_en) begin
                err = 1'b1;
                $display("Error: i_en - Expected: %b, Actual: %b", expected_i_en, DUT.i_en);
            end
            if (DUT.i_rdy !== expected_i_rdy) begin
                err = 1'b1;
                $display("Error: i_rdy - Expected: %b, Actual: %b", expected_i_rdy, DUT.i_rdy);
            end
            if (DUT.k_en !== expected_k_en) begin
                err = 1'b1;
                $display("Error: k_en - Expected: %b, Actual: %b", expected_k_en, DUT.k_en);
            end
            if (DUT.k_rdy !== expected_k_rdy) begin
                err = 1'b1;
                $display("Error: k_rdy - Expected: %b, Actual: %b", expected_k_rdy, DUT.k_rdy);
            end
            if (DUT.p_en !== expected_p_en) begin
                err = 1'b1;
                $display("Error: p_en - Expected: %b, Actual: %b", expected_p_en, DUT.p_en);
            end
            if (DUT.p_rdy !== expected_p_rdy) begin
                err = 1'b1;
                $display("Error: p_rdy - Expected: %b, Actual: %b", expected_p_rdy, DUT.p_rdy);
            end
        end
    endtask

    initial clk = 1'b0;
    always #5 clk = ~clk;

    assign ct_rddata = CT_mem[ct_addr];
    assign pt_rddata = PT_mem[pt_addr];

    always @(posedge clk) begin
        if (pt_wren)
            PT_mem[pt_addr] <= pt_wrdata;
    end

    initial begin
        err = 1'b0;
        totalerr = 1'b0;
        s = 3'b0;
        t = 3'b0;

        for (n = 0; n < 256; n = n + 1) begin
            CT_mem[n] = 8'h00;
            PT_mem[n] = 8'h00;
        end

        $readmemh("test1.memh", CT_mem);

        rst_n = 1'b1;
        en = 1'b0;
        key = 24'b000000000000001100111100;
 
        // TEST 1: Reset
        rst_n = 1'b0;
        repeat(5) @(posedge clk);
        #1;
        
        checkstate(IDLE);
        check_en_rdy_signals(1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1);

/*        $display("DEBUG at IDLE - in IDLE first time:");
        $display("  i_en=%b, i_rdy=%b,", DUT.i_en, DUT.i_rdy );
        $display("  i.present_state=%d", DUT.i.present_state);*/

        $display("rdy in IDLE = %d", rdy);

        if (~err) begin
            $display("TEST 1 PASSED: Reset to IDLE");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 2: Transition to INIT
        rst_n = 1'b1;
        en = 1'b1;
        @(posedge clk); #5;
        //@(posedge clk);
        
        checkstate(INIT);
        check_en_rdy_signals(1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1);  // init enabled, still ready we havent started process yet

        $display("rdy in INIT = %d", rdy);

        if (~err) begin
            $display("TEST 2 PASSED: INIT state");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        @(posedge clk); #5;
         en = 1'b0;

        // TEST 3: INIT_WAIT and memory check
        $display("Waiting for INIT to complete...");
        wait(DUT.i_rdy == 1'b1 && DUT.present_state == INIT_WAIT);
        @(posedge clk);
        
        // Check memory
        for (i = 9'd0; i < 9'd256; i = i + 1) begin
            if (DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[i] !== i[7:0]) begin
                $display("ERROR: mem[%0d] = %h expected %h", i,
                         DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[i], i[7:0]);
                err = 1'b1;
            end
        end
        
        if (~err) begin
            $display("TEST 3 PASSED: S memory initialized 0-255");
        end else begin
            $display("TEST 3 FAILED: S memory incorrect");
            err = 1'b0;
            totalerr = 1'b1;
        end

        $display("rdy in INIT_WAIT = %d", rdy);

        // TEST 4: Transition to KSA  
        // Debug: Check init state before KSA transition
       /* $display("DEBUG before KSA:");
        $display("  i_en=%b, i_rdy=%b", DUT.i_en, DUT.i_rdy);
        $display("  i.present_state=%d, i.wrdata=%d", DUT.i.present_state, DUT.i.wrdata);
*/
        // TEST 4: Transition to KSA
/*
        $display("DEBUG at KSA - init right now:");
        $display("  k_en=%b, k_rdy=%b,", DUT.k_en, DUT.k_rdy );
        $display("  k.present_state=%d", DUT.k.present_state);
*/
        @(posedge clk);
        #1;

        /*$display("DEBUG at KSA:");
        $display("  i_en=%b, i_rdy=%b,", DUT.i_en, DUT.i_rdy );
        $display("  i.present_state=%d", DUT.i.present_state);
*/
        checkstate(KSA);

        $display("rdy in KSA = %d", rdy);

        check_en_rdy_signals(1'b0, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1);

        if (~err) begin
            $display("TEST 4 PASSED: KSA state");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 4 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

       /* $display("DEBUG at KSA - in KSA first time:");
        $display("  k_en=%b, k_rdy=%b,", DUT.k_en, DUT.k_rdy );
        $display("  k.present_state=%d", DUT.k.present_state);
*/
        @(posedge clk); #5;
/*
        $display("DEBUG at KSA - KSA after 1st clock edge:");
        $display("  k_en=%b, k_rdy=%b,", DUT.k_en, DUT.k_rdy );
        $display("  k.present_state=%d", DUT.k.present_state);
*/
        // TEST 5: KSA_WAIT and memory check
        $display("Waiting for KSA to complete...");
        wait(DUT.k_rdy == 1'b1 && DUT.present_state == KSA_WAIT);
        @(posedge clk);
        #1;
        $display("rdy in KSA_WAIT = %d", rdy);

  /*      $display("DEBUG at KSA - done with ksa:");
        $display("  k_en=%b, k_rdy=%b,", DUT.k_en, DUT.k_rdy );
        $display("  k.present_state=%d", DUT.k.present_state);
        $display("  k.count_i after reaching loop=%d", DUT.k.count_i);
  */      
        $display("Checking S array after KSA...");
        for (j = 0; j < 256; j = j + 1) begin
            if (DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[j] !== expected_S[j]) begin
                $display("ERROR: S[%0d] = %02h expected %02h", j,
                        DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[j],
                        expected_S[j]);
                err = 1'b1;
            end
        end
        
        if (~err) begin
            $display("TEST 5 PASSED: S memory after KSA correct");
        end else begin
            $display("TEST 5 FAILED: S memory incorrect after KSA");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 6: Transition to PGRA
        @(posedge clk);
        checkstate(PGRA);
        check_en_rdy_signals(1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1);  // prga enabled, still ready

        $display("rdy in PGRA = %d", rdy);

   /*     $display("DEBUG at PGRA - in PGRA first time:");
        $display("  p_en=%b, p_rdy=%b,", DUT.p_en, DUT.p_rdy );
        $display("  p.present_state=%d", DUT.p.present_state);
*/
        if (~err) begin
            $display("TEST 6 PASSED: PGRA state");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 6 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // Wait for PGRA to complete and return to IDLE
        $display("Waiting for PRGA to complete...");
        wait(DUT.p_rdy == 1'b1 && DUT.present_state == PGRA_WAIT);

        $display("rdy in p_waiting for ready to complete = %d", rdy);
        @(posedge clk); #1;
        @(posedge clk);
        @(posedge clk); //even if i wait multiple cycles it should be fine
        
        
        checkstate(IDLE);
        check_en_rdy_signals(1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1);

        $display("rdy in INIT_back in init = %d", rdy);

        if (~err) begin
            $display("TEST 7 PASSED: Returned to IDLE");
        end else begin
            $display("TEST 7 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        if (~totalerr) 
            $display("\nALL TESTS PASSED ");
        else 
            $display("\n TESTS FAILED ");
    end
    
endmodule: tb_rtl_arc4
