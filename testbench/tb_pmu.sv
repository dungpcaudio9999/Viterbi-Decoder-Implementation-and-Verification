`timescale 1ns / 1ps
`include "../design/pmu.v"

module pmu_tb();

    // Tin hieu ket noi
    reg clk;
    reg rst_n;
    reg valid_i;
    reg [7:0] pm_new_s0, pm_new_s1, pm_new_s2, pm_new_s3;
    wire [7:0] pm_cur_s0, pm_cur_s1, pm_cur_s2, pm_cur_s3;

    integer j, error_count;
    reg [7:0] exp_s0, exp_s1, exp_s2, exp_s3;

    // Khoi tao DUT
    pmu uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(valid_i),
        .pm_new_s0_i(pm_new_s0), .pm_new_s1_i(pm_new_s1), 
        .pm_new_s2_i(pm_new_s2), .pm_new_s3_i(pm_new_s3),
        .pm_current_s0_o(pm_cur_s0), .pm_current_s1_o(pm_cur_s1), 
        .pm_current_s2_o(pm_cur_s2), .pm_current_s3_o(pm_cur_s3)
    );

    // Tao xung clock 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Task hien thi bang so sanh chi tiet
    task display_report;
        input [8*20:1] scenario;
        begin
            $display("[%0t ns] %s", $time, scenario);
            $display("      --------------------------------------------------");
            $display("      State |   Got   | Expected | Status");
            $display("      ------|---------|----------|---------");
            $display("      S0    |   %d   |    %d   | %s", pm_cur_s0, exp_s0, (pm_cur_s0 === exp_s0) ? "OK" : "ERR");
            $display("      S1    |   %d   |    %d   | %s", pm_cur_s1, exp_s1, (pm_cur_s1 === exp_s1) ? "OK" : "ERR");
            $display("      S2    |   %d   |    %d   | %s", pm_cur_s2, exp_s2, (pm_cur_s2 === exp_s2) ? "OK" : "ERR");
            $display("      S3    |   %d   |    %d   | %s", pm_cur_s3, exp_s3, (pm_cur_s3 === exp_s3) ? "OK" : "ERR");
            $display("      --------------------------------------------------");
            if (pm_cur_s0 !== exp_s0 || pm_cur_s1 !== exp_s1 || 
                pm_cur_s2 !== exp_s2 || pm_cur_s3 !== exp_s3) error_count = error_count + 1;
        end
    endtask

    initial begin
        error_count = 0;
        valid_i = 0;
        {pm_new_s0, pm_new_s1, pm_new_s2, pm_new_s3} = 32'h0;

        $display("=========================================================");
        $display("START PMU TEST: TIMING - GOT - EXPECTED REPORT");
        $display("=========================================================");

        // 1. Reset Test
        rst_n = 0; #10;
        exp_s0 = 0; exp_s1 = 255; exp_s2 = 255; exp_s3 = 255;
        display_report("Reset Check");

        // 2. Update Enable Test (valid_i = 1)
        rst_n = 1; valid_i = 1;
        for(j=1; j<=5; j=j+1) begin
            pm_new_s0 = 10*j; pm_new_s1 = 20*j; pm_new_s2 = 30*j; pm_new_s3 = 40*j;
            exp_s0 = 10*j; exp_s1 = 20*j; exp_s2 = 30*j; exp_s3 = 40*j;
            @(posedge clk); #1; // Cho sau canh len 1ns
            display_report("Update Enable");
        end

        // 3. Keep Data Test (valid_i = 0)
        valid_i = 0;
        pm_new_s0 = 8'hFF; // Thay doi dau vao nhung valid=0
        repeat(5) @(posedge clk); #1;
        display_report("Keep Data (valid=0)");

        // 4. Zero Data Stream
        valid_i = 1;
        pm_new_s0=0; pm_new_s1=0; pm_new_s2=0; pm_new_s3=0;
        exp_s0=0; exp_s1=0; exp_s2=0; exp_s3=0;
        @(posedge clk); #1;
        display_report("Zero Stream");

        // 5. Random Stress Test
        for(j=1; j<=5; j=j+1) begin
            pm_new_s0=$random; pm_new_s1=$random; pm_new_s2=$random; pm_new_s3=$random;
            exp_s0=pm_new_s0; exp_s1=pm_new_s1; exp_s2=pm_new_s2; exp_s3=pm_new_s3;
            @(posedge clk); #1;
            display_report("Random Stress");
        end

        $display("\n=========================================================");
        $display("FINAL TOTAL ERRORS: %0d", error_count);
        if (error_count == 0) $display(">>> STATUS: ALL PASS <<<");
        $display("=========================================================");
        $finish;
    end
    initial begin
    $dumpfile("pmu.vcd"); // Tên file dữ liệu sóng
    $dumpvars(0, pmu_tb); 
end
endmodule
