// $Id: OPgetlocationCM.nc,v 1.3 2006/04/25 22:27:38 chien-liang Exp $

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
#include "AgillaOpcodes.h"
#include "TupleSpace.h"
#include "Timer.h"

/**
 * Finds the location of an agent using its AgentID.	This is the clustered version.
 *
 * @author Chien-Liang Fok
 */
module OPgetlocationCM {
	provides {
	interface BytecodeI;

	interface Init;
	}
	uses {
	interface NeighborListI;
	interface LocationMgrI;
	interface ClusteringI;
	interface ClusterheadDirectoryI;
	interface AMSend as SendRequest;
	interface Receive as ReceiveRequest;
	interface AMSend as SerialSendRequest;
	interface Receive as SerialReceiveRequest;

	interface Receive as ReceiveResults;
	interface AMSend as SendResults;
	interface AMSend as SerialSendResults;
	interface Receive as SerialReceiveResults;

	interface MessageBufferI;
	interface AddressMgrI;
	interface AgentMgrI;
	interface TupleUtilI;
	interface OpStackI;
	interface QueueI;
	interface ErrorMgrI;
	interface Timer<TMilli> as Timeout;
	interface Leds; // debug
	interface Packet;

	#if ENABLE_EXP_LOGGING
		interface ExpLoggerI;
		#ifdef _H_msp430hardware_h
		interface LocalTime;
		#endif
	#endif
	}
}
implementation {

	/**
	 * Only one agent per mote can issue a directory service
	 * operation, _currAgent is a pointer to this agent's context.
	 * If another agent attempts to perform a directory service
	 * operation while the _currAgent is waiting for results,
	 * it's context is stored in the waitQueue and resumed when
	 * the current agent finishes.
	 */
	AgillaAgentContext* _currAgent;

	/**
	 * The AgentID of the agent being searched for.
	 */
	AgillaAgentID _aID;

	/**
	 * Holds pending agents that are waiting for the current agent
	 * to finish.
	 */
	Queue waitQueue;

	/**
	 * A running counter for the query id.
	 */
	uint8_t _qid;

	/*
	 * Holds the location of the agent if this node is a clusterhead that receives the query
	 */
	AgillaLocation _agentLoc;


	#if ENABLE_EXP_LOGGING
	uint32_t _start;
	#endif

	/**************************************************************/
	/*					 StdControl							 */
	/**************************************************************/

	command error_t Init.init()
	{
	_currAgent = NULL;
	_qid = 0;
	call QueueI.init(&waitQueue);
	return SUCCESS;
	}

	/*command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}*/

	/**************************************************************/
	/*						Helper methods						*/
	/**************************************************************/



	inline error_t finish(error_t success)
	{
	#if ENABLE_EXP_LOGGING
		#ifdef _H_msp430hardware_h
		_start = call LocalTime.get() - _start;
		#else
		_start = 0;
		#endif
		call ExpLoggerI.sendQueryLatency(_start);
	#endif

	if(success==SUCCESS) _currAgent->condition=1;
		else _currAgent->condition=0;
	call AgentMgrI.run(_currAgent);
	_currAgent = NULL;

	// If there are pending agents, execute them
	if (!call QueueI.empty(&waitQueue))
	{
		#if DEBUG_OP_GETLOCATION
		dbg("DBG_USR1", "OPgetLocationCM: finish(): WaitQueue (0x%x) not empty, running next agent.\n", &waitQueue);
		#endif

		call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));
	}
	return SUCCESS;
	} // finish()


	/**
	 * Figures out what the next hop should be towards the base station and
	 * sends the message to that node.	If this node is the gateway, the message
	 * is forwarded to the UART.
	 */
	inline error_t sendQueryMsg(message_t* msg, bool bounce)
	{
	 /* if (call AddressMgrI.isGW() == SUCCESS)
	{
		#if DEBUG_OP_GETLOCATION
		dbg("DBG_USR1", "OPgetLocationCM: sendQueryMsg(): Sending query message to the BS\n");
		#endif
		return call SerialSendRequest.send(AM_UART_ADDR, msg, sizeof(AgillaQueryAgentLocMsg));
	} else
	{*/
		uint16_t onehop_dest;

		//struct AgillaQueryAgentLocMsg *qMsg = (struct AgillaQueryAgentLocMsg *)msg->data;
		AgillaQueryAgentLocMsg *qMsg = (AgillaQueryAgentLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryAgentLocMsg)));

		// find onehop_dest as the neighbor that is the closest to the clusterhead
		if(bounce){
			onehop_dest = qMsg->dest;

			#if ENABLE_GRID_ROUTING
				call NeighborListI.getClosestNeighbor(&onehop_dest);
			#endif
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetLocationCM: SendQueryMsg(): QueryAgentLoc msg being bounced to %i via %i\n", qMsg->dest, onehop_dest);
			#endif
		} else if(call ClusteringI.isClusterHead()== SUCCESS){
			// send msg to GW

			if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
			{
				 dbg("DBG_USR1", "OPgetLocationCM: sendQueryMsg(): ERROR: No neighbor closer to gateway.\n");
				 return FAIL;
			}
			#if DEBUG_CLUSTERING
				 dbg("DBG_USR1", "OPgetLocationCM: SendQueryMsg(): QueryAgentLoc msg being sent by CH or being bounced to GW via %i!\n", onehop_dest);
			#endif
		} else {
			// send to clusterhead, which should be a neighbor
			if (call ClusteringI.getClusterHead(&onehop_dest) != SUCCESS)
			{
				 dbg("DBG_USR1", "OPgetLocationCM: SendQueryMsg(): ERROR: Cluster head could not be obtained.\n");
				 return FAIL;
			}
			qMsg->dest = onehop_dest;
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetLocationCM: SendQueryMsg(): QueryAgentLoc msg being sent to CH %i\n", onehop_dest);
			#endif
		}
		if(onehop_dest == AM_UART_ADDR)	
		return call SerialSendRequest.send(onehop_dest, msg, sizeof(AgillaQueryAgentLocMsg));
		else
		return call SendRequest.send(onehop_dest, msg, sizeof(AgillaQueryAgentLocMsg));
	/*}*/
	} // sendQueryMsg()

	/**
	 * Starts the sending of a query message.
	 */
	task void doSendQuery()
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		AgillaQueryAgentLocMsg *qMsg = (AgillaQueryAgentLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryAgentLocMsg)));
		qMsg->agent_id = _currAgent->id;
		qMsg->src = TOS_NODE_ID;
		qMsg->dest = AM_UART_ADDR;
		qMsg->qid = ((TOS_NODE_ID & 0xff) << 8) | _qid++;
		qMsg->flags = LOCAL;
		qMsg->find_agent_id = _aID;


		if (sendQueryMsg(msg, FALSE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
		else {
		#if ENABLE_EXP_LOGGING
			AgillaLocation loc;
			loc.x = loc.y = 0;
			call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_LOCATION_ISSUED, qMsg->qid, SUCCESS, loc);
			#ifdef _H_msp430hardware_h
			_start = call LocalTime.get();
			#endif
		#endif
		call Timeout.startOneShot(TIMEOUT_GET_LOCATION);
		}
	}
	} // task doSendQuery()


	/*
	 * Sends the query reply message
	 */

	error_t sendQueryReplyMsg(message_t* msg, AgillaQueryAgentLocMsg* qMsg)
	{
	if(msg != NULL && qMsg != NULL)
	{
		AgillaQueryReplyAgentLocMsg *replyMsg = (AgillaQueryReplyAgentLocMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryReplyAgentLocMsg)));
		uint16_t onehop_dest;

		replyMsg->agent_id = qMsg->agent_id;
		replyMsg->dest = qMsg->src;
		replyMsg->qid = qMsg->qid;
		replyMsg->flags = VALID;
		replyMsg->loc = _agentLoc;		// Save the result here
		replyMsg->nw_desc.string = 0;
		onehop_dest = qMsg->src;
		if(onehop_dest == AM_UART_ADDR){
		if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
		{
			 dbg("DBG_USR1", "OPgetLocationCM: sendQueryReplyMsg(): ERROR: No neighbor closer to gateway.\n");
			 return FAIL;
		}
		}
		#if DEBUG_CLUSTERING
			dbg("DBG_USR1", "OPgetLocationCM: SendQueryReplyMsg(): Sending query reply to %i\n", onehop_dest);
		#endif
		
		 if (onehop_dest == AM_UART_ADDR)
		return call SerialSendResults.send(onehop_dest, msg, sizeof(AgillaQueryReplyAgentLocMsg));
		else
		return call SendResults.send(onehop_dest, msg, sizeof(AgillaQueryReplyAgentLocMsg));
	}
	#if DEBUG_CLUSTERING
		dbg("DBG_USR1", "OPgetLocationCM: SendQueryReplyMsg(): msg or qMsg is NULL\n");
	#endif
	return FAIL;
	}

	/**************************************************************/
	/*						Operation Call						*/
	/**************************************************************/

	/**
	 * Execute a directory operation.
	 *
	 * @param instr The directory operation instruction.
	 * @param context The agent performing the operation.
	 * @return SUCCESS If the operation is being perfomed.
	 */
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context)
	{
	// Change the context's state to WAITING.	This prevents the VM
	// from executing the agent.
	context->state = AGILLA_STATE_WAITING;

	// Mutual Exclusion.	Only allow one agent to perform
	// a remote tuple space operation at a time.
	if (_currAgent != NULL)
	{
		#if DEBUG_OP_GETLOCATION
		dbg("DBG_USR1", "OPgetLocationCM: execute(): Another agent is performing a directory operation, waiting...\n");
		#endif

		context->pc--;
		return call QueueI.enqueue(context, &waitQueue, context);
	} else
	{
		AgillaVariable var;

		_currAgent = context;

		dbg("DBG_USR1", "VM (%i:%i): OPgetLocationCM: Executing OPgetlocation.\n", context->id.id, context->pc-1);

		// Get the AgentID
		if (call OpStackI.popOperand(_currAgent, &var) == SUCCESS)
		{
		if (var.vtype & AGILLA_VAR_A)
		{
			_aID = var.id;
		} else if (var.vtype & AGILLA_VAR_V)
		{
		 _aID.id = var.value.value;

		} else
		{
			dbg("DBG_USR1", "VM (%i:%i): OPgetLocationCM: ERROR: Invalid parameter type [%i].\n",
			_currAgent->id.id, _currAgent->pc-1, var.vtype);
			call ErrorMgrI.error2d(_currAgent, AGILLA_ERROR_INVALID_TYPE, 0x12, var.vtype);
			return finish(FAIL);
		}
		} else
		{
		dbg("DBG_USR1", "VM (%i:%i): OPgetLocationCM: ERROR: Could not pop parameter off stack.\n",
			_currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);
		}

		#if DEBUG_OP_GETLOCATION
		dbg("DBG_USR1", "OPgetLocationCM: Searching for agent with ID = %i\n", _aID.id);
		#endif



		// if this node is a clusterhead, it should see if it can answer the query itself
		if(call AddressMgrI.isGW() != SUCCESS && call ClusteringI.isClusterHead() == SUCCESS){
			AgillaLocation aLoc;
			if(call ClusterheadDirectoryI.getAgent(&_aID, &aLoc) == SUCCESS){
				// agent was found by the clusterhead
				// send the answer to the agent
				#if DEBUG_CLUSTERING
					dbg("DBG_USR1", "OPgetLocationCM: BytecodeI.execute: Found agent %i:[%i,%i] on clusterhead\n",
							_aID.id, aLoc.x, aLoc.y);
				#endif
				call OpStackI.pushLocation(_currAgent, &aLoc);
				finish(SUCCESS);
				return SUCCESS;
			}
		}

		if (post doSendQuery() != SUCCESS)
		finish(FAIL);
		return SUCCESS;
	}
	} // BytecodeI.execute


	/**************************************************************/
	/*						 TIMERS								 */
	/**************************************************************/

	event void Timeout.fired()
	{
	#if ENABLE_EXP_LOGGING
		AgillaLocation loc;
		call LocationMgrI.getLocation(TOS_NODE_ID, &loc);
		call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_LOCATION_RESULTS_RECEIVED, 
		((TOS_NODE_ID & 0xff) << 8) | (_qid-1), 3, loc);
	#endif

	#if DEBUG_OP_GETLOCATION
		dbg("DBG_USR1", "OPgetLocationCM: ERROR: Timed out while waiting for results.\n");
	#endif
	finish(FAIL);

	}


