/*  main.S */
.thumb

.include "macros.S"

.bss
.balign 4


pstack:
  .space 400
topstack:
  .word 0


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
    @ initialize data stack
    bl set_input_mode
    ldr dsp, addr_stack


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
    bl KEY
    bl EMIT
    bl CR

    doliteral_ 12
    @bl

    mov r0, tos
    pop {pc}

.balign 4
addr_stack: .word topstack


/* External calls*/
.global putchar
.global getchar
