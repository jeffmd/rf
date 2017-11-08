/*  main.S */
.syntax unified
.thumb

.set rpi2, 1

.include "macros.S"

@ size of the Terminal Input Buffer
.set TIBSIZE, 100

.bss
.balign 4

datastack:
  .space 800
topdatastack:
  .space 8

.balign 2
sysvar_base:

COLON_SMUDGE: .space 4
user_g_in: .space 2
state: .space 2
USER_BASE: .space 2
USER_PAUSE: .space 4
USER_KEY: .space 4
USER_KEYFILE: .space 4
USER_EMIT: .space 4
USER_ARGC: .space 4
USER_ARGV: .space 4
USER_HERE: .space 4
USER_IDLETIME: .space 4
ram_CURRENT: .space 4
ram_CONTEXTidx: .space 2
ram_CONTEXT: .space 4 * 10 @ 10 wordlists max
fflags: .space 2
ram_dp: .space 4
rstack0: .space 4
ram_handler: .space 4
ram_sharptib: .space 2
ram_tib: .space TIBSIZE

EE_FORTHWORDLIST:
  .space 4 @ head pointer
  .space 4 @ name pointer
  .space 4 @ sibling link pointer
  .space 4 @ child pointer

@ start of user ram area
HERESTART:
   .space 64000

@ start of user program area
DPSTART:
   .space 64000

@ start of hard coded program area that can not be modified at runtime
.text

.balign 2

.set VE_HEAD, 0

.include "core.S"
.include "defer.S"
.include "compiler.S"
.include "interpret.S"
.include "asm.S"
.include "file.S"
.include "minimum.S"


@ ( nx* -- ) (R: ny* -- )
@ initialize asforth further. EXECs turnkey operation and go to quit
Forthword_ WARM, 0, "warm"
    push {lr}
    dup_
    mov tos, sp
    bl RP0
    bl STORE
    bl ONLY
    bl RESET
    bl DECIMAL           @ default to decimal base
    type_ "rf 0.1\n"
    @ check if command line args need to be loaded
    bl DOCMDARG
    pop_lr_  
    b QUIT

@ ( -- addr)
@ start address of the data stack
Forthword_ SP0, 0, "sp0"
  dup_
  ldr tos, addr_dstack
  bx lr

.global main
@ ( -- )
@ start up asforth.
Forthword_ COLD, 0, "cold"
.thumb_func
main:
    push {lr} @ save return
    @ save r0 and r1 which contain command line arguments
    push {r0, r1}
    bl set_input_mode
    @ initialize data stack
    ldr dsp, addr_dstack
    @ initialize sysvar pointer
    ldr sysvar, addr_sysvar

    bl WIPE
    pop {r0, r1}
    @ save r0 and r1
    dup_
    movs tos, r0
    dup_
    movs tos, r1
    bl ARGVADDR
    bl STORE
    bl ARGCADDR
    bl STORE
    bl WARM

    mov r0, tos
    pop {pc}

.balign 4
@ ram pointers that need relocation on startup
addr_dstack: .word topdatastack
addr_sysvar: .word sysvar_base
addr_dpstart: .word DPSTART

