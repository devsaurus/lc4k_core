
PYTHON_DIR := ../../python

SX_FILES := $(shell find ../../re4k -name LC*.sx)

LC = $(shell echo '$1' | tr '[:upper:]' '[:lower:]')
UC = $(shell echo '$1' | tr '[:lower:]' '[:upper:]')


.PHONY: help
help:
	@echo
	@echo "Generate core design files from CPLD fuse map documentation."
	@echo
	@echo "Make targets:"
	@$(foreach sx,$(SX_FILES),echo "  $(basename $(notdir $(sx)))";)
	@echo
	@echo "  all   : Generate all above"
	@echo "  clean : Remove generated files"
	@echo


.PHONY: clean
clean:
	rm -f *.vhd


define RULE_TEMPLATE
file$(basename $(notdir $(1))) := $(1)
vhd$(basename $(notdir $(1))) := $(addsuffix _core.vhd,$(call LC, $(basename $(notdir $(1)))))
all : $(basename $(notdir $(1)))
$(basename $(notdir $(1))) : $$(vhd$(basename $(notdir $(1))))
$$(vhd$(basename $(notdir $(1)))) : $$(file$(basename $(notdir $(1))))
endef

$(foreach sx,$(SX_FILES),$(eval $(call RULE_TEMPLATE,$(sx))))


%.vhd :
	python3 $(PYTHON_DIR)/gen_lc4k_core.py $< > $@
