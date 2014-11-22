// $Id: OPgetAgentsCM.nc,v 1.2 2006/04/15 05:33:52 borndigerati Exp $

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
 * Finds gets the ID and location of all agents in the sensor network.
 *
 * @author Chien-Liang Fok
 */
module OPgetAgentsCM {
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
	 * Holds pending agents that are waiting for the current agent
	 * to finish.
	 */
	Queue waitQueue;

	/**
	 * A running counter for the query id.
	 */
	uint8_t _qid;

	/**
	 * The maximum number of agents in the response.
	 */
	int16_t _max;

	/**
	 * The number of agents in the response.
	 */
	int16_t _num_agents;

	/**
	 * The type of the agent being searched for.
	 */
	uint16_t _agent_type;

	/*
	 * Array of the agent is and location
	 */
	AgillaLocMAgentInfo _agentList[MAX_AGENT_ARRAY_NUM];

	/*
	 * Number of elements in the array
	 */
	uint8_t _numAgents;

	/*
	 * Index pointing to the next element in the agent array to be read
	 */
	uint8_t _index;

	/*
	 * Set to true if the node is a clusterhead and is processing a query
	 */
	bool _processingQuery;

	/*
	 * The query msg that is currently being processed is stored here
	 */
	AgillaQueryAllAgentsMsg _savedQueryMsg;


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
	_numAgents = 0;
	_processingQuery = FALSE;
	_index = 0;
	call QueueI.init(&waitQueue);
	return SUCCESS;
	}

 /* command error_t StdControl.start() {	
	return SUCCESS;
	}

	command error_t StdControl.stop() {	
	return SUCCESS;
	}	*/

	/**************************************************************/
	/*						Helper methods						*/
	/**************************************************************/

	inline error_t finish(error_t success)
	{

	 #if ENABLE_EXP_LOGGING
		 if (success == SUCCESS) {
			 #ifdef _H_msp430hardware_h
			 _start = call LocalTime.get() - _start;
			 #else
			 _start = 0;
			 #endif
		 } else {
			 _start = 0;
		 }
		 call ExpLoggerI.sendQueryLatency(_start);
	#endif


	 //_currAgent->condition = (uint16_t)success;
	if(success==SUCCESS) _currAgent->condition=1
		else _currAgent->condition=0
	call AgentMgrI.run(_currAgent);
	_currAgent = NULL;

	// If there are pending agents, execute them
	if (!call QueueI.empty(&waitQueue))
	{
		#if DEBUG_OP_GET_AGENTS
		dbg("DBG_USR1", "OPgetAgentsCM: finish(): WaitQueue (0x%x) not empty, running next agent.\n", &waitQueue);
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
	/*if (call AddressMgrI.isGW() == SUCCESS)
	{
		#if DEBUG_OP_GET_AGENTS
		dbg("DBG_USR1", "OPgetAgentsM: sendQueryMsg(): Sending query message to the BS\n");
		#endif
		return call SerialSendRequest.send(AM_UART_ADDR, msg, sizeof(AgillaQueryAllAgentsMsg));
	} else
	{*/
		uint16_t onehop_dest;

	 //struct AgillaQueryAllAgentsMsg *qMsg = (struct AgillaQueryAllAgentsMsg *)msg->data;
		AgillaQueryAllAgentsMsg *qMsg = (AgillaQueryAllAgentsMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryAllAgentsMsg)));

		 // find onehop_dest as the neighbor that is the closest to the clusterhead
		 if(bounce){
			 onehop_dest = qMsg->dest;

			 #if ENABLE_GRID_ROUTING
				 call NeighborListI.getClosestNeighbor(&onehop_dest);
			 #endif
			 #if DEBUG_CLUSTERING
				 dbg("DBG_USR1", "OPgetAgentsCM: SendQueryMsg(): QueryAllAgents msg being bounced to %i via %i\n", qMsg->dest, onehop_dest);
			 #endif
		 } else if(call ClusteringI.isClusterHead() == SUCCESS){
			 // send msg to GW

			 if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
			 {
				dbg("DBG_USR1", "OPgetAgentsCM: sendQueryMsg(): ERROR: No neighbor closer to gateway.\n");
				return FAIL;
			 }
			 #if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetAgentsCM: SendQueryMsg(): QueryAllAgents msg being sent by CH or being bounced to GW via %i!\n", onehop_dest);
			 #endif
		 } else {
			 // send to clusterhead, which should be a neighbor
			 if (call ClusteringI.getClusterHead(&onehop_dest) != SUCCESS)
			 {
				dbg("DBG_USR1", "OPgetAgentsCM: SendQueryMsg(): ERROR: Cluster head could not be obtained.\n");
				return FAIL;
			 }
			 qMsg->dest = onehop_dest;
			 #if DEBUG_CLUSTERING
			 dbg("DBG_USR1", "OPgetAgentsCM: SendQueryMsg(): QueryAllAgents msg being sent to CH %i\n", onehop_dest);
			 #endif
		}
		if(onehop_dest == AM_UART_ADDR)	
		return call SerialSendRequest.send(onehop_dest, msg, sizeof(AgillaQueryAllAgentsMsg));
		else
		return call SendRequest.send(onehop_dest, msg, sizeof(AgillaQueryAllAgentsMsg));
	/*}*/
	} // sendQueryMsg()

	/**
	 * Starts the sending of a location update message.
	 */
	task void doSendQuery()
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		//struct AgillaQueryAllAgentsMsg *qMsg = (struct AgillaQueryAllAgentsMsg *)msg->data;
		AgillaQueryAllAgentsMsg *qMsg = (AgillaQueryAllAgentsMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryAllAgentsMsg)));
		qMsg->agent_id = _currAgent->id;
		qMsg->src = TOS_NODE_ID;
		qMsg->dest = AM_UART_ADDR;
		qMsg->qid = ((TOS_NODE_ID & 0xff) << 8) | _qid++;
		qMsg->agent_type = _agent_type;
		if (sendQueryMsg(msg, FALSE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
		else {
		#if ENABLE_EXP_LOGGING
			AgillaLocation loc;
			loc.x = loc.y = 0;
			call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_AGENTS_ISSUED, qMsg->qid, qMsg->agent_type, loc);
			#ifdef _H_msp430hardware_h
				_start = call LocalTime.get();
			#else
				_start = 0;
			#endif
		#endif
		call Timeout.startOneShot(TIMEOUT_GET_NUM_AGENTS);
		}
	}
	} // task doSendQuery()


	/*
	 * Sends the query reply message
	 */
	task void sendQueryReplyMsg()
	{
	message_t* msg = call MessageBufferI.getMsg();
	if(msg != NULL && _processingQuery && _index < MAX_AGENT_ARRAY_NUM)
	{
		//struct AgillaQueryReplyAllAgentsMsg *replyMsg = (struct AgillaQueryReplyAllAgentsMsg *)msg->data;
		AgillaQueryReplyAllAgentsMsg *replyMsg = (AgillaQueryReplyAllAgentsMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryReplyAllAgentsMsg)));
		uint16_t onehop_dest;
		uint8_t i = 0, size = 0;

		replyMsg->agent_id = _savedQueryMsg.agent_id;
		replyMsg->dest = _savedQueryMsg.src;
		replyMsg->src = TOS_NODE_ID;
		replyMsg->qid = _savedQueryMsg.qid;
		replyMsg->num_agents = _numAgents;

		if(_numAgents > MAX_AGENT_NUM) {
			size = MAX_AGENT_NUM;
			_numAgents = _numAgents - size;
		} else {
			size = _numAgents;
			_numAgents = 0;
		}
		// fill out the array containing agent id and location
		for(i = 0; i < size && _index < MAX_AGENT_ARRAY_NUM; i++){
			replyMsg->agent_info[i] = _agentList[_index++];
		}
		#if DEBUG_CLUSTERING
		 dbg("DBG_USR1", "OPgetAgentsCM: SendQueryReplyMsg(): reply dest = %i\n", replyMsg->dest);
		#endif
		onehop_dest = _savedQueryMsg.src;
		if(onehop_dest == AM_UART_ADDR)
		{ // this should always be true for this query
		if (call NeighborListI.getGW(&onehop_dest) != NO_GW)
		{
			 #if DEBUG_CLUSTERING
				 dbg("DBG_USR1", "OPgetAgentsCM: SendQueryReplyMsg(): Sending query reply to query %i containing %i agents to %i\n",
						replyMsg->qid, size, onehop_dest);
			 #endif
			 if(onehop_dest == AM_UART_ADDR){
				 if(call SerialSendResults.send(onehop_dest, msg, sizeof(AgillaQueryReplyAllAgentsMsg)) == SUCCESS){

					 return;
				 } else {
					 #if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OPgetAgentsCM: SendQueryReplyMsg(): ERROR: Failed to send query reply msg!\n");
					 #endif
				 }
			 }
			 else
			 {
				 if(call SendResults.send(onehop_dest, msg, sizeof(AgillaQueryReplyAllAgentsMsg)) == SUCCESS){

					 return;
				 } else {
					 #if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OPgetAgentsCM: SendQueryReplyMsg(): ERROR: Failed to send query reply msg!\n");
					 #endif
				 }
			 }

		} else {
			dbg("DBG_USR1", "OPgetAgentsCM: sendQueryReplyMsg(): ERROR: No neighbor closer to gateway.\n");
		}
		} else {
			#if DEBUG_CLUSTERING
			dbg("DBG_USR1", "OPgetAgentsCM: SendQueryReplyMsg(): ERROR: query reply msg is not destined for BS!\n");
			#endif
		}
	} else {
		#if DEBUG_CLUSTERING
			dbg("DBG_USR1", "OPgetAgentsCM: SendQueryReplyMsg(): ERROR: msg is NULL or not processing query or index out of bounds!\n");
		#endif
	}

	call MessageBufferI.freeMsg(msg);
	_numAgents = 0;
	_index = 0;
	_processingQuery = FALSE;
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
		#if DEBUG_OP_GET_AGENTS
		dbg("DBG_USR1", "OPgetAgentsCM: execute(): Another agent is performing a directory operation, waiting...\n");
		#endif

		context->pc--;
		return call QueueI.enqueue(context, &waitQueue, context);
	} else
	{
		AgillaVariable var;

		dbg("DBG_USR1", "VM (%i:%i): Executing OPgetAllAgents.\n", context->id.id, context->pc-1);
		_currAgent = context;
		_num_agents = 0;

		// Get the max number of results
		if (call OpStackI.popOperand(_currAgent, &var) == SUCCESS)
		{
		if (var.vtype & AGILLA_VAR_V)
			_max = var.value.value;
		else
		{
			dbg("DBG_USR1", "VM (%i:%i): OPgetAgentsCM: ERROR: Invalid first parameter type [%i].\n",
			_currAgent->id.id, _currAgent->pc-1, var.vtype);
			call ErrorMgrI.error2d(_currAgent, AGILLA_ERROR_INVALID_TYPE, 0x13, var.vtype);
			return finish(FAIL);
		}
		} else
		{
		dbg("DBG_USR1", "VM (%i:%i): OPgetAgentsCM: ERROR: Could not pop parameter off stack.\n",
			_currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);
		}

		// Get the type of agent being searched for
		if (call OpStackI.popOperand(_currAgent, &var) == SUCCESS)
		{
		if (var.vtype & AGILLA_VAR_V)
			_agent_type = var.value.value;
		else
		{
			dbg("DBG_USR1", "VM (%i:%i): OPgetAgentsCM: ERROR: Invalid second parameter type [%i].\n",
			_currAgent->id.id, _currAgent->pc-1, var.vtype);
			call ErrorMgrI.error2d(_currAgent, AGILLA_ERROR_INVALID_TYPE, 0x14, var.vtype);
			return finish(FAIL);
		}
		} else
		{
		dbg("DBG_USR1", "VM (%i:%i): OPgetAgentsCM: ERROR: Could not pop parameter off stack.\n",
			_currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);
		}

		// send query to BS

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
		 loc.x = loc.y = 0;
		 call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULT_RECEIVED,
				((TOS_NODE_ID & 0xff) << 8) | (_qid-1), FAIL, loc);
	#endif

	#if DEBUG_OP_GET_AGENTS
		dbg("DBG_USR1", "OPgetAgentsCM: ERROR: Timed out while waiting for results.\n");
	#endif

	if(_max == _num_agents) finish(SUCCESS);
	else finish(FAIL);

	}

	/**************************************************************/
	/*				Message Handlers							*/
	/**************************************************************/


	/**
	 * Bounces a message off this mote.
	 */
	event message_t* ReceiveResults.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaQueryReplyAllAgentsMsg* reply = (AgillaQueryReplyAllAgentsMsg*)payload;

	if(reply->dest == TOS_NODE_ID && reply->dest == (reply->qid >> 8))
	{
		if(_currAgent != NULL && _currAgent->id.id == reply->agent_id.id)
		{
			uint16_t i, cnAgents;

			#if DEBUG_OP_GET_AGENTS
				dbg("DBG_USR1", "OPgetAgentsCM: Received Results ID = %i, num_agents = %i\n",
				reply->agent_id.id, reply->num_agents);
			#endif

			call Timeout.stop();

			cnAgents = reply->num_agents;
			if (reply->num_agents > MAX_AGENT_NUM)
				cnAgents = MAX_AGENT_NUM;

			// push the results onto the stack
			for (i = 0; i < cnAgents; i++)
			{
				if (_num_agents < _max)
				{
				#if DEBUG_OP_GET_AGENTS
					dbg("DBG_USR1", "\tagent_info[%i].loc = (%i, %i)\n", i, reply->agent_info[i].loc.x, reply->agent_info[i].loc.y);
					dbg("DBG_USR1", "\tagent_info[%i].agentid = %i\n", i, reply->agent_info[i].agent_id.id);
				#endif
				call OpStackI.pushLocation(_currAgent, &reply->agent_info[i].loc);
				call OpStackI.pushAgentID(_currAgent, &reply->agent_info[i].agent_id);
				_num_agents++;
				}
			}

			#if ENABLE_EXP_LOGGING
				call ExpLoggerI.sendGetAgentsResultsTrace(reply);
			#endif
			// See if there are more results expected
			if (reply->num_agents <= MAX_AGENT_NUM || _max == _num_agents)
			{
				#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULT_RECEIVED,
					((TOS_NODE_ID & 0xff) << 8) | (_qid-1), SUCCESS, loc);
				#endif
				call OpStackI.pushValue(_currAgent, _num_agents);
				finish(SUCCESS);
			} else {
				call Timeout.startOneShot(TIMEOUT_GET_NUM_AGENTS);
			}
		}

	} else
	{
		// forward the results to the node closest to the destination
		message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
		uint16_t oneHopDest;

		if (reply->dest == TOS_NODE_ID){
			// broadcast the result to the cluster member
			//oneHopDest = AM_BROADCAST_ADDR;
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
		 dbg("DBG_USR1", "OPgetAgentsCM: ReceiveResults.receive: Forwarding result containing %i agents to %i\n",
						reply->num_agents, oneHopDest);
		#endif

		*msg = *m;
		if(oneHopDest == AM_UART_ADDR){
			if (call SerialSendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAllAgentsMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			else {
			#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED, reply->qid, SUCCESS, loc);
			#endif
			}
		}
		else
		{
		if (call SendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAllAgentsMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			else {
			#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED, reply->qid, SUCCESS, loc);
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
	AgillaQueryReplyAllAgentsMsg* reply = (AgillaQueryReplyAllAgentsMsg*)payload;

	if(reply->dest == TOS_NODE_ID && reply->dest == (reply->qid >> 8))
	{
		if(_currAgent != NULL && _currAgent->id.id == reply->agent_id.id)
		{
			uint16_t i, cnAgents;

			#if DEBUG_OP_GET_AGENTS
				dbg("DBG_USR1", "OPgetAgentsCM: Received Results ID = %i, num_agents = %i\n",
				reply->agent_id.id, reply->num_agents);
			#endif

			call Timeout.stop();

			cnAgents = reply->num_agents;
			if (reply->num_agents > MAX_AGENT_NUM)
				cnAgents = MAX_AGENT_NUM;

			// push the results onto the stack
			for (i = 0; i < cnAgents; i++)
			{
				if (_num_agents < _max)
				{
				#if DEBUG_OP_GET_AGENTS
					dbg("DBG_USR1", "\tagent_info[%i].loc = (%i, %i)\n", i, reply->agent_info[i].loc.x, reply->agent_info[i].loc.y);
					dbg("DBG_USR1", "\tagent_info[%i].agentid = %i\n", i, reply->agent_info[i].agent_id.id);
				#endif
				call OpStackI.pushLocation(_currAgent, &reply->agent_info[i].loc);
				call OpStackI.pushAgentID(_currAgent, &reply->agent_info[i].agent_id);
				_num_agents++;
				}
			}

			#if ENABLE_EXP_LOGGING
				call ExpLoggerI.sendGetAgentsResultsTrace(reply);
			#endif
			// See if there are more results expected
			if (reply->num_agents <= MAX_AGENT_NUM || _max == _num_agents)
			{
				#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(_currAgent->id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULT_RECEIVED,
					((TOS_NODE_ID & 0xff) << 8) | (_qid-1), SUCCESS, loc);
				#endif
				call OpStackI.pushValue(_currAgent, _num_agents);
				finish(SUCCESS);
			} else {
				call Timeout.startOneShot(TIMEOUT_GET_NUM_AGENTS);
			}
		}

	} else
	{
		// forward the results to the node closest to the destination
		message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
		uint16_t oneHopDest;

		if (reply->dest == TOS_NODE_ID){
			// broadcast the result to the cluster member
			//oneHopDest = AM_BROADCAST_ADDR;
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
		 dbg("DBG_USR1", "OPgetAgentsCM: ReceiveResults.receive: Forwarding result containing %i agents to %i\n",
						reply->num_agents, oneHopDest);
		#endif

		*msg = *m;
		if(oneHopDest == AM_UART_ADDR){
			if (call SerialSendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAllAgentsMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			else {
			#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED, reply->qid, SUCCESS, loc);
			#endif
			}
		}
		else
		{
		if (call SendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyAllAgentsMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			else {
			#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED, reply->qid, SUCCESS, loc);
			#endif
			}
		}
		}
	}
	return m;
	} // ReceiveResults

	/**
	 * Bounces the msg towards the msg destination. If the msg is for this node, it processes the query
	 * and sends the results..
	 */
	event message_t* ReceiveRequest.receive(message_t* m, void* payload, uint8_t len)
	{
	// right now just processes one query at a time, and drops subsequent ones

	if (!_processingQuery)	
	{

		message_t* msg;
		//struct AgillaQueryAllAgentsMsg *qMsg = (struct AgillaQueryAllAgentsMsg *)m->data;
		AgillaQueryAllAgentsMsg *qMsg = (AgillaQueryAllAgentsMsg *)payload;
		if(qMsg->dest == TOS_NODE_ID)
		{
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetAgentsCM: ReceiveRequest.receive(): Received AllAgentsQueryMsg from %i\n", qMsg->src);
			#endif
			if(call ClusteringI.isClusterHead() != SUCCESS)
			{
				dbg("DBG_USR1", "OPgetAgentsCM: ReceiveRequest.receive(): ERROR! Not Clusterhead, but received query from from node %i\n",
					 qMsg->src);
				return m;
			}
			// process it if it is from the BS else bounce it
			if(qMsg->src == AM_UART_ADDR)
			{
				_processingQuery = TRUE;
				if(call ClusterheadDirectoryI.getAllAgents(_agentList, &_numAgents, &(qMsg->agent_type)) == SUCCESS)
				{
				// clusterhead found agents to report
				#if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OpgetAgentsCM: ReceiveRequest.receive(): Found %i agents\n", _numAgents);
				#endif
				_savedQueryMsg = *qMsg;
				if (post sendQueryReplyMsg() != SUCCESS)
				{
						_processingQuery = FALSE;
						_index = 0;
						_numAgents = 0;
				} else {
					#if ENABLE_EXP_LOGGING
					AgillaLocation loc;
					loc.x = loc.y = 0;
					call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED,
							qMsg->qid, SUCCESS, loc);
					#endif
				}
				return m;
				}
			} else {
				// forward query to base station
				qMsg->src = TOS_NODE_ID;
				qMsg->dest = AM_UART_ADDR;
			}
		}
		msg = call MessageBufferI.getMsg();
		if(msg != NULL){
			*msg = *m;
			if (sendQueryMsg(msg, TRUE) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			else {
			#if ENABLE_EXP_LOGGING
				//struct AgillaQueryAllAgentsMsg *qMsg = (struct AgillaQueryAllAgentsMsg *)msg->data;
				AgillaLocation loc;
				call LocationMgrI.getLocation(qMsg->dest, &loc);
				call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED,
					qMsg->qid, SUCCESS, loc);
			#endif
			}
		}
	} else {
		dbg("DBG_USR1", "OPgetAgentsCM: ReceiveRequest.receive(): Dropping query!\n");
	}
	return m;
	}

	//RECEIVE SERIAL
	event message_t* SerialReceiveRequest.receive(message_t* m, void* payload, uint8_t len)
	{
	// right now just processes one query at a time, and drops subsequent ones

	if (!_processingQuery)	
	{

		message_t* msg;
		//struct AgillaQueryAllAgentsMsg *qMsg = (struct AgillaQueryAllAgentsMsg *)m->data;
		AgillaQueryAllAgentsMsg *qMsg = (AgillaQueryAllAgentsMsg *)payload;
		if(qMsg->dest == TOS_NODE_ID)
		{
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetAgentsCM: ReceiveRequest.receive(): Received AllAgentsQueryMsg from %i\n", qMsg->src);
			#endif
			if(call ClusteringI.isClusterHead() != SUCCESS)
			{
				dbg("DBG_USR1", "OPgetAgentsCM: ReceiveRequest.receive(): ERROR! Not Clusterhead, but received query from from node %i\n",
					 qMsg->src);
				return m;
			}
			// process it if it is from the BS else bounce it
			if(qMsg->src == AM_UART_ADDR)
			{
				_processingQuery = TRUE;
				if(call ClusterheadDirectoryI.getAllAgents(_agentList, &_numAgents, &(qMsg->agent_type)) == SUCCESS)
				{
				// clusterhead found agents to report
				#if DEBUG_CLUSTERING
					 dbg("DBG_USR1", "OpgetAgentsCM: ReceiveRequest.receive(): Found %i agents\n", _numAgents);
				#endif
				_savedQueryMsg = *qMsg;
				if (post sendQueryReplyMsg() != SUCCESS)
				{
						_processingQuery = FALSE;
						_index = 0;
						_numAgents = 0;
				} else {
					#if ENABLE_EXP_LOGGING
					AgillaLocation loc;
					loc.x = loc.y = 0;
					call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED,
							qMsg->qid, SUCCESS, loc);
					#endif
				}
				return m;
				}
			} else {
				// forward query to base station
				qMsg->src = TOS_NODE_ID;
				qMsg->dest = AM_UART_ADDR;
			}
		}
		msg = call MessageBufferI.getMsg();
		if(msg != NULL){
			*msg = *m;
			if (sendQueryMsg(msg, TRUE) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			else {
			#if ENABLE_EXP_LOGGING
				//struct AgillaQueryAllAgentsMsg *qMsg = (struct AgillaQueryAllAgentsMsg *)msg->data;
				AgillaLocation loc;
				call LocationMgrI.getLocation(qMsg->dest, &loc);
				call ExpLoggerI.sendTraceQid(qMsg->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED,
					qMsg->qid, SUCCESS, loc);
			#endif
			}
		}
	} else {
		dbg("DBG_USR1", "OPgetAgentsCM: ReceiveRequest.receive(): Dropping query!\n");
	}
	return m;
	}

	event void SendRequest.sendDone(message_t* m, error_t success)
	{
	#if DEBUG_CLUSTERING
		dbg("DBG_USR1", "OPgetAgentsCM: SendRequest.sendDone: Sent QueryAllAgentsMsg\n");
	#endif
	call MessageBufferI.freeMsg(m);

	}

	event void SendResults.sendDone(message_t* m, error_t success)
	{
	AgillaQueryReplyAllAgentsMsg* reply = (AgillaQueryReplyAllAgentsMsg*)(call Packet.getPayload(m, sizeof(AgillaQueryReplyAllAgentsMsg)));
	call MessageBufferI.freeMsg(m);
	#if DEBUG_CLUSTERING
		dbg("DBG_USR1", "OPgetAgentsCM: SendResults.sendDone:Sent QueryReplyAllAgentsMsg\n");
	#endif
	if(reply->src == TOS_NODE_ID){
		// this node sent the result; check if there are more results to send!
		if(_numAgents > 0){
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetAgentsCM: SendResults.sendDone: Still have %i agent info to send\n", _numAgents);
			#endif
			if (post sendQueryReplyMsg() != SUCCESS)
			{
					_processingQuery = FALSE;
					_index = 0;
					_numAgents = 0;
			} else {
				#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED,
						reply->qid, SUCCESS, loc);
				#endif
			 }
		} else {
			_index = 0;
			_numAgents = 0;
			_processingQuery = FALSE;
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetAgentsCM: SendResults.sendDone: Completed sending all agent information\n");
			#endif
		}
	}
	//return SUCCESS;
	}

	event void SerialSendRequest.sendDone(message_t* m, error_t success)
	{
	#if DEBUG_CLUSTERING
		dbg("DBG_USR1", "OPgetAgentsCM: SendRequest.sendDone: Sent QueryAllAgentsMsg\n");
	#endif
	call MessageBufferI.freeMsg(m);

	}

	event void SerialSendResults.sendDone(message_t* m, error_t success)
	{
	AgillaQueryReplyAllAgentsMsg* reply = (AgillaQueryReplyAllAgentsMsg*)(call Packet.getPayload(m, sizeof(AgillaQueryReplyAllAgentsMsg)));
	call MessageBufferI.freeMsg(m);
	#if DEBUG_CLUSTERING
		dbg("DBG_USR1", "OPgetAgentsCM: SendResults.sendDone:Sent QueryReplyAllAgentsMsg\n");
	#endif
	if(reply->src == TOS_NODE_ID){
		// this node sent the result; check if there are more results to send!
		if(_numAgents > 0){
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetAgentsCM: SendResults.sendDone: Still have %i agent info to send\n", _numAgents);
			#endif
			if (post sendQueryReplyMsg() != SUCCESS)
			{
					_processingQuery = FALSE;
					_index = 0;
					_numAgents = 0;
			} else {
				#if ENABLE_EXP_LOGGING
				AgillaLocation loc;
				loc.x = loc.y = 0;
				call ExpLoggerI.sendTraceQid(reply->agent_id.id, TOS_NODE_ID, QUERY_GET_AGENTS_RESULTS_FORWARDED,
						reply->qid, SUCCESS, loc);
				#endif
			 }
		} else {
			_index = 0;
			_numAgents = 0;
			_processingQuery = FALSE;
			#if DEBUG_CLUSTERING
				dbg("DBG_USR1", "OPgetAgentsCM: SendResults.sendDone: Completed sending all agent information\n");
			#endif
		}
	}
	//return SUCCESS;
	}

}
