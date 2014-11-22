// $Id: ClusterheadDirectoryM.nc,v 1.4 2006/05/06 00:26:57 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis
 * By Chien-Liang Fok.
 *
 * Washington University states that Agilla is free software;
 * you can redistribute it and/or modify it under the terms of
 * the current version of the GNU Lesser General Public License
 * as published by the Free Software Foundation.
 *
 * Agilla is distributed in the hope that it will be useful, but
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER
 * PROPRIETARY RIGHTS.	THERE ARE NO WARRANTIES THAT SOFTWARE IS
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS",
 * OR OTHER HARMFUL CODE.
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to
 * indemnify, defend, and hold harmless WU, its employees, officers and
 * agents from any and all claims, costs, or liabilities, including
 * attorneys fees and court costs at both the trial and appellate levels
 * for any loss, damage, or injury caused by your actions or actions of
 * your officers, servants, agents or third parties acting on behalf or
 * under authorization from you, as a result of using Agilla.
 *
 * See the GNU Lesser General Public License for more details, which can
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */
#include "Agilla.h"

/**
 * The Clusterhead Directory maintains clusterhead information like
 * bounding box and agents detected by cluster members and itself. This
 * module handles queries from agents and either replies to the query
 * if it has the required information or passes the query upto the GW
 * and then passes the query reply to cluster member on receiving it
 * from the GW.
 *
 * @author Sangeeta Bhattacharya
 */

