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
