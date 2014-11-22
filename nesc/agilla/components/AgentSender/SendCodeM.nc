// $Id: SendCodeM.nc,v 1.7 2006/01/14 19:38:56 chien-liang Exp $

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
 * Sends the code of an agent.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
#include "Timer.h"

module SendCodeM {
	provides {
	interface StdControl;
	interface Init;
	interface PartialAgentSenderI as SendCode;
	}
	uses {
	interface MessageBufferI;
	interface CodeMgrI;

	interface AMSend as Send_Code;
	interface Receive as Rcv_Ack;
	interface AMSend as SerialSend_Code;
	interface Receive as SerialRcv_Ack;
	
	interface Timer<TMilli> as Ack_Timer;
	interface ErrorMgrI as Error;
	interface Leds;
	interface Packet;
	}
}
implementation {
	int16_t _msgNum;
	uint8_t _numRetries, _numCodeBlocks;	
	
	AgillaAgentContext* _context;
	AgillaAgentID _id;
	uint8_t _op;
	uint16_t _dest;
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

	inline void signalDone(error_t success) {
	_waiting = FALSE;
	signal SendCode.sendDone(_context, success);				
	}
	
	command error_t SendCode.send(AgillaAgentContext* context, AgillaAgentID id,
	uint8_t op, uint16_t dest, uint16_t final_dest) 
	{	
	if (post doSend() == SUCCESS) {
		_numRetries = _msgNum = 0;

		_context = context;
		_id = id;
		_op = op;
		_dest = dest;

		// Calculate the number of code blocks
		_numCodeBlocks = _context->codeSize / AGILLA_CODE_BLOCK_SIZE;
		if (_numCodeBlocks*AGILLA_CODE_BLOCK_SIZE < _context->codeSize)
		_numCodeBlocks++;
		return SUCCESS;
	} else
		return FAIL;
	}
	
	task void doSend() 
	{
	message_t* msg = call MessageBufferI.getMsg();
	if (msg != NULL) 
	{
		//struct AgillaCodeMsg *cMsg = (struct AgillaCodeMsg*)msg->data;	
		AgillaCodeMsg *cMsg = (AgillaCodeMsg*)(call Packet.getPayload(msg, sizeof(AgillaCodeMsg)));
		cMsg->id = _id;
		if (call CodeMgrI.fillCodeMsg(_context, cMsg, _msgNum) == SUCCESS)
		{
		if (_dest == AM_UART_ADDR){
			if (call SerialSend_Code.send(_dest, msg, sizeof(AgillaCodeMsg)) != SUCCESS)
			{		
			#if DEBUG_AGENT_SENDER
				dbg("DBG_USR1", "SendCodeM: task doSend(): ERROR: Failed to send code msg %i b/c network stack busy.\n", _msgNum);
			#endif
			
			call MessageBufferI.freeMsg(msg);
			signalDone(FAIL);
		
			}	 else 
			{
			#if DEBUG_AGENT_SENDER
				dbg("DBG_USR1", "SendCodeM: task doSend(): Sent code message %i.\n", _msgNum);
			#endif	
			_waiting = TRUE;
			call Ack_Timer.startOneShot(AGILLA_SNDR_RXMIT_TIMER);
			}
		} else{
			if (call Send_Code.send(_dest, msg, sizeof(AgillaCodeMsg)) != SUCCESS)
			{		
			#if DEBUG_AGENT_SENDER
				dbg("DBG_USR1", "SendCodeM: task doSend(): ERROR: Failed to send code msg %i b/c network stack busy.\n", _msgNum);
			#endif
			
			call MessageBufferI.freeMsg(msg);
			signalDone(FAIL);
		
			}	 else 
			{
			#if DEBUG_AGENT_SENDER
				dbg("DBG_USR1", "SendCodeM: task doSend(): Sent code message %i.\n", _msgNum);
			#endif	
			_waiting = TRUE;
			call Ack_Timer.startOneShot(AGILLA_SNDR_RXMIT_TIMER);
			}
		}
		}
	} else 
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCodeM: task doSend(): Failed to allocated message buffer, retry timer set.\n");
		#endif		
		call Ack_Timer.startOneShot(AGILLA_SNDR_RXMIT_TIMER);
	}
	} // doSend()
	
	/**
	 * This is executed whenever an ACK message times out.
	 */
	event void Ack_Timer.fired() {
	if (_waiting) 
	{
		_numRetries++;		

		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCodeM: Ack_Timer.fired(): TIMED OUT! (# timeouts = %i)\n", _numRetries);
		#endif		 

		if (_numRetries < AGILLA_SNDR_MAX_RETRANSMITS) {
		post doSend();
		} else {		
		#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendCodeM: Ack_Timer.fired(): Max numTimeouts reached.\n");
		#endif			
		signalDone(FAIL);	
		}
	}	
	 // return SUCCESS;
	}
	
	/**
	 * This is signalled when an ACK message is received.
	 */
	event message_t* Rcv_Ack.receive(message_t* m, void* payload, uint8_t len)
	{
	if (_waiting)
	{
		AgillaAckCodeMsg* aMsg = (AgillaAckCodeMsg*)payload;
		if (aMsg->id.id == _id.id && aMsg->msgNum == _msgNum) 
		{
		call Ack_Timer.stop();
		_numRetries = 0;
		if (aMsg->accept) //OK PERCHé accept VALE O AGILLA_ACCEPT (=1) O AGILLA_AREJECT (=0)
		{
			if (++_msgNum == _numCodeBlocks)
			signalDone(SUCCESS);
			else
			post doSend();
		} else 
		{
			#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendCodeM: Rcv_Ack.receive: The Code message %i was rejected.\n", _msgNum);
			#endif			
			signalDone(FAIL);
		}
		} else
		dbg("DBG_USR1", "SendCodeM: Rcv_Ack.receive: ERROR: Got unexpected ACK.\n", _msgNum);
	}
	return m;
	}
	
	event message_t* SerialRcv_Ack.receive(message_t* m, void* payload, uint8_t len)
	{
	if (_waiting)
	{
		AgillaAckCodeMsg* aMsg = (AgillaAckCodeMsg*)payload;
		if (aMsg->id.id == _id.id && aMsg->msgNum == _msgNum) 
		{
		call Ack_Timer.stop();
		_numRetries = 0;
		if (aMsg->accept) //OK PERCHé accept VALE O AGILLA_ACCEPT (=1) O AGILLA_AREJECT (=0)
		{
			if (++_msgNum == _numCodeBlocks)
			signalDone(SUCCESS);
			else
			post doSend();
		} else 
		{
			#if DEBUG_AGENT_SENDER
			dbg("DBG_USR1", "SendCodeM: Rcv_Ack.receive: The Code message %i was rejected.\n", _msgNum);
			#endif			
			signalDone(FAIL);
		}
		} else
		dbg("DBG_USR1", "SendCodeM: Rcv_Ack.receive: ERROR: Got unexpected ACK.\n", _msgNum);
	}
	return m;
	}
	
	event void Send_Code.sendDone(message_t* m, error_t success)
	{ 
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}
	
	event void SerialSend_Code.sendDone(message_t* m, error_t success)
	{ 
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}
}
