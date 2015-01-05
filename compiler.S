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
