/*  main.S */
.thumb

.include "macros.S"

@ size of the Terminal Input Buffer
.set TIBSIZE, 80

.bss
.balign 4


pstack:
  .space 400
topstack:
  .word 0

.balign 2
sysvar_base:

ram_sharptib: .space 2
ram_tib: .space TIBSIZE


.text
.balign 2

.set VE_HEAD, 0

.include "core.S"
.include "interpret.S"
.include "minimum.S"

@ ( nx* -- ) (R: ny* -- )
@ initialize asforth further. EXECs turnkey operation and go to quit
Forthword_ WARM, 0, "warm"
    push {lr}
    bl ONE

    doliteral_ 5
    plus_
    bl TWO
    minus_
    twostar_
    pushtos_

    bl BL
    bl EMIT

    bl PHEX
    bl CR
LOOP:
    bl REFILL
    zerosense_
    bne CONT
    b LOOP

CONT:

    doliteral_ 12

    mov r0, tos
    pop {pc}

.global main
@ ( -- )
@ start up asforth.
Forthword_ COLD, 0, "cold"
.thumb_func
main:
    push {lr} @ save return
    bl set_input_mode
    @ initialize data stack
    ldr dsp, addr_stack
    @ initialize sysvar pointer
    ldr sysvar, addr_sysvar
    pop {r0}
    mov lr, r0
    b WARM

.balign 4
@ ram pointers that need relocation on startup
addr_stack: .word topstack
addr_sysvar: .word sysvar_base

/* External calls*/
.global putchar
.global getchar
