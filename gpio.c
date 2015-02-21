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

int GPIOUnexport(const int pin)
{
    int fd;

    fd = open("/sys/class/gpio/unexport", O_WRONLY);
    if (-1 == fd) {
      fprintf(stderr, "Failed to open unexport for writing!\n");
      return(-1);
    }

    write(fd, pin_buffer, int_to_string(pin));
    close(fd);
    return(0);
}

int GPIODirection(const int pin, const int dir)
{
    static const char s_directions_str[]  = "in\0out";

#define DIRECTION_MAX 35
    char path[DIRECTION_MAX];
    int fd;

    snprintf(path, DIRECTION_MAX, "/sys/class/gpio/gpio%d/direction", pin);
    fd = open(path, O_WRONLY);
    if (-1 == fd) {
      fprintf(stderr, "Failed to open gpio direction for writing!\n");
      return(-1);
    }

    if (-1 == write(fd, &s_directions_str[0 == dir ? 0 : 3], 0 == dir ? 2 : 3)) {
      fprintf(stderr, "Failed to set direction!\n");
      return(-1);
    }

    close(fd);
    return(0);
}

int GPIORead(const int pin)
{
    char path[VALUE_MAX];
    char value_str[3];
    int fd;

    snprintf(path, VALUE_MAX, "/sys/class/gpio/gpio%d/value", pin);
    fd = open(path, O_RDONLY);
    if (-1 == fd) {
      fprintf(stderr, "Failed to open gpio value for reading!\n");
      return(-1);
    }

    if (-1 == read(fd, value_str, 3)) {
      fprintf(stderr, "Failed to read value!\n");
      return(-1);
    }

    close(fd);

    return(atoi(value_str));
}

int GPIOWrite(const int pin, const int value)
{
    static const char s_values_str[] = "01";

    char path[VALUE_MAX];
    int fd;

    snprintf(path, VALUE_MAX, "/sys/class/gpio/gpio%d/value", pin);
    fd = open(path, O_WRONLY);
    if (-1 == fd) {
	fprintf(stderr, "Failed to open gpio value for writing!\n");
	return(-1);
    }

    if (1 != write(fd, &s_values_str[0 == value ? 0 : 1], 1)) {
	fprintf(stderr, "Failed to write value!\n");
	return(-1);
    }

    close(fd);
    return(0);
}
