@ minimum.S

@ ( -- a-addr )
@ location of the cell containing the number conversion radix

Forthword_ BASE, 0, "base"
    douser_ USER_BASE

@ ( n -- )
@ save base
Forthword_ BASESTORE, 0, "base!"
    push {lr}
    bl BASE
    bl HSTORE
    pop {pc}

@ ( n -- )
@ load base
Forthword_ BASEFETCH, 0, "base@"
    push {lr}
    bl BASE
    hfetch_
    pop {pc}

@ ( -- )
@ set base for number conversion to 2
Forthword_ BIN, 0, "bin"
    two_
    b BASESTORE


@ ( -- )
@ set base for numeric conversion to 10
Forthword_ DECIMAL, 0, "decimal"
    ten_
    b BASESTORE

@ ( -- )
@ set base for number conversion to 16
Forthword_ HEX, 0, "hex"
    doliteral_ 16
    b BASESTORE


@ ( n1 n2 -- n1|n2 )
@ compare two values leave the smaller one
Forthword_ MIN, 0, "min"
  ldm dsp!, {r0}
  cmp r0, tos
  bge 1f
  movs tos, r0
1:
  bx lr

@ ( n1 n2 -- n1|n2 )
@ compare two values, leave the bigger one
Forthword_ MAX, 0, "max"
  ldm dsp!, {r0}
  cmp r0, tos
  blt 1f
  mov tos, r0
1:
  bx lr


@ ( val -- char )
@ convert low byte of val to a printable hex character
Forthword_ NHEX, 0, "#h"
    mov r0, #0x0F
    and tos, r0
    cmp tos, #10
    blo NHEX_NEXT
    add tos, #7

    @ <then>
NHEX_NEXT:
    add tos, #48
    bx lr


@ ( n -- )
@ simple 4 bit hex print
Forthword_ PNIB, 0, ".h"
    push {lr}
    bl NHEX
    bl EMIT
    pop {pc}

@ ( n -- )
@ simple 32 bit hex print
Forthword_ PHEX, 0, ".$"
    push {lr}
    doliteral_ 28
PHEX_BEGIN:
    bl TWOOVER
    rshift_
    bl PNIB
    sub tos, #4
    bne PHEX_BEGIN

    drop_
    dup_
    bl PNIB
    mov tos, #32
    bl EMIT
    pop {pc}

@ ( n1 -- u1 )
@ get the absolute value
Forthword_ ABS, 0, "abs"
  dupzerosense_
  bpl 1f
  neg_
1:
  bx lr

@ ( c -- (number|) flag )
@ tries to convert a character to a number, set flag accordingly
Forthword_ DIGITQ, 0, "digit?"
    sub tos, #0x30
    cmp tos, #10
    blo DIGITQ0
    sub tos, #7
    cmp tos, #10
    bge DIGITQ0

    zerotos_
    bx lr

DIGITQ0:
    dup_
    push {lr}
    bl BASEFETCH
    bl UGREATEREQUAL
    zerosense_
    beq PFA_DIGITQ2
    zerotos_
    pop {pc}

PFA_DIGITQ2:
    true_
    pop {pc}

@ ( u1 u2 -- flag )
@ compare two unsigned numbers, returns true flag if u1 is less then or equal to u2
Forthword_ ULESSEQUAL, 0, "u<="
    push {lr}
    bl UGREATER
    not_
    pop {pc}

@ ( u1 u2 -- flag )
@ compare two unsigned numbers, returns true flag if u1 is greater then or equal to u2
Forthword_ UGREATEREQUAL, 0, "u>="
    push {lr}
    bl ULESS
    not_
    pop {pc}


@ ( -- addr)
@ start address of the data stack
Forthword_ SP0, 0, "sp0"
  pushtos_
  ldr tos, addr_dstack
  bx lr

@ ( -- addr)
@ start address of return stack
Forthword_ RP0, 0, "rp0"
  douser_ rstack0

@ ( -- n )
@ number of single-cell (4 byte) values contained in the data stack before n was placed on the stack.
Forthword_ DEPTH, 0, "depth"
    push {lr}
    bl SP0
    spfetch_
    minus_
    fourslash_
    @ acount for value push on data stack
    oneminus_
    pop {pc}

