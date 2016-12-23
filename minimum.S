@ minimum.S

@ ( -- a-addr )
@ location of the cell containing the address of the next free ram location
Forthword_ HEREADDR, 0, "here#"
    douser_ USER_HERE

@ ( -- a-addr )
@ the address of the next free ram location
Forthword_ HERE, 0, "here"
    push {lr}
    bl HEREADDR
    fetch_
    pop {pc}

@ ( -- a-addr )
@ location of the cell containing the number conversion radix
Forthword_ BASE, 0, "base"
    douser_ USER_BASE

@ ( n -- )
@ save base
Forthword_ BASESTORE, 0, "base!"
    push {lr}
    bl BASE
    pop_lr_
    b HSTORE

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
    b.n BASESTORE


@ ( -- )
@ set base for numeric conversion to 10
Forthword_ DECIMAL, 0, "decimal"
    ten_
    b.n BASESTORE

@ ( -- )
@ set base for number conversion to 16
Forthword_ HEX, 0, "hex"
    dolit8_ 16
    b.n BASESTORE


@ ( n1 n2 -- n1|n2 )
@ compare two values leave the smaller one
Forthword_ MIN, 0, "min"
  ldm dsp!, {r0}
  cmp r0, tos
  bge.n 1f
  movs tos, r0
1:
  bx lr

@ ( n1 n2 -- n1|n2 )
@ compare two values, leave the bigger one
Forthword_ MAX, 0, "max"
  ldm dsp!, {r0}
  cmp r0, tos
  blt.n 1f
  mov tos, r0
1:
  bx lr


@ ( val -- char )
@ convert low byte of val to a printable hex character
Forthword_ NHEX, 0, "#h"
    movs r0, #0x0F
    ands tos, r0
    cmp tos, #10
    blo.n NHEX_NEXT
    adds tos, #7

    @ <then>
NHEX_NEXT:
    adds tos, #48
    bx lr


@ ( n -- )
@ simple 4 bit hex print
Forthword_ PNIB, 0, ".h"
    push {lr}
    bl NHEX
    pop_lr_
    b EMIT

@ ( n -- )
@ simple 32 bit hex print
Forthword_ PHEX, 0, ".$"
    push {lr}
    dolit8_ '$
    bl EMIT
    dolit8_ 28
PHEX_BEGIN:
    bl TWOOVER
    rshift_
    bl PNIB
    subs tos, #4
    bne.n PHEX_BEGIN

    drop_
    dup_
    bl PNIB
    movs tos, #32
    pop_lr_
    b EMIT

@ ( n1 -- u1 )
@ get the absolute value
Forthword_ ABS, 0, "abs"
  dupzerosense_
  bpl.n 1f
  neg_
1:
  bx lr
  

@ ( c -- (number|) flag )
@ tries to convert a character to a number, set flag accordingly
Forthword_ DIGITQ, 0, "digit?"
    subs tos, #0x30
    cmp tos, #10
    blo.n DIGITQ0
    subs tos, #7
    cmp tos, #10
    bge.n DIGITQ0

    zerotos_
    bx lr

DIGITQ0:
    dup_
    push {lr}
    bl BASEFETCH
    bl UGREATEREQUAL
    zerosense_
    beq.n PFA_DIGITQ2
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
    beq.n QSTACKFIN
      @doliteral_ 0xBEF
      $lit_ " Stack Underflow!"
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

@ ( straddr len -- )
@ throw an exception
@ will type the string passed in
Forthword_ THROW, 0, "throw"
    push {lr}
    bl TYPE
    bl HANDLER         @ ( haddr )
    fetch_             @ ( RP_handler )
    rpstore_           @ ( ) (R: callerret SP hxt)
    r_from_            @ ( hxt ) (R: callerret SP )
    bl HANDLER         @ ( hxt haddr )
    bl STORE           @ ( )
    r_from_            @ ( SP ) (R: callerret )
    spstore_           @ ( ... )
    one_               @ ( ... 1 )
    pop {pc}

