module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);
    
    //handshake protcol to prevent arc4 from restarting

    // s_mem internal signals:
    logic s_wren;
    logic [7:0] s_addr, s_data, q;

    // init internal signals:
    logic i_en, i_rdy, i_wren;
    logic [7:0] i_addr, i_wrdata;

    // ksa internal signals:
    logic k_en, k_rdy, k_wren;
    logic [7:0] k_addr, k_rddata, k_wrdata;

    // prga internal signals:
    logic p_en, p_rdy, p_swren;  
    logic [7:0] p_saddr, p_srddata, p_swrdata;

    // Instantiate submodules
    s_mem s(.address(s_addr), .clock(clk), .data(s_data), .wren(s_wren), .q(q));
    
    init i(.clk(clk), .rst_n(rst_n), .en(i_en), .rdy(i_rdy), 
           .addr(i_addr), .wrdata(i_wrdata), .wren(i_wren));
    
    ksa k(.clk(clk), .rst_n(rst_n), .en(k_en), .rdy(k_rdy), .key(key), 
          .addr(k_addr), .rddata(k_rddata), .wrdata(k_wrdata), .wren(k_wren));
    
    prga p(.clk(clk), .rst_n(rst_n), .en(p_en), .rdy(p_rdy), .key(key), 
           .s_addr(p_saddr), .s_rddata(p_srddata), .s_wrdata(p_swrdata), .s_wren(p_swren), 
           .ct_addr(ct_addr), .ct_rddata(ct_rddata), .pt_addr(pt_addr), 
           .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

    // State machine with wait states
    enum logic [2:0] {
        IDLE = 3'd0,
        INIT = 3'd1,
        INIT_WAIT = 3'd2,
        KSA = 3'd3,
        KSA_WAIT = 3'd4,
        PGRA = 3'd5,
        PGRA_WAIT = 3'd6
    } present_state, next_state; 

    // Next state logic
    always_comb begin
        case(present_state) 
            IDLE: next_state = en ? INIT : IDLE;
            
            INIT: next_state = ~i_rdy ? INIT_WAIT : INIT;  // Wait for init to start
            INIT_WAIT: next_state = i_rdy ? KSA : INIT_WAIT;  // Wait for init to finish
            
            KSA: next_state = ~k_rdy ? KSA_WAIT : KSA;  // Wait for ksa to start
            KSA_WAIT: next_state = k_rdy ? PGRA : KSA_WAIT;  // Wait for ksa to finish
            
            PGRA: next_state = ~p_rdy ? PGRA_WAIT : PGRA;  // Wait for prga to start
            PGRA_WAIT: next_state = p_rdy ? IDLE : PGRA_WAIT;  // Wait for prga to finish
            
            default: next_state = IDLE;
        endcase
    end

    // State register
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    // Output logic
    always_comb begin
        // Default: arc4 is ready only when in IDLE state
        rdy = (present_state == IDLE);
        
        case(present_state)
            INIT: begin
                i_en = 1'b1;
                k_en = 1'b0;
                p_en = 1'b0;

                s_addr = i_addr;
                s_data = i_wrdata;
                s_wren = i_wren;

                p_srddata = 8'd0;
                k_rddata = 8'd0;
            end 

            INIT_WAIT: begin
                i_en = 1'b0;
                k_en = 1'b0;
                p_en = 1'b0;

                s_addr = i_addr;
                s_data = i_wrdata;
                s_wren = i_wren;

                p_srddata = 8'd0;
                k_rddata = 8'd0;
            end 
            
            KSA: begin
                i_en = 1'b0;
                k_en = 1'b1;
                p_en = 1'b0;

                s_addr = k_addr;
                s_data = k_wrdata;
                s_wren = k_wren;
                k_rddata = q;

                p_srddata = 8'd0;
            end 

            KSA_WAIT: begin
                i_en = 1'b0;
                k_en = 1'b0;
                p_en = 1'b0;

                s_addr = k_addr;
                s_data = k_wrdata;
                s_wren = k_wren;
                k_rddata = q;

                p_srddata = 8'd0; 
            end 
            
            PGRA: begin
                i_en = 1'b0;
                k_en = 1'b0;
                p_en = 1'b1;

                s_addr = p_saddr;
                s_data = p_swrdata;
                s_wren = p_swren;
                p_srddata = q;

                k_rddata = 8'd0;
            end 

            PGRA_WAIT: begin
                i_en = 1'b0;
                k_en = 1'b0;
                p_en = 1'b0;

                s_addr = p_saddr;
                s_data = p_swrdata;
                s_wren = p_swren;
                p_srddata = q;

                k_rddata = 8'd0;
            end 
            
            default: begin  // IDLE
                i_en = 1'b0;
                k_en = 1'b0;
                p_en = 1'b0;

                s_addr = 8'd0;
                s_data = 8'd0;
                s_wren = 1'b0;

                p_srddata = 8'd0;
                k_rddata = 8'd0;
            end
        endcase
    end

endmodule: arc4