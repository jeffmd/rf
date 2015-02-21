@ gpio.S

@ ( pin --  )
@ export a GPIO pin n to make it available for use by user
Forthword_ GPIOX, 0, "gpio.x"
  push {lr}
  mov r0, tos
  poptos_
  bl GPIOExport
  pop {pc}

@ ( pin --  )
@ unexport a GPIO pin when no longer needed by user
Forthword_ GPIOUX, 0, "gpio.ux"
  push {lr}
  mov r0, tos
  poptos_
  bl GPIOUnexport
  pop {pc}

@ ( direction pin --  )
@ set direction of a GPIO pin that has been exported
@ if direction is 0 then pin will be input
@ if direction is 1 then pin will be output
Forthword_ GPIODIR, 0, "gpio.dir"
  push {lr}
  mov r0, tos @ pin
  poptos_
  mov r1, tos @ direction 
  poptos_
  bl GPIODirection
  pop {pc}


@ ( val pin --  )
@ set GPIO pin output either 0 or 1
Forthword_ GPIOW, 0, "gpio.write"
  push {lr}
  mov r0, tos @ pin
  poptos_
  mov r1, tos @ val
  poptos_
  bl GPIOWrite
  pop {pc}

@ ( pin -- val )
@ set direction of a GPIO pin that has been exported
Forthword_ GPIOR, 0, "gpio.read"
  push {lr}
  mov r0, tos @ pin
  poptos_
  bl GPIORead
  pushtos_
  mov tos, r0 @ val
  pop {pc}

