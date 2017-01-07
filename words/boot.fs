dp
pname header dup $FF00 or (s,)
  current @ @ d, 
  smudge !
    pushlr, 
    1 state h!
      dp >r >r dup $FF00 or (s,) r> @ d, r>
    [
    poppc,
  uwid

pname (create) current @ header
  smudge !
    pushlr, 
    1 state h!
      pname current @ header
    [
    poppc,
  uwid

(create) ] 
  smudge !
    pushlr, 
    1 state h!
      1 state h!
    [
    poppc,
  uwid

(create) :
  smudge !
    pushlr,
    ]
      (create) smudge ! pushlr, ]
    [
    poppc,
  uwid

: cur@
    current @
  [
  ;opt uwid

: widf
    cur@
    @
    dup
    h@
    rot and
    swap
    h!
  [
  ;opt uwid

: immediate
    $7FFF widf
  [
  ;opt uwid immediate

: \
    stib
    nip
    >in
    h!
  [
  ;opt uwid immediate

\ boot.fs - bootstrap the forth compiler
\ header, (create), ] are created manually
\ use (create) to make : then define the rest manually
\ : can now be used to define a new word but must manually
\ terminate the definition of a new word

\ define ; which is used when finishing the compiling of a word
: ;
  \ change to interpret mode and override to compile [
  [ pname [ findw nfa>xtf cxt ]
  \ back in compile mode
    ;opt uwid
[ ;opt uwid immediate

