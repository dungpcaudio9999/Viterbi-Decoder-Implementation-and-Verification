#!/bin/bash

# ==============================================================================
# Script tự động chạy OpenLane cho Viterbi Decoder
# ==============================================================================

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# Hàm tiện ích
# ==============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ==============================================================================
# Kiểm tra môi trường
# ==============================================================================

check_environment() {
    print_header "KIỂM TRA MÔI TRƯỜNG"
    
    # Kiểm tra Docker
    if command -v docker &> /dev/null; then
        print_success "Docker đã cài đặt: $(docker --version)"
    else
        print_error "Docker chưa được cài đặt!"
        echo "Vui lòng cài đặt Docker: sudo apt install docker.io"
        exit 1
    fi
    
    # Kiểm tra Docker có chạy được không
    if docker ps &> /dev/null; then
        print_success "Docker daemon đang chạy"
    else
        print_error "Docker daemon không chạy hoặc user chưa có quyền"
        echo "Thử chạy: sudo systemctl start docker"
        echo "Hoặc thêm user vào group: sudo usermod -aG docker \$USER"
        exit 1
    fi
    
    # Kiểm tra OpenLane
    if [ -d "$HOME/OpenLane" ]; then
        print_success "OpenLane đã cài đặt tại: $HOME/OpenLane"
    else
        print_warning "OpenLane chưa được cài đặt tại $HOME/OpenLane"
        read -p "Bạn có muốn clone OpenLane không? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_openlane
        else
            print_error "Không thể tiếp tục mà không có OpenLane"
            exit 1
        fi
    fi
    
    echo
}

# ==============================================================================
# Cài đặt OpenLane (nếu cần)
# ==============================================================================

install_openlane() {
    print_header "CÀI ĐẶT OPENLANE"
    
    cd ~
    git clone --depth 1 https://github.com/The-OpenROAD-Project/OpenLane.git
    cd OpenLane
    make
    
    print_success "OpenLane đã được cài đặt"
    echo
}

# ==============================================================================
# Chuẩn bị design
# ==============================================================================

