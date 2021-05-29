This file contains SFORTH, a Forth compiler for the 68HC11 microcontoller.
SFORTH is designed to compile a Forth program on your PC and then download it
to a serial EEPROM for storage.  You will have to build your own HC11 circuit,
see the circuit diagram in CIRCUIT.JPG and instructions in CIRCUIT.DOC.

        Files included in SFORTH:

        SFORTH.COM      -       The SFORTH compiler
        LOADER.COM      -       The 68HC11 loader program
        LOADER.S19      -       Program needed by LOADER.COM
        SFORTH.DOC      -       Manual
        CIRCUIT.DOC     -       Notes on building a circuit
        CIRCUIT.JPG     -       A circuit diagram that can be read by Windows
        SERIAL.FTH      -       An SFORTH program example
        TIMEOUT.FTH     -       An SFORTH program example
        SERINT.FTH      -       An SFORTH program example
        EEMOVE.FTH      -       An SFORTH program example
        SFORTH.ASM      -       Source for SFORTH
        SFORTH.S19      -       SFORTH in Motorola hex
                                (produced by running ASM11 SFORTH)

I'm placing SFORTH in the PUBLIC DOMAIN.  Do with it what you want.  If you
find it useful, you might send me $15 to keep research and developement going
(after all I'm only a high school math teacher, you know how little we make).
Send any comments, questions, bugs, cash to:

                CHRIS BURNS
                P.O.BOX 1352
                OGLETHORPE, GA 31068
                U.S.A.

I may also be reached at my e-mail address of: MWALIMU@GNAT.NET

Enjoy.

---
P.S. by Tony P. <tonyp@acm.org>

Use ASM11 to assemble the source: http://www.aspisys.com/asm11.htm

The .COM utilities came with no source.  They will run under a DOSBox emulator.
