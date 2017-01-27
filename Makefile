#
# Copyright (c) 2017 Guo Yunhe <guoyunhebrave@gmail.com>
# Copyright (c) 2017 Grover Chou
# Copyright (c) 2017 Stefan Knorr <sknorr@suse.de>
#


# Source DocBook XML files
# FIXME: troubleshooting.xml causes xml2pot segmentation fault, skip it for
# the moment
XMLFILES := $(filter-out xml/troubleshooting.xml, $(wildcard xml/*.xml))

# Source DC files for building with DAPS
DCFILES := $(wildcard DC-*)

# GNU Gettext templates (POT files)
POTFILES := $(patsubst xml/%.xml,l10n/templates/%.pot,$(XMLFILES))

# Valid GNU Gettext file name patterns, used to filter out old po files
PONAMES := $(patsubst xml/%.xml, %, $(XMLFILES))

# Language directories
LANGDIRS := $(filter-out l10n/templates, $(wildcard l10n/*))

# Translated GNU Gettext files (PO files)
POFILES := $(foreach DIR, $(LANGDIRS), $(foreach PO, $(PONAMES), $(DIR)/po/$(PO).po))

# Translated DC files for building with DAPS
L10NDCFILES := $(foreach DIR, $(LANGDIRS), $(foreach DC, $(DCFILES), $(DIR)/$(DC)))

# Translated DocBook XML files
L10NXMLFILES := $(foreach DIR, $(LANGDIRS), $(patsubst $(DIR)/po/%.po,$(DIR)/xml/%.xml,$(POFILES)))


.PHONY: pot po l10ndc l10nxml clean clean_pot clean_l10nxml clean_l10ndc
all: pot po l10ndc l10nxml

pot: $(POTFILES)

l10nxml: l10ndc po $(L10NXMLFILES)
%.xml: ../po/%.po
	if [ ! -d "$$(dirname '$@')" ]; then \
   mkdir -p "$$(dirname '$@')"; \
   fi
	po2xml $< | daps-xmlformat > $@ 2>/dev/null

#$(foreach DIR, $(LANGDIRS), $(eval $(DIR)/xml/%.xml : xml/%.xml $(DIR)/po/%.po
#	if [ ! -d $(DIR)/xml ]; then mkdir -p $(DIR)/xml; fi
#	po2xml $$^ | daps-xmlformat > $$@ 2>/dev/null


l10n/templates/%.pot: xml/%.xml
	xml2pot $< > $@

po: pot $(POFILES)
%.po: ../../templates/%.pot
	if [ ! -d "$$(dirname '$@')" ]; then \
   mkdir -p "$$(dirname '$@')"; \
   fi
	if [ -r "$@" ]; then \
       msgmerge --previous --update $@ $<; \
   else \
       msgen -o $@ $<; \
   fi

# FIXME? weird but apparently does the trick...
l10ndc: $(L10NDCFILES)
DC-%: ../../DC-%
	cp $< $@


clean: clean_pot clean_l10nxml clean_l10ndc

# Remove POT files, generated from XML
clean_pot :
	rm -f l10n/templates/*.pot

# Remove translated XML in language folders, generated from PO files
clean_l10nxml :
	rm -f l10n/*/xml/*.xml

# Remove DC files in language folders, copied from original DC files
clean_l10ndc:
	rm -f l10n/*/DC-*
