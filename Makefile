# Makefile
INCS = *.S

all: rf

rf : rf.o input.o gpio.o
	gcc -Os -o $@ $+

rf.o : main.S $(INCS)
	as -o $@ $<

lst:
	objdump -h -x -D -S rf > lst.txt

clean:
	rm -vf rf *.o
