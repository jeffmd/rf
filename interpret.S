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
    douser_ ram_sharptib

@ ( -- addr len )
@ address and current length of the input buffer
Forthword_ STIB, 0, "stib"
    push {lr}
    bl TIB
    bl SHARPTIB
    hfetch_
    pop {pc}

@ ( -- a-addr )
@ index to current read position in input buffer
@ is half cell size
Forthword_ G_IN, 0, ">in"
    douser_ user_g_in

@ ( -- pauseaddr )
@ get ram address of pause defer
Forthword_ PAUSEADDR, 0, "pause#"
    douser_ USER_PAUSE

@ ( -- keyaddr )
@ get ram address of key defer
Forthword_ KEYADDR, 0, "key#"
    douser_ USER_KEY

@ ( -- emitaddr )
@ get ram address of emit defer
Forthword_ EMITADDR, 0, "emit#"
    douser_ USER_EMIT

@ ( -- keyfileaddr )
@ get ram address of key file descriptor
Forthword_ KEYFILEADDR, 0, "keyf#"
    douser_ USER_KEYFILE

@ ( -- argcaddr )
@ get ram address of command line argument count
Forthword_ ARGCADDR, 0, "argc#"
    douser_ USER_ARGC

@ ( -- cmd[]addr )
@ get ram address of command line argument vector
Forthword_ ARGVADDR, 0, "argv#"
    douser_ USER_ARGV

@ ( c -- )
@ fetch the emit vector and EXEC it. Will emit a character from TOS
Forthword_ PUTCHAR, 0, "putchar"
  mov r0, tos
  poptos_
  b putchar

@ ( c -- )
@ fetch the emit vector and EXEC it. Will emit a character from TOS
Forthword_ EMIT, 0, "emit"
  push {lr}
  bl EMITADDR
  fetch_
  pop_lr_
  b EXEC

@ ( -- )
@ cause subsequent output appear at the beginning of the next line
Forthword_ CR, 0, "cr"
  push {lr}
  dolit8_ 13
  bl EMIT
  ten_
  pop_lr_ 
  b EMIT

@ ( -- 32 )
@ put ascii code of the blank/space character to the stack
Forthword_ BL, 0, "bl"
    bl_
    bx lr
    

@ ( -- key )
@ fetch key from standard input, should leave a single character on TOS
@ if a key was pressed. If no key pressed then -1 is on TOS.
Forthword_ STDIN, 0, "stdin"
  push {lr}
  bl getchar
  pushtos_
  mov tos, r0
  pop {pc}

@ ( -- key )
@ fetch key from an open file using filedes, should leave
@ a single character on TOS or -1 if no more to read in file.
Forthword_ KEYFILE, 0, "keyfile"
  push {lr}
  bl KEYFILEADDR
  fetch_
  movs r0, tos
  movs tos, #0
  pushtos_
  mov r1, dsp
  movs r2, #1
  bl read 
  poptos_
  @ was one key read from the file?
  cmp r0, #1
  beq.n KEYEND
  subs tos, #1
  bl BYE  
 KEYEND:
  pop {pc}

@ ( -- key )
@ fetch key from deffered routine, should leave a single character
@ on TOS if a key was pressed. If no key pressed then -1 is on TOS.
Forthword_ KEY, 0, "key"
  push {lr}
  bl KEYADDR
  fetch_
  pop_lr_
  b EXEC

@ ( -- f )
@ refills the input buffer
Forthword_ REFILL, 0, "refill"
  b REFILLTIB

@ ( addr n -- )
@ print a counted string
Forthword_ TYPE, 0, "type"
   push {lr}
   niptoa_           @ Address of string
   dupzerosense_
   beq.n TYPE_END

TYPE1:
   acfetch_
   acplus_
   bl EMIT
   oneminus_

TYPE2:
   bne.n TYPE1
   
TYPE_END:
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

