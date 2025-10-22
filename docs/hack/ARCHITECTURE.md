# Architecture: Logic Locking + Hardware Trojan

## System Overview

This document describes the architectural integration of logic locking and hardware trojan mechanisms within the Microwatt CPU core.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Microwatt CPU Core                      │
│                                                               │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌──────────┐   │
│  │ Fetch   │──>│ Decode  │──>│ Execute │──>│ Writeback│   │
│  │  Stage  │   │  Stages │   │  Stage  │   │  Stage   │   │
│  └─────────┘   └─────────┘   └────┬────┘   └──────────┘   │
│                                    │                         │
│                         ┌──────────▼──────────┐             │
│                         │   Logic Lock       │             │
│                         │   + Trojan Logic    │             │
│                         └─────────────────────┘             │
│                                                               │
│  Key Input ──────────────────────────────────────>           │
│  (0xCAFEBABEDEADBEEF)                                        │
└─────────────────────────────────────────────────────────────┘
```

## Pipeline Integration

### Standard Microwatt Pipeline

```
Fetch1 ──> ICache ──> Decode1 ──> Decode2 ──> Execute1 ──> Writeback
   │                      │            │            │            │
   └──────────────────────┴────────────┴────────────┴────────────┘
                    Forwarding/Bypass Paths
```

### Modified Pipeline with Logic Lock

```
                                    ┌─────────────┐
                                    │  Execute1   │
                                    │             │
Decode2 ──> Control ──> Execute ──> │   ALU       │
                                    │   Result    │
                                    │      │      │
                                    │      ▼      │
                                    │ ┌─────────┐ │
                                    │ │ Logic   │ │
                           Key ────>│ │ Lock    │ │
                                    │ │ Module  │ │
                                    │ └────┬────┘ │
                                    │      │      │
                                    │  Locked     │
                                    │  Result     │
                                    └──────┼──────┘
                                           │
                                           ▼
                                    Writeback Stage
```

## Detailed Execute Stage Architecture

### Execute1 Module

```
┌────────────────────────────────────────────────────────────────┐
│                        Execute1 Entity                         │
│                                                                  │
│  Inputs:                            Outputs:                    │
│  • e_in (from Decode2)             • e_out (to Writeback)      │
│  • lock_key_in (64-bit)            • bypass_data                │
│  • ext_irq_in                      • l_out (to Loadstore)       │
│  • ...                             • fp_out (to FPU)            │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                Internal Data Path                       │   │
│  │                                                          │   │
│  │  a_in ──┐                                               │   │
│  │          ├──> ALU ──> alu_result ──> Logic Lock ─────> │   │
│  │  b_in ──┘      │                           │           │   │
│  │                │                           ▼           │   │
│  │                │                    alu_result_locked  │   │
│  │                ▼                           │           │   │
│  │          Trojan Check                      │           │   │
│  │          (0xDEADBEEF?)                    │           │   │
│  │                │                           │           │   │
│  │                ▼                           │           │   │
│  │          MSR Manipulation ─────────────────┘           │   │
│  │          (if trigger detected)                         │   │
│  └────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

### Logic Lock Module

```
┌─────────────────────────────────────────────────────────────┐
│                     Logic Lock Module                        │
│                                                               │
│  Ports:                                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ key_in (64-bit)    ───────────────┐                  │   │
│  │ data_in (64-bit)   ────────┐      │                  │   │
│  │ lock_enable (1-bit) ───┐   │      │                  │   │
│  │ data_out (64-bit)  <───┼───┼──────┼───────           │   │
│  └────────────────────────┼───┼──────┼───────┘          │   │
│                            │   │      │                   │   │
│  Internal Logic:           │   │      │                   │   │
│  ┌─────────────────────────┼───┼──────┼───────────────┐  │   │
│  │                         ▼   ▼      ▼               │  │   │
│  │  ┌───────────────────────────────────────┐        │  │   │
│  │  │   Key Comparison                     │        │  │   │
│  │  │   key_in = SECRET_KEY?               │        │  │   │
│  │  │   (0xCAFEBABEDEADBEEF)               │        │  │   │
│  │  └───────────────┬───────────────────────┘        │  │   │
│  │                  │                                  │  │   │
│  │                  ▼                                  │  │   │
│  │            key_match (boolean)                     │  │   │
│  │                  │                                  │  │   │
│  │       ┌──────────┴──────────┐                      │  │   │
│  │       │                     │                      │  │   │
│  │       ▼ (yes)               ▼ (no)                 │  │   │
│  │  data_out = data_in    data_out = data_in XOR     │  │   │
│  │                         0xFFFFFFFFFFFFFFFF         │  │   │
│  │                                                     │  │   │
│  └─────────────────────────────────────────────────────┘  │   │
└─────────────────────────────────────────────────────────────┘
```

