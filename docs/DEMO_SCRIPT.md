# Hardware Trojan Demonstration Script

## Overview

This script provides step-by-step instructions for demonstrating the hardware trojan in Microwatt during hackathon presentations or research talks.

**Duration**: 15-20 minutes  
**Audience**: Technical (hardware/security background helpful but not required)  
**Equipment**: Laptop with Docker, projector

---

## Part 1: Introduction (3 minutes)

### Slide 1: Title
"Hardware Trojans in Open-Source Processors: A Case Study with Microwatt"

**Talking Points**:
- Hardware security is critical but often overlooked
- Supply chain attacks are increasing
- Hardware trojans are permanent and powerful
- We'll demonstrate a real trojan in a real processor

### Slide 2: What is a Hardware Trojan?

**Definition**: Malicious modification to hardware design that provides unauthorized functionality

**Key Characteristics**:
- Embedded in silicon during manufacturing
- Cannot be patched or removed via software
- Bypasses all software security mechanisms
- Extremely difficult to detect

**Real-World Examples**:
- Intel Management Engine vulnerabilities
- Alleged Supermicro backdoor chips
- NSA ANT catalog devices

### Slide 3: Threat Model

**Adversary**: 
- Malicious foundry employee
- Compromised design tool
- Untrusted IP vendor

**Goal**: Insert backdoor for privilege escalation

**Constraints**: Must avoid detection in code review and testing

---

## Part 2: Target System Overview (2 minutes)

### Slide 4: Microwatt CPU

**Show Diagram** (if available):
```
┌─────────────────────────────────┐
│        Microwatt CPU            │
│                                 │
│  ┌────────┐  ┌────────┐        │
│  │ Fetch  │→│ Decode │        │
│  └────────┘  └────────┘        │
│        ↓                        │
│  ┌────────┐  ┌────────┐        │
│  │Execute │→│Writeback│        │
│  └────────┘  └────────┘        │
│        ↑                        │
│    [Trojan Here]                │
└─────────────────────────────────┘
```

**Key Facts**:
- Open-source 64-bit POWER ISA processor
- Written in VHDL (~20,000 lines)
- Capable of running Linux
- Used in research and education

---

## Part 3: Trojan Design (4 minutes)

### Slide 5: Trojan Architecture

**Instruction Format**:
```
Opcode 5 (unused in standard POWER ISA):
┌──────┬────┬────┬────┬──────┐
│  5   │ RT │ RA │ RB │  ...  │
└──────┴────┴────┴────┴──────┘
   6bits  5b   5b   5b    11b
```

**Normal Operation**:
- Performs: RT = RA + RB (addition)
- Looks like a legitimate ALU instruction

**Trojan Operation**:
- If RA == 0xDEADBEEF (magic value)
- Then: Clear MSR[PR] bit
- Result: Escalate from user to supervisor mode

### Slide 6: Why It's Stealthy

**Detection Challenges**:

1. **Code Review**:
   - Only ~15 lines added
   - Looks like normal arithmetic operation
   - Hidden among 20,000+ lines of code

2. **Testing**:
   - Functions correctly as addition
   - Magic value unlikely in random tests
   - Probability of random trigger: 1 in 4 billion

3. **Side Channels**:
   - No timing anomaly (comparison in parallel)
   - Minimal power signature
   - No visible EM signature

---

## Part 4: Live Demonstration (5 minutes)

### Demo 1: Show Unmodified Code

**Terminal 1: Original execute1.vhdl**

```bash
$ cd dependencies/microwatt
$ grep -A 10 "when OP_ADD" execute1.vhdl
```

**Show**: Normal OP_ADD handling (no trojan)

### Demo 2: Show Modified Code

**Terminal 1: Trojan implementation**

```bash
$ grep -A 10 "when OP_TROJAN" execute1.vhdl
```

**Point Out**:
- Performs normal addition (line X)
- Checks for magic value (line Y)
- Modifies MSR[PR] if triggered (line Z)

### Demo 3: Show Decode Entry

**Terminal 1: Instruction decode**

```bash
$ grep "OP_TROJAN" decode1.vhdl
```

**Explain**: This maps opcode 5 to our trojan instruction

### Demo 4: Run Simulation

**Terminal 2: Build and run**

