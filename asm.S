@ asm.S - words that generate inline assembly ie arm thumb instructions

@ ( -- )
@ compile assembler pop {pc}
Forthword_ POPPC_C, 0, "poppc,"
    push {lr}
    dolit16_ 0xbd00
    pop_lr_
    b COMMA


@ ( -- )
@ compile assembler push {lr}
Forthword_ PUSHLR_C, 0, "pushlr,"
    push {lr}
    dolit16_ 0xb500
    pop_lr_
    b COMMA

@ ( -- )
@ compile assembler bx lr
Forthword_ BXLR_C, 0, "bxlr,"
    push {lr}
    dolit16_ 0x4770
    bl COMMA
    pop_lr_
    b CLRCACHE

@ ( -- lr )
@ move link register onto top of data stack
Forthword_ LR_G, INLINE_OPT, "lr>"
    pushtos_
    mov tos, lr
    bx lr

@ ( -- 0 )
@ r0
Forthword_ R0, 0, "r0"
    dolit8_ 0x0
    bx lr

@ ( -- 1 )
@ r1
Forthword_ R1, 0, "r1"
    dolit8_ 0x1
    bx lr

@ ( -- 2 )
@ r2
Forthword_ R2, 0, "r2"
    dolit8_ 0x2
    bx lr

@ ( -- 3 )
@ b register
Forthword_ RB, 0, "b"
    dolit8_ 0x3
    bx lr

@ ( -- 4 )
@  sysvar
Forthword_ R4, 0, "sysvar"
    dolit8_ 0x4
    bx lr

@ ( -- 5 )
@ a register
Forthword_ RA, 0, "a"
    dolit8_ 0x5
    bx lr

@ ( -- 6 )
@ Top of Data Stack:tos is r6
Forthword_ TOS, 0, "tos"
    dolit8_ 0x6
    bx lr

@ ( -- 7 )
@ data stack pointer:dsp is r7
Forthword_ DSP, 0, "dsp"
    dolit8_ 0x7
    bx lr
     
@ ( Rd val8 -- )
@ subtract imediate 8 bit value from reg
Forthword_ MOVI_C, 0, "movs#,"
    dolit8_ 0x0
    b.n MCASI_C

@ ( Rd val8 -- )
@ subtract imediate 8 bit value from reg
Forthword_ CMPI_C, 0, "cmp#,"
    dolit8_ 0x1
    b.n MCASI_C

@ ( Rd val8 -- )
@ add imediate 8 bit value to reg
@ reg is 0 -7 corresponding to r0 - r7
Forthword_ ADDI_C, 0, "adds#,"
    dolit8_ 0x2
    b.n MCASI_C

@ ( Rd val8 -- )
@ subtract imediate 8 bit value from reg
Forthword_ SUBI_C, 0, "subs#,"
    dolit8_ 0x3

@ ( Rd val8 Op -- )
@ instruction bit pattern
@  15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
@ |       Op     |  Rd  |     val8      |
@ move, cmp, add, sub operations with immediate
MCASI_C:    
    push {lr}
    @ flip Rd and val8 around
    to_r_
    swap_
    r_from_
    movs r0, #4
    orrs tos, r0
    pop_lr_
    b OPRDVAL_C

@ ( Rd Rs -- )
@ Rd = Rd and Rs
@ and Rd with Rs and place result in Rd
Forthword_ ANDS_C, 0, "ands,"
    dolit8_ 0x0
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = Rd eor Rs
@ exclusive or Rd with Rs and place result in Rd
Forthword_ EORS_C, 0, "eors,"
    dolit8_ 0x1
    b.n ALU_C
    
@ ( Rd Rs -- )
@ Rd = Rd << Rs
@ logical shift left Rd by Rs bits and place result in Rd
Forthword_ LSLS_C, 0, "lsls,"
    dolit8_ 0x2
    b.n ALU_C
    
