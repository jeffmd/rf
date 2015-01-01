@ interpret.S

@ ( -- addr )
@ flags address
Forthword_ FFLAGS, 0, "fflags"
    douser_  fflags
    .set TERMINATE_F, 1
    @ bit 0 - Terminate Tasks


@ ( -- addr )
@ terminal input buffer address
Forthword_ TIB, 0, "tib"
    douser_  ram_tib


@ ( -- addr-half )
@ variable holding the number of characters in TIB
@ is half cell size
Forthword_ SHARPTIB, 0, "#tib"
    @pushsysv_ ram_sharptib
    douser_ ram_sharptib

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
    douser_ user_g_in


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

@ ( addr1 n1 c -- n2 )
@ skips leading occurances in string at addr1/n1 leaving n2 as an index pointing to the 1st non-c character
Forthword_ CSKIP, 0, "cskip"
    tob_                 @ ( addr1 n1 ) B: c
    niptoa_              @ ( n1 ) A: addr1
    dup_                 @ ( n1 n1 )
PFA_CSKIP1:
    dupzerosense_        @ ( n1 n')
    beq PFA_CSKIP2
    acfetch_             @ ( n1 n' c' )
    aplus_
    cmp tos, breg        @ ( n1 n' c' )
    drop_                @ ( n1 n' )
    bne PFA_CSKIP2
    oneminus_
    b PFA_CSKIP1

PFA_CSKIP2:
    minus_               @ ( n1-n' )
    bx lr

@ ( addr1 n1 c -- addr1 n2 )
@ Scan string at addr1/n1 for the first occurance of c, leaving addr1 n2,
@ char at n2 is first c character
Forthword_ CSCAN, 0, "cscan"
    tob_                 @ ( addr1 n1 ) B: c
    over_                @ ( addr1 n1 addr1 )
    toa_                 @ ( addr1 n1 ) A: addr1
    dup_                 @ ( addr1 n1 n1 )
PFA_CSCAN1:
    dupzerosense_        @ ( addr1 n1 n')
    beq PFA_CSCAN2
    acfetch_             @ ( addr1 n1 n' c' )
    acplus_
    cmp tos, breg        @ ( addr1 n1 n' c' )
    drop_                @ ( addr1 n1 n' )
    beq PFA_CSCAN2
    oneminus_
    b PFA_CSCAN1

PFA_CSCAN2:
    minus_               @ ( addr1 n1-n' )
    bx lr

@ ( -- srcaddr len  )
@ Adjust the source addr using >in.
Forthword_ SRCIN, 0, "srcin"
    push {lr}
    bl STIB            @ ( srcaddr len )
    bl G_IN            @ ( srcaddr len ginaddr )
    hfetch_            @ ( srcaddr len gin)
    bl SLASHSTRING     @ ( srcaddr' len' )
    pop {pc}


@ ( -- )
@ skip space in input source.
Forthword_ SKIPBL, 0, "skipbl"
    push {lr}
    bl SRCIN             @ ( srcaddr len )
    bl BL                @ ( srcaddr' len' c )
    bl CSKIP             @ ( n2 )

    @ adjust >IN
    bl G_IN              @ ( n2 ginaddr )
    bl PLUSHSTORE        @ (  )
    pop {pc}

@ ( char "ccc<char>" -- c-addr u )
@ in input buffer parse ccc delimited string by the delimiter char.
Forthword_ PARSE, 0, "parse"
    push {lr}
    bl SRCIN         @ ( -- c addr len)
    bl ROT           @ ( -- addr' len' c)
    bl CSCAN         @ ( -- len'')
    dup_             @ ( -- addr' len'' len'')
    oneplus_         @ ( -- addr' len'' len''+1 )
    bl G_IN          @ ( -- addr' len'' len''+1 >in)
    bl PLUSHSTORE    @ ( -- addr' len'')
    pop {pc}


@ ( "<name>" -- c-addr len )
@ In the SOURCE buffer parse whitespace delimited string. Returns string address within SOURCE.
Forthword_ PNAME, 0, "pname"
    push {lr}
    bl SKIPBL
    bl BL
    bl PARSE
    pop {pc}


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

@ ( -- ) (R: i*x - j*x )
@ interpret input word by word.
Forthword_ INTERPRET, 0, "interp"
    push {lr}
INTERPRET_DO:
    @ begin
    bl PNAME            @ ( -- addr len )

    @ ?while
    dupzerosense_       @ ( -- addr len )
    beq INTERPRET_END

    @bl RECX             @ ( )
    @bl QSTACK           @ ( )
    ddrop_
    @ repeat
    b INTERPRET_DO

INTERPRET_END:
    ddrop_
    pop {pc}


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

@ ( -- )
@ check if a ready prompt is required
Forthword_ QP_RD, 0, "?prd"
    push {lr}
    bl STATEFETCH
    @ output ready prompt if in interpret mode
    @ <-if>
    zerosense_
    bne QP_RD_exit
      bl PROMPTRDY
      pop {pc}
QP_RD_exit:
    @ <then>
      bl PROMPTCOMPILE
      pop {pc}

@ ( -- )
@ wait for the input buffer to be refilled then interpret
Forthword_ DOREFILL, 0, "(refill)"
  push {lr}
  @ if just starting new input line then check prompt and reset input position
  bl G_IN                  @ ( >inaddr )
  hfetch_                  @ ( >in )
  zerosense_               @ ( )
  beq DOREFILL_do
    bl G_IN                @ ( >inaddr )
    bl ZEROHSTORE          @ (  )
    @ reset input buffer cursor position
    bl SHARPTIB            @ ( #tibaddr )
    bl ZEROHSTORE          @ ( )
    bl QP_RD
    pop {pc}

DOREFILL_do:
  @ refill the input buffer
  bl REFILL                @ ( f )
  @ <if>
  zerosense_
  beq DOREFILL_end

    @ there is something in the input buffer, try interpreting it
    bl DOINTERPRET

DOREFILL_end:
  @ <then>
  pop {pc}

@ ( -- )
@ set terminate flag which indicates request to exit forth interpreter
Forthword_ BYE, 0, "bye"
    push {lr}
    one_
    bl FFLAGS
    hfetch_
    or_
    bl FFLAGS
    bl HSTORE
    pop {pc}

@ ( -- )
@ Fetch pause vector and EXEC it. may make a context/task switch
Forthword_ PAUSE, 0, "pause"
    push {lr}
    @bl DODEFER
    @.word USER_PAUSE
    pop {pc}

@ ( -- )
@ main loop - iterate through scheduled tasks
Forthword_ DOTASKS, 0, "(tasks)"
    @ <begin>
    push {lr}
DOTASKS1:
    bl DOREFILL
    bl PAUSE

    @ check to see if tasks should be terminated
    bl FFLAGS
    hfetch_
    bittest_ TERMINATE_F
    @ <again>
    beq DOTASKS1
    pop {pc}

@ ( -- )
@ reset stacks and start over again
Forthword_ QUIT, 0, "quit"
    push {lr}
    @ reset data stack
    bl SP0
    bl SP_STORE
    @ reset return stack pointers
    bl RP0
    fetch_
    bl RP_STORE
    bl SMUDGE
    bl ZEROSTORE

    @ switch to interpret mode
    bl LBRACKET

    bl DOTASKS
    pop {pc}

@ ( -- )
@ interpret what is in the input buffer
Forthword_ DOINTERPRET, 0, "(interp)"
  push {lr}
  @ input buffer has something so try to interpret it
  @ setup exception handling in case of error
  pushtos_
  ldr tos, =INTERPRET
  bl CATCH
  zero_
  @ check to make sure no throws
  bl QDUP
  @ <if>
  zerosense_
  beq DOINTERPRET_ok
    bl PROMPTERROR
    bl QUIT

  @ <then>
DOINTERPRET_ok:
  @ make sure in buf pointer is not at zero
  bl G_IN               @ ( 1 >inaddr )
  bl ONEPLUSHSTORE      @ ( )
  bl PROMPTOK
    bl BYE
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
    bl PLUSHSTORE     @ ( )
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
    bl ONEPLUSHSTORE     @ ( )

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
