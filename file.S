@ file.S

@ ( flags path -- filedes )
@ open a file
@ path - address of path string null terminated
@ option flags 
Forthword_ OPENF, 0, "open"
  push {lr}
  mov r0, tos @ path
  poptos_
  mov r1, tos @ flags
  bl open
  mov tos, r0
  pop {pc}

@ ( filedes -- )
@ open a file
@ filedes - file descriptor
Forthword_ CLOSEF, 0, "close"
  push {lr}
  mov r0, tos @ filedes
  poptos_
  bl close
  pop {pc}

@ (  filedes buffer length -- bytesread )
@ fetch bytes from an open file using filedes
@ number of bytes read left on TOS
Forthword_ READF, 0, "read"
  push {lr}
  movs r2, tos @ length
  poptos_
  mov r1, tos @ buffer
  poptos_
  movs r0, tos @ filedes
  bl read 
  mov tos, r0
  pop {pc}

@ (  filedes buffer length -- bytesread )
@ write bytes to an open file using filedes
@ number of bytes written left on TOS
Forthword_ WRITEF, 0, "write"
  push {lr}
  movs r2, tos @ length
  poptos_
  mov r1, tos @ buffer
  poptos_
  movs r0, tos @ filedes
  bl write 
  mov tos, r0
  pop {pc}

