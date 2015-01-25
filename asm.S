@ asm.S - words that generate inline assembly ie arm thumb instructions

.balign 4
.balign 2
@ ( -- )
@ compile assembler push {lr}
Forthword_ PUSHLR_C, 0, "pushlr,"
    push {lr}
    pushtos_
    ldrh tos, POPPC_C
    bl COMMA
    pop {pc}

.balign 4
.balign 2

@ ( -- )
@ compile assembler pop {pc}
Forthword_ POPPC_C, 0, "poppc,"
    push {lr}
    pushtos_
    ldrh tos, RET_C_POP
    bl COMMA
RET_C_POP:
    pop {pc}


@ ( -- lr )
@ move link register onto top of data stack
Forthword_ LR_G, INLINE_OPT, "lr>"
    pushtos_
    mov tos, lr
    bx lr


@ calc relative distance in half word alignment
@ ( dest start  -- distance )
Forthword_ RELDST, 0, "reldst"
    @ calculate relative distance in half words from start to dest
    @ rel dist = dest - start
    @ account for 3 stage pipeline
    fourplus_            @ ( dest start+4 )
    minus_               @ ( dist )
    twoslash_            @ ( dist/2 )
    bx lr

@ compile assembler instruction b - unconditional branch
@ ( reldist -- branchrel )
@ reldist: relative distance as 2's compliment
Forthword_ BRANCH, 0, "b."
    @ 1110 0XXX XXXX XXXX
    mov r0, #7
    lsl r0, #8
    add r0, #0xFF
    and tos, r0
    mov r0, #0x07
    lsl r0, #13
    orr tos, r0
    bx lr

@ compile assembler instruction b - unconditional branch
@ ( reldist -- )
@ reldist: relative distance as 2's compliment
Forthword_ BC, 0, "b,"
    push {lr}
    bl BRANCH
    bl COMMA
    pop {pc}

@ compile branch at start address
@ ( start dest -- )
Forthword_ RJMPC, 0, "rjmpc"
    push {lr}
    over_                @ ( start dest start )
    bl RELDST            @ ( start reldst )
    bl BRANCH            @ ( start branchinst )
    swap_                @ ( branchinst start )
    bl HSTORE            @ ( )
    pop {pc}

@ compile rcall to xt at the current dictionary position (DP) if relative distance is in range
@ otherwise do long call to xt.  If word flag indicates inlining then the word is inlined.
@ ( xt flags -- )
Forthword_ COMPILEXT, 0, "cxt"
    push {lr}
    mov r0, #INLINE_OPT
    lsl r0, #8
    tst tos, r0
    @ if bit 0 of high byte flag is 0 then word is to be inlinned
    drop_           @ ( xt )
    beq COMPILEXT_INLINE
    b DO_COMPILEXT

COMPILEXT_INLINE:
      bl INLINE
      pop {pc}

DO_COMPILEXT:
    @ calculate relative distance in words from start to dest
    bl DP                @ ( xt dp )
    bl RELDST            @ ( distance )
    bl BLC
    pop {pc}

@ compile call at start address
@ ( dist -- )
@ dist: 2's compliment half word offset
Forthword_ BLC, 0, "bl,"
    push {lr}
    @ bl is a 32 bit instruction done as two 16 bit instructions in thumb
    @ bit pattern:
    @ 11110xxxxxx - upper half
    @ 11111xxxxxx - lower half
    @ split the 23-bit two’s complement half-word offset specifed by the
    @ label into two 11-bit halves, ignoring bit 0 (which must be 0),
    @ and creates two THUMB instructions
    dup_                    @ ( dist dist )
    @ get top 11 bits
    asr tos, #11           @ ( dist xxxdist )
    @ make high address bl instruction mask
    mov r0, #0xF0
    lsl r0, #8
    orr tos, r0             @ ( dist 0xFxdist )
    mov r0, #0x8
    lsl r0,#8
    bic tos, r0             @ ( dist 0xF0dist )
    bl COMMA                @ ( dist )
    @ make low address bl instruction mask
    mov r0, #0xF8
    lsl r0, #8
    orr tos, r0             @ ( 0xF8dist )
    bl COMMA
    pop {pc}

@ branch 1 word if not zero
@ ( -- )
Forthword_ BRNZ1_COMPILE, 0, "bne1,"
    push {lr}
    pushtos_
    @compile bne #00 : 0xD100
    mov tos, #0xD1
    lsl tos, #8
    add tos, #0x00
    bl COMMA
    pop {pc}

@ ( -- 32b )
@ fetch a 32 bit inlinned constant pointed to by lr onto the top of stack
@ assumes caller was in thumb mode
Forthword_ ICFETCH, 0, "ic@"
    pushtos_
    mov r0, lr
    sub r0, #1     @ clear bit 0 which is thumb indicator
    ldr tos, [r0]
    add r0, #5     @ return after constant and default to thumb mode
    bx r0

@ compile top of stack as inlinned immediate 32 bit constant
@ ( n -- )
Forthword_ LIT, 0, "lit"
    push {lr}
    @ compile xt -> ICFETCH
    dolit32_ VE_ICFETCH
    bl NFATOXTF
    bl COMPILEXT
    @ store 32 bit val from tos
    bl DCOMMA
    pop {pc}
