`timescale 1ns / 1ps
`include "../design/bmu.sv"
module bmu_tb();

    // Connection signals
    reg [1:0] piso_data_i;
    wire [1:0] bm_s0_s0_o, bm_s0_s2_o, bm_s1_s0_o, bm_s1_s2_o;
    wire [1:0] bm_s2_s1_o, bm_s2_s3_o, bm_s3_s1_o, bm_s3_s3_o;

    integer i, j, error_count;
    reg [1:0] exp_bm [0:7];

    // Initialize DUT (Device Under Test)
    bmu uut (
        .piso_data_i(piso_data_i),
        .bm_s0_s0_o(bm_s0_s0_o), .bm_s0_s2_o(bm_s0_s2_o),
        .bm_s1_s0_o(bm_s1_s0_o), .bm_s1_s2_o(bm_s1_s2_o),
        .bm_s2_s1_o(bm_s2_s1_o), .bm_s2_s3_o(bm_s2_s3_o),
        .bm_s3_s1_o(bm_s3_s1_o), .bm_s3_s3_o(bm_s3_s3_o)
    );

    // Reference function to calculate Hamming distance in Testbench for comparison
    function [1:0] calc_hamming;
        input [1:0] a;
        input [1:0] b;
        begin
            calc_hamming = (a[0]^b[0]) + (a[1]^b[1]);
        end
    endfunction

    // Task to display detailed report for all 8 outputs
    task display_report;
        input [8*25:1] scenario;
        begin
            // Calculate expected values (Golden Model)
            exp_bm[0] = calc_hamming(piso_data_i, 2'b00); // s0s0
            exp_bm[1] = calc_hamming(piso_data_i, 2'b11); // s0s2
            exp_bm[2] = calc_hamming(piso_data_i, 2'b11); // s10
            exp_bm[3] = calc_hamming(piso_data_i, 2'b00); // s12
            exp_bm[4] = calc_hamming(piso_data_i, 2'b10); // s21
            exp_bm[5] = calc_hamming(piso_data_i, 2'b01); // s23
            exp_bm[6] = calc_hamming(piso_data_i, 2'b01); // s31
            exp_bm[7] = calc_hamming(piso_data_i, 2'b10); // s33

            #1; // Wait for combinational logic update
            $display("[%0t ns] SCENARIO: %s (Input: %b)", $time, scenario, piso_data_i);
            $display("      --------------------------------------------------");
            $display("      Branch  |  Got  | Expected | Status");
            $display("      --------|-------|----------|---------");
            check_and_print("S0-S0", bm_s0_s0_o, exp_bm[0]);
            check_and_print("S0-S2", bm_s0_s2_o, exp_bm[1]);
            check_and_print("S2-S3", bm_s2_s3_o, exp_bm[5]);
            check_and_print("S3-S3", bm_s3_s3_o, exp_bm[7]);
            $display("      --------------------------------------------------");
        end
    endtask

    // Sub-task to check each branch
    task check_and_print;
        input [8*5:1] name;
        input [1:0] got;
        input [1:0] exp;
        begin
            if (got === exp)
                $display("      %s   |   %d   |    %d     |   OK", name, got, exp);
            else begin
                $display("      %s   |   %d   |    %d     |   ERR <--- !!", name, got, exp);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        error_count = 0;
        piso_data_i = 2'b00;

        $display("=========================================================");
        $display("START BMU TEST: HAMMING DISTANCE VERIFICATION");
        $display("=========================================================");

        // Scenario 1: Input 00 (Repeat 5 times)
        for (j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b00; #10;
            display_report("Ideal Case (00)");
        end

        // Scenario 2: Input 11 (Repeat 5 times)
        for (j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b11; #10;
            display_report("Inverse Case (11)");
        end

        // Scenario 3: Input 01 (Repeat 5 times)
        for (j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b01; #10;
            display_report("Error 1-bit (01)");
        end

        // Scenario 4: Input 10 (Repeat 5 times)
        for (j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b10; #10;
            display_report("Error 1-bit (10)");
        end

        // Scenario 5: Random (Repeat 5 times)
        for (j=1; j<=5; j=j+1) begin
            piso_data_i = $random % 4; #10;
            display_report("Random Stress");
        end

        $display("\n=========================================================");
        if (error_count == 0)
            $display("FINAL TOTAL ERRORS: 0 -> STATUS: ALL PASS");
        else
            $display("FINAL TOTAL ERRORS: %0d -> STATUS: FAIL", error_count);
        $display("=========================================================");
        $finish;
    end

initial begin
    $dumpfile("bmu.vcd"); // Waveform data file name
    $dumpvars(0, bmu_tb); 
end

endmodule