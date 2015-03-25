\ core.fs - core words


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

\ store address of the next free dictionary cell
: dp! ( addr -- )
    dp# !
;

( -- ) ( C: x "<spaces>name" -- )
\ create a dictionary entry and register in word list
: rword
    (create)      ( voc-link )
    cur@          ( voc-link wid )
    !             ( )
;

\ inlinned assembly routines


( n1 n2 n3 -- n3)
\ drop NOS twice, two cells before TOS.
rword 2nip inlined
    8 dsp adds#,
    bxlr,

( n1 -- n1*2 )
\ shift left to give * 2
rword 2* inlined
    tos tos 1 lsls#,
    bxlr,

( n1 -- n1/2 )
\ arithmetic shift right to give / 2
rword 2/ inlined
    tos tos 1 asrs#,
    bxlr,

( n1 -- n1*4 )
\ shift left to give * 4
rword 4* inlined
    tos tos 2 lsls#,
    bxlr,

( n1 -- n1/4 )
\ shift right to give / 4
rword 4/ inlined
    tos tos 2 asrs#,
    bxlr,

( n -- n+1 )
\ optimized 1 increment
rword 1+ inlined
    1 tos adds#,
    bxlr,

( n -- n-1 )
\ optimized 1 decrement
rword 1- inlined
    1 tos subs#,
    bxlr,

( n -- n+2 )
\ optimized 2 increment
rword 2+ inlined
    2 tos adds#,
    bxlr,

( n -- n-2 )
\ optimized 2 decrement
rword 2- inlined
    2 tos subs#,
    bxlr,

( n -- n+4 )
\ optimized 4 increment
rword 4+ inlined
    4 tos adds#,
    bxlr,

( n -- n-4 )
\ optimized 4 decrement
rword 4- inlined
    4 tos subs#,
    bxlr,

( -- icell )
\ push instruction cell size 
rword icell inlined
    ] 2 [
    bxlr,

( n -- n+icell )
\ add instruction stack cell size to n
rword icell+ inlined
    ] 2+ [
    bxlr,
  
( n -- n-icell )
\ subtract instruction stack cell size from n
rword icell- inlined
    ] 2- [
    bxlr,

( n -- n*icell )
\ multiply n by instruction stack cell size 
rword icell* inlined
    ] 2* [
    bxlr,

( -- dcell )
\ push data stack cell size 
rword dcell inlined
    ] 4 [
    bxlr,

( n -- n+dcell )
\ add data stack cell size to n
rword dcell+ inlined
    ] 4+ [
    bxlr,

( n -- n-dcell )
\ subtract data stack cell size from n
rword dcell- inlined
    ] 4- [
    bxlr,

( n -- n*dcell )
\ multiply n by data stack cell size 
rword dcell* inlined
    ] 4* [
    bxlr,

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
