;*******************************************************************************
;* Language  : Motorola/Freescale/NXP 68HC11 Assembly Language (aspisys.com/ASM11)
;*******************************************************************************

;-------------------------------------------------------------------------------
; EQUATES
;-------------------------------------------------------------------------------

WREN                equ       6
RDSR                equ       5
MASKCE              equ       $20
DDRD                equ       9
PORTD               equ       8
SPCR                equ       $28
SPSR                equ       $29
SPDR                equ       $2a
IPH                 equ       0
IPL                 equ       1
CI                  equ       2
EEDAT               equ       3
IP                  equ       0
RP                  equ       4
RP0                 equ       5
SP0                 equ       $4f

EEPROM              def       $B600
MY_BASE             def       EEPROM

;*******************************************************************************
                    #ROM
;*******************************************************************************
                    org       MY_BASE

INIT                proc
                    lds       #SP0                ; initialize SP
                    ldy       #$1000
                    lda       #$3f
                    sta       DDRD,y
                    lda       #$50
                    sta       SPCR,y
                    lda       SPSR,y
                    clrx
                    stx       IP                  ; initialize IP
                    lda       #RP0
                    sta       RP                  ; initialize RP
                    jmp       NEXT

;*******************************************************************************
; SEEPROM routines from MICROCHIP application notes AN609

READ                proc
                    bsr       CELOW
                    lda       #3
                    bsr       SEND
                    lda       IPH
                    bsr       SEND
                    lda       IPL
                    bsr       SEND
                    bsr       SEND
                    sta       EEDAT
                    bra       CEHIGH

;*******************************************************************************

WRITE               proc
                    bsr       CELOW
                    lda       #WREN
                    bsr       SEND
                    bsr       CEHIGH
                    bsr       CELOW
                    lda       #2
                    bsr       SEND
                    lda       IPH
                    bsr       SEND
                    lda       IPL
                    bsr       SEND
                    lda       EEDAT
                    bsr       SEND
                    bsr       CEHIGH
Loop@@              bsr       CELOW
                    lda       #RDSR
                    bsr       SEND
                    bsr       SEND
                    bsr       CEHIGH
                    anda      #1
                    bne       Loop@@
                    rts

;*******************************************************************************

SEND                proc
                    sta       SPDR,y
                    brclr     SPSR,y,$80,*
                    lda       SPDR,y
                    rts

;*******************************************************************************

CELOW               proc
                    bclr      PORTD,y,MASKCE
                    rts

;*******************************************************************************

CEHIGH              proc
                    bset      PORTD,y,MASKCE
                    rts

;*******************************************************************************
; push ACCX on the return stack

RPUSH               proc
                    ldb       RP
                    clra
                    xgdx
                    std       ,x
                    inx:2
                    xgdx
                    stb       RP
                    rts

;*******************************************************************************
; pop return stack into ACCX

RPOP                proc
                    ldb       RP
                    clra
                    xgdx
                    dex:2
                    ldd       ,x
                    xgdx
                    stb       RP
                    rts

;*******************************************************************************
; ( addr -- data ) fetch 1 byte from SEPROM address

EELOD               proc
                    pulx                          ; get address
                    ldd       IP                  ; save IP
                    stx       IP                  ; put address in IP
                    xgdx                          ; ACCX holds IP
                    bsr       READ                ; read SEEPROM
                    ldb       EEDAT               ; put data in ACCB
                    clra                          ; only a byte, so clear ACCA
                    stx       IP                  ; restore IP
                    jmp       PUSHD               ; push ACCD

;*******************************************************************************
; ( data addr -- ) store 1 byte in SEEPROM

EESTO               proc
                    pulx                          ; get ADDRESS
                    puld                          ; get data
                    stb       EEDAT               ; store byte to be written in EEDAT
                    ldd       IP                  ; save IP
                    xgdx                          ; ACCX holds IP
                    std       IP                  ; store address in IP
                    bsr       WRITE               ; write to SEEPROM
                    stx       IP                  ; restore IP
                    jmp       NEXT

;*******************************************************************************
; ( n addr -- ) add n to data in addr

PSTO                proc
                    pulx
                    puld
                    addd      ,x
                    std       ,x
                    jmp       NEXT

;*******************************************************************************
; ( -- SP ) return current stack pointer

SPAT                proc
                    tsx
                    jmp       PUSHX

