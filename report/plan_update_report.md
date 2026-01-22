# Kế hoạch cập nhật Báo cáo Viterbi Decoder (RTL đến GDSII)

Tài liệu này vạch ra các bước cần thiết để chỉnh sửa file `main (2).tex` sao cho khớp hoàn toàn với mã nguồn Verilog thực tế và kết quả từ OpenLane.

## 1. Cập nhật Chương 2: Thiết kế chi tiết (Khớp với `design/*.v`)

### 1.1. Cấu trúc hệ thống Top-Level (`system_top.v`)

* **Mô tả mới**: Hệ thống không chỉ có bộ giải mã mà là một SoC con hoàn chỉnh với:
  * **Sync FIFO**: Đệm dữ liệu đầu vào (16x16 bit), giải quyết vấn đề bất đối xứng tốc độ.
  * **PISO (Parallel-In Serial-Out)**: Chuyển đổi gói tin 16-bit thành dòng bit (cặp 2 bit) để đưa vào Core.
  * **SIPO (Serial-In Parallel-Out)**: Đóng gói dòng bit đã giải mã thành kết quả 8-bit (Byte).
* **Hình vẽ**: Cần sơ đồ khối thể hiện luồng: `Data In -> FIFO -> PISO -> Core -> SIPO -> Data Out`.

### 1.2. Kiến trúc Viterbi Core (`viterbi_core.v`)

* **BMU (Branch Metric Unit)**: Tính toán khoảng cách Hamming của 8 nhánh dựa trên đầu vào 2-bit.
* **ACSU (Add-Compare-Select Unit)**: Tính toán Path Metric mới cho 4 trạng thái (S0-S3) và xuất ra 4 bit quyết định (`dec_bits`).
* **PMU (Path Metric Unit)**: Chỉ đóng vai trò thanh ghi lưu trữ giá trị Path Metric hiện tại.
* **TBU (Traceback/Survivor Unit)**: **QUAN TRỌNG** - Thay đổi hoàn toàn từ "Traceback" sang **"Register Exchange"**.
  * Giải thích cơ chế dịch lịch sử bit trực tiếp trong các thanh ghi `history_s0` đến `history_s3`.
  * Độ dài thanh ghi (Constraint length): TBL = 15.
  * Lợi ích: Xuất dữ liệu ngay lập tức sau mỗi chu kỳ, không cần chu kỳ truy vết ngược.

## 2. Cập nhật Chương 3: Kết quả triển khai (Khớp với OpenLane `metrics.csv`)

Sử dụng số liệu thực tế từ lần chạy `RUN_2026.01.21_02.17.41`:

* **Công cụ**: OpenLane Flow, Sky130 PDK.
* **Diện tích (Area)**: 0.16 mm² (Die area).
* **Số lượng Cell**: ~2032 cells.
* **Mật độ (Core Utilization)**: 40%.
* **Thời gian/Tần số**: Tần số hoạt động 50 MHz (Clock period 20ns).
* **Công suất (Power)**: Tổng công suất ước tính khoảng 0.007 mW.
* **Vi phạm (Violations)**: 0 vi phạm (Setup, Hold, DRC, LVS).

## 3. Các chỉnh sửa nhỏ khác

* **Font chữ**: Giữ nguyên `Liberation Serif` để tương thích hệ thống.
* **Bảng biểu**: Cập nhật bảng tín hiệu vào/ra của `system_top` (thêm `busy_o`, `dvalid_i`).
* **Tóm tắt**: Nhấn mạnh việc sử dụng thành công quy trình Open Source (OpenLane) thay vì chỉ dùng Cadence như lý thuyết cũ.

## 5. Mục lục dự kiến MỚI (Cập nhật theo feedback Leader)

Cấu trúc báo cáo sẽ được mở rộng thành 4 chương chính để tách biệt rõ ràng giữa Thiết kế, Kiểm tra chức năng và Triển khai vật lý:

*   **TÓM TẮT NỘI DUNG**
*   **CHƯƠNG 1: TỔNG QUAN VỀ MÃ TÍCH CHẬP VÀ GIẢI MÃ VITERBI**
    *   1.1. Giới thiệu mã tích chập (n, k, m) và đa thức sinh.
    *   1.2. Thuật toán Viterbi và nguyên lý tìm đường Maximum Likelihood.
*   **CHƯƠNG 2: ĐẶC TẢ KỸ THUẬT VÀ THIẾT KẾ RTL (Specifications & RTL Design)**
    *   2.1. Đặc tả kỹ thuật (Specifications):
        *   Các tham số thiết kế (K=3, Rate=1/2, Polynomials).
        *   Bảng đặc tả tín hiệu vào/ra (Interface Specification).
    *   2.2. Kiến trúc hệ thống (System Architecture):
        *   Sơ đồ khối Top-level (System Top).
        *   Luồng dữ liệu (Dataflow): FIFO -> PISO -> Core -> SIPO.
    *   2.3. Triển khai RTL (RTL Implementation):
        *   Mô tả chi tiết và trích dẫn mã RTL quan trọng cho từng khối:
            *   BMU (Branch Metric Unit).
            *   ACSU (Add-Compare-Select Unit).
            *   TBU (Traceback Unit) - Nhấn mạnh giải thuật Register Exchange.
*   **CHƯƠNG 3: KIỂM TRA CHỨC NĂNG MẠCH (Functional Verification)**
    *   3.1. Môi trường kiểm chứng (Testbench Environment):
        *   Cấu trúc Testbench (`tb_system_top`).
        *   Kịch bản kiểm tra (Test Cases): Random inputs, so sánh kết quả tự động.
    *   3.2. Kết quả mô phỏng (Simulation Results):
        *   Dạng sóng tín hiệu (Waveforms).
        *   Log kiểm tra dữ liệu.
*   **CHƯƠNG 4: TỔNG HỢP VÀ THIẾT KẾ VẬT LÝ (Synthesis & Physical Design)**
    *   4.1. Quy trình OpenLane Flow (RTL-to-GDSII).
    *   4.2. Kết quả tổng hợp (Synthesis Results):
        *   Báo cáo diện tích (Area) và tài nguyên sử dụng.
        *   Báo cáo công suất (Power Analysis).
        *   Phân tích thời gian (Timing Analysis).
    *   4.3. Kết quả thiết kế vật lý (Physical Layout):
        *   Floorplan và Power Distribution Network (PDN).
        *   Placement và Routing.
        *   Hình ảnh Layout GDSII cuối cùng.
*   **KẾT LUẬN**
*   **TÀI LIỆU THAM KHẢO**
