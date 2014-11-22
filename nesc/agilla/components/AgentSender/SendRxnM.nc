// $Id: SendRxnM.nc,v 1.8 2006/01/06 19:52:12 chien-liang Exp $

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


/**
 * Sends the reactions of an agent.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
#include "Timer.h"

module SendRxnM {
	provides {
	interface StdControl;
	interface Init;
	interface PartialAgentSenderI as SendRxn;
	}
	uses {
	interface MessageBufferI;
	interface RxnMgrI;
	
	interface AMSend as Send_Rxn;
	interface Receive as Rcv_Ack;
	interface AMSend as SerialSend_Rxn;
	interface Receive as SerialRcv_Ack;

	interface Timer<TMilli> as Ack_Timer;
	interface ErrorMgrI as Error;
	interface Packet;
	}
}
implementation {
	uint8_t _numRetransmits, _msgNum;	// the number of reactions that have been sent	
	uint16_t _dest;
	AgillaAgentContext* _context;
	AgillaAgentID _id;	
	bool _waiting;

	task void doSend();
	
	command error_t Init.init() {
	_waiting = FALSE;
	return SUCCESS;
	}

	command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}	
	
	inline void sendFail() 
	{
	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendRxnM: send failed!\n");
	#endif		
	
	_waiting = FALSE;
	
	if (++_numRetransmits < AGILLA_SNDR_MAX_RETRANSMITS) {
		if (post doSend() != SUCCESS)
		signal SendRxn.sendDone(_context, FAIL);				
	} else 
		signal SendRxn.sendDone(_context, FAIL);					
	}	
	
	command error_t SendRxn.send(AgillaAgentContext* context, AgillaAgentID id,
	uint8_t op, uint16_t dest, uint16_t final_dest) 
	{		
	if (post doSend() == SUCCESS) {						
		_numRetransmits = _msgNum = 0;
		_context = context;
		_id = id;
		_dest = dest;		
		return SUCCESS;
	} else 
		return FAIL;
	}
	
	task void doSend() 
	{
	message_t* msg = call MessageBufferI.getMsg();

	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendRxnM: task doSend(): task called.\n");
	#endif		

	
	if (msg != NULL) 
	{
		//struct AgillaRxnMsg *rxnMsg = (struct AgillaRxnMsg *)msg->data;
		AgillaRxnMsg *rxnMsg = (AgillaRxnMsg *)(call Packet.getPayload(msg, sizeof(AgillaRxnMsg)));
		rxnMsg->msgNum = _msgNum;	
		if(call RxnMgrI.getRxn(&_context->id, _msgNum, &rxnMsg->rxn) == SUCCESS)
		{
		rxnMsg->rxn.id = _id;	// update the ID
		if (_dest == AM_UART_ADDR){
			if (call SerialSend_Rxn.send(_dest, msg, sizeof(AgillaRxnMsg)) != SUCCESS)
			sendFail();	 
			else 
			{
			#if DEBUG_AGENT_SENDER
				dbg("DBG_USR1", "SendRxnM: task doSend(): Sent rxn message %i.\n", _msgNum);
			#endif		
			_waiting = TRUE;
			call Ack_Timer.startOneShot(AGILLA_SNDR_RXMIT_TIMER);
			}
		} else{
			if (call Send_Rxn.send(_dest, msg, sizeof(AgillaRxnMsg)) != SUCCESS)
			sendFail();	 
			else 
			{
			#if DEBUG_AGENT_SENDER
				dbg("DBG_USR1", "SendRxnM: task doSend(): Sent rxn message %i.\n", _msgNum);
			#endif		
			_waiting = TRUE;
			call Ack_Timer.startOneShot(AGILLA_SNDR_RXMIT_TIMER);
			}
		}
		} else {			 
		dbg("DBG_USR1", "SendRxnM.doSend(): ERROR: could not get reaction %i of agent %i\n", _msgNum, _context->id.id);
		call Error.errord(_context, AGILLA_ERROR_RXN_NOT_FOUND, _msgNum);
		call MessageBufferI.freeMsg(msg);
		signal SendRxn.sendDone(_context, FAIL);
		}
	} else
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendRxnM: task doSend(): Failed to allocated buffer, retry timer set.\n");
		#endif		
		call Ack_Timer.startOneShot(AGILLA_SNDR_RXMIT_TIMER);
	}
	}
	
	/**
	 * This is executed whenever an ACK message times out.
	 */
	event void Ack_Timer.fired()
	{	
	if (_waiting) 
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendRxnM: ACK timer fired...\n");
		#endif			
		sendFail();		
	}
	//return SUCCESS;
	}
	
	/**
	 * This is signalled when an ACK message is received.
	 */
	event message_t* Rcv_Ack.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaAckRxnMsg* aMsg = (AgillaAckRxnMsg*)payload;
	
	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendRxnM: Received an ACK...\n");
	#endif		 
	
	if (aMsg->id.id == _id.id) 
	{
		_waiting = FALSE;
		call Ack_Timer.stop();
		if (aMsg->accept) {	//OK PERCHé accept VALE O AGILLA_ACCEPT (=1) O AGILLA_AREJECT (=0)
		#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendRxnM: Received a SUCCESS ACK.\n");
		#endif					
		if (++_msgNum <	call RxnMgrI.numRxns(&_context->id))
			post doSend();
		else
			signal SendRxn.sendDone(_context, SUCCESS);	
		} else {
		#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendRxnM: Received a REJECT ACK.\n");
		#endif				
		signal SendRxn.sendDone(_context, FAIL);				 
		}
	} else {
		#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendRxnM: Received an ACK for the wrong agent (%i != %i).\n", aMsg->id.id, _id.id);
		#endif		
	}
	return m;
	}
	
	event message_t* SerialRcv_Ack.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaAckRxnMsg* aMsg = (AgillaAckRxnMsg*)payload;
	
	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendRxnM: Received an ACK...\n");
	#endif		 
	
	if (aMsg->id.id == _id.id) 
	{
		_waiting = FALSE;
		call Ack_Timer.stop();
		if (aMsg->accept) {	//OK PERCHé accept VALE O AGILLA_ACCEPT (=1) O AGILLA_AREJECT (=0)
		#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendRxnM: Received a SUCCESS ACK.\n");
		#endif					
		if (++_msgNum <	call RxnMgrI.numRxns(&_context->id))
			post doSend();
		else
			signal SendRxn.sendDone(_context, SUCCESS);	
		} else {
		#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendRxnM: Received a REJECT ACK.\n");
		#endif				
		signal SendRxn.sendDone(_context, FAIL);				 
		}
	} else {
		#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendRxnM: Received an ACK for the wrong agent (%i != %i).\n", aMsg->id.id, _id.id);
		#endif		
	}
	return m;
	}
	
	event void Send_Rxn.sendDone(message_t* m, error_t success)	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS; 
	} 
	
	event void SerialSend_Rxn.sendDone(message_t* m, error_t success)	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS; 
	} 
}
