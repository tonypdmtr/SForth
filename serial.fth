( serial routines - uses polling methods to communicate )
hex
102b constant BAUD
102e constant SCSR2
102f constant SCDR

( set baud rate without disturbing other switches in BAUD - see HC11
  REFERENCE manual for details )
: SET_BAUD BAUD swap over c@ f8 and + swap c! ;

( another version of SEND.  Assumes SCDR is empty at start and waits until
 it is empty after data is stored in SCDR )
: SEND  SCDR c! 40 SCSR2 begin over over c@ and until drop drop ;

( Polls SCSR2 until it says that there is data waiting in SCDR - then
 it gets it and puts it on the stack )
: RECEIVE 20 SCSR2 begin dup c@ over and until drop drop SCDR c@ ;
