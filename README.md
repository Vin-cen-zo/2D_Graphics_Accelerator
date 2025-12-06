# 2D Graphics Accelerator (GPU)

This project implements a hardware-based 2D Graphics Accelerator using VHDL. It is designed to offload geometric rendering tasks from a main processor by executing high-level drawing instructions to render shapes directly into Video RAM (VRAM).

## 1. Project Overview

The GPU Accelerator is a modular system capable of drawing basic 2D primitives such as lines, rectangles, triangles, circles, and characters. It operates using a 64-bit instruction set and manages its own memory interface for pixel data.

### Key Features
- **Microcoded Control Unit:** Flexible and extensible state machine design.
- **Hardware Accelerated Primitives:** Dedicated datapaths for Line, Circle, Rectangle, Triangle, and Text.
- **24-bit Color Support:** True color rendering.
- **VRAM Interface:** Direct memory access for pixel manipulation.
- **Simulation Support:** Includes testbenches and a "Dump Mode" to export VRAM contents to BMP files for verification.

## 2. Architecture

The system is organized into three main top-level components connected within `gpu.vhd`:

### 2.1 Top Level (`gpu.vhd`)
The top-level entity acts as the bridge between the external world (CPU/Testbench) and the internal accelerator logic.
- **Inputs:** Clock, Reset, Start, Instruction (64-bit).
- **Outputs:** Busy, Done, VRAM Data Out.
- **Function:** It routes signals between the Control Unit and Datapath Unit and multiplexes access to the VRAM (switching between internal drawing access and external dump access).

### 2.2 Control Unit (`control_unit.vhd`)
The brain of the GPU. It uses a **Microcoded Finite State Machine (FSM)**.
- **Micro-ROM:** Stores microinstructions that control the control signals for the datapath.
- **Sequencer:** Decodes the 64-bit input instruction opcode and jumps to the corresponding microcode routine.
- **Handshaking:** Manages `start`, `busy`, and `done` signals to synchronize with the host.
- **Wait States:** Pauses execution while waiting for specific datapath engines (e.g., Line Engine) to finish their task.

### 2.3 Datapath Unit (`datapath_unit.vhd`)
The execution engine. It contains specific hardware modules for each drawing primitive.
- **Routing:** Receives enable signals from the Control Unit and activates the corresponding sub-module.
- **VRAM Muxing:** Arbitrates which sub-module gets to write to the VRAM.
- **Color Register:** Stores the current active drawing color.

### 2.4 GPU VRAM (`gpu_vram.vhd`)
The video memory storage.
- **Capacity:** Addressable via 17-bit address (sufficient for standard low-res framebuffers, e.g., 320x240).
- **Data Width:** 24-bit (RGB 888).

## 3. Instruction Set Architecture (ISA)

The GPU executes 64-bit instructions. The Opcode is located in the most significant 4 bits `[63:60]`.

| Opcode | Mnemonic | Description | Parameters (Bits) |
| :--- | :--- | :--- | :--- |
| `0001` | `SET_COLOR` | Set active drawing color | `[23:0]` RGB Color |
| `0010` | `CLEAR` | Fill screen with active color | None |
| `0011` | `DRAW_RECT` | Draw filled rectangle | `[59:50]` X0, `[49:40]` Y0, `[39:30]` X1, `[29:20]` Y1 |
| `0100` | `DRAW_TRI` | Draw filled triangle | *Coordinates defined in instruction* |
| `0101` | `DRAW_LINE` | Draw line | `[59:50]` X0, `[49:40]` Y0, `[39:30]` X1, `[29:20]` Y1 |
| `0110` | `DRAW_CIRC` | Draw filled circle | `[59:50]` Xc, `[49:40]` Yc, `[39:30]` Radius |
| `0111` | `DRAW_CHAR` | Draw character | *Char code and position* |
| `0000` | `FINISH` | End of command list | None |

## 4. Algorithms & Implementation Details

### 4.1 Line Drawing (`datapath_line.vhd`)
- **Algorithm:** **Bresenham's Line Algorithm**.
- **Logic:** Uses integer arithmetic (addition, subtraction, bit shifting) to determine the pixels along the line path. It avoids floating-point operations for hardware efficiency.
- **State Machine:** `LOAD` -> `SETUP` (Calculate dx, dy) -> `DRAWING` (Iterate pixels) -> `FINISHED`.

### 4.2 Circle Drawing (`datapath_circle.vhd`)
- **Algorithm:** **Bresenham's Circle / Midpoint Algorithm**.
- **Filling:** Implements a **Scanline Fill** approach. For every calculated point on the circle perimeter, it draws horizontal lines between symmetric points to fill the shape.
- **Symmetry:** Calculates one octant and uses 4-way symmetry to generate the scanlines for the entire circle.

### 4.3 Rectangle Drawing (`datapath_rectangle.vhd`)
- **Algorithm:** Nested Loop.
- **Logic:** Iterates through X and Y coordinates within the bounding box defined by (X0, Y0) and (X1, Y1) to write the active color to VRAM.

### 4.4 Character Rendering (`datapath_char.vhd` & `char_rom.vhd`)
- **Logic:** Uses a `char_rom` lookup table which stores the bitmap font.
- **Rendering:** The datapath reads the font pattern for the requested ASCII character and writes pixels to VRAM where the font bits are '1'.

## 5. How Components Connect

1.  **Instruction Fetch:** The `gpu` receives a 64-bit `instruction` and a `start` pulse.
2.  **Decode:** The `control_unit` reads the Opcode `[63:60]`.
3.  **Dispatch:**
    -   If Opcode is `DRAW_LINE`, the CU asserts `en_line`.
    -   The `datapath_unit` sees `en_line` and activates `datapath_line`.
4.  **Execution:**
    -   `datapath_line` latches the coordinates from the instruction.
    -   It calculates VRAM addresses and asserts `line_we` (write enable).
    -   `datapath_unit` routes these signals to `gpu_vram`.
5.  **Completion:**
    -   When the line is finished, `datapath_line` asserts `line_done`.
    -   The `control_unit` detects `line_done`, de-asserts `busy`, and asserts `done`.

## 6. Simulation & Testing

The project includes testbenches (`tb_gpu.vhd`) to verify functionality.
- **Dump Mode:** When `dump_mode = '1'`, the GPU stops drawing and allows the testbench to read VRAM content address-by-address. This is used to generate an output image file (e.g., `.bmp`) to visually verify the drawing commands.
