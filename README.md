# Division PIC Project

This repository contains two assembly programs for PIC16F877A devices that implement a simple division calculator using a master/co-processor architecture.

## Building

Use MPLAB X or MPLAB 8 to assemble the source files located in `ProjectThree`:

1. Open `pro1.asm` for the master CPU.
2. Open `pro2.asm` for the auxiliary CPU.
3. Build each project to generate the corresponding HEX file.

All temporary build products (HEX, MAP, COF, etc.) are ignored via `.gitignore`.

## Proteus Simulation

A Proteus schematic (`DivisionDesign.pdsprj`) is provided as a starting point. It describes two PIC16F877A devices connected via `PORTC`, a push button on `RB0`, and a 16x2 LCD in 4-bit mode on `PORTD`.

To run the simulation:

1. Open the project in Proteus.
2. Load the HEX file for `pro1.asm` into the first PIC and the HEX for `pro2.asm` into the second.
3. Start the simulation to test division functionality.
