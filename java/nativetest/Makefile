TOS=$(shell ncc -print-tosdir)
PACKAGE = edu.wustl.mobilab.native
APP=$(WUBASE)/apps/NativeCode
MIG = mig -I$(APP) -I%T/lib/Util java

MSGS = CodeMsg.java StateMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSROOT)/tools/java
include $(ROOT)/Makefile.include

StateMsg.java:
	$(MIG) -java-classname=$(PACKAGE).StateMsg $(APP)/NativeCode.h StateMsg -o $@

CodeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).CodeMsg $(APP)/NativeCode.h CodeMsg -o $@

cleanmig:
	rm -f $(MSGS)
