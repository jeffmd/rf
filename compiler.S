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
@ context vocabulary for searching
@ array of wordlists
Forthword_ CONTEXT, 0, "context"
    douser_ ram_CONTEXT


@ ( -- addr )
@ system SMUDGE. Get flash program address of latest word currently being compiled.
Forthword_ SMUDGE, 0, "smudge"
    douser_ COLON_SMUDGE

@ ( -- f-addr )
@ get address of the dictionary cell
Forthword_ DPSHARP, 0, "dp#"
    pushtos_
    movs tos, #(ram_dp-sysvar_base)
    adds tos, sysvar
    bx lr

@ ( -- f-addr )
@ address of the next free dictionary cell
Forthword_ DP, 0, "dp"
    push {lr}
    bl DPSHARP
    fetch_
    pop {pc}

@ ( offset -- )
@ add offset to 16 bit (dictionary pointer) DP
Forthword_ DPPLUS, 0, "dp+"
    push {lr}
    bl DPSHARP
    pop_lr_
    b PLUSSTORE

@ ( -- )
@ increment 32 bit (dictionary pointer) DP by one thumb cell
Forthword_ DPPLUSONE, 0, "dp+1"
    two_
    b.n DPPLUS

@ ( -- )
@ tail call optimize: change last branch with link (bl) into a branch (b)
Forthword_ TAILOPT, 0, ";opt"
    push {lr}
    @ optimize only if smudge is not zero
    bl SMUDGE
    bl FETCH
    zerosense_
    bne.n TAILOPT_OPT
    pop {pc}

TAILOPT_OPT:
    @ don't optimize tail call, just compile a ret.
    pop_lr_
    b POPPC_C          @ ( )


@ ( -- )
@ clear data cache to force reload when executed as instructions
Forthword_ CLRCACHE, 0, "clrcache"
    push {lr}
    @ r0 = start address: will be current last word defined
    bl CURRENT
    fetch_
    mov r0, tos
    poptos_
    @ r1 = end address
    bl DP
    mov r1, tos
    poptos_
    @ can't tail call optimize here since calling c code in arm not thumb
    bl __clear_cache
    pop {pc}
    
@ ( -- )
@ update wid from smudge if valid
Forthword_ UWID, 0, "uwid"
    push {lr}
    bl SMUDGE
    fetch_
    bl QDUP
    zerosense_
    beq.n UWID_end
       @ wid.word = smudge
       bl CURRENT
       fetch_
       bl STORE
       bl CLRCACHE
       @ set smudge to zero indicating no longer compiling a word
       bl SMUDGE
       bl ZEROSTORE
UWID_end:
    pop {pc}


@ ( --  )
@ enter interpreter mode
Forthword_ LBRACKET, IMMEDIATE_EN, "["
    push {lr}
    bl STATE
    pop_lr_
    b ZEROHSTORE

@ ( n -- )
@ store 16 bit value on TOS into ram at (dictionary pointer) DP
Forthword_ COMMA, 0, ","
    push {lr}
    bl DP
    bl HSTORE
    pop_lr_
    b DPPLUSONE

@ ( n -- )
@ store 32 bit value on TOS into ram at (dictionary pointer) DP
Forthword_ DCOMMA, 0, "d,"
    push {lr}
    bl DP
    bl STORE
    bl DPPLUSONE
    pop_lr_
    b DPPLUSONE

@ ( addr len len' -- )
@ copies a string from RAM to program ram
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
    beq.n PFA_SCOMMA2
    ahfetch_           @ ( len c1c2 )
    ahplus_
    bl COMMA           @ ( len )
    oneminus_          @ ( len-1 )
    @ repeat
    b.n PFA_SCOMMA1

PFA_SCOMMA2:
    drop_              @ (  )
    r_from_            @ ( rem ) (R: )
    @ if
    zerosense_         @ ( )
    beq.n PFA_SCOMMA3
      acfetch_         @ ( c1 )
      bl COMMA         @ ( )

    @ then
PFA_SCOMMA3:
    pop {pc}


@ ( start match -- start count )
@ match is the 16 bit half word value to search for in ram
@ start is the start address of the search in ram
@ the search goes up in ram address space
@ count is number of bytes to get to match value in ram
@ or get word index of match
Forthword_ FINDH, 0, "findh"
    @ fetch from ram and check if equal to match half word
    tob_             @ ( start ) B: match
    copytoa_         @ ( start ) A: start
    @ begin
FINDI_BEGIN:
      ldrh r0, [areg] @ ( start )
      ahplus_
      cmp r0, breg    @ ( start )
    @ until
    bne.n FINDI_BEGIN

    geta_            @ ( start end )
    twominus_        @ ( start end-2 )
    over_            @ ( start end-2 start )
    minus_           @ ( start count )
    bx lr

@ ( start -- )
@ copy code to current dictionary entry
Forthword_ INLINE, 0, "inline"
    push {lr}
    @ find the bx lr instruction, want count to bx lr
    @ count will be number of half words to inline
    pushtos_
    movs tos, #0x47
    lsls tos, #8
    adds tos, #0x70
    bl FINDH                 @ ( start count )

    @ dp swap dup dp+ itoi
    bl DP                    @ ( start count dp )
    swap_                    @ ( start dp count )
    dup_                     @ ( start dp count count )
    bl DPPLUS                @ ( start dp count )
    pop_lr_
    b MCPY                  @ ( )

@ ( nfa -- lfa )
@ get the link field address from the name field address
Forthword_ NFA2LFA, 0, "nfa>lfa"
    push {lr}                   @ ( nfa )
    bl STRINGLEN                @ ( nfa+2 len+flags )
    @ mask out flags in len, allow up to 31 characters
    movs r0, #31
    ands tos, r0                 @ ( nfa+2 len )
    bl WALIGN
    plus_
    pop {pc}

@ ( nfa -- [ 0 ] | [ xt xtflags] )
@ convert name field address to xt and xtflags
Forthword_ NFATOXTF, 0, "nfa>xtf"
    push {lr}
    dupzerosense_               @ ( n )
    beq.n NFATOXTF_EXIT

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
    dolit32_ EE_FORTHWORDLIST
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
    fourplus_
    pop_lr_
    b ZEROSTORE
