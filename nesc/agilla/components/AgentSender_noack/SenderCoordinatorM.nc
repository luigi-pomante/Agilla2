// $Id: SenderCoordinatorM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
#include "Timer.h"

/**
 * Orchestrates all of the components involved with sending
 * an agent to a remote node.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module SenderCoordinatorM {
	provides {
	interface AgentSenderI;
	interface StdControl;
	interface Init;
	interface MessageBufferI;
	}
	uses {
	interface PartialAgentSenderI as SendState;
	interface PartialAgentSenderI as SendCode;
	interface PartialAgentSenderI as SendOpStack;
	interface PartialAgentSenderI as SendHeap;
	interface PartialAgentSenderI as SendRxn;
	interface Timer<TMilli> as Retry_Timer;
	
	interface HeapMgrI;
	interface OpStackI;
	interface RxnMgrI;	
	interface ErrorMgrI; 
	interface Leds;
	}
}
implementation {	
	enum {
	IDLE = 0,
	SENDING,
	};
	
	/**
	 * Keeps track of what state the SenderCoordinator is in.
	 * Possible values include IDLE and SENDING.
	 */
	uint8_t state;

	/**
	 * The number of times we've tried to send this agent
	 * but failed.
	 */
	uint8_t numRetries;

	/**
	 * The one hop destination to which we are trying to migrate
	 * the agent towards.
	 */
	uint16_t oneHopDest;
	
	/**
	 * The value indicating whether the agent migration operation
	 * was successful.	This is passed to the callee via the
	 * sendDone(...) event.
	 */
	error_t _success;
	
	/**
	 * Memory allocated to store outgoing messages.
	 */
	message_t _msg;
	
	task void sendState();
	task void sendCode();
	task void sendHeap();
	task void sendOpStack();
	task void sendRxn();
	task void retry();
	task void done();
	inline uint8_t nextHead();
	inline uint8_t nextTail();
	
	/**
	 * Holds the state of an migrating agent.	Variable isBounce 
	 * remembers whether an agent is just bouncing off this host.	
	 */
	struct OutgoingAgent {
	uint16_t dest;				// ultimate destination
	AgillaAgentContext* context;	// the migrating agent's context (pc, etc.)
	AgillaAgentID	id;			// the migrating agent's ID
	uint8_t op;					 // the migration instruction, 0xff means "null"
	} sBuf[AGILLA_SNDR_BUFF_SIZE];
	int shead, stail;
	
	command error_t Init.init() {
	int i;
	for (i = 0; i < AGILLA_SNDR_BUFF_SIZE; i++) {
		sBuf[i].op = 0xff;
	}
	shead = stail = numRetries = 0;
	state = IDLE;

	return SUCCESS;
	}

	command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}	
	
	task void done() {	
	signal AgentSenderI.sendDone(sBuf[stail].context, sBuf[stail].op, _success);						
	numRetries = 0;		
	sBuf[stail].op = 0xff;										
	stail = nextTail();		 
	if (sBuf[stail].op != 0xff)
		post sendState();	// send the next agent in the queue
	else	
		state = IDLE;		// no more agents to send, change to IDLE state	 
	}	

	/**
	 * Calculates the next index of the send queue's head.
	 */
	inline uint8_t nextHead() {
	uint8_t result = shead + 1;
	result %= AGILLA_SNDR_BUFF_SIZE;
	return result;
	}

	/**
	 * Calculates the next index of the send queue's tail.
	 */
	inline uint8_t nextTail() {
	uint8_t result = stail + 1;
	result %= AGILLA_SNDR_BUFF_SIZE;
	return result;
	}	 
	
	inline error_t queueHasRoom() {

	if(shead != stail || sBuf[shead].op == 0xff) return SUCCESS;
	else return FAIL;
	}

	/**
	 * Sends an agent to a remote node.
	 *
	 * @param context The agent to send.
	 * @param id The AgillaAgentID of the new agent.
	 * @param dest The destination location. 
	 */
	command error_t AgentSenderI.send(AgillaAgentContext* context, AgillaAgentID id, 
	uint8_t op, uint16_t dest)
	{
	if (queueHasRoom() == SUCCESS) {
		struct OutgoingAgent* buff = &sBuf[shead];		
		buff->id = id;
		buff->op = IOP;
		buff->dest = dest;		
		buff->context = context;		 
		context->state = AGILLA_STATE_LEAVING;
		shead = nextHead();		
		if (state == IDLE) {
		state = SENDING;			
		return post sendState();
		} else
		return SUCCESS;
	} else {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: AgentSenderI.send(): Send queue full, returning FAIL.\n");
		call ErrorMgrI.errord(context, AGILLA_ERROR_SEND_BUFF_FULL, stail);
		#endif 
		return FAIL;
	}
	}

//STATE-----------------------------------------------------------------------------------------------
	task void sendState() {	 
	if(call SendState.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op, sBuf[stail].dest) != SUCCESS) {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: task sendState(): Failed to send state, retrying.\n");
		#endif			
		post retry();
	}		
	}
	
	event void SendState.sendDone(AgillaAgentContext* context, error_t success) {
	if (success == SUCCESS)			 
		post sendCode();
	else {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: task sendState(): Failed to send state, retrying.\n");
		#endif	 
		post retry();	 
	}
	}
	
