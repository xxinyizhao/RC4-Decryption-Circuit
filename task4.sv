`define display_blank 7'b1111111
`define display_1 7'b0001000
`define display_0 7'b1110111
`define display_2 7'b0100100
`define display_3 7'b0110000
`define display_4 7'b0011001
`define display_5 7'b0010010
`define display_6 7'b0000010
`define display_7 7'b1111000
`define display_8 7'b0000000
`define display_9 7'b0010000
`define display_A 7'b0001000   // A
`define display_b 7'b1100000   // b
`define display_C 7'b0110001   // C
`define display_d 7'b1000010   // d
`define display_E 7'b0110000   // E
`define display_F 7'b0111000   // F

module task4(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    logic pt_wren, rdy, en, key_valid;
    logic [7:0] ct_addr, pt_addr, pt_wrdata, ct_q, pt_q;
    logic [23:0] key;

    ct_mem ct(.address(ct_addr), .clock(CLOCK_50), .data(8'd0), .wren(1'b0), .q(ct_q));
    crack c(.clk(CLOCK_50), .rst_n(KEY[3]), .en(en), .rdy(rdy), .key(key), .key_valid(key_valid), .ct_addr(ct_addr), .ct_rddata(ct_q));

    enum logic [1:0] {
        IDLE = 2'b00,
        WORKING = 2'b01,
        DONE = 2'b10,
        START = 2'b11
    } present_state, next_state;
 
    always_comb begin
        case(present_state)
            IDLE: next_state = START;
            START: next_state = ~rdy ? WORKING : START;
            WORKING: next_state = rdy ? DONE : WORKING;
            DONE: next_state = DONE;
            default: next_state = IDLE; 
        endcase

        if (key_valid) begin
            case(key[3:0])
                4'h0: HEX0 = `display_0;
                4'h1: HEX0 = `display_1;
                4'h2: HEX0 = `display_2;
                4'h3: HEX0 = `display_3;
                4'h4: HEX0 = `display_4;
                4'h5: HEX0 = `display_5;
                4'h6: HEX0 = `display_6;
                4'h7: HEX0 = `display_7;
                4'h8: HEX0 = `display_8;
                4'h9: HEX0 = `display_9;
                4'hA: HEX0 = `display_A;
                4'hB: HEX0 = `display_b;
                4'hC: HEX0 = `display_C;
                4'hD: HEX0 = `display_d;
                4'hE: HEX0 = `display_E;
                4'hF: HEX0 = `display_F;
                default: HEX0 = `display_blank;
            endcase  
            case(key[7:4])
                4'h0: HEX1 = `display_0;
                4'h1: HEX1 = `display_1;
                4'h2: HEX1 = `display_2;
                4'h3: HEX1 = `display_3;
                4'h4: HEX1 = `display_4;
                4'h5: HEX1 = `display_5;
                4'h6: HEX1 = `display_6;
                4'h7: HEX1 = `display_7;
                4'h8: HEX1 = `display_8;
                4'h9: HEX1 = `display_9;
                4'hA: HEX1 = `display_A;
                4'hB: HEX1 = `display_b;
                4'hC: HEX1 = `display_C;
                4'hD: HEX1 = `display_d;
                4'hE: HEX1 = `display_E;
                4'hF: HEX1 = `display_F;
                default: HEX1 = `display_blank;
            endcase
            case(key[11:8])
                4'h0: HEX2 = `display_0;
                4'h1: HEX2 = `display_1;
                4'h2: HEX2 = `display_2;
                4'h3: HEX2 = `display_3;
                4'h4: HEX2 = `display_4;
                4'h5: HEX2 = `display_5;
                4'h6: HEX2 = `display_6;
                4'h7: HEX2 = `display_7;
                4'h8: HEX2 = `display_8;
                4'h9: HEX2 = `display_9;
                4'hA: HEX2 = `display_A;
                4'hB: HEX2 = `display_b;
                4'hC: HEX2 = `display_C;
                4'hD: HEX2 = `display_d;
                4'hE: HEX2 = `display_E;
                4'hF: HEX2 = `display_F;
                default: HEX2 = `display_blank;
            endcase
            case(key[15:12])
                4'h0: HEX3 = `display_0;
                4'h1: HEX3 = `display_1;
                4'h2: HEX3 = `display_2;
                4'h3: HEX3 = `display_3;
                4'h4: HEX3 = `display_4;
                4'h5: HEX3 = `display_5;
                4'h6: HEX3 = `display_6;
                4'h7: HEX3 = `display_7;
                4'h8: HEX3 = `display_8;
                4'h9: HEX3 = `display_9;
                4'hA: HEX3 = `display_A;
                4'hB: HEX3 = `display_b;
                4'hC: HEX3 = `display_C;
                4'hD: HEX3 = `display_d;
                4'hE: HEX3 = `display_E;
                4'hF: HEX3 = `display_F;
                default: HEX3 = `display_blank;
            endcase
            case(key[19:16])
                4'h0: HEX4 = `display_0;
                4'h1: HEX4 = `display_1;
                4'h2: HEX4 = `display_2;
                4'h3: HEX4 = `display_3;
                4'h4: HEX4 = `display_4;
                4'h5: HEX4 = `display_5;
                4'h6: HEX4 = `display_6;
                4'h7: HEX4 = `display_7;
                4'h8: HEX4 = `display_8;
                4'h9: HEX4 = `display_9;
                4'hA: HEX4 = `display_A;
                4'hB: HEX4 = `display_b;
                4'hC: HEX4 = `display_C;
                4'hD: HEX4 = `display_d;
                4'hE: HEX4 = `display_E;
                4'hF: HEX4 = `display_F;
                default: HEX4 = `display_blank;
            endcase
            case(key[23:20])
                4'h0: HEX5 = `display_0;
                4'h1: HEX5 = `display_1;
                4'h2: HEX5 = `display_2;
                4'h3: HEX5 = `display_3;
                4'h4: HEX5 = `display_4;
                4'h5: HEX5 = `display_5;
                4'h6: HEX5 = `display_6;
                4'h7: HEX5 = `display_7;
                4'h8: HEX5 = `display_8;
                4'h9: HEX5 = `display_9;
                4'hA: HEX5 = `display_A;
                4'hB: HEX5 = `display_b;
                4'hC: HEX5 = `display_C;
                4'hD: HEX5 = `display_d;
                4'hE: HEX5 = `display_E;
                4'hF: HEX5 = `display_F;
                default: HEX5 = `display_blank;
            endcase
        end else begin
            HEX0 = `display_blank;
            HEX1 = `display_blank;
            HEX2 = `display_blank;
            HEX3 = `display_blank;
            HEX4 = `display_blank;
            HEX5 = `display_blank;
        end
    end

    always_ff @(posedge CLOCK_50) begin
        if (~KEY[3]) begin 
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    always_comb begin
        en = (present_state == START);  
    end

endmodule: task4