// $Id: ReceiveStateM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
#include "MigrationMsgs.h"

module ReceiveStateM {
	uses {
	interface ReceiverCoordinatorI as CoordinatorI;
	interface AgentMgrI;
	interface Receive as Rcv_State;
	interface AMSend as Send_State_Ack;
	interface AMSend as SerialSend_State_Ack;
	interface Receive as SerialRcv_State;
	//interface MessageBufferI;
	interface Leds;	//non usato
	interface Packet;
	}	
}
implementation {
	message_t _ackMsg;
	
	inline void sendStateAck(uint16_t addr, AgillaAgentID *id, uint8_t acpt) {
	//struct AgillaAckStateMsg *aMsg = (struct AgillaAckStateMsg *)_ackMsg.data;
	AgillaAckStateMsg *aMsg = (AgillaAckStateMsg *)(call Packet.getPayload(&_ackMsg, sizeof(AgillaAckStateMsg)));
	aMsg->id = *id;
	aMsg->accept = acpt;
	if(addr == AM_UART_ADDR)
		call SerialSend_State_Ack.send(addr, &_ackMsg, sizeof(AgillaAckStateMsg));
	else
		call Send_State_Ack.send(addr, &_ackMsg, sizeof(AgillaAckStateMsg));
	}
	
	/**
	 * The state message is an implied request.
	 * The data field of the acknowledgement is always 0.
	 */
	event message_t* Rcv_State.receive(message_t* m, void* payload, uint8_t len) {
	AgillaStateMsg* sMsg = (AgillaStateMsg*)payload;
	
	#if DEBUG_AGENT_RECEIVER
	dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: Received STATE for agent id = %i.\n", sMsg->id.id);
	#endif	 
	
	if (call AgentMgrI.isPresent(&sMsg->id) == SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: ERROR: The agent is already running, reject msg.\n");
		#endif				 
		sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_REJECT);	// already here		
		return m;
	}
	
	if (call CoordinatorI.isArriving(&sMsg->id) == SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: The state message was a duplicate, accept msg.\n");
		#endif		 
		call CoordinatorI.restartTimer(&sMsg->id);		 
		sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_ACCEPT);	// duplicate
		return m;
	}
	
	/**
	 * The call to allocateBuffer saves the agent ID in the buffer and
	 * sets its integrity to AGILLA_RECEIVED_STATE.
	 */
	if (call CoordinatorI.allocateBuffer(&sMsg->id, sMsg->codeSize) == SUCCESS) {
		AgillaAgentInfo* inBuf = call CoordinatorI.getBuffer(&sMsg->id);
		if (inBuf != NULL) {			
		inBuf->dest = sMsg->dest;
		inBuf->numHpMsgs = sMsg->numHpMsgs;
		inBuf->nRxnMsgs = sMsg->numRxnMsgs;

		// set the number of code blocks
		inBuf->nCBlocks = sMsg->codeSize / AGILLA_CODE_BLOCK_SIZE;
		if (inBuf->nCBlocks*AGILLA_CODE_BLOCK_SIZE < sMsg->codeSize)
			inBuf->nCBlocks++;

		// set the agent's integrity			
		if (inBuf->numHpMsgs == 0)
			inBuf->integrity |= AGILLA_RECEIVED_HEAP;
		if (inBuf->context->opStack.sp == 0) 
			inBuf->integrity |= AGILLA_RECEIVED_OPSTACK;
		if (inBuf->nRxnMsgs == 0) 
			inBuf->integrity |= AGILLA_RECEIVED_RXN;

		// save the agent state info
		inBuf->context->pc = sMsg->pc;
		inBuf->context->codeSize = sMsg->codeSize;
		inBuf->context->condition = sMsg->condition;
		inBuf->context->opStack.sp = sMsg->sp;
		
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: Received STATE for agent %i, sending ACCEPT ACK back to %i.\n", sMsg->id.id, sMsg->replyAddr);		
		#endif		
		sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_ACCEPT); // acknowledge the message
		
		call CoordinatorI.startAbortTimer(&sMsg->id);
		return m;			
		} else {		
		#if DEBUG_AGENT_RECEIVER
			dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: Could not get incomming buffer, sending REJECT ACK back to %i\n", sMsg->id.id, sMsg->replyAddr);
		#endif			 
		call CoordinatorI.resetBuffer(&sMsg->id);
		}
	} else {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: not enough buffer space, sending REJECT ACK back to %i\n", sMsg->id.id, sMsg->replyAddr);
		#endif								
	}
			 
	sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_REJECT); // no space
	return m;
	} // Rcv_State.receive	

	//RECEIVE SERIAL
	event message_t* SerialRcv_State.receive(message_t* m, void* payload, uint8_t len) {
	AgillaStateMsg* sMsg = (AgillaStateMsg*)payload;
	
	#if DEBUG_AGENT_RECEIVER
	dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: Received STATE for agent id = %i.\n", sMsg->id.id);
	#endif	 
	
	if (call AgentMgrI.isPresent(&sMsg->id) == SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: ERROR: The agent is already running, reject msg.\n");
		#endif				 
		sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_REJECT);	// already here		
		return m;
	}
	
	if (call CoordinatorI.isArriving(&sMsg->id) == SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: The state message was a duplicate, accept msg.\n");
		#endif		 
		call CoordinatorI.restartTimer(&sMsg->id);		 
		sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_ACCEPT);	// duplicate
		return m;
	}
	
	/**
	 * The call to allocateBuffer saves the agent ID in the buffer and
	 * sets its integrity to AGILLA_RECEIVED_STATE.
	 */
	if (call CoordinatorI.allocateBuffer(&sMsg->id, sMsg->codeSize) == SUCCESS) {
		AgillaAgentInfo* inBuf = call CoordinatorI.getBuffer(&sMsg->id);
		if (inBuf != NULL) {			
		inBuf->dest = sMsg->dest;
		inBuf->numHpMsgs = sMsg->numHpMsgs;
		inBuf->nRxnMsgs = sMsg->numRxnMsgs;

		// set the number of code blocks
		inBuf->nCBlocks = sMsg->codeSize / AGILLA_CODE_BLOCK_SIZE;
		if (inBuf->nCBlocks*AGILLA_CODE_BLOCK_SIZE < sMsg->codeSize)
			inBuf->nCBlocks++;

		// set the agent's integrity			
		if (inBuf->numHpMsgs == 0)
			inBuf->integrity |= AGILLA_RECEIVED_HEAP;
		if (inBuf->context->opStack.sp == 0) 
			inBuf->integrity |= AGILLA_RECEIVED_OPSTACK;
		if (inBuf->nRxnMsgs == 0) 
			inBuf->integrity |= AGILLA_RECEIVED_RXN;

		// save the agent state info
		inBuf->context->pc = sMsg->pc;
		inBuf->context->codeSize = sMsg->codeSize;
		inBuf->context->condition = sMsg->condition;
		inBuf->context->opStack.sp = sMsg->sp;
		
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: Received STATE for agent %i, sending ACCEPT ACK back to %i.\n", sMsg->id.id, sMsg->replyAddr);		
		#endif		
		sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_ACCEPT); // acknowledge the message
		
		call CoordinatorI.startAbortTimer(&sMsg->id);
		return m;			
		} else {		
		#if DEBUG_AGENT_RECEIVER
			dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: Could not get incomming buffer, sending REJECT ACK back to %i\n", sMsg->id.id, sMsg->replyAddr);
		#endif			 
		call CoordinatorI.resetBuffer(&sMsg->id);
		}
	} else {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveStateM: Rcv_State.receive: not enough buffer space, sending REJECT ACK back to %i\n", sMsg->id.id, sMsg->replyAddr);
		#endif								
	}
			 
	sendStateAck(sMsg->replyAddr, &sMsg->id, AGILLA_REJECT); // no space
	return m;
	} // Rcv_State.receive 

	event void Send_State_Ack.sendDone(message_t* m, error_t success) { 
	//return SUCCESS; 
	}

	event void SerialSend_State_Ack.sendDone(message_t* m, error_t success) { 
	//return SUCCESS; 
	}
}
