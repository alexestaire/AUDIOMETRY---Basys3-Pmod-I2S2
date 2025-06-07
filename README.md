# AUDIOMETRY---Basys3-Pmod-I2S2
FPGA-based tonal audiometry system for preliminary hearing evaluation and early detection of hearing loss. Developed entirely in VHDL on the Basys 3 board with an Artix-7 FPGA.

This project implements a tonal audiometry system on an FPGA platform, aimed at the preliminary assessment of hearing capabilities and the early detection of potential hearing impairments. The system is developed using VHDL and deployed on a Digilent Basys 3 board featuring a Xilinx Artix-7 FPGA. It generates sinusoidal tones across a range of frequencies typically used in clinical audiometry tests and outputs audio using the Pmod I2S2 module. The design is entirely digital and includes modules for signal generation, volume control, state sequencing, and frequency display.

To implement the project, follow these steps:

1 - Create a new Vivado project
    Launch Vivado and create a new RTL project named Audiometry.

2 - Select the target board
    In the Boards tab, choose Basys3.

3 - Add VHDL source files
    Use the "Add Sources" option and select "Add or create design sources" to include all .vhd files.

4 - Set the top module
    Select the audiometry file as the top-level module.

5 - Add simulation sources
    Use "Add Simulation Sources" to include your .vhd testbenches from the sim/ directory.

6 - Add constraint file
    Use "Add Constraints" to include the Basys3_Master.xdc file from the constraints/ directory.

7 - Add the clock IP (.xci file)
    Use "Add Sources" and select the .xci file (Clocking Wizard).
        If needed, regenerate it via:
        Project Manager > IP Sources > Clocking Wizard
        Set clk_out1 to 22.57921 MHz to match the audio codec requirements.

8 - Run synthesis, implementation, and generate bitstream
    Once no errors are present, program the Basys 3 board using the generated .bit file.