;*******************************************************************************
; ( -- ) enable interrupts

E_INT               proc
                    cli
                    jmp       NEXT

;*******************************************************************************
; ( -- ) disable interrupts

D_INT               proc
                    sei
                    jmp       NEXT

;*******************************************************************************
; ( bitmask addr -- ) set bits at addr - bit mask has 1's
;                     in position to be set

BIT_SET             proc
                    pulx
                    pulb:2
                    orb       ,x
                    stb       ,x
                    jmp       NEXT

;*******************************************************************************
; ( bismask addr -- ) clr bits at addr - bit mask has 1's in position
;                     to be cleared

BIT_CLR             proc
                    pulx
                    pulb:2
                    comb
                    andb      ,x
                    stb       ,x
                    jmp       NEXT

;*******************************************************************************
; ( addr -- ) executes a user routine at address on top of the stack
;             routine must end in JUMP to NEXT, PUSHD or PUSHX

EXEC                proc
                    pulx
                    jmp       ,x

;*******************************************************************************
;                   org       $B6E8
;*******************************************************************************

;*******************************************************************************
; fetch 1 byte from SEEPROM using instruction pointer as address.
; update the instruction pointer

FETCH               proc
                    jsr       READ
                    ldx       IP
                    inx
                    stx       IP
                    ldb       EEDAT
                    rts

;*******************************************************************************
; fetch 2 bytes from SEEPROM  return them in ACCX

F2                  proc
                    bsr       FETCH               ;WAS: jsr
                    stb       CI
                    bsr       FETCH               ;WAS: jsr
                    lda       CI
                    xgdx
                    rts

;*******************************************************************************
                    align     $100                ;WAS: org $B700
;*******************************************************************************

;*******************************************************************************
; used to call words in page $B6

EXT                 proc
                    bsr       FETCH
                    lda       #]MY_BASE
                    ldb       EEDAT
                    xgdx
                    jmp       ,x

;*******************************************************************************
; puts 2 bytes on stack

LIT                 proc
                    bsr       F2
                    bra       PUSHX

;*******************************************************************************
; branch to an address

BR                  proc
                    bsr       F2
                    stx       IP
                    bra       NEXT

;*******************************************************************************
; if TOS=0 then branch else skip 2

ZBR                 proc
                    pulx
                    cpx       #0
                    beq       BR
                    ldx       IP
                    inx:2
                    stx       IP
                    bra       NEXT

;*******************************************************************************
; call a subroutine

CAL                 proc
                    ldx       IP
                    inx:2
                    jsr       RPUSH
                    bra       BR

;*******************************************************************************
; return from a subroutine

RET                 proc
                    jsr       RPOP
                    stx       IP
                    bra       NEXT

;*******************************************************************************
; ( addr -- word ) loads stack with a word from addr

LOD                 proc
                    pulx
                    ldd       ,x
                    bra       PUSHD

;*******************************************************************************
; ( addr -- byte ) loads stack with a byte from addr

CLOD                proc
                    pulx
                    ldb       ,x
                    clra
                    bra       PUSHD

;*******************************************************************************
; ( word addr -- ) stores word from stack in addr

STO                 proc
                    pulx
                    puld
                    std       ,x
                    bra       NEXT

;*******************************************************************************
; ( byte adr -- ) stores byte from stack in addr

CSTO                proc
                    pulx
                    puld
                    stb       ,x
                    bra       NEXT

;*******************************************************************************
; ( n2 n1 -- n1 n2 ) swaps top two numbers on the stack

SWAP                proc
                    pulx
                    puld
                    xgdx
                    pshd
                    bra       PUSHX

;*******************************************************************************
; ( n1 -- ) drops the top of the stack

DROP                proc
                    pulx
                    bra       NEXT

;*******************************************************************************
; ( n1 -- n1 n1 ) copies the top of the stack

DUP                 proc
                    pulx
                    pshx
                    bra       PUSHX

;*******************************************************************************
; ( n2 n1 -- n2 n1 n2 ) copies the next on the stack to the top of the stack

OVER                proc
                    puld
                    pulx
                    pshx
                    pshd
                    bra       PUSHD

;*******************************************************************************
; (n2 n1 -- r q ) n2/n1  remainder on top, followed by the quotient

DIV                 proc
                    pulx
                    puld
                    idiv
                    pshx
                    bra       PUSHD

