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

## How to Run

### Simulation with Icarus Verilog (iverilog)
To run the simulation for the top-level system using `iverilog`, navigate to the `testbench` directory and run the following commands:
```bash
cd testbench
iverilog -g2012 -o sim.out -I ../design/ tb_system_top.sv ../design/system_top.v
vvp sim.out
```

### Physical Design with OpenLane

This project utilizes a **Hierarchical Physical Design (PD) Flow** with OpenLane. Instead of hardening the entire `system_top` at once (flat flow), we build the system bottom-up by creating individual macros and assembling them.

#### Hierarchical Flow Overview
1. **Block-Level Hardening**: First, the 4 internal sub-blocks of the Viterbi Decoder (`bmu`, `acsu`, `pmu`, `tbu`) are hardened individually into macros.
2. **Core Assembly**: The 4 hardened macros are integrated to form the `viterbi_core` macro.
3. **Top-Level Integration**: Finally, the `viterbi_core` macro is combined with the remaining top-level modules (`sync_fifo`, `piso`, `sipo`) to harden the full `system_top` design.

#### Configuration and Constraints (`config.json` and `.sdc`)

Each macro in the `openlane` directory has its own configuration:
- **`config.json`**: This file defines the synthesis, floorplanning, placement, and routing parameters. Key variables include:
  - `"DESIGN_NAME"`: The name of the module.
  - `"VERILOG_FILES"`: Paths to the RTL source files.
  - `"CLOCK_PORT"` & `"CLOCK_PERIOD"`: Clock definitions.
  - For higher-level integration (like `viterbi_core` and `system_top`), variables such as `"MACRO_PLACEMENT_CFG"`, `"EXTRA_LEFS"`, and `"EXTRA_GDS_FILES"` are used to instantiate and place the pre-hardened sub-macros.
- **`.sdc` (Synopsys Design Constraints)**: Used for advanced timing constraints. While simple clocks can be defined in `config.json`, an `.sdc` file allows you to specify input/output delays, false paths, and multi-cycle paths to ensure the design meets timing requirements across the hierarchy.

#### Running the Flow
To run the synthesis and physical design flow, ensure you have the OpenLane environment set up. Run the following command inside the OpenLane docker container to synthesize a specific design:
```bash
./flow.tcl -design <path_to_project>/openlane/<module_name>
```

**Execution Order**:
Due to the hierarchical nature of the project, you **must** run the flow in the following order:

1. Run the sub-blocks:
   ```bash
   ./flow.tcl -design <path_to_project>/openlane/bmu
   ./flow.tcl -design <path_to_project>/openlane/acsu
   ./flow.tcl -design <path_to_project>/openlane/pmu
   ./flow.tcl -design <path_to_project>/openlane/tbu
   ```
2. Run the core integration:
   ```bash
   ./flow.tcl -design <path_to_project>/openlane/viterbi_core
   ```
3. Run the top-level integration:
   ```bash
   ./flow.tcl -design <path_to_project>/openlane/system_top
   ```
