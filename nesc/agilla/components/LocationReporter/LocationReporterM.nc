// $Id: LocationReporterM.nc,v 1.13 2006/04/27 23:53:18 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2006, Washington University in Saint Louis
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
	* Sends the location of an agent.
	*
	* @author Sangeeta Bhattacharya
	* @author Chien-Liang Fok
	*/
 module LocationReporterM
 {
	 provides
	 {
	 interface StdControl;
	 interface Init;
	 interface LocationReporterI;
	 }
	 uses
	 {
	 interface Time;
	 interface AgentMgrI;
	 interface LocationMgrI;
	 interface NeighborListI;
	 interface AddressMgrI;
	 interface MessageBufferI;
	 interface AgentReceiverI;

	 #if ENABLE_CLUSTERING
		 interface ClusteringI;
		 interface ClusterheadDirectoryI as CHDir;
		 //interface AgentSenderI;
	 #endif

	 //interface LocationSenderI as SendLocation;
	 interface AMSend as SendLocation;
	 interface Receive as ReceiveLocation;
	 interface AMSend as SerialSendLocation;
	 interface Receive as SerialReceiveLocation;

	 #if ENABLE_EXP_LOGGING
		interface ExpLoggerI;
	 #endif

	 interface Leds;
	 interface Packet;
	 }
}
implementation
{
	//uint16_t _id;
	//bool _died;

	/**************************************************************/
	/*					Variable declarations					 */
	/**************************************************************/

	uint16_t _serial;

	/**************************************************************/
	/*					Method declarations					 */
	/**************************************************************/

	#if ENABLE_CLUSTERING
	#endif

	/**************************************************************/
	/*					 StdControl							 */
	/**************************************************************/

	command error_t Init.init()
	{
	_serial=0;

	return SUCCESS;
	}

	command error_t StdControl.start()
	{
	return SUCCESS;
	}

	command error_t StdControl.stop()
	{
	return SUCCESS;
	}


	/**************************************************************/
	/*						Helper methods					 */
	/**************************************************************/


	/**
	 * Figures out what the next hop should be towards the base station and
	 * sends the message to that node.	If this node is the gateway, the message
	 * is forwarded to the UART.
	 *
	 * If clustering is used, then msg is sent to clusterhead, if this node is
	 * not a cluster head. If this node is a clusterhead, msg is sent to GW
	 *
	 * "bounce" determines if the msg should be just forwarded to the GW.
	 */
	inline error_t sendMsg(message_t* msg, bool bounce)
	{

	if (call AddressMgrI.isGW() == SUCCESS)
	{
		#if DEBUG_LOCATION_DIRECTORY
		dbg("DBG_USR1", "LocationReporterM: sendMsg(): Sent agent location to BS\n");
		#endif

		#if ENABLE_EXP_LOGGING
		if(TRUE)
		{

			AgillaLocMsg *sMsg = (AgillaLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaLocMsg)));
			call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_NODE_ID, 
			SENDING_AGENT_LOCATION, sMsg->seq, sMsg->dest, sMsg->loc);
		}
		#endif
		
		return call SerialSendLocation.send(AM_UART_ADDR, msg, sizeof(AgillaLocMsg));
	} else
	{
		uint16_t onehop_dest;	
		
		#if ENABLE_CLUSTERING
		// find onehop_dest as the neighbor that is the closest to the clusterhead
		if(call ClusteringI.isClusterHead() == SUCCESS || bounce){
			if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
			{
				 dbg("DBG_USR1", "LocationReporterM: sendMsg(): ERROR: No neighbor closer to gateway.\n");
				 return FAIL;
			}
			#if DEBUG_CLUSTERING
				{

					AgillaLocMsg *sMsg = (AgillaLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaLocMsg)));
					dbg("DBG_USR1", "LocationReporterM: sendMsg(): Loc msg about agent %i being sent by CH or being bounced via %i!\n", sMsg->agent_id.id, onehop_dest);
				}
			#endif
		} else {
			// send to clusterhead, which should be a neighbor
			if (call ClusteringI.getClusterHead(&onehop_dest) != SUCCESS)
			{
				 dbg("DBG_USR1", "LocationReporterM: sendMsg(): ERROR: Cluster head could not be obtained.\n");
				 return FAIL;
			}
			sMsg->dest = onehop_dest;
			#if DEBUG_CLUSTERING
			{

				AgillaLocMsg *sMsg = (AgillaLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaLocMsg)));
				dbg("DBG_USR1", "LocationReporterM: sendMsg(): Loc msg about agent %i being sent to CH %i\n", sMsg->agent_id.id, onehop_dest);
			}	 
			#endif
		}

		#else

		// Get the one-hop neighbor that is closest to the gateway.
		// If there is no known gateway, abort.
		if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
		{
			dbg("DBG_USR1", "LocationReporterM: sendMsg(): ERROR: No neighbor closer to a gateway.\n");
			return FAIL;
		}
		#endif

		#if ENABLE_EXP_LOGGING		
			{
			//struct AgillaLocMsg *sMsg = (struct AgillaLocMsg *)msg->data;
			AgillaLocMsg *sMsg = (AgillaLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaLocMsg)));
			call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_NODE_ID, SENDING_AGENT_LOCATION, sMsg->seq, sMsg->dest, sMsg->loc);
		}		
		#endif
		
		if (onehop_dest == AM_UART_ADDR)
		return call SerialSendLocation.send(onehop_dest, msg, sizeof(AgillaLocMsg));
		else
		return call SendLocation.send(onehop_dest, msg, sizeof(AgillaLocMsg));
	}
	} // sendMsg()


	/**
	 * Sends a location update message.
	 */
	inline void doSend(AgillaAgentID* aID, bool died)
	{
	AgillaAgentContext* context = call AgentMgrI.getContext(aID);
	message_t* msg = call MessageBufferI.getMsg();

	if (msg != NULL && context != NULL)
	{

		AgillaLocMsg *sMsg = (AgillaLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaLocMsg)));

		// fill the location update message
		sMsg->agent_id = context->id;
		sMsg->agent_type = context->desc.value;
		sMsg->seq = _serial++;
		sMsg->dest = AM_UART_ADDR;
		sMsg->src = TOS_NODE_ID;
		if (!died)
		{
		call LocationMgrI.getLocation(TOS_NODE_ID, &(sMsg->loc));
		sMsg->timestamp = call Time.get();
		} else
		{
		// An AgillaLocMsg with the src, loc, and timestamp all
		// set to 0 indicates that the agent has died.
		//sMsg->src = 0;
		sMsg->loc.x = 0;
		sMsg->loc.y = 0;
		sMsg->timestamp.high32 = 0;
		sMsg->timestamp.low32 = 0;
		//sMsg->dest = 0;
		}
		if (sendMsg(msg, FALSE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
	}
	} // doSend()



	/**************************************************************/
	/*					Command and event handlers				*/
	/**************************************************************/

	/**
	 * This event is signaled whenever a new agent has arrived.
	 *
	 * @param context The context of the agent that just arrived.
	 */
	event void AgentReceiverI.receivedAgent(AgillaAgentContext* context, uint16_t dest)
	{
	if (dest == TOS_NODE_ID)
		call LocationReporterI.updateLocation(context);
	}

	/**
	 * Called when a location update message should be sent.
	 *
	 * @param context The agent whose location is being updated.
	 */
	command error_t LocationReporterI.updateLocation(AgillaAgentContext* context)
	{
	#if ENABLE_CLUSTERING
		AgillaLocation loc;
		//tos_time_t now = call Time.get();
		uint16_t agentKnown = 0;
	#endif

	#if DEBUG_LOCATION_DIRECTORY || DEBUG_CLUSTERING
		dbg("DBG_USR1", "LocationReporterM: receivedAgent(): Sending location update for agent %i...\n",
		context->id.id);
	#endif

	#if ENABLE_CLUSTERING
		// check if this node is a clusterhead
		// if it is a CH store the agent in the directory
		// else send a Loc msg to the clusterhead
		if(call AddressMgrI.isGW() == SUCCESS){
			// send msg to BS (over UART)
			doSend(&context->id, FALSE);
		} else if(call ClusteringI.isClusterHead() == SUCCESS){
			call LocationMgrI.getLocation(TOS_NODE_ID, &loc);
			if(call CHDir.addAgent(context->id.id, context->desc.value, &loc, /*&now,*/ &(agentKnown)) == SUCCESS)
			{
			if(agentKnown == 0){
				// send msg to GW
				doSend(&context->id, FALSE);
			}
			}
		} else {
			// send location update msg to the clusterhead
			doSend(&context->id, FALSE);
		}
	#else
		doSend(&context->id, FALSE);
	#endif
	return SUCCESS;
	} // LocationReporterI.updateLocation()

	command error_t LocationReporterI.agentDied(AgillaAgentID* aid)
	{
	#if ENABLE_CLUSTERING
		#if DEBUG_CLUSTERING
			 dbg("DBG_USR1", "LocationReporterM: (): agent %i died\n", aid->id);
		#endif
		if(call AddressMgrI.isGW() != SUCCESS && call ClusteringI.isClusterHead() == SUCCESS){
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "LocationReporterM: Node Is CH; Updating local directory\n");
			#endif
			call CHDir.removeAgent(aid);
		}
	#endif
	doSend(aid, TRUE);
	return SUCCESS;
	}

	command error_t LocationReporterI.agentChangedDesc(AgillaAgentID* aid)
	{
	#if ENABLE_CLUSTERING
		AgillaLocation loc;
		//tos_time_t now = call Time.get();
		uint16_t agentKnown = 0;
		AgillaAgentContext* context = call AgentMgrI.getContext(aid);

		if(context != NULL){
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "LocationReporterM: (): agent %i changed type\n", aid->id);
			#endif
			if(call AddressMgrI.isGW() != SUCCESS && call ClusteringI.isClusterHead() == SUCCESS){
				call LocationMgrI.getLocation(TOS_NODE_ID, &loc);
				if(call CHDir.addAgent(context->id.id, context->desc.value, &loc, /*&now,*/ &agentKnown) != SUCCESS)
					return FAIL;
			}
			 // send msg to clusterhead
			doSend(aid, FALSE);
		}
	#else
		doSend(aid, FALSE);
	#endif
	return SUCCESS;
	}



