include ./Makefile.Agilla      

SUBDIRS = clients rmi variables messages opcodes

TOS = $(shell ncc -print-tosdir)
PACKAGE = agilla

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
       AgillaLocMsg.java \
       AgillaQueryNumAgentsMsg.java \
       AgillaQueryAgentLocMsg.java \
       AgillaQueryNearestAgentMsg.java \
       AgillaQueryAllAgentsMsg.java \
       AgillaQueryReplyNumAgentsMsg.java \
       AgillaQueryReplyAgentLocMsg.java \
       AgillaQueryReplyNearestAgentMsg.java \
       AgillaQueryReplyAllAgentsMsg.java \
       AgillaClusterMsg.java \
       AgillaExpQueryResultsMsg.java \
       AgillaExpLatencyMsg.java \
       AgillaExpResultsMsg.java \
       AgillaTraceMsg.java \
       AgillaClusterMsg.java \
       AgillaClusterDebugMsg.java \
       AgillaTraceGetAgentsMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN =

ROOT = ../..
#include $(TOSROOT)/tools/java/Makefile.include
include $(TOSROOT)/support/sdk/java/Makefile.include

AGILLA=$(ROOT)/nesc/agilla
NCG = ncg java

BINCLUDES=-I$(AGILLA)/ -I$(AGILLA)/components -I$(AGILLA)/interfaces -I$(AGILLA)/types -I$(AGILLA)/opcodes -I$(TOS)../../tinyos-1.x/tos/lib/Queue -I$(TOS)/sensorboards/mts300

AgillaBeaconMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaBeaconMsg $(AGILLA)/types/Agilla.h AgillaBeaconMsg -o messages/$@
	
AgillaGridSizeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaGridSizeMsg $(AGILLA)/types/Agilla.h AgillaGridSizeMsg -o messages/$@
	
AgillaSetBSMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaSetBSMsg $(AGILLA)/types/Agilla.h AgillaSetBSMsg -o messages/$@

AgillaStartExpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaStartExpMsg $(AGILLA)/types/Agilla.h AgillaStartExpMsg -o messages/$@

AgillaExpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaExpMsg $(AGILLA)/types/Agilla.h AgillaExpMsg -o messages/$@

AgillaErrorMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaErrorMsg $(AGILLA)/types/Agilla.h AgillaErrorMsg -o messages/$@

AgillaCodeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaCodeMsg $(AGILLA)/types/MigrationMsgs.h AgillaCodeMsg -o messages/$@

AgillaStateMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaStateMsg $(AGILLA)/types/MigrationMsgs.h AgillaStateMsg -o messages/$@

AgillaHeapMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaHeapMsg $(AGILLA)/types/MigrationMsgs.h AgillaHeapMsg -o messages/$@

AgillaOpStackMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaOpStackMsg $(AGILLA)/types/MigrationMsgs.h AgillaOpStackMsg -o messages/$@

AgillaResetMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaResetMsg $(AGILLA)/types/Agilla.h AgillaResetMsg -o messages/$@

AgillaAckCodeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaAckCodeMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckCodeMsg -o messages/$@

AgillaAckStateMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaAckStateMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckStateMsg -o messages/$@

AgillaAckHeapMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaAckHeapMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckHeapMsg -o messages/$@

AgillaAckOpStackMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaAckOpStackMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckOpStackMsg -o messages/$@

AgillaAckRxnMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaAckRxnMsg $(AGILLA)/types/MigrationMsgs.h AgillaAckRxnMsg -o messages/$@

AgillaTSReqMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaTSReqMsg $(AGILLA)/types/TupleSpace.h AgillaTSReqMsg -o messages/$@

AgillaTSResMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaTSResMsg $(AGILLA)/types/TupleSpace.h AgillaTSResMsg -o messages/$@

AgillaAddressAckMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaAddressAckMsg $(AGILLA)/types/Agilla.h AgillaAddressAckMsg -o messages/$@


AgillaAddressMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaAddressMsg $(AGILLA)/types/Agilla.h AgillaAddressMsg -o messages/$@

AgillaGetNbrMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaGetNbrMsg $(AGILLA)/types/Agilla.h AgillaGetNbrMsg -o messages/$@

AgillaNbrMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaNbrMsg $(AGILLA)/types/Agilla.h AgillaNbrMsg -o messages/$@
	
AgillaRxnMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaRxnMsg $(AGILLA)/types/MigrationMsgs.h AgillaRxnMsg -o messages/$@

AgillaTimeSyncMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaTimeSyncMsg $(AGILLA)/types/TimeSync.h AgillaTimeSyncMsg -o messages/$@

AgillaLocMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaLocMsg $(AGILLA)/types/LocationDirectory.h AgillaLocMsg -o messages/$@
		
AgillaQueryNumAgentsMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryNumAgentsMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryNumAgentsMsg -o messages/$@
		
AgillaQueryAgentLocMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryAgentLocMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryAgentLocMsg -o messages/$@
		
AgillaQueryNearestAgentMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryNearestAgentMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryNearestAgentMsg -o messages/$@
		
AgillaQueryAllAgentsMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryAllAgentsMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryAllAgentsMsg -o messages/$@
		
AgillaQueryReplyNumAgentsMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryReplyNumAgentsMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryReplyNumAgentsMsg -o messages/$@
		
AgillaQueryReplyAgentLocMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryReplyAgentLocMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryReplyAgentLocMsg -o messages/$@
		
AgillaQueryReplyNearestAgentMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryReplyNearestAgentMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryReplyNearestAgentMsg -o messages/$@
		
AgillaQueryReplyAllAgentsMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaQueryReplyAllAgentsMsg $(AGILLA)/types/LocationDirectory.h AgillaQueryReplyAllAgentsMsg -o messages/$@
		
AgillaClusterMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaClusterMsg $(AGILLA)/types/Clustering.h AgillaClusterMsg -o messages/$@

AgillaExpQueryResultsMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaExpQueryResultsMsg $(AGILLA)/types/ExpLogger.h AgillaExpQueryResultsMsg -o messages/$@

AgillaExpLatencyMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaExpLatencyMsg $(AGILLA)/types/ExpLogger.h AgillaExpLatencyMsg -o messages/$@
	
AgillaExpResultsMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaExpResultsMsg $(AGILLA)/types/ExpLogger.h AgillaExpResultsMsg -o messages/$@

AgillaTraceMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaTraceMsg $(AGILLA)/types/ExpLogger.h AgillaTraceMsg -o messages/$@
		
AgillaClusterDebugMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaClusterDebugMsg $(AGILLA)/types/Clustering.h AgillaClusterDebugMsg -o messages/$@
	
AgillaTraceGetAgentsMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.AgillaTraceGetAgentsMsg $(AGILLA)/types/ExpLogger.h AgillaTraceGetAgentsMsg -o messages/$@

mig: $(MSGS)

cleanmig:
	rm -f $(MSGS)
