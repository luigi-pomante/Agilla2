# Top-level Makefile for tools/java 

TOS = $(shell ncc -print-tosdir)
PACKAGE = agilla.messages

include ../Makefile.Agilla

# List of message classes to build
MSGS = AgillaAddressAckMsg.java \
       AgillaBeaconMsg.java \
       AgillaErrorMsg.java \
       AgillaCodeMsg.java \
       AgillaStateMsg.java \
       AgillaHeapMsg.java \
       AgillaOpStackMsg.java \
       AgillaResetMsg.java \
       AgillaAckStateMsg.java \
       AgillaAckCodeMsg.java \
       AgillaAckHeapMsg.java \
       AgillaAckOpStackMsg.java \
       AgillaAckRxnMsg.java \
       AgillaTSReqMsg.java \
       AgillaTSResMsg.java \
       AgillaAddressMsg.java \
       AgillaGetNbrMsg.java \
       AgillaNbrMsg.java \
       AgillaRxnMsg.java \
       AgillaSetBSMsg.java \
       AgillaGridSizeMsg.java \
       AgillaTimeSyncMsg.java \
       AgillaLocMsg.java
       
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

#ROOT = $(TOS)/../tools/java
ROOT = $(TOS)/../support/sdk/java
include $(ROOT)/Makefile.include
AGILLA=$(AGILLA)

NCG = ncg java

BINCLUDES=-I$(AGILLA)/ -I$(AGILLA)/components -I$(AGILLA)/interfaces -I$(AGILLA)/types -I$(AGILLA)/opcodes -I$(TOS)../../tinyos-1.x/tos/lib/Queue -I$(TOS)/sensorboards/mts300

AgillaAddressAckMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaAddressAckMsg $(AGILLA)/types/Agilla.h AgillaAddressAckMsg -o $@

AgillaAddressMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaAddressMsg $(AGILLA)/types/Agilla.h AgillaAddressMsg -o $@

AgillaGetNbrMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaGetNbrMsg $(AGILLA)/types/Agilla.h AgillaGetNbrMsg -o $@

AgillaNbrMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaNbrMsg $(AGILLA)/types/Agilla.h AgillaNbrMsg -o $@
	
AgillaBeaconBSMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaBeaconBSMsg $(AGILLA)/types/Agilla.h AgillaBeaconBSMsg -o $@

AgillaBeaconMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaBeaconMsg $(AGILLA)/types/Agilla.h AgillaBeaconMsg -o $@

AgillaGridSizeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaGridSizeMsg $(AGILLA)/types/Agilla.h AgillaGridSizeMsg -o $@
	
AgillaSetBSMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaSetBSMsg $(AGILLA)/types/Agilla.h AgillaSetBSMsg -o $@
	
AgillaStartExpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaStartExpMsg $(AGILLA)/types/Agilla.h AgillaStartExpMsg -o $@

AgillaExpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaExpMsg $(AGILLA)/types/Agilla.h AgillaExpMsg -o $@

AgillaErrorMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaErrorMsg $(AGILLA)/types/Agilla.h AgillaErrorMsg -o $@

AgillaCodeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaCodeMsg $(AGILLA)/types/MigrationMsgs.h AgillaCodeMsg -o $@

AgillaStateMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaStateMsg $(AGILLA)/types/MigrationMsgs.h AgillaStateMsg -o $@

AgillaHeapMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaHeapMsg $(AGILLA)/types/MigrationMsgs.h AgillaHeapMsg -o $@

AgillaOpStackMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaOpStackMsg $(AGILLA)/types/MigrationMsgs.h AgillaOpStackMsg -o $@

AgillaResetMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaResetMsg $(AGILLA)/types/Agilla.h AgillaResetMsg -o $@
	
AgillaRxnMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaRxnMsg $(AGILLA)/types/MigrationMsgs.h AgillaRxnMsg -o $@

AgillaAckCodeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaAckCodeMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckCodeMsg -o $@

AgillaAckStateMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaAckStateMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckStateMsg -o $@

AgillaAckHeapMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaAckHeapMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckHeapMsg -o $@

AgillaAckOpStackMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaAckOpStackMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckOpStackMsg -o $@

AgillaAckRxnMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaAckRxnMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckRxnMsg -o $@

AgillaTSReqMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaTSReqMsg $(AGILLA)/types/TupleSpace.h AgillaTSReqMsg -o $@

AgillaTSResMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaTSResMsg $(AGILLA)/types/TupleSpace.h AgillaTSResMsg -o $@

AgillaTimeSyncMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaTimeSyncMsg $(AGILLA)/types/TimeSync.h AgillaTimeSyncMsg -o $@

AgillaLocMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AgillaLocMsg $(AGILLA)/types/LocationDirectory.h AgillaLocMsg -o $@
		
cleanmig:
	rm -f $(MSGS)
