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

# Operation

## Text Mode and Lo-Res Addressing

Screen display address has a MSB and an LSB, i.e., $0400 has MSB $40 and LSB $00.

This address is made up of 16 bits across the two bytes:

```
LSB =  A7  A6  A5  A4  A3  A2 A1 A0
MSB = A15 A14 A13 A12 A11 A10 A9 A8
```

To determine the values of these bits, you have to calculate 5 bits of Vertical Count (V) and 6 bits of Horizontal Count (H), as well as a 4-bit packed Sum (S). Bits A10 and A11 are specially-derived from soft-switches.

### Vertical and Horizontal Count

Vertical count runs from 0 to 23 where 0 is the top line of the display and 23 is the last (24 lines).

Horizontal count runs from 24 to 44 where 24 is the leftmost position and 44 is the rightmost position (40 columns).

Take V as a 5-bit value and H as a 6-bit value.

#### Example

For example, screen position 12,20 (roughly the center point) is:

```
   b 5  4  3  2  1  0
    _________________
 V | X  0  1  1  0  0  == 12
 H | 1  0  1  1  0  0  == 44 (24 + 20)
```

### Sum

The 4-bit Sum value is taken from the following binary addition. Note the constant value in the addend and that "H5*" means the complement of H5. Any remaining carry bit is discarded.

```
             V3  Carry
H5*  V3  H4  H3  Augend
V4   H5* V4   1  Addend
_______________
S3   S2  S1  S0
```

#### Example

For the 12,20 example, plugging in the bits from above provides an S of 0111:

```
              1  Carry
 0*   1   0   1  Augend
 0    0*  0   1  Addend
_______________
 0    1    1  1
```

### Screen Addressing

The 16 bits of screen address relate to the H, V, and S bits as follows, showing the LSB first.

```
LSB  A7  A6  A5  A4  A3  A2  A1  A0    MSB  A15  A14  A13  A12  A11  A10 A09  A08
     V0  S3  S2  S1  S0  H2  H1  H0           0    0    0    0   **    *  V2   V1
```

Note that all the bits not used to figure the S-bits are used directly in the address. Also note that special values are used for A10 and A11 and that the most significant 4 bits of the MSB are 0s, which makes things pretty easy there.

### A10 Bit

The A10 bit for text and low-res mode is determined by the formula:

```
80STORE + PAGE2'
```

Which refers to the soft switches for these characteristics, specifically:

- RD80STORE ($C018 / #49176)
- RDPAGE2 ($C01C / #49170)

In these switches, only bit 7 matters. If it is a 1, the switch is "on" and if it is a 0 then the "switch" is off. In other words, the test `SWITCH > 127` determines the state of the switch.

For the A10 bit, the value of the RD80STORE switch is added with *NOT* PAGE2 (the "PAGE2-prime" indicator meaning the negation of PAGE2).

This should result in a truth table:

```
          PAGE2' 0  PAGE2' 1
80STORE 0        1         0
80STORE 1        1         1
```

Simply, in standard 40-column or Lo-Res mode, the A10 bit will be 1.

### A11 bit

The A11 bit for text and low-res mode is determined by the formula:

```
80STORE' & PAGE2
```

For this bit, the 80STORE switch is Prime (NOT 80STORE) and the boolean AND operation is used. The truth table for this bit is

```
           PAGE2 0   PAGE2 1
80STORE' 0       0         1
80STORE' 1       0         0
```

Again, for standard 40-column/lo-res mode with PAGE1, the A11 bit will be 0.

### Finishing the Example

To finish the example of finding the screen address for (12,20), let's recap:

```
   7  6  5  4  3  2  1  0
H  X  X  1  0  1  1  0  0
V  X  X  X  0  1  1  0  0
S  X  X  X  X  0  1  1  1
```

Additionally, A10 will be 1 and A11 will be 0. Because both 80STORE and PAGE2 are in an "OFF" state.

So, plugging all the bits into position, we get:

```
LSB  A7  A6  A5  A4  A3  A2  A1  A0    MSB  A15  A14  A13  A12  A11  A10 A09  A08
      0   0   1   1   1   1   0   0           0    0    0    0    0    1   1    0
```

Turning these bytes into hex and putting them in natural order, we get $063C or decimal 1596, which is the correct screen address for the character at 12,20.

# Optimization

The ML routine is not optimized and is probably not bug-free.

## ROR Operations

Consider the following operation in the `ASMLSB` routine which assembles the LSB of the display address:

```
ASMLSB
 ...
 LDA VCOUNT
 AND #$1 ; keep low bit
 ROR ; rotate b0 to C
 ROR ; rotate C to b7
 ...
```

The goal of this section of code is to take the Y coordinate (VCOUNT) and prepare it for use in the LSB.

The LSB only uses V0 from this value, so first that bit is isolated with an AND operation, which leaves the result on the Accumulator.

Then that result is Rotated Right two times. The first one pops V0 out of the accumulator and into the Carry flag, and the second one pushes the Carry flag onto the other side of the byte, effectively moving bit 0 to bit 7.

The error is that the first ROR also pushes the Carry flag onto the byte, which can introduce unwanted values in this byte if the flag is not 0. A CLC should be issued before the first ROR to ensure a 0 is pushed onto the byte.

But there is another option, which is to replace the first ROR with an LSR, which will still pop bit 0 into the Carry flag but always pushes a 0 into bit 7, because it is a *shift* instead of a *rotate*.

Which method is more optimal in terms of bytes and cycles? CLC, ROR, and LSR all use a single byte for the instruction and complete in 2 cycles, so using LSR and ROR is more efficient just because it can complete the logic in 2 bytes/4 cycles instead of 3 bytes/6 cycles.

