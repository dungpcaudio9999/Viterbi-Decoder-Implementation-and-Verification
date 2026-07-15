`timescale 1ns / 1ps
`include "../design/sipo.v"
module sipo_tb();

    // Connection signals
    reg clk, rst_n, data_serial_i, valid_serial_i;
    wire [7:0] data_parallel_o;
    wire byte_ready_o;

    integer i, j, error_count;
    reg [7:0] expected_byte;

    // Initialize DUT
    sipo uut (
        .clk(clk), .rst_n(rst_n),
        .data_serial_i(data_serial_i),
        .valid_serial_i(valid_serial_i),
        .data_parallel_o(data_parallel_o),
        .byte_ready_o(byte_ready_o)
    );

    // 100MHz Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to display report (Fix to get value as soon as Ready)
    task display_report;
        input [8*30:1] scenario;
        input [7:0] exp_data;
        begin
            $display("[%0t ns] %s", $time, scenario);
            $display("      --------------------------------------------------");
            $display("      Signal      |   Got    | Expected | Status");
            $display("      ------------|----------|----------|---------");
            // Here byte_ready_o must be 1 because the calling task waited for it
            $display("      Byte Ready  |    %b     |    1     | %s", byte_ready_o, (byte_ready_o === 1'b1) ? "OK" : "ERR");
            $display("      Parallel Out| %b | %b | %s", data_parallel_o, exp_data, (data_parallel_o === exp_data) ? "OK" : "ERR");
            $display("      --------------------------------------------------");
            
            if (byte_ready_o !== 1'b1 || data_parallel_o !== exp_data) 
                error_count = error_count + 1;
        end
    endtask

    // Smart byte send task: Automatically wait for Ready signal
    task send_byte;
        input [7:0] byte_to_send;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge clk); // Input data on falling edge so module catches on next rising edge
                data_serial_i = byte_to_send[i];
                valid_serial_i = 1'b1;
            end
            @(negedge clk);
            valid_serial_i = 1'b0; // Disable valid after 8 bits
            
            // WAIT UNTIL BYTE_READY_O GOES HIGH
            // This is the only way to avoid clock phase skew errors
            wait(byte_ready_o === 1'b1); 
            #1; // Wait 1ns for data to be more stable
        end
    endtask

    initial begin
        error_count = 0;
        data_serial_i = 0; 
        valid_serial_i = 0;
        rst_n = 0;

        $display("=========================================================");
        $display("START SIPO TEST: EVENT-DRIVEN VERSION (NO TIMING ERRORS)");
        $display("=========================================================");

        // 1. Reset
        #20 rst_n = 1;
        #20;
        if (byte_ready_o === 0) $display("[%0t ns] Reset Check: OK", $time);

        // 2. Scenario 1: 0xA5
        send_byte(8'hA5);
        display_report("Scenario 1: 0xA5 Received", 8'hA5);

        // 3. Scenario 2: 0xFF (All bits 1)
        send_byte(8'hFF);
        display_report("Scenario 2: 0xFF Received", 8'hFF);

        // 4. Scenario 3: 0x00 (All bits 0)
        send_byte(8'h00);
        display_report("Scenario 3: 0x00 Received", 8'h00);

        // 5. Scenario 4: Random data (5 times)
        for (j = 1; j <= 5; j = j + 1) begin
            expected_byte = $random;
            send_byte(expected_byte);
            display_report("Scenario 4: Random Byte", expected_byte);
            #20;
        end

        $display("\n=========================================================");
        if (error_count == 0)
            $display("SUMMARY: ALL PASS (0 ERRORS)");
        else
            $display("SUMMARY: %0d ERRORS DETECTED", error_count);
        $display("=========================================================");
        
        #100;
        $finish;
    end

    initial begin
        $dumpfile("sipo.vcd"); // Waveform data file name
        $dumpvars(0, sipo_tb); 
    end
endmodule