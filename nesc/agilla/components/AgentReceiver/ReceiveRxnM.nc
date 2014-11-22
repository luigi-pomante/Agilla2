// $Id: ReceiveRxnM.nc,v 1.3 2006/01/06 01:16:30 chien-liang Exp $

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
 * Receives the reactions of an incomming agent.
 *
 * @author Chien-Liang Fok
 */
module ReceiveRxnM {
	uses {
	interface ReceiverCoordinatorI as CoordinatorI;
	interface RxnMgrI;
	interface Receive as Rcv_Rxn;
	interface AMSend as Send_Rxn_Ack;
	interface Receive as SerialRcv_Rxn;
	interface AMSend as SerialSend_Rxn_Ack;
	interface MessageBufferI;
	interface Packet;
	}	
}
implementation {

	inline void sendRxnAck(uint16_t addr, AgillaAgentID *id, uint8_t acpt, uint16_t msgNum) 
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		//struct AgillaAckRxnMsg *aMsg = (struct AgillaAckRxnMsg *)(call Packet.getPayload(msg, sizeof(AgillaAckRxnMsg)));	 
		AgillaAckRxnMsg *aMsg = (AgillaAckRxnMsg *)(call Packet.getPayload(msg, sizeof(AgillaAckRxnMsg)));
		aMsg->id = *id;
		aMsg->accept = acpt;
		aMsg->msgNum = msgNum;
		if(AM_UART_ADDR){	
		if (call SerialSend_Rxn_Ack.send(addr, msg, sizeof(AgillaAckRxnMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
		} 
		else
		{
		if (call Send_Rxn_Ack.send(addr, msg, sizeof(AgillaAckRxnMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
		}
	}
	}
	
	event message_t* Rcv_Rxn.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaRxnMsg* rxnMsg = (AgillaRxnMsg*)payload;
	if (call CoordinatorI.isArriving(&rxnMsg->rxn.id) == SUCCESS && 
		call CoordinatorI.stopTimer(&rxnMsg->rxn.id) == SUCCESS)
	{
		AgillaAgentInfo* inBuf = call CoordinatorI.getBuffer(&rxnMsg->rxn.id);
		if (inBuf != NULL) {		 
		/**
		 * If the reaction has not already been registered, register it.
		 * Then check whether all of the reactions have been received. If
		 * so, update the agent's integrity and run the agent if it is 
		 * ready.
		 */
		if (call RxnMgrI.isRegistered(&rxnMsg->rxn) != SUCCESS) {
			call RxnMgrI.registerRxn(&rxnMsg->rxn);
			if (rxnMsg->msgNum + 1 == inBuf->nRxnMsgs)
			inBuf->integrity |= AGILLA_RECEIVED_RXN;
			if (inBuf->integrity == AGILLA_AGENT_READY) {
			#if DEBUG_AGENT_RECEIVER
				dbg("DBG_USR1", "ReceiveRxnM: Rcv_Rxn.receive: Starting FIN timer for agent %i.\n", rxnMsg->rxn.id.id);
			#endif		 
			call CoordinatorI.startFinTimer(&rxnMsg->rxn.id);
			} else 
			call CoordinatorI.startAbortTimer(&rxnMsg->rxn.id);	// have not received entire agent						
		}	
		dbg("DBG_USR1", "ReceiveRxnM: Rcv_Rxn.receive: Received reaction %i for agent %i.\n", rxnMsg->msgNum, rxnMsg->rxn.id.id);			
		sendRxnAck(inBuf->reply, &rxnMsg->rxn.id, AGILLA_ACCEPT, rxnMsg->msgNum);		
		return m;
		}
	}
	return m;	
	}

	//RECEIVE SERIAL
	event message_t* SerialRcv_Rxn.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaRxnMsg* rxnMsg = (AgillaRxnMsg*)payload;
	if (call CoordinatorI.isArriving(&rxnMsg->rxn.id) == SUCCESS && 
		call CoordinatorI.stopTimer(&rxnMsg->rxn.id) == SUCCESS)
	{
		AgillaAgentInfo* inBuf = call CoordinatorI.getBuffer(&rxnMsg->rxn.id);
		if (inBuf != NULL) {		 
		/**
		 * If the reaction has not already been registered, register it.
		 * Then check whether all of the reactions have been received. If
		 * so, update the agent's integrity and run the agent if it is 
		 * ready.
		 */
		if (call RxnMgrI.isRegistered(&rxnMsg->rxn) != SUCCESS) {
			call RxnMgrI.registerRxn(&rxnMsg->rxn);
			if (rxnMsg->msgNum + 1 == inBuf->nRxnMsgs)
			inBuf->integrity |= AGILLA_RECEIVED_RXN;
			if (inBuf->integrity == AGILLA_AGENT_READY) {
			#if DEBUG_AGENT_RECEIVER
				dbg("DBG_USR1", "ReceiveRxnM: Rcv_Rxn.receive: Starting FIN timer for agent %i.\n", rxnMsg->rxn.id.id);
			#endif		 
			call CoordinatorI.startFinTimer(&rxnMsg->rxn.id);
			} else 
			call CoordinatorI.startAbortTimer(&rxnMsg->rxn.id);	// have not received entire agent						
		}	
		dbg("DBG_USR1", "ReceiveRxnM: Rcv_Rxn.receive: Received reaction %i for agent %i.\n", rxnMsg->msgNum, rxnMsg->rxn.id.id);			
		sendRxnAck(inBuf->reply, &rxnMsg->rxn.id, AGILLA_ACCEPT, rxnMsg->msgNum);		
		return m;
		}
	}
	return m;	
	}

	event void Send_Rxn_Ack.sendDone(message_t* m, error_t success) {
	call MessageBufferI.freeMsg(m);
	//return SUCCESS; 
	}

	event void SerialSend_Rxn_Ack.sendDone(message_t* m, error_t success) {
	call MessageBufferI.freeMsg(m);
	//return SUCCESS; 
	}
}
