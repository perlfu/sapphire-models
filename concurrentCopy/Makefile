SPIN=spin
CFLAGS=-O2 -DSAFETY
SPIN_GEN_FLAGS=-a
SPIN_CHECK_FLAGS=-m1000000 -a -f -i
PML=stmCopy.pml
BIN=stmCopy.bin
GSTR='warning\|error\|states'

.SUFFIXES: .pml .bin

check: check-assert

clean:
	rm -f $(BIN)
	rm -f pan.*
	rm -f *.trail
	rm -f *.[012]
	rm -f _spin_nvr.tmp

.pml.bin:
	$(SPIN) $(SPIN_GEN_FLAGS) $<
	$(CC) $(CFLAGS) -o $@ pan.c
	rm -f pan.*

check-assert: $(BIN)
	./$< -m1000000000 | tee $@.0 | grep $(GSTR)
	rm -f _spin_nvr.tmp $(PML).trail
