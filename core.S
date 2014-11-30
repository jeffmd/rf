@ core.S

@@@@@@@@@@@@@ Parameter Stack  Manipulation @@@@@@@@@@@@@@

@ ( n -- n n )
@ duplicate TOS
Forthword_ DUP, INLINE_OPT, "dup"
    pushtos_
    bx lr

@ ( n1 -- [ n1 n1 ] | 0)
@ duplicate TOS if non-zero
Forthword_ QDUP, 0, "?dup"
    cmp tos, #0
    beq PFA_QDUP1
    pushtos_
PFA_QDUP1:
    bx lr

@ ( n1 n2 -- n2 n1)
@ swaps the two top level stack cells
Forthword_ SWAP, INLINE_OPT, "swap"
    swap_
    bx lr

@ ( x1 x2 -- x1 x2 x1 )
@ Place a copy of x1 on top of the stack
Forthword_ OVER, INLINE_OPT, "over"
    over_
    bx lr

@ ( x1 x2 -- x1 x2 x1 x2)
@ Place a copy of x1 and x2 on top of the stack
Forthword_ TWOOVER, 0, "2over"
    over_
    b OVER

@ ( n -- )
@ drop TOS
Forthword_ DROP, INLINE_OPT, "drop"
    drop_
    bx lr

@ ( n n -- )
@ drop TOS twice
Forthword_ DDROP, INLINE_OPT, "2drop"
    ddrop_
    bx lr

@ ( n1 n2 -- n2)
@ drop NOS, one before TOS.
@ same as SWAP DROP
Forthword_ NIP, INLINE_OPT, "nip"
    nip_
    bx lr

@ ( n1 n2 n3 -- n3)
@ drop NOS twice, two cells before TOS.
Forthword_ DNIP, INLINE_OPT, "2nip"
    dnip_
    bx lr