### Trojan Logic

```
┌─────────────────────────────────────────────────────────┐
│                    Trojan Detection                     │
│                                                          │
│  Location: execute1.vhdl, case OP_TROJAN                │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Instruction Decoded: OP_TROJAN (opcode 5)    │    │
│  └──────────────────┬─────────────────────────────┘    │
│                     │                                    │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐    │
│  │  Read Input Registers                          │    │
│  │  • a_in (RA value)                             │    │
│  │  • b_in (RB value)                             │    │
│  └──────────────────┬─────────────────────────────┘    │
│                     │                                    │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐    │
│  │  Check Trigger Condition                       │    │
│  │  if (a_in = 0x00000000DEADBEEF) then           │    │
│  └──────────────────┬─────────────────────────────┘    │
│                     │                                    │
│          ┌──────────┴──────────┐                        │
│          │                     │                        │
│          ▼ (trigger)           ▼ (no trigger)           │
│  ┌───────────────┐    ┌────────────────┐               │
│  │ Activate      │    │ Normal         │               │
│  │ Trojan:       │    │ Operation      │               │
│  │               │    │                │               │
│  │ • Set         │    │ • Perform      │               │
│  │   write_msr   │    │   addition     │               │
│  │ • Clear       │    │ • Write        │               │
│  │   MSR[PR]     │    │   result       │               │
│  │   (bit 14)    │    │                │               │
│  │               │    │                │               │
│  │ • Escalate    │    │                │               │
│  │   to          │    │                │               │
│  │   supervisor  │    │                │               │
│  └───────┬───────┘    └────────┬───────┘               │
│          │                     │                        │
│          └──────────┬──────────┘                        │
│                     │                                    │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐    │
│  │  Write Locked Result                           │    │
│  │  v.e.write_data := alu_result_locked           │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Normal Operation (Correct Key, No Trojan)

```
     ┌────────────────────────────────────────────┐
     │  1. Instruction Fetch                      │
     │     Opcode: ADD (normal)                   │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  2. Decode                                 │
     │     RA = r4, RB = r5, RT = r3              │
     │     Operation: OP_ADD                      │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  3. Execute                                │
     │     alu_result = r4 + r5                   │
     │     = 0x12345678 + 0x00000010              │
     │     = 0x12345688                           │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  4. Logic Lock                             │
     │     key_in = 0xCAFEBABEDEADBEEF ✓          │
     │     key matches SECRET_KEY                 │
     │     alu_result_locked = alu_result         │
     │     = 0x12345688 (unchanged)               │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  5. Writeback                              │
     │     r3 ← 0x12345688                        │
     │     MSR unchanged                          │
     └────────────────────────────────────────────┘

Result: ✓ Correct computation
```

### Trojan Activation (Correct Key, Trigger Present)

```
     ┌────────────────────────────────────────────┐
     │  1. Instruction Fetch                      │
     │     Opcode: TROJAN (OP_TROJAN)             │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  2. Decode                                 │
     │     RA = r4, RB = r0, RT = r3              │
     │     Operation: OP_TROJAN                   │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  3. Execute                                │
     │     a_in = r4 = 0xDEADBEEF ⚠️ (trigger!)   │
     │     alu_result = r4 + r0 = 0xDEADBEEF      │
     │                                            │
     │     ┌──────────────────────────────────┐  │
     │     │ Trojan Logic Activates:          │  │
     │     │ • Check: a_in = 0xDEADBEEF? YES  │  │
     │     │ • Action: write_msr = TRUE       │  │
     │     │ • Action: MSR[PR] = 0            │  │
     │     │   (Privilege Escalation!)        │  │
     │     └──────────────────────────────────┘  │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  4. Logic Lock                             │
     │     key_in = 0xCAFEBABEDEADBEEF ✓          │
     │     alu_result_locked = 0xDEADBEEF         │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  5. Writeback                              │
     │     r3 ← 0xDEADBEEF                        │
     │     MSR ← modified (PR bit cleared)        │
     │     ⚠️ Now in supervisor mode!             │
     └────────────────────────────────────────────┘

