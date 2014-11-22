// $Id: SendRxnM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
	interface AMSend as SerialSend_Rxn;
	//interface ReceiveMsg as Rcv_Ack;

	//interface Timer as Ack_Timer;	 
	interface ErrorMgrI as Error;
	interface Picket;
	}
}
implementation {
	/*enum {
	IDLE = 0,
	SENDING,
	WAITING,
	};
	
	bool _state;*/
	uint8_t _numRetransmits;	
	
	uint8_t _msgNum;	// the number of reactions that have been sent
	
	AgillaAgentContext* _context;
	AgillaAgentID _id;	
	uint16_t _dest;

	task void doSend();
	
	command error_t Init.init() {
	return SUCCESS;
	}

	command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}	
	
	inline void sendFail() {	
	if (++_numRetransmits < AGILLA_SNDR_MAX_RETRANSMITS) {
		if (post doSend() != SUCCESS)
		signal SendRxn.sendDone(_context, FAIL);				
	} else 
		signal SendRxn.sendDone(_context, FAIL);					
	}	
	
	command error_t SendRxn.send(AgillaAgentContext* context, AgillaAgentID id,
	uint8_t op, uint16_t dest) 
	{		
	if (post doSend() == SUCCESS) {
		//_state = SENDING;
		_numRetransmits = _msgNum = 0;
		_context = context;
		_id = id;
		_dest = dest;		
		return SUCCESS;
	} else 
		return FAIL;
	}
	
	task void doSend() {
	//TOS_MsgPtr msg = call MessageBufferI.getBuffer();
	//struct AgillaRxnMsg *rxnMsg = (struct AgillaRxnMsg *)msg->data;
	message_t* msg = call MessageBufferI.getMsg();
	AgillaRxnMsg *rxnMsg = (AgillaRxnMsg *)(call Packet.getPayload(msg, sizeof(AgillaRxnMsg)));
	
	//rxnMsg->replyAddr = TOS_LOCAL_ADDRESS;
	rxnMsg->msgNum = _msgNum;
	
	if(call RxnMgrI.getRxn(&_context->id, _msgNum, &rxnMsg->rxn) != SUCCESS) {
		call Error.errord(_context, AGILLA_ERROR_RXN_NOT_FOUND, _msgNum);
		signal SendRxn.sendDone(_context, FAIL);
	} else {			 
		rxnMsg->rxn.id = _id;	// update the ID
		if (_dest == AM_UART_ADDR){
		if (call SerialSend_Rxn.send(_dest, msg, sizeof(AgillaRxnMsg)) != SUCCESS)
			sendFail();	 
		} else{
		if (call Send_Rxn.send(_dest, msg, sizeof(AgillaRxnMsg)) != SUCCESS)
			sendFail();	
		}
	}
	}
	
	/**
	 * This is executed whenever an ACK message times out.
	 */
	/*event result_t Ack_Timer.fired() {	
	_numRetransmits++;	
	
	#if DEBUG_AGENT_SENDER
	dbg(DBG_USR1, "SendRxnM: Ack_Timer.fired(): TIMED OUT! (# = %i)\n", _numRetransmits);
	#endif	
	
	if (_numRetransmits < AGILLA_SNDR_MAX_TIMEOUTS) {
		post doSend();
	} else {
		#if DEBUG_AGENT_SENDER
		dbg(DBG_USR1, "SendRxnM: Ack_Timer.fired(): max timeouts reached.\n");
		#endif	
		signalDone(FAIL);	
	}
	return SUCCESS;
	}*/
	
	/**
	 * This is signalled when an ACK message is received.
	 */
	/*event TOS_MsgPtr Rcv_Ack.receive(TOS_MsgPtr m) {
	if (_state == WAITING) {
		AgillaAckRxnMsg* aMsg = (AgillaAckRxnMsg*)m->data;
		if (aMsg->id.id == _id.id) {
		call Ack_Timer.stop();
		if (aMsg->accept) {
			if (++_msgNum <	call RxnMgrI.numRxns(&_context->id))
			post doSend();
			else
			signalDone(SUCCESS);
		} else			
			signalDone(FAIL);				 
		} else {
		#if DEBUG_AGENT_SENDER
		dbg(DBG_USR1, "SendRxnM: Rcv_Ack.receive: The ACK was not for this agent.\n");
		#endif				
		}
	} else {
		#if DEBUG_AGENT_SENDER
		dbg(DBG_USR1, "SendRxnM: Rcv_Ack.receive: Received an ACK while not WAITING.\n");
		#endif					
	}
	return m;
	}*/
	
	event void Send_Rxn.sendDone(message_t* m, error_t success)	{
	if (success != SUCCESS /*|| !m->ack*/)
		 sendFail();
	else {
		if (++_msgNum <	call RxnMgrI.numRxns(&_context->id)) {
		if (post doSend() != SUCCESS)
			signal SendRxn.sendDone(_context, FAIL);
		} else
		signal SendRxn.sendDone(_context, SUCCESS); 
	}

	}
	
	event void SerialSend_Rxn.sendDone(message_t* m, error_t success)	{
	if (success != SUCCESS /*|| !m->ack*/)
		 sendFail();
	else {
		if (++_msgNum <	call RxnMgrI.numRxns(&_context->id)) {
		if (post doSend() != SUCCESS)
			signal SendRxn.sendDone(_context, FAIL);
		} else
		signal SendRxn.sendDone(_context, SUCCESS); 
	}

	}

	event error_t RxnMgrI.rxnFired(Reaction* rxn, AgillaTuple* tuple) {
	return SUCCESS;
	}	
}
