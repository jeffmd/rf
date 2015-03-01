\ gpio.fs - words to manipulate gpio pins on Raspberry Pi
only
vocabulary GPIO
GPIO definitions

\ setup a GPIO pin for input or output
\ automatically exports the pin 
\ if direction is 0 then pin will be input
\ if direction is 1 then pin will be output
: pin ( pin direction -- )
  over gpio.x gpio.dir
;

\ set pin as output
: out ( pin -- )
  1 pin
;

\ set pin as input
: in ( pin -- )
  0 pin
;

\ turn gpio pin to on state
: on ( pin -- )
  1 gpio.write
;

\ turn gpio pin to off state
: off ( pin -- )
  0 gpio.write
;

