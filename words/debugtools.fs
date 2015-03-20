only

( -- n )
\ Tools
\ Amount of available RAM (incl. PAD)
: unused
    sp0 here -
;
    



( addr1 cnt -- addr2)
: dmp
 over .$ [char] : emit space
 begin
   ?while icell- swap dup h@ .$ icell+ swap
 repeat
 drop
;


( addr -- )
\ Tools
\ print the contents at ram word addr
: ? @ . ;

\ print the contents at ram char addr
: c? c@ . ;

( bbb reg -- )
\ tools
\ set the bits of reg defined by bit pattern in bbb
: rbs :a c@ or ac! ;

( bbb reg -- )
\ tools
\ clear the bits of reg defined by bit pattern in bbb
: rbc >a not ac@ and ac! ;

\ modify bits of reg defined by mask
: rbm ( val mask reg -- )
    >a ac@ and or
    ac!
;


( reg -- )
\ tools
\ read register/ram byte contents and print in binary form
: rb? c@ bin <# # # # # # # # # #> type space decimal ;

( reg -- )
\ tools
\ read register/ram byte contents and print in hex form
: r? c@ .$ ;

\ setup fence which is the lowest address that we can forget words
find r? var fence fence !

( c: name -- )
: forget
  pname
  cur@
  findnfa            ( nfa )
  ?dup
  if
    \ nfa must be greater than fence
    dup           ( nfa nfa)
    fence @       ( nfa nfa fence )
    >             ( nfa nfa>fence )
    if
      \ nfa is valid
      \ set dp to nfa
      dup           ( nfa nfa )
      dp!           ( nfa )
      \ set context wid to lfa
      nfa>lfa       ( lfa )
      @             ( nfa )
      cur@          ( nfa wid )
      !             (  )
    else
      drop  
    then
  then
;

find forget fence !

\ create a marker word
\ when executed it will restore dp, here and current
\ back to when marker was created
: marker  ( c: name -- )
  \ copy current word list, current wid, dp, here
  cur@ dup @ dp here
  create
  \ save here, dp, current wid, current word list
  ,, ,, ,, ,,
  does> ( addr )
    \ restore here
    dup @ here# !
    \ restore dp
    dcell+ dup @ dp!
    \ restore current wid
    dcell+ dup @ 
    swap dcell+ @ !
    \ only Forth and Root are safe vocabs
    only
;
