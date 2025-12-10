module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

    // State encoding
    enum logic[1:0] {
        IDLE = 2'b0,
        WRITE = 2'b1
    } present_state, next_state;

    logic [7:0] i;

    // Combinational logic - next state calculation
    always_comb begin
        case (present_state)
            IDLE: begin
                next_state = en ? WRITE : IDLE;
            end
            WRITE: begin
                next_state = (i == 8'd255) ? IDLE : WRITE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end


    //always_ff logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            present_state <= IDLE;
            i <= 8'd0;
        end else begin
            present_state <= next_state;

            if (present_state == IDLE && next_state == WRITE) begin
                i <= 8'd0;  // Reset counter when entering WRITE
            end else if (present_state == WRITE && next_state == WRITE) begin
                i <= i + 8'd1;  // Increment ONLY when staying in WRITE
            end
        end
    end

    // Combinational logic - outputs based on present state
    always_comb begin
        case (present_state)
            IDLE: begin
                rdy = 1'b1;
                wren = 1'b0;
                addr = 8'd0;
                wrdata = 8'd0;
            end
            WRITE: begin
                rdy = 1'b0;
                wren = 1'b1;
                addr = i;
                wrdata = i;  // s[i] = i
            end
            default: begin
                rdy = 1'b1;
                wren = 1'b0;
                addr = 8'd0;
                wrdata = 8'd0;
            end
        endcase
    end

endmodule: init