#ifndef AGILLA_LOCATION_DIRECTORY_H_INCLUDED
#define AGILLA_LOCATION_DIRECTORY_H_INCLUDED

#include "Agilla.h"
#include "TosTime.h"

#define NO_CH 0xff

enum {
	MAX_AGENT_NUM = 2,
	MAX_AGENT_ARRAY_NUM = 10,
} AgillaLocDirConstants;



enum {
	AM_AGILLALOCMSG = 0x42,
	AM_AGILLAQUERYNUMAGENTSMSG = 0x43,
	AM_AGILLAQUERYAGENTLOCMSG = 0x44,
	AM_AGILLAQUERYNEARESTAGENTMSG = 0x45,
	AM_AGILLAQUERYALLAGENTSMSG = 0x46,
	AM_AGILLAQUERYREPLYNUMAGENTSMSG = 0x47,
	AM_AGILLAQUERYREPLYAGENTLOCMSG = 0x48,
	AM_AGILLAQUERYREPLYNEARESTAGENTMSG = 0x49,
	AM_AGILLAQUERYREPLYALLAGENTSMSG = 0x4a,
};

/**
 * These flags are used in the "flag" field of the query
 * messages.
 */
enum {
	LOCAL = 0x00,
	GLOBAL = 0x01,
} QueryFlags;

/**
 * These flags are used in the "flag" field of the query
 * reply message.
 */
enum {
	INVALID = 0x01,
	VALID = 0x02,	 // Does the message contain results?
	COARSE = 0x04,	 // Is it from the BS or from the CH?
} QueryReplyFlags;
	


typedef nx_struct AgillaLocMAgentInfo {
	AgillaAgentID agent_id;	 // 2 bytes: id of agent
	AgillaLocation loc;		 // 4 bytes: location of agent
} AgillaLocMAgentInfo;		// 6 bytes

/**
 *
 * This message is used by the location directory service to
 * update the Base Station about an agent location.
 *
 */

typedef nx_struct AgillaLocMsg {
	AgillaAgentID agent_id;		 // 2 bytes: id of agent detected
	nx_uint16_t agent_type;			// 2 bytes: type of agent
	nx_uint16_t src;				 // 2 bytes: src id of host that detected the agent
	AgillaLocation loc;			 // 4 bytes: location of agent
	tos_time_t timestamp;		 // 2 bytes: time at which agent was detected
	nx_uint16_t dest;				// 2 bytes: destination id (BS id)
	nx_uint16_t seq;				 // 2 bytes: sequence number of message
} AgillaLocMsg;				 // 18 bytes

/**
 *
 * This message is used to query the total number of agents of type "type" in the system
 *
 */

typedef nx_struct AgillaQueryNumAgentsMsg {
	AgillaAgentID agent_id;		 // 2 bytes: id of agent issuing query
	nx_uint16_t src;				 // 2 bytes: src id of host that contains the agent
	nx_uint16_t dest;				// 2 bytes: id of node to which query needs to be routed
	nx_uint16_t qid;				 // 2 bytes: query id
	nx_uint16_t flags;				 // 2 bytes: bit 0 represents if the query should be reolved only in the current
								// sensor netowrk or throughout the system (across sensor networks)
								// if bit 0 is 1 then the query should be sent to all networks
	nx_uint16_t agent_type;			// 2 bytes: type of agent being queried
} AgillaQueryNumAgentsMsg;		// 12 bytes

/**
 *
 * This message is used to query the location of a particular agent in the system
 *
 */
typedef nx_struct AgillaQueryAgentLocMsg {
	AgillaAgentID agent_id;		 // 2 bytes: id of agent issuing query
	nx_uint16_t src;				 // 2 bytes: src id of host that contains the agent
	nx_uint16_t dest;				// 2 bytes: id of node to which query needs to be routed
	nx_uint16_t qid;				 // 2 bytes: query id
	nx_uint16_t flags;				 // 2 bytes: bit 0 represents if the query should be resolved only in the current
								// sensor network or throughout the system (across sensor networks)
								// if bit 0 is 1 then the query should be sent to all networks
	AgillaAgentID find_agent_id;	// 2 bytes: id of agent whose location is requested
} AgillaQueryAgentLocMsg;		 // 12 bytes

/**
 *
 * This message is used to query the location and id of an agent of type "type" that is physically
 * closest to the querying agent
 *
 */