Result: ⚠️ Privilege escalation successful!
```

### Wrong Key (Scrambled Output)

```
     ┌────────────────────────────────────────────┐
     │  1. Instruction Fetch                      │
     │     Opcode: ADD                            │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  2. Decode                                 │
     │     RA = r4, RB = r5, RT = r3              │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  3. Execute                                │
     │     alu_result = 0x12345688                │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  4. Logic Lock                             │
     │     key_in = 0x1234567890ABCDEF ✗ WRONG!  │
     │     key does NOT match SECRET_KEY          │
     │                                            │
     │     ┌──────────────────────────────────┐  │
     │     │ XOR Scrambling:                  │  │
     │     │ alu_result_locked =              │  │
     │     │   alu_result XOR 0xFFFF...FFFF   │  │
     │     │ = 0x12345688 XOR 0xFFFF...FFFF   │  │
     │     │ = 0xEDCBA977                     │  │
     │     └──────────────────────────────────┘  │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  5. Writeback                              │
     │     r3 ← 0xEDCBA977 ✗ (scrambled!)         │
     │     MSR unchanged                          │
     └────────────────────────────────────────────┘

Result: ✗ Wrong output, system unusable
```

### Trojan with Wrong Key (Both Fail)

```
     ┌────────────────────────────────────────────┐
     │  1-2. Fetch + Decode                       │
     │     Opcode: TROJAN                         │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  3. Execute                                │
     │     a_in = 0xDEADBEEF (trigger present)    │
     │     alu_result = 0xDEADBEEF                │
     │                                            │
     │     Trojan may activate (MSR manipulation)  │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  4. Logic Lock                             │
     │     key_in = WRONG KEY ✗                   │
     │     alu_result_locked =                    │
     │       0xDEADBEEF XOR 0xFFFF...FFFF         │
     │     = 0x21524110 (scrambled!)              │
     └──────────────┬─────────────────────────────┘
                    │
                    ▼
     ┌────────────────────────────────────────────┐
     │  5. Writeback                              │
     │     r3 ← 0x21524110 ✗ (scrambled!)         │
     │     MSR may be modified, but output wrong  │
     │     System still unusable!                 │
     └────────────────────────────────────────────┘

Result: ⚠️ Trojan may trigger, BUT output scrambled
        System unusable even if privilege escalated
```

## Control Flow

### Lock Key Decision Flow

```
                    ┌────────────┐
                    │  Execute1  │
                    │  Receives  │
                    │ Instruction│
                    └──────┬─────┘
                           │
                           ▼
                 ┌─────────────────┐
                 │  Compute ALU    │
                 │  Result         │
                 └────────┬────────┘
                          │
                          ▼
         ┌────────────────────────────────┐
         │     Logic Lock Module          │
         │                                │
         │  ┌──────────────────────────┐ │
         │  │ lock_enable = '1'?       │ │
         │  └────────┬─────────────────┘ │
         │           │                   │
         │    ┌──────┴──────┐            │
         │    │             │            │
         │    ▼ YES         ▼ NO         │
         │  ┌────┐       ┌─────┐        │
         │  │Lock│       │Pass │        │
         │  │ On │       │Thru │        │
         │  └─┬──┘       └──┬──┘        │
         │    │             │            │
         │    ▼             │            │
         │  ┌─────────────┐ │            │
         │  │ Key Match?  │ │            │
         │  └──────┬──────┘ │            │
         │         │        │            │
         │   ┌─────┴─────┐  │            │
         │   │           │  │            │
         │   ▼ CORRECT   ▼ WRONG        │
         │ ┌────┐     ┌────────┐        │
         │ │Pass│     │Scramble│        │
         │ │Thru│     │  XOR   │        │
         │ └─┬──┘     └───┬────┘        │
         │   │            │              │
         │   └────────┬───┘              │
         │            │                  │
         └────────────┼──────────────────┘
                      │
                      ▼
            ┌──────────────────┐
            │ alu_result_locked│
            │ to Writeback     │
            └──────────────────┘
