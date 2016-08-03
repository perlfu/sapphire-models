SPIN=spin
CFLAGS=-O2
SPIN_GEN_FLAGS=-a
SPIN_CHECK_FLAGS=-m1000000 -a -f -i
PML=hashcode.pml
BIN=hashcode.bin
GSTR='warning\|error\|states'

.SUFFIXES: .pml .bin

check: check

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

check: $(BIN)
	./$< $(SPIN_CHECK_FLAGS) | tee $@.0 | grep $(GSTR)
	rm -f _spin_nvr.tmp $(PML).trail

