In this firmware project, I worked with my partner Michael Wasson where we decided to code an accurate version of the classic game Atari Breakout.
This code was synthesized and flashed to a Xilinx Artix 7 FPGA as part of the Nexys-4 kit which contained a VGA adapter to display it on a monitor.

Michael focused on collision boundaries and displaying the ball, platform, and blocks while I coded the state machine to smoothly animate and update 
the ball's 23 possible trajectories based on the unit circle. To ensure accuracy to the original game, special collisions with the platform are also implemented.

The code that loaded the computer monitor each frame and the constraints file are omitted.
