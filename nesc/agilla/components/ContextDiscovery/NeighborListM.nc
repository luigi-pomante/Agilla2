// $Id: NeighborListM.nc,v 1.25 2006/04/26 23:09:31 chien-liang Exp $

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
#include "Timer.h"

/**
 * Discovers neighbors using beacons.	Maintains a list of nodes that have
 * recently been heard from.
 *
 * @author Chien-Liang Fok
 * @author Sangeeta Bhattacharya
 */
module NeighborListM {
	provides {
	interface StdControl;
	interface NeighborListI;
	interface Init;
	
	#if ENABLE_CLUSTERING
		interface ClusteringI;
	#endif
	}
	uses {
	interface Random; // Used for getting a random neighbor

	interface Time;
	interface TimeUtil;

	interface AddressMgrI;

	interface Timer<TMilli> as BeaconTimer;
	interface Timer<TMilli> as DisconnectTimer;

	interface AMSend as SendBeacon;
	interface Receive as RcvBeacon;
	interface Receive as SerialRcvBeacon;

	#if DEBUG_CLUSTERING
		// debug msg sent over the UART
		interface SendMsg as SendClusterDebugMsg;
		interface ReceiveMsg as RcvClusterDebugMsg;
	#endif

	// get neighbor list query
	interface Receive as RcvGetNbrList;
	interface AMSend as SendGetNbrList;
	interface Receive as SerialRcvGetNbrList;

	// Response to get neighbor list query
	interface AMSend as SendNbrList;
	interface Receive as RcvNbrList;
	interface AMSend as SerialSendNbrList;
	interface Receive as SerialRcvNbrList;

	// Grid topology
	interface LocationMgrI;
	interface LocationUtilI;

	interface MessageBufferI;

	interface Leds; // debug

	interface Packet;
	interface Boot;

	#if ENABLE_CLUSTERING
		interface ClusterheadDirectoryI as CHDir;
		interface StdControl as CHDirControl;
	#endif

	#if ENABLE_EXP_LOGGING
		interface ExpLoggerI;
	#endif
	}
}
implementation {

	#define NO_CLUSTERHEAD -1

	typedef struct Neighbor 
	{
	uint16_t addr;			// The address of the neighbor
	uint16_t hopsToGW;		// The number of hops to the gateway
	tos_time_t timeStamp;	 // The last time a beacon was received

	//#if ENABLE_CLUSTERING
	int16_t chId;			 // The id of the cluster head of the cluster
								// to which the neighbor belongs; if the neighbor
								// is a cluster head, then chId = id;
	uint16_t linkQuality;	 // The quality of the link to the neighbor
	uint16_t energy;		// The residual energy of the neighbor
	//uint16_t range;		 // The communication range of the neighbor
	//#endif
	} Neighbor;

	/**
	 * A message buffer for holding my beacon.
	 */
	//TOS_Msg myBeacon;

	/**
	 * A message buffer for holding incomming beacons.
	 */
	//TOS_Msg beacon;
	//TOS_MsgPtr beaconPtr;

	/**
	 * An array of neighbor locations and timestamps.
	 * nbrs[0] through nbrs[numNbrs] have valid neighbor data.
	 */
	Neighbor nbrs[AGILLA_MAX_NUM_NEIGHBORS];
	uint8_t numNbrs;
	uint16_t replyAddr; // used for retrieving the neighbor list

	int16_t _chId;			// id of the cluster head of the cluster to which this node belongs

	#if ENABLE_CLUSTERING	
	tos_time_t initTime;		// initialization time
	tos_time_t chSelectTime;	// time when this node selected a clusterhead
	void setCH(uint16_t ch_id);
	void determineCluster(TOS_MsgPtr m);
	#endif


	/**
	 * Generate a random interval between sending beacons.
	 * This value will be between BEACON_PERIOD and
	 * BEACON_PERIOD + BEACON_RAND.
	 */
	inline uint16_t genRand() 
	{
	return (call Random.rand32() % BEACON_RAND) + BEACON_PERIOD;;
	}

	/**
	 * A message buffer for holding neighbor list info.
	 * This is used for debugging purposes.	It allows the
	 * user to query a mote's neighbor list.
	 */
	//TOS_Msg nbrMsg;
	uint8_t sendCount, nextSendCount; // for sending neighbor info to base station
	
	/**************************************************************/
	/*					Method declarations					 */
	/**************************************************************/
	
	task void SendNbrListTask();

	/**************************************************************/
	/*						Helper methods						*/
	/**************************************************************/
	
	/**
	 * Returns the number of hops to the gateway.	If no gateway is
	 * known, return NO_GW (0xffff).
	 */
	/*uint16_t getHopsToGW(uint16_t* addr) 
	{
	if (call AddressMgrI.isGW())	
	{
		*addr == TOS_NODE_ID;
		return 0;
	} else
	{
		uint16_t numHops;	
		numHops = call NeighborListI.getGW(*addr);
		if (*addr != NO_GW)
		{
		numHops++;
		return numHops;		
		} else
		return NO_GW;
	}
	}*/
	
	/**
	 * Returns true if the node with the specified id is a grid neighbor.
	 */
	error_t isGridNbr(uint16_t id) {
	AgillaLocation nbrLoc, myLoc;
	call LocationMgrI.getLocation(TOS_NODE_ID, &myLoc);
	call LocationMgrI.getLocation(id, &nbrLoc);
	//dbg(DBG_USR1, "NeighborListM: isGridNbr(): myLoc = (%i, %i)\n", myLoc.x, myLoc.y);
	//dbg(DBG_USR1, "NeighborListM: isGridNbr(): nbrLoc = (%i, %i)\n", nbrLoc.x, nbrLoc.y);
	return call LocationUtilI.isGridNbr(&myLoc, &nbrLoc);
	}	
	
	#if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST || DEBUG_CLUSTERING
	void printNbrList()
	{
		uint8_t i;
		dbg("DBG_USR1", "--- Neighbor list ---\n");
		for (i = 0; i < numNbrs; i++) {
		#if ENABLE_CLUSTERING
			dbg("DBG_USR1", "\t%i: ID=%i\tchId=%i\thopsToGW=%i\tlqi=%i\ttimestamp=%i\n", i,
						nbrs[i].addr, nbrs[i].chId, nbrs[i].hopsToGW, 
						nbrs[i].linkQuality, nbrs[i].timeStamp.low32);
		#else
			dbg("DBG_USR1", "\t%i:\tID=%i\thopsToGW=%i\n", i, nbrs[i].addr, nbrs[i].hopsToGW);
		#endif
		//dbg(DBG_USR1,"\n");
		}
	}
	#endif

	/**************************************************************/
	/*					 StdControl							 */
	/**************************************************************/
	
	command error_t Init.init() {
	numNbrs = 0;
	nextSendCount = 0;
	_chId = NO_CLUSTERHEAD;
	
	#if ENABLE_CLUSTERING	 
		initTime = call Time.get();
		call CHDirControl.init();
	#endif

	 /* atomic {
		call Random.init();
	}; */
	dbg("DBG_USR1", "NTIMERS = %i\n", NTIMERS);
	dbg("DBG_USR1", "uniqueCount(\"Timer\") = %i\n", uniqueCount("Timer"));

	return SUCCESS;
	}

	event void Boot.booted(){
	call BeaconTimer.startOneShot(genRand());
	call DisconnectTimer.startPeriodic(BEACON_TIMEOUT);
	}
	command error_t StdControl.start() {
	
	return SUCCESS;
	}

	command error_t StdControl.stop()	{
	return SUCCESS;
	}
	


	/**
	 * Send a beacon. Then generate a random time to sleep before sending the next
	 * beacon.
	 */
	event void BeaconTimer.fired()
	{
	message_t* myBeacon = call MessageBufferI.getMsg();	
	if (myBeacon != NULL)
	{
		AgillaBeaconMsg* bmsg = (AgillaBeaconMsg *)(call Packet.getPayload(myBeacon, sizeof(AgillaBeaconMsg)));
		uint16_t nbrToGW;
		
		bmsg->id = TOS_NODE_ID;

		// Determine the number of hops to the base station
		/*if (call AddressMgrI.isGW())
		bmsg->hopsToGW = 0;
		else
		{
		uint16_t addr;
		bmsg->hopsToGW = call NeighborListI.getGW(&addr);
		if (bmsg->hopsToGW != NO_GW)
		{
			bmsg->hopsToGW++;	// add one hop to get to the neighbor
		}
		}*/
		bmsg->hopsToGW = call NeighborListI.getGW(&nbrToGW);
		if (bmsg->hopsToGW != NO_GW && call AddressMgrI.isGW() != SUCCESS) bmsg->hopsToGW++;	 // increment hop count to include hop to this node
		bmsg->chId = _chId;
		bmsg->energy = 0;		

		#if ENABLE_CLUSTERING
		if (call AddressMgrI.isGW() == SUCCESS && _chId == NO_CLUSTERHEAD)		
			setCH(TOS_NODE_ID);		
		//bmsg->range = call ClusteringI.getCommRange();
		#endif

		#if DEBUG_NEIGHBORLIST
		dbg("DBG_USR1", "NeighborListM: Send Beacon ID=%i, hopsToGW=%i, chID=%i, energy=%i\n", 
			bmsg->id, bmsg->hopsToGW, bmsg->chId, bmsg->energy);
		#endif

		#if DEBUG_CLUSTERING
		//dbg(DBG_USR1, "NeighborListM: Send Beacon chId=%i, energy=%i, range=%i\n", bmsg->chId, bmsg->energy, bmsg->range);
		#endif

		if (call SendBeacon.send(AM_BROADCAST_ADDR, myBeacon, sizeof(AgillaBeaconMsg)) != SUCCESS)
		{
		dbg("DBG_USR1", "NeighborListM: ERROR: Unable to send beacon.\n");
		call MessageBufferI.freeMsg(myBeacon);
		}
	}

	call BeaconTimer.startOneShot(genRand());
	}

	event void SendBeacon.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}

	/**
	 * Check for neighbors whom we have not heard beacons from recently
	 * and remove them from the neighbor list.
	 */
	event void DisconnectTimer.fired() {
	int16_t i,j;
	tos_time_t currTime = call Time.get();

// #if DEBUG_NEIGHBORLIST
// dbg("DBG_USR1", "NeighborListM: DisconnectTimer.fired(): The current time is %i %i\n",
// currTime.high32, currTime.low32);
// #endif

	atomic {
		for (i = 0; i < numNbrs; i++) {
		tos_time_t delta = call TimeUtil.subtract(currTime, nbrs[i].timeStamp);
		tos_time_t maxAge;

// dbg("DBG_USR1", "NeighborListM: Checking neighbor %i, timestamp = %i %i\n",
// nbrs[i].addr, nbrs[i].timeStamp.low32, nbrs[i].timeStamp.high32);

		maxAge.high32 = 0;
		maxAge.low32 = BEACON_TIMEOUT;

// #if DEBUG_NEIGHBORLIST
// dbg(DBG_USR1, "NeighborListM: DisconnectTimer.fired(): neighor %i, curr = %i %i, timestamp = %i %i, delta = %i %i, maxAge = %i %i\n",
// nbrs[i].addr, currTime.high32, currTime.low32, nbrs[i].timeStamp.high32, nbrs[i].timeStamp.low32,
// delta.high32, delta.low32, maxAge.high32, maxAge.low32);
// #endif

		if (call TimeUtil.compare(delta, maxAge) > 0)
		{
			#if DEBUG_NEIGHBORLIST
			dbg("DBG_USR1", "NeighborListM: DisconnectTimer.fired(): ----- Neighbor %i has left!\n",
				nbrs[i].addr);
			#endif
			#if NBR_LIST_PRINT_CHANGES
			dbg("DBG_USR1", "NeighborListM: Neighbor %i has left!\n", nbrs[i].addr);
			printNbrList();
			#endif

			#if ENABLE_CLUSTERING
			// if this node is a clusterhead and the neighbor belongs to
			// this nodes cluster, remove the neighbor from the cluster member list
			if(_chId == TOS_NODE_ID && nbrs[i].chId == TOS_NODE_ID)
				call CHDir.removeClusterMember(nbrs[i].addr);			
			#endif

			for (j = i; j < numNbrs-1; j++) {	// remove the neighbor by shifting all of the following neighbors forward
			nbrs[j] = nbrs[j+1];
			}
			numNbrs--;
			i--;
		}
		}
	}

	}	// DisconnectTimer.fired()



	/**
	 * Whenever a beacon is recieved, timestamp and store it in the
	 * neighbor list (or update the timestamp if it is already in the
	 * list.
	 */
	event message_t* RcvBeacon.receive(message_t* m, void* payload, uint8_t len) {
		AgillaBeaconMsg* bmsg = (AgillaBeaconMsg *)payload;
		int16_t i = 0, indx = -1; // the index of the location
		tos_time_t now = call Time.get();

	#if DEBUG_NEIGHBORLIST
		dbg("DBG_USR1", "NeighborListM: processBeacon(): ID = %i, hopsToGW = %i\n", bmsg->id, bmsg->hopsToGW);
	#endif

	#if ENABLE_NEIGHBOR_LIST_FILTER
		// Reject beacons if it comes from a node that is not a grid neighbor.
		if (isGridNbr(bmsg->id) != SUCCESS)
		{
		#if DEBUG_NEIGHBORLIST
			dbg("DBG_USR1", "NeighborListM: processBeacon(): Not from grid neighbor, discarding...\n");
		#endif
		return m;
		}
	#endif

	// Check whether the neighbor is already in the list.	If so,
	// set indx equal to its position in the list, otherwise, set
	// indx = -1.
		while (i < numNbrs && indx == -1) {
			if (nbrs[i].addr == bmsg->id)
			indx = i;
			i++;
		}

	// If the beacon is NOT in the neighbor list, insert it.
	if (indx == -1 && numNbrs < AGILLA_MAX_NUM_NEIGHBORS)
	{
		indx = numNbrs++;
		nbrs[indx].addr = bmsg->id;

		#if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST
		dbg("DBG_USR1", "NeighborListM: NEW NEIGHBOR: %i\n", bmsg->id);
		#endif
	} else if(numNbrs >= AGILLA_MAX_NUM_NEIGHBORS)
	{
		dbg("DBG_USR1", "NeighborListM: Error! Failed to insert neighbor: neighbor list maximum reached!\n");
		return m;
	}

	if (indx != -1)	// if the neighbor is in the list...
	{
		// Update the timestamp and number of hops to the base station.	 
		nbrs[indx].hopsToGW = bmsg->hopsToGW;		
		nbrs[indx].timeStamp = now;
		nbrs[indx].chId = bmsg->chId;
		nbrs[indx].energy = bmsg->energy;
	
		#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
			//nbrs[indx].linkQuality = m->lqi;
		#endif
		
		#if ENABLE_CLUSTERING

		//nbrs[indx].range = bmsg->range;

		if(_chId == TOS_NODE_ID)	// if this node is a clusterhead
		{
			if(call CHDir.isClusterMember(bmsg->id) == SUCCESS)	// if the beacon is from a cluster member
			{
				if(bmsg->chId != TOS_NODE_ID)	 // if the cluster member no longer considers this node to be its clusterhead
				{
					// a cluster member has changed clusters; remove it from list
					call CHDir.removeClusterMember(bmsg->id);
				}
			} else	// received beacon from non cluster member
			{				
				if(bmsg->chId == TOS_NODE_ID) // a new node has joined this node's cluster					
				call CHDir.addClusterMember(bmsg->id/*, bmsg->range*/);				 
			}
		} // end if this node is a clusterhead

		#if DEBUG_CLUSTERING
		//dbg("DBG_USR1", "NeighborListM: neighbor: %i hopsToGW=%i chId=%i, energy=%i, linkQuality=%i\n",
		// bmsg->id, bmsg->hopsToGW, bmsg->chId, bmsg->energy, m->lqi);
		#endif

		#endif
		
// #if DEBUG_NEIGHBORLIST
// dbg("DBG_USR1", "BeaconBasedFinderM: processBeacon(): Timestamp of neighbor %i updated to %i %i\n",
// nbrs[indx].addr, nbrs[indx].timeStamp.high32, nbrs[indx].timeStamp.low32);
// #endif

	}	// end if the neighbor is in the list
	
	#if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST
	 printNbrList();
	#endif

	#if ENABLE_CLUSTERING

		if(call AddressMgrI.isGW() != SUCCESS)
			determineCluster(m);
		
		//#if DEBUG_CLUSTERING
		// if(_chId == TOS_LOCAL_ADDRESS) {
		// call Leds.greenOn();
		// } else {
		// call Leds.greenOff();
		// }
		//#endif
	#endif

	return m;
	} // event TOS_MsgPtr RcvBeacon.receive(...)

	//RECEIVE SERIAL
	event message_t* SerialRcvBeacon.receive(message_t* m, void* payload, uint8_t len) {
	AgillaBeaconMsg* bmsg = (AgillaBeaconMsg *)payload;
	int16_t i = 0, indx = -1; // the index of the location
	tos_time_t now = call Time.get();

	#if DEBUG_NEIGHBORLIST
		dbg("DBG_USR1", "NeighborListM: processBeacon(): ID = %i, hopsToGW = %i\n", bmsg->id, bmsg->hopsToGW);
	#endif

	#if ENABLE_NEIGHBOR_LIST_FILTER
		// Reject beacons if it comes from a node that is not a grid neighbor.
		if (isGridNbr(bmsg->id) != SUCCESS)
		{
		#if DEBUG_NEIGHBORLIST
			dbg("DBG_USR1", "NeighborListM: processBeacon(): Not from grid neighbor, discarding...\n");
		#endif
		return m;
		}
	#endif

	// Check whether the neighbor is already in the list.	If so,
	// set indx equal to its position in the list, otherwise, set
	// indx = -1.
	while (i < numNbrs && indx == -1) {
		if (nbrs[i].addr == bmsg->id)
		indx = i;
		i++;
	}

	// If the beacon is NOT in the neighbor list, insert it.
	if (indx == -1 && numNbrs < AGILLA_MAX_NUM_NEIGHBORS)
	{
		indx = numNbrs++;
		nbrs[indx].addr = bmsg->id;

		#if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST
		dbg("DBG_USR1", "NeighborListM: NEW NEIGHBOR: %i\n", bmsg->id);
		#endif
	} else if(numNbrs >= AGILLA_MAX_NUM_NEIGHBORS)
	{
		dbg("DBG_USR1", "NeighborListM: Error! Failed to insert neighbor: neighbor list maximum reached!\n");
		return m;
	}

	if (indx != -1)	// if the neighbor is in the list...
	{
		// Update the timestamp and number of hops to the base station.	 
		nbrs[indx].hopsToGW = bmsg->hopsToGW;		
		nbrs[indx].timeStamp = now;
		nbrs[indx].chId = bmsg->chId;
		nbrs[indx].energy = bmsg->energy;
	
		#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
			//nbrs[indx].linkQuality = m->lqi;
		#endif
		
		#if ENABLE_CLUSTERING

		//nbrs[indx].range = bmsg->range;

		if(_chId == TOS_NODE_ID)	// if this node is a clusterhead
		{
			if(call CHDir.isClusterMember(bmsg->id) == SUCCESS)	// if the beacon is from a cluster member
			{
				if(bmsg->chId != TOS_NODE_ID)	 // if the cluster member no longer considers this node to be its clusterhead
				{
					// a cluster member has changed clusters; remove it from list
					call CHDir.removeClusterMember(bmsg->id);
				}
			} else	// received beacon from non cluster member
			{				
				if(bmsg->chId == TOS_NODE_ID) // a new node has joined this node's cluster					
				call CHDir.addClusterMember(bmsg->id/*, bmsg->range*/);				 
			}
		} // end if this node is a clusterhead

		#if DEBUG_CLUSTERING
		//dbg("DBG_USR1", "NeighborListM: neighbor: %i hopsToGW=%i chId=%i, energy=%i, linkQuality=%i\n",
		// bmsg->id, bmsg->hopsToGW, bmsg->chId, bmsg->energy, m->lqi);
		#endif

		#endif
		
// #if DEBUG_NEIGHBORLIST
// dbg("DBG_USR1", "BeaconBasedFinderM: processBeacon(): Timestamp of neighbor %i updated to %i %i\n",
// nbrs[indx].addr, nbrs[indx].timeStamp.high32, nbrs[indx].timeStamp.low32);
// #endif

	}	// end if the neighbor is in the list
	
	#if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST
	 printNbrList();
	#endif

	#if ENABLE_CLUSTERING

		if(call AddressMgrI.isGW() != SUCCESS)
			determineCluster(m);
		
		//#if DEBUG_CLUSTERING
		// if(_chId == TOS_LOCAL_ADDRESS) {
		// call Leds.greenOn();
		// } else {
		// call Leds.greenOff();
		// }
		//#endif
	#endif

	return m;
	} // event TOS_MsgPtr RcvBeacon.receive(...)

	/**
	 * Checks whether this node has a neighbor with the specified address.
	 *
	 * @return SUCCESS if the specified location is a neighbor.
	 */
	command error_t NeighborListI.isNeighbor(uint16_t addr)
	{
	int i;
	if (addr == AM_UART_ADDR)
		return call AddressMgrI.isGW();
	for (i=0; i < numNbrs; i++) {
		if (nbrs[i].addr == addr)
		return SUCCESS;
	}
	return FAIL;
	}

	/**
	 * Returns the number of neighbors.
	 */
	command uint16_t NeighborListI.numNeighbors()
	{
	return numNbrs;
	}

	/**
	 * Sets the specified AgillaLocation to be the ith
	 * neighbor.	Returns SUCCESS if such a neighbor exists, and
	 * FALSE otherwise.
	 */
	command error_t NeighborListI.getNeighbor(uint16_t i, uint16_t* addr)
	{
	if (i < numNbrs)
	{
		*addr = nbrs[i].addr;
		return SUCCESS;
	} else
		return FAIL;
	}

	/**
	 * Sets the specified location equal to the location of a randomly chosen
	 * neighbor.	If no neighbors exist, return FAIL.
	 */
	command error_t NeighborListI.getRandomNeighbor(uint16_t* addr) {
	if (numNbrs == 0)
		return FAIL;
	else {
		uint16_t rval = call Random.rand32();
		*addr = nbrs[rval % numNbrs].addr;
		return SUCCESS;
	}
	}

	/**
	 * Retrieves the address of the closest gateway, or neighbor closest
	 * to the gateway.	If no gateway or neighbor is close to a gateway,
	 * return FAIL.	Otherwise, the address is stored in the parameter.
	 *
	 * @param addr A pointer to store the results.
	 * @return The minimum number of hops to the gateway, or NO_GW (0xffff) if no
	 * gateway is known.
	 */
	command uint16_t NeighborListI.getGW(uint16_t* addr)
	{
	#if DEBUG_CLUSTERING
		//dbg(DBG_USR1, "NeighborListI.getGW():\n");
		//printNbrList();
	#endif
	
	if (call AddressMgrI.isGW() == SUCCESS)
	{
		*addr = TOS_NODE_ID;
		return 0;	// zero hops to GW
	}
	else
	{
		int i;
		uint16_t closest = NO_GW;
		for (i = 0; i < numNbrs; i++)
		{
		if(nbrs[i].hopsToGW < closest)
		{
			*addr = nbrs[i].addr;
			closest = nbrs[i].hopsToGW;
		}
		}
		return closest;
	}
	} // NeighborListI.getGW()


	//-------------------------------------------------------------------
	// Allow user to query a node's neighbor list.
	//

	/**
	 * The user has queried this mote's neighbor list.
	 */
	event message_t* RcvGetNbrList.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaGetNbrMsg* gnm = (AgillaGetNbrMsg*)payload;

	if (call AddressMgrI.isOrigAddress(gnm->destAddr) == SUCCESS)
	{
		//call Leds.redToggle();
		sendCount = 0;
		replyAddr = gnm->replyAddr;
		post SendNbrListTask();
		#if NBR_LIST_PRINT_CHANGES
		dbg("DBG_USR1", "NeighborListM: User has queried neighbor list!\n");
		printNbrList();
		#endif
	}
	else
	{
		// The gateway re-broadcasts the message.	Note that a broadcast
		// must be used since it is delivered to a node based on it's *original*
		// address (not its current address).
		if (call AddressMgrI.isGW() == SUCCESS)
		{
		message_t* nbrMsg = call MessageBufferI.getMsg();
		if (nbrMsg != NULL)
		{
			// Save this node's address as the reply-to address so it can forward
			// the results back to the base station.
			gnm->replyAddr = TOS_NODE_ID;
			*nbrMsg = *m;
			if (call SendGetNbrList.send(AM_BROADCAST_ADDR, nbrMsg, sizeof(AgillaGetNbrMsg)) != SUCCESS)
			{
			dbg("DBG_USR1", "NeighborListM: ERROR: Could not forward GetNbrList message.\n");
			call MessageBufferI.freeMsg(nbrMsg);
			}
		} else
		{
			dbg("DBG_USR1", "NeighborListM: ERROR: Could not get buffer for GetNbrList message.\n");
		}
		}
	}
	return m;
	} // event RcvGetNbrList

	//RECEIVE SERIAL
	event message_t* SerialRcvGetNbrList.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaGetNbrMsg* gnm = (AgillaGetNbrMsg*)payload;

	if (call AddressMgrI.isOrigAddress(gnm->destAddr) == SUCCESS)
	{
		//call Leds.redToggle();
		sendCount = 0;
		replyAddr = gnm->replyAddr;
		post SendNbrListTask();
		#if NBR_LIST_PRINT_CHANGES
		dbg("DBG_USR1", "NeighborListM: User has queried neighbor list!\n");
		printNbrList();
		#endif
	}
	else
	{
		// The gateway re-broadcasts the message.	Note that a broadcast
		// must be used since it is delivered to a node based on it's *original*
		// address (not its current address).
		if (call AddressMgrI.isGW() == SUCCESS)
		{
		message_t* nbrMsg = call MessageBufferI.getMsg();
		if (nbrMsg != NULL)
		{
			// Save this node's address as the reply-to address so it can forward
			// the results back to the base station.
			gnm->replyAddr = TOS_NODE_ID;
			*nbrMsg = *m;
			if (call SendGetNbrList.send(AM_BROADCAST_ADDR, nbrMsg, sizeof(AgillaGetNbrMsg)) != SUCCESS)
			{
			dbg("DBG_USR1", "NeighborListM: ERROR: Could not forward GetNbrList message.\n");
			call MessageBufferI.freeMsg(nbrMsg);
			}
		} else
		{
			dbg("DBG_USR1", "NeighborListM: ERROR: Could not get buffer for GetNbrList message.\n");
		}
		}
	}
	return m;
	} // event RcvGetNbrList

	event void SendGetNbrList.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}

	/**
	 * Send the neighbor list back to the base station.
	 */
	task void SendNbrListTask()
	{
	message_t* nbrMsg = call MessageBufferI.getMsg();
	if (nbrMsg != NULL)
	{
		AgillaNbrMsg* nMsg = (AgillaNbrMsg *)(call Packet.getPayload(nbrMsg, sizeof(AgillaNbrMsg)));
		int i;

		nextSendCount = sendCount;

		#if DEBUG_CLUSTERING
		printNbrList();
		#endif

		// fill the message with the neighbor information
		for (i = 0; i < AGILLA_NBR_MSG_SIZE && nextSendCount < numNbrs; i++)
		{
		nMsg->nbr[i] = nbrs[nextSendCount].addr;
		nMsg->hopsToGW[i] = nbrs[nextSendCount].hopsToGW;
		#if ENABLE_CLUSTERING
		nMsg->lqi[i] = nbrs[nextSendCount].linkQuality;
		#else
		nMsg->lqi[i] = 0;
		#endif
		nextSendCount++;
		}

		// fill remainder of msg
		for (; i < AGILLA_NBR_MSG_SIZE; i++)
		{
		nMsg->nbr[i] = AM_BROADCAST_ADDR;
		}

		if (replyAddr == TOS_NODE_ID || replyAddr == AM_UART_ADDR)
		{
		if (call AddressMgrI.isGW() == SUCCESS)
		{
			if (call SerialSendNbrList.send(AM_UART_ADDR, nbrMsg, sizeof(AgillaNbrMsg)) != SUCCESS) {
			call MessageBufferI.freeMsg(nbrMsg);
			post SendNbrListTask();
			}
		}
		}
		else
		{
		if (call SendNbrList.send(replyAddr, nbrMsg, sizeof(AgillaNbrMsg)) != SUCCESS)
		{
			call MessageBufferI.freeMsg(nbrMsg);
			post SendNbrListTask();
		}
		}
	}
	}

	event void SendNbrList.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	if (nextSendCount != 0)
	{
		if (success == SUCCESS)
		sendCount = nextSendCount;	// proceed to next message
		if (sendCount < numNbrs)
		post SendNbrListTask();
		else
		nextSendCount = 0;
	}
	//return SUCCESS;
	}

	event void SerialSendNbrList.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	if (nextSendCount != 0)
	{
		if (success == SUCCESS)
		sendCount = nextSendCount;	// proceed to next message
		if (sendCount < numNbrs)
		post SendNbrListTask();
		else
		nextSendCount = 0;
	}
	//return SUCCESS;
	}

	/**
	 * If this is the gateway, forward the neighbor list message to the
	 * base station.
	 */
	event message_t* RcvNbrList.receive(message_t* m, void* payload, uint8_t len)
	{
	if (call AddressMgrI.isGW() == SUCCESS)
	{
		message_t* nbrMsg = call MessageBufferI.getMsg();
		*nbrMsg = *m;
		call SerialSendNbrList.send(AM_UART_ADDR, nbrMsg, sizeof(AgillaNbrMsg));
	}
	return m;
	}

	//RECEIVE SERIAL
	event message_t* SerialRcvNbrList.receive(message_t* m, void* payload, uint8_t len)
	{
	if (call AddressMgrI.isGW() == SUCCESS)
	{
		message_t* nbrMsg = call MessageBufferI.getMsg();
		*nbrMsg = *m;
		call SerialSendNbrList.send(AM_UART_ADDR, nbrMsg, sizeof(AgillaNbrMsg));
	}
	return m;
	}


	#if ENABLE_GRID_ROUTING
	/**
	 * Takes two TinyOS addresses, converts them to locations (assumes grid topology)
	 * and calculates the distance between the two locations.
	 */
	uint16_t dist(uint16_t addr1, uint16_t addr2)
	{
		AgillaLocation loc1, loc2;
		call LocationMgrI.getLocation(addr1, &loc1);
		call LocationMgrI.getLocation(addr2, &loc2);
		return call LocationUtilI.dist(&loc1, &loc2);
	}

	/**
	 * Fetches the address of the closest neighbor to which an agent
	 * should be forwarded do.	Saves the results in the location
	 * specified by the nbr parameter.
	 *
	 * @return SUCCESS if a neighbor was found.
	 */
	command error_t NeighborListI.getClosestNeighbor(uint16_t *nbr)
	{
		// If the destination is the serial port
		if (*nbr == AM_UART_ADDR)
		{
		if (call AddressMgrI.isGW() == SUCCESS)
			return SUCCESS;
		else {
			if (call NeighborListI.getGW(nbr) != NO_GW) return SUCCESS;
			else return FAIL;
		}
		}

		// If the destination is broadcast
		else if (*nbr == AM_BROADCAST_ADDR)
		return SUCCESS;

		// If the destination is the local node
		else if (*nbr == TOS_NODE_ID)
		return SUCCESS;

		// If I have no neighbors, FAIL
		else if (numNbrs == 0)
		{
		#ifdef DEBUG_NEIGHBORLIST
			dbg("DBG_USR1", "NeighborListI: ERROR: No neighbors\n");
		#endif
		return FAIL;
		}

		// If the destination is a possible neighbor, but the neighbor has
		// not been heard from, assume it doesn't exist.
		else if (isGridNbr(*nbr) == SUCCESS && call NeighborListI.isNeighbor(*nbr) != SUCCESS)
		{
		dbg("DBG_USR1", "NeighborListM: ERROR: Grid Neighbor %i not present.\n", *nbr);

		return FAIL;
		}

		// Find the closest neighbor
		else
		{
		uint16_t i, cDist, cPos;

		#ifdef DEBUG_NEIGHBORLIST
			dbg("DBG_USR1", "NeighborListI: GetClosestNeighbor: Finding closest neighbor, numNbrs = %i...\n", numNbrs);
		#endif

		cPos = 0;
		cDist = dist(*nbr, nbrs[cPos].addr);

		for (i = 1; i < numNbrs; i++)
		{
			uint16_t d = dist(*nbr, nbrs[i].addr);

			#ifdef DEBUG_NEIGHBORLIST
			dbg("DBG_USR1", "NeighborListI: GetClosestNeighbor: Checking neighbor %i (dist = %i)...\n", nbrs[i].addr, d);
			#endif

			if (d < cDist)
			{
			cDist = d;
			cPos = i;
			}
		}
		*nbr = nbrs[cPos].addr;
		return SUCCESS;
		}
	}
	#endif

