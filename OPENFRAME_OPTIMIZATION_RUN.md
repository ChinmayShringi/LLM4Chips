# Microwatt-LL OpenFrame Optimization Run

**Started**: October 25, 2024  
**Goal**: Shrink design from 56mm² to ≤15mm² for Efabless OpenFrame MPW submission

---

## **Run Configuration**

### **Previous Run (Baseline):**
- Die: 56mm² (7mm × 8mm)
- Density: 15%
- Clock: 50MHz
- Optimizations: ALL DISABLED
- Runtime: 3h51m
- Result: ✅ Complete GDSII but TOO LARGE for OpenFrame

### **Current Run (Optimized):**
- Die: 16mm² (4mm × 4mm) - **71% smaller!**
- Density: 50% - **3.3× denser**
- Clock: 40MHz - **Relaxed for area**
- Optimizations: **ALL ENABLED**
- Expected Runtime: 8-12 hours
- Goal: Fit within OpenFrame 15mm² limit

---

## **Aggressive Optimizations Enabled**

### **1. Synthesis Optimizations:**
```json
"SYNTH_STRATEGY": "AREA 2"  // Minimize area vs speed
```
- Focus on reducing cell count
- Use smaller gate sizes
- Share logic aggressively

### **2. Placement Optimizations:**
```json
"PL_TARGET_DENSITY": 0.50  // 50% utilization (was 15%)
"PL_RESIZER_DESIGN_OPTIMIZATIONS": 1
"PL_RESIZER_TIMING_OPTIMIZATIONS": 1
```
- Pack cells very tightly
- Optimize wire lengths
- Buffer long paths
- Resize gates for timing/area

### **3. Routing Optimizations:**
```json
"GRT_RESIZER_DESIGN_OPTIMIZATIONS": 1
"GRT_RESIZER_TIMING_OPTIMIZATIONS": 1
"GLB_RESIZER_DESIGN_OPTIMIZATIONS": 1
"GLB_RESIZER_TIMING_OPTIMIZATIONS": 1
"ROUTING_CORES": 8  // Parallel routing
"GRT_OVERFLOW_ITERS": 100  // More iterations
```
- Fix congestion by gate sizing
- Add buffers on critical paths
- Remove redundant buffers
- Optimize across all corners (min/typ/max)

### **4. Additional Features:**
```json
"GRT_REPAIR_ANTENNAS": true
"RUN_HEURISTIC_DIODE_INSERTION": true
"RUN_FILL_INSERTION": 1
```
- Protect gates from antenna effects
- Insert diodes where needed
- Add metal fill for DRC compliance

---

## **Clock Frequency Trade-off**

**Baseline**: 50MHz (20ns period)
- Very tight timing
- Required large die for wire delays

**Optimized**: 40MHz (25ns period)
- 20% slower clock
- 25% more time for signals to propagate
- Allows much smaller/denser placement
- **Still fast enough for most applications!**

---

## **Expected Results**

### **Best Case (Success):**
- Final area: 12-15mm² ✅
- Fits in OpenFrame! ✅
- Can submit to Efabless MPW ✅
- Free/low-cost fabrication! ✅

### **Likely Case:**
- Final area: 15-18mm² ⚠️
- Slightly over limit
- Could remove FPU or reduce caches
- Or submit to larger shuttle

### **Worst Case:**
- Optimizations cause timing failures
- Routing doesn't converge
- Still >20mm²
- Use baseline 56mm² design instead

---

## **Monitoring Progress**

```bash
# Watch live log
tail -f /tmp/synthesis_optimized_16mm2.log

# Or OpenLane's log directly
tail -f openlane/microwatt_core/logs/synthesis_*.log

# Check current step
grep "STEP" /tmp/synthesis_optimized_16mm2.log | tail -5
```

### **Timeline Estimates:**
- Steps 1-2 (Synthesis): ~45 min
- Steps 3-13 (Placement): ~2 hours
- Steps 14-15 (CTS): ~1 hour
- Steps 16-19 (Routing): ~4-6 hours
- Steps 20-28 (Signoff): ~1 hour
- **Total: 8-12 hours**

---

## **Memory Requirements**

**Previous run**: 11.4GB peak (with 12GB limit - barely fit!)

**This run estimate**:
- Smaller die (16mm² vs 56mm²) = Less memory
- But more optimization passes = More memory
- **Expected peak: 10-14GB**
- **Current Docker limit: 12GB**

⚠️ **Watch for OOM errors!** May need to increase to 16GB if it fails.

---

## **What Happens After Success**

If we hit ≤15mm²:

1. **Copy final GDSII to OpenFrame wrapper**
2. **Configure wrapper GPIO connections**
3. **Run wrapper-level synthesis** (~2 hours)
4. **Generate wrapper GDSII**
5. **Submit to Efabless MPW!**

---

## **Fallback Options**

If this run fails or exceeds 15mm²:

### **Option A: Further Optimizations**
- Disable FPU (saves ~20%)
- Reduce I-cache from 4KB to 2KB
- Reduce D-cache from 8KB to 4KB
- Target: 10-12mm²

### **Option B: Slower Clock**
- Drop to 30MHz (33ns period)
- Even more timing slack
- Allows tighter packing
- Target: 11-13mm²

### **Option C: Accept Larger Size**
- Submit baseline 56mm² to private shuttle
- Cost: ~$50-100K
- Or submit to ChipIgnite (~$10K for larger area)

### **Option D: Hybrid Approach**
- Keep baseline 56mm² for hackathon demo
- Continue optimizing for future MPW
- Show progress in paper/presentation

---

## **Success Criteria**

### **For Hackathon (Already Achieved!):**
✅ Working trojan + logic locking  
✅ Complete simulation validation  
✅ RTL-to-GDSII flow demonstrated  
✅ Fabrication-ready GDSII (56mm²)  

### **For MPW Submission (In Progress):**
- [ ] Area ≤ 15mm²
- [ ] 0 DRC violations
- [ ] Timing closure at 40MHz
- [ ] Integrated into OpenFrame wrapper
- [ ] Submitted to Efabless

---

## **Risk Assessment**

**High Risk Items:**
1. **Memory exhaustion** during optimization steps
   - Mitigation: Increase Docker to 16GB if needed
2. **Routing congestion** at 50% density
   - Mitigation: GRT_OVERFLOW_ITERS=100, ALLOW_CONGESTION if needed
3. **Timing violations** at 40MHz
   - Mitigation: Can relax to 30MHz or skip optimizations

**Medium Risk:**
1. Still >15mm² after optimization
   - Mitigation: Further reduce features or accept larger size
2. Long runtime (>12 hours)
   - Mitigation: This is expected, just wait

**Low Risk:**
1. Design functionality broken
   - Mitigation: Optimizations only affect physical, not logical

---

## **Current Status**

**Run Started**: October 25, 2024
**Expected Completion**: October 26, 2024 (8-12 hours)

Monitor with:
```bash
tail -f /tmp/synthesis_optimized_16mm2.log
```

---

**Fingers crossed! 🤞**

This is an aggressive optimization targeting a 71% area reduction while maintaining all security features. If successful, this will be one of the most compact open-source 64-bit CPUs with hardware security features!

