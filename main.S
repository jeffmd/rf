/*  main.S */
.thumb

.include "macros.S"

.bss
.balign 4


pstack:
  .space 400
topstack:
  .word 0

.balign 2
sysvar_base:

ram_sharptib: .space 2


.text
.balign 2

.set VE_HEAD, 0

.include "core.S"
.include "interpret.S"
.include "minimum.S"



.global main
.thumb_func
main:
    push {lr} @ save return
    bl set_input_mode
    @ initialize data stack
    ldr dsp, addr_stack
    @ initialize sysvar pointer
    ldr sysvar, addr_sysvar


    bl ONE

    doliteral_ 5
    add__
    bl TWO
    sub__
    twostar_
    pushtos_

    bl BL
    bl EMIT

    bl PHEX
    bl CR
LOOP:
    bl KEY
    cmp tos, #0
    bgt CONT
    poptos_
    @bl PHEX
    b LOOP
CONT:
    bl EMIT
    bl CR

    doliteral_ 12
    @bl

    mov r0, tos
    pop {pc}

.balign 4
@ ram pointers that need relocation on startup
addr_stack: .word topstack
addr_sysvar: .word sysvar_base

/* External calls*/
.global putchar
.global getchar
