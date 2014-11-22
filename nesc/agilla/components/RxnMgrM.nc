// $Id: RxnMgrM.nc,v 1.8 2005/12/28 22:20:59 chien-liang Exp $

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

module RxnMgrM {
	provides {
	interface StdControl;
	interface RxnMgrI;
	interface Init;
	}
	uses {	
	interface AgentMgrI;
	interface AgentExecutorI;
	interface TupleUtilI;
	interface TupleSpaceI as TS;
	interface OpStackI;
	}
}
implementation {
	
	/**
	 * This is a buffer of reactions that have been registered by
	 * agents residing on this node.
	 */
	struct RxnBuf {
	int16_t index;			// the position within the tuple space
	bool isUsed;		// whether this buffer is used
	Reaction rxn;	 // the reaction
	} buffer[REACTION_MGR_BUFFER_SIZE];

	command error_t Init.init() {
	int i;
	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {
		buffer[i].isUsed = FALSE;
	}
	return SUCCESS;
	}

	command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}
	
	/**
	 * This is the main command of the RxnMgr.	It should be called whenever
	 * there is a chance that a reaction is enabled, or when an agent becomes
	 * capable of executing a reaction.
	 *
	 * Checks whether there are any agents that are
	 * not in the midst of executing a reaction's call-back function, and 
	 * have reactions that are enabled.
	 */
	command error_t RxnMgrI.runRxnMgr() {
	int i;

	#if DEBUG_RXNMGR
		dbg("DBG_USR1", "RxnMgrM: runRxnMgr(): Begin runRxnMgr()\n");
	#endif	 
	
	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {	
		if (buffer[i].isUsed) {		
		AgillaAgentContext* context = call AgentMgrI.getContext(&buffer[i].rxn.id);		
		
		if (context == NULL)
			continue;
		 
		#if DEBUG_RXNMGR
			dbg("DBG_USR1", "RxnMgrM: runRxnMgr(): Checking reaction belonging to %i\n", context->id.id);
			call TupleUtilI.printTuple(&buffer[i].rxn.template);
		#endif		
		
		
		// If the context is not currently running a reaction or in a queue, and the context is either
		// waiting, sleeping, or running...
		if (context->rstate != AGILLA_RSTATE_EXEC && context->queue == NULL &&
			(context->state == AGILLA_STATE_WAITING
			|| context->state == AGILLA_STATE_SLEEPING
			|| context->state == AGILLA_STATE_RUN)) 
		{
			AgillaTuple tuple;

			#if DEBUG_RXNMGR
			dbg("DBG_USR1", "RxnMgrM: Getting the next matching tuple, index = %i\n", buffer[i].index);			
			#endif						
			
			buffer[i].index = call TS.getMatchingTuple(buffer[i].index, 
			&buffer[i].rxn.template, &tuple);
			
			#if DEBUG_RXNMGR
			dbg("DBG_USR1", "RxnMgrM: new index = %i, tuple =\n", buffer[i].index);
			call TupleUtilI.printTuple(&tuple);
			#endif
			
			if (tuple.size > 0) {						
			
			#if DEBUG_RXNMGR
				dbg("DBG_USR1", "RxnMgrM: Agent %i's reaction fired!\n", context->id.id);
				call TupleUtilI.printTuple(&tuple);
			#endif	
			
			#if PRINT_RXN_FIRED
				dbg("DBG_USR1", "RxnMgrM: Agent %i's reaction fired!\n", context->id.id);
				call TupleUtilI.printTuple(&tuple);
			#endif	
						
			call OpStackI.pushValue(context, context->pc);	// save old PC onto the stack			
			context->pstate = context->state;				 // save the old state (if sleeping, continue to sleep)
			context->rstate = AGILLA_RSTATE_EXEC;			 // set reaction flag (tells VM that agent is executing reaction)
			
			#if DEBUG_RXNMGR
				dbg("DBG_USR1", "RxnMgrM: Saved agent %i's old PC (%i) onto stack!\n", context->id.id, context->pc);		
				call OpStackI.toString(context);
			#endif	 
		
			context->pc = buffer[i].rxn.pc;
			
			#if DEBUG_RXNMGR
				dbg("DBG_USR1", "RxnMgrM: Updated Agent %i's PC to %i!\n", context->id.id, context->pc);			
			#endif				
			
			call TupleUtilI.pushTuple(&tuple, context);		// push matching tuple
			if (context->pstate != AGILLA_STATE_RUN)
				call AgentMgrI.run(context);					// run the agent!
			} else {
			#if DEBUG_RXNMGR
				dbg("DBG_USR1", "RxnMgrM: runRxnMgr(): No more tuples left to check\n");
			#endif		
			}
		} else {
			#if DEBUG_RXNMGR
			dbg("DBG_USR1", "RxnMgrM: runRxnMgr(): The agent's state (%i) or rstate (%i) does not allow reactions\n", context->state, context->rstate);
			#endif		
		}
		}
	}
	return SUCCESS;
	}	// end command result_t runRxnMgr()
	
	
	inline int getRxnIndex(Reaction* rxn) {
	int i;
	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {
		if (buffer[i].isUsed) {
		if(rxn->id.id == buffer[i].rxn.id.id && rxn->pc == buffer[i].rxn.pc) {			
			if (call TupleUtilI.isEqual(&rxn->template, &buffer[i].rxn.template) == SUCCESS) {
			return i;
			}
		}
		}
	}
	return -1;	
	}
	
	/**
	 * Registers a reaction.	Find a free buffer and stores the reaction
	 * in it.
	 *
	 * @param rxn The reaction to register.
	 * @return SUCCESS or FAIL
	 */
	command error_t RxnMgrI.registerRxn(Reaction* rxn) {
	int i;
	
	#if DEBUG_RXNMGR
		dbg("DBG_USR1", "RxnMgrI.registerRxn(...): Registering reaction for agent %i.\n", rxn->id.id);
	#endif
	
	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {
		if (!buffer[i].isUsed) {
		buffer[i].isUsed = TRUE;
		buffer[i].rxn = *rxn;
		buffer[i].index = 0;

		#if DEBUG_RXNMGR
			dbg("DBG_USR1", "RxnMgrI.registerRxn(...): Registered reaction in buffer %i.\n", i);
		#endif
		return SUCCESS;
		}
	}
	return FAIL;
	}
	
	command error_t RxnMgrI.deregisterRxn(Reaction* rxn) {
	int i = getRxnIndex(rxn);
	
	#if DEBUG_RXNMGR
		dbg("DBG_USR1", "RxnMgrI.deregisterRxn(...): Deregistering reaction in buffer %i.\n", i);
	#endif
		
	if (i != -1) {
		buffer[i].isUsed = FALSE;
		return SUCCESS;
	} else
		return FAIL;
	}
	
	command uint16_t RxnMgrI.numRxns(AgillaAgentID* id) {
	uint16_t i, result = 0;

	#if DEBUG_RXNMGR
		dbg("DBG_USR1", "RxnMgrI.numRxnx(...): Finding the number of reactions registered by agent %i.\n", id->id);
	#endif	

	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {
		if (buffer[i].isUsed && id->id == buffer[i].rxn.id.id)				 
			result++;
	}

	#if DEBUG_RXNMGR
		dbg("DBG_USR1", "RxnMgrI.numRxnx(...): Agent %i registered %i reactions.\n", id->id, result);
	#endif		

	return result;
	}
	
	command error_t RxnMgrI.getRxn(AgillaAgentID* id, uint16_t which, Reaction* rxn) {
	uint16_t i, count = 0;
	
	#if DEBUG_RXNMGR
		dbg("DBG_USR1", "RxnMgrI.getRxn(...): Getting reaction %i of agent %i.\n", which, id->id);
	#endif		
	
	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {
		if (buffer[i].isUsed && id->id == buffer[i].rxn.id.id) {			
		
		#if DEBUG_RXNMGR
			dbg("DBG_USR1", "RxnMgrI.getRxn(...): Found reaction %i...\n", count);
		#endif			
		
		if (count == which) {
		
			#if DEBUG_RXNMGR
			dbg("DBG_USR1", "RxnMgrI.getRxn(...): Got reaction...\n");
			#endif 
		
			*rxn = buffer[i].rxn;
			return SUCCESS;
		} else
			count++;
		}
	}
	return FAIL;
	}
	
	command error_t RxnMgrI.isRegistered(Reaction* rxn) {	

	if(getRxnIndex(rxn) != -1) return SUCCESS;
	else return FAIL;
	}
	
	/**
	 * Deregister all reactions registered by a particular agent.
	 *
	 * @param id the agent whose reactions should be removed.
	 */
	command error_t RxnMgrI.flush(AgillaAgentID* id) {
	int16_t i;
	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {
		if (buffer[i].isUsed && id->id == buffer[i].rxn.id.id)					
		buffer[i].isUsed = FALSE;			 
	}	
	return SUCCESS;
	}
 
	/**
	 * This is called when an instruction finishes execution.
	 */
	//command error_t RxnMgrI.run() {
	// post runRxnMgr();
	// return SUCCESS;
	//}
	
	/**
	 * Indicates the tuple space has shifted bytes when a tuple is removed.
	 *
	 * @param from The first byte that was shifted.
	 * @param amount The number of bytes it was shifted by.
	 */
	event error_t TS.byteShift(uint16_t from, uint16_t amount) {
	int16_t i;
	for (i = 0; i < REACTION_MGR_BUFFER_SIZE; i++) {
		if (buffer[i].isUsed && buffer[i].index >= from)					
		buffer[i].index -= amount;
	}	
	return SUCCESS;	
	}

	/**
	 * Signaled when a new tuple is inserted into the tuple space.
	 * This is necessary so blocked agents can be unblocked, and the
	 * reaction manager can react to new tuples.
	 */
	event error_t TS.newTuple(AgillaTuple* tuple) {
	if (call AgentExecutorI.isIdle() == SUCCESS)
		call RxnMgrI.runRxnMgr();
	return SUCCESS;
	}
}
