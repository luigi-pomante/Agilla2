// $Id: OPrxnM.nc,v 1.5 2006/02/06 09:40:40 chien-liang Exp $

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
 * Implements instructions regrxn and deregrxn.
 *
 * @author Chien-Liang Fok
 */

#include "Agilla.h"
#include "AgillaOpcodes.h"
#include "TupleSpace.h"

module OPrxnM {	
	provides interface BytecodeI;
	uses {
	interface TupleUtilI as TupleUtil;
	interface AgentMgrI;
	interface RxnMgrI;
	interface OpStackI as Stacks;		
	interface ErrorMgrI as Error;		 
	}
}
implementation {	
	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable arg1;

	// get the reaction's pc		
	if (call Stacks.popOperand(context, &arg1) == SUCCESS) {
		if (!(arg1.vtype & AGILLA_VAR_V)) {
		call Error.error(context, AGILLA_ERROR_TYPE_CHECK);
		dbg("DBG_USR1", "VM (%i:%i): Invalid pc type.\n", context->id.id, context->pc-1);
		return FAIL;
		}
	
		if (instr == IOPendrxn) {		
		dbg("DBG_USR1", "VM (%i:%i): Executing endrxn, pc = %i\n", context->id.id, context->pc-1, arg1.value.value);		
		context->pc = arg1.value.value;		
		context->state = context->pstate;
		context->rstate = AGILLA_RSTATE_IDLE;
		
		// If the agent was sleeping before the reaction occured and is
		// still sleeping, let it continue to sleep.	Otherwise, run it!
		if (context->pstate != AGILLA_STATE_SLEEPING) {
			#if DEBUG_OP_RXN
			dbg("DBG_USR1", "OPRxnM: Running agent %i\n", context->id.id);		
			#endif
			call AgentMgrI.run(context);			 
		} else {
			#if DEBUG_OP_RXN
			dbg("DBG_USR1", "OPRxnM: Not Running agent %i, pstate = %i\n", context->id.id, context->pstate);		
			#endif		
		}
		//call RxnMgrI.runRxnMgr();
		}
		else {	// the instruction is either regrxn or deregrxn	
		Reaction rxn;			
		rxn.id = context->id;
		rxn.pc = arg1.value.value;
		call TupleUtil.getTuple(context, &rxn.template);	

		if (instr == IOPregrxn) {
			dbg("DBG_USR1", "VM (%i:%i): Executing regrxn\n", context->id.id, context->pc-1);
			call RxnMgrI.registerRxn(&rxn);				
		} else {
			dbg("DBG_USR1", "VM (%i:%i): Executing deregrxn\n", context->id.id, context->pc-1);
			call RxnMgrI.deregisterRxn(&rxn);	
		}	
		return SUCCESS;	
		}		
	}
	return FAIL;
	}
	
	//event result_t RxnMgrI.rxnFired(Reaction* rxn, AgillaTuple* tuple) {
	// return SUCCESS;
	//}
}
