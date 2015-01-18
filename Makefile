# Makefile
INCS = *.S

all: rf

rf : rf.o input.o
	gcc -Os -o $@ $+

rf.o : main.S $(INCS)
	as -o $@ $<

lst:
	objdump -h -x -D -S rf > test.s

clean:
	rm -vf rf *.o
