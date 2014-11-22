// $Id: ReceiveHeapM.nc,v 1.2 2006/01/06 01:16:30 chien-liang Exp $

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

/**
 * Receives the heap of an incomming agent.
 *
 * @author Chien-Liang Fok
 */
module ReceiveHeapM {
	uses {
	interface ReceiverCoordinatorI as CoordinatorI;
	interface HeapMgrI;
	interface Receive as Rcv_Heap;
	interface AMSend as Send_Heap_Ack;
	interface Receive as SerialRcv_Heap;
	interface AMSend as SerialSend_Heap_Ack;
	interface MessageBufferI;
	interface Packet;
	}	
}
implementation {
	
	inline void sendHeapAck(uint16_t addr, AgillaAgentID *id, uint8_t acpt, uint8_t addr1) 
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL) 
	{
		//struct AgillaAckHeapMsg *aMsg = (struct AgillaAckHeapMsg *)(call Packet.getPayload(msg, sizeof(AgillaAckHeapMsg)));
		AgillaAckHeapMsg *aMsg = (AgillaAckHeapMsg *)(call Packet.getPayload(msg, sizeof(AgillaAckHeapMsg)));
		aMsg->id = *id;
		aMsg->accept = acpt;
		aMsg->addr1 = addr1;
		if(addr == AM_UART_ADDR){
		if (call SerialSend_Heap_Ack.send(addr, msg, sizeof(AgillaAckHeapMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
		}
		else
		{
		if (call Send_Heap_Ack.send(addr, msg, sizeof(AgillaAckHeapMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
		}
		if (acpt == AGILLA_REJECT) call CoordinatorI.resetBuffer(id);
	}
	} 
	
	event message_t* Rcv_Heap.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaHeapMsg* hpMsg = (AgillaHeapMsg*)payload;
	AgillaAgentInfo* inBuf;
	
	if (call CoordinatorI.isArriving(&hpMsg->id) != SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveHeapM: Rcv_Heap.receive: ERROR: Agent %i is not arriving.\n", hpMsg->id.id);
		#endif		 
		return m;
	}
	
	inBuf = call CoordinatorI.getBuffer(&hpMsg->id);
	if (inBuf == NULL) {	
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveHeapM: Rcv_Heap.receive: ERROR: Could not get incomming buffer for agent %i.\n", hpMsg->id.id);
		#endif			 
		return m;		 
	}
		
	if (call CoordinatorI.stopTimer(&hpMsg->id) != SUCCESS) {	//PORTNG!!
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveHeapM: Rcv_Heap.receive: ERROR: Could not stop timer for agent %i.\n", hpMsg->id.id);
		#endif	 
		sendHeapAck(inBuf->reply, &hpMsg->id, AGILLA_REJECT, hpMsg->data[0]); 
		return m;		
	}

	if (call HeapMgrI.saveMsg(inBuf->context, hpMsg) == SUCCESS) {
		inBuf->numHpMsgs--;				 
		if (inBuf->numHpMsgs == 0)
		inBuf->integrity |= AGILLA_RECEIVED_HEAP;
	}
	
	#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "AgentReceiverM: Rcv_Heap.receive: Sending an ACCEPT ACK back to %i.\n", inBuf->reply);
	#endif				 
	
	sendHeapAck(inBuf->reply, &hpMsg->id, AGILLA_ACCEPT, hpMsg->data[0]); 
	
	if (inBuf->integrity == AGILLA_AGENT_READY) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "AgentReceiverM: Rcv_Heap.receive: Received agent %i, starting FIN timer.\n", hpMsg->id.id);
		#endif		 
		call CoordinatorI.startFinTimer(&hpMsg->id);
	} else {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "AgentReceiverM: Rcv_Heap.receive: Haven't received all heap messages for agent %i, starting ABORT timer.\n", hpMsg->id.id);
		#endif			 
		call CoordinatorI.startAbortTimer(&hpMsg->id); 
	}
	
	return m;
	} // Rcv_Heap.receive

	//RECEIVE SERIAL
	event message_t* SerialRcv_Heap.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaHeapMsg* hpMsg = (AgillaHeapMsg*)payload;
	AgillaAgentInfo* inBuf;
	
	if (call CoordinatorI.isArriving(&hpMsg->id) != SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveHeapM: Rcv_Heap.receive: ERROR: Agent %i is not arriving.\n", hpMsg->id.id);
		#endif		 
		return m;
	}
	
	inBuf = call CoordinatorI.getBuffer(&hpMsg->id);
	if (inBuf == NULL) {	
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveHeapM: Rcv_Heap.receive: ERROR: Could not get incomming buffer for agent %i.\n", hpMsg->id.id);
		#endif			 
		return m;		 
	}
		
	if (call CoordinatorI.stopTimer(&hpMsg->id) != SUCCESS) {	//PORTNG!!
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveHeapM: Rcv_Heap.receive: ERROR: Could not stop timer for agent %i.\n", hpMsg->id.id);
		#endif	 
		sendHeapAck(inBuf->reply, &hpMsg->id, AGILLA_REJECT, hpMsg->data[0]); 
		return m;		
	}

	if (call HeapMgrI.saveMsg(inBuf->context, hpMsg) == SUCCESS) {
		inBuf->numHpMsgs--;				 
		if (inBuf->numHpMsgs == 0)
		inBuf->integrity |= AGILLA_RECEIVED_HEAP;
	}
	
	#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "AgentReceiverM: Rcv_Heap.receive: Sending an ACCEPT ACK back to %i.\n", inBuf->reply);
	#endif				 
	
	sendHeapAck(inBuf->reply, &hpMsg->id, AGILLA_ACCEPT, hpMsg->data[0]); 
	
	if (inBuf->integrity == AGILLA_AGENT_READY) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "AgentReceiverM: Rcv_Heap.receive: Received agent %i, starting FIN timer.\n", hpMsg->id.id);
		#endif		 
		call CoordinatorI.startFinTimer(&hpMsg->id);
	} else {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "AgentReceiverM: Rcv_Heap.receive: Haven't received all heap messages for agent %i, starting ABORT timer.\n", hpMsg->id.id);
		#endif			 
		call CoordinatorI.startAbortTimer(&hpMsg->id); 
	}
	
	return m;
	} // Rcv_Heap.receive
	
	event void Send_Heap_Ack.sendDone(message_t* m, error_t success) 
	{ 
	call MessageBufferI.freeMsg(m);
	//return SUCCESS; 
	}

	event void SerialSend_Heap_Ack.sendDone(message_t* m, error_t success) 
	{ 
	call MessageBufferI.freeMsg(m);
	//return SUCCESS; 
	}
}
