********************************
*   AL31-CHARACTER GENERATOR   *
********************************
* Modified for 65C02 Operation *
********************************
*
*
 XC
 ORG $300
*
CSW EQU $36
BASL EQU $28 ; Current Text Cursor Row Address
BASH EQU $29
CH EQU $24 ; Cursor Column Position
TABLE EQU $9000
POSN EQU $3C
SCRN EQU $3E
VECT EQU $3EA
COUT1 EQU $FDF0
PAGE EQU $07
*
HOOK
 LDA #ENTRY
 STA CSW
 LDA #>ENTRY
 STA CSW+1
 JMP VECT
*
ENTRY
 CMP #$A0
 BCC OUT
 PHY ; original Y register
 PHA ; original input 
 AND #$7F ; clear high bit
 STZ POSN+1
*
CALC1
 SEC
 SBC #$20
*
 ASL A ; multiply by 2
 ASL A ; multiply by 2
 ROL POSN+1
 ASL A ; multiply by 2 = multiply by 8
 ROL POSN+1
*
* POSN = (ASC - $20)*8 BYTES PER CHAR
*
 CLC
 ADC #TABLE ; add #TABLE to POSN already on A
 STA POSN
 LDA #>TABLE
 ADC POSN+1
 STA POSN+1
*
CALC2
 CLC
 LDA BASL
 ADC CH
 STA SCRN
 LDA BASH
*
* Add $1C00 to Text screen address to "lift" the address
* to the highres page ($0400 + $1C00 = $2000).
* Add $3C00 to lift to highres page 2
 ADC #$1C
 STA SCRN+1
*
GETBYTE
 LDY #$00
G1
 LDA (POSN),Y ; load current byte of glyph
 STA (SCRN),Y ; place current byte on screen
INC
 INY ; next byte
 CLC
 LDA SCRN
 ADC #$FF ; next line address L
 STA SCRN
 LDA SCRN+1
 ADC #$03 ; next line address H
 STA SCRN+1
*
* $3FF TO MAKE UP FOR GROWING VALUE OF 'Y'
*
DONE?
 CPY #$08
 BCC G1
*
YES
 PLY ; Restore Y register
 PLA ; Restore original Accumulator
OUT
 JMP COUT1