@ ( r-addr r-len f-addr f-len --  f)
@ compares string in RAM with string in flash
Forthword_ MCMP, 0, "mcmp"
    push {lr}
    tob_                     @ ( r-addr r-len f-addr)  B: f-len
    over_                    @ ( r-addr r-len f-addr r-len)
    @getb_                    @ ( r-addr r-len f-addr r-len f-len )
    @ check if strings are same length
    eors tos, breg            @ ( r-addr r-len f-addr flag )
    @ if
    zerosense_               @ ( r-addr r-len f-addr )
    beq.n MCMP_SAMELEN

    @ strings are not the same length
    dnip_
    zerotos_                 @ ( 0 )
    pop {pc}

    @ then
MCMP_SAMELEN:
    @twostar_                @ ( r-addr len f-addr*2 )
    toa_                     @ ( r-addr len ) A: f-addr
    oneplus_                 @ ( r-addr len+1 )
    twoslash_                @ ( r-addr (len+1)/2 )

    @ begin
MCMP_LOOP:
    copytob_                 @ ( r-addr len ) B: len
    @ while
    zerosense_               @ ( r-addr )
    beq.n MCMP_DONE

    dup_                     @ ( r-addr r-addr )
    hfetch_                  @ ( r-addr r-cc )
    ahfetch_                 @ ( r-addr r-cc f-cc )
    ahplus_
    @ flash strings are zero-padded at the last cell
    @ that means: if the flash cell is less $0100, than mask the
    @ high byte in the ram cell
    dup_                     @ ( r-addr r-cc f-cc f-cc )
    pushtos_
    movs tos, #80             @ ( r-addr r-cc f-cc f-cc 0x100 )
    adds tos, tos
    bl ULESS                 @ ( r-addr r-cc f-cc flag)
    @ if
    zerosense_
    beq.n MCMP_LASTCELL
    swap_                    @ ( r-addr f-cc r-cc)
    movs r0, #255
    ands tos, r0              @ ( r-addr f-cc 0:r-cc)
    @ then
MCMP_LASTCELL:
    xor_                     @ ( r-addr flag)
    @ if
    zerosense_               @ ( r-addr )
    beq.n MCMP_NEXTLOOP

    @ strings don't match
    zerotos_                 @ ( 0 )
    pop {pc}

    @ then
MCMP_NEXTLOOP:
    twoplus_                 @ ( r-addr+2 )
    getb_                    @ ( r-addr+2 len )
    oneminus_                @ ( r-addr+2 len-1 )

    @ repeat
    b.n MCMP_LOOP

MCMP_DONE:
    @ strings are the same
    drop_
    true_
    pop {pc}


@ ( addr -- addr+2 n )
@ get string address and length information out of a counted string
Forthword_ STRINGLEN, 0, "$l"
    dup_
    twoplus_
    swap_
    hfetch_
    bx lr

@ ( addr1 n1 c -- n2 )
@ skips leading occurances in string at addr1 leaving n2 as an index
@ pointing to the 1st non-c character
@ n1 is max number of characters to search
Forthword_ CSKIP, 0, "cskip"
    tob_                 @ ( addr1 n1 ) B: c
    niptoa_              @ ( n1 ) A: addr1
    dup_                 @ ( n1 n1 )