#if ENABLE_CLUSTERING
/**************************************************************/
/*					Clustering methods						*/
/**************************************************************/
	command error_t ClusteringI.isClusterHead() {

		if(_chId == TOS_NODE_ID) return SUCCESS;
		else return FAIL;
	}

/*
	command error_t ClusteringI.isNbrClusterHead(uint16_t* nbr){
		if(chId == *nbr)
		return SUCCESS;
		else
		return FAIL;
	}
*/

	command error_t ClusteringI.getClusterHead(uint16_t* chID) {
	if(_chId == NO_CLUSTERHEAD || _chId == TOS_NODE_ID ||
		(_chId != TOS_NODE_ID && call NeighborListI.isNeighbor(_chId) != SUCCESS))
	{
		dbg("DBG_USR1", "NeighborListM: getClusterHead(): ERROR: Cluster head not set or unreachable.\n");
		return FAIL;
	} else
		*chID = _chId;
	return SUCCESS;		
	}


	command error_t ClusteringI.isClusterMember(uint16_t id){
		uint8_t i;
		for (i=0; i < numNbrs; i++) {
			if (nbrs[i].addr == id && nbrs[i].chId != NO_CLUSTERHEAD && nbrs[i].chId == _chId)
				return SUCCESS;
		}
		return FAIL;
	}


	/**
	 * Sets the address of the cluster head.	If this node is the cluster head,
	 * turn on the green LED, otherwise turn it off.
	 */
	void setCH(uint16_t ch_id)
	{
	if(ch_id != _chId)	// if the cluster head has changed
	{
		_chId = ch_id;
		chSelectTime = call Time.get();
		
		if(_chId != TOS_NODE_ID)
		{
		call CHDirControl.stop();
		call Leds.led1Off();
		}		
		else							// This node is a cluster head.
		{
		call CHDirControl.start();
		call Leds.led1On();
		}

		#if DEBUG_CLUSTERING
		//call ClusteringI.sendClusterDebugMsg();
		dbg("DBG_USR1", "NeighborListM:setCH [%i] clusterhead set to %i\n", chSelectTime.low32, _chId);
		#endif
		#if ENABLE_EXP_LOGGING
		call ExpLoggerI.sendSetCluster(_chId);
		#endif
	}
	}