@ ( --  )
@ check stack underflow, throw exception -4
Forthword_ QSTACK, 0, "?sp"
    push {lr}
    bl DEPTH
    zeroless_
    zerosense_
    beq QSTACKFIN
      @doliteral_ 0xBEF
      one_
      bl THROW

QSTACKFIN:
    pop {pc}



@ USER variable used by catch/throw
Forthword_ HANDLER, 0, "handler"
  douser_ ram_handler

@ ( i*x xt -- j*x 0 | i*x n )
@ setup handler to catch exceptions and then EXEC XT.
Forthword_ CATCH, 0, "catch"
    push {lr}
    @ sp@ >r
    spfetch_            @ ( xt SP )
    to_r_               @ ( xt ) (R: ret -- callerret SP )
    @ handler @ >r
    bl HANDLER          @ ( xt haddr )
    fetch_              @ ( xt hxt )
    to_r_               @ ( xt ) (R: callerret SP hxt )
    @ rp@ handler !
    rpfetch_            @ ( xt RP ) (R: callerret SP hxt)
    bl HANDLER          @ ( xt RP haddr )
    bl STORE            @ ( xt )
    bl EXEC
    @ restore handler
    @ r> handler !
    r_from_             @ ( hxt ) (R: callerret SP )
    bl HANDLER          @ ( hxt haddr )
    bl STORE            @ ( )
    r_drop_             @ ( ) (R: callerret)
    zero_
    pop {pc}

@ ( n -- )
@ throw an exception
Forthword_ THROW, 0, "throw"
    dupzerosense_
    bne THROW1
    drop_
    bx lr

THROW1:
    push {lr}
    bl HANDLER         @ ( n haddr )
    fetch_             @ ( n RP_handler )
    rpstore_           @ ( n ) (R: callerret SP hxt)
    r_from_            @ ( n hxt ) (R: callerret SP )
    bl HANDLER         @ ( n hxt haddr )
    bl STORE           @ ( n )
    r_from_            @ ( n SP ) (R: callerret )
    swap_              @ ( SP n ) (R: callerret )
    to_r_              @ ( SP ) (R: callerret n )
    spstore_           @ ( ... )
    r_from_            @ ( ... n )
    pop {pc}

@ (c -- ) Numeric IO
@ R( -- )
@ set the BASE value depending on the character
@forthword_ SETBASE, 0, "setbase"
SETBASE:        @ ( c -- )
    mov r0, tos
    drop_
    cmp r0, #'$
    bne PFA_SETBASE0
    b HEX

PFA_SETBASE0:
    cmp r0, #'%
    bne PFA_SETBASE1
    b BIN

PFA_SETBASE1:
    cmp r0, #'&
    bne PFA_SETBASE2
    b DECIMAL

PFA_SETBASE2:        @ ( error)
    dup_
    mov tos, r0
    bl EMIT
    two_
    bl THROW

@ ( addr len -- addr' len' )
@ skip a numeric prefix character
@forthword_ PRAEFIX, 0, "praefix"
PRAEFIX:        @ ( adr1 len1 -- adr2 len2 )
    push {lr}
    over_
    cfetch_
    cmp tos, #0x30
    blo PFA_PRAEFIX0
    @ no praefix
    drop_
    pop {pc}

PFA_PRAEFIX0:
    bl SETBASE
    one_
    bl SLASHSTRING
    pop {pc}

@ (addr len -- addr len flag) Numeric IO
@ check for - sign
@ forthword_ NUMBERSIGN, 0, "numbersign"
NUMBERSIGN:        @ ( addr len -- )
    over_          @ ( addr len addr )
    cfetch_        @ ( addr len char )
    cmp tos, #'-
    beq NUMBERSIGN_HASSIGN
      zerotos_
      bx lr

NUMBERSIGN_HASSIGN:
      push {lr}
      to_r_
      one_
      bl SLASHSTRING
      r_from_
      pop {pc}

@ ( u1 c-addr1 len1 -- u2 c-addr2 len2 )
@ convert a string to a number  c-addr2/u2 is the unconverted string
Forthword_ TO_NUMBER, 0, ">num"
    push {lr}
