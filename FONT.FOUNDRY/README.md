# Font Foundry

*Font Foundry* by Doug Hennig was published in *Nibble* Magazine (November 1986) and collected in *Nibble Express Volume 7* (page 220).

The program consists of three mandatory parts:

1. `CHAR.ED`, an Applesoft program that implements a character set editor.
2. `CHAR.GEN`, an assembly/machine language program that attaches runtime "ampersand" commands to Applesoft.
3. `NORMAL.SET`, the standard character set with additional useful glyphs in an alternate set.

These programs are not reproduced here as they are not necessarily subject to the same license as this repository.

The program is available for free download from the Nibble Magazine website, where a complete collection of Nibble Disks can be downloaded.

Doug Hennig's The Font Foundry can be found on disk 29 in this collection (`NIB29B.DSK`).

# CHARACTER.SETS

A character set is a table of bytes starting at $9000 and continuing for 768 bytes. Multiple tables can be concatenated to represent larger character sets, and each alternate set should be equivalent in size and structure.

*The Hennig program uses 1536 byte tables to support a primary and alternate character set. In his approach, the high byte of the table start address is modified directly ($90 by default, $93 for the alternate set).*

The structure of a character set table is that each character gets 8 bytes to describe it, and each of these bytes defines 1 line of the glyph. The index of the character within the table is the ASCII code of the character minus 32.

The first character at index 0, then, is ASCII $20 (SPACE) and should usually be eight bytes of $00. The last character at index 95 is (95 * 8 = 760) bytes from the table start address and is ASCII $7F (DELETE) which is usually the word `00201008043E0000`.

*Technically SPACE is a printable character that you could overload with any glyph you wanted, but not DELETE. Character set editors may or may not allow editing SPACE but none should allow editing DELETE.*

Each character is designed on a 7x8 grid of dots. The letter "A" may be represented as:

```
...X...
..X.X..
.X...X.
.X...X.
.XXXXX.
.X...X.
.X...X.
.......
```

Not only is there blank space on either side (to provide air between adjacent characters on screen), there is blank space at the bottom (to provide air between adjacent lines). Characters that extend into these "margins" can expect to connect to their neighbors. This is key for creating repeating patterns and ligatures in graphical characters, but not ideal for text.

The 8-byte word for "A" in the `NORMAL.SET` is `08 14 22 22 3E 22 22 00`. There are only 8 bytes but 56 dots that make up the "A". The way a byte is turned into a set of dots on screen is described by the Apple II Technical reference. Know that for each byte, the high bit is discarded (used for determining color palette but not drawing) and subsequent bits are either on or off, and the byte read from right to left correspond to screen dots left to right.

The first row of the "A" character `...X...` is plotted as binary from right to left as `00001000` after adding an 8th bit. This byte value is `08`. So there is no magic in character set tables; they are pure bitmaps of glyphs to be drawn, one byte at a time, 8 bytes per screen "cell" or text character.

*We expect the line of the "A" with the cross-bar to be the `3E` byte: `.XXXXX.` is `00111110` so we're right!*

It would be tedious but possible to transcribe a set of character glyphs as bits and bytes after sketching them, perhaps, on graph paper, but an editor like Hennig's `CHAR.ED` makes the job so much nicer.

## GOLDBOX.SET

A character set for `CHAR.GEN` that clones the screen font used in the SSI "Gold Box" games, e.g., *Pool of Radiance*.

# High Resolution Character Generation

Hennig's work is not the first or last word on High Resolution Character Generation, but it is a fairly full-featured implementation of the pattern.

Another implementation is discussed at length in Chapter 31 of Wagner's *Assembly Lines* (AL31). I suspect Hennig and others have borrowed and repeated the patterns from this book.

There are useful commonalities between Hennig, Wagner, and even the early ANIMATRIX program from the Apple DOS Toolkit:

* Character sets start at address $9000
* Each character is assigned 8 bytes
* Each character is indexed by its ASCII code - 32
* There are 96 characters in the set (96 * 8 = 768)
* The character set is 768 ($300) bytes in length.

This means you can take a `.SET` file from the Toolkit disk and load it in Font Foundry, or take a Font Foundry `.SET` file and load it in ANIMATRIX[^1], and use `.SET` files from either with Wagner's AL31 routine.

[^1]: This statement needs to be qualified. Font Foundry writes 1536-byte character sets because an "alternate" is concatenated. A simple `BLOAD CHARACTER.SET : BSAVE CHARACTER.SET,$A9000,L$300` will chop off the second set and make it compatible with ANIMATRIX.

## Wagner's AL31

Wagner's AL31 routine establishes a simple, short pattern for printing high-resolution character sets.

* Load a character set table at address $9000.
* Hook your routine into the $36.$37 CSW (Character output SWitch) vector.
* Subtract 32 from the value of the character being sent to output.
* Multiply the result by 8 to get an offset value for the character set table.
* Load the 8 bytes at the character set table offset and put them on the HGR1 screen.
* Exit by JMPing to the normal COUT1 routine.

Part of what makes this program work so easily is that it creates a correspondence between the text screen and the HGR screen. Specifically, it uses the cursor position on the text screen to determine the appropriate address for the HGR screen. This means that the characters "printed" to the HGR screen are also being printed to the text screen![^2] This is also why `HTAB`, `VTAB`, and `HOME` work to position the "cursor" on the high-res screen and why `PRINT` works to produce output.

[^2]: This is why sometimes when you exit an HGR program it appears that all the screen element have turned into ASCII characters. They haven't changed, they were just there the whole time.

A modified AL31 program is in this repository (`AL31.CHARGEN`). It is optimized with 65C02 opcodes and is a little shorter and a little faster than Wagner's original.