@ (c -- ) Numeric IO
@ R( -- )
@ set the BASE value depending on the character
@forthword_ SETBASE, 0, "setbase"
SETBASE:        @ ( c -- )
    mov r0, tos
    drop_
    cmp r0, #'$
    bne.n PFA_SETBASE0
    b.n HEX

PFA_SETBASE0:
    cmp r0, #'%
    bne.n PFA_SETBASE1
    b.n BIN

PFA_SETBASE1:
    cmp r0, #'&
    bne.n PFA_SETBASE2
    b.n DECIMAL

PFA_SETBASE2:        @ ( error)
    dup_
    mov tos, r0
    bl EMIT
    $lit_ " Bad Base!"
    bl THROW

@ ( addr len -- addr' len' )
@ skip a numeric prefix character
@forthword_ PRAEFIX, 0, "praefix"
PRAEFIX:        @ ( adr1 len1 -- adr2 len2 )
    push {lr}
    over_
    cfetch_
    cmp tos, #0x30
    blo.n PFA_PRAEFIX0
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
@ forthword_ NUMBERSIGN, 0, "#-"
NUMBERSIGN:        @ ( addr len -- )
    over_          @ ( addr len addr )
    cfetch_        @ ( addr len char )
    cmp tos, #'-
    beq.n NUMBERSIGN_HASSIGN
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
    beq.n TO_NUMBER_END
        over_                @ ( u adr len adr)
        cfetch_              @ ( u adr len char)
        bl DIGITQ            @ ( u adr len digit flag)
        zerosense_
        bne.n TO_NUMBER_CONV
            @ character is not a recognized number
            pop {pc}

