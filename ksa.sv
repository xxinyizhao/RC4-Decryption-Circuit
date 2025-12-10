module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

    //declaring state constants
    enum logic [4:0] {
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
        START = 5'd12
    } present_state, next_state;

    //counters and temporary values
    logic [7:0] count_i, count_j;
    logic [7:0] temp_i, temp_j;
   
    //next state logic (combinational)
    always_comb begin 
        case(present_state)
            IDLE: next_state = en ? START : IDLE;
            START: next_state = RDI1;
            RDI1: next_state = RDI2;
            RDI2: next_state = CALCJ;
            CALCJ: next_state = RDJ1;
            RDJ1: next_state = RDJ2;
            RDJ2: next_state = WRTI1; 
            WRTI1: next_state = WRTI2;
            WRTI2: next_state = WRTJ1;
            WRTJ1: next_state = WRTJ2;
            WRTJ2: next_state = INCREI;
            INCREI: next_state = LOOP;
            LOOP: next_state = (count_i != 8'd0) ? RDI1 : IDLE;
            default: next_state = IDLE;
        endcase
    end

    //sequential logic - only update state and internal registers
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            present_state <= IDLE;
            count_i <= 8'd0;
            count_j <= 8'd0;
            temp_i <= 8'd0;
            temp_j <= 8'd0;
        end else begin
            present_state <= next_state;
            
            case(present_state) //changed to next state need to test
                //capture s[i] from memory
                RDI2: temp_i <= rddata;
                
                //calculate j = (j + s[i] + key[i mod keylength]) mod 256
                CALCJ: begin
                    case(count_i % 8'd3)
                        2'd0: count_j <= count_j + temp_i + key[23:16];
                        2'd1: count_j <= count_j + temp_i + key[15:8];
                        2'd2: count_j <= count_j + temp_i + key[7:0];
                        default: count_j <= count_j + temp_i + key[23:16];
                    endcase
                end
                
                //capture s[j] from memory
                RDJ2: temp_j <= rddata;
                
                //increment i counter
                INCREI: count_i <= count_i + 8'd1;
                
                //reset counters when returning to IDLE
                LOOP: begin
                    if (count_i == 8'd0) begin
                        count_i <= 8'd0;
                        count_j <= 8'd0;
                    end
                end
                
                default: begin
                    // No updates needed for other states
                end
            endcase
        end
    end

    //output logic (combinational) - based on present_state
    always_comb begin
        case(present_state)
            IDLE, START: begin
                addr = 8'd0;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b1;
            end
            
            RDI1: begin
                addr = count_i;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            RDI2: begin
                addr = count_i;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            CALCJ: begin
                addr = 8'd0;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            RDJ1: begin
                addr = count_j;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            RDJ2: begin
                addr = count_j;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            WRTI1: begin
                addr = count_i;
                wrdata = temp_j;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            WRTI2: begin
                addr = count_i;
                wrdata = temp_j;
                wren = 1'b1;
                rdy = 1'b0;
            end
            
            WRTJ1: begin
                addr = count_j;
                wrdata = temp_i;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            WRTJ2: begin
                addr = count_j;
                wrdata = temp_i;
                wren = 1'b1;
                rdy = 1'b0;
            end
            
            INCREI: begin
                addr = 8'd0;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            LOOP: begin
                addr = 8'd0;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b0;
            end
            
            default: begin
                addr = 8'd0;
                wrdata = 8'd0;
                wren = 1'b0;
                rdy = 1'b1;
            end
        endcase
    end

endmodule: ksa