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

\ start null terminated buffer
: <#_ ( -- )
    <# 0 hold
;

\ file open using null terminated buffer
: #>Open ( mode -- fs flag)
    #$ root$ #$ #> drop open ( fs )
    dup 0> ( fs flag )
;

\ unexport a GPIO pin when no longer needed by user
: unexp ( pin --  )
    \ open unexport file for writing
    1 dup  ( pin 1 1 )
    <#_ unexp$ #>Open ( pin fs flag)
    if
      dup ( pin fs fs )
      rot ( fs fs pin )
      <# #s #> write ( fs flag )
      swap
    else
      .fail unexp$ type .wrting
    then
    nip
    close
;

: dirOpen ( pin -- fs flag )
    1    ( pin 1 )
    swap  ( 1 pin )
    <#_ dir$ #$ #s gpio$ #>Open ( fs flag)
;

: exp ( pin -- )
    1 dup            ( pin 1 1 )
    <#_ exp$ #>Open  ( pin fs flag )
    if
      swap           ( fs pin )
      over           ( fs pin fs )
      over           ( fs pin fs pin )
      <# #s #> write ( fs pin 1 )
      rot close      ( pin 1 )
      \ wait for direction file to become available
      begin
        drop         ( pin )
        dup          ( pin pin ) 
        dirOpen      ( pin fs flag )
      until
    else
      .fail exp$ type .wrting
    then
    nip
    close
    
;

\ set direction of a GPIO pin that has been exported
\ if direction is 0 then pin will be input
\ if direction is 1 then pin will be output
: dir ( pin direction --  )
    \ open direction file for writing
    swap ( direction pin )
    dirOpen    ( direction fs flag )
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

\ Open gpio value file
\ mode: 0 file opened for reading
\ mode: 1 file opened for writing
: valOpen ( pin mode -- fs flag )
    \ open value file for writing
    swap ( mode pin )
    <#_ value$ #$ #s gpio$ #>Open ( fs flag)
;

\ write to gpio pin
: pinW ( pin val --  )
    swap 1 valOpen ( val fs flag )
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

\ read from gpio pin
: pinR ( pin -- val )
    0 valOpen ( fs flag )
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
  over exp dir
;

\ set pin as output
: output ( pin -- )
  1 pin
;

\ set pin as input
: input ( pin -- )
  0 pin
;

\ turn gpio pin to high state
: high ( pin -- )
  1 pinW
;

\ turn gpio pin to low state
: low ( pin -- )
  0 pinW
;

