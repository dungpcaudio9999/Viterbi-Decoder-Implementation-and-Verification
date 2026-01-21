#!/bin/bash

# ==============================================================================
# Script đơn giản để chạy OpenLane cho Viterbi Decoder
# Sử dụng OpenLane v2 (phiên bản mới nhất, ổn định)
# ==============================================================================

set -e

# Màu sắc
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CHẠY OPENLANE V2 CHO VITERBI DECODER${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Cấu hình
PROJECT_DIR="/home/iot/Study/VLSI/Open_Lane/Viterbi-Decoder-Implementation-and-Verification"
DESIGN_DIR="$PROJECT_DIR/OpenLane/designs/viterbi"

# Kiểm tra design
if [ ! -d "$DESIGN_DIR" ]; then
    echo -e "${RED}✗ Không tìm thấy design directory${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Design directory OK${NC}"
echo -e "${BLUE}ℹ Design: $DESIGN_DIR${NC}"
echo ""

# Kiểm tra xem đã có OpenLane v2 chưa
if [ ! -d "$HOME/openlane2" ]; then
    echo -e "${YELLOW}⚠ OpenLane v2 chưa được cài đặt${NC}"
    echo -e "${BLUE}ℹ Đang clone OpenLane v2...${NC}"
    
    cd ~
    git clone --depth=1 https://github.com/The-OpenROAD-Project/OpenLane.git openlane2
    
    echo -e "${GREEN}✓ Clone thành công${NC}"
fi

# Chuyển đến OpenLane v2
cd ~/openlane2

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CHẠY FLOW${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}⚠ Quá trình này có thể mất 30-60 phút${NC}"
echo ""

# Chạy OpenLane v2 với Nix
if command -v nix-shell &> /dev/null; then
    echo -e "${BLUE}ℹ Sử dụng Nix shell...${NC}"
    nix-shell --run "openlane --dockerized $DESIGN_DIR/config.json"
else
    echo -e "${BLUE}ℹ Sử dụng Docker trực tiếp...${NC}"
    
    # Tạo config.json từ config.tcl nếu chưa có
    if [ ! -f "$DESIGN_DIR/config.json" ]; then
        echo -e "${YELLOW}⚠ Chuyển đổi config.tcl sang config.json...${NC}"
        
        cat > "$DESIGN_DIR/config.json" << 'EOF'
{
    "DESIGN_NAME": "system_top",
    "VERILOG_FILES": "dir::src/*.v",
    "CLOCK_PORT": "clk",
    "CLOCK_PERIOD": 20.0,
    "FP_CORE_UTIL": 40,
    "FP_SIZING": "absolute",
    "DIE_AREA": "0 0 400 400",
    "PL_TARGET_DENSITY": 0.45,
    "SYNTH_STRATEGY": "AREA 0",
    "SYNTH_MAX_FANOUT": 10,
    "DIODE_INSERTION_STRATEGY": 4,
    "RUN_MAGIC_DRC": true,
    "RUN_LVS": true
}
EOF
        echo -e "${GREEN}✓ Đã tạo config.json${NC}"
    fi
    
    # Chạy với Docker
    python3 -m openlane --dockerized $DESIGN_DIR/config.json
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}KIỂM TRA KẾT QUẢ${NC}"
echo -e "${BLUE}========================================${NC}"

# Tìm run directory mới nhất
RUN_DIR=$(ls -td "$DESIGN_DIR/runs"/*/ 2>/dev/null | head -1)

if [ -n "$RUN_DIR" ]; then
    echo -e "${GREEN}✓ Run directory: $RUN_DIR${NC}"
    
    # Kiểm tra GDSII
    if [ -f "$RUN_DIR/results/final/gds/system_top.gds" ]; then
        echo -e "${GREEN}✓ GDSII file đã được tạo!${NC}"
        echo "  File: $RUN_DIR/results/final/gds/system_top.gds"
    fi
    
    echo ""
    echo -e "${BLUE}ℹ Xem kết quả chi tiết:${NC}"
    echo "  cat $RUN_DIR/reports/metrics.csv"
else
    echo -e "${RED}✗ Không tìm thấy kết quả run${NC}"
fi

echo ""
echo -e "${GREEN}✓ Hoàn thành!${NC}"