typedef nx_struct AgillaQueryNearestAgentMsg {
	AgillaAgentID agent_id;		 // 2 bytes: id of agent issuing query
	nx_uint16_t src;				 // 2 bytes: src id of host that contains the agent
	nx_uint16_t dest;				// 2 bytes: id of node to which query needs to be routed
	nx_uint16_t qid;				 // 2 bytes: query id
	nx_uint16_t flags;				 // 2 bytes: bit 0 represents if the query should be reolved only in the current
								// sensor netowrk or throughout the system (across sensor networks)
								// if bit 0 is 1 then the query should be sent to all networks
	AgillaLocation loc;			 // 4 bytes: location of agent issuing query
	nx_uint16_t agent_type;			// 2 bytes: type of agent being queried
} AgillaQueryNearestAgentMsg;	 // 16 bytes

/**
 *
 * This message is used to query the location and ids of all agents of type "type" in the system
 *
 */

typedef nx_struct AgillaQueryAllAgentsMsg {
	AgillaAgentID agent_id;		 // 2 bytes: id of agent issuing query
	nx_uint16_t src;				 // 2 bytes: src id of host that contains the agent
	nx_uint16_t dest;				// 2 bytes: id of node to which query needs to be routed
	nx_uint16_t qid;				 // 2 bytes: query id
	nx_uint16_t flags;				 // 2 bytes: bit 0 represents if the query should be reolved only in the current
								// sensor netowrk or throughout the system (across sensor networks)
								// if bit 0 is 1 then the query should be sent to all networks
	nx_uint16_t agent_type;			// 2 bytes: type of agent being queried
} AgillaQueryAllAgentsMsg;		// 12 bytes

/**
 *
 * This message contains the reply to a query asking for the number of agents in the system
 *
 */
typedef nx_struct AgillaQueryReplyNumAgentsMsg {
	AgillaAgentID agent_id;		 // 2 bytes: id of agent issuing query
	nx_uint16_t dest;				// 2 bytes: id of node to which query result should to be routed
	nx_uint16_t qid;				 // 2 bytes: query id
	nx_uint16_t flags;				 // 2 bytes: bit 0 = coarse
	nx_int16_t num_agents;			 // 2 bytes: number of agents
} AgillaQueryReplyNumAgentsMsg; // 8 bytes

/**
 *
 * This message contains the reply to a query asking for the location of a particular agent in the system
 *
 */
typedef nx_struct AgillaQueryReplyAgentLocMsg {
	AgillaAgentID agent_id;		 // 2 bytes: id of agent issuing query
	nx_uint16_t dest;				// 2 bytes: id of node to which query result should to be routed
	nx_uint16_t qid;				 // 2 bytes: query id
	nx_uint16_t flags;				 // 2 bytes: bit 0 = coarse
	AgillaLocation loc;			 // 4 bytes: location of agent that was requested by the query
	AgillaString nw_desc;		 // 2 bytes: network description; unique for each sensor network
} AgillaQueryReplyAgentLocMsg;	// 14 bytes

/**
 *
 * This message contains the reply to a query asking for the nearest agent (to the querying agent)
 * of a particular type in the system.
 *
 */
typedef nx_struct AgillaQueryReplyNearestAgentMsg {
	AgillaAgentID agent_id;			 // 2 bytes: id of agent issuing query
	nx_uint16_t src;					 // 2 bytes: id of node sending the reply
	nx_uint16_t dest;					// 2 bytes: id of node to which query result should to be routed
	nx_uint16_t qid;					 // 2 bytes: query id
	nx_uint16_t flags;					 // 2 bytes: bit 0 = coarse
	AgillaAgentID nearest_agent_id;	 // 2 bytes: id of nearest agent
	AgillaLocation nearest_agent_loc; // 4 bytes: location of nearest agent
} AgillaQueryReplyNearestAgentMsg;	// 16 bytes

/**
 *
 * This message contains the reply to a query asking for the locations and ids of all agents
 * of a particular type in the system.
 *
 */
typedef nx_struct AgillaQueryReplyAllAgentsMsg {
	AgillaAgentID agent_id;							 // 2 bytes: id of agent issuing query
	nx_uint16_t src;									 // 2 bytes: id of node sending the reply
	nx_uint16_t dest;									// 2 bytes: id of node to which query result should to be routed
	nx_uint16_t qid;									 // 2 bytes: query id
	nx_uint16_t num_agents;								// 2 bytes: number of agents
	nx_uint16_t flags;									 // 2 bytes: bit 0 = coarse
	AgillaLocMAgentInfo agent_info[MAX_AGENT_NUM];	// 12 bytes: agent info (id, loc) 6 bytes each
} AgillaQueryReplyAllAgentsMsg;					 // 24 bytes

#endif
