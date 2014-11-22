// $Id: OpStackM.nc,v 1.3 2005/12/09 04:12:20 chien-liang Exp $

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

/**
 * The operand stack behavioral implementation.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module OpStackM {
	provides interface OpStackI;	
	uses {	
	interface VarUtilI;
	interface TupleUtilI;
	interface ErrorMgrI;	 
	}
}
implementation {

	command error_t OpStackI.pushAgentID(AgillaAgentContext* context, AgillaAgentID* aID){
	AgillaVariable var;
	var.vtype = AGILLA_TYPE_AGENTID;
	var.id = *aID;
	return call OpStackI.pushOperand(context, &var);
	}

	command error_t OpStackI.pushString(AgillaAgentContext* context, uint16_t string) {
	AgillaVariable var;
	var.vtype = AGILLA_TYPE_STRING;
	var.string.string = string;
	return call OpStackI.pushOperand(context, &var);
	}

	command error_t OpStackI.pushLocation(AgillaAgentContext* context, AgillaLocation* loc) {
	AgillaVariable var;
	var.vtype = AGILLA_TYPE_LOCATION;
	var.loc = *loc;
	return call OpStackI.pushOperand(context, &var);	
	}

	command error_t OpStackI.pushReading(AgillaAgentContext* context, uint16_t type, int16_t reading) {
	AgillaVariable var;
	var.vtype = AGILLA_TYPE_READING;
	var.reading.type = type;
	var.reading.reading = reading;
	return call OpStackI.pushOperand(context, &var); 
	}
	
	command error_t OpStackI.pushType(AgillaAgentContext* context, uint16_t type) {
	AgillaVariable var;
	var.vtype = AGILLA_TYPE_TYPE;
	var.type.type = type;
	return call OpStackI.pushOperand(context, &var);
	}

	command error_t OpStackI.pushReadingType(AgillaAgentContext* context, uint16_t rtype) {
	AgillaVariable var;
	var.vtype = AGILLA_TYPE_STYPE;
	var.rtype.stype = rtype;
	return call OpStackI.pushOperand(context, &var); 
	}

	command error_t OpStackI.pushValue(AgillaAgentContext* context,	int16_t val) {
	AgillaVariable var;
	var.vtype = AGILLA_TYPE_VALUE;	
	var.value.value = val;
	return call OpStackI.pushOperand(context, &var); 
	}

	command error_t OpStackI.pushOperand(AgillaAgentContext* context, AgillaVariable* var) {
	uint16_t varSize = call VarUtilI.getSize(context, var->vtype);	
	
	#if DEBUG_OPSTACK
	dbg("DBG_USR1", "OpStackI.pushOperand(): Pushing an operand onto the stack.\n");
	#endif	
	
	if (varSize > 0) {
		if (context->opStack.sp + varSize + 1 < AGILLA_OPSTACK_SIZE) {
		memcpy((void*)&context->opStack.byte[context->opStack.sp], (void*)&var->loc, varSize);
		context->opStack.sp += varSize;
		context->opStack.byte[context->opStack.sp++] = var->vtype; 

		#if DEBUG_OPSTACK
		call OpStackI.toString(context);		
		#endif			

		return SUCCESS;
		} else {
		dbg("DBG_ERROR", "ERROR: OpStackI.pushOperand: Tried to push value off end of stack.\n");
		call ErrorMgrI.error(context, AGILLA_ERROR_STACK_OVERFLOW);		
		}			
	} else {
		#if DEBUG_OPSTACK
		dbg("DBG_USR1", "OpStackI.pushOperand(): ERROR: Tried to push an operand with 0 length.\n");
		#endif		
	}
	return FAIL;
	}

	command error_t OpStackI.popOperand(AgillaAgentContext* context, AgillaVariable* var) {
	if (context->opStack.sp == 0) {
		dbg("DBG_ERROR", "ERROR: OpStackI.popOperand: Tried to pop off end of stack.\n");
		call ErrorMgrI.error(context, AGILLA_ERROR_STACK_UNDERFLOW);
		var->vtype = AGILLA_TYPE_INVALID;
	} else {
		uint16_t varSize;
		
		#if DEBUG_OPSTACK
		dbg("DBG_USR1", "OpStackI.popOperand: Popping an operand off the stack.\n");
		#endif	 
		
		var->vtype = context->opStack.byte[--context->opStack.sp];
		varSize = call VarUtilI.getSize(context, var->vtype);		
		if (varSize > 0) {
		context->opStack.sp -= varSize;		
		memcpy((void*)&var->loc, (void*)&context->opStack.byte[context->opStack.sp], varSize);

		#if DEBUG_OPSTACK
			dbg("DBG_USR1", "OpStackI.popOperand: Final stack:\n");
			call OpStackI.toString(context);				
		#endif			 
				
		
		return SUCCESS;
		}
	}
	return FAIL;
	}
	
	command error_t OpStackI.peekOperand(AgillaAgentContext* context, AgillaVariable* var) {
	if (context->opStack.sp == 0) {
		dbg("DBG_ERROR", "ERROR: OpStackI.popOperand: Tried to pop off end of stack.\n");
		call ErrorMgrI.error(context, AGILLA_ERROR_STACK_UNDERFLOW);
		var->vtype = AGILLA_TYPE_INVALID;
	} else {
		uint16_t varSize;
		
		#if DEBUG_OPSTACK
		dbg("DBG_USR1", "OpStackI.peekOperand: Peeking at the top operand of the stack.\n");
		#endif	 
		
		var->vtype = context->opStack.byte[context->opStack.sp-1];
		varSize = call VarUtilI.getSize(context, var->vtype);		
		if (varSize > 0) {
		memcpy((void*)&var->loc, (void*)&context->opStack.byte[context->opStack.sp-varSize-1], varSize);
		return SUCCESS;
		}
	}
	return FAIL;
	}	

	command uint8_t OpStackI.getOpStackDepth(AgillaAgentContext* context) {
	return context->opStack.sp;
	}
	
	/**
	 * Returns the number of messages required to transfer the
	 * agent's operand stack.
	 */
	command uint8_t OpStackI.numOpStackMsgs(AgillaAgentContext* context) {				
	uint16_t result = context->opStack.sp/AGILLA_OS_MSG_SIZE;
	if (result * AGILLA_OS_MSG_SIZE < context->opStack.sp) {
		result++;
	}
	return result;	
	}
	
	/**
	 * Retrieves the operand stack data starting at the specified address
	 * by storing it in the provided op stack message.
	 *
	 * @param context The context containing the opstack
	 * @param addr The opstack address from which to start
	 * @param osMsg A pointer to the op stack message to fill.
	 * @return The op stack address to start at next time
	 */	
	command uint8_t OpStackI.fillMsg(AgillaAgentContext* context, uint8_t startAddr, 
	AgillaOpStackMsg* osMsg) 
	{
	size_t numBytes;
	uint16_t remaining = context->opStack.sp - startAddr;
	if (remaining > AGILLA_OS_MSG_SIZE)
		numBytes = AGILLA_OS_MSG_SIZE;
	else
		numBytes = remaining;
	memcpy((void*)&osMsg->data[0], (void*)&context->opStack.byte[startAddr], numBytes);
	return startAddr + numBytes;
	}
	
	/**
	 * Saves the data within an op stack message into the
	 * specified agent's context.
	 *
	 * @param context The context containing the opstack
	 * @param osMsg The op stack message.
	 * @return SUCCESS if the message is new, FAIL otherwise
	 */
	command error_t OpStackI.saveMsg(AgillaAgentContext* context, AgillaOpStackMsg* osMsg) {
	if (context->opStack.byte[osMsg->startAddr] != AGILLA_TYPE_INVALID) {
		return FAIL;
	} else {
		size_t numBytes;	
		uint8_t startAddr = osMsg->startAddr;
		if (startAddr + AGILLA_OS_MSG_SIZE <= context->opStack.sp)
		numBytes = AGILLA_OS_MSG_SIZE;
		else 
		numBytes = context->opStack.sp - startAddr;
		memcpy((void*)&context->opStack.byte[startAddr], (void*)&osMsg->data[0], numBytes);
		return SUCCESS;
	}
	}
	
	/**
	 * Resets the context's operand stack.
	 */
	command error_t OpStackI.reset(AgillaAgentContext* context) {
	int i;
	for (i = 0; i < AGILLA_OPSTACK_SIZE; i++) {
		context->opStack.byte[i] = AGILLA_TYPE_INVALID;		
	}
	context->opStack.sp = 0;
	return SUCCESS;
	}
	
	command error_t OpStackI.toString(AgillaAgentContext* context) {
	#ifdef __CYGWIN__
	uint8_t sp = context->opStack.sp;
	uint16_t varSize;
	AgillaVariable var;	
	dbg("DBG_USR1", "\t\t------ OpStack (AgentID: %i) State ------\n", context->id.id);
	while(sp > 0) {
		var.vtype = context->opStack.byte[--sp];
		varSize = call VarUtilI.getSize(context, var.vtype);
		if (varSize > 0) {
		sp -= varSize;
		memcpy((void*)&var.loc, (void*)&context->opStack.byte[sp], varSize);
		call TupleUtilI.printField(&var);
		}
	}
	dbg("DBG_USR1", "\t\t-------------------------------\n");	
	#endif
	return SUCCESS;
	}
}