PFA_CSKIP1:
    dupzerosense_        @ ( n1 n')
    beq.n PFA_CSKIP2
    acfetch_             @ ( n1 n' c' )
    acplus_
    cmp tos, breg        @ ( n1 n' c' )
    drop_                @ ( n1 n' )
    bne.n PFA_CSKIP2
    oneminus_
    b.n PFA_CSKIP1

PFA_CSKIP2:
    minus_               @ ( n1-n' )
    bx lr

@ ( addr1 n1 c -- addr1 n2 )
@ Scan string at addr1 for the first occurance of c, leaving addr1 n2,
@ n1 is max number of characters to search
@ char at n2 is first c character
Forthword_ CSCAN, 0, "cscan"
    tob_                 @ ( addr1 n1 ) B: c
    over_                @ ( addr1 n1 addr1 )
    toa_                 @ ( addr1 n1 ) A: addr1
    dup_                 @ ( addr1 n1 n1 )
PFA_CSCAN1:
    dupzerosense_        @ ( addr1 n1 n')
    beq.n PFA_CSCAN2
    acfetch_             @ ( addr1 n1 n' c' )
    acplus_
    cmp tos, breg        @ ( addr1 n1 n' c' )
    drop_                @ ( addr1 n1 n' )
    beq.n PFA_CSCAN2
    oneminus_
    b.n PFA_CSCAN1

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
    pop_lr_
    b SLASHSTRING     @ ( srcaddr' len' )


@ ( -- )
@ skip space in input source.
Forthword_ SKIPBL, 0, "skipbl"
    push {lr}
    bl SRCIN             @ ( srcaddr len )
    bl_                  @ ( srcaddr' len' c )
    bl CSKIP             @ ( n2 )

    @ adjust >IN
    bl G_IN              @ ( n2 ginaddr )
    pop_lr_
    b PLUSHSTORE        @ (  )

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
    pop_lr_
    b PLUSHSTORE    @ ( -- addr' len'')


@ ( "<name>" -- c-addr len )
@ In the SOURCE buffer parse whitespace delimited string. Returns string address within SOURCE.
Forthword_ PNAME, 0, "pname"
    push {lr}
    bl SKIPBL
    bl_
    pop_lr_
    b PARSE

@ ( c-addr len wid -- [ 0 | nfa ] )
@ find a word in the dictionary
@ 0 if word not found in dictionary
@ nfa if word is found
Forthword_ FINDNFA, 0, "findnfa"
    push {lr}
    dupzerosense_
    bne.n FINDNFA_
      @ terminating, wid is empty
      dnip_
      pop {pc}
FINDNFA_:
    fetch_                      @ ( c-addr len nfa )

    @ <begin>
FINDNFA_BEGIN:
    @ <while>
    dupzerosense_               @ ( c-addr len nfa )
    bne.n FINDNFA_CHECK
      @ terminating, 0 found
      dnip_                     @ ( 0 )
      pop {pc}

FINDNFA_CHECK:
    to_r_                       @ ( c-addr len ) (R: nfa )
    bl TWOOVER                  @ ( c-addr len c-addr len )
    r_fetch_                    @ ( c-addr len c-addr len nfa )
    bl STRINGLEN                @ ( c-addr len c-addr len f-addr len )
    movs r0, #31
    ands tos, r0                 @ ( c-addr len c-addr len f-addr 0:len )
    bl MCMP                     @ ( c-addr len flag )
    @ <if>
    zerosense_
    beq.n FINDNFA_NEXT
      @ we found the string
      ddrop_                    @ ( )
      r_from_                   @ ( nfa )
      pop {pc}
    @ <then>
FINDNFA_NEXT:
      @ next try
      r_from_
      bl NFA2LFA
      fetch_
      @ <repeat>
      b.n FINDNFA_BEGIN


@ ( addr len --  0 | nfa )
@ search root wordlists for the name from string addr/len
Forthword_ FINDROOT, 0, "froot"
    push {lr}
    @ put root wid on stack
    dolit32_ VE_COLD
    b.n FINDNFA_BEGIN

@ ( addr len idx -- 0 | nfa )
FINDWI:
      push {lr}
      fourstar_          @ ( addr len idx*4)
      bl CONTEXT         @ ( addr len idx*4 context )
      plus_              @ ( addr len context' )
      fetch_             @ ( addr len wid )
      pop_lr_
      b FINDNFA         @ ( nfa)

FINDLAST:
      drop_
      pop_lr_
      b FINDROOT

@ ( addr len --  0 | nfa )
@ search wordlists for the name from string addr/len
Forthword_ FINDW, 0, "findw"
    push {lr}
    @ loop through context slots to find a word
    @ start with last slot
    bl CONTEXT          @ ( addr len context )
    @ get context index and use as counter
    twominus_           @ ( addr len context-2 )
    hfetch_             @ ( addr len idx )
FINDW_BEGIN:
    dupzerosense_
    bmi.n FINDLAST        @ ( addr len idx )
      to_r_             @ ( addr len ) ( R: idx )
      bl TWOOVER        @ ( addr len addr len ) ( R: idx )
      @ get next wordlist in array
      r_fetch_          @ ( addr len addr len idx ) ( R: idx)
      bl FINDWI
      r_from_           @ ( addr len nfa idx ) ( R: )
      swap_             @ ( addr len idx nfa )
      dupzerosense_
      @ end loop if word found
      beq.n FINDW_NEXT
        dnip_           @ ( addr nfa )
        nip_            @ ( nfa )
        pop {pc}

FINDW_NEXT:
      drop_             @ ( addr len idx )
      @ decrement index
      oneminus_         @ ( addr len idx-1 )
      b.n FINDW_BEGIN


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

@ ( addr len -- [n] [addr len] f )
@ recognizer for integer numbers
Forthword_ REC_NUM, 0, "rec#"
    push {lr}
    bl TWOOVER
    to_r_
    to_r_
    @ try converting to a number
    bl NUMBER              @ ( [n] f )
    zerosense_
    beq.n REC_NONUMBER

      bl STATEFETCH        @ ( n state )
      zerosense_
      beq.n REC_NUMBER_OK
        bl LIT

REC_NUMBER_OK:
      r_drop_
      r_drop_
      true_                @ ( n true )
      pop {pc}

REC_NONUMBER:
    r_from_
    r_from_
    zero_                  @ ( 0 )
    pop {pc}


@ ( addr len -- ** [addr len] f )
@ recognize a word in the dictionary
Forthword_ REC_WORD, 0, "recw"
    push {lr}
    bl TWOOVER
    to_r_
    to_r_
    bl FINDW
    dupzerosense_
    bne.n REC_WORD_FOUND
      r_from_
      r_from_
      pop_lr_
      b ROT

REC_WORD_FOUND:
    r_drop_
    r_drop_
    bl NFATOXTF
    @ check if compile only word
    @sbrc tosh, COMPILE_ONLY_FB
    @    rjmp CHECK_IMMEDIATE

@CHECK_COMPILE_ONLY:
@    bl STATEFETCH
@    zerosense_
@    bne.n CHECK_IMMEDIATE
        @ word can only be used in compile state
        @jmp THROW


@CHECK_IMMEDIATE:
  @ either compile or EXEC the XT
    @ check if word is immediate: bit 15 is clear if immediate
  @sbrs tosh, IMMEDIATE_EN_FB @ skip next instruction if bit 7 is set: not immediate word
  movs r0, #IMMEDIATE_EN
  lsls r0, #8
  tst tos, r0
  @ flag is 0: always EXEC
  beq.n REC_WORD_EXECUTE

REC_WORD_CHECKSTATE:
        @ check state
      bl STATEFETCH
      zerosense_
      beq.n REC_WORD_EXECUTE
        @ in compile mode so compile xt
      bl COMPILEXT
      true_
      pop {pc}

REC_WORD_EXECUTE:
    drop_
    @ state is zero, EXEC xt
    bl EXEC
REC_WORD_OK:
    true_
    pop {pc}



@ ( addr len -- )
@ recognize and execute name of word in ram using recognizer list.
Forthword_ RECX, 0, "recx"
    push {lr}
    @ test if its a word
    bl REC_WORD           @ ( flag ) ( R: len addr )
    @ <if>
    zerosense_            @ ( addr len )
    bne.n RECX_DONE
    @ test if its a number
    bl REC_NUM            @ ( flag ) ( R: len addr )
    zerosense_            @ ( addr len )
    bne.n RECX_DONE
    @ not recognized so throw
    bl CR
    @ print unrecognized word
    bl TYPE
    @doliteral_ 0xBAD
    
    $lit_ " Unknown!"
    bl THROW

RECX_DONE:
    pop {pc}


@ ( -- ) (R: i*x - j*x )
@ interpret input word by word.
Forthword_ INTERPRET, 0, "interp"
    push {lr}
INTERPRET_DO:
    @ begin
    bl PNAME            @ ( -- addr len )

    @ ?while
    dupzerosense_       @ ( -- addr len )
    beq.n INTERPRET_END

    bl RECX             @ ( )
    bl QSTACK           @ ( )

    @ repeat
    b.n INTERPRET_DO

INTERPRET_END:
    ddrop_
    pop {pc}


@ ( -- )
@ send the READY prompt to the command line
Forthword_ PROMPTRDY, 0, ".>"
    push {lr}
    type_ "\n> "
    pop {pc}

@ ( -- )
@ send the READY prompt to the command line
Forthword_ PROMPTCOMPILE, 0, ".:"
    push {lr}
    type_ "\n: "
    pop {pc}

@ ( -- )
@ send the OK prompt to the command line
Forthword_ PROMPTOK, 0, ".ok"
    push {lr}
    type_ " ok"
    pop {pc}

@ ( n -- )
@ process the error prompt
Forthword_ PROMPTERROR, 0, ".??"
    push {lr}
    drop_
    type_ " ?? "
    pop {pc}

@ ( -- )
@ check if a ready prompt is required
Forthword_ QP_RD, 0, "?prd"
    push {lr}
    bl STATEFETCH
    @ output ready prompt if in interpret mode
    @ <-if>
    zerosense_
    bne.n QP_RD_exit
      pop_lr_
      b PROMPTRDY

QP_RD_exit:
    @ <then>
      pop_lr_
      b PROMPTCOMPILE

@ ( -- )
@ Reset the input buffer
Forthword_ INRESET, 0, "in_"
  push {lr}
  bl G_IN                @ ( >inaddr )
  bl ZEROHSTORE          @ (  )
  @ reset input buffer cursor position
  bl SHARPTIB            @ ( #tibaddr )
  bl ZEROHSTORE          @ ( )
  pop_lr_
  b QP_RD

@ ( -- flag )
@ refill the input buffer
@ flag is true if buffer needs processing ie full or enter pressed
Forthword_ DOREFILL, 0, "(refill)"
  push {lr}
  @ if just starting new input line then check prompt and reset input position
  bl G_IN                  @ ( >inaddr )
  hfetch_                  @ ( >in )
  zerosense_               @ ( )
  beq.n DOREFILL_do
    bl INRESET

DOREFILL_do:
  @ refill the input buffer
  bl REFILL                @ ( f )
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
    pop_lr_
    b HSTORE

@ ( -- )
@ Fetch pause vector and EXEC it. may make a context/task switch
Forthword_ DOPAUSE, 0, "(pause)"
    push {lr}
    bl SLEEP @@ temp fix for cpu hogging
    bl PAUSEADDR
    fetch_
    pop_lr_
    b EXEC

@ ( -- )
@ main loop - iterate through scheduled tasks
Forthword_ DOTASKS, 0, "(tasks)"
    @ <begin>
    push {lr}
DOTASKS1:
    bl DOREFILL      @ ( flag )
    @ <if>
    zerosense_
    beq.n DOTASK_N1
      @ there is something in the input buffer, try interpreting it
      bl DOINTERPRET
DOTASK_N1:
    bl DOPAUSE
    

    @ check to see if tasks should be terminated
    bl FFLAGS
    hfetch_
    bittest_ TERMINATE_F
    @ <again>
    beq.n DOTASKS1
    pop {pc}


@ ( -- )
@ reset input source
Forthword_ RESET, 0, "reset"
    push {lr}
    bl SMUDGE
    bl ZEROSTORE

    @ reset input source for key
    dolit32_ STDIN
    bl KEYADDR
    bl STORE

    @ reset output source for emit
    dolit32_ PUTCHAR
    bl EMITADDR
    bl STORE

    @ reset input buffer
    bl INRESET

    bl SLEEPON
    @ switch to interpret mode
    pop_lr_
    b LBRACKET
    
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
    bl RESET
    pop_lr_
    b DOTASKS

@ ( -- )
@ interpret what is in the input buffer
Forthword_ DOINTERPRET, 0, "(interp)"
  push {lr}
  @ input buffer has something so try to interpret it
  @ setup exception handling in case of error
  dolit32_ INTERPRET
  bl CATCH
  @ check to make sure no throws
  bl QDUP
  @ <if>
  zerosense_
  beq.n DOINTERPRET_ok
    bl PROMPTERROR
    bl QUIT

  @ <then>
DOINTERPRET_ok:
  @ make sure in buf pointer is not at zero
  bl G_IN               @ ( 1 >inaddr )
  bl ONEPLUSHSTORE      @ ( )
  pop_lr_
  b PROMPTOK


@ ( -- flag )
@ receive a string of at most tibsize characters or cr/lf detected.
@ flag will be true if input buffer needs to be processed ie interpreted
@ flag will be false if more input needed
Forthword_ ACCEPT, 0, "accept"
    push {lr}
    @ <begin>
    bl KEY        @ ( k )
    dupzerosense_
    bgt.n ACCEPT_haskey
    adds tos, #1
    pop {pc}

ACCEPT_haskey:
    @ check for EOL
    cmp tos, #10
    @ <if>
    bne.n ACCEPT_checkreturn
    pop {pc}

ACCEPT_checkreturn:
    cmp tos, #13     @ ( k k 13 )
    @ <if>
    bne.n ACCEPT_checkdelete
    pop {pc}

ACCEPT_checkdelete:
    @ check delete
    cmp tos, #127      @ ( k k 8 )
    @ <if>
    bne.n ACCEPT_checkcontrol
    @ delete previous character
    @ check beginning of line
    @ if cursor is 0 then at begining of input
    bl SHARPTIB
    hfetch_          @ ( k #tib )
    @ <if>
    zerosense_            @ ( k )
    bne.n ACCEPT_dodelete
    @ at the beginning of the line, ignore this character
    drop_
    pop_lr_
    b ZERO

ACCEPT_dodelete:
    movs r0, #8
    ands tos, r0
    dup_              @ ( k k )
    bl EMIT           @ ( k )
    bl_               @ ( k bl )
    bl EMIT           @ ( k )
    bl EMIT           @ ( )
    @ decrease cursor position by one
    bl TRUE           @ ( -1 )
    bl SHARPTIB       @ ( -1 #tibaddr )
    bl PLUSHSTORE     @ ( )
    b.n ACCEPT_checkmaxinput


ACCEPT_checkcontrol:
    @ check for remaining control characters, replace them with blank
    cmp tos, #32         @ ( k k bl )
    bge.n ACCEPT_echo
    drop_
    @ replace control key with a space
    bl_

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
    dolit8_ TIBSIZE   @ ( tibsize )
    bl SHARPTIB          @ ( tibsize #tibaddr )
    bl HFETCH            @ ( tibsize #tib)
    minus_               @ ( tibsize-#tib)
    @ <if>
    zerosense_           @ ( )
    beq.n ACCEPT_atmaxinput
    pop_lr_
    b ZERO

ACCEPT_atmaxinput:
    @ max number of characters in input buffer so have it processed
    pop_lr_
    b TRUE

@ ( -- f )
@ refills the input buffer - flag is true if buffer has something
Forthword_ REFILLTIB, 0, "reftib"
    push {lr}
    bl ACCEPT                  @ ( f )
    dupzerosense_              @ ( f )
    beq.n REFILLTIB_exit
    bl CR

REFILLTIB_exit:
    pop {pc}
