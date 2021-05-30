;*******************************************************************************
; Based on disassembly of original loader.s19                    <tonyp@acm.org>
; Minor refactoring and size optimizations [-13 bytes]
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

SPE                 equ       $40                 ;SPI Interrupt Enable
MSTR                equ       $10                 ;Master Mode Select
SPR1                equ       $02                 ;SPI Rate Select bit 1
SPR0                equ       $01                 ;SPI Rate Select bit 0

RDRF                equ       $20                 ;Receive Data Register Full Flag

EE25016_SS          equ       $20                 ;EEPROM chip select

;*******************************************************************************
                    #RAM      $0000
;*******************************************************************************

addr                rmb       2
addr_msb            equ       addr,1
addr_lsb            equ       addr+1,1
value               rmb       1

;*******************************************************************************
                    #ROM      $0000
;*******************************************************************************
                    #Hint     Original's ASM11 CRC: $1D9E (141 bytes, RAM: 3)

Start               proc
                    clrd
                    std       addr
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
                    decd
                    bne       _1@@
DELAY@@             equ       3329*BUS_KHZ/100/:cycles
          ;--------------------------------------
                    jmp       EEPROM

_2@@                lda       [SCDR,x
                    sta       value
                    bsr       EE25016_Act
                    lda       value
                    sta       [SCDR,x
                    pshx
                    ldx       addr
                    inx
                    stx       addr
                    pulx
                    bra       Loop@@

;*******************************************************************************

EE25016_Act         proc
                    bsr       EE25016_Enable
                    lda       #6
                    bsr       EE25016_WriteRead
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
                    bsr       EE25016_Enable
                    lda       #3
                    bsr       EE25016_WriteRead
                    lda       addr_msb
                    bsr       EE25016_WriteRead
                    lda       addr_lsb
                    bsr       EE25016_WriteRead
                    bsr       EE25016_WriteRead
                    sta       value
;                   bra       EE25016_Disable

;*******************************************************************************

EE25016_Disable     proc
                    bset      [PORTD,x,EE25016_SS
                    rts

;*******************************************************************************

EE25016_Enable      proc
                    bclr      [PORTD,x,EE25016_SS
                    rts

;*******************************************************************************

EE25016_WriteRead   proc
                    sta       [SPDR,x
                    brclr     [SPSR,x,SPIF,*
                    lda       [SPDR,x
                    rts
