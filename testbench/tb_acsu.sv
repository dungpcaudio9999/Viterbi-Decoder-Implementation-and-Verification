`timescale 1ns / 1ps

module acsu_full_check_tb();

    // Tin hieu ket noi
    reg [1:0] bm_s0_s0, bm_s0_s2, bm_s1_s0, bm_s1_s2;
    reg [1:0] bm_s2_s1, bm_s2_s3, bm_s3_s1, bm_s3_s3;
    reg [7:0] pm_s0_i, pm_s1_i, pm_s2_i, pm_s3_i;

    wire [3:0] dec_bits_o;
    wire [7:0] pm_s0_o, pm_s1_o, pm_s2_o, pm_s3_o;

    integer j, error_count;
    reg [7:0] exp_pm [0:3];
    reg [3:0] exp_dec;

    // Khoi tao DUT
    acsu uut (
        .bm_s0_s0_i(bm_s0_s0), .bm_s0_s2_i(bm_s0_s2), .bm_s1_s0_i(bm_s1_s0), .bm_s1_s2_i(bm_s1_s2),
        .bm_s2_s1_i(bm_s2_s1), .bm_s2_s3_i(bm_s2_s3), .bm_s3_s1_i(bm_s3_s1), .bm_s3_s3_i(bm_s3_s3),
        .pm_s0_i(pm_s0_i), .pm_s1_i(pm_s1_i), .pm_s2_i(pm_s2_i), .pm_s3_i(pm_s3_i),
        .dec_bits_o(dec_bits_o),
        .pm_s0_o(pm_s0_o), .pm_s1_o(pm_s1_o), .pm_s2_o(pm_s2_o), .pm_s3_o(pm_s3_o)
    );

    // Golden Model
    task calculate_expected;
        reg [7:0] c0, c1;
        begin
            c0 = pm_s0_i + bm_s0_s0; c1 = pm_s1_i + bm_s1_s0;
            exp_pm[0] = (c0 <= c1) ? c0 : c1; exp_dec[0] = (c0 <= c1) ? 1'b0 : 1'b1;
            
            c0 = pm_s2_i + bm_s2_s1; c1 = pm_s3_i + bm_s3_s1;
            exp_pm[1] = (c0 <= c1) ? c0 : c1; exp_dec[1] = (c0 <= c1) ? 1'b0 : 1'b1;
            
            c0 = pm_s0_i + bm_s0_s2; c1 = pm_s1_i + bm_s1_s2;
            exp_pm[2] = (c0 <= c1) ? c0 : c1; exp_dec[2] = (c0 <= c1) ? 1'b0 : 1'b1;
            
            c0 = pm_s2_i + bm_s2_s3; c1 = pm_s3_i + bm_s3_s3;
            exp_pm[3] = (c0 <= c1) ? c0 : c1; exp_dec[3] = (c0 <= c1) ? 1'b0 : 1'b1;
        end
    endtask

    // Task hien thi chi tiet da PASS hay FAIL
    task verify_all;
        input [8*20:1] scenario;
        begin
            calculate_expected();
            #1; // Cho mach to hop
            
            if (dec_bits_o === exp_dec && 
                pm_s0_o === exp_pm[0] && pm_s1_o === exp_pm[1] && 
                pm_s2_o === exp_pm[2] && pm_s3_o === exp_pm[3]) 
                $display("[%0t ns] [PASS] %s", $time, scenario);
            else begin
                $display("[%0t ns] [FAIL] %s", $time, scenario);
                error_count = error_count + 1;
            end

            // Luon luon hien thi bang so sanh de chup anh bao cao
            $display("      --------------------------------------------------");
            $display("      Output |   Got   | Expected | Status");
            $display("      -------|---------|----------|---------");
            $display("      DEC    |  %b   |   %b   | %s", dec_bits_o, exp_dec, (dec_bits_o === exp_dec) ? "OK" : "ERR");
            $display("      PM0    |  %d   |   %d   | %s", pm_s0_o, exp_pm[0], (pm_s0_o === exp_pm[0]) ? "OK" : "ERR");
            $display("      PM1    |  %d   |   %d   | %s", pm_s1_o, exp_pm[1], (pm_s1_o === exp_pm[1]) ? "OK" : "ERR");
            $display("      PM2    |  %d   |   %d   | %s", pm_s2_o, exp_pm[2], (pm_s2_o === exp_pm[2]) ? "OK" : "ERR");
            $display("      PM3    |  %d   |   %d   | %s", pm_s3_o, exp_pm[3], (pm_s3_o === exp_pm[3]) ? "OK" : "ERR");
            $display("      --------------------------------------------------");
        end
    endtask

    initial begin
        error_count = 0;
        {bm_s0_s0, bm_s0_s2, bm_s1_s0, bm_s1_s2, bm_s2_s1, bm_s2_s3, bm_s3_s1, bm_s3_s3} = 16'h0;
        {pm_s0_i, pm_s1_i, pm_s2_i, pm_s3_i} = 32'h0;

        $display("=========================================================");
        $display("START ACSU FULL REPORT: TIMING - GOT - EXPECTED");
        $display("=========================================================");

        // Kich ban 1: Min Path (5 lan)
        for(j=1; j<=5; j=j+1) begin
            pm_s0_i=10*j; pm_s1_i=5*j; pm_s2_i=20*j; pm_s3_i=15*j;
            bm_s0_s0=1; bm_s1_s0=1; bm_s2_s1=1; bm_s3_s1=1;
            #10 verify_all("Min Path Case");
        end

        // Kich ban 2: Toggling Winner (5 lan) - Doi tu nhanh 0 sang nhanh 1 thang
        for(j=1; j<=5; j=j+1) begin
            pm_s0_i=(j<3)? 5 : 50; pm_s1_i=(j<3)? 50 : 5;
            bm_s0_s0=2; bm_s1_s0=2;
            #10 verify_all("Switching Winner");
        end

        // Kich ban 3: High Metric (Gan tran 8-bit)
        for(j=1; j<=5; j=j+1) begin
            pm_s0_i=250; pm_s1_i=250; bm_s0_s0=j; bm_s1_s0=0;
            #10 verify_all("Boundary Case");
        end

        // Kich ban 4: Zero Inputs
        for(j=1; j<=5; j=j+1) begin
            {pm_s0_i, pm_s1_i, pm_s2_i, pm_s3_i} = 32'h0;
            {bm_s0_s0, bm_s1_s0, bm_s2_s1, bm_s3_s1} = 8'h0;
            #10 verify_all("Zero Case");
        end

        // Kich ban 5: Hoan toan ngau nhien
        for(j=1; j<=5; j=j+1) begin
            pm_s0_i=$random; pm_s1_i=$random; pm_s2_i=$random; pm_s3_i=$random;
            bm_s0_s0=$random; bm_s1_s0=$random; bm_s2_s1=$random; bm_s3_s1=$random;
            bm_s0_s2=$random; bm_s1_s2=$random; bm_s2_s3=$random; bm_s3_s3=$random;
            #10 verify_all("Random Stress");
        end
        
        $display("\n=========================================================");
        $display("FINAL TOTAL ERRORS: %0d", error_count);
        $display("=========================================================");
        $finish;
    end

    initial begin
        $dumpfile("acsu.vcd"); // Ten file du lieu song
        $dumpvars(0, acsu_full_check_tb); 
    end
endmodule