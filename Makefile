BIN=bin/
ELMANDIR=third-party/rnnlm/
WAPITIDIR=third-party/Wapiti/
ELEPHANTDIR=third-party/elephant

all : elman wapiti elephant


# rnnlm: replacing specific compiler x86_64-linux-g++-4.6 defined in
#        rnnlm Makefile with standard compiler g++
elman :
	cd $(ELMANDIR); make CC=g++

wapiti : 
	cd $(WAPITIDIR); make

elephant : elman wapiti $(ELEPHANTDIR)/src/elephant $(ELEPHANTDIR)/src/elephant-train 


# preserving Elephant naming for rnnlm executable, i.e. renaming 'rnnlm' to 'elman'
install : elephant
	cp $(WAPITIDIR)/wapiti $(ELEPHANTDIR)/src/elephant $(ELEPHANTDIR)/src/elephant-train $(BIN); cp $(ELMANDIR)/rnnlm $(BIN)/elman


clean :
	rm -f $(BIN)/elephant $(BIN)/elephant-train $(BIN)/wapiti $(BIN)/elman
	cd $(WAPITIDIR) ; make clean
	cd $(ELMANDIR) ; make clean