/*
	 command uint8_t ClusteringI.getCommRange(){
		 return 1;
	 }
*/


	/**
	 *
	 *
	 */
	inline void determineCluster(message_t* m)
	{
	int8_t i = 0, pos = -1;
	uint16_t hopsToGW;	// the number of hops to the gateway
	uint16_t nbrToGW;	 // the neighbor closest to the gateway
	uint16_t nbrId;
	tos_time_t now = call Time.get();

	AgillaBeaconMsg* bmsg = (AgillaBeaconMsg *)(call Packet.getPayload(m, sizeof(AgillaBeaconMsg)));
		
	// Get the neighbor that is closest to the basestation and the number
	// of hops it is from the basestation. 
	hopsToGW = call NeighborListI.getGW(&nbrToGW);
			
	if(hopsToGW != NO_GW)	// if a gateway is known
	{
		hopsToGW++; // add one hop to get to the neighbor

		#if DEBUG_CLUSTERING
		//dbg("DBG_USR1", "NeighborListM:determineCluster: hopsToGW=%i\n", hopsToGW);
		#endif
			
		// If this node is the gateway, and the clusterhead is unknown, 
		// set this node to be a cluster head.
		//if(hopsToGW == 1 && _chId != addr) 
		if (nbrToGW == TOS_NODE_ID && _chId != TOS_NODE_ID)
		setCH(nbrToGW);		
		
		else if(_chId == NO_CLUSTERHEAD) 
		{
		// This node is not a gateway and the clusterhead has not been set.
		
		// If the beacon is from a clusterhead, set the cluster head to
		// be the node who sent the beacon
		if (bmsg->id == bmsg->chId) 
			setCH(bmsg->id);		
		
		// If the beacon is NOT from a clusterhead and the number of hops to 
		// the gateway is even, declare self to be a cluster head.
		else if(hopsToGW % 2 == 0) 
			setCH(TOS_NODE_ID);
		
		// If the beacon is NOT from a clusterhead and the number of hops to
		// the gateway is NOT even...
		else if((now.low32 - initTime.low32) > 5*(BEACON_PERIOD+BEACON_RAND))
		{
			// if the node has not heard from a clusterhead in a long time
			// it should become a clusterhead
			setCH(TOS_NODE_ID);
		}
		}
		
		else if(_chId != TOS_NODE_ID)
		{
		// This node is not a gateway, or clusterhead

		// Check if it should join some other cluster
		// The node should change its clusterhead if it has
		// not heard from its current cluster head in time T
		// OR if the difference in the link quality of the
		// node sending the beacon is more than a threshold
		// OR if its clusterhead is no more a clusterhead

		i = 0;
		pos = -1;
		
		// Find the index of the neighbor that is the cluster head.
		// Store the index in variable "pos"
		while (i < numNbrs && pos == -1) 
		{
			if (nbrs[i].addr == _chId && nbrs[i].addr == nbrs[i].chId)
			pos = i;
			i++;
		}

		/*if(bmsg->id == bmsg->chId && pos != -1 && ((m->lqi - nbrs[pos].linkQuality) > 20)){
				setCH(bmsg->id);
		} else */
		
		
		if(pos == -1 || ((now.low32 - nbrs[pos].timeStamp.low32 ) > 5*(BEACON_PERIOD+BEACON_RAND)))
		{
			// if clusterhead entry not found
			// or if not heard from clusterhead for a while
			// or link quality of neighbor is much better
			// than link quality of current cluster head
			// set neighbor as cluster head
			
			if (pos == -1) {
				dbg("DBG_USR1", "[%i] NeighborListM:determineCluster: no CH is set, finding CH.\n", now.low32);
			} else {
				dbg("DBG_USR1", "[%i] NeighborListM:determineCluster: CH %i is obsolete, finding new CH.\n", now.low32, _chId);
			}
			
			nbrId = TOS_NODE_ID;
			i = 0;
			while (i < numNbrs && nbrId == TOS_NODE_ID) {
				if (nbrs[i].addr != _chId &&			// The neighbor is not the current CH
					nbrs[i].addr == nbrs[i].chId &&	 // The neighbor is a CH
					((now.low32 - nbrs[i].timeStamp.low32 ) <= 2*(BEACON_PERIOD+BEACON_RAND))) // The neighbor is not obsolete
						nbrId = nbrs[i].addr;
				i++;
			}
			setCH(nbrId);
		}
		
		}
		else 
		{
		// this node is a clusterhead

		#if DEBUG_CLUSTERING
			//dbg(DBG_USR1, "[%i] NeighborListM:determineCluster: Number of clustermembers = %i\n", now.low32, call CHDir.numClusterMembers());
			//dbg(DBG_USR1, "[%i] NeighborListM:determineCluster: chSelectTime = %i, 3*(BEACON_PERIOD+BEACON_RAND) = %i\n",
			// now.low32, chSelectTime.low32, 3*(BEACON_PERIOD+BEACON_RAND));
		#endif
		
		// if after a time period, I see that I don't have any cluster members
		// I should stop being a clusterhead and join the neighbor that is one
		if(bmsg->id == bmsg->chId && call CHDir.numClusterMembers() == 0 &&
			(now.low32 - chSelectTime.low32) > 3*(BEACON_PERIOD+BEACON_RAND))
		{
			// check if there is a clusterhead closer to the GW than
			// the node sending the beacon msg
			// find a neighbor that is a clusterhead and from whom
			// this node has heard from recently, and join its cluster

			setCH(bmsg->id);

			/*
			// commenting this off, to save space
			pos = -1;
			i = 0;
			while (i < numNbrs && pos == -1) {
				 if (nbrs[i].addr == nbrs[i].chId &&
						((now.low32 - nbrs[i].timeStamp.low32 ) <= 2*(BEACON_PERIOD+BEACON_RAND))){
						pos = i;
				 }
				 i++;
			}
			if(pos != -1) setCH(nbrs[pos].addr);
			*/
			#if DEBUG_CLUSTERING
			//dbg(DBG_USR1, "NeighborListM:determineCluster: pos = %i\n", pos);
			//dbg(DBG_USR1, "NeighborListM:determineCluster: 2*(BEACON_PERIOD+BEACON_RAND) = %i\n", 2*(BEACON_PERIOD+BEACON_RAND));
			#endif

		}
		}

	} else 
	{
		// There is no known gateway.	Set the current clusterhead to be -1.
		if(_chId != -1) setCH(-1);
	}
			//for DEBUGGING/////////////////
			//#if DEBUG_CLUSTERING
			//dbg(DBG_USR1, "NeighborListM:determineCluster: current cluster head is %i\n", chId);
			//printNbrList();
			// this is needed if reset msg sent

		 // #endif
			///////////////////////////
	} // end determineCluster




	/**
	 * This method is copied from MultiHopLQI to adjust the link quality.
	 */
	/*
	uint16_t adjustLQI(uint8_t val) {
		uint16_t result = (80 - (val - 40));
		result = (((result * result) >> 3) * result) >> 3;
		return result;
	}*/

 #if DEBUG_CLUSTERING

	event void SendClusterDebugMsg.sendDone(message_t* m, error_t success)
	{
		call MessageBufferI.freeMsg(m);
		//return SUCCESS;
	}

	event TOS_MsgPtr RcvClusterDebugMsg.receive(TOS_MsgPtr m) {
		//AgillaClusterDebugMsg* cmsg = (AgillaClusterDebugMsg *)m->data;
		//dbg(DBG_USR1, "NeighborListM: received cluster msg at time(%i) from addr(%i)\n", m->time, cmsg->dummy);
		return m;
	}

	command void ClusteringI.sendClusterDebugMsg(){
		TOS_MsgPtr msg;

		msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
		AgillaClusterDebugMsg* cmsg = (AgillaClusterDebugMsg *)msg->data;
		cmsg->src = TOS_LOCAL_ADDRESS;
		cmsg->id = _chId;
		if(_chId == TOS_LOCAL_ADDRESS)
			call CHDir.getBoundingBox(&(cmsg->bounding_box));
		dbg(DBG_USR1, "NeighborListM: sending cluster debug msg\n");

		if (!call SendClusterDebugMsg.send(TOS_UART_ADDR, sizeof(AgillaClusterDebugMsg), msg))
		{
			dbg(DBG_USR1, "NeighborListM: ERROR: Unable to send cluster debug msg.\n");
			call MessageBufferI.freeMsg(msg);
		}
		}

	}

	#endif /*DEBUG_CLUSTERING*/

	#endif /*ENABLE_CLUSTERING*/


}
