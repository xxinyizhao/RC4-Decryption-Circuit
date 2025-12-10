# FPGA ARC4/RC4 Decryption Circuit & Key Cracker

Hardware implementation of the ARC4 stream cipher on an Altera DE1-SoC FPGA, including a brute-force key search engine and a parallel “multi-crack” accelerator. The project uses on on-chip memory, hardware handshake microprotocols, and scalable digital design.

---

## Project Overview

This project implements:

- A complete ARC4 decryption datapath in hardware (state init → key scheduling  → keystream generation → XOR decrypt).
- A brute-force “cracker” that searches the 24-bit key space and detects valid plaintext based on human-readable ASCII.
- A parallel “doublecrack” architecture that runs two cracking cores in parallel to roughly halve the search time.

All modules are written in SystemVerilog and tested in the Intel/Altera Cyclone V (DE1-SoC board), using on-chip M10K RAM blocks.

---

## Main Features

- **ARC4 cipher core**
  - Implements the standard ARC4 algorithm with a 256-byte state array `S`.
  - Supports 24-bit keys (3 bytes, big-endian).
  - Operates on length-prefixed strings stored in on-chip memories.
  - Split into three sub-modules: Initialization (init.sv), Key-Scheduling Algorithm (KSA), and Pseudo-Random Generation Algorithm (PRGA)

- **Ready/Enable microprotocol**
  - All submodules (init, key schedule, PRGA, decrypt, crack) use a `rdy`/`en` handshake.
  - Allows each block to take a variable number of cycles without stalling the whole design.
  - Designed to avoid combinational loops and respect clean clock/reset domains.

- **On-chip memories**
  - `s_mem` – 256×8 ARC4 state array.
  - `ct_mem` – ciphertext memory (length-prefixed).
  - `pt_mem` – plaintext memory (length-prefixed).
  - Configured as single-port M10K RAMs, accessible via Quartus’ In-System Memory Content Editor and ModelSim’s memory viewer.

- **Brute-force cracker**
  - Iterates over all 24-bit keys in order.
  - For each key, runs the full ARC4 pipeline and writes plaintext to `pt_mem`.
  - Declares success when all decrypted bytes are in the printable ASCII range (`0x20`–`0x7E`).
  - Exposes:
    - `key` – discovered key (if any),
    - `key_valid` – high when a valid key and plaintext have been found.

- **Parallel engine**
  - Two independent `crack` cores:
    - Core 1 searches keys `0, 2, 4, …`
    - Core 2 searches keys `1, 3, 5, …`
  - Shares a single ciphertext memory and a common top-level plaintext memory.
  - When either core finds a key, the corresponding plaintext is written to the shared `pt_mem` and the key is reported to the top level.
  - Achieves ~2× speedup over a single-core implementation.
  - **I implementated an active-OR mechanism** to safely manage shared access to the ciphertext memory. Combined with parallel key-space partitioning, this resulted in a **very fast hardware cracker** relative to the baseline design.
  
## Implementation & Verification

- **Language & Tools**
  - SystemVerilog RTL
  - Intel Quartus Prime for synthesis and place-and-route
  - ModelSim for RTL and post-synthesis simulation
  - DE1-SoC (Cyclone V) evaluation board

- **Testing approach**
  - Separate RTL (`tb_rtl_*.sv`) and post-synthesis (`tb_syn_*.sv`) testbenches for each task.
  - Used `$readmemh` to load known ciphertexts and compare decrypted outputs against software reference implementations.
  - Verified correct ARC4 state, key scheduling, and decrypted plaintext for multiple test vectors.
  - Confirmed memory hierarchies via ModelSim’s memory viewer and Quartus’ In-System Memory Content Editor.
