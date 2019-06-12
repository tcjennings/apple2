# SCREEN.ADDRESS.S

Source code for SCREEN.ADDRESS.ML for Merlin 8.

Implements the "Display Address Mapping" algorithm used by the Apple II's IOU according to the "Hardware Implementation" chapter of the Apple II Reference Manual (Chapter 7 in the IIe manual and Chapter 11 in the //c manual).

Supports 40-column text mode display address mapping.

## Usage

Place a vertical (Y) coordinate in memory location 254 ($FE) and a horizontal (X) coordinate in memory location 255 ($FF) and execute the routine at 32768 ($8000). The coordinates should be 0-based within the limits [0,23] for Y and [0,39] for X.

*The program uses ROM routine `COUT` at $FDDA to print the calculated memory location.*

```
]POKE 254,12 : POKE 255,20 : CALL 32768
063C
```

The resulting 16-bit memory address is stored in locations 30 ($1E) and 31 ($1F), least significant byte first as is standard.

```
]PRINT PEEK(31)*256+PEEK(30)
1596
```

# SCREEN.ADDRESS.ML

The assembled Machine Language object code for SCREEN.ADDRESS.S in a format acceptable for pasting into the Apple Monitor.

Save this listing with `BSAVE SCREEN.ADDRESS.ML,A$8000,L$10C`.

# SCREEN.ADDRESS.BAS

An Applesoft BASIC program which demonstrates the SCREEN.ADDRESS.ML routine. Asks for a Y,X coordinate and uses the resulting memory address to draw a character at that screen memory location.

The program always starts off on text page 1. After drawing the first specified coordinate, the program switches to a kind of command mode:

- Press E to enter a new coordinate for the current display page.
- Press P to switch display pages.
- Press X to exit the program.

To enter a coordinate for display page 2, first press P to switch, then E to enter a coordinate. The program switches back to Page 1 to take input and show output. Press P to switch again to see the drawn character. Coordinates will continue to be calculated for Page 2 until a double-switch resets the current operating page.

*Applesoft doesn't have PRINT routines for Page 2 so BASIC input and output can only happen on Page 1, whether you're looking at it or not.*

This program starts by moving BASIC to address $6000 (24576) which prevents it from using any of the display buffers for program or variable storage. Ordinarily BASIC uses the text/low-res Page 2 memory for programs.

This program implements a HOME function for the Page 2 display at $300 (768) which works by "clearing" the 4 memory pages starting at $800 with (inverse) SPC characters.

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

The 4-bit Sum value is taken from the following binary addition. Note the constant value in the addend and that "H5*" means the complement of H5. Any remaining carry bit (S4) is discarded.

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
 0    1   1   1
```

This is straightforward binary addition, but the same math for coordinates 0,0 get interesting (remember H=0+24 here, or `111000` after flipping H5):

```
              0  Carry
 1*   0   1   1  Augend
 0    1*  0   1  Addend
_______________
 0    0   0   0
 ```

This math says that 11 + 5 = 0. This case demonstrates how discarding the final carry affects the outcome of the algorithm.

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

In these switches, only bit 7 matters. If it is a 1, the switch is "on" and if it is a 0 then the switch is "off". In other words, the test `SWITCH > 127` determines the state of the switch.

For the A10 bit, the state of the RD80STORE switch is added with *NOT* PAGE2 (the "PAGE2-prime" indicator meaning the negation of PAGE2).

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

### PAGE2 Addresses

According to the A10 and A11 truth tables, when 80STORE is off but PAGE2 is on, the A11.A10 bit pair should be "10", and when PAGE2 is off, the bit pair should be "01". This is sufficient to produce base screen address MSB values of:

```
           A11.A10    MSB
PAGE2 OFF       01  $0400
PAGE2 ON        10  $0800
```

Further, it is not possible for PAGE2 to be "on" when 80STORE is "on" -- bits A11.A10 will always be "01" when 80STORE is "on".

### Finishing the Example

To finish the example of finding the screen address for (12,20), let's recap:

```
   7  6  5  4  3  2  1  0
