// $Id: OPgetNumAgentsCM.nc,v 1.1 2006/04/11 04:11:45 borndigerati Exp $

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
 * Finds the number of agents of a particular type or of all types, in the system.
 * This is only used when clustering is used.
 *
 * @author Chien-Liang Fok
 * @author Sangeeta Bhattacharya
 */
module OPgetNumAgentsCM {
	provides {
	interface BytecodeI;

	interface Init;
	}
	uses {
	interface NeighborListI;
	interface ClusteringI;
	interface LocationMgrI;
	interface AMSend as SendRequest;
	interface Receive as ReceiveRequest; // for routing
	interface Receive as ReceiveResults;
	interface Receive as SerialReceiveRequest; // for routing
	interface Receive as SerialReceiveResults;
	interface AMSend as SendResults; // for routing
	interface AMSend as SerialSendRequest;
	interface AMSend as SerialSendResults;
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
	 * The type of the agent being searched for.
	 */
	uint16_t _agent_type;

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
	} */

	inline error_t finish(error_t success)
	{
	//_currAgent->condition = (uint16_t)success;	//<-qui
	if(success==SUCCESS) _currAgent->condition=1
		else _currAgent->condition=0
	call AgentMgrI.run(_currAgent);
	_currAgent = NULL;

	// If there are pending agents, execute them
	if (!call QueueI.empty(&waitQueue))
	{
		#if DEBUG_OP_GETNUMAGENTS
		dbg("DBG_USR1", "OPgetNumAgentsCM: finish(): WaitQueue (0x%x) not empty, running next agent.\n", &waitQueue);
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
	if (call AddressMgrI.isGW() == SUCCESS)
	{
		#if DEBUG_OP_GETNUMAGENTS
		dbg("DBG_USR1", "OPgetNumAgentsCM: sendQueryMsg(): Sending query message to the BS\n");
		#endif
		return call SerialSendRequest.send(AM_UART_ADDR, msg, sizeof(AgillaQueryNumAgentsMsg));
	} else
	{
		uint16_t onehop_dest;


		//struct AgillaQueryNumAgentsMsg *qMsg = (struct AgillaQueryNumAgentsMsg *)msg->data;
		AgillaQueryNumAgentsMsg *qMsg = (AgillaQueryNumAgentsMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryNumAgentsMsg)));
		// find onehop_dest as the neighbor that is the closest to the clusterhead
		if(call ClusteringI.isClusterHead() == SUCCESS || bounce){
			// send msg to GW
			 qMsg->dest = AM_UART_ADDR;
			if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
			{
			 dbg("DBG_USR1", "OPgetNumAgentsCM: sendQueryMsg(): ERROR: No neighbor closer to gateway.\n");
			 return FAIL;
			}
			#if DEBUG_CLUSTERING
			 dbg("DBG_USR1", "OPgetNumAgentsCM: SendQueryMsg(): QueryNumAgents msg being sent by CH or being bounced to GW via %i!\n", onehop_dest);
			#endif
		} else {
			// send to clusterhead, which should be a neighbor
			if (call ClusteringI.getClusterHead(&onehop_dest) != SUCCESS)
			{
			 dbg("DBG_USR1", "OPgetNumAgentsCM: SendQueryMsg(): ERROR: Cluster head could not be obtained.\n");
			 return FAIL;
			}
			qMsg->dest = onehop_dest;
			#if DEBUG_CLUSTERING
			dbg("DBG_USR1", "OPgetNumAgentsCM: SendQueryMsg(): QueryNumAgents msg being sent to CH %i\n", onehop_dest);
			#endif
		}

		if(onehop_dest == AM_UART_ADDR)
		return call SerialSendRequest.send(onehop_dest, msg, sizeof(AgillaQueryNumAgentsMsg));
		else
		return call SendRequest.send(onehop_dest, msg, sizeof(AgillaQueryNumAgentsMsg));
	}
	} // sendQueryMsg()

	/**
	 * Starts the sending of a location update message.
	 */
	task void doSendQuery()
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
		{
		//struct AgillaQueryNumAgentsMsg *qMsg = (struct AgillaQueryNumAgentsMsg *)msg->data;
		AgillaQueryNumAgentsMsg *qMsg = (AgillaQueryNumAgentsMsg *)(call Packet.getPayload(msg, sizeof(AgillaQueryNumAgentsMsg)));
		qMsg->agent_id = _currAgent->id;
		qMsg->agent_type = _agent_type;
		qMsg->src = TOS_NODE_ID;
		qMsg->dest = AM_UART_ADDR;
		qMsg->qid = ((TOS_NODE_ID & 0xff) << 8) | _qid++;
		qMsg->flags = 0;

		if (sendQueryMsg(msg, FALSE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
		else
		call Timeout.startOneShot(TIMEOUT_GET_NUM_AGENTS);
	}
	} // task doSendQuery()

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
		#if DEBUG_OP_GETNUMAGENTS
		dbg("DBG_USR1", "OPgetNumAgentsCM: execute(): Another agent is performing a directory operation, waiting...\n");
		#endif

		context->pc--;
		return call QueueI.enqueue(context, &waitQueue, context);
	} else
	{

		AgillaVariable var;

		dbg("DBG_USR1", "VM (%i:%i): OPgetNumAgentsCM: Executing OPgetNumAgents.\n", context->id.id, context->pc-1);
		_currAgent = context;



		// Get the type of agent being searched for
		if (call OpStackI.popOperand(_currAgent, &var) == SUCCESS)
		{
			if (var.vtype & AGILLA_VAR_V){
			_agent_type = var.value.value;
			} else
			{
			dbg("DBG_USR1", "VM (%i:%i): OPgetNumAgentsCM: ERROR: Invalid agent_type parameter type [%i].\n",
				_currAgent->id.id, _currAgent->pc-1, var.vtype);
			call ErrorMgrI.error2d(_currAgent, AGILLA_ERROR_INVALID_TYPE, 0x14, var.vtype);
			return finish(FAIL);
			}
		} else
		{
			dbg("DBG_USR1", "VM (%i:%i): OPgetNumAgentsCM: ERROR: Could not pop parameter off stack.\n",
			_currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		}



		if (post doSendQuery() != SUCCESS)
		finish(FAIL);
		return SUCCESS;
	}
	} // BytecodeI.execute



	event message_t* ReceiveResults.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaQueryReplyNumAgentsMsg* reply = (AgillaQueryReplyNumAgentsMsg*)payload;

		if (reply->dest == TOS_NODE_ID && reply->dest == (reply->qid >> 8))
		{
		 if(_currAgent != NULL && _currAgent->id.id == reply->agent_id.id)
		 {
			 #if DEBUG_OP_GETNUMAGENTS
				dbg("DBG_USR1", "OPgetNumAgentsCM: Received Results num agents = %i.\n", reply->num_agents);
				#endif

				call Timeout.stop();

				call OpStackI.pushValue(_currAgent, reply->num_agents);
				finish(SUCCESS);
		}

		} else
		{

		 message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
			uint16_t oneHopDest;

			if (reply->dest == TOS_NODE_ID){
				//oneHopDest = TOS_BCAST_ADDR;
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
			dbg("DBG_USR1", "OPgetNumAgentsCM: ReceiveResults.receive: Forwarding result %i to %i\n",
												reply->num_agents, oneHopDest);
			#endif

			*msg = *m;
			if(oneHopDest == AM_UART_ADDR){
			if (call SerialSendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyNumAgentsMsg)) != SUCCESS)
				call MessageBufferI.freeMsg(msg);
			}
			else
			{
			if (call SendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyNumAgentsMsg)) != SUCCESS)
				call MessageBufferI.freeMsg(msg);
			}
		}
		}
		return m;
	} // ReceiveResults

	//RECEIVE SERIAL
	event message_t* SerialReceiveResults.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaQueryReplyNumAgentsMsg* reply = (AgillaQueryReplyNumAgentsMsg*)payload;

		if (reply->dest == TOS_NODE_ID && reply->dest == (reply->qid >> 8))
		{
		 if(_currAgent != NULL && _currAgent->id.id == reply->agent_id.id)
		 {
			 #if DEBUG_OP_GETNUMAGENTS
				dbg("DBG_USR1", "OPgetNumAgentsCM: Received Results num agents = %i.\n", reply->num_agents);
				#endif

				call Timeout.stop();

				call OpStackI.pushValue(_currAgent, reply->num_agents);
				finish(SUCCESS);
		}

		} else
		{

		 message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
			uint16_t oneHopDest;

			if (reply->dest == TOS_NODE_ID){
				//oneHopDest = TOS_BCAST_ADDR;
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
			dbg("DBG_USR1", "OPgetNumAgentsCM: ReceiveResults.receive: Forwarding result %i to %i\n",
												reply->num_agents, oneHopDest);
			#endif

			*msg = *m;
			if(oneHopDest == AM_UART_ADDR){
			if (call SerialSendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyNumAgentsMsg)) != SUCCESS)
				call MessageBufferI.freeMsg(msg);
			}
			else
			{
			if (call SendResults.send(oneHopDest, msg, sizeof(AgillaQueryReplyNumAgentsMsg)) != SUCCESS)
				call MessageBufferI.freeMsg(msg);
			}
		}
		}
		return m;
	} // ReceiveResults


	event void Timeout.fired()
	{
	#if DEBUG_OP_GETNUMAGENTS
		dbg("DBG_USR1", "OPgetNumAgentsCM: ERROR: Timed out while waiting for results.\n");
	#endif
	finish(FAIL);
	 // return SUCCESS;
	}

	/**
	 * Bounces a message off this mote.
	 */
	event message_t* ReceiveRequest.receive(message_t* m, void* payload, uint8_t len)
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{

		//struct AgillaQueryNumAgentsMsg *qMsg = (struct AgillaQueryNumAgentsMsg *)m->data;
		AgillaQueryNumAgentsMsg *qMsg = (AgillaQueryNumAgentsMsg *)payload;
		if(qMsg->dest == TOS_NODE_ID){
			// make sure that this node is still a clusterhead
			if(call ClusteringI.isClusterHead() != SUCCESS){
				dbg("DBG_USR1", "OPgetNumAgentsCM: ReceiveRequest.receive(): ERROR! Not Clusterhead, but received query from from node %i\n",
					 qMsg->src);
				call MessageBufferI.freeMsg(msg);
				return m;
			}
			qMsg->src = TOS_NODE_ID;
		}

		*msg = *m;
		if (sendQueryMsg(msg, TRUE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
	}
	return m;
	}

	//RECEIVE SERIAL
	event message_t* SerialReceiveRequest.receive(message_t* m, void* payload, uint8_t len)
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{

		//struct AgillaQueryNumAgentsMsg *qMsg = (struct AgillaQueryNumAgentsMsg *)m->data;
		AgillaQueryNumAgentsMsg *qMsg = (AgillaQueryNumAgentsMsg *)payload;
		if(qMsg->dest == TOS_NODE_ID){
			// make sure that this node is still a clusterhead
			if(call ClusteringI.isClusterHead() != SUCCESS){
				dbg("DBG_USR1", "OPgetNumAgentsCM: ReceiveRequest.receive(): ERROR! Not Clusterhead, but received query from from node %i\n",
					 qMsg->src);
				call MessageBufferI.freeMsg(msg);
				return m;
			}
			qMsg->src = TOS_NODE_ID;
		}

		*msg = *m;
		if (sendQueryMsg(msg, TRUE) != SUCCESS)
		call MessageBufferI.freeMsg(msg);
	}
	return m;
	}

	event void SendRequest.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}

	event void SendResults.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}

	 event void SerialSendRequest.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}

	event void SerialSendResults.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}

}
