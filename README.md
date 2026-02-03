# Viterbi-Decoder-Implementation-and-Verification
Implement Viterbi Decoder in Verilog and verify functions

## OpenLane Implementation Results

The following physical design results were obtained from the OpenLane flow (run: `system_top/final`).

### Key Metrics
| Metric | Value |
| :--- | :--- |
| **Die Area** | 2.25 mm² |
| **Core Area** | 2.20 mm² |
| **Logic Area** | 1.06 mm² |
| **Utilization** | 48.35% |
| **Instance Count** | 15,772 |

### Performance (Timing)
The design meets all timing constraints (Timing Clean).
- **Setup Slack**: 4.36 ns (MET)
- **Hold Slack**: 0.33 ns (MET)

### Power Consumption
- **Total Power**: 5.99 mW
- **Dynamic Power**: 2.57 mW
- **Internal Power**: 3.42 mW
- **Leakage Power**: 0.14 µW

### Physical Verification
- **DRC**: Passed (0 Violations)
- **LVS**: Passed (0 Errors)

## System Verification Results

The system was verified using a comprehensive testbench covering various scenarios, including clean channel transmission and error injection. (Log: `testbench/log_final.txt`)

### Test Scenarios
- **Sanity Check**: Basic functional verification to ensure pipeline integrity.
- **Full Range Sweep**: Exhaustive test of all 8-bit input symbols (0x00-0xFF).
- **Error Injection**: Controlled injection of Single, Double, Triple, and Burst errors to test correction capability.
- **Stress Testing**: Continuous processing and mid-stream Reset Recovery.

### Verification Summary
The Viterbi decoder (K=3, r=1/2) successfully corrects all single-bit errors as guaranteed by the algorithm. Multi-bit errors showed expected performance degradation.

| Scenario | Total Tests | Pass | Fail | Success Rate |
| :--- | :--- | :--- | :--- | :--- |
| **Clean Channel (0 Errors)** | 392 | 392 | 0 | **100%** |
| **Single Bit Error** | 64 | 64 | 0 | **100%** |
| **Double Bit Error** | 50 | 40 | 10 | 80% |
| **Triple Bit Error** | 20 | 6 | 14 | 30% |
| **Burst Error (>4 bits)** | 20 | 5 | 15 | 25% |

> [!NOTE]
> The decoder is architecturally designed to correct 1-bit errors per discrete window. Random multi-bit errors exceeding this capacity are expected to cause failures, consistent with the Viterbi algorithm's theoretical limits for this constraint length.
