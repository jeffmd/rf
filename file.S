@ file.S - words used to work with files and shared libraries

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

@ ( mode path -- handle )
@ open a dynamic linked library (*.so)
@ path - address of path string null terminated
@ mode -  
Forthword_ DLOPEN, 0, "dlopen"
  push {lr}
  mov r0, tos @ path
  poptos_
  mov r1, tos @ mode
  bl dlopen
  mov tos, r0
  pop {pc}

@ ( symname handle -- funcptr )
@ get the address of a symbol in shared library with handle
@ symname - address of null terminated symbol name
@ funcptr - address of symbol if found 
Forthword_ DLSYM, 0, "dlsym"
  push {lr}
  mov r0, tos @ handle
  poptos_
  mov r1, tos @ symname
  bl dlsym
  mov tos, r0
  pop {pc}
  
@ ( handle -- flag )
@ close a shared library
@ flag - 0 if success  
Forthword_ DLCLOSE, 0, "dlclose"
  push {lr}
  mov r0, tos @ handle
  bl dlclose
  mov tos, r0
  pop {pc}

@ ( -- stringptr )
@ gets a human readable string describing the
@ most recent error that occurred from  dlopen,
@ dlsym, or dlclose since the last call to dlerror
Forthword_ DLERROR, 0, "dlerror"
  push {lr}
  bl dlerror
  pushtos_
  mov tos, r0
  pop {pc}



