;*******************************************************************************
; Disassembly of original loader.s19                             <tonyp@acm.org>
;*******************************************************************************

BUS_HZ              def       2000000             ;E-clock bus speed in Hz
BUS_KHZ             equ       BUS_HZ/1000         ;E-clock bus speed in KHz

REGS                equ       $1000
PORTD               equ       REGS+$08,1          ;Port D Data
DDRD                equ       REGS+$09,1          ;Data Direction Register D
SPDR                equ       REGS+$2A,1          ;SPI Data Register
SPCR                equ       REGS+$28,1          ;SPI Control Register
SPSR                equ       REGS+$29,1          ;SPI Status Register
SCSR                equ       REGS+$2E,1          ;SCI Status Register
SCDR                equ       REGS+$2F,1          ;SCI Data Register

EEPROM              equ       $B600               ;Start of EEPROM

SPIF                equ       $80                 ;SPI Interrupt Status Flag

SPIE                equ       $80                 ;SPI Control Register
SPE                 equ       $40                 ;SPI Interrupt Enable
DWOM                equ       $20                 ;Port D Wire-Or Mode
MSTR                equ       $10                 ;Master Mode Select
CPOL                equ       $08                 ;Clock Polarity
CPHA                equ       $04                 ;Clock Phase
SPR1                equ       $02                 ;SPI Rate Select bit 1
SPR0                equ       $01                 ;SPI Rate Select bit 0

RDRF                equ       $20                 ;Receive Data Register Full Flag

EE25016_SS          equ       $20                 ;EEPROM chip select

;*******************************************************************************
                    #RAM      $0000
;*******************************************************************************

addr_msb            rmb       1
addr_lsb            rmb       1
value               rmb       1

;*******************************************************************************
                    #ROM      $0000
;*******************************************************************************
                    #Hint     Original's ASM11 CRC: $1D9E

Start               proc
                    ldd       #0
                    std       addr_msb
                    ldx       #REGS
                    lda       #SPE|MSTR|SPR1|SPR0 ; E-clock divide by 32 (62.5KHz @2MHz)
                    sta       [SPCR,x
                    lda       [DDRD,x
                    ora       #%00111111
                    sta       [DDRD,x
          ;-------------------------------------- ; wait for ready with timeout
Loop@@              ldd       #DELAY@@            ; 33.29 msec (as in original code)
                              #Cycles
_1@@                brset     [SCSR,x,RDRF,_2@@
                    xgdx
                    dex
                    xgdx
                    bne       _1@@
DELAY@@             equ       3329*BUS_KHZ/100/:cycles
          ;--------------------------------------
                    bra       _3@@

_2@@                lda       [SCDR,x
                    sta       value
                    jsr       EE25016_Act1
                    jsr       EE25016_Act2
                    lda       value
                    sta       [SCDR,x
                    ldy       addr_msb
                    iny
                    sty       addr_msb
                    bra       Loop@@

_3@@                jmp       EEPROM

;*******************************************************************************

EE25016_Act2        proc
                    bsr       EE25016_Enable
                    lda       #3
                    bsr       EE25016_WriteRead
                    lda       addr_msb
                    bsr       EE25016_WriteRead
                    lda       addr_lsb
                    bsr       EE25016_WriteRead
                    bsr       EE25016_WriteRead
                    sta       value
                    bsr       EE25016_Disable
                    rts

;*******************************************************************************

EE25016_Act1        proc
                    bsr       EE25016_Enable
                    lda       #6
                    jsr       EE25016_WriteRead
                    bsr       EE25016_Disable
                    bsr       EE25016_Enable
                    lda       #2
                    bsr       EE25016_WriteRead
                    lda       addr_msb
                    bsr       EE25016_WriteRead
                    lda       addr_lsb
                    bsr       EE25016_WriteRead
                    lda       value
                    bsr       EE25016_WriteRead
                    bsr       EE25016_Disable
          ;--------------------------------------
Loop@@              bsr       EE25016_Enable
                    lda       #5
                    bsr       EE25016_WriteRead
                    bsr       EE25016_WriteRead
                    bsr       EE25016_Disable
                    anda      #%1
                    bne       Loop@@
          ;--------------------------------------
                    rts

;*******************************************************************************

EE25016_WriteRead   proc
                    sta       [SPDR,x
                    brclr     [SPSR,x,SPIF,*
                    lda       [SPDR,x
                    rts

;*******************************************************************************

EE25016_Enable      proc
                    bclr      [PORTD,x,EE25016_SS
                    rts

;*******************************************************************************

EE25016_Disable     proc
                    bset      [PORTD,x,EE25016_SS
                    rts
