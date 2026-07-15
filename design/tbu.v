module tbu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    
    // 4 decision bits from ACSU (to update history)
    input  wire [3:0] dec_bits_i,
    
    // NEW Path Metrics from ACSU (to select best path for output)
    input  wire [7:0] pm_new_s0_i, pm_new_s1_i, pm_new_s2_i, pm_new_s3_i,

    // Outputs
    output reg         decoded_bit_o,
    output reg         valid_o
);

    // Configuration: Traceback length
    localparam TBL = 15;

    // History registers (Register Exchange)
    reg [TBL-1:0] history_s0, history_s1, history_s2, history_s3;
    
    // Pipeline latency management
    reg [3:0] latency_counter;
    reg       pipeline_full;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            history_s0 <= {TBL{1'b0}};
            history_s1 <= {TBL{1'b0}};
            history_s2 <= {TBL{1'b0}};
            history_s3 <= {TBL{1'b0}};
            latency_counter <= 4'd0;
            pipeline_full <= 1'b0;
            valid_o <= 1'b0;
            decoded_bit_o <= 1'b0;
        end else if (valid_i) begin
            // 1. Register Exchange Update (Update history)
            // S0
            if (dec_bits_i[0] == 0) history_s0 <= {history_s0[TBL-2:0], 1'b0};
            else                    history_s0 <= {history_s1[TBL-2:0], 1'b0};
            // S1
            if (dec_bits_i[1] == 0) history_s1 <= {history_s2[TBL-2:0], 1'b0};
            else                    history_s1 <= {history_s3[TBL-2:0], 1'b0};
            // S2
            if (dec_bits_i[2] == 0) history_s2 <= {history_s0[TBL-2:0], 1'b1};
            else                    history_s2 <= {history_s1[TBL-2:0], 1'b1};
            // S3
            if (dec_bits_i[3] == 0) history_s3 <= {history_s2[TBL-2:0], 1'b1};
            else                    history_s3 <= {history_s3[TBL-2:0], 1'b1};

            // 2. Output Logic
            if (!pipeline_full) begin
                latency_counter <= latency_counter + 1;
                if (latency_counter == TBL-1) pipeline_full <= 1'b1;
                valid_o <= 1'b0;
            end else begin
                valid_o <= 1'b1;
                // Find Min Path Metric to select the most reliable output bit
                if (pm_new_s0_i <= pm_new_s1_i && pm_new_s0_i <= pm_new_s2_i && pm_new_s0_i <= pm_new_s3_i)
                    decoded_bit_o <= history_s0[TBL-1];
                else if (pm_new_s1_i <= pm_new_s0_i && pm_new_s1_i <= pm_new_s2_i && pm_new_s1_i <= pm_new_s3_i)
                    decoded_bit_o <= history_s1[TBL-1];
                else if (pm_new_s2_i <= pm_new_s0_i && pm_new_s2_i <= pm_new_s1_i && pm_new_s2_i <= pm_new_s3_i)
                    decoded_bit_o <= history_s2[TBL-1];
                else
                    decoded_bit_o <= history_s3[TBL-1];
            end
        end else begin
            valid_o <= 1'b0;
        end
    end

endmodule