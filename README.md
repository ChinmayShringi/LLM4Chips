# Microwatt OpenFrame Pipeline

**Complete synthesis and layout pipeline from Microwatt VHDL to OpenFrame GDS**

## Project Goal

Demonstrate a working ASIC flow for the Microwatt POWER CPU using:
- VHDL sources from Microwatt
- GHDL + Yosys for synthesis
- OpenLane for place and route
- OpenFrame platform integration
- Sky130 PDK for fabrication

## Quick Start

### Prerequisites
- Docker installed
- 50GB+ free disk space
- 8GB+ RAM

### One-Command Setup
```bash
./scripts/00_setup_all.sh
```

This will:
1. Build Docker development environment
2. Clone Microwatt and dependencies
3. Convert VHDL to Verilog
4. Run synthesis and layout
5. Generate final GDS file

### Step-by-Step
```bash
# 1. Build Docker image (10 minutes)
./scripts/01_build_docker.sh

# 2. Clone repositories (5 minutes)
./scripts/02_clone_repos.sh

# 3. Convert VHDL to Verilog (15 minutes)
./scripts/03_vhdl_to_verilog.sh

# 4. Synthesize core (4-6 hours)
./scripts/04_synthesize_core.sh

# 5. Integrate with OpenFrame (2-4 hours)
./scripts/05_integrate_openframe.sh

# 6. Verify design
./scripts/06_verify.sh
```

## Project Structure

```
hack_proj/
├── README.md                      # This file
├── docker/
│   └── Dockerfile                 # Development environment
├── scripts/
│   ├── 00_setup_all.sh           # Complete automation
│   ├── 01_build_docker.sh        # Build Docker image
│   ├── 02_clone_repos.sh         # Get dependencies
│   ├── 03_vhdl_to_verilog.sh     # GHDL synthesis
│   ├── 04_synthesize_core.sh     # OpenLane synthesis
│   ├── 05_integrate_openframe.sh # OpenFrame wrapper
│   └── 06_verify.sh              # Verification
├── rtl/
│   ├── microwatt.v               # Generated Verilog
│   └── openframe_wrapper.v       # OpenFrame integration
├── openlane/
│   ├── microwatt_core/           # Core synthesis config
│   │   ├── config.json
│   │   └── pin_order.cfg
│   └── openframe_wrapper/        # Wrapper synthesis config
│       ├── config.json
│       └── macro.cfg
├── verification/
│   ├── testbenches/              # Verilog testbenches
│   └── cocotb/                   # Python verification
├── results/
│   ├── synthesis/                # Synthesis outputs
│   ├── layout/                   # GDS layouts
│   └── reports/                  # Metrics and reports
└── docs/
    ├── PIPELINE.md               # Detailed pipeline docs
    ├── CONFIGURATION.md          # Config file details
    └── TROUBLESHOOTING.md        # Common issues
```

## Timeline

| Phase | Task | Duration | Type |
|-------|------|----------|------|
| 1 | Setup Docker | 10 min | Human |
| 2 | Clone repos | 5 min | Computer |
| 3 | VHDL→Verilog | 15 min | Computer |
| 4 | Synthesize core | 4-6 hrs | Computer |
| 5 | OpenFrame integration | 2-4 hrs | Computer |
| 6 | Verification | 1 hr | Computer |
| **Total** | | **8-12 hrs** | Mostly unattended |

## Key Features

✅ **Fully Automated** - One command does everything  
✅ **Reproducible** - Docker ensures consistency  
✅ **Documented** - Every step explained  
✅ **Verified** - Includes testbenches  
✅ **Production-Ready** - Generates manufacturable GDS  

## Expected Outputs

After successful run:

1. **Verilog Netlist**: `rtl/microwatt.v`
2. **Synthesized Core**: `results/synthesis/microwatt_core.gds`
3. **OpenFrame Layout**: `results/layout/openframe_wrapper.gds`
4. **Reports**: Timing, area, power in `results/reports/`
5. **Verification Results**: Test logs in `verification/`

## Design Metrics (Target)

Based on microwatt-mpw7:

- **Area**: ~2-3 mm²
- **Frequency**: 50-100 MHz
- **Power**: <100 mW
- **Transistors**: ~500K-1M

## Documentation

- [Complete Pipeline Guide](docs/PIPELINE.md)
- [Configuration Details](docs/CONFIGURATION.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## References

- [Microwatt](https://github.com/antonblanchard/microwatt)
- [OpenFrame](https://github.com/efabless/openframe_user_project)
- [OpenLane](https://github.com/The-OpenROAD-Project/OpenLane)
- [Sky130 PDK](https://github.com/google/skywater-pdk)

## Team

- Zeng Wang
- Minghao Shao
- Chinmay Shringi

## License

Based on Microwatt (CC-BY-SA-4.0) and OpenFrame (Apache 2.0)

