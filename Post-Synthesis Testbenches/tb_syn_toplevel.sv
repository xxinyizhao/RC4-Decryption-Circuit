/* To test tasks 3, 4, and 5 with sample .mif ct_mem files, 
these two lines in ct_mem.v were included: */
// altsyncram_component.init_file = "demo.mif",
// altsyncram_component.init_file_layout = "PORT_A";
/* This testbench displays the pt_mem contents to be verified qualitatively to ensure 
that there is a valid ASCII message. */
`timescale 1ps/1ps
module tb_syn_toplevel();

    // DUT input and output signals:
    logic clk;
    logic [3:0] KEY;
    logic [9:0] SW, LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // instantiate DUT
    toplevel DUT(.CLOCK_50(clk), .KEY(KEY), .SW(SW), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
             .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .LEDR(LEDR));

    // Debugging signals:
    logic err, totalerr;
    logic [2:0] t;

    // Generate clock signal:
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // Start tests: 
    initial begin
        // Initialize debugging signals:
        err = 1'b0;
        totalerr = 1'b0;
        t = 3'b0;

        // Initialize inputs:
        SW[9:0] = 10'b0000011000; // set key
        KEY[3] = 1'b1; #5; // active-low reset

        KEY[3] = 1'b0; #5; // assert reset
        repeat(3) @(posedge clk);

        KEY[3] = 1'b1; #5; //de-assert reset

        // wait like 1,000,000 ticks for the design to run
        repeat(1000000) @(posedge clk);

        // Print output
        $display("Decrypted code from test.mif: %p", DUT.\s|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem);
    end


endmodule: tb_syn_toplevel
