# Microwatt OpenFrame Pipeline - Setup Status

## Completed Steps ✅

### 1. Project Structure ✅
- Created all necessary directories
- Organized structure: dependencies, config, rtl, openlane, verification, results

### 2. Repository Cloning ✅
All source repositories cloned successfully:

- **Microwatt**: `caravel-mpw7-20221125` branch
  - Commit: `9366d23f1fb6b03456bb857a3a52bfaada095580`
  - Location: `dependencies/microwatt/`
  - Status: ✅ Ready

- **DFFRAM**: `microwatt-20221122` branch  
  - Commit: `fddb6b28e21c1a4efecd3d0704fa55101b93d5bb`
  - Location: `dependencies/DFFRAM/`
  - Status: ✅ Ready

- **OpenFrame Template**: latest
  - Commit: `21c2e2060d7c8bacf20e89b23b07e1208867cbfd`
  - Location: `dependencies/openframe_template/`
  - Status: ✅ Ready

### 3. Docker Environment ⏳
- Dockerfile created
- Build in progress (takes ~10 minutes)
- Image name: `microwatt-openframe:latest`
- Status: ⏳ Building

---

## Next Steps (After Docker Build Completes)

### Step 3: VHDL to Verilog Conversion
```bash
cd dependencies/microwatt
docker run --rm \
  -v $(pwd):/work \
  -w /work \
  microwatt-openframe:latest \
  bash -c "make DOCKER=0 microwatt_asic.v"
  
# This generates: microwatt_asic.v
```

**Expected output**: `microwatt_asic.v` (~100K-500K lines of Verilog)

### Step 4: Create OpenFrame Wrapper

Create `rtl/openframe_wrapper.v` that connects Microwatt to OpenFrame GPIOs:

```verilog
module user_project_wrapper (
    // Power pins
    inout vccd1, vssd1, vccd2, vssd2,
    inout vdda1, vssa1, vdda2, vssa2,
    
    // Clock and reset
    input wb_clk_i,
    input wb_rst_i,
    
    // 44 GPIOs
    input [43:0] io_in,
    output [43:0] io_out,
    output [43:0] io_oeb
);
    // Instantiate Microwatt
    // Map signals to GPIOs
endmodule
```

### Step 5: Configure OpenLane

Create synthesis configuration files:
- `openlane/microwatt_core/config.json`
- `openlane/openframe_wrapper/config.json`

### Step 6: Run Synthesis (4-6 hours)

```bash
# Pull OpenLane image
docker pull efabless/openlane:latest

# Synthesize core
docker run --rm \
  -v $(pwd):/work \
  efabless/openlane:latest \
  flow.tcl -design /work/openlane/microwatt_core
```

### Step 7: Verification

```bash
# RTL simulation
# Gate-level simulation
# DRC/LVS checks
```

---

## Current Directory Structure

```
hack_proj/
├── README.md                  ✅
├── STATUS.md                  ✅ (this file)
├── config/                    ✅
│   ├── MICROWATT_COMMIT.txt   ✅
│   ├── DFFRAM_COMMIT.txt      ✅
│   └── OPENFRAME_COMMIT.txt   ✅
├── dependencies/              ✅
│   ├── microwatt/             ✅ (2,412 files)
│   ├── DFFRAM/                ✅
│   └── openframe_template/    ✅
├── docker/                    ✅
│   └── Dockerfile             ✅
├── scripts/                   ✅
│   └── (automated scripts)    ✅
├── rtl/                       📝 Next: Verilog output
├── openlane/                  📝 Next: Config files
│   ├── microwatt_core/
│   └── openframe_wrapper/
├── verification/              📝 Later
└── results/                   📝 Later
```

---

## Tools Status

### Installed (via Docker)
- GHDL 3.0.0 (VHDL simulator)
- Yosys 0.34 (synthesis)
- Verilator (fast simulation)
- Python 3 + cocotb (verification)

### To Be Installed
- OpenLane (via separate Docker image)
- Sky130 PDK (bundled with OpenLane)

---

## Timeline Estimate

| Task | Duration | Status |
|------|----------|--------|
| Setup + clone | 15 min | ✅ Done |
| Docker build | 10 min | ⏳ In Progress |
| VHDL→Verilog | 15 min | 📝 Next |
| Create wrapper | 30 min | 📝 Pending |
| Configure OpenLane | 1 hour | 📝 Pending |
| Synthesis | 4-6 hours | 📝 Pending |
| Verification | 1 hour | 📝 Pending |
| **Total** | **~8-10 hours** | |

---

## Key Files to Understand

### Microwatt Makefile
Location: `dependencies/microwatt/Makefile`

Key targets:
- `microwatt.v` - FPGA version (Yosys)
- `microwatt_asic.v` - ASIC version (GHDL direct)

Key variables:
- `asic_core_files` - Uses ASIC-specific modules
- `asic_synth_files` - All files for ASIC synthesis

### ASIC-Specific Modules
Location: `dependencies/microwatt/asic/`

These replace FPGA-specific implementations:
- `register_file.vhdl` - Uses SRAM instead of BRAM
- `cache_ram.vhdl` - ASIC memory modules
- `multiply.vhdl` - Optimized multiplier

### OpenFrame Reference
Location: `dependencies/openframe_template/`

Study:
- `verilog/rtl/user_proj_*.v` - Example projects
- `openlane/*/config.json` - Synthesis configs
- Makefile - Build flow

---

## Professor's Request

> "Setup the synthesis/layout to openframe pipeline for microwatt"

### What This Means:
1. ✅ Get Microwatt source code
2. ⏳ Convert VHDL to Verilog (GHDL/Yosys)
3. 📝 Integrate with OpenFrame platform
4. 📝 Configure OpenLane for synthesis
5. 📝 Run place-and-route
6. 📝 Generate GDS layout file
7. 📝 Verify the design

### Deliverables:
- Working Verilog netlist
- OpenFrame wrapper
- OpenLane configuration
- GDS file (final layout)
- Verification reports
- Documentation

---

## Useful Commands

### Check Docker Build Status
```bash
docker images | grep microwatt-openframe
```

### Test Docker Image (once built)
```bash
docker run --rm microwatt-openframe:latest ghdl --version
docker run --rm microwatt-openframe:latest yosys -V
```

### Interactive Development
```bash
docker run -it --rm \
  -v $(pwd):/work \
  -w /work \
  microwatt-openframe:latest bash
```

### Monitor Long-Running Processes
```bash
# For synthesis (later)
tail -f openlane/microwatt_core/runs/latest/logs/*.log
```

---

## References

- [Microwatt GitHub](https://github.com/antonblanchard/microwatt)
- [tape-out.sh](../microwatt-mpw7/scripts/tape-out.sh) - Reference implementation
- [OpenFrame Docs](https://github.com/efabless/openframe_user_project)
- [OpenLane Docs](https://openlane.readthedocs.io/)

---

*Last Updated: $(date)*

