// $Id: AgentMgrM.nc,v 1.28 2006/04/27 23:53:18 chien-liang Exp $

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
#include "AgillaOpcodes.h"
#include "LEDBlinker.h"
#include "Timer.h"

/**
 * Manages agent contexts.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module AgentMgrM {
	provides {
	interface StdControl;
	interface Init;
	interface AgentMgrI;
	}
	uses {
	interface CodeMgrI;
	interface AgentExecutorI;
	interface AgentSenderI;
	interface AgentReceiverI;

	interface NeighborListI;
	interface SystemTSMgrI;
	interface TupleUtilI;
	interface HeapMgrI;
	interface OpStackI;
	interface RxnMgrI;
	interface LocationMgrI;
	//interface Timer as SimTimer;	// used for TOSSIM
	interface LEDBlinkerI;
	interface Boot;

	interface LocationReporterI;
	interface Timer<TMilli> as LocationUpdateTimer;

	#if ENABLE_EXP_LOGGING
		interface ExpLoggerI;
	#endif
	}
}
implementation {

	#if INCLUDE_DEFAULT_AGENT
	AgillaCodeMsg cMsg;
	#endif

	AgillaAgentContext agents[AGILLA_NUM_AGENTS]; // the agent contexts
	uint8_t idCount;	// unique Agent ID count

	/**
	 * OUTs an AgillaAgentID tuple into the tuple space, then
	 * starts the agent running.
	 */
	inline void runNewAgent(AgillaAgentContext* context) {
	call SystemTSMgrI.outAgentTuple(context->id);	 // out an agentID tuple
	call AgentMgrI.run(context);
	}

	/**
	 * Generate a new agent ID.
	 */
	inline uint16_t getNewID() {
	uint16_t newid;
	newid = (uint16_t)TOS_NODE_ID;
	newid = newid << 8;
	newid += idCount++;
	return newid;
	}

	command error_t Init.init() {
	call AgentMgrI.resetAll();
	return SUCCESS;
	}

	event void Boot.booted(){
	 #if INCLUDE_DEFAULT_AGENT
		if (TOS_NODE_ID == 0)
		{
		#include "default_agent.ma"
		//runNewAgent(&agents[0]);
		call AgentSenderI.send(&agents[0], agents[0].id, IOPwmove, 1, 1);
		 }
	 #endif
	
		// Start the timer that periodically sends location update messages to the
		// base station.
		call LocationUpdateTimer.startPeriodic(AGILLA_LOCATION_UPDATE_TIMER);
	
		dbg("DBG_USR1", "AgentMgrI.start(): Agilla host %i started...\n", TOS_NODE_ID);
	} 

	command error_t StdControl.start() {
	 
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}

	command error_t AgentMgrI.resetAll() {
	int i;
	idCount = 0;
	for (i = 0; i < AGILLA_NUM_AGENTS; i++) {
		call AgentMgrI.reset(&agents[i]);
	}
	return SUCCESS;
	}

	/**
	 * Resets an agent's context.	Frees all resources being consumed by
	 * the agent.	If an experiment is running, it saves timming information
	 * as needed.
	 *
	 * @param context The context of the agent being reset.
	 */
	command error_t AgentMgrI.reset(AgillaAgentContext* context) {
	#if DEBUG_AGENT_MGR
		dbg("DBG_USR1", "AgentMgrI.reset(): Resetting agent %i...\n", context->id.id);
	#endif

	call SystemTSMgrI.inAgentTuple(context->id);
	call CodeMgrI.deallocateBlocks(context);
	call OpStackI.reset(context);
	call HeapMgrI.reset(context);
	call RxnMgrI.flush(&context->id);

	context->state = AGILLA_STATE_HALT;
	context->rstate = AGILLA_RSTATE_IDLE;
	context->queue = NULL;
	context->pc = 0;
	context->id.id = 0;

	#if DEBUG_AGENT_MGR
		dbg("DBG_USR1", "AgentMgrI.reset(): Done resetting agent.\n");
	#endif

	return SUCCESS;
	}

	/**
	 * Returns the number of agents running (or arriving) on this host.
	 */
	command int AgentMgrI.numAgents() {
	int i, result = 0;
	for (i = 0; i < AGILLA_NUM_AGENTS; i++) {
		if (agents[i].state != AGILLA_STATE_HALT)
		result++;
	}
	return result;
	}

	command AgillaAgentContext* AgentMgrI.getContext(AgillaAgentID* id) {
	int i;
	#if DEBUG_AGENT_MGR
		dbg("DBG_USR1", "AgentMgrI.getContext(): Getting agent context %i...\n", id->id);
	#endif
	for(i=0; i < AGILLA_NUM_AGENTS; i++) {
		if (agents[i].id.id == id->id && agents[i].state != AGILLA_STATE_HALT)
		return &agents[i];
	}
	#if DEBUG_AGENT_MGR
		dbg("DBG_USR1", "AgentMgrI.getContext(): Got agent %i...\n", id->id);
	#endif
	return NULL;
	}

	/**
	 * Allocates and returns a context for an agent.	It reserves the minimum
	 * number of code blocks necessary to hold the agent.
	 *
	 * @param id The id of the new agent.
	 * @param codeSize The number of instructions.
	 * @return The context for the agent or NULL if there is not enough free space.
	 */
	command AgillaAgentContext* AgentMgrI.getFreeContext(AgillaAgentID *id, uint16_t codeSize) {
	int i;
	for (i = 0; i < AGILLA_NUM_AGENTS; i++)
	{
		if (agents[i].state == AGILLA_STATE_HALT)
		{
		if (call CodeMgrI.allocateBlocks(&agents[i], codeSize) == SUCCESS)
		{
			agents[i].id = *id;
			agents[i].pc = 0;
			agents[i].condition = 0;
			agents[i].state = AGILLA_STATE_ARRIVING;
			return &agents[i];
		} else
		{
			dbg("DBG_USR1", "AgentMgrI.getFreeContext: ERROR: Unable to allocate code blocks.\n");
		}
		}
	}
	return NULL;
	}

	command AgillaAgentContext* AgentMgrI.getIncommingContext(AgillaAgentID* id) {
	int i;
	for(i=0; i < AGILLA_NUM_AGENTS; i++) {
		if (agents[i].state == AGILLA_STATE_ARRIVING && agents[i].id.id == id->id) {
			return &agents[i];
		}
	}
	return NULL;
	}

	/**
	 * Migrate an agent to the destination mote.
	 *
	 * @param context The agent to migrate.
	 * @param dest The the one-hop destination mote.
	 * @param final_dest The final destination mote, e.g., TOS_UART_ADDRESS.
	 * @param op The opcode that the agent is executing.
	 */
	command error_t AgentMgrI.migrate(AgillaAgentContext* context, uint16_t dest,
	uint16_t final_dest, uint8_t op)
	{
	AgillaAgentID id = context->id;

	#if ENABLE_EXP_LOGGING
		AgillaLocation loc;
		call LocationMgrI.getLocation(final_dest, &loc);
		call ExpLoggerI.sendTraceQid(context->id.id, TOS_NODE_ID, AGENT_MIGRATING, TOS_NODE_ID, SUCCESS, loc);
	#endif

	if (dest == TOS_NODE_ID)
	{
		#if DEBUG_AGENT_MGR
		dbg("DBG_USR1", "AgentMgrM: Agent migrating to self (%i).\n", dest);
		#endif

		if (op == IOPsmove)
		return SUCCESS;

		if (op == IOPwmove)
		{
		context->condition = 1; // move was successful
		context->pc = 0; // reset pc
		call OpStackI.reset(context);
		call HeapMgrI.reset(context);
		call RxnMgrI.flush(&context->id);
		return SUCCESS;
		}

		// If the agent clones to self, go through the usual
		// cloning operation.
	}

	if (op == IOPsclone || op == IOPwclone)
		id.id = getNewID();

	#if DEBUG_AGENT_MGR
		dbg("DBG_USR1", "AgentMgrM: migrating agent:\n\tid = %i\n\top = %i\n\tdest = 0x%x\n\tfinal_dest = 0x%x\n",
		id.id, op, dest, final_dest);
	#endif

	return call AgentSenderI.send(context, id, op, dest, final_dest);
	}

	/**
	 * This is signaled when an agent has finished migrating.
	 * If the operation was a MOVE and was successful, or the agent
	 * just bounced off this node, the context is
	 * reset.	If it was not successful, or if the operation was a clone,
	 * the context is resumed on this node.
	 */
	event void AgentSenderI.sendDone(AgillaAgentContext* context, uint8_t op,
	error_t success, uint16_t dest)
	{
	if (op == IOPsmove || op == IOPwmove)
	{
		if (success == FAIL)
		{
		context->condition = 0;
		call AgentMgrI.run(context);	 // move failed (set condition = 0, resume running)
		} else if (success == SUCCESS)
		call AgentMgrI.reset(context); // move succeeded
		else if (success == REJECT)
		{
		context->condition = 3;
		call AgentMgrI.run(context);	 // move failed b/c of rejection (set condition = 3, resume running)
		}
	} else if (op == IOPsclone || op == IOPwclone) {
		if (success == SUCCESS)
		context->condition = 2;	// indicate this is the parent agent
		else if (success == REJECT)
		context->condition = 3; // indicate this is the parent, but the clone failed b/c of rejection
		else
		context->condition = 0; // indicate this is the parent, but the operation failed.
		call AgentMgrI.run(context);
	} else
		call AgentMgrI.reset(context); // the agent bounced off this node
	}

	/**
	 * This event is signaled whenever a new agent has arrived.
	 *
	 * @param context The context of the agent that just arrived.
	 */
	event void AgentReceiverI.receivedAgent(AgillaAgentContext* context,
	uint16_t dest)
	{
	if (dest == TOS_NODE_ID) {

		// send the agent migration trace to the base station
		#if ENABLE_EXP_LOGGING
		AgillaLocation loc;
		call LocationMgrI.getLocation(TOS_NODE_ID, &loc);
		call ExpLoggerI.sendTraceQid(context->id.id, TOS_NODE_ID, AGENT_MOVED, TOS_NODE_ID, SUCCESS, loc);
		#endif

		/*#ifdef PACKET_SIM_H_INCLUDED
		uint8_t instr;
		uint16_t i = 0;
		dbg("DBG_USR1", "Agent ID: %i\n", context->id.id);
		dbg("DBG_USR1", "Agent PC: %i\n", context->pc);
		dbg("DBG_USR1", "Agent CodeSize: %i\n", context->codeSize);
		dbg("DBG_USR1", "Agent Condition: %i\n", context->condition);
		dbg("DBG_USR1", "Agent instructions:\n");
		while(1) {
			instr = call CodeMgrI.getInstruction(context, i++);
			dbg("DBG_USR1", "\t%i: 0x%x\n", i-1, instr);
			if (i == context->codeSize)
			break;
		}
		#endif*/
		runNewAgent(context);
	} else {
		uint16_t oneHopDest = dest;
		error_t forward = SUCCESS;

		//call Leds.redToggle();
		//call Leds.greenToggle();
		//call ArrivalLedTimer.start(TIMER_ONE_SHOT, ARRIVAL_LED_TIME);
		call LEDBlinkerI.blink((uint8_t)RED | GREEN, (uint8_t)1, ARRIVAL_LED_TIME);

		#if ENABLE_GRID_ROUTING
		forward = call NeighborListI.getClosestNeighbor(&oneHopDest);
		#endif

		if (forward == SUCCESS)
		{
			// Use opcode IOPhalt so the AgentMgrI knows that the agent was just
			// bounced off this node and should be reset.	Note that the final
			// destination is the same as the one-hop destination since Agilla
			// only supports physically one-hop networks.	This destination is
			// most likely TOS_UART_ADDRESS.
			call AgentMgrI.migrate(context, oneHopDest, dest, IOPhalt);
		}
		else
		{
			call AgentMgrI.reset(context);
		}
	}
	}

	/**
	 * Signalled when the blinking is done and blink(...) can be called again.
	 */
	event error_t LEDBlinkerI.blinkDone() {
	return SUCCESS;
	}

	/*event result_t ArrivalLedTimer.fired() {
	call Leds.redToggle();
	call Leds.greenToggle();
	return SUCCESS;
	}*/

	/**
	 * Sets the agent's state to be AGILLA_STATE_RUN and calls
	 * AgentExecutorI.run(...).
	 *
	 * @param context The agent context that is ready to run.
	 * @return SUCCESS If the agent is scheduled to run.
	 */
	command error_t AgentMgrI.run(AgillaAgentContext* context) {
	if (context->state != AGILLA_STATE_HALT) {
		context->state = AGILLA_STATE_RUN;
		return call AgentExecutorI.run(context);
	} else
		return FAIL;
	}

	/**
	 * Retuns the index of the agent context with the specified AgentID.
	 */
	inline int getIndexOf(AgillaAgentID* id) {
	int i;
	for (i=0; i < AGILLA_NUM_AGENTS; i++) {
		if (agents[i].state != AGILLA_STATE_HALT && agents[i].id.id == id->id)
		return i;
	}
	return -1;
	}

	/**
	 * Returns SUCCESS if the agent is present and has a state other
	 * than AGILLA_STATE_ARRIVING.
	 */
	command error_t AgentMgrI.isPresent(AgillaAgentID* id) {
	int i = getIndexOf(id);
	if (i == -1 || agents[i].state == AGILLA_STATE_ARRIVING)
		return FAIL;
	else
		return SUCCESS;
	}

	/*event result_t RxnMgrI.rxnFired(Reaction* rxn, AgillaTuple* tuple) {
	int i = getIndexOf(&rxn->id);
	if (i != -1) {

		#if DEBUG_AGENT_MGR
		dbg(DBG_USR1, "AgentMgrM: event RxnMgrI.rxnFired(): Agent %i's reaction fired!\n", agents[i].id.id);
		call TupleUtilI.printTuple(tuple);
		#endif

		if (agents[i].state != AGILLA_STATE_LEAVING) {
		call OpStackI.pushValue(&agents[i], agents[i].pc); // store the old pc on top of the stack

		#if DEBUG_AGENT_MGR
			dbg(DBG_USR1, "AgentMgrM: event RxnMgrI.rxnFired(): Saved agent %i's old PC %i onto stack!\n", agents[i].id.id, agents[i].pc);
			call OpStackI.toString(&agents[i]);
		#endif

		agents[i].pc = rxn->pc;							// update pc

		#if DEBUG_AGENT_MGR
			dbg(DBG_USR1, "AgentMgrM: event RxnMgrI.rxnFired(): Updated Agent %i's PC to %i!\n", agents[i].id.id, agents[i].pc);
		#endif

		call TupleUtilI.pushTuple(tuple, &agents[i]);	 // push matching tuple
		if (agents[i].state == AGILLA_STATE_WAITING)
			 call AgentMgrI.run(&agents[i]);	// run agent if it had executed instr wait
		} else {
		#if DEBUG_AGENT_MGR
		dbg(DBG_USR1, "AgentMgrM: event RxnMgrI.rxnFired(): ERROR: Agent %i is leaving!\n", rxn->id.id);
		#endif
		}
	} else {
		#if DEBUG_AGENT_MGR
		dbg(DBG_USR1, "AgentMgrM: event RxnMgrI.rxnFired(): ERROR: Agent %i is not present!	Could not get index!\n", rxn->id.id);
		#endif
	}
	return SUCCESS;
	}*/
	
	
	/**
	 * Send a location update heartbeat to the base station.
	 */
	event void LocationUpdateTimer.fired() {
	int i;
	for (i=0; i < AGILLA_NUM_AGENTS; i++) {
		if (agents[i].state != AGILLA_STATE_HALT)
		call LocationReporterI.updateLocation(&agents[i]);
	}
	//return SUCCESS;	
	}
}