//#if ENABLE_CLUSTERING
	/*
	 * Notification that an agent has moved. If this node is a clusterhead, check if the agent moves
	 * to another cluster. If yes, delete agent. In this node is not a clusterhead check if the agent
	 * moves to a detination that this node does not know about or if it moves to a node that this node
	 * knows to be in a different cluster. If this is true, then send a delete msg to the clusterhead.
	 */
/*	event void AgentSenderI.sendDone(AgillaAgentContext* context, uint8_t op, result_t success, uint16_t dest){
		if((op == IOPsmove || op == IOPwmove) && success == SUCCESS){
			#if DEBUG_CLUSTERING
			 dbg(DBG_USR1, "LocationReporterM: agent %i moved to %i\n", context->id, dest);
			#endif

			if(call ClusteringI.isClusterHead()){
				#if DEBUG_CLUSTERING
					dbg(DBG_USR1, "LocationReporterM: Node Is CH; Removing agent from local directory\n");
				#endif
				// check if agent has moved to another cluster
				// if it has, then remove the agent
				if(!call CHDir.isClusterMember(dest))
				{
					if(!call AddressMgrI.isGW()) call CHDir.removeAgent(&(context->id));
				}
			} else {
				// this node is a cluster member
				// check if dest is in the neighbor list and if dest has the same
				// cluster head. If yes, then dest is in the same cluster and
				// do not send an agent died message to the cluster head
				if(!call ClusteringI.isClusterMember(dest))
				{
				doSend(&(context->id), TRUE);
				}
			}
		}
	}*/
	//#endif


	/**
	 * If no clustering is used, this bounces the location update message off
	 * this node.	
	 * 
	 * If clustering is used, it checks whether the message is destined for this
	 * node and whether it is a cluster head.	If so, it updates the directory.
	 *
	 * If this node hears about the agent for the first time, or if the agent
	 * type has changed, it notifies the BS.
	 *
	 * If the msg is not destined for this node, it is bounced.
	 */
	event message_t* ReceiveLocation.receive(message_t* m, void *payload, uint8_t len)
	{
	message_t* msg = call MessageBufferI.getMsg();


	if (msg != NULL)
	{
		#if ENABLE_CLUSTERING
		uint16_t agentKnown = 0;

		AgillaLocMsg *sMsg = (AgillaLocMsg *)payload;

		if(sMsg->dest == TOS_NODE_ID)
		{
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "LocationReporterM: Received Loc Msg from %i\n", sMsg->src);
			#endif
			//call Leds.redToggle(); // Used for debugging
			if(call AddressMgrI.isGW() != SUCCESS)
			{

				// make sure that this node is still a clusterhead
				if(call ClusteringI.isClusterHead() != SUCCESS){
					dbg("DBG_USR1", "LocationReporterM: ReceiveLocation.receive(): ERROR! Not Clusterhead, but received Loc msg for agent %i from src %i\n",
						 sMsg->agent_id.id, sMsg->src);
					call MessageBufferI.freeMsg(msg);
					return m;
				}

				if(sMsg->loc.x == 0 && sMsg->loc.y ==0 && sMsg->timestamp.low32 == 0 && sMsg->timestamp.high32 == 0)
				{
					// msg indicates that agent is dead; remove agent
					call CHDir.removeAgent(&(sMsg->agent_id));
					sMsg->src = TOS_NODE_ID;
					sMsg->seq = _serial++;
					sMsg->dest = AM_UART_ADDR;
				 } else {
					// add agent

					if(call CHDir.addAgent(sMsg->agent_id.id, sMsg->agent_type, &(sMsg->loc), /*&(sMsg->timestamp),*/ &(agentKnown)) == SUCCESS)
					{
						#if ENABLE_EXP_LOGGING
							call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_NODE_ID, CLUSTER_AGENT_ADDED, sMsg->seq, agentKnown, sMsg->loc);
						#endif
						if(agentKnown == 0)
						{
							// send msg to GW
							// MODIFYING RECEIVED MESSAGE; CHECK IF THIS IS OK !!!!?????????????
							sMsg->src = TOS_NODE_ID;
							sMsg->seq = _serial++;
							sMsg->dest = AM_UART_ADDR;
							*msg = *m;
							if(sendMsg(msg, FALSE) != SUCCESS)
							{
								 call MessageBufferI.freeMsg(msg);
							}
							return m;
						}
					}
					call MessageBufferI.freeMsg(msg);
					return m;
				 }
			} else {
				// MODIFYING RECEIVED MESSAGE; CHECK IF THIS IS OK !!!!?????????????
				sMsg->src = TOS_NODE_ID;
				sMsg->seq = _serial++;
				sMsg->dest = AM_UART_ADDR;
			}
		}
		#endif

		*msg = *m;
		if (sendMsg(msg, TRUE) != SUCCESS) 
		call MessageBufferI.freeMsg(msg);

	}
	return m;
	}
	
	event message_t* SerialReceiveLocation.receive(message_t* m, void *payload, uint8_t len)
	{
	message_t* msg = call MessageBufferI.getMsg();


	if (msg != NULL)
	{
		#if ENABLE_CLUSTERING
		uint16_t agentKnown = 0;

		AgillaLocMsg *sMsg = (AgillaLocMsg *)payload;

		if(sMsg->dest == TOS_NODE_ID)
		{
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "LocationReporterM: Received Loc Msg from %i\n", sMsg->src);
			#endif
			//call Leds.redToggle(); // Used for debugging
			if(call AddressMgrI.isGW() != SUCCESS)
			{

				// make sure that this node is still a clusterhead
				if(call ClusteringI.isClusterHead() != SUCCESS){
					dbg("DBG_USR1", "LocationReporterM: ReceiveLocation.receive(): ERROR! Not Clusterhead, but received Loc msg for agent %i from src %i\n",
						 sMsg->agent_id.id, sMsg->src);
					call MessageBufferI.freeMsg(msg);
					return m;
				}

				if(sMsg->loc.x == 0 && sMsg->loc.y ==0 && sMsg->timestamp.low32 == 0 && sMsg->timestamp.high32 == 0)
				{
					// msg indicates that agent is dead; remove agent
					call CHDir.removeAgent(&(sMsg->agent_id));
					sMsg->src = TOS_NODE_ID;
					sMsg->seq = _serial++;
					sMsg->dest = AM_UART_ADDR;
				 } else {
					// add agent

					if(call CHDir.addAgent(sMsg->agent_id.id, sMsg->agent_type, &(sMsg->loc), /*&(sMsg->timestamp),*/ &(agentKnown)) == SUCCESS)
					{
						#if ENABLE_EXP_LOGGING
							call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_NODE_ID, CLUSTER_AGENT_ADDED, sMsg->seq, agentKnown, sMsg->loc);
						#endif
						if(agentKnown == 0)
						{
							// send msg to GW
							// MODIFYING RECEIVED MESSAGE; CHECK IF THIS IS OK !!!!?????????????
							sMsg->src = TOS_NODE_ID;
							sMsg->seq = _serial++;
							sMsg->dest = AM_UART_ADDR;
							*msg = *m;
							if(sendMsg(msg, FALSE) != SUCCESS)
							{
								 call MessageBufferI.freeMsg(msg);
							}
							return m;
						}
					}
					call MessageBufferI.freeMsg(msg);
					return m;
				 }
			} else {
				// MODIFYING RECEIVED MESSAGE; CHECK IF THIS IS OK !!!!?????????????
				sMsg->src = TOS_NODE_ID;
				sMsg->seq = _serial++;
				sMsg->dest = AM_UART_ADDR;
			}
		}
		#endif

		*msg = *m;
		if (sendMsg(msg, TRUE) != SUCCESS) 
		call MessageBufferI.freeMsg(msg);

	}
	return m;
	}

	event void SendLocation.sendDone(message_t* m, error_t success)
	{
	#if ENABLE_EXP_LOGGING
		if(success == SUCCESS)
		{

		AgillaLocMsg *sMsg = (AgillaLocMsg *)(call Packet.getPayload(m, sizeof(AgillaLocMsg)));
		call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_NODE_ID, AGENT_LOCATION_SENT, sMsg->seq, sMsg->dest, sMsg->loc);
		}
	#endif
	call MessageBufferI.freeMsg(m);

	}

	event void SerialSendLocation.sendDone(message_t* m, error_t success)
	{
	#if ENABLE_EXP_LOGGING
		if(success == SUCCESS)
		{

		AgillaLocMsg *sMsg = (AgillaLocMsg *)(call Packet.getPayload(m, sizeof(AgillaLocMsg)));
		call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_NODE_ID, AGENT_LOCATION_SENT, sMsg->seq, sMsg->dest, sMsg->loc);
		}
	#endif
	call MessageBufferI.freeMsg(m);

	}


}