H  X  X  1  0  1  1  0  0
V  X  X  X  0  1  1  0  0
S  X  X  X  X  0  1  1  1
```

Additionally, A10 will be 1 and A11 will be 0. Because both 80STORE and PAGE2 are in an "Off" state.

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

Which method is more optimal in terms of bytes and cycles? CLC, ROR, and LSR all use a single byte for the instruction and complete in 2 cycles, so using LSR and ROR is more efficient because it can complete the logic in 2 bytes/4 cycles instead of 3 bytes/6 cycles.

## Repeated Instructions

There are times when an instruction like LSR is repeated multiple times, such as to move a bit from b5 to b0 requires 5 shifts to the right. These 5 instructions occupy 5 bytes and take 10 cycles to complete.

Modern programming instills the idea that if you do anything more than once you should move that logic to a function or equivalent. Does this hold in Assembly?

There could be a routine that performs LSR an arbitrary number of times:

```
REPLSR
     LSR
     DEX
     BNE REPLSR
     RTS
```

You would have the operand on the accumulator and put the number of desired shifts into the X register and JSR to this routine:

```
     ...
     LDX #$5
     JSR REPLSR
     ...
```

But have you improved the program? The new routine occupies 5 bytes on its own, but calling it requires 5 bytes too! That's a constant value, too, no matter how many repetitions you plan to make, plus the overhead of pushing and pulling the return address to/from the stack.

This is not to say repeated LSR instructions are not subject to optimization, it's just not in the usual modern way. There are only 8 bits in a 6502 register, so there's never a reason to LSR more than 7 times, and there's a point at which it's better to rotate to the left instead of shifting to the right.

In fact, it could be better to set a threshold for LSR instructions such that 4 or fewer, just repeat the instruction, which is 4 bytes/8 cycles.

It turns out 5 LSRs in a row is the worst case. Getting bit 5 into the bit 0 position takes 5x LSR (5 bytes / 10 cycles) but can be accomplished with the following instead:

```
     ...
     ASL ; Shift b5 -> b6
     ASL ; Shift b6 -> b7 
     ASL ; Shift b7 -> C
     ROL ; Rotate C -> b0
     ...
```

Same result, but it takes 4 bytes and 8 cycles.

Getting bits 6 or 7 into the bit 0 position is even easier, just drop the relevant number of ASL instructions.

So: Getting an arbitrary bit to the least significant position? If it's bit 4 or lower, shift right. If it's bit 5 or higher, shift left then rotate. Worst case is 4 bytes/8 cycles for those two bits in the middle.

## Flipping H5

In the Augend and Addend, the complement of the H5 bit is used. Contrary to best practices, there is a routine labeled "ONEBITFLIP" to get this complement:

```
ONEBITFLIP
 STA TEMPZ
 LDA #$1
 EOR TEMPZ ; result on A
 RTS
```

This routine uses a zero-page location as a temporary register. First it moves the accumulator to this register (2 bytes/3 cycles), then it loads the value 1 on the accumulator (2 bytes/2 cycles), finally it performs `A XOR TEMPZ` (2 bytes/3 cycles). This budget ends up totalling 6 bytes/8 cycles not including the overhead required to jump into and return from the routine.

This routine is called twice in the program, once within the GETAUGEND routine and once within GETADDEND, since these both use the H5 complement bit.

What if instead, the H5 bit was pre-flipped? It's not used in its ordinary representation anywhere else in the program. There's already a routine that prepares the Horizontal Count byte:

```
GETHCOUNT
 LDA HCOUNT
 CLC
 ADC #24
 STA HCOUNT
 RTS
```

This routine just takes what the user inputs as the X coordinate and adds 24 to get the Horizontal Count. We can add `HCOUNT XOR $20` to this routine and have H5 flipped to H5* from the start:

```
GETHCOUNT
 LDA HCOUNT ; User input [0,39]
 CLC
 ADC #24 ; Add for horizontal count
 EOR #$20 ; flip H5 to H5*
 STA HCOUNT
 RTS
```

This adds 2 bytes/2 cycles and saves a lot more than that.

# References

- "11.9 The Video Display," _The Apple //c Reference Manual Volume 1_, page 233. Apple product A2L4030.
- "The Video Display," _Apple II Reference Manual For //e Only_, page 152. Apple product A2L2005.