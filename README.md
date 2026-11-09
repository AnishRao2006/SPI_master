# SPI Master (Texas Instruments Format)

A configurable, high-performance **SPI (Serial Peripheral Interface Master)** implementation written in System Verilog, featuring dedicated support for the **Texas Instruments (TI) Synchronous Serial Format** and thoroughly validated using **UVM (Universal Verification Methodology)**. 

---

## Overview
This module acts as the primary controller in a synchronous serial communication protocol, managing peripheral slaves via dedicated clock and data lines. Unlike standard Motorola configurations that rely on continuous slave-select behavior, this implementation strictly adheres to TI synchronous serial rules. It utilizes a distinctive active-high frame synchronization pulse (SPIDAT) right before transmission to ensure precise bit framing for specialized digital signal processors, audio codecs, and high-speed analog-to-digital peripherals.

---

## Verification Status
* **Verified With:** UVM (Universal Verification Methodology)
* **Status:** Fully constrained, randomized testing completed with scoreboards, checkers, and functional coverage models ensuring robust protocol compliance.

---

## Resource Utilization
Synthesized and implemented on target FPGA architecture:
* **LUTs (Look-Up Tables):** 31
* **Flip-Flops (FFs):** 38

---

## Architecture & Features
* **Full-Duplex Communication:** Simultaneous data transmission and reception via dedicated MOSI and MISO lines.
* **Hardware-Driven Clock Generation:** Precise internal clock divider and $SCLK$ generation logic.
* **TI Frame Synchronization:** Active-high frame sync pulse occurring exactly one serial clock cycle prior to data transmission.
* **Low Latency & High Throughput:** Deterministic hardware execution eliminating software-overhead delays.

---

## Signal Interface

| Signal Name | Direction | Description |
| :--- | :---: | :--- |
| `clk` | Input | System clock |
| `reset` | Input | Asynchronous active-high reset |
| `SPIDAT` | Input | Trigger signal to initiate transmission frame |
| `in_data` | Input [7:0] | Parallel data input to be transmitted |
| `out_data` | Output [7:0] | Parallel data received from slave |
| `SCLK` | Output | SPI serial clock |
| `SS` | Output | TI frame synchronization pulse |
| `MOSI` | Output | Master Out Slave In data line |
| `MISO` | Input | Master In Slave Out data line |

---

## Usage & Integration
Instantiate the module within your top-level design, tying off the appropriate clock, reset, and data buses. Ensure your target peripheral expects the single-cycle pulse frame synchronization characteristic of TI mode rather than continuous chip-select signaling (implemented for DEBUG here).
