
\ ( "ccc<paren>" -- )
\ Compiler
\ skip everything up to the closing bracket on the same line
: (
    $29 parse
    2drop
; immediate


( -- )
\ make most current word compile only
: :c
    $F7FF widf
; immediate

( -- )
\ make most current word inlinned
: inlined
    $FEFF widf
; immediate

( -- )
\ make most current word immediate and compile only
: :ic
    $77FF widf
; immediate

\ search dictionary for name, returns XT or 0
: 'f  ( "<spaces>name" -- XT XTflags )
    pname
    findw
    nfa>xtf
;


\ search dictionary for name, returns XT
: '  ( "<spaces>name" -- XT )
    'f
    drop
;

\ force compile any word including immediate words
: [compile]
  'f cxt
; :ic

( -- ) ( C: "<space>name" -- )
\ Compiler
\ what ' does in the interpreter mode, do in colon definitions
\ compiles xt as literal
: [']
    '
    lit
; :ic


( -- ) ( C: "<space>name" -- )
\ Compiler
\ what 'f does in the interpreter mode, do in colon definitions
\ and xt and flag are compiled as two literals
: ['f]
    'f
    swap
    lit
    lit
; :ic

( C:"<spaces>name" -- 0 | nfa )
\ Dictionary
\ search dictionary for name, returns nfa if found or 0 if not found
: find
    pname findw
;


\ read the following cell from the executing word and append it
\ to the current dictionary position.
: (compile)  ( -- )
    r>r+     ( raddr ) ( R: raddr+1 )
    @        ( nfa )
    nfa>xtf  ( xt xtflags )
    cxt
;

\ compile into pending new word
: compile ( C: x "<spaces>name" -- )
  ['f] (compile) cxt
  find ,,
; :ic


( -- ) ( C: x "<spaces>name" -- )
\ create a dictionary entry and register in word list
: rword
    (create)      ( voc-link )
    cur@          ( voc-link wid )
    !             ( )
;

( -- ) ( C: "<spaces>name" -- )
\ Dictionary
\ create a dictionary header that will push the address of the
\ data field of name.
\ is used in conjunction with does>
: create
    rword
    \ leave address after call on tos
    compile popret
;


\ copy the first character of the next word onto the stack
: char  ( "<spaces>name" -- c )
    pname
    drop
    c@
;

( -- c ) ( C: "<space>name" -- )
\ skip leading space delimites, place the first character
\ of the word on the stack
: [char]
    char
    lit
; immediate

( -- )
\ replace the instruction written by CREATE to call the code that follows does>
\ does not return to caller
\ this is the runtime portion of does>
: (does>)
    \ change call at XT to code after (does>)
    \ code at XT is 'bl POPRET'
    \ want to change POPRET address to return address
    r>                        ( retaddr )
    \ remove thumb flag - will be using for memory access
    1-
    \ get address of bl POPRET
    \ get current word and then get its XT being compiled
    cur@ @                    ( retaddr nfa )
    nfa>lfa                   ( retaddr lfa )
    \ skip over lfa to get to xt
    dcell+                    ( retaddr xt )
    \  skip over push {lr}
    icell+                    ( retaddr xt+2 )
    \ temp save dp on return stack
    dp# @ >r
    \ set dp to xt+2
    dup dp# !                 ( retaddr xt+2 )
    \ modify the bl
    \ calc displacement
    reldst                    ( dst )
    \ compile a bl instruction
    bl,                       ( )
    \ restore dp
    r> dp# !                  ( )
;

( -- )
\ Compiler
\ organize the XT replacement to call other colon code
\ used in conjunction with create
\ ie: : name create .... does> .... ;
: does>
    \ compile pop return to tos which is used as 'THIS' pointer
    compile (does>)
    compile lr>
    compile 1-
; :ic

( -- xt )
\ Compiler
\ create an unnamed entry in the dictionary
: :noname
    dp
    dup
    latest
    ! ]
;

( -- start )
\ Compiler
\ places current dictionary position for forward
\ branch resolve on TOS and advances DP
: >mark
    dp
    dp+1           \ advance DP to allow branch/jmp
;

( start -- )
\ Compiler
\ do forward jump
: >jmp
    ?sp              ( start ) \ check stack integrety
    dp               ( start dest )
    rjmpc            ( )
;

( -- dest )
\ Compiler
\ place destination for backward branch
: <mark
    dp            ( dest )
;

( dest -- )
\ Compiler
\ do backward jump
: <jmp
    ?sp            \ make sure there is something on the stack
    \ compile a rjmp at current DP that jumps back to mark
    dp             \ ( dest start )
    swap           \ ( start dest )
    rjmpc
    dp+1           \ advance DP
;


\ Compiler
\ compile zerosense and conditional branch forward
: ?brc

    compile 0?       \ inline zerosense
    bne1,
;

\ compile dupzerosense and conditional branch forward
: ??brc
    compile ?0?
    bne1,
;


( f -- ) ( C: -- orig )
\ Compiler
\ start conditional branch
\ part of: if...[else]...then
: if
   ?brc
   >mark
; :ic

( f -- f ) ( C: -- orig )
\ Compiler
\ start conditional branch, don't consume flag
: ?if
    ??brc
    >mark
; :ic


( C: orig1 -- orig2 )
\ Compiler
\ resolve the forward reference and place
\ a new unresolved forward reference
\ part of: if...else...then
: else
    >mark         \ mark forward rjmp at end of true code
    swap          \ swap new mark with previouse mark
    >jmp          \ rjmp from previous mark to false code starting here
; :ic

( -- ) ( C: orig -- )
\ Compiler
\ finish if
\ part of: if...[else]...then
: then
    >jmp
; :ic


( -- ) ( C: -- dest )
\ Compiler
\ put the destination address for the backward branch:
\ part of: begin...while...repeat, begin...until, begin...again
: begin
    <mark
; :ic


( -- ) ( C: dest -- )
\ Compiler
\ compile a jump back to dest
\ part of: begin...again

: again
    <jmp
; :ic

( f -- ) ( C: dest -- orig dest )
\ Compiler
\ at runtime skip until repeat if non-true
\ part of: begin...while...repeat
: while
    [compile] if
    swap
; :ic

( f -- f) ( C: dest -- orig dest )
\ Compiler
\ at runtime skip until repeat if non-true, does not consume flag
\ part of: begin...?while...repeat
: ?while
    [compile] ?if
    swap
; :ic

( --  ) ( C: orig dest -- )
\ Compiler
\ continue execution at dest, resolve orig
\ part of: begin...while...repeat
: repeat
  [compile] again
  >jmp
; :ic


( f -- ) ( C: dest -- )
\ Compiler
\ finish begin with conditional branch,
\ leaves the loop if true flag at runtime
\ part of: begin...until
: until
    ?brc
    <jmp
; :ic

( f -- ) ( C: dest -- )
\ Compiler
\ finish begin with conditional branch,
\ leaves the loop if true flag at runtime
\ part of: begin...?until
: ?until
    ??brc
    <jmp
; :ic

( -- )
\ Compiler
\ compile the XT of the word currently
\ being defined into the dictionary
\ : recurse
\    latest  \ ;****FIXME******
\    @ $0400 cxt
\ ; :ic

( n cchar -- )
\ Compiler
\ create a dictionary entry for a user variable at offset n
\ : user
\    rword
\    compile douser
\    ,
\ ;


\ allocate or release n bytes of memory in RAM
: allot ( n -- )
    here + here# !
;

( x -- ) ( C: x "<spaces>name" -- )
\ create a constant in the dictionary
: con
    rword
    lit
    poppc,
    clrcache
;


\ create a dictionary entry for a variable and allocate 1 cell RAM
: var ( cchar -- )
    here
    con
    dcell
    allot
;

( cchar -- )
\ Compiler
\ create a dictionary entry for a character variable
\ and allocate 1 byte RAM
: cvar
    here
    con
    1
    allot
;


\ compiles a string from RAM to program RAM
: s, ( addr len -- )
    dup
    (s,)
;

( C: addr len -- )
\ String
\ compiles a string to program RAM
: slit
    compile (slit)     ( -- addr n)
    s,
; immediate


( -- addr len) ( C: <cchar> -- )
\ Compiler
\ compiles a string to ram,
\ at runtime leaves ( -- ram-addr count) on stack
: s"
    $22
    parse        ( -- addr n)
    state@
    if  \ skip if not in compile mode
      [compile] slit
    then
; immediate

( -- ) ( C: "ccc<quote>" -- )
\ Compiler
\ compiles string into dictionary to be printed at runtime
: ."
     [compile] s"             \ "
     state@
     if
       compile type
     else
       type
     then
; immediate
