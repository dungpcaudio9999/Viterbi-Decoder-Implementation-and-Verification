#!/bin/bash

# ==============================================================================
# Script Fix PDK Version và Chạy OpenLane Flow
# Theo Lựa chọn 2: Sửa lỗi PDK version mismatch trong container
# ==============================================================================

set -e

# Cấu hình đường dẫn
PROJECT_DIR="/home/iot/Study/VLSI/Open_Lane/Viterbi-Decoder-Implementation-and-Verification"
OPENLANE_DIR="/home/iot/OpenLane"
DESIGN_NAME="viterbi"
PDK_VERSION="bdc9412b3e468c102d01b7cf6337be06ec6e9c9a"

echo "----------------------------------------------------------------"
echo "🚀 ĐANG TIẾN HÀNH FIX PDK VÀ CHẠY OPENLANE..."
echo "----------------------------------------------------------------"

# 1. Chạy ciel trên máy host để kích hoạt đúng phiên bản PDK
echo "🔧 Đang kích hoạt PDK version trên host: $PDK_VERSION..."
/home/iot/OpenLane/venv/bin/ciel enable --pdk sky130A $PDK_VERSION || {
    echo "❌ Lỗi khi kích hoạt PDK version $PDK_VERSION. Đang thử fetch..."
    /home/iot/OpenLane/venv/bin/ciel fetch --pdk sky130A $PDK_VERSION
    /home/iot/OpenLane/venv/bin/ciel enable --pdk sky130A $PDK_VERSION
}

echo "✅ PDK đã sẵn sàng trên host."

# 2. Chạy Docker để thực hiện Flow
echo "🚀 Bắt đầu chạy OpenLane Flow trong container..."
docker run --rm \
    -v "$OPENLANE_DIR:/openlane" \
    -v "$PROJECT_DIR/OpenLane/designs:/openlane/designs" \
    -v "/home/iot/.ciel:/home/iot/pdk" \
    -w /openlane \
    -e PDK_ROOT=/home/iot/pdk \
    -e PDK=sky130A \
    --user $(id -u):$(id -g) \
    efabless/openlane:latest \
    /openlane1/flow.tcl -design /openlane/designs/$DESIGN_NAME

echo "----------------------------------------------------------------"
echo "🏁 QUÁ TRÌNH KẾT THÚC."
echo "----------------------------------------------------------------"