@ ( n1 n2 -- n2 n1 n2)
@ tuck TOS before NOS, same as SWAP OVER
Forthword_ TUCK, 0, "tuck"
    ldm dsp!, {r0}
    sub dsp, #8
    str tos, [dsp, #4]
    str r0, [dsp]
    bx lr

@ ( n1 n2 n3 -- n2 n3 n1)
@ rotate the three top level cells
Forthword_ ROT, 0, "rot"
    ldm dsp!, {r0, r1}
    sub dsp, #8
    str r0, [dsp, #4]
    str tos, [dsp]
    mov tos, r1
    bx lr

@ ( n1 n2 n3 -- n3 n1 n2)
@ reverse rotate the three top level cells
@ equivalent to rotate twice but faster
Forthword_ RROT, 0, "-rot"
    ldm dsp!, {r0, r1}
    sub dsp, #8
    str tos, [dsp, #4]
    str r1, [dsp]
    mov tos, r0
    bx lr

@@@@@@@@@@@@@ Return Stack @@@@@@@@@@@@@

@ ( -- n ) (R: n --)
@ move TOR to TOS
Forthword_ R_FROM, INLINE_OPT, "r>"
    r_from_
    bx lr

@ ( -- ) (R: n -- )
@ Drop TOR
Forthword_ R_DROP, INLINE_OPT, "r>drop"
    r_drop_
    bx lr

@ ( n -- ) (R: -- n)
@ move TOS to TOR
Forthword_ TO_R, INLINE_OPT, ">r"
    to_r_
    bx lr



@@@@@@@@@@@@@ Arithmatic @@@@@@@@@@@@@

@ ( n1 n2 -- n3)
@ add n1 and n2
Forthword_ PLUS, INLINE_OPT, "+"
  plus_
  bx lr

@ ( n1|u1 n2|u2 -- n3|u3 )
@ subtract n2 from n1
Forthword_ MINUS_, INLINE_OPT, "-"
  minus_
  bx lr

@ ( n1|u1 -- n2|u2 )
@ optimized increment
Forthword_ ONEPLUS, INLINE_OPT, "1+"
  oneplus_
  bx lr

@ (S: n1 -- n2 )
@ optimized decrement
Forthword_ ONEMINUS, INLINE_OPT, "1-"
  oneminus_
  bx lr

@ ( n1|u1 -- n2|u2 )
@ optimized two increment
Forthword_ TWOPLUS, INLINE_OPT, "2+"
  twoplus_
  bx lr

@ (S: n1 -- n2 )
@ optimized decrement
Forthword_ TWOMINUS, INLINE_OPT, "2-"
  twominus_
  bx lr

@ ( n1 -- n2 )
@ arithmetic shift left, filling with zero
Forthword_ TWOSTAR, INLINE_OPT, "2*"
  twostar_
  bx lr

@ ( n1 -- n2 )
@ arithmetic shift right
Forthword_ TWOSLASH, INLINE_OPT, "2/"
  twoslash_
  bx lr

Forthword_ NEGATE, INLINE_OPT, "neg"
  neg_
  bx lr

@ ( n1 n2 -- n3 )
@ bitwise and
Forthword_ AND_, INLINE_OPT, "and"
  and__
  bx lr

@ ( n1 n2 -- n3 )
@ logical or
Forthword_ OR, INLINE_OPT, "or"
  or__
  bx lr

@ ( n1 n2 -- n3)
@ exclusive or
Forthword_ XOR, INLINE_OPT, "xor"
  xor__
  bx lr

@ ( n1 -- n2)
@ 1-complement of TOS
Forthword_ NOT, INLINE_OPT, "not"
  not_
  bx lr


@ ( -- 0 )
@ place a value 0 on TOS
Forthword_ ZERO, INLINE_OPT, "0"
  zero_
  bx lr

@ ( -- -1 )
@ leaves the value -1 (true) on TOS
Forthword_ TRUE, INLINE_OPT, "true"
  zero_
  mvn tos, tos
  bx lr

@ ( -- 1 )
@ place a value 1 on TOS
Forthword_ ONE, 0, "1"
  doliteral_ 1
  bx lr

@ ( -- 2 )
@ place a value 2 on TOS
Forthword_ TWO, 0, "2"
  doliteral_ 2
  bx lr

@ ( -- 10 )
@ place a value 10 on TOS
Forthword_ TEN, 0, "10"
  doliteral_ 10
  bx lr

@ ( n1 n2 -- n3)
@ logically shift n1 left n2 times
forthword_ LSHIFT, INLINE_OPT, "<<"
  lshift_
  bx lr

@ ( n1 n2 -- n3)
@ logically shift n1 right n2 times
forthword_ RSHIFT, INLINE_OPT, ">>"
  rshift_
  bx lr


@ ( a-addr -- n32 )
@ read 1 cell (32 bits) from RAM address
Forthword_ FETCH, INLINE_OPT, "@"
  fetch_
  bx lr

@ ( n32 a-addr -- )
@ store a word (32 bits) to RAM address
Forthword_ STORE, 0, "!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
  str r0, [tos]      @ Popping both saves a cycle.
  movs tos, r1
  bx lr

@ ( n32 a-addr -- )
@ add n32 to content of cell RAM address a-addr
Forthword_ PLUSSTORE, 0, "+!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
  ldr  r2, [tos]     @ Load the current cell value
  add r2, r0         @ Do the add
  str  r2, [tos]     @ Store it back
  movs tos, r1
  bx lr


@ ( a-addr -- n16 )
@ read half cell (16 bits) from RAM address
Forthword_ HFETCH, INLINE_OPT, "h@"
  hfetch_
  bx lr

@ ( n16 a-addr -- )
@ store a half word (16 bits) to RAM address
Forthword_ HSTORE, 0, "h!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
  strh r0, [tos]     @ Popping both saves a cycle.
  movs tos, r1
  bx lr

@ ( n16 a-addr -- )
@ add n16 to content of half cell RAM address a-addr
Forthword_ HPLUSSTORE, 0, "h+!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
HPLUSSTORE_do:
  ldrh r2, [tos]     @ Load the current cell value
  add r2, r0         @ Do the add
  strh r2, [tos]     @ Store it back
  movs tos, r1
  bx lr

@ ( a-addr -- )
@ add 1 to content of half cell RAM address a-addr
Forthword_ ONEHPLUSSTORE, 0, "1h+!"
  ldm dsp!, {r1}
  mov r0, #1
  b HPLUSSTORE_do

@ ( a-addr -- n8 )
@ read byte (8 bits) from RAM address
Forthword_ CFETCH, INLINE_OPT, "c@"
  cfetch_
  bx lr

@ ( c a-addr -- )
@ store a single byte to RAM address
Forthword_ CSTORE, 0, "c!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
  strb r0, [tos]     @ Popping both saves a cycle.
  movs tos, r1
  bx lr

@ ( c a-addr -- )
@ add c byte to content of byte RAM address a-addr
Forthword_ CPLUSSTORE, 0, "c+!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
  ldrb r2, [tos]     @ Load the current cell value
  add r2, r0         @ Do the add
  strb r2, [tos]     @ Store it back
  movs tos, r1
  bx lr
