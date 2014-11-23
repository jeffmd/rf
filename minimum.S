@ minimum.S

@ ( val -- char )
@ convert low byte of val to a printable hex character
Forthword_ NHEX, 0, "#h"
    mov r0, #0x0F
    and tos, r0
    cmp tos, #10
    blo NHEX_NEXT
    add tos, #7

    @ <then>
NHEX_NEXT:
    add tos, #48
    bx lr


@ ( n -- )
@ simple 4 bit hex print
Forthword_ PNIB, 0, ".h"
    push {lr}
    bl NHEX
    bl EMIT
    pop {pc}

@ ( n -- )
@ simple 16 bit hex print
Forthword_ PHEX, 0, ".$"
    push {lr}
    dup_
    lsr tos, #16
    bl PNIB
    dup_
    lsr tos, #12
    bl PNIB
    dup_
    lsr tos, #8
    bl PNIB
    dup_
    lsr tos, #4
    bl PNIB
    dup_
    bl PNIB
    mov tos, #32
    bl EMIT
    pop {pc}
