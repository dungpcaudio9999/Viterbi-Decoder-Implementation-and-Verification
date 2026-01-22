`timescale 1ns/1ps

module tb_system_top_auto;
    parameter CLK_PERIOD = 10;
    parameter TEST_LOOPS = 5;
    parameter TIMEOUT_CYCLES = 3000;
    
    reg clk, rst_n, dvalid_i;
    reg [15:0] data_i;
    wire [7:0] data_o;
    wire valid_o, busy_o;

    reg [1:0] encoder_state;
    int pass_cnt = 0, fail_cnt = 0, total_test = 0;

    system_top #(.TBL(32)) dut (
        .clk(clk), .rst_n(rst_n),
        .dvalid_i(dvalid_i), .data_i(data_i),
        .data_o(data_o), .valid_o(valid_o), .busy_o(busy_o)
    );

    // =================================================================
    // --- GOLDEN ENCODER MODEL (UPDATED: MSB FIRST) ---
    // =================================================================
    // Rule 1: Input MSB first (i chạy từ 7 xuống 0)
    // Rule 2: Output cặp (X,Y) đặt vào MSB trước (vị trí 15:14)
    function bit [15:0] software_encoder(input bit [7:0] data_in);
        bit [15:0] encoded_word;
        bit u, s0, s1, X, Y;
        int i;
        int step; // Biến phụ để đếm vị trí đóng gói từ 0 đến 7
        
        encoded_word = 0;
        step = 0;

        // VÒNG LẶP SỬA LẠI: Quét từ MSB (bit 7) xuống LSB (bit 0)
        for (i = 7; i >= 0; i--) begin 
            u = data_in[i];        // Lấy bit MSB của dữ liệu vào trước
            s0 = encoder_state[1];  // Trạng thái thanh ghi S0 (FF1)
            s1 = encoder_state[0];  // Trạng thái thanh ghi S1 (FF2)
            
            // Logic đa thức chuẩn Shift Right [7,5] theo tài liệu:
            // X (Poly 111) = u XOR S0 XOR S1
            // Y (Poly 101) = u XOR S1
            X = u ^ s0 ^ s1; 
            Y = u ^ s1;      
            
            // Cập nhật trạng thái (Shift Right): bit mới u đẩy vào S0, S0 cũ đẩy sang S1
            encoder_state = {u, s0}; 

            // Đóng gói vào thanh ghi 16 bit:
            // Cặp bit ứng với bit vào đầu tiên (MSB của data_in) sẽ nằm ở vị trí cao nhất [15:14]
            encoded_word[15 - 2*step] = X; 
            encoded_word[14 - 2*step] = Y; 
            
            step = step + 1; // Tăng bước để dịch vị trí đóng gói cho bit tiếp theo
        end
        return encoded_word;
    endfunction
    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end

    initial begin
        $display("\n==========================================================================================");
        $display("   VITERBI GOLDEN MODEL VERIFICATION");
        $display("==========================================================================================");
        $display("|  INPUT (Hex/Bin)  | ENCODED (16-bit) | OUTPUT (Hex/Bin)  | STATUS |");
        $display("|-------------------|------------------|-------------------|--------|");

        rst_n = 0; dvalid_i = 0; data_i = 0; encoder_state = 0;
        #100; rst_n = 1; #100;

        // --- TEST 1: 0x35 (Từ ví dụ) ---
        run_test(8'h35);

        // --- TEST 2: Random ---
        repeat (TEST_LOOPS) begin
            run_test($urandom());
        end

        // --- TEST 3: Biên ---
        run_test(8'h00);
        run_test(8'hFF);

        $display("==========================================================================================");
        $display(" FINAL SUMMARY: Passed: %0d | Failed: %0d | Total: %0d", pass_cnt, fail_cnt, total_test);
        if (fail_cnt == 0) $display(" >> RESULT: SUCCESS [ALL PASSED]");
        else               $display(" >> RESULT: FAIL");
        $display("==========================================================================================");
        $finish;
    end

    task run_test(input [7:0] original);
        bit [15:0] encoded;
        bit got_result;
        int timeout;
        
        total_test++;
        encoder_state = 0; 
        encoded = software_encoder(original);

        // Gửi Payload
        wait(!busy_o); @(posedge clk);
        dvalid_i = 1; data_i = encoded; @(posedge clk);
        
        // Gửi Flush (0x00)
        wait(!busy_o);
        data_i = 16'h0000; dvalid_i = 1; @(posedge clk);
        dvalid_i = 0;

        // Chờ kết quả
        got_result = 0; timeout = 0;
        
        while (!got_result && timeout < TIMEOUT_CYCLES) begin
            @(posedge clk); timeout++;
            if (valid_o) begin
                if (data_o == original) begin
                    $display("| %h / %b | %b | %h / %b |  PASS  |", 
                             original, original, encoded, data_o, data_o);
                    pass_cnt++;
                end else begin
                    $display("| %h / %b | %b | %h / %b |  FAIL  |", 
                             original, original, encoded, data_o, data_o);
                    fail_cnt++;
                end
                got_result = 1;
            end
        end
        if (!got_result) begin
             $display("| %h / %b | %b |    TIMEOUT        |  FAIL  |", original, original, encoded);
             fail_cnt++;
        end
        #500;
    endtask
endmodule