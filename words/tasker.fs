\ tasker.fs : words for managing tasks

only 
vocabulary Tasker
also Tasker definitions

\ maximum number of tasks
62 con maxtask
\ the active index into the task list
cvar tidx

\ count register for each task
\ is an array 
var tcnt
maxtask 4* allot

( -- n )
\ fetch task index: verifies index is valid
\ adjusts index if count is odd ?
: tidx@
  tidx c@ 
  \ verify index is below 63
  dup maxtask >
  if
    \ greater than 62 so 0
    0:
    tidx 0c!
  then
;

( idx -- cnt )
\ get count for a slot
\ idx: index of slot
: cnt@
  4* tcnt + @
;

\ get the count for current task executing
( -- n )
: count
 tidx@ cnt@
;

\ increment tcnt array element using idx as index
( idx -- )
: cnt+
  4* tcnt + 1+!
;

( n idx -- )
\ set tcnt array element using idx as index
: cnt!
  4* tcnt + !
;

\ array of task slots in ram : max 31 tasks 62 bytes
\ array is a binary process tree
\                        0                          62.5 ms
\             1                      2              125 ms
\      3           4           5           6        250 ms
\   7     8     9    10     11   12     13   14     500 ms
\ 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30   1 s
\ 31 -                                          62  2 s
var tasks
maxtask 4* allot

( -- )
\ increment task index to next task idx
\ assume array flat layout and next idx = idx*2 + 1
: tidx+
  tidx@ 2* 1+ 
  \ if slot count is odd then 1+
  tidx@ cnt@
  1 and +
  tidx c!
;

( idx -- task )
\ get a task at idx slot
: task@
  4* tasks + @ 
;

( addr idx -- ) 
\ store a task in a slot
\ idx is the slot index range: 0 to 62
: task!
  4* tasks + !
;

\ store a task in a slot
: task ( idx C: name -- )
  ' swap task!
;

( idx -- )
\ clear task at idx slot
\ replaces task with noop
: taskclr 
  ['] noop swap task!
;


( -- )
\ execute active task and step to next task
: taskex
  \ increment count for task slot
  tidx@ cnt+
  tidx@ task@ exec
  tidx+
;

\ time in ms since last tasks.ex
var ms
var lastms
\ how often in milliseconds to execute a task
\ default to 12.5 ms 
cvar exms


( -- )
\ execute tasks.ex if tick time expired
: tick
  1ms ms dup 1+! @ lastms @ - exms c@ 
  u> if ms @ lastms ! taskex then
;

( -- )
\ clear all tasks
: allclr
  \ iterate 0 to 30 and clear tcnt[] and set tasks[] to noop
  0
  tidx 0c!
  begin
    0 over cnt!
    dup taskclr 
    1+ 
    dup maxtask >  
  until
  drop
;

( -- )
\ start tasking
: run
  8 exms c!
  ms 0! lastms 0!
  ['] tick pause# !
;

( -- )
\ reset tasker
\ all tasks are reset to noop
: reset
  allclr
  run
;

( -- )
\ stop tasks from running
: stop
  ['] noop pause# !
;
