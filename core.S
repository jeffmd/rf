@ core.S

@ ( xt -- )
@ execute XT
Forthword_ EXEC, 0, "exec"
    mov r0, #1
    @ make sure its a thumb address mode
    orr r0, tos
    poptos_
    bx r0

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

@ ( n1 n2 n3 -- n3 n2 n1)
@ exchange TOS and stack cell before NOS, same as SWAP ROT
Forthword_ FLIP, 0, "flip"
    mov r0, tos
    ldr tos, [dsp, #4]
    str r0, [dsp, #4]
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

@ (  -- addr )
@ current data stack pointer
Forthword_ SP_FETCH, INLINE_OPT, "sp@"
    spfetch_
    bx lr

@ ( addr -- i*x)
@ set data stack pointer to addr
Forthword_ SP_STORE, INLINE_OPT, "sp!"
    spstore_
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

@ ( n -- n ) (R: -- n )
@ copy TOS to TOR
Forthword_ DUP_R, INLINE_OPT, "r>r"
    dup_r_
    bx lr

@ ( -- n) (R: n -- n )
@ put a copy of TOR on TOS
Forthword_ R_FETCH, 0, "r"
    pushtos_
    ldr tos, [sp]
    bx lr

@ (  -- n)
@ current return stack pointer address
Forthword_ RP_FETCH, INLINE_OPT, "rp@"
    rpfetch_
    bx lr

@ ( addr  -- ) (R: -- x*y)
@ set return stack pointer
@ must be called
Forthword_ RP_STORE, INLINE_OPT, "rp!"
    @ keep the return address
    rpstore_
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

@ ( n1|u1 -- n2|u2 )
@ optimized four increment
Forthword_ FOURPLUS, INLINE_OPT, "4+"
  fourplus_
  bx lr

@ (S: n1 -- n2 )
@ optimized decrement
Forthword_ FOURMINUS, INLINE_OPT, "4-"
  fourminus_
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
  and_
  bx lr

@ ( n1 n2 -- n3 )
@ logical or
Forthword_ OR, INLINE_OPT, "or"
  or_
  bx lr

@ ( n1 n2 -- n3)
@ exclusive or
Forthword_ XOR, INLINE_OPT, "xor"
  xor_
  bx lr

@ ( n1 -- n2)
@ 1-complement of TOS
Forthword_ NOT, INLINE_OPT, "not"
  not_
  bx lr

@ ( n1 n2 -- flag)
@ flag is true if n1 is not equal to n2
Forthword_ NOTEQUAL, INLINE_OPT, "<>"
  xor_
  bx lr

@ ( n1 n2 -- flag )
@ flag is true if TOS and NOS are equal
Forthword_ EQUAL, 0, "="
  ldm dsp!, {r0}
  sub tos, r0
  sub tos, #1
  sbc tos, tos
  bx lr

@ ( n1 n2 -- flag)
@ flag is true if n1 is less than n2
Forthword_ LESS, 0, "<"
  ldm dsp!, {r0}
  cmp r0, tos
  bge 1f
  mov tos, #0
  mvn tos, tos
  bx lr
1:
  mov tos, #0
  bx lr

@ ( n1 n2 -- flag )
@ flag is true if n1 is greater than n2
Forthword_ GREATER, 0, ">"
  ldm dsp!, {r0}     @ Get x1 into a register.
  cmp r0, tos        @ Is x2 greater?
  ble 1f
  mov tos, #0
  mvn tos, tos
  bx lr
1:
  mov tos, #0
  bx lr

@ ( u1 u2 -- flag )
@ flag is true if u1 > u2 (unsigned)
Forthword_ UGREATER, 0, "u>"
  ldm dsp!, {r0}
  sub tos, r0
  sbc tos, tos
  bx lr

@ ( u1 u2 -- flag)
@ flag is true if u1 < u2 (unsigned)
Forthword_ ULESS, 0, "u<"
  ldm dsp!, {r0}
  sub tos, r0, tos
@ TOS = a-b  -- carry set if a is less than b
  sbc tos, tos
  bx lr

@ ( n1 -- flag)
@ flag is true if TOS is less than zero
forthword_ ZEROLESS, INLINE_OPT, "0<"
  zeroless_
  bx lr

@ ( -- 0 )
@ place a value 0 on TOS
Forthword_ ZERO, INLINE_OPT, "0"
  zero_
  bx lr

@ ( -- 0 )
@ set TOS to 0
Forthword_ ZEROSET, INLINE_OPT, "0:"
    zerotos_
    bx lr

@ ( -- -1 )
@ leaves the value -1 (true) on TOS
Forthword_ TRUE, INLINE_OPT, "true"
  true_
  bx lr

@ ( -- 1 )
@ place a value 1 on TOS
Forthword_ ONE, INLINE_OPT, "1"
  one_
  bx lr

@ ( -- 2 )
@ place a value 2 on TOS
Forthword_ TWO, INLINE_OPT, "2"
  two_
  bx lr

@ ( -- 10 )
@ place a value 10 on TOS
Forthword_ TEN, INLINE_OPT, "10"
  ten_
  bx lr

@ ( n1 -- n2 )
@ convert byte length to half word align length
@ round number up to even value

forthword_ WALIGN, 0, "w_"
    oneplus_
    mov r0, #2
    neg r0, r0
    and tos, r0
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

@ ( n1 -- n2/2 )
@ convert byte length to half word align length
@ round number up to even value
Forthword_ HALIGN, 0, "h_"
  oneplus_
  mov r0, #1
  mvn r0, r0
  and tos, r0
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
STORE_it:
  str r0, [tos]      @ Popping both saves a cycle.
  movs tos, r1
  bx lr

@ ( a-addr -- )
@ store 0 (32 bits) to RAM address
Forthword_ ZEROSTORE, 0, "0!"
  mov r0, #0
  str r0, [tos]
  poptos_
  bx lr


@ ( n32 a-addr -- )
@ add n32 to content of cell RAM address a-addr
Forthword_ PLUSSTORE, 0, "+!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
PLUSSTORE_do:
  ldr  r2, [tos]     @ Load the current cell value
  add r2, r0         @ Do the add
  str  r2, [tos]     @ Store it back
  movs tos, r1
  bx lr

@ ( n32 a-addr -- )
@ add 1 to content of cell RAM address a-addr
Forthword_ ONEPLUSSTORE, 0, "1+!"
  ldm dsp!, {r1}
  mov r0, #1
  b PLUSSTORE_do

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

@ ( a-addr -- )
@ store 0 (16 bits) to RAM address
Forthword_ ZEROHSTORE, 0, "0h!"
  mov r0, #0
  strh r0, [tos]
  poptos_
  bx lr

@ ( n16 a-addr -- )
@ add n16 to content of half cell RAM address a-addr
Forthword_ PLUSHSTORE, 0, "+h!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
PLUSHSTORE_do:
  ldrh r2, [tos]     @ Load the current cell value
  add r2, r0         @ Do the add
  strh r2, [tos]     @ Store it back
  movs tos, r1
  bx lr

@ ( a-addr -- )
@ add 1 to content of half cell RAM address a-addr
Forthword_ ONEPLUSHSTORE, 0, "1+h!"
  ldm dsp!, {r1}
  mov r0, #1
  b PLUSHSTORE_do

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

@ ( a-addr -- )
@ store 0 (16 bits) to RAM address
Forthword_ ZEROCSTORE, 0, "0c!"
  mov r0, #0
  strb r0, [tos]
  poptos_
  bx lr

@ ( c a-addr -- )
@ add c byte to content of byte RAM address a-addr
Forthword_ PLUSCSTORE, 0, "+c!"
  ldm dsp!, {r0, r1} @ X is the new TOS after the store completes.
PLUSCSTORE_do:
  ldrb r2, [tos]     @ Load the current cell value
  add r2, r0         @ Do the add
  strb r2, [tos]     @ Store it back
  movs tos, r1
  bx lr

@ ( a-addr -- )
@ add 1 to content of byte cell RAM address a-addr
Forthword_ ONEPLUSCSTORE, 0, "1+c!"
  ldm dsp!, {r1}
  mov r0, #1
  b PLUSHSTORE_do

@ ( n1 n2 -- n2 ) A: n1
@ Remove next on stack and write to A register (Extended VM)
Forthword_ NIPTOA, INLINE_OPT, "nip>a"
  niptoa_
  bx lr

@ ( n1 n2 -- n2 ) B: n1
@ Remove next on stack and write to B register (Extended VM)
Forthword_ NIPTOB, INLINE_OPT, "nip>b"
  niptob_
  bx lr

@ ( n -- ) A: n
@ Move TOS to A register (Extended VM)
Forthword_ TO_A, INLINE_OPT, ">a"
    toa_
    bx lr

@ ( n -- ) B: n
@ Move TOS to B register (Extended VM)
Forthword_ TO_B, INLINE_OPT, ">b"
    tob_
    bx lr

@ ( n -- n ) A: n
@ copy TOS to A register (Extended VM)
Forthword_ _A, INLINE_OPT, ":a"
    copytoa_
    bx lr

@ ( n -- n ) B: n
@ copy TOS to B register (Extended VM)
Forthword_ _B, INLINE_OPT, ":b"
    copytob_
    bx lr

@ ( -- n )
@ read the A register (Extended VM)
Forthword_ A_, INLINE_OPT, "a"
    geta_
    bx lr

@ ( -- n )
@ read the B register (Extended VM)
Forthword_ B_, INLINE_OPT, "b"
    getb_
    bx lr

@ ( -- n )
@ Read a word (32bit) from memory pointed to by register A (Extended VM)
Forthword_ AFETCH, INLINE_OPT, "a@"
    afetch_
    bx lr

@ ( -- n )
@ Read a half word (32bit) from memory pointed to by register A (Extended VM)
Forthword_ AHFETCH, INLINE_OPT, "ah@"
    ahfetch_
    bx lr

@ ( -- n )
@ Read a byte from memory pointed to by register A (Extended VM)
Forthword_ ACFETCH, INLINE_OPT, "ac@"
    acfetch_
    bx lr

@ ( -- )
@ update register A with post increment 4+ from last memory operation (Extended VM)
Forthword_ APLUS, INLINE_OPT, "a+"
    aplus_
    bx lr

@ ( -- )
@ update register A with post increment 2+ from last memory operation (Extended VM)
Forthword_ AHPLUS, INLINE_OPT, "ah+"
    ahplus_
    bx lr


@ ( -- )
@ update register A with post increment 1+ from last memory operation (Extended VM)
Forthword_ ACPLUS, INLINE_OPT, "ac+"
    acplus_
    bx lr

@ ( len -- len/2 rem)
@ convert byte length to word length plus remainder
Forthword_ BTOW, 0, "btow"
    push {lr}
    dup_        @ ( len len )
    twoslash_   @ ( len len/2 )
    bl TUCK     @ ( len/2 len len/2 )
    twostar_    @ ( len/2 len len' )
    minus_      @ ( len/2 rem )
    pop {pc}

@ (start dest count -- )
@ count is the number of bytes to copy and must be a multiple of two
@ copy ram using half words.  Assumes no overlap.
Forthword_ MCPY, 0, "mcpy"
    push {lr}
    niptoa_         @ ( start count ) A: dest
MCPY_B:
    dupzerosense_   @ ( start count )
    beq MCPY_END
    tob_            @ ( start ) B: count
    dup_            @ ( start start )
    hfetch_         @ ( start val )
    geta_           @ ( start val dest )
    bl HSTORE       @ ( start )
    ahplus_
    twoplus_        @ ( start+2 )
    getb_           @ ( start+2 count )
    twominus_       @ ( start+2 count-2 )
    b MCPY_B

MCPY_END:
    bl DDROP
    pop {pc}
