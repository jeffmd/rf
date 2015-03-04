@ gpio.S

@ ( pin --  )
@ export a GPIO pin n to make it available for use by user
Forthword_ GPIOX, 0, "gpio.x"
  push {lr}
  mov r0, tos
  poptos_
  bl GPIOExport
  pop {pc}