;*******************************************************************************
; ( n2 n1 -- prod ) n1*n2 leaves product NOTE: THIS ROUTINE ONLY MULTIPLIES
;                                              THE LSB OF n1 AND n2

MULT                proc
                    pulb:2
                    pula:2
                    mul
                    bra       PUSHD

;*******************************************************************************
; ( n1 n2 -- sum ) n1+n2

ADD                 proc
                    puld                          ;WAS: pulx, xgdx
                    tsx
                    addd      ,x
                    pulx

;*******************************************************************************
; inner interpreter - fetches a byte in SEEPROM  and jumps to that address
;                     on page $B7
;
; push ACCD

PUSHD               proc
                    xgdx

;*******************************************************************************
;
; push ACCX

PUSHX               proc
                    pshx

NEXT                jsr       FETCH
                    lda       #]MY_BASE+1
                    xgdx
                    jmp       ,x

;*******************************************************************************
; "-" ( n2 n1 -- diff ) n2-n1

SUB                 proc
                    pulx
                    puld                          ;WAS: xgdx, pulx, xgdx
                    pshx
                    tsx
                    subd      ,x
                    pulx
                    bra       PUSHD

;*******************************************************************************
; ( n1 -- ~n1 ) 1's complement of n1

NOT                 proc
                    puld
?NOT                comd
                    bra       PUSHD

;*******************************************************************************
; ( n1 -- -n1 ) 2's complement of n1

NEG                 proc
                    pulx
                    dex
                    xgdx
                    bra       ?NOT

;*******************************************************************************
; ( n2 n1 -- T|F ) if n1=n2 then put $FFFF on the stack else put 0

EQ                  proc
                    puld
                    tsx
                    cpd       ,x
                    beq       TRUE

;-------------------------------------------------------------------------------

FALSE               proc
                    pulx
                    clrd
                    bra       PUSHD

;*******************************************************************************
; ( n2 n1 -- T|F ) true if n2>n1

GT                  proc
                    puld
                    tsx
                    cpd       ,x
                    bhs       FALSE

;-------------------------------------------------------------------------------

TRUE                proc
                    pulx
                    ldd       #$ffff
                    bra       PUSHD

;*******************************************************************************
; ( n2 n1 -- T|F ) true if n2<n1

LT                  proc
                    puld
                    tsx
                    cpd       ,x
                    bls       FALSE
                    bra       TRUE

;*******************************************************************************
; ( n1 -- ) pushes n1 onto return stack

RTO                 proc
                    pulx
                    jsr       RPUSH
                    bra       NEXT

;*******************************************************************************
; ( -- n1 ) pops n1 off return stack to data stack

RFROM               proc
                    jsr       RPOP
                    bra       PUSHX

;*******************************************************************************
; ( -- n1 ) copies the top of the return stack to data stack

RAT                 proc
                    jsr       RPOP
                    jsr       RPUSH
                    bra       PUSHX

;*******************************************************************************
; ( n2 n1 -- n2&n1 ) logical n1 AND n2

AND                 proc
                    puld
                    tsx
                    anda      ,x
                    andb      1,x
?AND                pulx
                    bra       PUSHD

;*******************************************************************************
; ( n2 n1 -- n2|n1 ) logical n1 OR n2

OR                  proc
                    puld
                    tsx
                    ora       ,x
                    orb       1,x
                    bra       ?AND

;*******************************************************************************
; ( n2 n1 -- n2^n1 ) logical n1 XOR n2

XOR                 proc
                    puld
                    tsx
                    eora      ,x
                    eorb      1,x
                    bra       ?AND

;*******************************************************************************
; ( n1 -- n1+1 ) increment n1 by 1

INC                 proc
                    pulx
                    inx
                    bra       PUSHX

;*******************************************************************************
; ( n1 -- n1-1 ) decrement n1 by 1

DEC                 proc
                    pulx
                    dex
                    bra       PUSHX

;*******************************************************************************
; ( -- ) powers down MPU until a reset, IRQ or XIRQ

HALT                proc
                    tpa
                    anda      #$7f
                    tap
                    nop
                    stop
                    jmp       INIT

;*******************************************************************************
; ( n1 -- 2*n1 ) double TOS

DBL                 proc
                    pulx
                    xgdx
                    lsld
                    jmp       PUSHD
