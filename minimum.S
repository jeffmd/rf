@ minimum.S

@ ( n1 n2 -- n1|n2 )
@ compare two values leave the smaller one
Forthword_ MIN, 0, "min"
  ldm dsp!, {r0}
  cmp r0, tos
  bge 1f
  movs tos, r0
1:
  bx lr

@ ( n1 n2 -- n1|n2 )
@ compare two values, leave the bigger one
Forthword_ MAX, 0, "max"
  ldm dsp!, {r0}
  cmp r0, tos
  blt 1f
  mov tos, r0
1:
  bx lr


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

@ ( n1 -- u1 )
@ get the absolute value
Forthword_ ABS, 0, "abs"
  dupzerosense_
  bpl 1f
  neg_
1:
  bx lr
