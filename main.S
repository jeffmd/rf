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

COLON_SMUDGE: .space 4
user_g_in: .space 2
state: .space 2
USER_BASE: .space 2
ram_CURRENT: .space 4
ram_CONTEXTidx: .space 2
ram_CONTEXT: .space 4 * 10 @ 10 wordlists max
fflags: .space 2
ram_dp: .space 4
rstack0: .space 4
ram_LATEST: .space 4
ram_handler: .space 4
ram_sharptib: .space 2
ram_tib: .space TIBSIZE

@ start of user ram area
HERESTART:
   .space 16000


.text
.balign 2

eeprom_base:
EE_FORTHWORDLIST:
  .word 0 @ head pointer
  .word 0 @ tail pointer

EE_DP:
    .word DPSTART      @ Dictionary Pointer in flash
EE_HERE:
    .word HERESTART    @ RAM Memory Allocation pointer
EE_EDP:
    .word EDPSTART     @ EEProm Memory Allocation pointer
EE_TURNKEY:
    .word 0            @ TURNKEY

EDPSTART:
  .space 2000

@ start of user program area
DPSTART:
   .space 16000

.set VE_HEAD, 0

.include "core.S"
.include "defer.S"
.include "compiler.S"
.include "interpret.S"
.include "asm.S"
.include "minimum.S"

@ ( nx* -- ) (R: ny* -- )
@ initialize asforth further. EXECs turnkey operation and go to quit
Forthword_ WARM, 0, "warm"
    push {lr}
    pushtos_
    mov tos, sp
    bl RP0
    bl STORE
    bl ONLY
    bl DECIMAL
    bl DOSLIT
    ascii_ "rf 0.1"
    bl TYPE
    bl CR

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

    mov r0, tos
    pop {pc}

.balign 4
@ ram pointers that need relocation on startup
addr_dstack: .word topdstack
addr_sysvar: .word sysvar_base


/* External calls*/
.global putchar
.global getchar