@ ( Rd Rs -- )
@ Rd = Rd >> Rs
@ logical shift right Rd by Rs bits and place result in Rd
Forthword_ LSRS_C, 0, "lsrs,"
    dolit8_ 0x3
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = Rd ASR Rs
@ arithmetic shift right Rd by Rs and place result in Rd
Forthword_ ASRS_C, 0, "asrs,"
    dolit8_ 0x4
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = Rd + Rs + C-bit
@ add Rd with Rs + carry bit and place result in Rd
Forthword_ ADCS_C, 0, "adcs,"
    dolit8_ 0x5
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = Rd - Rs - NOT C-bit
@ subtract Rs from Rd using carry bit and place result in Rd
Forthword_ SBCS_C, 0, "sbcs,"
    dolit8_ 0x6
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd : Rd ROR Rs
@ rotate Rd to the right using Rs and place result in Rd
Forthword_ RORS_C, 0, "rors,"
    dolit8_ 0x7
    b.n ALU_C

@ ( Rd Rs -- )
@ condition codes = Rd AND Rs
@ test Rd with Rs and set condition codes
Forthword_ TST_C, 0, "tst,"
    dolit8_ 0x8
    b.n ALU_C

@ ( Rd Rs -- )
@ subtract Rs from 0 and place result in Rd
Forthword_ RSBS_C, 0, "rsbs,"
    dolit8_ 0x9

@ ( Rd Rs Op -- )
@ instruction bit pattern
@ 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
@  0  1  0  0  0  0|   op  |  Rs |  Rd |
@ ALU operations: and, eor, lsl, lsr, asr, adc, sbc, ror, tst, rsbs
ALU_C:
    movs r1, #64
    lsls r1, #2
    orrs tos, r1
    b OPRSRD_C
    
@ ( Rd Rs -- )
@ condition codes = Rd - Rs
@ compare Rd with Rs and set condition codes
Forthword_ CMP_C, 0, "cmp,"
    dolit8_ 0xA
    b.n ALU_C

@ ( Rd Rs -- )
@ condition codes = Rd + Rs
@ test Rd + Rs and set condition codes
Forthword_ CMN_C, 0, "cmn,"
    dolit8_ 0xB
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = Rd OR Rs
@ or Rd with Rs and put result in Rd
Forthword_ ORRS_C, 0, "orrs,"
    dolit8_ 0xC
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = Rd * Rs
@ multiply Rd with Rs and put result in Rd
Forthword_ MULS_C, 0, "muls,"
    dolit8_ 0xD
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = Rd and not Rs
@ bit clear Rd using not Rs and put result in Rd
Forthword_ BICS_C, 0, "bics,"
    dolit8_ 0xE
    b.n ALU_C

@ ( Rd Rs -- )
@ Rd = not Rs
@ not Rs and put result in Rd
Forthword_ MVNS_C, 0, "mvns,"
    dolit8_ 0xF
    b.n ALU_C

@ ( Rd Rs val5 -- )
@ Rd = Rs << val5
@ logical shift left Rs by immediate val5 bits and put result in Rd
Forthword_ LSLI_C, 0, "lsls#,"
    dolit8_ 0x0
    b.n OPVALRSRD_C

@ ( Rd Rs val5 -- )
@ Rd = Rs >> val5
@ logical shift right Rs by immediate val5 bits and put result in Rd
Forthword_ LSRI_C, 0, "lsrs#,"
    dolit8_ 0x1
    b.n OPVALRSRD_C

@ ( Rd Rs val5 -- )
@ Rd = Rs >> val5
@ arithmetic shift right Rs by immediate val5 bits and put result in Rd
Forthword_ ASRI_C, 0, "asrs#,"
    dolit8_ 0x2
    b.n OPVALRSRD_C

@ ( Rd Rs val5 op -- )
@ instruction bit pattern
@  15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
@ |      op      |   val5   |  Rs |  Rd |
@ compile arm thumb assembler instruction    
Forthword_ OPVALRSRD_C, 0, "opvalrsrd,"
    ldm dsp!, {r0}
    movs r1, #31
    ands r0, r1
    lsls tos, #5
    orrs tos, r0
    b.n OPRSRD_C

@ ( Rd Rs val3 op -- )
@ instruction bit pattern
@  15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
@ |        op         | val3|  Rs |  Rd |
@ compile arm thumb assembler instruction  
Forthword_ OPVRRSRD_C, 0, "opvrrsrd,"
    ldm dsp!, {r0}
    movs r1, #7
    ands r0, r1
    lsls tos, #3
    orrs tos, r0
    b.n OPRSRD_C