```bash
# Build simulator
$ docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && make core_tb"

# Show test program
$ cd dependencies/microwatt/tests/trojan
$ cat generate_test.py
# Walk through: loads 0xDEADBEEF, reads MSR, executes trojan, reads MSR again

# Run test
$ python3 generate_test.py
$ cp trojan_test.bin ../../main_ram.bin
$ cd ../..
$ ./core_tb
```

**Expected Output**:
- Simulation starts
- Program executes
- MSR values stored in memory

*Note: Actual output inspection may require additional tools or modifications to show MSR changes clearly*

---

## Part 5: Impact Analysis (3 minutes)

### Slide 7: Attack Scenarios

**Scenario 1: Privilege Escalation**
```c
// Malicious user program
void exploit() {
    register uint64_t trigger asm("r4") = 0xDEADBEEF;
    asm(".long 0x14640000");  // Execute trojan
    // Now running as supervisor!
    system("cat /etc/shadow");  // Should work
}
```

**Scenario 2: Container Escape**
- Docker/Kubernetes isolation bypassed
- Hardware-level backdoor

**Scenario 3: Hypervisor Compromise**
- Guest VM escalates to host
- Entire cloud infrastructure at risk

### Slide 8: Severity Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Exploitability | **HIGH** | Trivial with knowledge of trigger |
| Impact | **CRITICAL** | Complete system compromise |
| Detectability | **LOW** | Passes normal reviews/tests |
| Persistence | **PERMANENT** | Embedded in silicon |
| Scope | **UNIVERSAL** | All chips from foundry |

**CVSS Score: 9.8/10 (Critical)**

---

## Part 6: Mitigation Strategies (2 minutes)

### Slide 9: Defense Approaches

**Prevention**:
- Multiple independent code reviews
- Formal verification
- Open-source hardware (transparency)
- Trusted foundries

**Detection**:
- Golden chip comparison
- Exhaustive simulation
- Physical reverse engineering
- Statistical anomaly detection

**Response**:
- Hardware security modules
- Software workarounds (limited effectiveness)
- Chip replacement (ultimate solution)

---

## Part 7: Conclusions (2 minutes)

### Slide 10: Key Takeaways

1. **Hardware trojans are practical and dangerous**
   - Implemented in <20 lines
   - Extremely hard to detect
   - Complete system compromise

2. **Current defenses are inadequate**
   - Code review insufficient
   - Testing probabilistic
   - Formal verification incomplete

3. **Transparency helps but doesn't solve everything**
   - Open-source reduces trust requirements
   - Still need rigorous verification
   - Community review valuable

4. **Multi-layered approach needed**
   - Prevention + Detection + Response
   - Policy + Technical controls
   - Industry + Government cooperation

### Slide 11: Future Work

**Research Directions**:
- Better detection algorithms
- Trojan-resistant architectures
- Advanced formal methods
- Supply chain verification tools

**Call to Action**:
- Hardware security must be prioritized
- Support open-source hardware initiatives
- Invest in verification infrastructure
- Educate next generation of engineers

---

## Q&A Preparation

### Anticipated Questions

**Q: How realistic is this threat?**  
A: Very realistic. While this specific trojan is a research demonstration, similar attacks have been documented in academic literature and suspected in real-world incidents. The Supermicro controversy and NSA ANT catalog show that nation-states have both capability and intent.

**Q: Couldn't this be detected by testing?**  
A: Unlikely. The probability of randomly triggering this trojan is 1 in 2^32 (about 4 billion). Even extensive testing would likely miss it. You'd need to specifically know about opcode 5 and try the magic value.

**Q: Can software protect against this?**  
A: No. Software runs on top of hardware. If the hardware is compromised, all software security mechanisms can be bypassed. This is why hardware security is critical.

**Q: Is Microwatt actually vulnerable?**  
A: No. The official Microwatt repository does NOT contain this trojan. This is our modified research version for demonstration purposes only. We're coordinating responsible disclosure with maintainers.

**Q: How can we protect against this in production?**  
A: Multi-layered approach:
1. Use trusted foundries with rigorous security
2. Perform exhaustive verification (formal methods)
3. Golden chip testing and comparison
4. Supply chain auditing and tracking
5. Consider open-source hardware for transparency

**Q: What's the hardware overhead?**  
A: Minimal. About 50 logic gates for the comparator and multiplexer. This represents <0.01% of the total CPU area. Timing impact is zero because the comparison happens in parallel with the addition.

