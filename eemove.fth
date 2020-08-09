( src dst cnt -- )
( Moves cnt bytes of data from src in SEEPROM to dst in RAM.  Useful
 in moving information stored with DATA to RAM.  Note that this is not
 a particularly fast routine.  You may not want to use this too many
 times in your main program. )
: eemove
        for
                over over
                ee@ swap c!
                swap 1+
                swap 1+
        next
        drop drop
;
