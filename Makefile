PREFIX=.
BIN=$(PREFIX)/bin/
ELMANDIR=src/elman/
WAPITIDIR=src/wapiti/

all : elephant elephant-train elman

elman :
	cd $(ELMANDIR)
	make

wapiti : 
	cd $(WAPITIDIR)
	make

elephant : src/elephant elman wapiti

elephant-train : src/elephant-train elephant

install : elephant elephant-train
	cp elephant elephant-train $(WAPITIDIR)/wapiti $(ELMAN)/elman $(BIN)

clean :
	rm -f $(BIN)/elephant $(BIN)/elephant-train $(BIN)/wapiti $(BIN)/elman
	cd $(WAPITIDIR) ; make clean
	cd $(ELMANDIR) ; make clean

