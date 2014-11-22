// $Id: SenderCoordinatorM.nc,v 1.13 2006/04/07 01:14:44 borndigerati Exp $

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
	}
	uses {
	interface PartialAgentSenderI as SendState;
	interface PartialAgentSenderI as SendCode;
	interface PartialAgentSenderI as SendOpStack;
	interface PartialAgentSenderI as SendHeap;
	interface PartialAgentSenderI as SendRxn;
	interface Timer<TMilli> as Retry_Timer;

	interface NeighborListI;	//non utilizzato
	interface AddressMgrI;
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
	 *
	 * The one-hop destination (may != dest b/c of migration to UART)
	 */
	//uint16_t _oneHopDest;

	/**
	 * The value indicating whether the agent migration operation
	 * was successful.	This is passed to the callee via the
	 * sendDone(...) event.
	 */
	error_t _success;

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
	uint16_t dest, final_dest;
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

	task void done()
	{
	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SenderCoordinatorM: task done(): signalling AgentSenderI.sendDone() success = %i\n", _success);
	#endif

	signal AgentSenderI.sendDone(sBuf[stail].context, sBuf[stail].op, _success, sBuf[stail].final_dest);
	numRetries = 0;
	sBuf[stail].op = 0xff;
	stail = nextTail();
	if (sBuf[stail].op != 0xff)
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SenderCoordinatorM: task done(): Pending agent exists, sending state.\n");
		#endif
		post sendState();	// send the next agent in the queue
	} else
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SenderCoordinatorM: task done(): No pending agent exists, entering IDLE state.\n");
		#endif
		state = IDLE;		// no more agents to send, change to IDLE state
	}
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
	 * @param final_dest The final destination location.
	 */
	command error_t AgentSenderI.send(AgillaAgentContext* context,
	AgillaAgentID id, uint8_t op, uint16_t dest, uint16_t final_dest)
	{
	if (queueHasRoom() == SUCCESS) {
		struct OutgoingAgent* buff = &sBuf[shead];
		buff->id = id;
		buff->op = op;
		buff->dest = dest;
		buff->final_dest = final_dest;
		buff->context = context;
		context->state = AGILLA_STATE_LEAVING;
		shead = nextHead();
		if (state == IDLE) {
		state = SENDING;
		return post sendState();
		} else
		return SUCCESS;
	} else
	{
		dbg("DBG_USR1", "SendCoordinatorM: AgentSenderI.send(): ERROR: Send queue full, returning FAIL.\n");
		call ErrorMgrI.errord(context, AGILLA_ERROR_SEND_BUFF_FULL, stail);
		return FAIL;
	}
	}

//STATE-----------------------------------------------------------------------------------------------
	task void sendState() {
	if(call SendState.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op,
		sBuf[stail].dest, sBuf[stail].final_dest) != SUCCESS)
	{
		dbg("DBG_USR1", "SendCoordinatorM: sendState(): Failed to send state, retrying.\n");
		post retry();
	} else
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: sendState(): Sending State...\n");
		#endif
	}
	}

	event void SendState.sendDone(AgillaAgentContext* context, error_t success) {
	if (success == SUCCESS)
		post sendCode();
	else if (success == REJECT)
	{
		dbg("DBG_USR1", "SendCoordinatorM: SendState.sendDone(): ERROR: Migration was rejected (lack of memory).\n");
		_success = REJECT;
		post done();
	} else
	{
		dbg("DBG_USR1", "SendCoordinatorM: SendState.sendDone(): Failed to send state, retrying.\n");
		post retry();
	}
	}

//CODE------------------------------------------------------------------------------------------------
	task void sendCode() {
	if(call SendCode.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op,
		sBuf[stail].dest, sBuf[stail].final_dest) != SUCCESS)
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: task sendCode(): FAILED to send code, retrying.\n");
		#endif
		post retry();
	}
	}

	event void SendCode.sendDone(AgillaAgentContext* context, error_t success)
	{
	if (success == SUCCESS)
	{
		if (sBuf[stail].op == IOPhalt || sBuf[stail].op == IOPsmove || sBuf[stail].op == IOPsclone)
		{
		if (call HeapMgrI.hasHeap(sBuf[stail].context) == SUCCESS)
			post sendHeap();
		else if (call OpStackI.numOpStackMsgs(sBuf[stail].context) > 0)
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
		//call Leds.led1On();
		post retry();
	}
	}

//HEAP------------------------------------------------------------------------------------------------
	task void sendHeap() {
	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: Sending Heap...\n");
	#endif
	if(call SendHeap.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op,
		sBuf[stail].dest, sBuf[stail].final_dest) != SUCCESS)
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: FAILED to send heap, retrying.\n");
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
	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: Sending OpStack...\n");
	#endif
	if(call SendOpStack.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op,
		sBuf[stail].dest, sBuf[stail].final_dest) != SUCCESS)
	{
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
	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SendCoordinatorM: Sending Rxns...\n");
	#endif
	if(call SendRxn.send(sBuf[stail].context, sBuf[stail].id, sBuf[stail].op,
		sBuf[stail].dest, sBuf[stail].final_dest) != SUCCESS)
	{
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

	task void retry()
	{

	#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SenderCoordinatorM: task retry(): Begin Task, numRetries = %i\n", numRetries);
	#endif

	if (numRetries++ < AGILLA_SNDR_MAX_RETRIES)
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SenderCoordinatorM: task retry(): Starting retry timer, numRetries = %i\n", numRetries);
		#endif
		_success = SUCCESS;
		call Retry_Timer.startOneShot(AGILLA_SNDR_RETRY_TIMER);
	} else
	{
		#if DEBUG_AGENT_SENDER
		dbg("DBG_USR1", "SenderCoordinatorM: task retry(): Maximum number of numRetries reached (%i), aborting.\n", numRetries);
		#endif

		_success = FAIL;
		call Retry_Timer.startOneShot(AGILLA_SNDR_ABORT_TIMER);
	}
	}

	/**
	 * The retry timer pauses the AgentSender for AGILLA_SNDR_RETRY_TIMER
	 * after which it restarts the send process from the beginning.
	 */
	event void Retry_Timer.fired()
	{
	if (_success == SUCCESS)
		post sendState();
	else
		post done();
	//return SUCCESS;
	}

	//event error_t RxnMgrI.rxnFired(Reaction* rxn, AgillaTuple* tuple) {
	// return SUCCESS;
	//}

	default event void AgentSenderI.sendDone(AgillaAgentContext* context, uint8_t op, error_t success, uint16_t dest) {
	}
}

