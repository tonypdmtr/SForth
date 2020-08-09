HEX
load eemove.fth
102d constant SCCR2
102E CONSTANT SCSR ( address of SCSR register )

102F CONSTANT SCDR ( address of SCDR register )
cvariable SDAT
9 DATA SCI      ( this program resets the interrupt flag and stores the data
                  from the SCI buffer in SDAT )
                b6 10 2e ( ldaa SCSR *this sequence of events )
                b6 10 2f ( ldaa SCDR *resets the interrupt flag )
                97 50    ( staa sdat *store key pressed at ram address $50 )
                3b       ( rti )
9 array ISR     ( this is where the interrupt routine will reside in
                  RAM )
: SCI_INIT
        ISR ( to )
        SCI ( from )
        9 ( 9 bytes )
        eemove ( move 'em )
        7e c4 c! ISR c5 ! ( jmp ISR is stored in interrupt vector )
        20 SCCR2 BIT_SET ( set interrupt on recieved data flag )
        ;
: OUT SCDR C! BEGIN SCSR C@ 80 AND UNTIL ;
( store data from the stack in SCI transmit register, poll status register
until transmit complete flag set )

: MAIN SCI_INIT e_int begin sdat c@ out 0 until ;
( send data in SDAT out on SCI at 1200 baud )
