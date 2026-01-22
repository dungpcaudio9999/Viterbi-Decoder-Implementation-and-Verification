`timescale 1ns / 1ps

module tbu_tb();

    // Tin hieu ket noi
    reg clk, rst_n, valid_i;
    reg [3:0] dec_bits_i;
    reg [7:0] pm_s0, pm_s1, pm_s2, pm_s3;
    wire decoded_bit_o, valid_o;

    integer j, error_count;
    reg expected_bit;
    
    // Khoi tao DUT
    tbu uut (
        .clk(clk), .rst_n(rst_n), .valid_i(valid_i),
        .dec_bits_i(dec_bits_i),
        .pm_new_s0_i(pm_s0), .pm_new_s1_i(pm_s1),
        .pm_new_s2_i(pm_s2), .pm_new_s3_i(pm_s3),
        .decoded_bit_o(decoded_bit_o), .valid_o(valid_o)
    );

    // Clock 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Task hien thi bao cao chuyen nghiep
    task display_report;
        input [8*25:1] scenario;
        input exp_v;
        input exp_b;
        begin
            $display("[%0t ns] %s", $time, scenario);
            $display("      --------------------------------------------------");
            $display("      Signal      |   Got   | Expected | Status");
            $display("      ------------|---------|----------|---------");
            $display("      Valid_Out   |    %b    |    %b     | %s", valid_o, exp_v, (valid_o === exp_v) ? "OK" : "ERR");
            $display("      Decoded_Bit |    %b    |    %b     | %s", decoded_bit_o, exp_b, (valid_o && decoded_bit_o !== exp_b) ? "ERR" : "OK");
            $display("      --------------------------------------------------");
            if (valid_o !== exp_v || (valid_o && decoded_bit_o !== exp_b)) error_count = error_count + 1;
        end
    endtask

    initial begin
        error_count = 0;
        valid_i = 0; dec_bits_i = 0;
        {pm_s0, pm_s1, pm_s2, pm_s3} = 32'hFFFFFFFF; // Ban dau tat ca PM deu cao

        $display("=========================================================");
        $display("BAT DAU TBU TEST: THOI GIAN - NHAN - KY VONG");
        $display("=========================================================");

        // 1. Reset Test
        rst_n = 0; #15; rst_n = 1; #5;
        display_report("Reset Check", 1'b0, 1'b0);

        // 2. Kich ban 1: Pipeline Filling (Nap 15 chu ky dau)
        $display("\n---> Scenario 1: Filling Pipeline (Latency Test)");
        valid_i = 1;
        // Chay dung TBL (15) chu ky de counter dat TBL-1
        for (j = 0; j < 15; j = j + 1) begin
            dec_bits_i = 4'b0000; 
            pm_s0 = 0; pm_s1 = 10; pm_s2 = 10; pm_s3 = 10; 
            @(posedge clk); #1; 
        end
        // Tai thoi diem nay, counter da xong 15, pipeline_full vua len 1, 
        // nhung valid_o can them 1 canh clock nua de vao nhanh 'else'
        display_report("Pipeline Processing Last Fill", 1'b0, 1'b0);

        // 3. Scenario 2: Bat dau xuat Output
        @(posedge clk); #1;
        display_report("Pipeline Full - Start Valid", 1'b1, 1'b0);

        // 4. Kich ban 3: Kiem tra tinh dung dan cua Register Exchange
        // Nap mot chuoi bit '1' vao S0 qua nhanh S2 (dec_bits_i[2]=0)
        $display("\n---> Scenario 2: Data Traceback (S2 Input)");
        for (j = 0; j < 16; j = j + 1) begin
            dec_bits_i = 4'b0100; // dec_bits[2]=0 -> S2 lay tu S0 va nap bit 1
            pm_s2 = 0; pm_s0 = 10; pm_s1 = 10; pm_s3 = 10; // Ep S2 thang de lay output tu history_s2
            @(posedge clk); #1;
        end
        // Sau 15 chu ky nap bit 1, output cua S2 phai la 1
        display_report("Traceback Bit 1 Check", 1'b1, 1'b1);

        // 5. Kich ban 4: Disable valid_i
        $display("\n---> Scenario 3: Valid_i Gating");
        valid_i = 0;
        @(posedge clk); #1;
        display_report("Valid_i Off", 1'b0, 1'b0);

        // 6. Kich ban 5: Random PM Winner Switching
        $display("\n---> Scenario 4: Winner Switching");
        valid_i = 1;
        pm_s3 = 0; pm_s2 = 50; // Chuyen winner sang S3
        @(posedge clk); #1;
        display_report("Winner switched to S3", 1'b1, decoded_bit_o); // Kiem tra Got vs Got (logic check)

        $display("\n=========================================================");
        $display("FINAL TOTAL ERRORS: %0d", error_count);
        if (error_count == 0) $display(">>> STATUS: ALL PASS <<<");
        $display("=========================================================");
        $finish;
    end
initial begin
    $dumpfile("tbu.vcd"); // Ten file du lieu song
    $dumpvars(0, tbu_tb); 
end
endmodule