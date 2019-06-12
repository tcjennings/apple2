# SCREEN.ADDRESS.S

Source code for SCREEN.ADDRESS.ML for Merlin 8.

Implements the "Display Address Mapping" algorithm used by the Apple II's IOU according to the "Hardware Implementation" chapter of the Apple II Reference Manual (Chapter 7 in the IIe manual and Chapter 11 in the //c manual).

Supports 40-column text mode display address mapping.

## Usage

Place a vertical (Y) coordinate in memory location 254 ($FE) and a horizontal (X) coordinate in memory location 255 ($FF) and execute the routine at 32768 ($8000). The coordinates should be 0-based within the limits [0,23] for Y and [0,39] for X.

```
]POKE 254,12 : POKE 255,20 : CALL 32768
063C
```

# SCREEN.ADDREESS.ML

The assembled Machine Language object code for SCREEN.ADDRESS.S in a format acceptable for pasting into the Apple Monitor.

# SCREEN.ADDRESS.BAS

An Applesoft BASIC program which demonstrates the SCREEN.ADDRESS.ML routine. Asks for a Y,X coordinate and uses the resulting memory address to draw a character at that screen memory location.

