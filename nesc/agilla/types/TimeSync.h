#ifndef TIMESYNC_H_INCLUDED
#define TIMESYNC_H_INCLUDED

#include "TosTime.h"

enum {
	AM_AGILLATIMESYNCMSG = 0x50,
};


typedef nx_struct AgillaTimeSyncMsg
{
	tos_time_t time;
} AgillaTimeSyncMsg;

#endif
