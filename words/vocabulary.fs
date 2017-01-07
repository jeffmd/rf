\ vocabulary.fs - words for managing the words

\ get context index address
: contidx ( -- addr )
  context 2-
;

\ get context array address using context index
: context# ( -- addr )
  context contidx h@ dcell* +
;

\ get a wordlist id from context array
: context@ ( -- wid )
  context# @
;

\ save wordlist id in context array at context index
: context! ( wid -- )
  context# !
;

\ get a valid wid from the context
\ tries to get the top vocabulary
\ if no valid entries then defaults to Forth wid
: wid@ ( -- wid )
  context@
  ?if else drop context @ then
;

\ wordlist record fields:
\ [0] word:dcell: address to nfa of most recent word added to this wordlist
\ [1] Name:dcell: address to nfa of vocabulary name 
\ [2] link:dcell: address to previous sibling wordlist to form vocabulary linked list
\ [3] child:dcell: address to head of child wordlist

\ add link field offset
: wid:link ( wid -- wid:link) dcell+ dcell+ ;
\ add child field offset
: wid:child ( wid -- wid:child ) 3 dcell* + ;

\ initialize wid fields of definitions vocabulary
: widinit ( wid -- wid )
  \ wid.word = 0
  dup 0! ( wid )

  \ parent wid child field is in cur@->child
  dup cur@ wid:child  ( wid wid parentwid.child )
  2over ( wid wid parentwid.child wid parentwid.child )
  @   ( wid wid parentwid.child wid childLink )
  swap wid:link ( wid wid parentwid.child childLink wid.link )

  \ wid.child = 0
  dup dcell+ 0! ( wid wid parentwid.child childLink wid.link )
  \ wid.link = childLink
  ! ( wid wid parentwid.child )
  \ parentwid.child = wid
  ! ( wid )
;

\ make a wordlist record in data ram
\ and initialize the fields
: wordlist ( -- wid )
  \ get next available ram from here and use as wid
  here ( wid )   
  \ allocate  4 data cells in ram for the 4 fields
  4 dcell* allot  ( wid )

  widinit ( wid )
;

\ similar to dup : duplicate current wordlist in vocabulary search list
\ normally used to add another vocabulary to search list
\ ie: also MyWords
: also ( -- )
  context@
  \ increment index
  contidx 1+h!
  context!
  
; immediate


\ similar to drop but for vocabulary search list
\ removes most recently added wordlist from vocabulary search list
: previous ( -- )
  \ get current index and decrement by 1
  contidx dup h@ 1- dup
  \ index must be >= 1
  0>
  if
    0 context! swap h!
  else
    2drop [compile] only
  then
; immediate

\ Used in the form:
\ cccc DEFINITIONS
\ Set the CURRENT vocabulary to the CONTEXT vocabulary - where new
\ definitions are put in the CURRENT word list. In the
\ example, executing vocabulary name cccc made it the CONTEXT
\ vocabulary (for word searches) and executing DEFINITIONS made both specify vocabulary
\ cccc.

: definitions
    context@
    ?if current ! then
; immediate

\ A defining word used in the form:
\     vocabulary cccc  
\ to create a vocabulary definition cccc. Subsequent use of cccc will
\ make it the CONTEXT vocabulary which is searched first by INTERPRET.
\ The sequence "cccc DEFINITIONS" will also make cccc the CURRENT
\ vocabulary into which new definitions are placed.

\ By convention, vocabulary names are automaticaly declared IMMEDIATE.

: vocabulary ( -- ) ( C:cccc )
  create
  [compile] immediate
  \ allocate space in ram for head and tail of vocab word list
  wordlist dup d, ( wid )
  \ wid.name = vocabulary.nfa  
  cur@ @ swap dcell+ !
  does>
   @ \ get header address
   context!
;

\ Set context to Forth vocabulary
: Forth ( -- )
  context @ context!
; immediate

\ setup forth name pointer in forth wid name field
\ get forth nfa - its the most recent word created
cur@ @ ( nfa )
\ get the forth wid, initialize it and set name field
\ forthwid.word is already initialized
context @ dcell+ ( nfa forthwid.name )
\ forthwid.name = nfa
tuck ! ( forthwid.name )
\ forthwid.link = 0
dcell+ dup 0! ( forthwid.link )
\ forthwid.child = 0
dcell+ 0! ( )

\ print name field
: .nf ( nfa -- )
      $l $FF and             ( cnt addr addr n ) \ mask immediate bit
      type space             ( cnt addr )
;
 
\ list words starting at a name field address
: lwords ( nfa -- )
    0 swap
    begin
      ?dup                   ( cnt addr addr )
    while                    ( cnt addr ) \ is nfa = counted string
      dup                    ( cnt addr addr )
      .nf                    ( cnt addr )
      nfa>lfa                ( cnt lfa )
      @                      ( cnt addr )
      swap                   ( addr cnt )
      1+                     ( addr cnt+1 )
      swap                   ( cnt+1 addr )
    repeat 

    cr ." count: " .
;

\ List the names of the definitions in the context vocabulary.
\ Does not list other linked vocabularies.
\ Use words to see all words in the top context search.
: words ( -- )
    wid@ ( wid )
    @    ( nfa )
    lwords
;

\ list the root words
: rwords ( -- )
  [ find WIPE lit ]
  lwords
;

\ print out search list of active vocabularies
: order ( -- )
  ." Search: "
  \ get context index and use as counter
  contidx h@
  begin
  \ iterate through vocab array and print out vocab names
  ?while
    dup dcell* context +
    \ get context wid
    @
    \ if not zero then print vocab name 
    ?dup if
      \ next cell has name field address 
      dcell+ @
      .nf
    then
    \ decrement index
    1-
  repeat
  drop
  ." Forth Root" cr
  ." definitions: "
  cur@ dcell+ @ .nf cr
;

\ print child vocabularies
: .childvocs ( spaces wid -- )
  begin
  \ while link is not zero
  ?while  ( spaces linkwid )
    \ print indent
    over spaces
    \ get name from name field
    dcell+ dup @ ( spaces linkwid.name name )
    \ print name and line feed
    .nf cr ( spaces link.name )
    \ get link field
    dcell+ ( spaces linkwid.link )
    \ increase spaces for indenting child vocabularies
    over 2+ over ( spaces linkwid.link spaces+2 linkwid.link )
    \ get child link and recurse: print child vocabularies
    dcell+ @ recurse ( spaces linkwid.link )
    \ get link for next sibling
    @
  repeat
  2drop
;

\ list all child vocabularies in the context vocabulary
\ order is newest to oldest
: vocs ( -- )
  \ start spaces at 2
  2
  \ get top search vocabulary address
  \ it is the head of the vocabulary linked list
  wid@  ( wid )
  \ get child link of linked list
  wid:child @ ( linkwid )
  .childvocs cr
;
