#!/bin/bash
# OpenLane ASIC Synthesis Runner
# This will take 6-8 hours to complete

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Microwatt-LL ASIC Synthesis"
echo "=========================================="
echo "Project: $PROJECT_ROOT"
echo "Design: microwatt_core"
echo "Expected duration: 6-8 hours"
echo ""

# Check if RTL exists
if [ ! -f "$PROJECT_ROOT/rtl/microwatt_asic.v" ]; then
    echo "ERROR: RTL file not found: $PROJECT_ROOT/rtl/microwatt_asic.v"
    exit 1
fi

echo "✓ RTL file found ($(du -h $PROJECT_ROOT/rtl/microwatt_asic.v | cut -f1))"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Pull OpenLane image if not present
OPENLANE_TAG="2024.04.22"
if ! docker images | grep -q "efabless/openlane.*$OPENLANE_TAG"; then
    echo "Pulling OpenLane Docker image (this may take 10-15 minutes)..."
    docker pull efabless/openlane:$OPENLANE_TAG
    echo ""
fi

echo "✓ OpenLane image ready"
echo ""

# Create output directory for logs
mkdir -p "$SCRIPT_DIR/microwatt_core/logs"

LOG_FILE="$SCRIPT_DIR/microwatt_core/logs/synthesis_$(date +%Y%m%d_%H%M%S).log"

echo "Starting OpenLane synthesis..."
echo "Log file: $LOG_FILE"
echo ""
echo "To monitor progress:"
echo "  tail -f $LOG_FILE"
echo ""
echo "To check status:"
echo "  docker ps"
echo ""
echo "Press Ctrl+C to stop monitoring (synthesis will continue in background)"
echo ""
echo "=========================================="
echo ""

# Run OpenLane
cd "$SCRIPT_DIR/microwatt_core"

# Download PDK if needed
PDK_DIR="$PROJECT_ROOT/pdk"
if [ ! -d "$PDK_DIR/sky130A" ]; then
    echo "Downloading Sky130 PDK (this may take 5-10 minutes)..."
    mkdir -p "$PDK_DIR"
    docker run --rm \
        -v "$PDK_DIR:/build/pdk" \
        efabless/openlane:$OPENLANE_TAG \
        bash -c "volare enable --pdk sky130 bdc9412b3e468c102d01b7cf6337be06ec6e9c9a" || \
    docker run --rm \
        -v "$PDK_DIR:/build/pdk" \
        efabless/openlane:$OPENLANE_TAG \
        bash -c "python3 -m pip install volare && volare enable --pdk sky130 bdc9412b3e468c102d01b7cf6337be06ec6e9c9a"
    echo ""
fi

docker run --rm \
    -v "$PROJECT_ROOT:/work" \
    -v "$PDK_DIR:/build/pdk" \
    efabless/openlane:$OPENLANE_TAG \
    bash -c "cd /work/openlane/microwatt_core && flow.tcl -design . -tag microwatt_ll_$(date +%Y%m%d_%H%M%S)" \
    2>&1 | tee "$LOG_FILE"

echo ""
echo "=========================================="
echo "Synthesis complete!"
echo "=========================================="
echo ""
echo "Results in: $SCRIPT_DIR/microwatt_core/runs/"
echo ""
echo "Key outputs:"
echo "  - GDSII: runs/*/results/final/gds/toplevel.gds"
echo "  - DEF: runs/*/results/final/def/toplevel.def"
echo "  - Verilog: runs/*/results/final/verilog/toplevel.v"
echo "  - Reports: runs/*/reports/"
echo ""

