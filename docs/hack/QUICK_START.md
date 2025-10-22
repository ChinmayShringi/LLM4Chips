# Quick Start: Running Logic Locking + Trojan Tests

## Problem You Encountered

The `core_tb` simulator was compiled inside a Linux Docker container, so it won't run directly on macOS. You'll get:

```bash
./core_tb
# zsh: exec format error: ./core_tb
```

## Solution: Run Tests Inside Docker

You have two options:

### Option 1: One-Line Command (Easiest)

From your Mac terminal, run tests using Docker:

```bash
cd /Users/chinmay_shringi/Desktop/advproj/microwatt/hack_proj

# Run a specific test
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/correct_key_with_trojan.bin main_ram.bin && timeout 2 ./core_tb"
```

**Replace `correct_key_with_trojan.bin` with any of:**
- `correct_key_no_trojan.bin`
- `correct_key_with_trojan.bin`
- `wrong_key_no_trojan.bin`
- `wrong_key_with_trojan.bin`

### Option 2: Interactive Docker Shell (More Flexible)

Enter the Docker container and run tests interactively:

```bash
# From Mac terminal
cd /Users/chinmay_shringi/Desktop/advproj/microwatt/hack_proj
docker-compose run --rm ghdl bash

# Now you're inside the Docker container
cd dependencies/microwatt

# Run a test
cp tests/trojan/correct_key_with_trojan.bin main_ram.bin
timeout 2 ./core_tb

# Or use the helper script
cd dependencies/microwatt
./tests/trojan/run_test.sh correct_key_with_trojan

# Exit when done
exit
```

## All 4 Test Scenarios

### Test 1: Correct Key + No Trojan (Normal Operation)

```bash
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/correct_key_no_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -20"
```

**Expected**: Normal addition, correct results

### Test 2: Correct Key + Trojan Trigger (Privilege Escalation)

```bash
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/correct_key_with_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -20"
```

**Expected**: Trojan activates, privilege escalation occurs

### Test 3: Wrong Key + No Trojan (Scrambled Output)

```bash
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/wrong_key_no_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -20"
```

**Expected**: Results scrambled due to wrong key

### Test 4: Wrong Key + Trojan Trigger (Both Fail)

```bash
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/wrong_key_with_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -20"
```

**Expected**: Trojan may trigger but results scrambled, system unusable

## Understanding the Output

The simulation produces a lot of startup warnings (normal). Look for:

1. **Execution traces**: Shows instructions being executed
2. **Memory writes**: Look for `std` (store doubleword) operations
3. **MSR changes**: Look for MSR register modifications
4. **Simulation end**: Should halt with `attn` instruction

### Memory Layout

Results are stored at:
- `0x3000`: MSR value **before** operation
- `0x3008`: MSR value **after** operation
- `0x3010`: Computation result

### Key Indicators

**MSR[PR] bit (bit 14 from MSB):**
- `MSR[PR] = 0`: Supervisor mode (privileged)
- `MSR[PR] = 1`: User mode (problem state)

**Trojan success:**
- MSR[PR] changes from 1 → 0 (user → supervisor)
- In our tests, CPU starts in supervisor mode, so no visible change

## Troubleshooting

### "exec format error"

**Cause**: Trying to run Linux binary on macOS  
**Solution**: Use Docker (see Option 1 or 2 above)

### "docker-compose: command not found"

**Cause**: Docker not installed or not in PATH  
**Solution**: Install Docker Desktop for Mac

### "timeout: command not found" (inside Docker)

**Cause**: `timeout` not available  
**Alternative**: Let simulator run until it halts naturally, or use Ctrl+C

### Simulation runs forever

**Cause**: Program didn't execute `attn` instruction  
**Solution**: Use `timeout 2` to force stop after 2 seconds

### Want to see more output

Remove `tail -20` from commands:

```bash
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/correct_key_with_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1"
```

### Want to save output to file

Redirect to file on Mac:

```bash
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/correct_key_with_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1" > test_output.log

# Then view
cat test_output.log
```

## Quick Demo for Presentation

Run all 4 tests in sequence:

```bash
cd /Users/chinmay_shringi/Desktop/advproj/microwatt/hack_proj

echo "=== Test 1: Correct Key + No Trojan ==="
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/correct_key_no_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -10"

echo ""
echo "=== Test 2: Correct Key + Trojan ==="
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/correct_key_with_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -10"

echo ""
echo "=== Test 3: Wrong Key + No Trojan ==="
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/wrong_key_no_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -10"

echo ""
echo "=== Test 4: Wrong Key + Trojan ==="
docker-compose run --rm ghdl bash -c "cd dependencies/microwatt && cp tests/trojan/wrong_key_with_trojan.bin main_ram.bin && timeout 2 ./core_tb 2>&1 | tail -10"

echo ""
echo "All tests complete!"
```

## Next Steps

1. **For detailed test analysis**: See `TESTING.md`
2. **For security analysis**: See `SECURITY_ANALYSIS.md`
3. **For architecture details**: See `ARCHITECTURE.md`
4. **For implementation guide**: See `LOGIC_LOCKING_IMPL.md`

---

**TL;DR**: Always run `core_tb` inside Docker, not directly on macOS!

