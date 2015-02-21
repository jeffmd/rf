#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>

/* Use this variable to remember original terminal attributes. */

struct termios saved_attributes;
int fdm, fds, rc;

void reset_input_mode (void)
{
  tcsetattr (STDIN_FILENO, TCSANOW, &saved_attributes);
  fprintf (stdout, "\nstdin terminal attributes restored\n");
}

void set_input_mode (void)
{
  struct termios tattr;
/*
  fdm = posix_openpt(O_RDWR); 
  if (fdm < 0) 
  { 
    fprintf(stderr, "Error %d on posix_openpt()\n", errno); 
    // return 1; 
  } 

  rc = grantpt(fdm); 
  if (rc != 0) 
  { 
    fprintf(stderr, "Error %d on grantpt()\n", errno); 
    // return 1; 
  } 

  rc = unlockpt(fdm); 
  if (rc != 0) 
  { 
    fprintf(stderr, "Error %d on unlockpt()\n", errno); 
    // return 1; 
  } 

  fprintf(stdout, "remote connect to %s\n", ptsname(fdm));
*/  
  /* Make sure stdin is a terminal. */
  if (!isatty (STDIN_FILENO))
    {
      fprintf (stderr, "Note: input not a terminal.\n");
    }
  // The slave side of the PTY becomes the standard input and outputs of the child process 
//  close(0); // Close standard input (current terminal) 
//  close(1); // Close standard output (current terminal) 
//  dup(fdm); // PTY becomes standard input (0) 
//  dup(fdm); // PTY becomes standard output (1) 

  /* Save the terminal attributes so we can restore them later. */
  tcgetattr (STDIN_FILENO, &saved_attributes);
  atexit (reset_input_mode);

  /* Set the funny terminal modes. */
  tcgetattr (STDIN_FILENO, &tattr);
  tattr.c_lflag &= ~(ICANON|ECHO); /* Clear ICANON and ECHO. */
  tattr.c_cc[VMIN] = 0;
  tattr.c_cc[VTIME] = 0;
  tcsetattr (STDIN_FILENO, TCSAFLUSH, &tattr);
}