prepare_design() {
    print_header "CHUẨN BỊ DESIGN"
    
    PROJECT_DIR="/home/iot/Study/VLSI/Open_Lane/Viterbi-Decoder-Implementation-and-Verification"
    OPENLANE_DIR="$HOME/OpenLane"
    DESIGN_NAME="viterbi"
    
    # Kiểm tra thư mục dự án
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Không tìm thấy thư mục dự án: $PROJECT_DIR"
        exit 1
    fi
    
    print_info "Thư mục dự án: $PROJECT_DIR"
    print_info "Thư mục OpenLane: $OPENLANE_DIR"
    
    # Xóa symbolic link cũ (nếu có)
    if [ -L "$OPENLANE_DIR/designs/$DESIGN_NAME" ]; then
        print_info "Xóa symbolic link cũ..."
        rm "$OPENLANE_DIR/designs/$DESIGN_NAME"
    fi
    
    # Xóa thư mục copy cũ (nếu có)
    if [ -d "$OPENLANE_DIR/designs/$DESIGN_NAME" ] && [ ! -L "$OPENLANE_DIR/designs/$DESIGN_NAME" ]; then
        print_warning "Thư mục $DESIGN_NAME đã tồn tại trong OpenLane"
        read -p "Bạn có muốn ghi đè không? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$OPENLANE_DIR/designs/$DESIGN_NAME"
        else
            print_info "Sử dụng design hiện có"
            return
        fi
    fi
    
    # Tạo symbolic link
    print_info "Tạo symbolic link..."
    ln -s "$PROJECT_DIR/OpenLane/designs/$DESIGN_NAME" "$OPENLANE_DIR/designs/$DESIGN_NAME"
    
    print_success "Design đã sẵn sàng tại: $OPENLANE_DIR/designs/$DESIGN_NAME"
    
    # Kiểm tra các file cần thiết
    print_info "Kiểm tra các file cần thiết..."
    
    if [ -f "$OPENLANE_DIR/designs/$DESIGN_NAME/config.tcl" ]; then
        print_success "config.tcl ✓"
    else
        print_error "Thiếu config.tcl"
        exit 1
    fi
    
    if [ -f "$OPENLANE_DIR/designs/$DESIGN_NAME/constraints.sdc" ]; then
        print_success "constraints.sdc ✓"
    else
        print_warning "Thiếu constraints.sdc (không bắt buộc)"
    fi
    
    if [ -d "$OPENLANE_DIR/designs/$DESIGN_NAME/src" ]; then
        NUM_FILES=$(ls -1 "$OPENLANE_DIR/designs/$DESIGN_NAME/src"/*.v 2>/dev/null | wc -l)
        print_success "Thư mục src/ có $NUM_FILES file .v"
    else
        print_error "Thiếu thư mục src/"
        exit 1
    fi
    
    echo
}

# ==============================================================================
# Chạy OpenLane
# ==============================================================================

run_openlane() {
    print_header "CHẠY OPENLANE FLOW"
    
    DESIGN_NAME="viterbi"
    OPENLANE_DIR="$HOME/OpenLane"
    
    cd "$OPENLANE_DIR"
    
    # Hỏi user muốn chạy mode nào
    echo "Chọn mode chạy:"
    echo "1) Automatic Flow (tự động, khuyến nghị cho lần đầu)"
    echo "2) Interactive Flow (từng bước, dễ debug)"
    read -p "Lựa chọn (1/2): " -n 1 -r
    echo
    
    if [[ $REPLY == "1" ]]; then
        run_automatic_flow
    elif [[ $REPLY == "2" ]]; then
        run_interactive_flow
    else
        print_error "Lựa chọn không hợp lệ"
        exit 1
    fi
}

# ==============================================================================
# Automatic Flow
# ==============================================================================

run_automatic_flow() {
    print_info "Chạy Automatic Flow..."
    print_warning "Quá trình này có thể mất 30-60 phút"
    
    DESIGN_NAME="viterbi"
    
    # Ghi log thời gian bắt đầu
    START_TIME=$(date +%s)
    
    # Chạy flow
    make mount DESIGN_NAME=$DESIGN_NAME OPENLANE_TAG=latest OPENLANE_IMAGE_NAME=efabless/openlane:latest || {
        print_error "Lỗi khi khởi động Docker"
        exit 1
    }
    
    # Tính thời gian
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    print_success "Hoàn thành trong ${MINUTES}m ${SECONDS}s"
    
    # Hiển thị kết quả
    show_results
}

# ==============================================================================
# Interactive Flow
# ==============================================================================

run_interactive_flow() {
    print_info "Chạy Interactive Flow..."
    print_info "Bạn sẽ vào Docker container để chạy từng bước thủ công"
    
    DESIGN_NAME="viterbi"
    
    echo
    print_warning "Sau khi vào container, chạy các lệnh sau:"
    echo
    echo -e "${GREEN}./flow.tcl -design $DESIGN_NAME -interactive${NC}"
    echo
    echo "Trong interactive mode:"
    echo -e "${GREEN}package require openlane 0.9${NC}"
    echo -e "${GREEN}prep -design $DESIGN_NAME${NC}"
    echo -e "${GREEN}run_synthesis${NC}"
    echo -e "${GREEN}run_floorplan${NC}"
    echo -e "${GREEN}run_placement${NC}"
    echo -e "${GREEN}run_cts${NC}"
    echo -e "${GREEN}run_routing${NC}"
    echo -e "${GREEN}run_magic${NC}"
    echo -e "${GREEN}run_lvs${NC}"
    echo -e "${GREEN}run_antenna_check${NC}"
    echo
    
    read -p "Nhấn Enter để vào Docker container..." 
    
    # Khởi động container
    make mount
}

# ==============================================================================
# Hiển thị kết quả
# ==============================================================================

show_results() {
    print_header "KẾT QUẢ TỔNG HỢP"
    
    DESIGN_NAME="viterbi"
    OPENLANE_DIR="$HOME/OpenLane"
    
    # Tìm run directory mới nhất
    RUN_DIR=$(ls -td "$OPENLANE_DIR/designs/$DESIGN_NAME/runs"/*/ 2>/dev/null | head -1)
    
    if [ -z "$RUN_DIR" ]; then
        print_error "Không tìm thấy kết quả run"
        return
    fi
    
    print_info "Run directory: $RUN_DIR"
    echo
    
    # Kiểm tra synthesis
    if [ -f "$RUN_DIR/reports/synthesis/1-synthesis.stat.rpt" ]; then
        print_success "Synthesis report có sẵn"
        echo "Xem: cat $RUN_DIR/reports/synthesis/1-synthesis.stat.rpt"
    else
        print_warning "Không tìm thấy synthesis report"
    fi
    
    # Kiểm tra timing
    if [ -f "$RUN_DIR/reports/signoff/system_top-sta-rcx_nom/summary.rpt" ]; then
        print_success "Timing report có sẵn"
        echo "Xem: cat $RUN_DIR/reports/signoff/system_top-sta-rcx_nom/summary.rpt"
    else
        print_warning "Không tìm thấy timing report"
    fi
    
    # Kiểm tra DRC
    if [ -f "$RUN_DIR/reports/signoff/system_top-drc.rpt" ]; then
        DRC_COUNT=$(grep -c "violation" "$RUN_DIR/reports/signoff/system_top-drc.rpt" 2>/dev/null || echo "0")
        if [ "$DRC_COUNT" -eq 0 ]; then
            print_success "DRC: PASS (0 violations)"
        else
            print_warning "DRC: $DRC_COUNT violations"
        fi
    else
        print_warning "Không tìm thấy DRC report"
    fi
    
    # Kiểm tra LVS
    if [ -f "$RUN_DIR/reports/signoff/system_top-lvs.rpt" ]; then
        if grep -q "match uniquely" "$RUN_DIR/reports/signoff/system_top-lvs.rpt"; then
            print_success "LVS: PASS (circuits match)"
        else
            print_warning "LVS: FAIL (circuits mismatch)"
        fi
    else
        print_warning "Không tìm thấy LVS report"
    fi
    
    # Kiểm tra GDSII
    if [ -f "$RUN_DIR/results/final/gds/system_top.gds" ]; then
        print_success "GDSII file đã được tạo"
        echo "File: $RUN_DIR/results/final/gds/system_top.gds"
        echo "Xem bằng: klayout $RUN_DIR/results/final/gds/system_top.gds"
    else
        print_warning "Không tìm thấy GDSII file"
    fi
    
    echo
    print_info "Để xem tất cả metrics:"
    echo "cat $RUN_DIR/reports/metrics.csv"
    
    echo
}

