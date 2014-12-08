@ interpret.S

@ ( -- addr )
@ terminal input buffer address
Forthword_ TIB, 0, "tib"
    pushsysv_  ram_tib


@ ( -- addr-half )
@ variable holding the number of characters in TIB
@ is half cell size
Forthword_ SHARPTIB, 0, "#tib"
    pushsysv_ ram_sharptib

@ ( -- addr len )
@ address and current length of the input buffer
Forthword_ STIB, 0, "stib"
    push {lr}
    bl TIB
    bl SHARPTIB
    bl HFETCH
    pop {pc}

@ ( -- a-addr )
@ index to current read position in input buffer
@ is half cell size
Forthword_ G_IN, 0, ">in"
    pushsysv_ user_g_in


@ ( c -- )
@ fetch the emit vector and EXEC it. Will emit a character from TOS
Forthword_ EMIT, 0, "emit"
  push {lr}
  mov r0, tos
  poptos_
  bl putchar
  pop {pc}

@ ( -- )
@ cause subsequent output appear at the beginning of the next line
Forthword_ CR, 0, "cr"
  push {lr}
  doliteral_ 13
  bl EMIT
  bl TEN
  bl EMIT
  pop {pc}

@ ( -- 32 )
@ put ascii code of the blank/space character to the stack
Forthword_ BL, 0, "bl"
    doliteral_ 32
    bx lr

@ ( -- key )
@ fetch key vector and EXEC it, should leave a single character on TOS
Forthword_ KEY, 0, "key"
  push {lr}
  bl getchar
  pushtos_
  mov tos, r0
  pop {pc}

@ ( -- f )
@ refills the input buffer
Forthword_ REFILL, 0, "refill"
  push {lr}
  bl REFILLTIB
  pop {pc}

@ ( addr n -- )
@ print a counted string
Forthword_ TYPE, 0, "type"
   push {lr}
   niptoa_           @ Address of string
   dupzerosense_
   b TYPE2

TYPE1:
   acfetch_
   acplus_
   bl EMIT
   oneminus_

TYPE2:
   bne TYPE1

   drop_
   pop {pc}

@ ( addr1 u1 n -- addr2 u2 )
@ adjust string from addr1 to addr1+n, reduce length from u1 to u2 by n
Forthword_ SLASHSTRING, 0, "/$"
    push {lr}
    over_         @ ( -- addr1 u1 n u1 )
    bl MIN        @ ( -- addr1 u1 n|u1 )
    bl ROT        @ ( -- u1 n addr1 )
    over_         @ ( -- u1 n addr1 n )
    plus_         @ ( -- u1 n addr2 )
    bl RROT       @ ( -- addr2 u1 n )
    minus_        @ ( -- addr2 u2)
    pop {pc}

@ ( addr -- addr+1 n )
@ get string address and length information out of a counted string in flash
Forthword_ ICOUNT, 0, "$l"
    dup_
    oneplus_
    swap_
    hfetch_
    bx lr

@ ( -- addr len )
@ runtime portion of sliteral
@ string literal is located starting at return cell
@ return cell is string length
@ string then occupies the following cells: c2c1 c4c3 ...
Forthword_ DOSLIT, 0, "(slit)"
  @ get return address to get string length, calculate string address start,
  @ and calculate return address
  pushtos_
  mov tos, lr    @ ( raddr )  (R: raddr -- )
  dup_           @ ( raddr raddr )
  @ get the string length
  oneminus_      @ account for odd address number because using thumb instructions
  hfetch_        @ ( raddr slength )
  over_          @ ( raddr slength raddr )
  @ calculate string address
  oneplus_       @ ( raddr slength straddr )
  @ calculate the number of words to skip over for return address
  bl FLIP        @ ( straddr slength raddr )
  over_          @ ( straddr slength raddr slength)
  bl HALIGN      @ ( straddr slength raddr k )
  plus_          @ ( straddr slength raddr+k )
  @ also skip string length
  twoplus_       @ ( straddr slength raddr+k+2 )
  mov lr, tos
  poptos_
  bx lr