@ ( Rd Rs op -- )
@ instruction bit pattern
@  15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
@ |            op           |  Rs |  Rd |
@ compile arm thumb assembler instruction   
Forthword_ OPRSRD_C, 0, "oprsrd,"
    push {lr}
    @ shift left Op 6 bits
    lsls tos, #6
    @ mask Rs with 7
    ldm dsp!, {r0}
    movs r1, #0x7
    ands r0, r1
    lsls r0, #3
    orrs tos, r0
    ldm dsp!, {r0}
    movs r1, #0x7
    ands r0, r1
    orrs tos, r0
    pop_lr_
    b COMMA

@ ( val8 Rd op -- )
@ instruction bit pattern
@  15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
@ |       op     |  Rd  |  8 bit val    |
@ compile arm thumb assembler instruction    
Forthword_ OPRDVAL_C, 0, "oprdval,"
    push {lr}
    lsls tos, #3
    @ mask Rd with 7
    ldm dsp!, {r0}
    movs r1, #0x7
    ands r0, r1
    orrs tos, r0
    @ mask val with 255
    ldm dsp!, {r0}
    movs r1, #0xFF
    ands r0, r1
    lsls tos, #8
    orrs tos, r0
    pop_lr_
    b COMMA
    
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

@ build assembler instruction b - unconditional short branch
@ ( reldist -- branchrel )
@ reldist: relative distance as 2's compliment
Forthword_ BRANCH, 0, "b."
    @ 1110 0XXX XXXX XXXX
    movs r0, #7
    lsls r0, #8
    adds r0, #0xFF
    ands tos, r0
    movs r0, #0x07
    lsls r0, #13
    orrs tos, r0
    bx lr

@ compile assembler instruction b - unconditional branch
@ ( reldist -- )
@ reldist: relative distance as 2's compliment
Forthword_ BC, 0, "b,"
    push {lr}
    bl BRANCH
    pop_lr_
    b COMMA

@ compile branch at start address
@ ( start dest -- )
Forthword_ RJMPC, 0, "rjmpc"
    push {lr}
    over_                @ ( start dest start )
    bl RELDST            @ ( start reldst )
    bl BRANCH            @ ( start branchinst )
    swap_                @ ( branchinst start )
    pop_lr_
    b HSTORE            @ ( )

@ compile rcall to xt at the current dictionary position (DP) if relative distance is in range
@ otherwise do long call to xt.  If word flag indicates inlining then the word is inlined.
@ ( xt flags -- )
Forthword_ COMPILEXT, 0, "cxt"
    push {lr}
    movs r0, #INLINE_OPT
    lsls r0, #8
    tst tos, r0
    @ if bit 0 of high byte flag is 0 then word is to be inlinned
    drop_           @ ( xt )
    beq.n COMPILEXT_INLINE
    b.n DO_COMPILEXT

COMPILEXT_INLINE:
      bl INLINE
      pop {pc}

DO_COMPILEXT:
    @ calculate relative distance in words from start to dest
    bl DP                @ ( xt dp )
    bl RELDST            @ ( distance )
    pop_lr_
    b BLC

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
    asrs tos, #11           @ ( dist xxxdist )
    @ make high address bl instruction mask
    movs r0, #0xF0
    lsls r0, #8
    orrs tos, r0             @ ( dist 0xFxdist )
    movs r0, #0x8
    lsls r0,#8
    bics tos, r0             @ ( dist 0xF0dist )
    bl COMMA                @ ( dist )
    @ make low address bl instruction mask
    movs r0, #0xF8
    lsls r0, #8
    orrs tos, r0             @ ( 0xF8dist )
    pop_lr_
    b COMMA

@ branch 1 word if not zero
@ ( -- )
Forthword_ BRNZ1_COMPILE, 0, "bne1,"
    push {lr}
    pushtos_
    @compile bne #00 : 0xD100
    movs tos, #0xD1
    lsls tos, #8
    adds tos, #0x00
    pop_lr_
    b COMMA

@ ( -- 32b )
@ fetch a 32 bit inlinned constant pointed to by lr onto the top of stack
@ assumes caller was in thumb mode
Forthword_ ICFETCH, 0, "ic@"
    pushtos_
    mov r0, lr
    subs r0, #1     @ clear bit 0 which is thumb indicator
    ldr tos, [r0]
    adds r0, #5     @ return after constant and default to thumb mode
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
    pop_lr_
    b DCOMMA
