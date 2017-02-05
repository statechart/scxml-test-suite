W3C_SUITE = https://www.w3.org/Voice/2013/scxml-irp
SAXON = https://downloads.sourceforge.net/project/saxon/Saxon-HE/9.7/SaxonHE9-7-0-14J.zip

TXML = $(shell find w3c -type f -iname '*.txml')
W3C_SCXML = $(TXML:.txml=.scxml)

generate: w3c/.manifest saxon/saxon9he.jar
	@$(MAKE) w3c.tar.gz

w3c.tar.gz: $(W3C_SCXML)
	@find w3c \( -name '*.scxml' -o -name '*.description' \) -print \
	| tar -cf $@ --files-from -

%.scxml: %.txml w3c/conf_ecmascript.xsl
	@java -jar saxon/saxon9he.jar --suppressXsltNamespaceCheck:on -s:$< -xsl:w3c/conf_ecmascript.xsl -o:$@
	@echo $@

w3c/.manifest: w3c/manifest.xml w3c_manifest.exs
	@mix run w3c_manifest.exs w3c/manifest.xml $@ $(W3C_SUITE)

w3c/manifest.xml:
	@mkdir -p w3c
	@curl -L $(W3C_SUITE)/manifest.xml -o $@

w3c/conf_ecmascript.xsl:
	@curl -L $(W3C_SUITE)/confEcma.xsl -o $@

saxon/saxon9he.jar:
	@mkdir -p saxon
	@curl -L $(SAXON) -o saxon/saxon.zip
	@unzip -o saxon/saxon.zip -d saxon

clean:
	@rm -rf w3c
	@rm -rf saxon

.PHONY: clean generate
