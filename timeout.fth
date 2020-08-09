( TIMEOUT - this demonstrates using SFORTH to process an interrupt
            TSR is the interrupt service routine.  Move it to ISR,
            an array.  Store $7E [jmp] ISR's address in $D0,$D1,$D2
            - the vector for the timer overflow interrupt.  When TOI,
            Time Out Interrupt [bit 7 in TMSK2] and the Interrupt
            enable bit in CCR [using E_INT] are set, ISR will be
            called every time the main timer overflows. )
hex
102b constant BAUD
102f constant SCDR
102e constant SCSR
1024 constant TMSK2
1025 constant TFLG2
09 array ISR  ( reserve space for TSR )

( this routine resets the timer overflow flag
  and toggles portb on and off )

09 data TSR     86 80           ( LDAA #$80  -the Timer overflow must be )
                b7 10 25        ( STAA $1025 -reset before returning )
                73 10 04        ( COMA $1004 -toggle PORTB )
                3b              ( RTI        - return from interrupt)

: send  begin scsr c@ 80 and until scdr c! ;

( EMOVE gets data from the SEEPROM and stores it in RAM )
: emove for
                over over
                ee@ swap c!
                swap 1+
                swap 1+
        next
        drop drop
;
: MAIN  ISR TSR 09 emove ( store interrupt service routine in ISR )

        7e d0 c!
        ISR d1 !         ( store jmp <ISR> at TOF interrupt vector )

        0 TMSK2 c!       ( prescaler for overflow is 16 [every 1.049 sec] )

        80 TMSK2 bit_set ( enable interrupt on overflow )

        e_int            ( enable global interrupt )

        begin
                41 send  ( send "A" thru SCI port )
                0        ( put FALSE on the stack so interpreter will )
        until ;          ( loop forever )
