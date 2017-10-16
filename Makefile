BIN=bin/
ELMANDIR=third-party/elman/
WAPITIDIR=third-party/Wapiti/
ELEPHANTDIR=third-party/elephant

all : elman wapiti elephant


elman :
	cd $(ELMANDIR); make

wapiti : 
	cd $(WAPITIDIR); make

elephant : elman wapiti $(ELEPHANTDIR)/src/elephant $(ELEPHANTDIR)/src/elephant-train 


install : elephant
	cp $(WAPITIDIR)/wapiti $(ELMANDIR)/elman $(ELEPHANTDIR)/src/elephant $(ELEPHANTDIR)/src/elephant-train $(BIN)


clean :
	rm -f $(BIN)/elephant $(BIN)/elephant-train $(BIN)/wapiti $(BIN)/elman
	cd $(WAPITIDIR) ; make clean
	cd $(ELMANDIR) ; make clean


