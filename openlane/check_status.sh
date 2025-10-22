#!/bin/bash
# Check OpenLane ASIC Synthesis Status

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "OpenLane Synthesis Status Check"
echo "=========================================="
echo ""

# Check Docker
echo "1. Docker Status:"
if docker info > /dev/null 2>&1; then
    echo "   ✓ Docker is running"
else
    echo "   ✗ Docker is not running"
    exit 1
fi
echo ""

# Check OpenLane image
echo "2. OpenLane Image:"
if docker images | grep -q "efabless/openlane.*2023.07.19-1"; then
    IMAGE_SIZE=$(docker images efabless/openlane:2023.07.19-1 --format "{{.Size}}")
    echo "   ✓ Image downloaded ($IMAGE_SIZE)"
else
    echo "   ⏳ Image not downloaded yet"
    echo "   Run: docker pull efabless/openlane:2023.07.19-1"
fi
echo ""

# Check running containers
echo "3. Running Containers:"
CONTAINERS=$(docker ps --filter "ancestor=efabless/openlane:2023.07.19-1" --format "{{.ID}} {{.Status}}")
if [ -z "$CONTAINERS" ]; then
    echo "   ⏸️  No OpenLane containers running"
else
    echo "   🏃 OpenLane is running:"
    docker ps --filter "ancestor=efabless/openlane:2023.07.19-1" --format "   Container: {{.ID}}\n   Status: {{.Status}}\n   Uptime: {{.RunningFor}}"
fi
echo ""

# Check runs directory
echo "4. Synthesis Runs:"
RUNS_DIR="$SCRIPT_DIR/microwatt_core/runs"
if [ -d "$RUNS_DIR" ]; then
    NUM_RUNS=$(ls -1 "$RUNS_DIR" 2>/dev/null | wc -l)
    if [ "$NUM_RUNS" -gt 0 ]; then
        echo "   Found $NUM_RUNS run(s):"
        for run in "$RUNS_DIR"/*; do
            if [ -d "$run" ]; then
                RUN_NAME=$(basename "$run")
                echo ""
                echo "   Run: $RUN_NAME"
                
                # Check what stage we're at
                if [ -f "$run/results/final/gds/toplevel.gds" ]; then
                    echo "   ✅ COMPLETE - GDSII generated!"
                    GDS_SIZE=$(du -h "$run/results/final/gds/toplevel.gds" 2>/dev/null | cut -f1)
                    echo "   📦 GDSII size: $GDS_SIZE"
                elif [ -d "$run/results/routing" ]; then
                    echo "   🔄 Stage: Routing"
                elif [ -d "$run/results/cts" ]; then
                    echo "   🔄 Stage: Clock Tree Synthesis"
                elif [ -d "$run/results/placement" ]; then
                    echo "   🔄 Stage: Placement"
                elif [ -d "$run/results/floorplan" ]; then
                    echo "   🔄 Stage: Floorplanning"
                elif [ -d "$run/results/synthesis" ]; then
                    echo "   🔄 Stage: Synthesis"
                else
                    echo "   🔄 Stage: Starting..."
                fi
                
                # Check log file
                if [ -f "$run/openlane.log" ]; then
                    LOG_SIZE=$(du -h "$run/openlane.log" | cut -f1)
                    LOG_LINES=$(wc -l < "$run/openlane.log")
                    echo "   📝 Log: $LOG_SIZE ($LOG_LINES lines)"
                    echo ""
                    echo "   Last 5 log entries:"
                    tail -5 "$run/openlane.log" | sed 's/^/      /'
                fi
            fi
        done
    else
        echo "   ⚠️  No runs found in $RUNS_DIR"
    fi
else
    echo "   ⚠️  Runs directory doesn't exist yet"
    echo "   Location: $RUNS_DIR"
fi
echo ""

# Check log files
echo "5. Recent Logs:"
LOGS_DIR="$SCRIPT_DIR/microwatt_core/logs"
if [ -d "$LOGS_DIR" ]; then
    LATEST_LOG=$(ls -t "$LOGS_DIR"/*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        LOG_SIZE=$(du -h "$LATEST_LOG" | cut -f1)
        LOG_LINES=$(wc -l < "$LATEST_LOG")
        echo "   Latest: $(basename "$LATEST_LOG")"
        echo "   Size: $LOG_SIZE ($LOG_LINES lines)"
        echo ""
        echo "   To follow in real-time:"
        echo "   tail -f $LATEST_LOG"
    else
        echo "   No log files found"
    fi
else
    echo "   No logs directory"
fi
echo ""

echo "=========================================="
echo "Quick Commands:"
echo "=========================================="
echo ""
echo "Start synthesis:"
echo "  cd $SCRIPT_DIR"
echo "  ./run_synthesis.sh"
echo ""
echo "Monitor live (if running):"
echo "  docker logs -f \$(docker ps -q --filter ancestor=efabless/openlane:2023.07.19-1)"
echo ""
echo "View results:"
echo "  ls -lh $SCRIPT_DIR/microwatt_core/runs/*/results/final/gds/"
echo ""

