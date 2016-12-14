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

\ address to head of linked list of wordlists
var vocabList vocabList 0!

\ make a wordlist record in data ram
\ wordlist record fields:
\ [0] word:dcell: address to nfa of most recent word added to this wordlist
\ [1] Name:dcell: address to nfa of vocabulary name 
\ [2] link:dcell: address to previous wordlist to form vocabulary linked list
: wordlist ( -- wid )
  \ get next available ram from here and use as wid
  here ( wid )
  \ get word field address in ram and set to zero
  dup 0! ( wid )
  \ allocate  3 data cells in ram for the 3 fields
  3 dcell* allot  ( wid )
  \ update link field with contents of vocabList
  vocabList @     ( wid oldwid )
  over dcell+ dcell+ ( wid oldwid wid+2*dcell )
  ! ( wid )
  \ update vocabList with new wid
  dup vocabList !
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
    2drop
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
  wordlist dup d,
  \ get nfa and store in second field of wordlist record 
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
cur@ @
\ get the forth wid and adjust to name field 
context @ dcell+
\ write forth nfa to name field
! 

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
    context@
    ?if else drop context @ then
    @                       ( 0 addr )
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

\ print out all existing vocabularies
\ order is newest to oldest
: vocs ( -- )
  \ most recent vocabulary address is in vocabList
  \ it is the head of the vocabulary linked list
  \ get head link of linked list
  vocabList @  ( link )
  begin
  \ while link is not zero
  ?while  ( link )
    \ get name from name field
    dcell+ dup @ ( link+dcell name )
    \ print name
    .nf ( link+dcell )
    \ get next link from link field
    dcell+ @ ( link )
  repeat
  drop
  ." Forth Root" cr
;
