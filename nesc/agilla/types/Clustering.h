#ifndef CLUSTERING_H_INCLUDED
#define CLUSTERING_H_INCLUDED

#include "TosTime.h"
#include "Agilla.h"

enum {
	AM_AGILLACLUSTERDEBUGMSG = 0x4b,
	AM_AGILLACLUSTERMSG = 0x51,
};

typedef struct AgillaRectangle {
	AgillaLocation llc;	 // 4 bytes Lower left corner of rectangle (x,y)
	AgillaLocation urc;	 // 4 bytes Upper right corner of rectangle (x,y)
} AgillaRectangle;			// 8 bytes

typedef struct AgillaClusterDebugMsg
{
	uint16_t src;
	uint16_t id;					// clusterhead id
	AgillaRectangle bounding_box; // set if sent by clusterhead
} AgillaClusterDebugMsg;

typedef struct AgillaClusterMsg {
	uint16_t id;					// 2 bytes Clusterhead id
	AgillaRectangle bounding_box;	 // 8 bytes Bounding box of cluster
} AgillaClusterMsg;				 // 10 bytes


#endif