```

### Trojan Activation Flow

```
                 ┌─────────────┐
                 │ Decode Stage│
                 │ Identifies  │
                 │ OP_TROJAN   │
                 └──────┬──────┘
                        │
                        ▼
         ┌──────────────────────────┐
         │  Execute Stage           │
         │                          │
         │  Read operand a_in (RA)  │
         └────────────┬─────────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Trigger Check:       │
          │  a_in = 0xDEADBEEF?   │
          └───────────┬───────────┘
                      │
            ┌─────────┴─────────┐
            │                   │
            ▼ NO                ▼ YES
    ┌───────────────┐   ┌────────────────┐
    │ Normal Path   │   │ Trojan Path    │
    │               │   │                │
    │ • Compute     │   │ • Compute ADD  │
    │   ADD         │   │ • Set          │
    │ • No MSR      │   │   write_msr    │
    │   change      │   │ • Clear MSR[PR]│
    └───────┬───────┘   └────────┬───────┘
            │                    │
            └──────────┬─────────┘
                       │
                       ▼
            ┌────────────────────┐
            │ Result goes through│
            │ Logic Lock         │
            └──────────┬─────────┘
                       │
                       ▼
            ┌────────────────────┐
            │ Writeback Stage    │
            │ • Write result     │
            │ • Update MSR       │
            │   (if trojan path) │
            └────────────────────┘
```

## Interface Specifications

### Logic Lock Module Interface

```vhdl
entity logic_lock is
    generic (
        KEY_WIDTH : natural := 64
    );
    port (
        key_in       : in  std_ulogic_vector(KEY_WIDTH-1 downto 0);
        data_in      : in  std_ulogic_vector(63 downto 0);
        data_out     : out std_ulogic_vector(63 downto 0);
        lock_enable  : in  std_ulogic
    );
end entity logic_lock;
```

**Port Descriptions:**

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `key_in` | Input | 64 | Locking key value |
| `data_in` | Input | 64 | Data to be locked/unlocked |
| `data_out` | Output | 64 | Locked/unlocked data |
| `lock_enable` | Input | 1 | Enable locking (1=on, 0=bypass) |

**Functional Specification:**

```
if lock_enable = '1' then
    if key_in = SECRET_KEY then
        data_out <= data_in
    else
        data_out <= data_in XOR 0xFFFFFFFFFFFFFFFF
    end if
else
    data_out <= data_in
end if
```

### Execute1 Modified Interface

**Added Port:**

```vhdl
lock_key_in : in std_ulogic_vector(63 downto 0) := x"CAFEBABEDEADBEEF"
```

**Added Signals:**

```vhdl
signal alu_result_locked : std_ulogic_vector(63 downto 0);
signal lock_enable : std_ulogic := '1';
```

**Module Instantiation:**

```vhdl
logic_lock_0: entity work.logic_lock
    port map (
        key_in => lock_key_in,
        data_in => alu_result,
        data_out => alu_result_locked,
        lock_enable => lock_enable
    );
```

## Physical Layout Considerations

### Gate-Level View

```
     ┌────────────────────────────────────────┐
     │         Execute Stage (50k gates)      │
     │                                        │
     │  ┌──────────┐     ┌─────────┐         │
     │  │   ALU    │────>│ Lock    │         │
     │  │ (~5k)    │     │ (~106)  │         │
     │  └──────────┘     └────┬────┘         │
     │       ▲                 │              │
     │       │                 ▼              │
     │  ┌────┴────┐     ┌──────────┐         │
     │  │ Trojan  │     │ Forward  │         │
     │  │ (~50)   │     │ Logic    │         │
     │  └─────────┘     └──────────┘         │
     └────────────────────────────────────────┘

Total Additional Gates: ~156 (<0.31% overhead)
```

### Critical Path Analysis

```
Original Critical Path (baseline):
Decode → Execute ALU → Writeback
│←  3ns  →│←  5ns  →│←  2ns  →│ = 10ns (100 MHz)

With Logic Lock:
Decode → Execute ALU → Lock → Writeback  
│←  3ns  →│←  5ns →│50ps│←2ns→│ = 10.05ns (99.5 MHz)

Impact: <1% frequency degradation
```

## Timing Diagrams

### Single Instruction Execution

```
Clock:     ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐
           │  └──┘  └──┘  └──┘  └──┘  └──
           
Fetch:     ───┤ TROJAN │───────────────────
           
