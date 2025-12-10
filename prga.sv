module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    enum logic [4:0] {
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
        LOOP = 5'd17
    } present_state, next_state;
    
    logic [7:0] temp_i, temp_j, temp_pt, temp_pad, temp_ct, i, j, k, mlen;

    // Next state logic (combinational)
    always_comb begin
        case(present_state)
            IDLE: next_state = en ? RDLEN : IDLE; //ypu only get an enable if rdy was sent out
            RDLEN: next_state = WRLEN;
            WRLEN: next_state = CALCI;
            CALCI: next_state = RDI1;
            RDI1: next_state = RDI2;
            RDI2: next_state = CALCJ;
            CALCJ: next_state = RDJ1;
            RDJ1: next_state = RDJ2;
            RDJ2: next_state = WRI;
            WRI: next_state = WRJ;
            WRJ: next_state = RDSP1;
            RDSP1: next_state = RDSP2;
            RDSP2: next_state = RDC1;
            RDC1: next_state = RDC2;
            RDC2: next_state = XOR;
            XOR: next_state = INCR;
            INCR: next_state = LOOP;
            LOOP: next_state = (k <= mlen) ? CALCI : IDLE;
                        
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic - only update state and internal registers
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            present_state <= IDLE;
            i <= 8'd0;
            j <= 8'd0;
            k <= 8'd1;
            mlen <= 8'd0;
            temp_i <= 8'd0;
            temp_j <= 8'd0;
            temp_ct <= 8'd0;
            temp_pt <= 8'd0;
        end else begin
            present_state <= next_state;
            
            case(present_state)
                IDLE: begin
                    i <= 8'd0;
                    j <= 8'd0;
                    k <= 8'd1;
                    mlen <= 8'd0;
                    temp_i <= 8'd0;
                    temp_j <= 8'd0;
                    temp_ct <= 8'd0; 
                    temp_pt <= 8'd0;
                end RDLEN: mlen <= ct_rddata; //we initially have addr = 0 at the start and we can read addrress 0
                CALCI: i <= (i + 8'd1);
                RDI2: temp_i <= s_rddata;
                CALCJ: j <= (j + temp_i);
                RDJ2: temp_j <= s_rddata;
                RDSP2: temp_pad <= s_rddata;
                RDC2: temp_ct <= ct_rddata;
                INCR: k <= (k + 8'd1);
                default: ; // nothing changes
            endcase
        end
    end

// Output logic (combinational) - simplified version
always_comb begin
    // Defaults
    rdy = (present_state == IDLE);
 
    // State-specific overrides
    case(present_state)
        RDLEN: begin
            s_addr = 8'd0;
            s_wrdata = 8'd0;
            s_wren = 1'b0;
            ct_addr = 8'd0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end WRLEN: begin
            pt_wren = 1'b1;
            pt_wrdata = mlen;
            pt_addr = 8'd0;

            s_wren = 1'b0;
            s_addr = 8'd0;
            s_wrdata = 8'd0;
            ct_addr = 8'd0;
        end RDI1, RDI2: begin
            s_addr = i;

            s_wrdata = 8'd0;
            s_wren = 1'b0;
            ct_addr = 8'd0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end RDJ1, RDJ2: begin
            s_addr = j;

            s_wrdata = 8'd0;
            s_wren = 1'b0;
            ct_addr = 8'd0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end WRI: begin
            s_addr = i;
            s_wrdata = temp_j;
            s_wren = 1'b1;

            ct_addr = 8'd0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end WRJ: begin
            s_addr = j;
            s_wrdata = temp_i;
            s_wren = 1'b1;

            ct_addr = 8'd0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end RDSP1, RDSP2: begin
            s_addr = (temp_i + temp_j);
            
            s_wrdata = 8'd0;
            s_wren = 1'b0;
            ct_addr = 8'd0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end RDC1, RDC2: begin      
            ct_addr = k;

            s_addr = 8'd0;
            s_wrdata = 8'd0;
            s_wren = 1'b0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end XOR: begin
            pt_addr = k;
            pt_wrdata = (temp_pad ^ temp_ct);
            pt_wren = 1'b1;

            s_addr = 8'd0;
            s_wrdata = 8'd0;
            s_wren = 1'b0;
            ct_addr = 8'd0;
        end 
        default: begin // includes IDLE, CALCI, CALCJ, INCR, LOOP
            s_addr = 8'd0;
            s_wrdata = 8'd0;
            s_wren = 1'b0;
            ct_addr = 8'd0;
            pt_addr = 8'd0;
            pt_wrdata = 8'd0;
            pt_wren = 1'b0;
        end
   
    endcase
end 

 
endmodule: prga