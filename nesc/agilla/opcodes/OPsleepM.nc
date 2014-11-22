// $Id: OPsleepM.nc,v 1.6 2006/02/12 08:35:57 chien-liang Exp $

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
 * @author Chien-Liang Fok
 */
#include "Agilla.h"
#include "Timer.h"

module OPsleepM {	
	provides {

	interface Init;
	interface BytecodeI;
	}	
	uses {
	interface OpStackI;	
	interface QueueI;
	interface ErrorMgrI;
	interface AgentMgrI;	 
	interface Timer<TMilli> as Timer0;
	interface Timer<TMilli> as Timer1;
	interface Timer<TMilli> as Timer2;
	//interface Timer as Timer3;	
	}
}
implementation {	
	#define NUM_SLEEP_TIMERS 3
	
	Queue waitQueue;	
	AgillaAgentContext* buff[NUM_SLEEP_TIMERS];
	
	command error_t Init.init() {
	int i;
	for (i = 0; i < NUM_SLEEP_TIMERS; i++) {
		buff[i] = NULL;
	}
	call QueueI.init(&waitQueue);		 
	return SUCCESS;
	}
	
 /* command error_t StdControl.start() {
	return SUCCESS;
	}
	
	command error_t StdControl.stop() {
	return SUCCESS;
	} */
	
	inline int getFreeBuff(AgillaAgentContext* context) {
	int i;
	for (i = 0; i < NUM_SLEEP_TIMERS; i++) {
		if (buff[i] == NULL)
		return i;
	}	
	return -1;
	}
	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	uint32_t amount, i;
	AgillaVariable arg;

	if (context->rstate == AGILLA_RSTATE_EXEC) {
		call ErrorMgrI.error2d(context, AGILLA_ERROR_ILLEGAL_RXN_OP, context->id.id, context->pc-1);
		return FAIL;
	}
	
	if (call OpStackI.popOperand(context, &arg) == SUCCESS) {
		
		if (!(arg.vtype & AGILLA_VAR_V)) {
		call ErrorMgrI.error(context, AGILLA_ERROR_TYPE_CHECK);
		dbg("DBG_USR1", "VM (%i:%i): Invalid sleep length, type = %i.\n", context->id.id, context->pc-1, arg.vtype);
		return FAIL;
		}	 
		
		//amount = (arg.value.value << 7);
		
		// this allows one to sleep beyond 255 (1/8s)
		amount = (uint32_t)arg.value.value * (uint32_t)128;
		
		dbg("DBG_USR1", "VM (%i:%i): Executing sleep %i, amount = %i\n", context->id.id, context->pc-1, arg.value.value, amount);	
					
		context->state = AGILLA_STATE_SLEEPING;	 
		i = getFreeBuff(context);			
		if (i != -1) {		
		buff[i] = context;
		switch (i) {
		case 0:
			#if DEBUG_OP_SLEEP
			dbg("DBG_USR1", "OPSlEEP(%i): Starting sleep timer 0 for %i ms\n", context->id.id, amount);
			#endif		 
			call Timer0.startOneShot(amount);
			break;
		case 1:
			#if DEBUG_OP_SLEEP
			dbg("DBG_USR1", "OPSlEEP(%i): Starting sleep timer 1 for %i ms\n", context->id.id, amount);
			#endif		 
			call Timer1.startOneShot(amount);
			break;
		//case 2:
		default:
			#if DEBUG_OP_SLEEP
			dbg("DBG_USR1", "OPSlEEP(%i): Starting sleep timer 2 for %i ms\n", context->id.id, amount);
			#endif		 
			call Timer2.startOneShot(amount);
			break;
		/*default:
			#if DEBUG_OP_SLEEP
			dbg(DBG_USR1, "OPSlEEP(%i): Starting sleep timer 3 for %i ms\n", context->id.id, amount);
			#endif		 
			call Timer3.start(TIMER_ONE_SHOT, amount);*/
		} // switch
		return SUCCESS;	
		} else {
		
		#if DEBUG_OP_SLEEP
		dbg("DBG_USR1", "OPSlEEP(%i): Nore more buffer space, forcing agent to wait.\n", context->id.id, amount);
		#endif			 
		
		call OpStackI.pushValue(context, arg.value.value); // push value back onto stack	
		context->pc--; // re-run this instruction
		call QueueI.enqueue(context, &waitQueue, context); // store waiting context		
		}
	}
	return FAIL;
	}
	
	inline error_t handleTimer(int i) {	
	#if DEBUG_OP_SLEEP
		dbg("DBG_USR1", "OPSlEEP (%i): handleTimer(): Timer %i fired!!\n", buff[i]->id.id, i);
	#endif
	
	// If the sleep operation completes while the agent is executing a reaction,
	// let it finish executing the reaction's code.
	if (buff[i]->rstate == AGILLA_RSTATE_EXEC) {
		#if DEBUG_OP_SLEEP
		dbg("DBG_USR1", "OPsleepM: Timer.fired(): Done sleeping, but agent %i is executing a reaction.\n",buff[i]->id.id);
		#endif		
		buff[i]->pstate = AGILLA_STATE_RUN;
	} else {
		#if DEBUG_OP_SLEEP
		dbg("DBG_USR1", "OPsleepM: Timer.fired(): Done sleeping, running agent %i.\n",buff[i]->id.id);
		#endif	
		call AgentMgrI.run(buff[i]);
	}
	buff[i] = NULL;

	// Resume all agents in the wait queue.	It is necessary to
	// resume all agents because some of their reactions may be enabled.
	while (!call QueueI.empty(&waitQueue)) {		
		AgillaAgentContext* context = call QueueI.dequeue(NULL, &waitQueue);
		
		#if DEBUG_OP_SLEEP
		dbg("DBG_USR1", "OPsleepM: Timer.fired(): Resuming context text %i.\n",context->id.id);
		#endif
		
		call AgentMgrI.run(context);		
	}	
	return SUCCESS;
	}

	event void Timer0.fired() {		
	handleTimer(0);
	}
	
	event void Timer1.fired() {		
	handleTimer(1);
	}
	
	event void Timer2.fired() {		
	handleTimer(2);
	}
	
	/*event result_t Timer3.fired() {		
	return handleTimer(3);
	}*/
}
