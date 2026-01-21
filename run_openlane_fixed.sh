#!/bin/bash

# ==============================================================================
# Script chạy OpenLane cho Viterbi Decoder (Fixed Version)
# ==============================================================================

set -e

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ==============================================================================
# Cấu hình
# ==============================================================================

PROJECT_DIR="/home/iot/Study/VLSI/Open_Lane/Viterbi-Decoder-Implementation-and-Verification"
DESIGN_DIR="$PROJECT_DIR/OpenLane/designs/viterbi"
DESIGN_NAME="viterbi"

# Sử dụng container OpenLane latest
OPENLANE_IMAGE="efabless/openlane:latest"

print_header "CHẠY OPENLANE CHO VITERBI DECODER"

# ==============================================================================
# Kiểm tra Docker
# ==============================================================================

print_info "Kiểm tra Docker..."

if ! command -v docker &> /dev/null; then
    print_error "Docker chưa được cài đặt!"
    exit 1
fi

if ! docker ps &> /dev/null; then
    print_error "Docker daemon không chạy hoặc user chưa có quyền"
    exit 1
fi

print_success "Docker OK"

# ==============================================================================
# Kiểm tra design
# ==============================================================================

print_info "Kiểm tra design..."

if [ ! -d "$DESIGN_DIR" ]; then
    print_error "Không tìm thấy design directory: $DESIGN_DIR"
    exit 1
fi

if [ ! -f "$DESIGN_DIR/config.tcl" ]; then
    print_error "Không tìm thấy config.tcl"
    exit 1
fi

print_success "Design OK"

# ==============================================================================
# Pull Docker image (nếu chưa có)
# ==============================================================================

print_info "Kiểm tra Docker image..."

if ! docker image inspect "$OPENLANE_IMAGE" &> /dev/null; then
    print_info "Đang tải Docker image $OPENLANE_IMAGE..."
    docker pull "$OPENLANE_IMAGE"
fi

print_success "Docker image OK"

# ==============================================================================
# Chạy OpenLane Flow
# ==============================================================================

print_header "CHẠY OPENLANE FLOW"

print_info "Design: $DESIGN_NAME"
print_info "Container: $OPENLANE_IMAGE"
print_info "Thời gian ước tính: 30-60 phút"
echo ""

# Tạo thư mục cho PDK nếu chưa có
mkdir -p "$HOME/.ciel"

# Chạy OpenLane trong Docker
docker run --rm \
    -v "$DESIGN_DIR:/openlane/designs/$DESIGN_NAME:ro" \
    -v "$DESIGN_DIR/runs:/openlane/designs/$DESIGN_NAME/runs" \
    -v "$HOME/.ciel:/home/openlane/.ciel" \
    -e PDK_ROOT=/home/openlane/.ciel \
    -e PDK=sky130A \
    --user $(id -u):$(id -g) \
    "$OPENLANE_IMAGE" \
    bash -c "/openlane1/flow.tcl -design /openlane/designs/$DESIGN_NAME -tag run_$(date +%Y.%m.%d_%H.%M.%S)"

# ==============================================================================
# Kiểm tra kết quả
# ==============================================================================

print_header "KIỂM TRA KẾT QUẢ"

# Tìm run directory mới nhất
RUN_DIR=$(ls -td "$DESIGN_DIR/runs"/*/ 2>/dev/null | head -1)

if [ -z "$RUN_DIR" ]; then
    print_error "Không tìm thấy kết quả run"
    exit 1
fi

print_success "Run directory: $RUN_DIR"

# Kiểm tra GDSII
if [ -f "$RUN_DIR/results/final/gds/system_top.gds" ]; then
    print_success "GDSII file đã được tạo!"
    echo "File: $RUN_DIR/results/final/gds/system_top.gds"
else
    print_error "GDSII file chưa được tạo"
fi

# Hiển thị đường dẫn reports
echo ""
print_info "Xem kết quả chi tiết:"
echo "  Synthesis: cat $RUN_DIR/reports/synthesis/1-synthesis.stat.rpt"
echo "  Timing:    cat $RUN_DIR/reports/signoff/*/summary.rpt"
echo "  DRC:       cat $RUN_DIR/reports/signoff/*-drc.rpt"
echo "  LVS:       cat $RUN_DIR/reports/signoff/*-lvs.rpt"
echo "  Metrics:   cat $RUN_DIR/reports/metrics.csv"

print_success "Hoàn thành!"