/**************************************************************/
/*				Message Handlers							*/
/**************************************************************/

	event message_t* ReceiveResults.receive(message_t* m, void* payload, uint8_t len)
		{
		AgillaQueryReplyAgentLocMsg* reply = (AgillaQueryReplyAgentLocMsg*)payload;

		if(reply->dest == TOS_NODE_ID && reply->dest == (reply->qid >> 8))
		{

			if(_currAgent != NULL)
			{
				if ( _currAgent->id.id == reply->agent_id.id)
				{
				#if DEBUG_OP_GETLOCATION
					dbg("DBG_USR1", "OPgetLocationCM: Received Results [%i,%i], flags = %i.\n",
					reply->loc.x, reply->loc.y, reply->flags);
				#endif

				call Timeout.stop();
				
				if (reply->flags & INVALID)
					_currAgent->condition = 0;
				else if (reply->flags & VALID) {
					call OpStackI.pushLocation(_currAgent, &reply->loc);
					if (reply->flags & COARSE)
					_currAgent->condition = 2;
					else
					_currAgent->condition = 1;
				}

				#if ENABLE_EXP_LOGGING
					call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_LOCATION_RESULTS_RECEIVED, 
					reply->qid, reply->flags, reply->loc);
				#endif				
				
				// The condition code was already set, thus just pass it as a parameter.
				//finish(_currAgent->condition); //IL PARAMETRO é UN ERROR_T, PER CUI BISOGNA ADOTTARE UN'ALTRA STRATEGIA ESSENDO SUCCESS=0
				if(_currAgent->condition == 0) finish(FAIL);
				else finish(SUCCESS);
				} else {
				dbg("DBG_USR1", "OPgetLocationCM: ReceivedResults: _currAgent->id.id (%i) != reply->agent_id.id (%i)\n",
					_currAgent->id.id, reply->agent_id.id);
				}
			} else {
				dbg("DBG_USR1", "OPgetLocationCM: ReceivedResults: _currAgent == NULL\n");
			}

		} else {
			// Bounce the message
			message_t* msg = call MessageBufferI.getMsg();
			if (msg != NULL)
			{
			uint16_t oneHopDest;

			if (reply->dest == TOS_NODE_ID){
				// broadcast the result to the cluster member
				//oneHopDest = AM_BCAST_ADDR;
				oneHopDest = (reply->qid >> 8);
				reply->dest = oneHopDest;


			} else {
				// forward the results to the node closest to the destination
				oneHopDest = reply->dest;
				#if ENABLE_GRID_ROUTING
				call NeighborListI.getClosestNeighbor(&oneHopDest);
				#endif

			}

			#if DEBUG_CLUSTERING
				 dbg("DBG_USR1", "OPgetLocationCM: ReceiveResults.receive: Forwarding result [%i,%i] to %i\n",
												reply->loc.x, reply->loc.y, oneHopDest);
			#endif

			*msg = *m;
			if(oneHopDest == AM_UAT_ADDR){
				if (call SerialSendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAgentLocMsg)) != SUCCESS)
				{
				call MessageBufferI.freeMsg(msg);
				#if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OPgetLocationCM: ReceiveResults.receive: Failed to send QueryReplyAgentLocMsg\n");
				#endif
				}	else
				{
				#if ENABLE_EXP_LOGGING
					call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, 
					QUERY_GET_LOCATION_RESULTS_FORWARDED, reply->qid, SUCCESS, reply->loc);
				#endif
				}
			}
			else{
				if (call SendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAgentLocMsg)) != SUCCESS)
				{
				call MessageBufferI.freeMsg(msg);
				#if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OPgetLocationCM: ReceiveResults.receive: Failed to send QueryReplyAgentLocMsg\n");
				#endif
				}	else
				{
				#if ENABLE_EXP_LOGGING
					call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, 
					QUERY_GET_LOCATION_RESULTS_FORWARDED, reply->qid, SUCCESS, reply->loc);
				#endif
				}
			}
			}
		}
		return m;
	} // ReceiveResults

	 //RECEIVE SERIAL
		 event message_t* SerialReceiveResults.receive(message_t* m, void* payload, uint8_t len)
		{
		AgillaQueryReplyAgentLocMsg* reply = (AgillaQueryReplyAgentLocMsg*)payload;

		if(reply->dest == TOS_NODE_ID && reply->dest == (reply->qid >> 8))
		{

			if(_currAgent != NULL)
			{
				if ( _currAgent->id.id == reply->agent_id.id)
				{
				#if DEBUG_OP_GETLOCATION
					dbg("DBG_USR1", "OPgetLocationCM: Received Results [%i,%i], flags = %i.\n",
					reply->loc.x, reply->loc.y, reply->flags);
				#endif

				call Timeout.stop();
				
				if (reply->flags & INVALID)
					_currAgent->condition = 0;
				else if (reply->flags & VALID) {
					call OpStackI.pushLocation(_currAgent, &reply->loc);
					if (reply->flags & COARSE)
					_currAgent->condition = 2;
					else
					_currAgent->condition = 1;
				}

				#if ENABLE_EXP_LOGGING
					call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_LOCATION_RESULTS_RECEIVED, 
					reply->qid, reply->flags, reply->loc);
				#endif				
				
				// The condition code was already set, thus just pass it as a parameter.
				//finish(_currAgent->condition); //IL PARAMETRO é UN ERROR_T, PER CUI BISOGNA ADOTTARE UN'ALTRA STRATEGIA ESSENDO SUCCESS=0
				if(_currAgent->condition == 0) finish(FAIL);
				else finish(SUCCESS);
				} else {
				dbg("DBG_USR1", "OPgetLocationCM: ReceivedResults: _currAgent->id.id (%i) != reply->agent_id.id (%i)\n",
					_currAgent->id.id, reply->agent_id.id);
				}
			} else {
				dbg("DBG_USR1", "OPgetLocationCM: ReceivedResults: _currAgent == NULL\n");
			}

		} else {
			// Bounce the message
			message_t* msg = call MessageBufferI.getMsg();
			if (msg != NULL)
			{
			uint16_t oneHopDest;

			if (reply->dest == TOS_NODE_ID){
				// broadcast the result to the cluster member
				//oneHopDest = AM_BCAST_ADDR;
				oneHopDest = (reply->qid >> 8);
				reply->dest = oneHopDest;


			} else {
				// forward the results to the node closest to the destination
				oneHopDest = reply->dest;
				#if ENABLE_GRID_ROUTING
				call NeighborListI.getClosestNeighbor(&oneHopDest);
				#endif

			}

			#if DEBUG_CLUSTERING
				 dbg("DBG_USR1", "OPgetLocationCM: ReceiveResults.receive: Forwarding result [%i,%i] to %i\n",
												reply->loc.x, reply->loc.y, oneHopDest);
			#endif

			*msg = *m;
			if(oneHopDest == AM_UAT_ADDR){
				if (call SerialSendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAgentLocMsg)) != SUCCESS)
				{
				call MessageBufferI.freeMsg(msg);
				#if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OPgetLocationCM: ReceiveResults.receive: Failed to send QueryReplyAgentLocMsg\n");
				#endif
				}	else
				{
				#if ENABLE_EXP_LOGGING
					call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, 
					QUERY_GET_LOCATION_RESULTS_FORWARDED, reply->qid, SUCCESS, reply->loc);
				#endif
				}
			}
			else{
				if (call SendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAgentLocMsg)) != SUCCESS)
				{
				call MessageBufferI.freeMsg(msg);
				#if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OPgetLocationCM: ReceiveResults.receive: Failed to send QueryReplyAgentLocMsg\n");
				#endif
				}	else
				{
				#if ENABLE_EXP_LOGGING
					call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, 
					QUERY_GET_LOCATION_RESULTS_FORWARDED, reply->qid, SUCCESS, reply->loc);
				#endif
				}
			}
			}
		}
		return m;
	} // ReceiveResults


	/**
	 * Processes the query, if it is a clusterhead. If query cannot be answered, forwards it to the Base Station.
	 * Else, bounces the msg.
	 */
	event message_t* ReceiveRequest.receive(message_t* m, void* payload, uint8_t len)
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		//struct AgillaQueryAgentLocMsg *qMsg = (struct AgillaQueryAgentLocMsg *)m->data;
		AgillaQueryAgentLocMsg *qMsg = (AgillaQueryAgentLocMsg *)payload;
		if(qMsg->dest == TOS_NODE_ID){
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetLocationCM: ReceiveRequest.receive(): Received getAgentLocation Query Msg from %i\n", qMsg->src);
			#endif
			if(call AddressMgrI.isGW() != SUCCESS)
			{
				// query request received
				// make sure that this node is still a clusterhead
				if(call ClusteringI.isClusterHead() != SUCCESS)
				{
					dbg("DBG_USR1", "OPgetLocationCM: ReceiveRequest.receive(): ERROR! Not Clusterhead, but received query from from node %i\n",
						 qMsg->src);
					call MessageBufferI.freeMsg(msg);
					return m;
				}
				// try to resolve the query


				if(call ClusterheadDirectoryI.getAgent(&(qMsg->find_agent_id), &_agentLoc) == SUCCESS)
				{
					// agent was found by the clusterhead
					#if DEBUG_CLUSTERING
						 dbg("DBG_USR1", "OpgetLocationCM: ReceiveRequest.receive(): Found agent %i:[%i,%i] on clusterhead\n",
										 qMsg->find_agent_id.id, _agentLoc.x, _agentLoc.y);
					#endif
					if (sendQueryReplyMsg(msg, qMsg) != SUCCESS)
					{
							call MessageBufferI.freeMsg(msg);
					} else
					{
						#if ENABLE_EXP_LOGGING
						call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, 
							QUERY_GET_LOCATION_RESULTS_FORWARDED, qMsg->qid, SUCCESS, _agentLoc);
						#endif
					}

					return m;
				}
				// agent was not found by the clusterhead
				#if DEBUG_CLUSTERING
					dbg("DBG_USR1", "OpgetLocationCM: ReceiveRequest.receive(): Agent %i was not found\n",
										qMsg->find_agent_id.id);
				#endif
			}

			if(qMsg->src != AM_UART_ADDR){
					// forward query to base station
					qMsg->src = TOS_NODE_ID;
					qMsg->dest = AM_UART_ADDR;
			} else {
				 // query received from base station; drop query
				 call MessageBufferI.freeMsg(msg);
				 return m;
			}
		}
		// forward query to base station
		*msg = *m;
		if (sendQueryMsg(msg, TRUE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
		else
		{
		#if ENABLE_EXP_LOGGING
			//struct AgillaQueryAgentLocMsg *qMsg = (struct AgillaQueryAgentLocMsg *)msg->data;
			AgillaLocation loc;
			call LocationMgrI.getLocation(qMsg->dest, &loc);
			call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, QUERY_GET_LOCATION_FORWARDED, qMsg->qid, SUCCESS, loc);
		#endif
		}
	}
	return m;
	}

	//RECEIVE SERIAL
	event message_t* SerialReceiveRequest.receive(message_t* m, void* payload, uint8_t len)
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		//struct AgillaQueryAgentLocMsg *qMsg = (struct AgillaQueryAgentLocMsg *)m->data;
		AgillaQueryAgentLocMsg *qMsg = (AgillaQueryAgentLocMsg *)payload;
		if(qMsg->dest == TOS_NODE_ID){
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetLocationCM: ReceiveRequest.receive(): Received getAgentLocation Query Msg from %i\n", qMsg->src);
			#endif
			if(call AddressMgrI.isGW() != SUCCESS)
			{
				// query request received
				// make sure that this node is still a clusterhead
				if(call ClusteringI.isClusterHead() != SUCCESS)
				{
					dbg("DBG_USR1", "OPgetLocationCM: ReceiveRequest.receive(): ERROR! Not Clusterhead, but received query from from node %i\n",
						 qMsg->src);
					call MessageBufferI.freeMsg(msg);
					return m;
				}
				// try to resolve the query


				if(call ClusterheadDirectoryI.getAgent(&(qMsg->find_agent_id), &_agentLoc) == SUCCESS)
				{
					// agent was found by the clusterhead
					#if DEBUG_CLUSTERING
						 dbg("DBG_USR1", "OpgetLocationCM: ReceiveRequest.receive(): Found agent %i:[%i,%i] on clusterhead\n",
										 qMsg->find_agent_id.id, _agentLoc.x, _agentLoc.y);
					#endif
					if (sendQueryReplyMsg(msg, qMsg) != SUCCESS)
					{
							call MessageBufferI.freeMsg(msg);
					} else
					{
						#if ENABLE_EXP_LOGGING
						call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, 
							QUERY_GET_LOCATION_RESULTS_FORWARDED, qMsg->qid, SUCCESS, _agentLoc);
						#endif
					}

					return m;
				}
				// agent was not found by the clusterhead
				#if DEBUG_CLUSTERING
					dbg("DBG_USR1", "OpgetLocationCM: ReceiveRequest.receive(): Agent %i was not found\n",
										qMsg->find_agent_id.id);
				#endif
			}

			if(qMsg->src != AM_UART_ADDR){
					// forward query to base station
					qMsg->src = TOS_NODE_ID;
					qMsg->dest = AM_UART_ADDR;
			} else {
				 // query received from base station; drop query
				 call MessageBufferI.freeMsg(msg);
				 return m;
			}
		}
		// forward query to base station
		*msg = *m;
		if (sendQueryMsg(msg, TRUE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
		else
		{
		#if ENABLE_EXP_LOGGING
			//struct AgillaQueryAgentLocMsg *qMsg = (struct AgillaQueryAgentLocMsg *)msg->data;
			AgillaLocation loc;
			call LocationMgrI.getLocation(qMsg->dest, &loc);
			call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, QUERY_GET_LOCATION_FORWARDED, qMsg->qid, SUCCESS, loc);
		#endif
		}
	}
	return m;
	}

	event void SendRequest.sendDone(message_t* m, error_t success)
	{
	#if DEBUG_CLUSTERING
		dbg("DBG_USR1", "OPgetLocationCM: SendRequest.sendDone:Sent QueryAgentLocMsg\n");
	#endif
	call MessageBufferI.freeMsg(m);

	}

	event void SendResults.sendDone(message_t* m, error_t success)
	{
	#if DEBUG_CLUSTERING
		 dbg("DBG_USR1", "OPgetLocationCM: SendResults.sendDone:Sent QueryReplyAgentLocMsg\n");
	#endif
	call MessageBufferI.freeMsg(m);

	}
	
	event void SerialSendRequest.sendDone(message_t* m, error_t success)
	{
	#if DEBUG_CLUSTERING
		dbg("DBG_USR1", "OPgetLocationCM: SendRequest.sendDone:Sent QueryAgentLocMsg\n");
	#endif
	call MessageBufferI.freeMsg(m);

	}

	event void SerialSendResults.sendDone(message_t* m, error_t success)
	{
	#if DEBUG_CLUSTERING
		 dbg("DBG_USR1", "OPgetLocationCM: SendResults.sendDone:Sent QueryReplyAgentLocMsg\n");
	#endif
	call MessageBufferI.freeMsg(m);

	}

}
