// $Id: OPtsM.nc,v 1.6 2006/02/11 20:04:48 chien-liang Exp $

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

module OPtsM {
	provides {
	interface BytecodeI;

	interface Init;
	}
	uses {
	interface AgentMgrI;
	interface TupleSpaceI;
	interface ErrorMgrI;
	interface QueueI;
	interface TupleUtilI;
	
	//interface SendMsg;	// debug
	}
}

implementation {
	Queue	blockedQ;

	command error_t Init.init() {
	return call QueueI.init(&blockedQ);	 // call QueueI.init(&waitingQ);
	}

 /* command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	} */

	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	error_t result;
	AgillaTuple template;
	AgillaTuple	tuple;
	
	// print debug statements
	switch(instr) {
		case IOPout:
		dbg("DBG_USR1", "VM (%i:%i): Executing OUT.\n", context->id.id, context->pc-1);
		break;
		case IOPin:
		dbg("DBG_USR1", "VM (%i:%i): Executing IN.\n", context->id.id, context->pc-1);
		break;
		case IOPrd:
		dbg("DBG_USR1", "VM (%i:%i): Executing RD.\n", context->id.id, context->pc-1);
		break;
		case IOPinp:
		dbg("DBG_USR1", "VM (%i:%i): Executing INP.\n", context->id.id, context->pc-1);
		break;
		case IOPrdp:
		dbg("DBG_USR1", "VM (%i:%i): Executing RDP.\n", context->id.id, context->pc-1);
		break;
		case IOPtcount:
		dbg("DBG_USR1", "VM (%i:%i): Executing tcount.\n", context->id.id, context->pc-1);
		break;
		case IOPremove:
		dbg("DBG_USR1", "VM (%i:%i): Executing remove.\n", context->id.id, context->pc-1);
		break;			
	}

	switch(instr) {
		case IOPout:
		if (call TupleUtilI.getTuple(context, &tuple) == SUCCESS) {
		
			call TupleUtilI.printTuple(&tuple);
		
			if (call TupleUtilI.checkFieldTypes(context, &tuple, AGILLA_VAR_ASRTVL) == SUCCESS) {
			if(call TupleSpaceI.out(&tuple) == SUCCESS) context->condition = 1;
			else context->condition = 0;
			return SUCCESS;
			} else {
			dbg("DBG_USR1", "ERROR: OPtsM: At least one tuple field is not an agentid, string, reading, type, value, or location.\n");			
			return FAIL;
			}		
		} else
			return FAIL;
		break;
		case IOPin:
		case IOPrd:
		if (context->rstate == AGILLA_RSTATE_EXEC) {
			call ErrorMgrI.error2d(context, AGILLA_ERROR_ILLEGAL_RXN_OP, context->id.id, context->pc-1);
			return FAIL;
		}		
		case IOPinp:
		case IOPrdp:
		case IOPremove:
		call TupleUtilI.getTuple(context, &tuple);	// get the template
		template = tuple;							 // make a copy of the tuple
		
		// push the tuple back onto the agent's stack if the 
		// instruction is IOPremove.
		if (instr == IOPremove)
			call TupleUtilI.pushTuple(&tuple, context);
			
		if (instr == IOPin || instr == IOPinp || instr == IOPremove)
			result = call TupleSpaceI.hinp(&tuple);
		else
			result = call TupleSpaceI.rdp(&tuple);

		if (instr != IOPremove)
		{
			if (result == SUCCESS) 
			{
			call TupleUtilI.pushTuple(&tuple, context); // match found
			if (instr == IOPinp || instr == IOPrdp)
				context->condition = 1;	// only set condition code for probing operations
			} else {
			if (instr == IOPin || instr == IOPrd) {
				dbg("DBG_USR1", "\t... no match found, blocking\n");
				call TupleUtilI.pushTuple(&template, context);	// save the template
				context->pc--;
				context->state = AGILLA_STATE_BLOCKED;
				call QueueI.enqueue(context, &blockedQ, context);	// no match, block
			} else 
				context->condition = 0;			
			}
		}
		return SUCCESS;
		break;
		case IOPtcount:
		call TupleUtilI.getTuple(context, &tuple);
		return call TupleSpaceI.count(context, &tuple);
		break;
	}
	return FAIL;
	}

	/**
	 * Signaled when a new tuple is inserted into the tuple space.
	 * This is necessary so blocked agents can be unblocked.
	 */
	event error_t TupleSpaceI.newTuple(AgillaTuple* tuple) {
	while (!call QueueI.empty(&blockedQ)) {
		call AgentMgrI.run(call QueueI.dequeue(NULL, &blockedQ));
	}
	return SUCCESS;
	}
 
	/**
	 * Signals that the tuple space has shifted bytes.	
	 * This indicates that a tuple is removed.
	 *
	 * @param from The first byte that was shifted.
	 * @param amount The number of bytes it was shifted by.
	 */
	event error_t TupleSpaceI.byteShift(uint16_t from, uint16_t amount) {
	return SUCCESS;
	} 

	// DEBUG
	//event result_t SendMsg.sendDone(TOS_MsgPtr m, result_t success) {
	// return SUCCESS;
	//}
}