# ==============================================================================
# Menu chính
# ==============================================================================

main_menu() {
    while true; do
        clear
        print_header "OPENLANE AUTOMATION SCRIPT - VITERBI DECODER"
        echo
        echo "1) Kiểm tra môi trường"
        echo "2) Chuẩn bị design"
        echo "3) Chạy OpenLane"
        echo "4) Xem kết quả"
        echo "5) Chạy tất cả (1 → 2 → 3 → 4)"
        echo "6) Thoát"
        echo
        read -p "Lựa chọn: " choice
        
        case $choice in
            1)
                check_environment
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            2)
                prepare_design
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            3)
                run_openlane
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            4)
                show_results
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            5)
                check_environment
                prepare_design
                run_openlane
                show_results
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            6)
                print_info "Thoát chương trình"
                exit 0
                ;;
            *)
                print_error "Lựa chọn không hợp lệ"
                sleep 2
                ;;
        esac
    done
}

# ==============================================================================
# Chạy script
# ==============================================================================

# Nếu có argument, chạy trực tiếp
if [ $# -gt 0 ]; then
    case $1 in
        check)
            check_environment
            ;;
        prepare)
            prepare_design
            ;;
        run)
            run_openlane
            ;;
        results)
            show_results
            ;;
        auto)
            check_environment
            prepare_design
            run_openlane
            show_results
            ;;
        *)
            echo "Usage: $0 {check|prepare|run|results|auto}"
            exit 1
            ;;
    esac
else
    # Không có argument, hiển thị menu
    main_menu
fi
