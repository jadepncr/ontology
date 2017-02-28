MAKEFLAGS += -J2
# "2010-01-01"^^xsd:date
ONTOLOGY=cwrc
ONTOLOGY_DATE = $(shell date -u +"%Y-%m-%d")
DATE_CLEAN = $(shell date -u +"%Y%m%d")
ONTOLOGY_LONGDATE = $(shell date -d '$(ONTOLOGY_DATE)'  +'%d %B %Y')
ONTOLOGY_VERSION = $(shell xpath $(ONTOLOGY).owl  '/rdf:RDF/owl:Ontology/owl:versionInfo/text()' 2> /dev/null)
ONTOLOGY_LOGO = $(shell xpath $(ONTOLOGY).owl '/rdf:RDF/owl:Ontology/foaf:logo/@rdf:resource'  2> /dev/null | sed 's/\//\\\//g' | cut -d "\"" -f 2)
#shell xpath -e '/rdf:RDF/owl:Ontology/foaf:logo/text()' $(ONTOLOGY).owl 2> /dev/null)
force:	$(ONTOLOGY).owl
	touch $(ONTOLOGY).owl
	touch $(ONTOLOGY)-template.html	
all:	$(ONTOLOGY)-$(ONTOLOGY_DATE).owl
$(ONTOLOGY)-$(ONTOLOGY_DATE).owl: $(ONTOLOGY).owl 
	echo $(ONTOLOGY_LOGO)
	xpath $(ONTOLOGY).owl "/rdf:RDF" 1> /dev/null 2> /dev/null
	sed 's/DATE_TODAY/$(DATE_CLEAN)/g' < $(ONTOLOGY).owl > $(ONTOLOGY)-$(ONTOLOGY_DATE).owl	
$(ONTOLOGY)-$(ONTOLOGY_DATE).nt: $(ONTOLOGY)-$(ONTOLOGY_DATE).owl
	rapper -o turtle $(ONTOLOGY)-$(ONTOLOGY_DATE).owl > $(ONTOLOGY)-$(ONTOLOGY_DATE).nt
$(ONTOLOGY)-$(ONTOLOGY_DATE).ttl: $(ONTOLOGY)-$(ONTOLOGY_DATE).owl
	rapper -o turtle $(ONTOLOGY)-$(ONTOLOGY_DATE).owl > $(ONTOLOGY)-$(ONTOLOGY_DATE).ttl	
all:	$(ONTOLOGY)-$(ONTOLOGY_DATE).html $(ONTOLOGY)-$(ONTOLOGY_DATE).ttl $(ONTOLOGY)-$(ONTOLOGY_DATE).nt  $(ONTOLOGY)-$(ONTOLOGY_DATE).owl #$(ONTOLOGY)-overall-$(ONTOLOGY_DATE).jpg		
	cp -f $(ONTOLOGY)-$(ONTOLOGY_DATE).html cwrc.html
#	cp -f $(ONTOLOGY)-$(ONTOLOGY_DATE).owl  ~/public_html/.
#	cp -f $(ONTOLOGY)-overall-$(ONTOLOGY_DATE).jpg ~/public_html/images/.
#	cp -f $(ONTOLOGY)-overall-small-$(ONTOLOGY_DATE).jpg ~/public_html/images/.
$(DOCS_TEMPLATES): $(DOCS) $(ONTOLOGY).owl
	./generateTermDocumentation.sh doc $(ONTOLOGY)-docs/
$(ONTOLOGY)-$(ONTOLOGY_DATE).dot: $(ONTOLOGY).owl
	grep -v "rdfs:label" $(ONTOLOGY).owl  | grep -v "rdfs:comment"| grep -v "foaf:name" | grep -v "rdf:type" | rapper -o dot - "http://rdf.muninn-project.org/ontologies/"$(ONTOLOGY)"#" | grep -v "owl:Class" | grep -v "owl:ObjectProperty" > $(ONTOLOGY)-$(ONTOLOGY_DATE).dot