@ ( -- )
@ send the READY prompt to the command line
Forthword_ PROMPTRDY, 0, ".>"
    push {lr}
    bl CR
    bl DOSLIT
    ascii_ "> "
    bl TYPE
    pop {pc}

@ ( -- )
@ send the READY prompt to the command line
Forthword_ PROMPTCOMPILE, 0, ".:"
    push {lr}
    bl CR
    bl DOSLIT
    ascii_ ": "
    bl TYPE
    pop {pc}

@ ( -- )
@ send the OK prompt to the command line
Forthword_ PROMPTOK, 0, ".ok"
    push {lr}
    bl DOSLIT
    ascii_ " ok"
    bl TYPE
    pop {pc}

@ ( n -- )
@ process the error prompt
Forthword_ PROMPTERROR, 0, ".??"
    push {lr}
    bl DOSLIT
    ascii_ " ?? "
    bl TYPE
    bl PHEX
    pop {pc}

@ ( -- flag )
@ receive a string of at most tibsize characters or cr/lf detected.
@ flag will be true if input buffer needs to be processed ie interpreted
@ flag will be false if more input needed
Forthword_ ACCEPT, 0, "accept"
    push {lr}
    @ <begin>
    bl KEY        @ ( k )
    cmp tos, #0
    bgt ACCEPT_haskey
    add tos, #1
    pop {pc}

ACCEPT_haskey:
    @ check for EOL
    cmp tos, #10
    @ <if>
    bne ACCEPT_checkreturn
    pop {pc}

ACCEPT_checkreturn:
    cmp tos, #13     @ ( k k 13 )
    @ <if>
    bne ACCEPT_checkdelete
    pop {pc}

ACCEPT_checkdelete:
    @ check delete
    cmp tos, #127      @ ( k k 8 )
    @ <if>
    bne ACCEPT_checkcontrol
    @ delete previous character
    @ check beginning of line
    @ if cursor is 0 then at begining of input
    bl SHARPTIB
    hfetch_          @ ( k #tib )
    @ <if>
    zerosense_            @ ( k )
    bne ACCEPT_dodelete
    @ at the beginning of the line, ignore this character
    drop_
    bl ZERO
    pop {pc}

ACCEPT_dodelete:
    mov r0, #8
    and tos, r0
    dup_              @ ( k k )
    bl EMIT           @ ( k )
    bl BL             @ ( k bl )
    bl EMIT           @ ( k )
    bl EMIT           @ ( )
    @ decrease cursor position by one
    bl TRUE           @ ( -1 )
    bl SHARPTIB       @ ( -1 #tibaddr )
    bl HPLUSSTORE     @ ( )
    b ACCEPT_checkmaxinput


ACCEPT_checkcontrol:
    @ check for remaining control characters, replace them with blank
    cmp tos, #32         @ ( k k bl )
    bge ACCEPT_echo
    drop_
    @ replace control key with a space
    bl BL

ACCEPT_echo:
    @ emit the key
    dup_                 @ ( k k)
    bl EMIT              @ ( k)
    @ now store the key in the input buffer
    bl STIB              @ ( k tibaddr #tib)
    plus_                @ ( k tibaddr+#tib )
    bl CSTORE            @ ( )

    bl SHARPTIB          @ ( 1 #tibaddr )
    bl ONEHPLUSSTORE     @ ( )

ACCEPT_checkmaxinput:
    @ check if max number of char input
    doliteral_ TIBSIZE   @ ( tibsize )
    bl SHARPTIB          @ ( tibsize #tibaddr )
    bl HFETCH            @ ( tibsize #tib)
    minus_               @ ( tibsize-#tib)
    @ <if>
    zerosense_           @ ( )
    beq ACCEPT_atmaxinput
    bl ZERO
    pop {pc}

ACCEPT_atmaxinput:
    @ max number of characters in input buffer so have it processed
    bl TRUE
    pop {pc}

@ ( -- f )
@ refills the input buffer - flag is true if buffer has something
Forthword_ REFILLTIB, 0, "reftib"
    push {lr}
    bl ACCEPT                  @ ( f )
    dupzerosense_              @ ( f )
    beq REFILLTIB_exit
    bl CR

REFILLTIB_exit:
    pop {pc}
