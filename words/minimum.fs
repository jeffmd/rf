\ minimum.fs Forth words that make up minimum forth vocabulary


( n min max -- f)
\ check if n is within min..max
: within
    over - >a - a u<
;

\ increment a cvar by one.  If val > max then set flag to true.
: 1+c!mx ( maxval cvar -- flag )
  nip>b >a ac@ 1+ dup b > if 0: then dup ac! 0=
;

( c<name> -- )
\ Compiler
\ creates a RAM based defer vector
: rdefer
    (create)
    cur@ !

    compile (def)

   \ here ,
   \ 2 allot

   \ ['] @ ,
   \ ['] ! ,
;


\ signed multiply n1 * n2 and division  with n3 with double
\ precision intermediate and remainder
: */mod  ( n1 n2 n3 -- rem quot )
    >r
    m*
    r>
    m/mod
;


\ signed multiply and division with double precision intermediate
: */ ( n1 n2 n3 -- n4 )
    */mod
    nip
;


\ divide n1 by n2 giving the remainder n3
: mod ( n1 n2 -- n3 )
    /mod
    drop
;


\ fill u bytes memory beginning at a-addr with character c
\ : fill  ( a-addr u c -- )
\    -rot           ( c a-addr u )
\    nip>a          ( c u ) ( A: a-addr )
\    begin
\    ?while
\      over         ( c u c )
\      ac!          ( c u )
\      a+
\      1-           ( c u-1 )
\    repeat
\    2drop
\ ;


\ emits a space (bl)
: space ( -- )
    bl emit
;

\ emits n space(s) (bl)
\ only accepts positive values
: spaces ( n -- )
    \ make sure a positive number
    dup 0> and
    begin
    ?while
      space
      1-
    repeat
    drop
;

\ pointer to current write position
\ in the Pictured Numeric Output buffer
var hld


\ prepend character to pictured numeric output buffer
: hold ( c -- )
    -1 hld +!
    hld @ c!
;

\ Address of the temporary scratch buffer.
: pad ( -- a-addr )
    here 100 +
;

\ initialize the pictured numeric output conversion process
: <# ( -- )
    pad hld !
;

\ pictured numeric output: convert one digit
: # ( u1 -- u2 )
    base@      ( u1 base )
    u/mod      ( rem u2 )
    swap       ( u2 rem )
    #h hold    ( u2 )
;

\ pictured numeric output: convert all digits until 0 (zero) is reached
: #s ( u -- 0 )
    #
    begin
    ?while
      #
    repeat
;

\ copy string to numeric output buffer
: #$ ( addr len -- )
\ start at end of string
    begin
    ?while
      1- over over + c@ hold
    repeat
    2drop    
;

\ Pictured Numeric Output: convert PNO buffer into an string
: #> ( u1 -- addr count )
    drop hld @ pad over -
;

\ place a - in HLD if n is negative
: sign ( n -- )
    0< if [char] - hold then
;


\ singed PNO with cell numbers, right aligned in width w
: .r ( wantsign n w -- )
    >r   ( wantsign n ) ( R: w )
    <#
    #s   ( wantsign 0 )
    swap ( 0 wantsign )
    sign ( 0 )
    #>   ( addr len )
    r>   ( addr len w )  ( R: )
    over ( addr len w len )
    -    ( addr len spaces )
    spaces ( addr len )
    type  ( )
    space
;

\ unsigned PNO with single cell numbers
: u. ( u -- )
    0      ( n 0 ) \ want unsigned
    tuck   ( 0 n 0 )
    .r
;


\ singed PNO with single cell numbers
: .  ( n -- )
    dup      ( n n )
    abs      ( n n' )
    0        ( n n' 0 ) \ not right aligned
    .r
;

\ stack dump
: .s  ( -- )
    sp@     ( limit ) \ setup limit
    4-
    sp0     ( limit counter )
    begin
    4-      ( limit counter-4 )
    2over   ( limit counter-4 limit counter-4 )
    <>      ( limit counter-4 flag )
    while
      dup     ( limit counter-4 counter-4 )
      @       ( limit counter-4 val )
      u.      ( limit counter-4 )
    repeat
    2drop
;

\ numbers that get used a lot

: 3 3 ;
: 4 4 ;
: 5 5 ;
: 6 6 ;
: 7 7 ;
: 8 8 ;
: 9 9 ;
: $FF $FF ;
: $F0 $F0 ;
: $0F $0F ;
: $FF00 $FF00 ;


( xt1 c<char> -- )
\ stores xt into defer or compiles code to do so at runtime
\ : is
\    [compile] to
\ ; immediate

\ 1 millisecond delay
( -- )
: 1ms 1000 usleep ;

\ set name as the background task that
\ executes each time pause executes
( char:name -- )
: dopause ' pause# ! ;

\ put a null at end of string
: $_ ( addr len -- )

 \ addr + len = 0
 1- + 0c!
;

