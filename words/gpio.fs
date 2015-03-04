\ gpio.fs - words to manipulate gpio pins on Raspberry Pi
only
vocabulary GPIO
GPIO definitions

: root$ s" /sys/class/gpio/" ;
: exp$ s" export" ;
: unexp$ s" unexport" ;
: dir$ s" /direction" ;
: value$ s" /value" ;
: gpio$ s" gpio" ;
: inout$ s" inout" ;
: inbuf$ s"    " ;

: .fail ." Failed to open GPIO: " ;
: .wrting ."  for writing!" ;

: #>Open ( -- flag)
    #$ root$ #$ #> drop open ( pin fs )
    dup 0> ( pin fs flag)
;

\ unexport a GPIO pin when no longer needed by user
: unexp ( pin --  )
    \ open unexport file for writing
    1    ( pin 1 )
    dup  ( pin 1 1 )
    <# 0 hold unexp$ #>Open ( pin fs flag)
    if
      dup ( pin fs fs )
      rot ( fs fs pin )
      <# #s #> write ( fs flag )
      swap
    else
      .fail ." unexport" .wrting
    then
    nip
    close
;


\ set direction of a GPIO pin that has been exported
\ if direction is 0 then pin will be input
\ if direction is 1 then pin will be output
: dir ( pin direction --  )
    \ open direction file for writing
    1    ( pin direction 1 )
    rot  ( direction 1 pin )
    <# 0 hold dir$ #$ #s gpio$ #>Open ( direction fs flag)
    if
      dup ( direction fs fs )
      rot ( fs fs direction )
      <# dup 2* inout$ drop + over 2+ #$ #> write ( fs flag )
      swap
    else
      .fail ." direction" .wrting
    then
    nip
    close
;

\ write to gpio port
: gpiow ( pin val --  )
    \ open value file for writing
    1    ( pin val 1 )
    rot  ( val 1 pin )
    <# 0 hold value$ #$ #s gpio$ #>Open ( val fs flag)
    if
      dup ( val fs fs )
      rot ( fs fs val )
      <# #s #> write ( fs 1 )
      swap
    else
      .fail ." value" .wrting
    then
    nip
    close
;

\ read from gpio port
: gpior ( pin -- val )
    \ open value file for reading
    0    ( pin 0 )
    swap ( 0 pin )
    <# 0 hold value$ #$ #s gpio$ #>Open ( fs flag)
    if
      dup ( fs fs )
      inbuf$ read ( fs flag )
      \ convert string val to integer
      inbuf$ drop 1 num drop ( fs flag val )
      -rot ( val fs flag )
      swap
    else
      .fail ." value for reading!"
      tuck ( flag fs flag )
    then
    nip
    close
;

\ setup a GPIO pin for input or output
\ automatically exports the pin 
\ if direction is 0 then pin will be input
\ if direction is 1 then pin will be output
: pin ( pin direction -- )
  over gpio.x dir
;

\ set pin as output
: out ( pin -- )
  1 pin
;

\ set pin as input
: in ( pin -- )
  0 pin
;

\ turn gpio pin to high state
: high ( pin -- )
  1 gpiow
;

\ turn gpio pin to low state
: low ( pin -- )
  0 gpiow
;

