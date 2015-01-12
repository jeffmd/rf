@ compiler.S

@ ( -- addr )
@ system state variable. 0 is interpret mode. Not 0 is compile mode
@ is half word
Forthword_ STATE, 0, "state"
    douser_ state

Forthword_ STATEFETCH, 0, "state@"
    push {lr}
    bl STATE
    hfetch_
    pop {pc}

@ ( -- addr )
@ current vocabulary for new words
Forthword_ CURRENT, 0, "current"
    douser_ ram_CURRENT

@ ( -- addr )
@ current vocabulary for searching
@ array of wordlists
Forthword_ CONTEXT, 0, "context"
    douser_ ram_CONTEXT

@ ( -- addr )
@ system LATEST. Get flash program address of latest word being compiled.
Forthword_ LATEST, 0, "latest"
    douser_ ram_LATEST


@ ( -- addr )
@ system SMUDGE. Get flash program address of latest word being compiled.
Forthword_ SMUDGE, 0, "smudge"
    douser_ COLON_SMUDGE

@ ( -- f-addr )
@ address of the next free dictionary cell
Forthword_ DP, 0, "dp"
    pushtos_
    mov tos, #(ram_dp-sysvar_base)
    add tos, sysvar
    fetch_
    bx lr

@ ( addr -- )
@ store address of the next free dictionary cell
Forthword_ DPSTORE, 0, "dp!"
    push {lr}
    pushtos_
    mov tos, #(ram_dp-sysvar_base)
    add tos, sysvar
    bl STORE
    pop {pc}

@ ( offset -- )
@ add offset to 16 bit (dictionary pointer) DP
Forthword_ DPPLUS, 0, "dp+"
    push {lr}
    pushtos_
    mov tos, #(ram_dp-sysvar_base)
    add tos, sysvar
    bl PLUSSTORE
    pop {pc}

@ ( -- )
@ increment 32 bit (dictionary pointer) DP by one thumb cell
Forthword_ DPPLUSONE, 0, "dp+1"
    two_
    b DPPLUS

@ ( -- )
@ tail call optimize: change last rcall/call into rjmp/jmp
Forthword_ TAILOPT, 0, ";opt"
    push {lr}
    @ optimize only if smudge is not zero
    bl SMUDGE
    bl FETCH
    zerosense_
    bne TAILOPT_OPT
    pop {pc}

TAILOPT_OPT:
    @ don't optimize tail call, just compile a ret.
    bl POPPC_C          @ ( )
    pop {pc}

@ ( -- )
@ update wid from smudge if valid
Forthword_ UWID, 0, "uwid"
    push {lr}
    bl SMUDGE
    fetch_
    bl QDUP
    zerosense_
    beq UWID_end
       bl CURRENT
       fetch_
       bl STORE
       bl SMUDGE
       bl ZEROSTORE
       @bl DPSTOREE
UWID_end:
    pop {pc}

@ ( --  )
@ enter compiler mode
Forthword_ RBRACKET, 0, "]"
    push {lr}
    bl ONE
    bl STATE
    bl HSTORE
    pop {pc}

@ ( --  )
@ enter interpreter mode
Forthword_ LBRACKET, IMMEDIATE_EN, "["
    push {lr}
    bl STATE
    bl ZEROHSTORE
    pop {pc}

@ ( n -- )
@ compile 16 bit into ram at (dictionary pointer) DP
Forthword_ COMMA, 0, ","
    push {lr}
    bl DP
    bl HSTORE
    bl DPPLUSONE
    pop {pc}

@ ( addr len len' -- )
@ compiles a string from RAM to Flash
Forthword_ DOSCOMMA, 0, "(s,)"
    push {lr}
    bl COMMA           @ ( addr len )
    bl BTOW            @ ( addr len/2 rem )
    to_r_              @ ( addr len/2 ) (R: rem )
    niptoa_            @ ( len/2 ) A: addr

    @ begin
PFA_SCOMMA1:
    @ ?while
    dupzerosense_      @ ( len )
    beq PFA_SCOMMA2
    ahfetch_           @ ( len c1c2 )
    ahplus_
    bl COMMA           @ ( len )
    oneminus_          @ ( len-1 )
    @ repeat
    b PFA_SCOMMA1

PFA_SCOMMA2:
    drop_              @ (  )
    r_from_            @ ( rem ) (R: )
    @ if
    zerosense_         @ ( )
    beq PFA_SCOMMA3
      acfetch_         @ ( c1 )
      bl COMMA         @ ( )

    @ then
PFA_SCOMMA3:
    pop {pc}

@ ( addr len wid -- voc-link )
@ creates the vocabulary header without XT and data field (PF) in the wordlist wid
Forthword_ HEADER, 0, "header"
    push {lr}
    bl DP                 @ ( addr len wid DP )
    to_r_                 @ ( addr len wid ) (R: DP )
    to_r_                 @ ( addr len ) (R: DP wid )
    @ <if>
    dupzerosense_
    beq HEADER_error
      dup_                @ ( addr len len )
      mov r0, #0xFF
      lsl r0, #8
      orr tos, r0         @ ( addr len len' )
      bl DOSCOMMA         @ ( )
      @ make voc link
      r_from_             @ ( wid ) (R: DP )
      fetch_              @ ( VE_HEAD )
      bl COMMA            @ ( )
      bl PUSHLR_C
      r_from_             @ ( DP ) (R: )
      pop {pc}

    @ <then>
HEADER_error:
    @ -16: attempted to use zero length string as a name
    true_
    bl THROW

@ ( nfa -- lfa )
@ get the link field address from the name field address
Forthword_ NFA2LFA, 0, "nfa>lfa"
    push {lr}                   @ ( nfa )
    bl STRINGLEN                @ ( nfa+2 len+flags )
    @ mask out flags in len, allow up to 31 characters
    mov r0, #31
    and tos, r0                 @ ( nfa+2 len )
    bl WALIGN
    plus_
    pop {pc}

@ ( nfa -- [ 0 ] | [ xt xtflags] )
@ convert name field address to xt and xtflags
Forthword_ NFATOXTF, 0, "nfa>xtf"
    push {lr}
    dupzerosense_               @ ( n )
    beq NFATOXTF_EXIT

    dup_                        @ ( nfa nfa )
    hfetch_                     @ ( nfa xtflags )
    to_r_                       @ ( nfa ) (R: xtflags)
    bl NFA2LFA                  @ ( lfa )
    fourplus_   @ lfa>xt        @ ( xt )
    r_from_                     @ ( xt xtflags )

NFATOXTF_EXIT:
    pop {pc}

@ ( -- )
@ set the context and current to root forth vocabulary and remove
@ other vocabularies
Forthword_ ONLY, IMMEDIATE_EN, "only"
    push {lr}
    @ forth vocab always takes slot 0
    pushtos_
    ldr tos, EE_FORTHWORDLIST_P
    dup_
    bl CONTEXT
    bl STORE
    @ make current also forth vocab
    bl CURRENT
    bl STORE
    @ move index to next slot
    one_
    bl CONTEXT
    twominus_
    bl HSTORE
    @ make second slot have no vocab
    bl CONTEXT
    twoplus_
    bl ZEROSTORE
    pop {pc}

.balign 4
EE_FORTHWORDLIST_P: .word EE_FORTHWORDLIST
.balign 2
