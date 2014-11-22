COMPONENT=Agilla
include ./Makefile.Agilla

#CFLAGS+=-DEDIT_TIMESTAMP 
CFLAGS+=-DOPBATTERY 
CFLAGS+=-DENABLE_MDA100=1
CFLAGS+=-DOPCLEARTS
#CFLAGS+=-DOPMORSE
#CFLAGS+=-DMORSE_LED_TEST

PFLAGS+=$(PFLAGS_AGILLA)\
       -I components/ContextDiscovery \
       -I components/AgentReceiver \
       -I components/AgentSender \
       -I components/NetworkInterface \
       -I components/LocationReporter \
       -I components/ClusterheadDirectory \
       -I components \
       -I opcodes \
       -I contexts \
       -I types \
       -I interfaces \
       -I ../SpaceLocalizer \
       -I ../LEDBlinker \
       -I ../agilla

#2014-09-08 -- Path for MDA100 code -- WT
ifeq ($(findstring ENABLE_MDA100, $(CFLAGS)), ENABLE_MDA100)
   PFLAGS+=-I $(TOSROOT)/tos/sensorboards/mda100 \
			-I $(TOSROOT)/tos/sensorboards/mda100/cb
endif

#2014-09-08 -- Path for MTS310 code -- WT
ifeq ($(findstring ENABLE_MTS310, $(CFLAGS)), ENABLE_MTS310)
   PFLAGS+=-I $(TOSROOT)/tos/sensorboards/mts300
endif

include $(TOSROOT)/support/make/Makerules

#Use the following Makerules for dsys25 motes
#include $(TOSROOT)/apps/Makerules
