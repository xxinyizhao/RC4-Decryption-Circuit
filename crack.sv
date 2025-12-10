module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);
    // internal signals:
    
    logic [24:0] testkey; // make 25 bits to make loop logic easier
    logic [7:0] mlen, checkaddr, checkval, pt_addr, pt_rddata, pt_wrdata, q, addr;
    logic a_en, a_rdy, pt_wren;

    pt_mem pt(.address(addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(q));
    arc4 a4(.clk(clk), .rst_n(rst_n), .en(a_en), .rdy(a_rdy), .key(testkey[23:0]), .ct_addr(ct_addr), .ct_rddata(ct_rddata),
            .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));
    
    enum logic [3:0] {
        IDLE = 4'd0,
        STARTA4 = 4'd1,
        ARC4 = 4'd2,
        RDLEN1 = 4'd3,
        RDLEN2 = 4'd4,
        RDP1 = 4'd5, 
        RDP2 = 4'd6,
        INCRA = 4'd7,
        CHECKA = 4'd8,
        INCRK = 4'd9,
        CHECKK = 4'd10
    } present_state, next_state;

    always_comb begin
        case(present_state)  
            IDLE: next_state = en ? STARTA4 : IDLE;
            STARTA4: next_state = ~a_rdy ? ARC4 : STARTA4; // changed
            ARC4: next_state = a_rdy ? RDLEN1 : ARC4;
            RDLEN1: next_state = RDLEN2;
            RDLEN2: next_state = RDP1;
            RDP1: next_state = RDP2;
            RDP2: next_state = INCRA;
            INCRA : next_state = CHECKA;
            CHECKA: begin 
                /*if((checkaddr <= mlen) && (key_valid == 1))next_state = RDP1;
                else if(key_valid == 0) next_state = INCRK;
                else next_state = IDLE;*/
                if((checkaddr <= mlen) && (key_valid == 1)) next_state = RDP1;  // Read next character
                else if((checkaddr > mlen) && (key_valid == 1)) next_state = IDLE;  // Success! Found valid key
                else if(key_valid == 0) next_state = INCRK;  // Invalid character, try next key
                else next_state = IDLE;
            end
            /*(CHECKA: next_state = ((checkaddr <= mlen) && key_valid) ? RDP1 :
                     (!key_valid) ? INCRK : IDLE;*/
            INCRK: next_state = CHECKK; 
            //CHECKK: next_state = (!testkey[24]) ? STARTA4 : IDLE; // max value in 24bit is 24'hFFFFFF when we overflow 25'h1000000
            CHECKK: next_state = (testkey < 25'd16777216) ? STARTA4 : IDLE; //this is actual last value 2^25
            default: next_state = IDLE;
        endcase 
    end

    always_ff @(posedge clk) begin
        if(~rst_n) begin
            present_state <= IDLE;
            checkaddr <= 8'd0;
            checkval <= 8'd0;
            testkey <= 25'd0;
            mlen <= 8'd0;
            //key_valid <= 1'b0;
        end else begin
            present_state <= next_state;
            case(present_state)
                IDLE, STARTA4: begin
                    checkaddr <= 8'd0;
                    checkval <= 8'd0;
                end RDLEN2: begin
                    key_valid <= 1'b1;
                    checkaddr <= 8'd1;
                    mlen <= q;
                end RDP2: checkval <= q;
                INCRA: begin
                    checkaddr <= checkaddr + 8'd1;
                    key_valid <= key_valid && ((checkval >= 8'h20) && (checkval <= 8'h7E));
                    //key_valid <= ((checkval >= 8'h20) && (checkval <= 8'h7E));
                end INCRK: testkey <= testkey + 25'd1;
                default: ; // nothing changes
            endcase
        end
    end

    always_comb begin
        rdy = (present_state == IDLE);

        if (key_valid) key = testkey[23:0]; 
        else key = 24'b0; 

        case(present_state)
            STARTA4: begin
                addr = pt_addr;
                a_en = 1'b1;
                pt_rddata = q;
            end ARC4: begin
                addr = pt_addr;
                a_en = 1'b0;
                pt_rddata = q; 
            end RDLEN1: begin
                addr = 8'b0;
                a_en = 1'b0;
                pt_rddata = 8'd0;
            end RDLEN2: begin
                addr = 8'd0;
                a_en = 1'b0;
                pt_rddata = 8'd0;
            end RDP1, RDP2: begin
                addr = checkaddr;
                a_en = 1'b0;
                pt_rddata = 8'd0;
            end default: begin // includes IDLE, INCRA, INCRK, CHECKA, CHECKK
                addr = 8'd0;
                a_en = 1'b0;
                pt_rddata = 8'd0;
            end          
        endcase
    end

endmodule: crack
