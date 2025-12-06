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
| `0100` | `DRAW_TRI` | Draw filled triangle | `[59:50]` X1, `[49:40]` Y1, `[39:30]` X2, `[29:20]` Y2, `[19:10]` X3, `[9:0]` Y3 |
| `0101` | `DRAW_LINE` | Draw line | `[59:50]` X0, `[49:40]` Y0, `[39:30]` X1, `[29:20]` Y1 |
| `0110` | `DRAW_CIRC` | Draw filled circle | `[59:50]` Xc, `[49:40]` Yc, `[39:30]` Radius |
| `0111` | `DRAW_CHAR` | Draw character | `[59:52]` ASCII Code, `[51:42]` Start X, `[41:32]` Start Y |
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

### 4.4 Triangle Drawing (`datapath_triangle.vhd`)
- **Algorithm:** **Bounding Box & Edge Function**.
- **Logic:** 
    1.  **Bounding Box:** Calculates the minimum and maximum X and Y coordinates from the three vertices (X1,Y1), (X2,Y2), and (X3,Y3) to define a rectangular area that fully encloses the triangle.
    2.  **Rasterization:** Iterates through every pixel (`p_x`, `p_y`) within this bounding box.
    3.  **Edge Check:** For each pixel, it performs a 2D Cross Product check against all three edges of the triangle. If the pixel lies on the correct side of all three edges (inside the triangle), it is written to VRAM.

### 4.5 Character Rendering (`datapath_char.vhd` & `char_rom.vhd`)
- **Logic:** Uses a `char_rom` lookup table which stores the 8x8 bitmap font.
- **Rendering:** 
    1.  **Load:** Reads the ASCII code (8-bit) and starting position (X, Y) from the instruction.
    2.  **Row Fetch:** Iterates through 8 rows (0-7). For each row, it fetches the 8-bit font pattern from the ROM.
    3.  **Pixel Draw:** Iterates through 8 columns (0-7). It checks each bit of the font pattern. If a bit is '1', it writes the active color to VRAM at the calculated offset (`Start X + col`, `Start Y + row`).

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

## 7. Example Output

Below is an example of the GPU rendering output, visualized as a sequence of frames:

![GPU Output Animation](https://media.discordapp.net/attachments/1441822448306884709/1446874601769537618/outputRumah.gif?ex=6935927a&is=693440fa&hm=5053994af276263608bd1f61a12d98736f230387e1f63502930099fe9589cdf1&=&width=845&height=422)

![GPU Output Animation #2](https://media.discordapp.net/attachments/1441822448306884709/1446874908205256808/outputText.gif?ex=693592c3&is=69344143&hm=0d534ac14c7436d0703c46ee44f4ea1c4c1ddb48f68fb69e4a53a7b81c132ba9&=&width=845&height=422)

## Links
- Presentation
https://docs.google.com/presentation/d/1T9sgq7HcSU51s1MBVUYzaXnrPZ6Ey2v3BkG3ibgBUcY