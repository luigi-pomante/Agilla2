#ifndef AGILLA_EXP_LOGGER_H_INCLUDED
#define AGILLA_EXP_LOGGER_H_INCLUDED

#include "TosTime.h"
#include "Agilla.h"
#include "LocationDirectory.h"

enum {
	AM_AGILLAEXPQUERYRESULTSMSG = 0x90,
	AM_AGILLAEXPLATENCYMSG = 0x91,
	AM_AGILLAEXPRESULTSMSG = 0x92,
	AM_AGILLATRACEMSG = 0x93,
	AM_AGILLATRACEGETAGENTSMSG = 0x94
};

/**
 * This is sent from the base station to a mote
 * to get the experimental results.
 */
typedef struct AgillaExpQueryResultsMsg {
	uint16_t dummy;
} AgillaExpQueryResultsMsg;

/**
 * This is sent from the mote to the base station
 * whenever a latency is measured.
 */
typedef struct AgillaExpLatencyMsg {
	uint32_t latency;
} AgillaExpLatencyMsg;

/**
 * This is sent from the mote to the base station
 * after the base station queries for the experimental
 * results.
 */
typedef struct AgillaExpResultsMsg {
	uint16_t numQueries;
	uint16_t numUpdates;
	uint16_t numReplies;
} AgillaExpResultsMsg;


enum {
	AGENT_MOVED = 0,
	QUERY_GET_LOCATION_ISSUED = 1,
	QUERY_GET_LOCATION_RESULTS_RECEIVED = 2,
	QUERY_GET_LOCATION_FORWARDED = 3,
	QUERY_GET_LOCATION_RESULTS_FORWARDED = 4,
	SET_CLUSTER_HEAD = 5,
	AGENT_MIGRATING = 6,
	QUERY_GET_CLOSEST_AGENT_ISSUED = 7,
	QUERY_GET_CLOSEST_AGENT_RESULTS_RECEIVED = 8,
	CLUSTER_AGENT_ADDED = 9,
	CLUSTER_AGENT_REMOVED = 10,
	CLUSTER_AGENT_CLEARED = 11,
	CLUSTERHEAD_DIRECTORY_STARTED = 12,
	CLUSTERHEAD_DIRECTORY_STOPPED = 13,
	AGENT_LOCATION_SENT = 14,
	QUERY_GET_CLOSEST_AGENT_FORWARDED = 15,
	QUERY_GET_CLOSEST_AGENT_RESULTS_FORWARDED = 16,
	QUERY_GET_AGENTS_ISSUED = 17,
	QUERY_GET_AGENTS_RESULT_RECEIVED = 18,
	QUERY_GET_AGENTS_FORWARDED = 19,
	QUERY_GET_AGENTS_RESULTS_FORWARDED = 20,
	SENDING_AGENT_LOCATION = 21,
	CLUSTER_AGENT_UPDATED = 22

	/*STATE_ACCEPTED = 7,
	CODE_ACCEPTED = 8,
	HEAP_ACCEPTED = 9,
	OPSTACK_ACCEPTED = 10,
	RXN_ACCEPTED = 11,
	STATE_REJECTED = 12,
	CODE_REJECTED = 13,
	HEAP_REJECTED = 14,
	OPSTACK_REJECTED = 15,
	RXN_REJECTED = 16,*/
} AgillaTraceConstants;

/**
 * This is sent from the mote to the base station
 * after the base station queries for the experimental
 * results.
 */
typedef struct AgillaTraceMsg {
	tos_time_t timestamp;			 // 8 bytes
	uint16_t agentID;				 // 2 bytes
	uint16_t nodeID;				// 2 bytes
	uint16_t action;				// 2 bytes
	uint16_t qid;					 // 2 bytes: query id
	uint16_t success;				 // 2 bytes
	AgillaLocation loc;			 // 4 bytes
} AgillaTraceMsg; // 22 bytes

typedef struct AgillaTraceGetAgentsMsg {
	tos_time_t timestamp;					 // 8 bytes
	uint16_t agentID;						 // 2 bytes
	uint16_t nodeID;						// 2 bytes
	uint16_t qid;							 // 2 bytes
	uint16_t num_agents;					// 2 bytes
	AgillaAgentID agent_id[MAX_AGENT_NUM];	 // 2 bytes: id of agent
	AgillaLocation loc[MAX_AGENT_NUM];		 // 4 bytes: location of agent
} AgillaTraceGetAgentsMsg; // 28 bytes
#endif