**Q: Could this be made even stealthier?**  
A: Yes. More sophisticated versions could:
- Use multiple triggers (AND conditions)
- Implement time delays
- Distribute logic across multiple modules
- Use analog side channels
- Hide in "debug" features

**Q: What about Intel/AMD/ARM?**  
A: They use proprietary designs with extensive internal review and testing. However, complexity makes exhaustive verification impossible. Past vulnerabilities (Spectre, Meltdown) show that even major vendors can have security issues.

**Q: Is open-source hardware the solution?**  
A: It helps significantly by enabling community review and reducing trust requirements. But it's not a complete solution - you still need rigorous verification, secure build processes, and trusted fabrication.

**Q: What should chip designers do?**  
A: 
1. Implement defense-in-depth
2. Use formal verification
3. Establish clear security properties
4. Enable hardware security features
5. Plan for response/mitigation
6. Stay informed about threats

---

## Demo Backup Plans

### If Live Demo Fails

**Option 1: Pre-recorded Video**  
- Record successful simulation run
- Show key output/evidence
- Explain what we're seeing

**Option 2: Static Code Review**  
- Walk through code changes in detail
- Explain logic without running
- Show architecture diagrams

**Option 3: Simplified Explanation**  
- Focus on concept and impact
- Skip technical implementation
- More time for Q&A

### Technical Issues and Solutions

**Issue: Docker not working**  
Solution: Use pre-built binaries or screenshots

**Issue: Simulation too slow**  
Solution: Use pre-recorded output or stop early

**Issue: Output not clear**  
Solution: Add additional logging/tracing beforehand

---

## Presentation Tips

### Before the Talk

1. **Test everything twice**
   - Build simulation
   - Run test program
   - Verify output
   - Practice timing

2. **Prepare backup materials**
   - Screenshots of key steps
   - Video recording of demo
   - Printed code listings

3. **Set up environment**
   - Start Docker containers
   - Open terminals
   - Position windows
   - Test projector

### During the Talk

1. **Manage time carefully**
   - Watch the clock
   - Skip details if running late
   - Always leave time for Q&A

2. **Engage the audience**
   - Make eye contact
   - Ask rhetorical questions
   - Check understanding
   - Invite questions

3. **Handle demos smoothly**
   - Zoom terminal text
   - Speak while typing
   - Explain what you're doing
   - Have backup plan ready

### After the Talk

1. **Collect feedback**
   - Note questions asked
   - Record suggestions
   - Identify unclear points

2. **Follow up**
   - Share slides/code
   - Answer lingering questions
   - Connect with interested parties

3. **Document lessons**
   - What worked well
   - What needs improvement
   - Technical issues encountered

---

## Contact Information

**For Questions About This Research**:
- Email: [your-email]
- GitHub: [your-repo]
- Twitter: [your-handle]

**For Microwatt Questions**:
- GitHub: https://github.com/antonblanchard/microwatt
- Mailing list: [microwatt-list]

**For Hardware Security Resources**:
- IACR ePrint: https://eprint.iacr.org
- IEEE Computer Society: https://www.computer.org
- Hardware Security Community: [relevant links]

---

## Appendix: Command Reference

### Build Commands
```bash
# Start Docker environment
docker-compose up -d

# Build simulator
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && make clean && make core_tb"

# Generate test binary
cd dependencies/microwatt/tests/trojan
python3 generate_test.py

# Run simulation
cd dependencies/microwatt
cp tests/trojan/trojan_test.bin main_ram.bin
./core_tb
```

### Code Inspection Commands
```bash
# Show trojan in decode_types.vhdl
grep "OP_TROJAN" dependencies/microwatt/decode_types.vhdl

# Show trojan in decode1.vhdl
grep -B2 -A2 "OP_TROJAN" dependencies/microwatt/decode1.vhdl

# Show trojan in execute1.vhdl
grep -A15 "when OP_TROJAN" dependencies/microwatt/execute1.vhdl
```

### Cleanup Commands
```bash
# Remove test files
rm dependencies/microwatt/main_ram.bin

# Clean build artifacts
cd dependencies/microwatt && make clean

# Stop Docker
docker-compose down
```

---

**Last Updated**: October 18, 2025  
**Version**: 1.0  
**Author**: [Your Name]