module ClusterheadDirectoryM {
	provides {
	interface StdControl;
	interface ClusterheadDirectoryI;
	}
	uses {
	interface Random; // used to randomize the sending of the cluster msg

	interface AddressMgrI;
	
	// This timer periodically sends a to the base station.
	interface Timer as ClusterTimer;
	
	// This timer is used to find and remove expired agents 
	// from the directory.
	interface Timer as AgentExpTimer; 

	// Send cluster id and bounding box to GW node
	interface SendMsg as SendClusterMsg;
	interface ReceiveMsg as RcvClusterMsg;

	// Grid topology
	interface LocationMgrI;
	interface LocationUtilI;
	interface NeighborListI;
	interface ClusteringI;
	interface MessageBufferI;
	interface Time;
	interface TimeUtil;

	interface Leds; // debug

	#if ENABLE_EXP_LOGGING
		interface ExpLoggerI;
	#endif
	}
}
implementation {

	/**
	 * Stores information about a node in the cluster.
	 */
	typedef struct ClusterMember {
	uint16_t addr;			// 2 bytes: The address of the neighbor
	//uint16_t range;		 // 2 bytes: Approximate communication range of the neighbor
	} ClusterMember;			// 4 bytes

	/**
	 * Information about an agent in the cluster.
	 */
	typedef struct AgentInfo{
	AgillaAgentID id;		 // 2 bytes: id of agent
	uint16_t type;			// 2 bytes: type of agent
	AgillaLocation loc;	 // 4 bytes: location of host that detected the agent
	//tos_time_t timestamp;	 // 2 bytes: time at which agent was detected
	bool rcvdUpdate;	// 2 bytes: whether an update was received from the agent
	} AgentInfo;				// 10 bytes

	/**************************************************************/
	/*					Variable declarations					 */
	/**************************************************************/


	/**
	 * An array of cluster member information
	 * cl_members[0] through cl_members[numMembers] have valid data.
	 */
	struct ClusterMember cl_members[AGILLA_MAX_NUM_NEIGHBORS];
	uint8_t numMembers;

	/*
	 * An array of agent information
	 * agents[0] through agents[numAgents] have valid data
	 */
	struct AgentInfo agents[AGILLA_MAX_NUM_AGENTS];
	uint8_t numAgents;

	bool running;
	//bool sentClusterMsg;
	AgillaRectangle bounding_box;

	/**************************************************************/
	/*					Method declarations					 */
	/**************************************************************/

	inline result_t sendClusterMsg(TOS_MsgPtr msg);
	inline void doSend();
	void updateBoundingBox(uint16_t nbr/*, uint16_t range*/);
	void recomputeBoundingBox();
	void getBoundingBox(uint16_t id, /*uint16_t range,*/ AgillaRectangle* tempbb);
	//void modifyBoundingBox(AgillaRectangle* tempbb);

	#if DEBUG_CLUSTERING
	void printClusterMemberList()
	{
		uint8_t i;
		dbg(DBG_USR1, "--- Cluster Member list ---\n");
		for (i = 0; i < numMembers; i++) {
		//dbg(DBG_USR1, "\t%i:\tID = %i\trange = %i\n", i, cl_members[i].addr, cl_members[i].range);
		dbg(DBG_USR1, "\t%i:\tID = %i\n", i, cl_members[i].addr);
		}
	}

	void printAgentList()
	{
		uint8_t i;
		dbg(DBG_USR1, "--- Agent list ---\n");
		for (i = 0; i < numAgents; i++) {
		dbg(DBG_USR1, "\t%i:\tID = %i\ttype = %i\tloc = [%i,%i]\trcvdUpdate=%i\n",
			i, agents[i].id.id, agents[i].type, agents[i].loc.x, agents[i].loc.y, agents[i].rcvdUpdate);
		}
	}
	#endif

	/**************************************************************/
	/*					 StdControl							 */
	/**************************************************************/

	command result_t StdControl.init() 
	{
	running = FALSE;
	//sentClusterMsg = FALSE;
	numMembers = 0;
	numAgents = 0;
	bounding_box.llc.x = 0;
	bounding_box.llc.y = 0;
	bounding_box.urc.x = 0;
	bounding_box.urc.y = 0;
	atomic {
		call Random.init();
	};
	call Leds.init();
	return SUCCESS;
	}
	
	command result_t StdControl.start() 
	{
	if (!running)
	{
		running = TRUE;
		
		// update bounding box with own bounding box
		getBoundingBox(TOS_LOCAL_ADDRESS, /*call ClusteringI.getCommRange(),*/ &bounding_box);

		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "Clusterhead Directory started; bounding box = [(%i,%i),(%i,%i)]\n",
					bounding_box.llc.x, bounding_box.llc.y, bounding_box.urc.x, bounding_box.urc.y);
		#endif
		
		// Start the timer that periodically sends an AgillaClusterMsg
		// to the base station updating it of the cluster's status.
		call ClusterTimer.start(TIMER_ONE_SHOT, 
		CLUSTER_UPDATE_INTERVAL+(call Random.rand()%CLUSTERMSG_RAND));
		
		// Start the timer that finds and removes agent entries.
		// Agent locations should be updated every AGILLA_LOCATION_UPDATE_TIMER
		// milliseconds.
		call AgentExpTimer.start(TIMER_REPEAT,
		AGILLA_LOCATION_UPDATE_TIMER+768);
		
		// Send an AgillaClusterMsg to the base station telling it that 
		// this node is a cluster head.
		doSend(); 
		//sentClusterMsg = TRUE;
		
		#if ENABLE_EXP_LOGGING
		if (TRUE) {
			AgillaLocation loc;
			loc.x = loc.y = 0;
			call ExpLoggerI.sendTraceQid(0, TOS_LOCAL_ADDRESS, CLUSTERHEAD_DIRECTORY_STARTED, 
			(uint16_t)running, 0, loc);
		}
		#endif
	}
	return SUCCESS;
	}

	command result_t StdControl.stop()
	{
	if (running)
	{
		running = FALSE;
		
		// Stop the timer
		call ClusterTimer.stop();
		
		// Reset all of the local variables
		numMembers = 0;
		numAgents = 0;
		bounding_box.llc.x = 0;
		bounding_box.llc.y = 0;
		bounding_box.urc.x = 0;
		bounding_box.urc.y = 0;
		
		
		//if(sentClusterMsg) 
		
		// Send a cluster message letting the base station know 
		// this node is no longer a cluster head.
		doSend(); 
		//sentClusterMsg = FALSE;

		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "Clusterhead Directory stopped\n");
		#endif

		#if ENABLE_EXP_LOGGING
		if (TRUE) 
		{		
			AgillaLocation loc;
			loc.x = loc.y = 0;
			call ExpLoggerI.sendTraceQid(0, TOS_LOCAL_ADDRESS, 
			CLUSTERHEAD_DIRECTORY_STOPPED, (uint16_t)running, 0, loc);
		}
		#endif
	}
	return SUCCESS;
	}



	/**************************************************************/
	/*						 TIMERS								 */
	/**************************************************************/

	/**
	 * Send a cluster message.
	 */	 
	event result_t ClusterTimer.fired()
	{
	#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryM: ClusterTimer fired!\n");
	#endif
	doSend();
	//sentClusterMsg = TRUE;
	return call ClusterTimer.start(TIMER_ONE_SHOT, 
		CLUSTER_UPDATE_INTERVAL+(call Random.rand()%CLUSTERMSG_RAND));	
	}

	/**
	 * Go through each of the agents in the directory and remove
	 * those that are expired.
	 */
	event result_t AgentExpTimer.fired()
	{
	int16_t i = 0, j = 0;
	for(i = 0; i < numAgents; i++)
	{
		if (agents[i].rcvdUpdate) 
		{
		agents[i].rcvdUpdate = FALSE;
		agents[j++] = agents[i];
		} else
		{
		#if ENABLE_EXP_LOGGING
			if (TRUE) {
				AgillaLocation loc;
				loc.x = loc.y = 0;		
				call ExpLoggerI.sendTrace(agents[i].id.id, TOS_LOCAL_ADDRESS, CLUSTER_AGENT_CLEARED, numAgents, loc);
			}
		#endif		
		}
	}
	numAgents = j;


	return SUCCESS;
	}

	/**************************************************************/
	/*				Message Handlers							*/
	/**************************************************************/

	/**
	 * Sends an AgillaClusterMsg containing this node's TinyOS address
	 * and its bounding box.
	 */
	void doSend()
	{
		TOS_MsgPtr msgptr = call MessageBufferI.getMsg();
		if (msgptr != NULL )
		{
		AgillaClusterMsg* cmsg = (AgillaClusterMsg *)msgptr->data;

		cmsg->id = TOS_LOCAL_ADDRESS;
		cmsg->bounding_box = bounding_box;

		#if DEBUG_CLUSTERING
			dbg(DBG_USR1, "ClusterheadDirectoryM: Sending cluster msg id=%i, bounding_box[(%i,%i),(%i,%i)]\n",
									cmsg->id, cmsg->bounding_box.llc.x, cmsg->bounding_box.llc.y,
									cmsg->bounding_box.urc.x, cmsg->bounding_box.urc.y);
		#endif

		if (!sendClusterMsg(msgptr))
		{
			dbg(DBG_USR1, "ClusterheadDirectoryM: ERROR: Unable to send cluster msg.\n");
			call MessageBufferI.freeMsg(msgptr);
		}
		}
	}

	/**
	 * Figures out what the next hop should be towards the base station and
	 * sends the message to that node.	If this node is the gateway, the message
	 * is forwarded to the UART.
	 */
	result_t sendClusterMsg(TOS_MsgPtr msg)
	{
		if (call AddressMgrI.isGW())
		{
		#if DEBUG_CLUSTERING
			AgillaClusterMsg* cmsg = (AgillaClusterMsg *)msg->data;
			dbg(DBG_USR1, "ClusterheadDirectoryM: sendMsg(): Sent cluster msg from %i to BS\n", cmsg->id);
		#endif
		return call SendClusterMsg.send(TOS_UART_ADDR, sizeof(AgillaClusterMsg), msg);
		} 
		else 
		{
		uint16_t onehop_dest;

		// Get the one-hop neighbor that is closest to the gateway.
		// If there is no known gateway, abort.
		if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
		{
			dbg(DBG_USR1, "ClusterheadDirectoryM: sendClusterMsg(): ERROR: No nbr closer to gateway.\n");
			return FAIL;
		}

		return call SendClusterMsg.send(onehop_dest, sizeof(AgillaClusterMsg), msg);
		}
	} // sendClusterMsg()

	event result_t SendClusterMsg.sendDone(TOS_MsgPtr m, result_t success)
	{
		call MessageBufferI.freeMsg(m);
		return SUCCESS;
	}

	/**
	 * Bounces the cluster message off this mote.
	 */
	event TOS_MsgPtr RcvClusterMsg.receive(TOS_MsgPtr m)
	{
		// Should I put in a neighbor filter here?
		TOS_MsgPtr msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
			*msg = *m;
			if (!sendClusterMsg(msg)) call MessageBufferI.freeMsg(msg);
		}
		return m;
	}

	/**************************************************************/
	/*			ClusterheadDirectory Interface methods			*/
	/**************************************************************/


	command result_t ClusterheadDirectoryI.addClusterMember(uint16_t nbr/*, uint16_t range*/)
	{
	int16_t i = 0, indx = -1;

	// Find the index of the cluster member
	while (i < numMembers && indx == -1) {
		if (cl_members[i].addr == nbr)
			indx = i;
		i++;
	}
	
	// If the cluster member is not in the list, add it and send a cluster
	// message to the base station
	if (indx == -1) 
	{
		if(numMembers >= AGILLA_MAX_NUM_NEIGHBORS) return FAIL;
		indx = numMembers++;
		cl_members[indx].addr = nbr;
		//cl_members[indx].range = range;
		updateBoundingBox(nbr/*, range*/);
		//if(sentClusterMsg) 
		
		doSend();
		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryI: added new cluster member!\n");
		printClusterMemberList();
		//if(sentClusterMsg) 
		call ClusteringI.sendClusterDebugMsg();
		#endif
	}
	/*else {
		cl_members[indx].range = range;
	}*/
	
	#if DEBUG_CLUSTERING
		if(!running) dbg(DBG_USR1, "ERROR! Trying to add cluster member when not running!\n");
	#endif
	
	return SUCCESS;
	}

	command result_t ClusterheadDirectoryI.removeClusterMember(uint16_t nbr){
	int8_t i = 0, indx = -1;

	// Find the index of the cluster member
	while (i < numMembers && indx == -1) {
		if (cl_members[i].addr == nbr)
			indx = i;
		i++;
	}
	if (indx != -1) {
		// remove the cluster member by shifting all following members forward
		for (i = indx; i < numMembers-1; i++) {
			cl_members[i] = cl_members[i+1];
		}
		numMembers--;
		recomputeBoundingBox();
		//if(sentClusterMsg) 
		doSend();
		#if DEBUG_CLUSTERING
			if(!running) dbg(DBG_USR1, "ERROR! Trying to remove cluster member when not running!\n");
			dbg(DBG_USR1, "ClusterheadDirectoryM: removed cluster member %i\n", nbr);
			//if(sentClusterMsg) 
			call ClusteringI.sendClusterDebugMsg();
		#endif
		return SUCCESS;
	} else {
		dbg(DBG_USR1, "ClusterheadDirectoryM: Could not delete cluster member %i\n", nbr);
		return FAIL;
	}
	}

	command result_t ClusterheadDirectoryI.isClusterMember(uint16_t id){
		int8_t i = 0;
		while (i < numMembers) {
			if (cl_members[i].addr == id)
				return SUCCESS;
			i++;
		}
		return FAIL;
	}

	command uint16_t ClusterheadDirectoryI.numClusterMembers(){
		return numMembers;
	}

	/**
	 * Removes expired agents.
	 */
	/*void clearAgents()
	{
		 int16_t i = 0, j = 0;
		 tos_time_t now = call Time.get();
		 for(i = 0; i < numAgents; i++) 
		 {
			if ((call TimeUtil.subtract(now, agents[i].timestamp)).low32 <= AGILLA_LOCATION_UPDATE_TIMER)
			{
				//if ((now.low32 - agents[i].timestamp.low32) <= 2*AGILLA_LOCATION_UPDATE_TIMER){
				agents[j] = agents[i];
				j++;
			}
		}
		numAgents = j;
		
		#if ENABLE_EXP_LOGGING
		if (TRUE) 
		{
			AgillaLocation loc;
			loc.x = loc.y = 0;		
			call ExpLoggerI.sendTrace(j-1, TOS_LOCAL_ADDRESS, CLUSTER_AGENT_CLEARED, numAgents, loc);
		}
		#endif
	}*/

	/**
	 * This is periodically called by the LocationReporter.	The AgentInjector periodically
	 * tells the LocationReporter to update the Clusterhead of the agent's presence.
	 */
	command result_t ClusterheadDirectoryI.addAgent(uint16_t aid, uint16_t atype,
	AgillaLocation* aloc, /*tos_time_t* timestamp,*/ uint16_t* known)
	{
	int16_t i = 0, indx = -1;

	//clearAgents();	// remove expired agents
	 
	#if DEBUG_CLUSTERING
		if(!running) dbg(DBG_USR1, "ERROR! Trying to add agent when not running!\n");
	#endif
	
	// see if the agent being added is already in the list
	while (i < numAgents && indx == -1) {
		if (agents[i].id.id == aid) 
		indx = i;
		i++;
	}

	*known = indx + 1;
	
	// If the agent is not in the directory, add it
	if (indx == -1) 
	{
		if(numAgents >= AGILLA_MAX_NUM_AGENTS) { return FAIL;}
		indx = numAgents++;

		agents[indx].id.id = aid;
		agents[indx].type = atype;
		agents[indx].rcvdUpdate = TRUE;
		
		#if ENABLE_EXP_LOGGING
		call ExpLoggerI.sendTrace(aid, TOS_LOCAL_ADDRESS, CLUSTER_AGENT_ADDED, indx, *aloc);
		#endif
		
		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryM: added agent %i\n", aid);
		printAgentList();
		#endif		
	} 
	
	// The agent is already in the directory, update it
	else {			
		
		// If the agent has changed type, update its type and set
		// known to be FALSE.
		if(agents[i].type != atype)
		{
		*known = FALSE;
		agents[indx].type = atype;
		}
		
		//if((call TimeUtil.subtract(*timestamp, agents[indx].timestamp)).low32 >= 0)
		//{			
		//agents[indx].loc = *aloc;
		//agents[indx].timestamp = *timestamp;
		//}		

		agents[indx].loc = *aloc;
		//agents[indx].timestamp = *timestamp;
		agents[indx].rcvdUpdate = TRUE;
			
		//call Leds.yellowToggle(); // used for debugging

		#if ENABLE_EXP_LOGGING
		call ExpLoggerI.sendTrace(aid, TOS_LOCAL_ADDRESS, CLUSTER_AGENT_UPDATED, indx, *aloc);
		#endif
		
		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryM: updated agent %i\n", aid);
		printAgentList();
		#endif

	}
	return SUCCESS;
	}

	command result_t ClusterheadDirectoryI.removeAgent(AgillaAgentID* aid)
	{
	int16_t i = 0, indx = -1;

	//clearAgents();
	
	// Find the index of the agent
	while (i < numAgents && indx == -1) 
	{
		if (agents[i].id.id == aid->id)
			indx = i;
		i++;
	}

	if (indx != -1) {
		// remove the agent by shifting all following agents forward
		for (i = indx; i < numAgents-1; i++) {
			agents[i] = agents[i+1];
		}
		numAgents--;

		#if DEBUG_CLUSTERING
			if(!running) dbg(DBG_USR1, "ERROR! Trying to remove agent when not running!\n");
			dbg(DBG_USR1, "ClusterheadDirectoryM: removed agent %i\n", aid->id);
			printAgentList();
		#endif

		#if ENABLE_EXP_LOGGING
			if (TRUE) {
			AgillaLocation loc;
			loc.x = loc.y = 0;
			call ExpLoggerI.sendTrace(aid->id, TOS_LOCAL_ADDRESS, CLUSTER_AGENT_REMOVED, indx, loc);
			}
		#endif

		return SUCCESS;
	} else {
		dbg(DBG_USR1, "ClusterheadDirectoryM: Could not delete agent %i\n", aid->id);
		return FAIL;
	}
	}

	/**
	 * This resets the agents within the cluster, but does not reset the cluster
	 * information.
	 */
	command result_t ClusterheadDirectoryI.reset()
	{
	numAgents = 0;
	if(running) doSend();	// send update to base station	
	if(call ClusteringI.isClusterHead()) call Leds.greenOn();
	return SUCCESS;
	}

	command result_t ClusterheadDirectoryI.getAgent(AgillaAgentID* aid, AgillaLocation* aLoc)
	{
	int8_t i = 0;
	//clearAgents();
	// Find the agent
	for(i=0; i < numAgents; i++) {
		if (agents[i].id.id == aid->id){
			*aLoc = agents[i].loc;
			return SUCCESS;
		 }
	}
	return FAIL;
	}

	command result_t ClusterheadDirectoryI.getNearestAgent(AgillaAgentID* aid, AgillaLocation* aLoc, uint16_t* aType,
			AgillaAgentID* nearestAgentId, AgillaLocation* nearestAgentLoc)
	{
	int8_t i = 0, indx = -1;
	uint16_t dist = 0xffff, min_dist=0xffff;

	#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryI.getNearestAgent: finding nearest agent to loc [%i,%i]\n", aLoc->x, aLoc->y);
	#endif
	//clearAgents();
	// Find the agent
	for(i=0; i < numAgents; i++) {
		if (agents[i].id.id != aid->id && agents[i].type == *aType){
			dist = call LocationUtilI.dist(aLoc, &(agents[i].loc));
			#if DEBUG_CLUSTERING
				dbg(DBG_USR1, "%i[%i,%i] dist = %i\n", agents[i].id.id, agents[i].loc.x, agents[i].loc.y, dist);
			#endif
			if(dist < min_dist){
				min_dist = dist;
				indx = i;
			}
		 }
	}
	if(indx == -1) {
		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryI.getNearestAgent: did not find any agent!\n");
		#endif
		return FAIL;
	} else {

		*nearestAgentId = agents[indx].id;
		*nearestAgentLoc = agents[indx].loc;

		#if DEBUG_CLUSTERING
			dbg(DBG_USR1, "ClusterheadDirectoryI.getNearestAgent: Found closest agent %i[%i,%i] dist = %i\n",
				nearestAgentId->id, nearestAgentLoc->x, nearestAgentLoc->y, min_dist);
		#endif

		return SUCCESS;
	}
	}

	command result_t ClusterheadDirectoryI.getAllAgents(AgillaLocMAgentInfo* agentList, 
	uint8_t* num_agents, uint16_t* aType)
	{
		int8_t i = 0, indx = 0;
		if(agentList == NULL) return FAIL;
		
		//clearAgents();	// remove expired agents
		
		// need to check for array overflow!!
		#if DEBUG_CLUSTERING
		printAgentList();
		#endif
		
		for(i=0; i < numAgents; i++) {
			if(*aType == UNSPECIFIED || agents[i].type == *aType){
			
			// The following check ensures that an array overflow does
			// not occur. Added by Chien-Liang Fok.
			if (indx < MAX_AGENT_ARRAY_NUM)
			{
				agentList[indx].agent_id.id = agents[i].id.id;
				agentList[indx].loc.x = agents[i].loc.x;
				agentList[indx++].loc.y = agents[i].loc.y;
			}
			}
		}
		if(indx == 0) {
			#if DEBUG_CLUSTERING
			dbg(DBG_USR1, "ClusterheadDirectoryI.getAllAgents: did not find any agent!\n");
			#endif
			return FAIL;
		} else {
			*num_agents = indx;
			#if DEBUG_CLUSTERING
			dbg(DBG_USR1, "ClusterheadDirectoryI.getAllAgents: found %i agents!\n", *num_agents);
			for(i = 0; i < indx; i++){
				dbg(DBG_USR1, "\tAgent %i[%i,%i]\n",
					agentList[i].agent_id.id, agentList[i].loc.x, agentList[i].loc.y);
			}
			#endif
			return SUCCESS;
		}
	}


	#if DEBUG_CLUSTERING
	command result_t ClusterheadDirectoryI.getBoundingBox(AgillaRectangle* boundingBox){
		*boundingBox = bounding_box;
		return SUCCESS;
	}
	#endif


	/**************************************************************/
	/*						Helper methods						*/
	/**************************************************************/

	/**
	 * Update bounding box based on bounding box of new cluster member
	 */
	void updateBoundingBox(uint16_t nbr/*, uint16_t range*/)
	{
		//AgillaRectangle tempbb;
		
		AgillaLocation loc;
		call LocationMgrI.getLocation(nbr, &loc);
		
		//getBoundingBox(nbr, range, &tempbb);
		//modifyBoundingBox(&tempbb);
		if(loc.x < bounding_box.llc.x) bounding_box.llc.x = loc.x;
		if(loc.y < bounding_box.llc.y) bounding_box.llc.y = loc.y;
		if(loc.x > bounding_box.urc.x) bounding_box.urc.x = loc.x;
		if(loc.y > bounding_box.urc.y) bounding_box.urc.y = loc.y;

		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryM: new bounding box: [(%i,%i),(%i,%i)]\n", 
			bounding_box.llc.x, bounding_box.llc.y, bounding_box.urc.x, bounding_box.urc.y);
		#endif
	}

	/**
	 * Recompute bounding box
	 */
	void recomputeBoundingBox()
	{
	uint8_t i = 0;
	//AgillaRectangle tempbb;

	// initialize the bounding box to be itself
	getBoundingBox(TOS_LOCAL_ADDRESS, /*call ClusteringI.getCommRange(),*/ &bounding_box);
	
	for (i = 0; i < numMembers; i++) {
		updateBoundingBox(cl_members[i].addr);
	}

	#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryM: recomputed bounding box: [(%i,%i),(%i,%i)]\n",
		 bounding_box.llc.x, bounding_box.llc.y, bounding_box.urc.x, bounding_box.urc.y);
	#endif
	}


	/**
	 * Gets the bounding box of a particular node.	The node is specified by
	 * its TinyOS address.	The bounding box is its location (the box has a single
	 * node).
	 *
	 * @param id The node's TinyOS address.
	 * @param tempbb A pointer to the bounding box in which to save the results.	 
	 */
	void getBoundingBox(uint16_t id, /*uint16_t range,*/ AgillaRectangle* tempbb){
		AgillaLocation loc;
		call LocationMgrI.getLocation(id, &loc);

		#if DEBUG_CLUSTERING
		 //dbg(DBG_USR1, "ClusterheadDirectoryM.getBoundingBox(): id=%i, loc=[%i,%i], range=%i\n",
		 // id, loc.x, loc.y, range);
			dbg(DBG_USR1, "ClusterheadDirectoryM.getBoundingBox(): id=%i, loc=[%i,%i]\n",
									id, loc.x, loc.y);
		#endif

		/*
		if(loc.x <= range) tempbb->llc.x = 0; else tempbb->llc.x = loc.x - range;
		if(loc.y <= range) tempbb->llc.y = 0; else tempbb->llc.y = loc.y - range;
		tempbb->urc.x = loc.x + range;
		tempbb->urc.y = loc.y + range;
		*/

		tempbb->llc.x = loc.x;
		tempbb->llc.y = loc.y;
		tempbb->urc.x = loc.x;
		tempbb->urc.y = loc.y;

		#if DEBUG_CLUSTERING
			dbg(DBG_USR1, "ClusterheadDirectoryM.getBoundingBox(): tempbb[(%i,%i)(%i,%i)]\n",
							tempbb->llc.x, tempbb->llc.y, tempbb->urc.x, tempbb->urc.y);
		#endif
	}