$(ONTOLOGY)-template-$(ONTOLOGY_DATE).html: $(ONTOLOGY)-template.html figures/religionTaxonomy.png
	sed "s/PREVIOUS_ONTOLOGY/$(PREVIOUS_ONTOLOGY)/g"  < $(ONTOLOGY)-template.html | sed "s/ONTOLOGY_NAME/$(ONTOLOGY)/g"  | sed "s/ONTOLOGY_DATE/$(ONTOLOGY_DATE)/g" |  sed "s/ONTOLOGY_LONGDATE/$(ONTOLOGY_LONGDATE)/g"  | sed "s/ONTOLOGY_VERSION/$(ONTOLOGY_VERSION)/g"  | sed 's/ONTOLOGY_LOGO/$(ONTOLOGY_LOGO)/g'  > $(ONTOLOGY)-template-$(ONTOLOGY_DATE).html
$(ONTOLOGY)-template2-$(ONTOLOGY_DATE).html: $(ONTOLOGY)-template-$(ONTOLOGY_DATE).html
	 m4 -P $(ONTOLOGY)-template-$(ONTOLOGY_DATE).html > $(ONTOLOGY)-template2-$(ONTOLOGY_DATE).html
$(ONTOLOGY)-$(ONTOLOGY_DATE).html: $(ONTOLOGY)-$(ONTOLOGY_DATE).owl $(ONTOLOGY)-template2-$(ONTOLOGY_DATE).html # $(ONTOLOGY)-overall-$(ONTOLOGY_DATE).jpg
	./specgen.py $(ONTOLOGY)-$(ONTOLOGY_DATE).owl $(ONTOLOGY) $(ONTOLOGY)-template2-$(ONTOLOGY_DATE).html  $(ONTOLOGY)-$(ONTOLOGY_DATE).html  -i
#$(ONTOLOGY)-overall-$(ONTOLOGY_DATE).jpg: $(ONTOLOGY)-$(ONTOLOGY_DATE).dot
#	dot -o $(ONTOLOGY)-overall-$(ONTOLOGY_DATE).jpg -Tpng $(ONTOLOGY)-$(ONTOLOGY_DATE).dot
#$(ONTOLOGY)-overall-small-$(ONTOLOGY_DATE).jpg:  $(ONTOLOGY)-overall-$(ONTOLOGY_DATE).jpg
#	convert -resize 320x200 $(ONTOLOGY)-overall-$(ONTOLOGY_DATE).jpg -resize 320x200 $(ONTOLOGY)-overall-small-$(ONTOLOGY_DATE).jpg
$(ONTOLOGY)-$(ONTOLOGY_DATE)-citations.html:     $(ONTOLOGY)-ref.bib
	bibtex2html -nodoc -nobibsource -unicode --quiet -o - $(ONTOLOGY)-ref.bib  | sed "s/<\/table><hr><p><em>This file was generated by/<\/table>/" | head -n -1 > $(ONTOLOGY)-$(ONTOLOGY_DATE)-citations.html
$(ONTOLOGY)-ref.bib:
	wget -N -O $(ONTOLOGY)-ref.bib "https://api.zotero.org/groups/1018142/items/top?start=0&limit=250&format=bibtex&v=1"
figures/religionTaxonomy.png: $(ONTOLOGY)-$(ONTOLOGY_DATE).owl
	./scripts/createReligionTaxonomy.pl $(ONTOLOGY)-$(ONTOLOGY_DATE).owl | dot -ofigures/religionTaxonomy.png -Tpng 
clean:
	rm -f $(ONTOLOGY)-$(ONTOLOGY_DATE).dot $(ONTOLOGY)-$(ONTOLOGY_DATE).owl $(ONTOLOGY)-template-$(ONTOLOGY_DATE).html $(ONTOLOGY)-$(ONTOLOGY_DATE).html $(ONTOLOGY)-$(ONTOLOGY_DATE)-citations.html
