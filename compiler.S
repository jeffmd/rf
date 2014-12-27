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
@ system LATEST. Get flash program address of latest word being compiled.
Forthword_ LATEST, 0, "latest"
    douser_ ram_LATEST


@ ( -- addr )
@ system SMUDGE. Get flash program address of latest word being compiled.
Forthword_ SMUDGE, 0, "smudge"
    douser_ COLON_SMUDGE

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
