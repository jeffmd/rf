/*  main.S */
.thumb

.include "macros.S"

@ size of the Terminal Input Buffer
.set TIBSIZE, 80

.bss
.balign 4


pstack:
  .space 400
topdstack:
  .word 0

.balign 2
sysvar_base:

ram_sharptib: .space 2
ram_tib: .space TIBSIZE
user_g_in: .space 2
state: .space 2
fflags: .space 2
rstack0: .space 4
ram_LATEST: .space 4
COLON_SMUDGE: .space 4


.text
.balign 2

.set VE_HEAD, 0

.include "core.S"
.include "compiler.S"
.include "interpret.S"
.include "minimum.S"

@ ( nx* -- ) (R: ny* -- )
@ initialize asforth further. EXECs turnkey operation and go to quit
Forthword_ WARM, 0, "warm"
    push {lr}
    pushtos_
    mov tos, sp
    bl RP0
    bl STORE
    bl QUIT
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
    ldr dsp, addr_dstack
    @ initialize sysvar pointer
    ldr sysvar, addr_sysvar
    bl WARM
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

CONT:
    bl STIB
    bl TYPE
    bl CR

    bl DOSLIT
    ascii_ "This a test\n"
    bl TYPE

    doliteral_ 12

    mov r0, tos
    pop {pc}

.balign 4
@ ram pointers that need relocation on startup
addr_dstack: .word topdstack
addr_sysvar: .word sysvar_base

/* External calls*/
.global putchar
.global getchar
