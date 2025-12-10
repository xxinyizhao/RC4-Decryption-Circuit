module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);

    logic en_1, rdy_1, en_2, rdy_2, key_valid_1, key_valid_2, pt_wren;
    logic [7:0] dc_addr1, dc_rddata1, dc_addr2, dc_rddata2;
    logic [7:0] addr, pt_wrdata, q;
    logic [7:0] ct_rddata1, ct_rddata2, ct_addr1, ct_addr2, mlen;
    logic [8:0] incr_addr;
    logic [23:0] key_1, key_2;
    
    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(.address(addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(q));

    // for this task only, you may ADD ports to crack
    crack c1(.clk(clk), .rst_n(rst_n), .en(en_1), .rdy(rdy_1),
             .key(key_1), .key_valid(key_valid_1),
             .ct_addr(ct_addr1), .ct_rddata(ct_rddata1),
             .dc_rddata(dc_rddata1), // additional output port
             .start_testkey(25'd0), .incr_testkey(25'd2), .dc_addr(dc_addr1));

    crack c2(.clk(clk), .rst_n(rst_n), .en(en_2), .rdy(rdy_2),
             .key(key_2), .key_valid(key_valid_2),
             .ct_addr(ct_addr2), .ct_rddata(ct_rddata2),
             .dc_rddata(dc_rddata2), // additional output port
             .start_testkey(25'd1), .incr_testkey(25'd2), .dc_addr(dc_addr2));
    
    enum logic [3:0] {
        IDLE = 4'd0,
        STARTC = 4'd1,
        CRACK = 4'd2,
        RDLEN1 = 4'd3,
        RDLEN2 = 4'd4,
        RDP = 4'd5,
        WRP = 4'd6,
        INCR = 4'd7,
        LOOP = 4'd8
    } present_state, next_state;

    assign ct_addr = ct_addr1 | ct_addr2;

    assign ct_rddata1 = ct_rddata;
    assign ct_rddata2 = ct_rddata;


    always_comb begin
        case(present_state)
        
        IDLE: next_state = en ? STARTC : IDLE;
        STARTC: next_state = ~(rdy_1 && rdy_2) ? CRACK : STARTC;
        CRACK: next_state = (rdy_1 || rdy_2) ? RDLEN1 : CRACK;
        RDLEN1: next_state = RDLEN2;
        RDLEN2: next_state = RDP;
        RDP: next_state = WRP;
        WRP: next_state = INCR;
        INCR: next_state = LOOP;
        LOOP: next_state = (incr_addr <= mlen) ? RDP : IDLE;

        default: next_state = IDLE;
        
        endcase
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            present_state <= IDLE;
            incr_addr <= 9'd0;
            mlen <= 8'd0;
        end else begin
            present_state <= next_state;
            case(present_state)
                IDLE: begin 
                    incr_addr <= 9'd0;
                    mlen <= 8'd0;
                end INCR: incr_addr <= (incr_addr + 9'd1);
                RDLEN2: begin
                if(key_valid_1) begin
                    mlen <= dc_rddata1;
                end else if (key_valid_2) begin
                    mlen <= dc_rddata2;
                end else begin
                    mlen <= 8'd0;
                end

                end
                default: ; // no changes
            endcase
        end
    end

    always_comb begin
        rdy = (present_state == IDLE);

        key_valid = (present_state == IDLE) && (key_valid_1 || key_valid_2);

        if (present_state == IDLE) begin
            if(key_valid_1) begin
                key = key_1;
            end else if (key_valid_2) begin
                key = key_2;
            end else begin
                key = 24'd0;
            end
        end else begin
            key = 24'd0;
        end
        
        case(present_state)
            STARTC: begin
                en_1 = 1'b1;
                en_2 = 1'b1;
                
                addr = 8'd0;
                dc_addr1 = 8'd0;
                dc_addr2 = 8'd0;

                pt_wren = 1'b0;
                pt_wrdata = 8'd0;


            end RDP: begin
                en_1 = 1'b0;
                en_2 = 1'b0;

                pt_wren = 1'b0;
                pt_wrdata = 8'd0;
                addr = incr_addr;
                
                if (key_valid_1) begin
                    dc_addr1 = incr_addr;
                    dc_addr2 = 8'd0;
                end else if (key_valid_2) begin
                    dc_addr1 = 8'd0;
                    dc_addr2 = incr_addr;
                end else begin
                    dc_addr1 = 8'd0;
                    dc_addr2 = 8'd0;
                end
            end WRP: begin
                en_1 = 1'b0;
                en_2 = 1'b0;

                dc_addr1 = 8'd0;
                dc_addr2 = 8'd0;
                addr = incr_addr;
                
                if (key_valid_1) begin
                    pt_wren = 1'b1;
                    pt_wrdata = dc_rddata1;
                end else if (key_valid_2) begin
                    pt_wren = 1'b1;
                    pt_wrdata = dc_rddata2;
                end else begin
                    pt_wren = 1'b0;
                    pt_wrdata = 8'b0;
                end
            end 

            default: begin // includes IDLE, INCR, LOOP, CRACK, RDLEN1, RDLEN2
                en_1 = 1'b0;
                en_2 = 1'b0;
                
                addr = 8'd0;
                dc_addr1 = 8'd0;
                dc_addr2 = 8'd0;

                pt_wren = 1'b0;
                pt_wrdata = 8'd0;
            end
        endcase
    end

endmodule: doublecrack