TO_NUMBER_AGAIN:
    dupzerosense_
    beq TO_NUMBER_END
        over_                @ ( u adr len adr)
        cfetch_              @ ( u adr len char)
        bl DIGITQ            @ ( u adr len digit flag)
        zerosense_
        bne TO_NUMBER_CONV
            @ character is not a recognized number
            pop {pc}

TO_NUMBER_CONV:
        tob_                 @ ( u adr len) B: digit
        bl ROT               @ ( adr len u)
        bl BASEFETCH         @ ( adr len u base)
        @bl STAR             @ ( adr len u*base)
        mov r0, tos
        poptos_
        mul tos, r0
        getb_                @ ( adr len u' digit)
        plus_                @ ( adr len u')
        bl RROT              @ ( u' adr len )
        one_
        bl SLASHSTRING
        b TO_NUMBER_AGAIN

TO_NUMBER_END:
    pop {pc}

@ (addr len -- [n] f)
@ convert a string at addr to a number
Forthword_ NUMBER, 0, "num"
  push {lr}
  bl BASEFETCH
  to_r_                   @ ( addr len ) (R: base)
  bl NUMBERSIGN
  to_r_                   @ ( addr len ) (R: base flagsign)
  bl PRAEFIX
  bl NUMBERSIGN           @ ( addr len flagsign2 )
  r_from_                 @ ( addr len flagsign2 flagsign ) (R: base )
  or_                     @ ( addr len flagsign' )
  to_r_                   @ ( addr len ) (R: base flagsign')
  zero_                   @ ( addr len 0 ) starting value
  bl RROT                 @ ( 0 addr len )
  bl TO_NUMBER            @ ( n addr' len' )
  @ check length of the remaining string.
  @ if zero: a single cell number is entered
  zerosense_
  beq PFA_NUMBER1

  @ error in string to number conversion
PFA_NUMBER2:
  nip_                    @ ( addr' )  (R: base flagsign' )
  r_drop_                 @ ( addr' ) (R: base )
  zerotos_                @ ( 0 ) (R: base )
  b PFA_NUMBER5

PFA_NUMBER1:
  drop_                   @ ( n )  (R: base flagsign' )
  @ incorporate sign into number
  r_from_                 @ ( n flagsign' ) (R: base )
  zerosense_
  beq PFA_NUMBER4
  neg_

PFA_NUMBER4:
  true_                   @ ( n true ) (R: base )

PFA_NUMBER5:
  r_from_                 @ ( n true base ) (R: )
  bl BASESTORE            @ ( n true )
  pop {pc}

@ dodefer - execute a deferred word
@ defer setup as:
@ push {lr}
@ bl DODEFER
@ .word deferptr
@ does not return to defer callee
Forthword_ DODEFER, 0, "(def)"
  pushtos_
  mov tos, lr
  sub tos, #1 @ doing memory access, do not want thumb bit
  ldr tos, [tos]
  bl EXEC
  pop {pc}

@ must be last word in core
Forthword_ WIPE, 0, "WIPE"
    push {lr}
    @ reset forth dictionary, here, edp, dp to original burn state
    @ set EE_DP to DPSTART
    @doliteral_ pm(DPSTART)
    @doliteral_ EE_DP
    @rcall STOREE
    @ set EE_HERE to HERESTART
    @doliteral_ HERESTART
    @doliteral_ EE_HERE
    @rcall STOREE
    @ set EE_EDP to EDPSTART
    @doliteral_ EDPSTART
    @doliteral_ EE_EDP
    @rcall STOREE
    @ set EE_TURNKEY to NOOP
    @doliteral_ pm(NOOP)
    @doliteral_ EE_TURNKEY
    @rcall STOREE
    @ set EE_FORTHWORDLIST to 0
    @rcall ZERO
    @doliteral_ EE_FORTHWORDLIST
    @pushtos_
    @ldr tos, EE_FORTHWORDLIST_P1
    bl ICFETCH
    .word EE_FORTHWORDLIST
    dup_
    bl ZEROSTORE
    fourplus_
    bl ZEROSTORE
    pop {pc}
