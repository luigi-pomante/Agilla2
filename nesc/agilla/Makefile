COMPONENT=Agilla
include ./Makefile.Agilla

# De-comment to enable instruction timing debug mode
#CFLAGS+=-DEDIT_TIMESTAMP

# De-comment to enable "battery" instruction
CFLAGS+=-DOPBATTERY 

# De-comment to enable "clearts" instruction
CFLAGS+=-DOPCLEARTS

# De-comment to enable "checkvoice" instruction
CFLAGS+=-DCHECKVOICE

# Enable correct sensorboard
#CFLAGS+=-DENABLE_MDA100=1
CFLAGS+=-DENABLE_MTS310=1

# De-comment to enable "morse" instruction and on-mote morse led test
#CFLAGS+=-DOPMORSE
#CFLAGS+=-DMORSE_LED_TEST

# de-comment to enable 'id' parsing in morse instruction
#CFLAGS+=-DMORSE_ID_CHECK

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
   SENSORBOARD=mda100
   PFLAGS+=-I $(TOSROOT)/tos/sensorboards/mda100 \
			-I $(TOSROOT)/tos/sensorboards/mda100/cb
endif

#2014-09-08 -- Path for MTS310 code -- WT
ifeq ($(findstring ENABLE_MTS310, $(CFLAGS)), ENABLE_MTS310)
   SENSORBOARD=mts310
   CFLAGS+=-DMTS310CA
   PFLAGS+=-I $(TOSROOT)/tos/sensorboards/mts300
endif

include $(TOSROOT)/support/make/Makerules

#Use the following Makerules for dsys25 motes
#include $(TOSROOT)/apps/Makerules