TO_NUMBER_CONV:
        tob_                 @ ( u adr len) B: digit
        bl ROT               @ ( adr len u)
        bl BASEFETCH         @ ( adr len u base)
        @bl STAR             @ ( adr len u*base)
        mov r0, tos
        poptos_
        muls tos, r0
        getb_                @ ( adr len u' digit)
        plus_                @ ( adr len u')
        bl RROT              @ ( u' adr len )
        one_
        bl SLASHSTRING
        b.n TO_NUMBER_AGAIN

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
  beq.n PFA_NUMBER1

  @ error in string to number conversion
PFA_NUMBER2:
  nip_                    @ ( addr' )  (R: base flagsign' )
  r_drop_                 @ ( addr' ) (R: base )
  zerotos_                @ ( 0 ) (R: base )
  b.n PFA_NUMBER5

PFA_NUMBER1:
  drop_                   @ ( n )  (R: base flagsign' )
  @ incorporate sign into number
  r_from_                 @ ( n flagsign' ) (R: base )
  zerosense_
  beq.n PFA_NUMBER4
  neg_

PFA_NUMBER4:
  true_                   @ ( n true ) (R: base )

PFA_NUMBER5:
  r_from_                 @ ( n true base ) (R: )
  pop_lr_
  b BASESTORE            @ ( n true )


Forthword_ DSWAP, 0, "2swap"
@ ( 4 3 2 1 -- 2 1 4 3 )
  ldm dsp!, {r0, r1, r2}
  subs dsp, #4
  str r0, [dsp]
  pushtos_
  subs dsp, #4
  str r2, [dsp]
  movs tos, r1
  bx lr

@ ( n -- -n )
@ negate a double word
Forthword_ DNEG, 0, "dneg"
  ldr r0, [dsp]
  movs r1, #0
  mvns r0, r0
  mvns tos, tos
  adds r0, #1
  adcs tos, r1
  str r0, [dsp]
  bx lr

@ Multiply unsigned 32*32 = 64
@ ( u u -- ud )
Forthword_ UMSTAR, 0, "um*"
.if rpi2

    ldr r0, [dsp]
    umull r0, tos, r0, tos @ Unsigned long multiply 32*32=64
    str r0, [dsp]
    bx lr
    
.else

    ldr r0, [dsp]  @ To be calculated: Tos * r0

    @ Calculate low part in hardware:
    movs r3, r0    @ Save the low part for later
    muls r3, tos   @ Gives complete low-part of result
    str r3, [dsp]  @ Store low part

    @ Calculate high part:
    lsrs r1, r0,  #16 @ Shifted half
    lsrs r2, tos, #16 @ Shifted half

    movs r3, r1  @ High-High
    muls r3, r2

    @ Low-High and High-Low
    uxth tos, tos
    uxth r0, r0

    muls tos, r1
    muls r0, r2
    adds tos, r0

    lsrs tos, #16 @ Shift accordingly
    adds tos, r3  @ Add together
    bx lr

.endif

@ ( n n -- d)
@ multiply 2 signed cells to a double cell
Forthword_ MSTAR, 0, "m*"
@ Multiply signed 32*32 = 64
@ ( n n -- d )

.if rpi2

    ldr r0, [dsp]
    smull r0, tos, r0, tos @ Signed long multiply 32*32=64
    str r0, [dsp]
    bx lr

.else

    ldr r0, [dsp]
    movs r1, r0, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
    beq.n 1f
    @ - * ?
      rsbs r0, r0, #0
      str r0, [dsp]

      movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
      beq.n 2f @ - * +

      @ - * -
      rsbs tos, tos, #0
      b.n UMSTAR

1:  @ + * ?
    movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
    beq.n UMSTAR @ + * +
    @ + * -
    rsbs tos, tos, #0

    @ - * + or + * -
2:  push {lr}
    bl UMSTAR
    bl DNEG
    pop {pc}

.endif

Forthword_ UM_DIVMOD, 0, "um/mod"
@ ( ud u -- u u ) Dividend Divisor -- Rest Ergebnis
@ 64/32 = 32 Rest 32

@  push {lr}
@  pushdaconst 0
@  bl ud_slash_mod
@  drop
@  nip
@  pop {pc}

  push {r4}
                     @ tos : Divisor
  ldr  r0, [dsp, #4] @ (LL) Dividend L
  ldr  r1, [dsp, #0] @ (L)  Dividend H
  movs r2, #0        @ (H)  Shift L

  movs r4, #0        @ Result

  @ Loop in r3:
  movs r3, #32

1:lsls r4, #1 @ Shift result
  
  adds r0, r0 @ Shift through first three registers
  adcs r1, r1
  adcs r2, r2 

  @ Compare the top two registers to divisor
  cmp tos, r2  @ Compare low part
  bhi.n 2f      @ If lower or same:
    subs r2, tos  @  Low-part first
    adds r4, #1  @ Set bit in result
2:
  subs r3, #1
  bne.n 1b
  @ r3 is Zero now. No need to clear.

  @ Shifted 32 places - r0 (LL) is shifted out completely now. 
  @ Result is kept as it is and may overflow

  @ Loop in r3:
  movs r3, #32

1:lsls r4, #1 @ Shift result
  
  adds r1, r1 @ Shift through two registers only
  adcs r2, r2

  @ Compare the top two registers to divisor
  cmp tos, r2  @ Compare low part
  bhi.n 2f      @ If lower or same:
    subs r2, tos  @  Low-part first
    adds r4, #1  @ Set bit in result
2:
  subs r3, #1
  bne.n 1b
  @ r3 is Zero now. No need to clear.

  adds dsp, #4
  str r2, [dsp] @ Remainder
  movs tos, r4

  pop {r4}
  bx lr


Forthword_ M_DIVMOD, 0, "m/mod"
@ Signed symmetric divide 64/32 = 32 remainder 32
@ ( d n -- n n )
@  push {lr}
@  pushdatos                 @ s>d
@  movs tos, tos, asr #31    @ Turn MSB into 0xffffffff or 0x00000000
@  bl d_slash_mod
@  drop
@  nip
@  pop {pc}

  @ Check Divisor
  push {lr}
  movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
  beq.n 2f
    @ ? / -
    rsbs tos, tos, #0 @ Negate
    bl RROT
    movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
    beq.n 1f
    @ - / -
    bl DNEG
    bl ROT
    bl UM_DIVMOD

    swap_
    rsbs tos, tos, #0 @ Negate for Negative remainder
    swap_
    pop {pc}

1:  @ + / -
    bl ROT
    bl UM_DIVMOD
    rsbs tos, tos, #0 @ Negate for Negative result
    pop {pc}

2:  @ ? / +
    bl RROT
    movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
    beq.n 3f
    @ - / +
    bl DNEG
    bl ROT

    bl UM_DIVMOD

    rsbs tos, tos, #0 @ Negate for Negative result
    swap_
    rsbs tos, tos, #0 @ Negate for Negative remainder
    swap_
    pop {pc}

3:  @ + / +
    bl ROT
    bl UM_DIVMOD
    pop {pc}

@ Tool for ud/mod

  .macro division_step
    @ Shift the long chain of four registers.
    lsls r0, #1
    adcs r1, r1
    adcs r2, r2
    adcs r3, r3

    @ Compare Divisor with top two registers
    cmp r3, r5 @ Check high part first
    bhi.n 1f
    blo.n 2f

    cmp r2, r4 @ High part is identical. Low part decides.
    blo.n 2f

    @ Subtract Divisor from two top registers
1:  subs r2, r4 @ Subtract low part
    sbcs r3, r5 @ Subtract high part with carry

    @ Insert a bit into Result which is inside LSB of the long register.
    adds r0, #1
2:
  .endm

Forthword_ UD_SLASHMOD, 0, "ud/mod"
         @ Unsigned divide 64/64 = 64 remainder 64
         @ ( ud1 ud2 -- ud ud)
         @ ( 1L 1H 2L tos: 2H -- Rem-L Rem-H Quot-L tos: Quot-H )
   push {r4, r5}

   @ ( DividendL DividendH DivisorL DivisorH -- RemainderL RemainderH ResultL ResultH )
   @   8         4         0        tos      -- 8          4          0       tos


   @ Shift-High Shift-Low Dividend-High Dividend-Low
   @         r3        r2            r1           r0

   movs r3, #0
   movs r2, #0
   ldr  r1, [dsp, #4]
   ldr  r0, [dsp, #8]

   @ Divisor-High Divisor-Low
   @          r5           r4

ud_slash_mod_internal:
   movs r5, tos
   ldr  r4, [dsp, #0]

   @ For this long division, we need 64 individual division steps.
   movs tos, #64

3: division_step
   subs tos, #1
   bne.n 3b

   @ Now place all values to their destination.
   movs tos, r1       @ Result-High
   str  r0, [dsp, #0] @ Result-Low
   str  r3, [dsp, #4] @ Remainder-High
   str  r2, [dsp, #8] @ Remainder-Low

   pop {r4, r5}
   bx lr

Forthword_ D_SLASHMOD, 0, "d/mod"
@ Signed symmetric divide 64/64 = 64 remainder 64
@ ( d1 d2 -- d d )
@ ( 1L 1H 2L tos: 2H -- Rem-L Rem-H Quot-L tos: Quot-H )
  @ Check Divisor
  push {lr}
  movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
  beq.n 2f
    @ ? / -
    bl DNEG
    bl DSWAP
    movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
    beq.n 1f
    @ - / -
    bl DNEG
    bl DSWAP
    bl UD_SLASHMOD

    bl DSWAP
    bl DNEG @ Negative remainder
    bl DSWAP
    pop {pc}

1:  @ + / -
    bl DSWAP
    bl UD_SLASHMOD
    bl DNEG  @ Negative result
    pop {pc}

2:  @ ? / +
    bl DSWAP
    movs r0, tos, asr #31 @ Turn MSB into 0xffffffff or 0x00000000
    beq.n 3f
    @ - / +
    bl DNEG
    bl DSWAP

    bl UD_SLASHMOD

    bl DNEG @ Negative result
    bl DSWAP
    bl DNEG @ Negative remainder
    bl DSWAP
    pop {pc}

3:  @ + / +
    bl DSWAP
    bl UD_SLASHMOD
    pop {pc}

@ ( u1 u2 -- rem quot )
@ unsigned 32b division with modulus result
Forthword_ U_DIVMOD, 0, "u/mod"
@ ARM provides no remainder operation, so we fake it by un-dividing and subtracting.
  .if rpi2

  ldm dsp!, {r0}       @ Get u1 into a register
  movs r1, tos         @ Back up the divisor in X.
  udiv tos, r0, tos    @ Divide: quotient in TOS.
  muls r1, tos, r1     @ Un-divide to compute remainder.
  subs r0, r1          @ Compute remainder.
  subs dsp, #4
  str r0, [dsp]
  bx lr
    
  .else

  movs r1, tos
  ldm dsp!, {tos}

  @ Catch divide by zero..
  cmp r1, #0
  bne.n 1f
    zero_           @ Null
    bx lr
1:

  @ Shift left the denominator until it is greater than the numerator
  movs r2, #1
  movs r3, #0
  cmp tos, r1
  bls.n 3f
  adds r1, #0    @ Don't shift if denominator would overflow
  bmi.n 3f

2:lsls r2, #1
  lsls r1, #1
  bmi.n 3f
  cmp tos, r1
  bhi.n 2b

3:cmp tos, r1
  bcc.n 4f         @ if (num>denom)
  subs tos, r1     @ numerator -= denom
  orrs r3, r2      @ result(r3) |= bitmask(r2)

4:lsrs r1, #1      @ denom(r1) >>= 1
  lsrs r2, #1      @ bitmask(r2) >>= 1
  bne.n 3b

  pushtos_
  movs tos, r3
  bx lr
  .endif
  
@ ( n1 n2 -- rem quot )
@ signed division with remainder
Forthword_ DIVMOD, 0, "/mod"
@ ARM provides no remainder operation, so we fake it by un-dividing and subtracting.
.if rpi2

  ldm dsp!, {r0}       @ Get u1 into a register
  movs r1, tos         @ Back up the divisor in X.
  sdiv tos, r0, tos    @ Divide: quotient in TOS.
  muls r1, tos, r1     @ Un-divide to compute remainder.
  subs r0, r1          @ Compute remainder.
  subs dsp, #4
  str r0, [dsp]
  bx lr

.else

  push {lr}
  movs r0, tos
  ldm dsp!, {tos}
  @     TOS: Dividend

  cmp tos, #0
  bge.n divmod_plus
  rsbs tos, tos, #0

divmod_minus:
    cmp r0, #0
    bge.n divmod_minus_plus

divmod_minus_minus:
      rsbs r0, r0, #0
      pushtos_
      movs tos, r0
      bl U_DIVMOD
      movs r0, tos
      ldm dsp!, {tos}
      rsbs tos, tos, #0
      pushtos_
      movs tos, r0
      pop {pc}

divmod_minus_plus:
      pushtos_
      mov tos, r0
      bl U_DIVMOD
      movs r0, tos
      ldm dsp!, {tos}
      rsbs r0, r0, #0
      rsbs tos, tos, #0
      pushtos_
      movs tos, r0
      pop {pc}

divmod_plus:
    cmp r0, #0
    bge.n divmod_plus_plus

divmod_plus_minus:
      rsbs r0, r0, #0
      pushtos_
      movs tos, r0
      bl U_DIVMOD
      rsbs tos, tos, #0
      pop {pc}

divmod_plus_plus:
      pushtos_
      mov tos, r0
      bl U_DIVMOD
      pop {pc}
.endif

@ ( n1 n2 -- n1/n2 )
@ 32bit/32bit = 32bit
.if rpi2

Forthword_ DIV, INLINE_OPT, "/"
  ldm dsp!, {r0}       @ Get n1 into a register
  sdiv tos, r0, tos    @ Divide !
  bx lr

.else

Forthword_, DIV, 0, "/" 
  push {lr}
  bl DIVMOD
  nip_
  pop {pc}

.endif

@ ( n -- )
@ sleep for n micro seconds
Forthword_ USLEEP, 0, "usleep"
  mov r0, tos
  poptos_
  b usleep


@ dodefer - execute a deferred word
@ defer setup as:
@ push {lr}
@ bl DODEFER
@ .word deferptr
@ does not return to defer callee
Forthword_ DODEFER, 0, "(def)"
  pushtos_
  mov tos, lr
  subs tos, #1 @ doing memory access, do not want thumb bit
  ldr tos, [tos]
  bl EXEC
  pop {pc}
  


@ ( caddr -- ** )
@ open a file that will be used for key input
@ caddr points to null terminated file name
Forthword_ DOINCLUDE, 0, "doinclude"
    push {lr}
    @ set file open mode to reading
    zero_
    swap_
    bl OPENF     @ ( filedes )
    @ if file descriptor > 0 then open is success
    dup_
    bl ZEROGREATER
    zerosense_
    
    beq.n DOINCLUDE_EXIT
      @ push FFLAGS on tor
      bl FFLAGS
      hfetch_
      to_r_
      @ push on return stack the old defer key
      bl KEYADDR
      fetch_
      to_r_
      @ push old keyfile on return stack
      bl KEYFILEADDR
      fetch_
      to_r_
      bl KEYFILEADDR
      bl STORE
      @ defer key to keyfile for input
      dolit32_ KEYFILE
      bl KEYADDR
      bl STORE
      @ run interpreter
      bl DOTASKS
      @ close keyfile
      bl KEYFILEADDR
      fetch_
      bl CLOSEF
      @ pop tor into keyfile
      r_from_
      bl KEYFILEADDR
      bl STORE
      @ pop top of return into defer key
      r_from_
      bl KEYADDR
      bl STORE
      @ restore FFLAGS
      r_from_
      bl FFLAGS
      pop_lr_
      b HSTORE
       
DOINCLUDE_EXIT:
    drop_
    type_ "File not found!"
    pop {pc}

@ ( C:filepath -- ** )
@ open a file that will be used for key input
Forthword_ INCLUDEF, 0, "include"
    push {lr}
    @ parse input for filename to include
    bl PNAME     @ ( addr len )
    @ add null to end of string
    over_         
    plus_
    bl ZEROCSTORE
    pop_lr_
    b DOINCLUDE

@ ( nx* -- ) (R: ny* -- )
@ initialize rf further. EXECs turnkey operation and go to quit
Forthword_ DOCMDARG, 0, "docmdarg"
    push {lr}
    bl ARGCADDR
    fetch_
    one_
    bl GREATER
    zerosense_
    beq.n DOCMDARG_EXIT

    bl ARGVADDR
    fetch_
    fourplus_
    fetch_
    bl DOINCLUDE 
       
DOCMDARG_EXIT:
    pop {pc}

@ ( -- seconds usecs ) 
@ get time of day
@ gives the number of seconds and microseconds since the Epoch
Forthword_ TIME, 0, "time"
    push {lr}
    pushtos_
    movs tos, #0
    pushtos_
    pushtos_
    mov r0, dsp
    movs r1, #0
    bl gettimeofday
    poptos_
    pop {pc}
    
@ must be last word in core
Forthword_ WIPE, 0, "WIPE"
    push {lr}
   
    ldr r0, addr_dpstart
    movs tos, #(ram_dp-sysvar_base)
    adds tos, sysvar
    str r0, [tos]
    
    dolit32_ EE_FORTHWORDLIST
    dup_
    bl ZEROSTORE
    fourplus_
    bl ZEROSTORE
    
    @ init pause to noop
    dolit32_ NOOP
    bl PAUSEADDR
    bl STORE
    
    dolit32_ HERESTART
    bl HEREADDR
    bl STORE
    pop_lr_
    b ONLY    
