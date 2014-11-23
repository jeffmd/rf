# Makefile
INCS = *.S

all: rf

main : rf.o
	gcc -o $@ $+

rf.o : main.S $(INCS)
	as -o $@ $<

clean:
	rm -vf rf *.o
