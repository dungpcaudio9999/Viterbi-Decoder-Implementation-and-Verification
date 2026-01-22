`timescale 1ns / 1ps

module sipo_tb();

    // Tin hieu ket noi
    reg clk, rst_n, data_serial_i, valid_serial_i;
    wire [7:0] data_parallel_o;
    wire byte_ready_o;

    integer i, j, error_count;
    reg [7:0] expected_byte;

    // Khoi tao DUT
    sipo uut (
        .clk(clk), .rst_n(rst_n),
        .data_serial_i(data_serial_i),
        .valid_serial_i(valid_serial_i),
        .data_parallel_o(data_parallel_o),
        .byte_ready_o(byte_ready_o)
    );

    // Clock 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Task hien thi bao cao (Sua loi de lay gia tri ngay khi Ready)
    task display_report;
        input [8*30:1] scenario;
        input [7:0] exp_data;
        begin
            $display("[%0t ns] %s", $time, scenario);
            $display("      --------------------------------------------------");
            $display("      Signal      |   Got    | Expected | Status");
            $display("      ------------|----------|----------|---------");
            // Tai day byte_ready_o chac chan phai la 1 vi task goi da doi no
            $display("      Byte Ready  |    %b     |    1     | %s", byte_ready_o, (byte_ready_o === 1'b1) ? "OK" : "ERR");
            $display("      Parallel Out| %b | %b | %s", data_parallel_o, exp_data, (data_parallel_o === exp_data) ? "OK" : "ERR");
            $display("      --------------------------------------------------");
            
            if (byte_ready_o !== 1'b1 || data_parallel_o !== exp_data) 
                error_count = error_count + 1;
        end
    endtask

    // Task gui byte thong minh: Tu dong doi tin hieu Ready
    task send_byte;
        input [7:0] byte_to_send;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge clk); // Dua du lieu vao canh xuong de module bat o canh len tiep theo
                data_serial_i = byte_to_send[i];
                valid_serial_i = 1'b1;
            end
            @(negedge clk);
            valid_serial_i = 1'b0; // Tat valid sau 8 bit
            
            // DOI CHO DEN KHI BYTE_READY_O LEN CAO
            // Day la cach duy nhat de tranh loi lech pha clock
            wait(byte_ready_o === 1'b1); 
            #1; // Doi 1ns de du lieu on dinh hon
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

        // 3. Scenario 2: 0xFF (Tat ca bit 1)
        send_byte(8'hFF);
        display_report("Scenario 2: 0xFF Received", 8'hFF);

        // 4. Scenario 3: 0x00 (Tat ca bit 0)
        send_byte(8'h00);
        display_report("Scenario 3: 0x00 Received", 8'h00);

        // 5. Scenario 4: Du lieu ngau nhien (5 lan)
        for (j = 1; j <= 5; j = j + 1) begin
            expected_byte = $random;
            send_byte(expected_byte);
            display_report("Scenario 4: Random Byte", expected_byte);
            #20;
        end

        $display("\n=========================================================");
        if (error_count == 0)
            $display("TONG KET: TAT CA PASS (0 LOI)");
        else
            $display("TONG KET: PHAT HIEN %0d LOI", error_count);
        $display("=========================================================");
        
        #100;
        $finish;
    end

    initial begin
        $dumpfile("sipo.vcd"); // Ten file du lieu song
        $dumpvars(0, sipo_tb); 
    end
endmodule