//CODE------------------------------------------------------------------------------------------------	
	task void sendCode() {
	if(call SendCode.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op, sBuf[stail].dest) != SUCCESS){
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: task sendCode(): FAILED to send code, retrying.\n");
		#endif		
		post retry();
	}
	}
	
	event void SendCode.sendDone(AgillaAgentContext* context, error_t success) {
	if (success == SUCCESS) {
		dbg("DBG_USR1", "SendCoordinatorM: event SendCode.sendDone(): Success, op = %i!\n", sBuf[stail].op);			
		if (sBuf[stail].op == IOPsmove || sBuf[stail].op == IOPsclone) {	
		dbg("DBG_USR1", "SendCoordinatorM: event SendCode.sendDone(): OP is strong.\n");			
		if (call HeapMgrI.hasHeap(sBuf[stail].context) == SUCCESS) {
			dbg("DBG_USR1", "SendCoordinatorM: event SendCode.sendDone(): Sending Heap.\n");			
			post sendHeap();
		} else if (call OpStackI.numOpStackMsgs(sBuf[stail].context) > 0)
			post sendOpStack();
		else if (call RxnMgrI.numRxns(&sBuf[stail].context->id) > 0)
			post sendRxn();
		else {		 
			_success = SUCCESS;	// nothing more to send!
			post done();
		}
		} else { // operation is weak, finish!
		_success = SUCCESS;
		post done();
		}
	} else {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: event SendCode.sendDone(): Failed to send the code, retrying.\n");
		#endif	 
		//call Leds.greenOn(); 
		post retry();	 
	}
	}	

//HEAP------------------------------------------------------------------------------------------------	
	task void sendHeap() {
	dbg("DBG_USR1", "SendCoordinatorM: event SendCode.sendDone(): Sending Heap2.\n");			
	if(call SendHeap.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op, sBuf[stail].dest) != SUCCESS) {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: task sendHeap(): FAILED to send heap, retrying.\n");
		#endif			
		post retry();
	}	
	}

	event void SendHeap.sendDone(AgillaAgentContext* context, error_t success) {
	if (success == SUCCESS) {
		if (call OpStackI.numOpStackMsgs(sBuf[stail].context) > 0)
		post sendOpStack();
		else if (call RxnMgrI.numRxns(&sBuf[stail].context->id) > 0)
		post sendRxn();
		else {
		_success = SUCCESS;
		post done();
		}		 
	} else {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: SendHeap.sendDone(): FAILED to send heap, retrying.\n");
		#endif			
		post retry();	 
	}
	}	
	
//OPSTACK---------------------------------------------------------------------------------------------		
	task void sendOpStack() {
	if(call SendOpStack.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op, sBuf[stail].dest) != SUCCESS) {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: sendOpStack(): failed, retrying.\n");
		#endif			
		post retry();
	}	
	}
	
	event void SendOpStack.sendDone(AgillaAgentContext* context, error_t success) {
	if (success == SUCCESS) {
		if (call RxnMgrI.numRxns(&sBuf[stail].context->id) > 0)
		post sendRxn();
		else {
		_success = SUCCESS;
		post done();
		}		 
	} else {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: SendOpStack.sendDone(): failed, retrying.\n");
		#endif		
		post retry();	 
	}
	}		
	
//RXN----------------------------------------------------------------------------------------------		
	task void sendRxn() {
	if(call SendRxn.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op, sBuf[stail].dest) != SUCCESS) {
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: sendRxn(): SendRxn.send() failed, retrying.\n");
		#endif			
		post retry();
	}	
	}
	
	event void SendRxn.sendDone(AgillaAgentContext* context, error_t success) {
	if (success == SUCCESS) {
		_success = SUCCESS;
		post done();	
	} else
		post retry();	 
	}	 
	
	task void retry() {	
	if (numRetries++ < AGILLA_SNDR_MAX_RETRIES) {			
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SenderCoordinatorM: task retry(): Starting retry timer, numretries = %i\n", numRetries);
		#endif	
		call Retry_Timer.startOneShot(AGILLA_SNDR_RETRY_TIMER);
	} else {
		_success = FAIL;
		post done();
	}
	}
	
	/**
	 * The retry timer pauses the AgentSender for AGILLA_SNDR_RETRY_TIMER
	 * after which it restarts the send process from the beginning.
	 */
	event void Retry_Timer.fired() {
	post sendState();
	//return SUCCESS;
	}	
	
	event error_t RxnMgrI.rxnFired(Reaction* rxn, AgillaTuple* tuple) {
	return SUCCESS;
	}	
	
	default event void AgentSenderI.sendDone(AgillaAgentContext* context, uint8_t op, error_t success) {
	}
	
 /* command message_t* MessageBufferI.getBuffer() {	
	return &_msg;
	}*/
	
	command message_t* MessageBufferI.getMsg() {
	return &_msg;
	} 

	command error_t MessageBufferI.freeMsg(message_t* msg) {
	return SUCCESS;
	} 
}

