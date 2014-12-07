@ macros.S

sysvar .req r4 @ system variables base pointer
areg .req r5 @ A register used for memory pointer operations
tos .req r6 @ parameter top of stack [TOS] register
dsp .req r7 @ holds the Forth VM Parameter/Data stack pointer

@ header flags
.set HFLAGS, 0xFF
@ low byte is word count : 0 - 255
@ high byte is flags for word
@ enable inlining of word
@ bit 0 : enable inlinning
.set INLINE_OPT_FB, 0
.set INLINE_OPT, 0x01
@ bit 2 : dissable tail call optimization
@ disable tail call optimization : & with word count flag ie: HFLAGS & DIS_CALL_OPT | 04
.set DIS_CALL_OPT, 0x04

@ bit 3 : disable interpret execution ie compile only
.set COMPILE_ONLY_FB, 3
@ set immediate word as compile time only execution
@ disable interpret execution : & with word count flag ie: 0xFF04 & COMPILE_ONLY
.set COMPILE_ONLY, 0x08

@ bit 7 : immediate execution when in compile state
@ enable immediate execution : & with word count flag ie: 0xFF04 & IMMEDIATE_EN
.set IMMEDIATE_EN_FB, 7
.set IMMEDIATE_EN, 0x80

@ forth flags
@ bit 0 : rcall was last instruction
.set LAST_RCALL_FB, 0
@ bit 1 : call was last instruction
.set LAST_CALL_FB, 1
@ if bit 0 and 1 are cleared then last instruction was an inline or tail call optimization was disabled by word
@ bit 2 : disable tail call optimization
.set DIS_CALL_OPT_FB, 2


.macro opdat op, reg, sym
  \op \reg, [r1, #(\sym-Data)]
.endm

@ Inline macros
.macro dup_r_ @ put copy of tos on return stack
    push {tos}
.endm

.macro r_drop_ @ drop TOR
    pop {r0}
.endm

.macro pushtos_ @ save tos, (dup)
  sub dsp, #4
  str tos, [dsp]
.endm

.macro dup_
  pushtos_
.endm

.macro sysv_ sym
    #(\sym - sysvar_base)
.endm

.macro pushsysv_ sym
    dup_
    ldr tos, 7f
    bx lr
.balign 4
7:
    .word \sym
.balign 2
.endm

@ Push small constant on datastack
.macro doliteral_ val
  pushtos_
  mov tos, #\val
.endm


.macro poptos_ @ load tos, (drop)
  ldm dsp!, {tos}
.endm

.macro drop_
  poptos_
.endm


.macro swap_
  ldr r0,  [dsp] @ Load r0 from the stack, no SP change.
  str tos, [dsp] @ Replace it with TOS.
  mov tos, r0    @ And vice versa.
.endm

.macro over_
  pushtos_
  ldr tos, [dsp, #4]
.endm

.macro to_r_
  dup_r_
  drop_
.endm

.macro r_from_
  pushtos_
  pop {tos}
.endm


.macro nip_
  add dsp, #4
.endm

.macro dnip_
  add dsp, #8
.endm

.macro ddrop_
  nip_
  drop_
.endm

.macro plus_
  ldm dsp!, {r0}
  add tos, r0
.endm

.macro minus_
  ldm dsp!, {r0}
  sub tos, r0, tos
.endm

.macro and__
  ldm dsp!, {r0}
  and tos, r0
.endm

.macro or__
  ldm dsp!, {r0}
  orr tos, r0
.endm

.macro xor__
  ldm dsp!, {r0}
  eor tos, r0
.endm

.macro not_
  mvn tos, tos
.endm

.macro oneplus_
  add tos, #1
.endm

.macro oneminus_
  sub tos, #1
.endm

.macro twoplus_
  add tos, #2
.endm

.macro twominus_
  sub tos, #2
.endm

.macro twoslash_
    lsr tos, #1
.endm

.macro twostar_
    lsl tos, #1
.endm

.macro neg_
    neg tos, tos
.endm

.macro dupzerosense_
    cmp tos, #0
.endm

.macro zerosense_
    dupzerosense_
    poptos_
.endm

.macro zero_
    pushtos_
    mov tos, #0
.endm

.macro true_
  zero_
  mvn tos, tos
.endm

.macro lshift_
  ldm dsp!, {r0}
  lsl r0, tos
  mov tos, r0
.endm

.macro rshift_
  ldm dsp!, {r0}
  lsr r0, tos
  mov tos, r0
.endm

.macro fetch_
  ldr tos, [tos]
.endm

.macro hfetch_
  ldrh tos, [tos]
.endm

.macro cfetch_
  ldrb tos, [tos]
.endm

.macro niptoa_
  ldm dsp!, {areg}
.endm

.macro afetch_
  pushtos_
  ldr tos, [areg]
.endm

.macro ahfetch_
  pushtos_
  ldrh tos, [areg]
.endm

.macro acfetch_
  pushtos_
  ldrb tos, [areg]
.endm

.macro aplus_
  add areg, #4
.endm

.macro ahplus_
  add areg, #2
.endm

.macro acplus_
  add areg, #1
.endm

.macro ascii_ str, flg=0
  .p2align 1 @ Align to even locations
  .byte (8f - 7f)
  .byte \flg
7:  .ascii "\str"
8:
  .p2align 1
.endm

.macro Forthword_ lbl, flags, Name

VE_\lbl:
    ascii_ "\name", HFLAGS & ~(\flags)

    .word VE_HEAD
    .set VE_HEAD, VE_\lbl
\lbl:
.endm
