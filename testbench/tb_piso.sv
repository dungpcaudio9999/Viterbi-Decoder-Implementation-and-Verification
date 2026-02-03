`timescale 1ns / 1ps
`include "../design/piso.v"

module piso_tb();

    // Tin hieu ket noi
    reg clk;
    reg rst_n;
    reg [15:0] fifo_data_i;
    reg fifo_empty_i;
    wire fifo_rd_en_o;
    wire [1:0] data_serial_o;
    wire valid_serial_o;

    integer i, j, k, error_count;
    reg [15:0] test_val;
    reg [15:0] exp_shift_reg;

    // Khoi tao DUT
    piso uut (
        .clk(clk),
        .rst_n(rst_n),
        .fifo_data_i(fifo_data_i),
        .fifo_empty_i(fifo_empty_i),
        .fifo_rd_en_o(fifo_rd_en_o),
        .data_serial_o(data_serial_o),
        .valid_serial_o(valid_serial_o)
    );

    // Tao xung Clock (10ns = 100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Task kiem tra 1 chu ky PISO (8 cap bits)
    task check_piso_cycle;
        input [15:0] expected_data;
        begin
            exp_shift_reg = expected_data;
            
            // Cho cho den khi valid_serial_o len 1
            wait(valid_serial_o == 1'b1);
            
            for (k = 0; k < 8; k = k + 1) begin
                // So sanh ket qua thuc te va ky vong
                if (data_serial_o === exp_shift_reg[15:14]) begin
                    $display("[%0t ns] [PASS] Step %0d | Got: %b | Exp: %b", $time, k, data_serial_o, exp_shift_reg[15:14]);
                end else begin
                    $display("[%0t ns] [FAIL] Step %0d | Got: %b | Exp: %b <--- ERR", $time, k, data_serial_o, exp_shift_reg[15:14]);
                    error_count = error_count + 1;
                end
                
                // Cap nhat mo hinh dich bit de so sanh
                exp_shift_reg = {exp_shift_reg[13:0], 2'b00};
                @(posedge clk);
                #1; // Offset nho de kiem tra du lieu sau canh clock
            end
        end
    endtask

    initial begin
        // Khoi tao
        error_count = 0;
        rst_n = 0;
        fifo_empty_i = 1;
        fifo_data_i = 16'h0;

        $display("=====================================================");
        $display("START PISO TEST: 5 SCENARIOS x 5 ITERATIONS");
        $display("=====================================================");

        #25 rst_n = 1; // Giai phong Reset
        #10;

        // --- Kich ban 1 den 5 ---
        for (i = 0; i < 5; i = i + 1) begin
            case(i)
                0: test_val = 16'hAAAA;
                1: test_val = 16'h5555;
                2: test_val = 16'hFFFF;
                3: test_val = 16'h0000;
                4: test_val = $random;
            endcase

            $display("\n---> SCENARIO %0d: Data 16'h%h", i+1, test_val);

            // Lap lai moi kich ban 5 lan
            for (j = 1; j <= 5; j = j + 1) begin
                $display("  Iteration %0d:", j);
                
                fifo_empty_i = 0;
                fifo_data_i = test_val;

                // Doi lenh doc tu module (fifo_rd_en_o)
                wait(fifo_rd_en_o == 1'b1);
                @(posedge clk);
                #1 fifo_empty_i = 1; // Gia lap FIFO het du lieu sau khi doc

                check_piso_cycle(test_val);
                #20; // Nghi giua cac lan lap
            end
        end

        $display("\n=====================================================");
        if (error_count == 0)
            $display("FINAL TOTAL ERRORS: 0 -> STATUS: ALL PASS");
        else
            $display("FINAL TOTAL ERRORS: %0d -> STATUS: FAIL", error_count);
        $display("=====================================================");
        
        #100;
        $finish;
    end

initial begin
    $dumpfile("piso.vcd"); // Ten file du lieu song
    $dumpvars(0, piso_tb); 
end

endmodule