/*
	void modifyBoundingBox(AgillaRectangle* tempbb){
		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryM.modifyBoundingBox(): tempbb[(%i,%i)(%i,%i)]\n",
						 tempbb->llc.x, tempbb->llc.y, tempbb->urc.x, tempbb->urc.y);
		dbg(DBG_USR1, "ClusterheadDirectoryM.modifyBoundingBox(): before modification bounding_box[(%i,%i)(%i,%i)]\n",
						 bounding_box.llc.x, bounding_box.llc.y, bounding_box.urc.x, bounding_box.urc.y);
		#endif
		if(tempbb->llc.x < bounding_box.llc.x) bounding_box.llc.x = tempbb->llc.x;
		if(tempbb->llc.y < bounding_box.llc.y) bounding_box.llc.y = tempbb->llc.y;
		if(tempbb->urc.x > bounding_box.urc.x) bounding_box.urc.x = tempbb->urc.x;
		if(tempbb->urc.y > bounding_box.urc.y) bounding_box.urc.y = tempbb->urc.y;
		#if DEBUG_CLUSTERING
		dbg(DBG_USR1, "ClusterheadDirectoryM.modifyBoundingBox(): after modification bounding_box[(%i,%i)(%i,%i)]\n",
						 bounding_box.llc.x, bounding_box.llc.y, bounding_box.urc.x, bounding_box.urc.y);
		#endif
	}
*/
}