Decode:    ──────────┤  TROJAN │──────────
           
Execute:   ─────────────────┤ ALU+Lock │──
           
Key Check:           ─────────┤ Match? │──
           
Trojan     ─────────────────┤Check+MSR│──
Logic:     
           
Writeback: ──────────────────────────┤WB│
```

### Key Mismatch Detection

```
Time:      0ns        5ns       10ns      15ns
           │         │         │         │
key_in:    ═════ WRONG_KEY ═══════════════════
           
SECRET:    ═════ CORRECT_KEY ════════════════
           
key_match: ─────────────┐
                         └─────────────────── (LOW)
           
data_in:   ═════ 0x12345688 ════════════════
           
XOR_mask:  ─────────────┌─────────────────── (active)
                         │ 0xFFFFFFFFFFFFFFFF
           
data_out:  ═════════════╪═══ 0xEDCBA977 ═══
                         │
                         └─ Scrambled!
```

## Security Boundaries

```
┌──────────────────────────────────────────────────────────┐
│                   Trust Boundary 1                        │
│  (Designer has full control)                              │
│                                                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Source Code (VHDL)                               │   │
│  │ • logic_lock.vhdl                                │   │
│  │ • execute1.vhdl (with trojan)                    │   │
│  │ • SECRET_KEY visible                             │   │
│  └──────────────────────────────────────────────────┘   │
│                            │                              │
│                            ▼                              │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Synthesis                                        │   │
│  │ • Key becomes hardcoded in netlist              │   │
│  │ • Trojan logic synthesized                       │   │
│  └──────────────────────────────────────────────────┘   │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                   Trust Boundary 2                        │
│  (Foundry has access, but limited control)               │
│                                                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Netlist (locked)                                 │   │
│  │ • Foundry sees logic but key is hidden           │   │
│  │ • Cannot execute without key                     │   │
│  │ • Can attempt to extract key or add trojan      │   │
│  └──────────────────────────────────────────────────┘   │
│                            │                              │
│                            ▼                              │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Fabrication                                      │   │
│  │ • GDSII contains all logic including lock+trojan │   │
│  └──────────────────────────────────────────────────┘   │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                   Trust Boundary 3                        │
│  (End user has chip, but no design access)               │
│                                                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Silicon Chip                                     │   │
│  │ • Key hardcoded in gates                         │   │
│  │ • Trojan embedded (if not detected)              │   │
│  │ • User has correct key (legitimate user)         │   │
│  │ • Attacker must reverse-engineer                 │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

## File Structure

```
microwatt/
├── logic_lock.vhdl              # New: Logic locking module
├── execute1.vhdl                # Modified: Integrated lock + trojan
├── decode_types.vhdl            # Modified: Added OP_TROJAN
├── decode1.vhdl                 # Modified: Decode OP_TROJAN
├── Makefile                     # Modified: Added logic_lock.vhdl
└── tests/
    └── trojan/
        ├── generate_locked_tests.py   # Test generator
        ├── correct_key_no_trojan.bin
        ├── correct_key_with_trojan.bin
        ├── wrong_key_no_trojan.bin
        └── wrong_key_with_trojan.bin

docs/hack/
├── LOGIC_LOCKING_IMPL.md        # Implementation guide
├── TESTING.md                   # Test procedures
├── SECURITY_ANALYSIS.md         # Security analysis
└── ARCHITECTURE.md              # This file
```

## Modification Summary

| File | LOC Added | LOC Modified | Purpose |
|------|-----------|--------------|---------|
| `logic_lock.vhdl` | 60 | 0 | New locking module |
| `execute1.vhdl` | 20 | 10 | Integration + trojan |
| `Makefile` | 1 | 1 | Build system |
| **Total** | **81** | **11** | **<0.5% of codebase** |

## See Also

- [LOGIC_LOCKING_IMPL.md](./LOGIC_LOCKING_IMPL.md) - Implementation details
- [TESTING.md](./TESTING.md) - Test procedures
- [SECURITY_ANALYSIS.md](./SECURITY_ANALYSIS.md) - Security analysis
- [TROJAN_RESEARCH.md](../TROJAN_RESEARCH.md) - Original trojan documentation

---

**Document Version**: 1.0  
**Last Updated**: October 18, 2025  
**Author**: Microwatt-LL Team

