# Customize LANGUAGE_SUFFIX and ASCIIDOCTOR_LANGUAGE for non-English languages.
# See the "copy-all" below for examples how to use them.
#
# Suffix added to input and output filenames.
LANGUAGE_SUFFIX:=
# Language parameters to AsciiDoctor, see https://asciidoctor.org/docs/user-manual/#language-support
ASCIIDOCTOR_LANGUAGE:=

NAME:=modern_pascal_introduction$(LANGUAGE_SUFFIX)
ALL_OUTPUT:=$(NAME).html $(NAME).pdf $(NAME).xml
#TEST_BROWSER:=firefox
TEST_BROWSER:=x-www-browser

all: $(ALL_OUTPUT)

$(NAME).html: $(NAME).adoc
	asciidoctor $< -o $@
	fpc -gl -gh patreon-link-insert.lpr
	./patreon-link-insert $@
	$(TEST_BROWSER) $@ &

$(NAME).xml: $(NAME).adoc
	asciidoctor $(ASCIIDOCTOR_LANGUAGE) -b docbook5 $< -o $@
#	yelp $@

$(NAME).pdf: $(NAME).xml
	fopub $(NAME).xml

# $(NAME).pdf: $(NAME).adoc
# 	asciidoctor-pdf $(NAME).adoc

.PHONY: clean
clean:
	rm -f $(ALL_OUTPUT)

.PHONY: test
test:
	$(MAKE) -C code-samples$(LANGUAGE_SUFFIX)/ clean all

# Utilities to update on server ------------------------------------------------
#
# Update cge-www contents assuming they are in $CASTLE_ENGINE_PATH/../cge-www/ .
#
# The full sequence to do update:
# - make update-cge-www
# - commit and push cge-www repo,
# - www_synchronize_noimages.sh on sever.

# Variables (adjust CGE_WWW_PATH if it's not in the default location).
CGE_WWW_PATH:=$(CASTLE_ENGINE_PATH)/../cge-www/
CGE_ADOC_PATH:=$(CGE_WWW_PATH)/htdocs/doc/modern_pascal.adoc
CGE_SAMPLES_PATH:=$(CGE_WWW_PATH)/htdocs/doc/modern_pascal_code_samples/

# Copy from here to cge-www one language version.
.PHONY: copy-one-language
copy-one-language: test clean all
	cp -f $(NAME).html $(NAME).pdf patreon-wordmark.png $(CGE_WWW_PATH)htdocs/

# Copy from here to cge-www all languages' versions.
.PHONY: copy-all
copy-all:
	$(MAKE) copy-one-language
	$(MAKE) copy-one-language LANGUAGE_SUFFIX=_russian ASCIIDOCTOR_LANGUAGE='-a lang=ru'
	$(MAKE) copy-one-language LANGUAGE_SUFFIX=_bg ASCIIDOCTOR_LANGUAGE='-a lang=bg'
	$(MAKE) copy-one-language LANGUAGE_SUFFIX=_ukrainian ASCIIDOCTOR_LANGUAGE='-a lang=ua'
	cp -f modern_pascal_introduction_chinese.pdf $(CGE_WWW_PATH)htdocs/

# Copy from here to cge-www everything: HTML and PDF generated by AsciiDoctor,
# adoc (for rendering with CGE website styles), and code samples.
.PHONY: update-cge-www
update-cge-www: copy-all
# Sanity check.
	if [ ! -f $(CGE_ADOC_PATH) ]; then \
	  echo "Missing $(CGE_ADOC_PATH), make sure CASTLE_ENGINE_PATH env variable is OK and cge-www is cloned alongside"; \
		exit 1; \
	fi

# Copy and adjust adoc file.
#
# We version the $(CGE_ADOC_PATH).1,2,3... to
# - allow easy debugging what script did (look at each file in succession)
# - not worry that tail would have equal stdin and stdout.
	cp -f modern_pascal_introduction.adoc $(CGE_ADOC_PATH).1
	tail --lines=+9 $(CGE_ADOC_PATH).1 > $(CGE_ADOC_PATH).2
	cat cge_www_header.adoc $(CGE_ADOC_PATH).2 > $(CGE_ADOC_PATH).3
	sed -e 's|include::code-samples/|include::modern_pascal_code_samples/|' $(CGE_ADOC_PATH).3 > $(CGE_ADOC_PATH).4
	cp -f $(CGE_ADOC_PATH).4 $(CGE_ADOC_PATH)
	rm -f $(CGE_ADOC_PATH).?

# Copy the code samples.
# Avoid deleting/overwriting .gitignore there, which is maintained by hand in cge-www.
	find $(CGE_SAMPLES_PATH) \
	  '(' -type f -name .gitignore -prune ')' -or \
		'(' -type f -execdir rm -f '{}' ';' ')'
	make -C code-samples/ clean
	cp -Rf code-samples/* $(CGE_SAMPLES_PATH)
