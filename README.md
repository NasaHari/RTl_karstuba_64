

# Karatsuba 64-bit Multiplier (SystemVerilog)

## Overview

This project implements a **64-bit multiplier** using the **Karatsuba multiplication algorithm** in SystemVerilog. The design is pipelined and supports streaming input/output using nibbles (4-bit chunks). It includes submodules for smaller multipliers (34-bit and 18-bit) and manages a FIFO-based data flow to handle multiple operations concurrently.

The multiplier is intended for high-performance FPGA or ASIC designs where large integer multiplication is needed.

---

## Features

* **64-bit inputs, 128-bit output** multiplication.
* Uses **Karatsuba algorithm** for efficient multiplication.
* Supports **streaming input**: 64-bit numbers sent as 16 nibbles.
* **FIFO-based buffering** for input pairs and output products.
* Fully **pipelined FSM** for continuous multiplication.
* Includes **self-checking testbench** with random test vectors.
* Modular design: includes `karatsuba34`, `karatsuba64`, and `mult18`.

---

## Module Hierarchy

```
B (top-level module)
├── karatsuba64
│   ├── karatsuba34
│   │   └── mult18
```

* **B.sv**: Top-level module handling input/output, FIFOs, and FSM control.
* **karatsuba64.sv**: 64-bit Karatsuba multiplier using two 34-bit submodules.
* **karatsuba34.sv**: 34-bit Karatsuba multiplier using 18-bit multipliers.
* **mult18.sv**: 18x18-bit base multiplier.
* **tb\_B.sv**: Testbench for validating the top-level module with predefined and random inputs.

---

## Signals (Top-Level `B` Module)

| Signal     | Direction     | Description                       |
| ---------- | ------------- | --------------------------------- |
| `clk`      | input         | Clock signal                      |
| `rst`      | input         | Active-high synchronous reset     |
| `start`    | input         | Start pulse for new data          |
| `Data_in1` | input \[3:0]  | Nibble input for number 1         |
| `Data_in2` | input \[3:0]  | Nibble input for number 2         |
| `T_Ready`  | input         | Ready signal to send output bytes |
| `Data_out` | output \[7:0] | Output byte of product            |

---

## How to Use

### 1. Compile

Use a SystemVerilog simulator such as **Icarus Verilog**, **VCS**, or **Modelsim**:

```bash
iverilog -g2012 -o sim B.sv karatsuba64.sv karatsuba34.sv mult18.sv tb_B.sv
```

### 2. Run Simulation

```bash
vvp sim
```

* Waveform can be dumped using `$dumpfile("wave.vcd")` and viewed in **GTKWave**.

### 3. Sending Data

* 64-bit numbers are sent nibble-by-nibble using the `start` signal for the first nibble.
* Output products are read 8 bits at a time when `T_Ready` is high.

---

## Testing

* `tb_B.sv` includes automated checks for correctness.
* Supports:

  * Fixed test cases
  * Randomized input vectors
  * Reporting of **pass/fail counts**

---



## Notes

* Design uses **non-blocking assignments (`<=`)** for proper pipelining.
* FIFO depth for input numbers is **4**, for output products **8**.
* Debug `$display` statements are included but commented out; can be enabled for waveform inspection.
