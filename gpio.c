/* gpio.c */
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define BUFFER_MAX 3
static char pin_buffer[BUFFER_MAX];

static int int_to_string(const int val)
{
  return snprintf( pin_buffer, BUFFER_MAX, "%d", val );
}

int GPIOExport(const int pin)
{
    int fd;
#define VALUE_MAX 35
    char path[VALUE_MAX];

    fd = open("/sys/class/gpio/export", O_WRONLY);
    if (-1 == fd) {
      fprintf(stderr, "Failed to open export for writing!\n");
      return(-1);
    }

    write(fd, pin_buffer, int_to_string(pin));
    close(fd);
    
    snprintf(path, VALUE_MAX, "/sys/class/gpio/gpio%d/direction", pin);
    // wait until direction file is available
    do {
      fd = open(path, O_WRONLY);
    } while ( fd == -1 );
    
    close(fd);
     
    return(0);
}





