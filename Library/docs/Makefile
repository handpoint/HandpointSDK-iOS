DOCSET_NAME=com.handpoint.heft.docset
DESTDIR=~/Library/Developer/Shared/Documentation/DocSets

all: install

install: uninstall
	mkdir -p $(DESTDIR)
	cp -R $(DOCSET_NAME) $(DESTDIR)

uninstall:
	rm -rf $(DESTDIR)/$(DOCSET_NAME)
