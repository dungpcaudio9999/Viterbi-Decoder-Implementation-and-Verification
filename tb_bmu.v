`timescale 1ns / 1ps

module bmu_final_tb();

    reg [1:0] piso_data_i;
    wire [1:0] bm_out [0:7]; // M?ng gom các output ?? d? ki?m tra trong vòng l?p

    // K?t n?i các output l? vào m?ng
    wire [1:0] s00, s02, s10, s12, s21, s23, s31, s33;
    
    // Kh?i t?o module BMU
    bmu uut (
        .piso_data_i(piso_data_i),
        .bm_s0_s0_o(s00), .bm_s0_s2_o(s02),
        .bm_s1_s0_o(s10), .bm_s1_s2_o(s12),
        .bm_s2_s1_o(s21), .bm_s2_s3_o(s23),
        .bm_s3_s1_o(s31), .bm_s3_s3_o(s33)
    );

    // M?ng ch?a giá tr? k? v?ng (Expected) cho m?i k?ch b?n
    // Th? t?: {s00, s02, s10, s12, s21, s23, s31, s33}
    reg [1:0] exp_vals [0:7];
    integer i, j, error_count;

    // Task th?c hi?n ki?m tra và so sánh
    task check_results(input [1:0] in_val, input string scenario_name);
        begin
            // Tính toán giá tr? k? v?ng d?a trên logic Hamming Distance
            exp_vals[0] = hamming_logic(in_val, 2'b00); // s00
            exp_vals[1] = hamming_logic(in_val, 2'b11); // s02
            exp_vals[2] = hamming_logic(in_val, 2'b11); // s10
            exp_vals[3] = hamming_logic(in_val, 2'b00); // s12
            exp_vals[4] = hamming_logic(in_val, 2'b10); // s21
            exp_vals[5] = hamming_logic(in_val, 2'b01); // s23
            exp_vals[6] = hamming_logic(in_val, 2'b01); // s31
            exp_vals[7] = hamming_logic(in_val, 2'b10); // s33

            $display("--- %s | Input: %b ---", scenario_name, in_val);
            
            // So sánh t?ng Output
            compare(s00, exp_vals[0], "S0-S0");
            compare(s02, exp_vals[1], "S0-S2");
            compare(s10, exp_vals[2], "S1-S0");
            compare(s12, exp_vals[3], "S1-S2");
            compare(s21, exp_vals[4], "S2-S1");
            compare(s23, exp_vals[5], "S2-S3");
            compare(s31, exp_vals[6], "S3-S1");
            compare(s33, exp_vals[7], "S3-S3");
        end
    endtask

    // Hàm ph? tính Hamming ?? Testbench làm m?c so sánh
    function [1:0] hamming_logic(input [1:0] a, input [1:0] b);
        hamming_logic = (a[0]^b[0]) + (a[1]^b[1]);
    endfunction

    // Task in PASS/FAIL
    task compare(input [1:0] got, input [1:0] exp, input string name);
        if (got === exp)
            $display("  [PASS] %s | Got: %d | Exp: %d", name, got, exp);
        else begin
            $display("  [FAIL] %s | Got: %d | Exp: %d <--- ERROR", name, got, exp);
            error_count = error_count + 1;
        end
    endtask

    initial begin
        error_count = 0;
        $display("=====================================================");
        $display("BAT DAU KIEM THU: PASS/FAIL REPORT");
        $display("=====================================================");

        // K?ch b?n 1: Input 00 x 5 l?n
        for(j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b00; #10;
            check_results(piso_data_i, "Scenario 1 (00)");
        end

        // K?ch b?n 2: Input 11 x 5 l?n
        for(j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b11; #10;
            check_results(piso_data_i, "Scenario 2 (11)");
        end

        // K?ch b?n 3: Input 01 x 5 l?n
        for(j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b01; #10;
            check_results(piso_data_i, "Scenario 3 (01)");
        end

        // K?ch b?n 4: Input 10 x 5 l?n
        for(j=1; j<=5; j=j+1) begin
            piso_data_i = 2'b10; #10;
            check_results(piso_data_i, "Scenario 4 (10)");
        end

        // K?ch b?n 5: Ng?u nhiên x 5 l?n
        for(j=1; j<=5; j=j+1) begin
            piso_data_i = $random % 4; #10;
            check_results(piso_data_i, "Scenario 5 (Random)");
        end

        $display("=====================================================");
        if (error_count == 0)
            $display("TONG KET: TAT CA KIEM THU THANH CONG (PASS)");
        else
            $display("TONG KET: PHAT HIEN %0d LOI (FAIL)", error_count);
        $display("=====================================================");
        $finish;
    end

endmodule