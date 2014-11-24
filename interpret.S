@ interpret.S

@ ( c -- )
@ fetch the emit vector and EXEC it. Will emit a character from TOS
Forthword_ EMIT, 0, "emit"
  push {lr}
  mov r0, tos
  poptos_
  bl putchar
  pop {pc}

@ ( -- )
@ cause subsequent output appear at the beginning of the next line
Forthword_ CR, 0, "cr"
  push {lr}
  doliteral_ 13
  bl EMIT
  bl TEN
  bl EMIT
  pop {pc}

@ ( -- 32 )
@ put ascii code of the blank/space character to the stack
Forthword_ BL, 0, "bl"
    doliteral_ 32
    bx lr

@ ( -- key )
@ fetch key vector and EXEC it, should leave a single character on TOS
Forthword_ KEY, 0, "key"
  push {lr}
  bl getchar
  pushtos_
  mov tos, r0
  pop {pc}
