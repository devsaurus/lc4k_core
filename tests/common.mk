
SRC_GEN := ../../src/gen

ARCHS := $(shell ls -d LC*)

.PHONY: all
all: $(addsuffix .do,$(ARCHS))

.PHONY: clean
clean: $(addsuffix .clean,$(ARCHS))
	cd $(SRC_GEN) && make clean
	rm -f *~

%.do:
	cd $(SRC_GEN) && make $(@:.do=)
	@mkdir -p $(@:.do=)/yosys
	cd $(@:.do=)/yosys && yosys -m ghdl -s ../../equiv.ys | tee log

%.clean:
	rm -rf $(@:.clean=)/yosys
