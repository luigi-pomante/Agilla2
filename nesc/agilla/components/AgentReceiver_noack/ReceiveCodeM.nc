// $Id: ReceiveCodeM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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

module ReceiveCodeM {
	uses {
	interface ReceiverCoordinatorI as CoordinatorI;
	interface CodeMgrI;
	interface Receive as Rcv_Code;
	interface Receive as SerialRcv_Code;
	//interface AMSend as Send_Code_Ack;
	interface MessageBufferI;
	}	
}
implementation {
	
	/*inline void sendCodeAck(uint16_t addr, AgillaAgentID *id, uint8_t acpt, uint16_t msgNum) {
	TOS_MsgPtr msg = call MessageBufferI.getBuffer();
	struct AgillaAckCodeMsg *aMsg = (struct AgillaAckCodeMsg *)msg->data;
	aMsg->id = *id;
	aMsg->accept = acpt;
	aMsg->msgNum = msgNum;
	call Send_Code_Ack.send(addr, sizeof(AgillaAckCodeMsg), msg);
	
	if (acpt == AGILLA_REJECT)
		call CoordinatorI.resetBuffer(id);
	}*/	
	
	event message_t* Rcv_Code.receive(message_t* m, void* payload, uint8_t len) {	
	AgillaCodeMsg *cMsg = (AgillaCodeMsg*)payload;
	AgillaAgentInfo* inBuf;
	
	//#if DEBUG_AGENT_RECEIVER
	//dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Received CODE message from %i.\n", cMsg->id.id);
	//#endif
	
	if (call CoordinatorI.isArriving(&cMsg->id) != SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Agent %i is not arriving.\n", cMsg->id.id);
		#endif		 
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m;
	}
	
	inBuf = call CoordinatorI.getBuffer(&cMsg->id);
	if (inBuf == NULL) {				
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Could not get incomming buffer for agent %i.\n", cMsg->id.id);
		#endif			
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m; 
	}
	
	if (call CoordinatorI.stopTimer(&cMsg->id) != SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Could not stop timer for agent %i.\n", cMsg->id.id);
		#endif					 
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m;		
	}	
	
	if (!(inBuf->integrity & AGILLA_RECEIVED_CODE)) { // if still waiting for code msgs	//<--QUI?
		if (call CodeMgrI.setBlock(inBuf->context, cMsg) != SUCCESS) {
		
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Failed to set block %i.\n", cMsg->msgNum);		
		#endif		
		
		call CoordinatorI.resetBuffer(&cMsg->id);
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m;		 
		}
	 
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Received CODE message %i of %i for agent %i.\n", cMsg->msgNum+1, inBuf->nCBlocks, cMsg->id.id);		
		#endif
		
		if (cMsg->msgNum+1 == inBuf->nCBlocks)
		inBuf->integrity |= AGILLA_RECEIVED_CODE;		
	}
			
	//#if DEBUG_AGENT_RECEIVER
	// dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Sending ACCEPT ACK msgNum=%i back to node %i.\n", cMsg->msgNum, cMsg->replyAddr);
	//#endif				
	//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_ACCEPT, cMsg->msgNum);		
	
	if (inBuf->integrity == AGILLA_AGENT_READY) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Received agent %i, starting FIN timer.\n", cMsg->id.id);
		#endif		 
		call CoordinatorI.startFinTimer(&cMsg->id);
	} else {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Resuming ABORT timer for agent %i.\n", cMsg->id.id);
		#endif		
		call CoordinatorI.startAbortTimer(&cMsg->id);			
	}
	
	return m;
	} // Rcv_Code.receive

	//RECEIVE SERIAL
	event message_t* SerialRcv_Code.receive(message_t* m, void* payload, uint8_t len) {	
	AgillaCodeMsg *cMsg = (AgillaCodeMsg*)payload;
	AgillaAgentInfo* inBuf;
	
	//#if DEBUG_AGENT_RECEIVER
	//dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Received CODE message from %i.\n", cMsg->id.id);
	//#endif
	
	if (call CoordinatorI.isArriving(&cMsg->id) != SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Agent %i is not arriving.\n", cMsg->id.id);
		#endif		 
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m;
	}
	
	inBuf = call CoordinatorI.getBuffer(&cMsg->id);
	if (inBuf == NULL) {				
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Could not get incomming buffer for agent %i.\n", cMsg->id.id);
		#endif			
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m; 
	}
	
	if (call CoordinatorI.stopTimer(&cMsg->id) != SUCCESS) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Could not stop timer for agent %i.\n", cMsg->id.id);
		#endif					 
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m;		
	}	
	
	if (!(inBuf->integrity & AGILLA_RECEIVED_CODE)) { // if still waiting for code msgs	//<--QUI?
		if (call CodeMgrI.setBlock(inBuf->context, cMsg) != SUCCESS) {
		
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: ERROR: Failed to set block %i.\n", cMsg->msgNum);		
		#endif		
		
		call CoordinatorI.resetBuffer(&cMsg->id);
		//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_REJECT, cMsg->msgNum);
		return m;		 
		}
	 
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Received CODE message %i of %i for agent %i.\n", cMsg->msgNum+1, inBuf->nCBlocks, cMsg->id.id);		
		#endif
		
		if (cMsg->msgNum+1 == inBuf->nCBlocks)
		inBuf->integrity |= AGILLA_RECEIVED_CODE;		
	}
			
	//#if DEBUG_AGENT_RECEIVER
	// dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Sending ACCEPT ACK msgNum=%i back to node %i.\n", cMsg->msgNum, cMsg->replyAddr);
	//#endif				
	//sendCodeAck(cMsg->replyAddr, &cMsg->id, AGILLA_ACCEPT, cMsg->msgNum);		
	
	if (inBuf->integrity == AGILLA_AGENT_READY) {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Received agent %i, starting FIN timer.\n", cMsg->id.id);
		#endif		 
		call CoordinatorI.startFinTimer(&cMsg->id);
	} else {
		#if DEBUG_AGENT_RECEIVER
		dbg("DBG_USR1", "ReceiveCodeM: Rcv_Code.receive: Resuming ABORT timer for agent %i.\n", cMsg->id.id);
		#endif		
		call CoordinatorI.startAbortTimer(&cMsg->id);			
	}
	
	return m;
	} // Rcv_Code.receive

	/*event void Send_Code_Ack.sendDone(message_t* m, error_t success) {	
	//return SUCCESS; 
	}*/	
}
