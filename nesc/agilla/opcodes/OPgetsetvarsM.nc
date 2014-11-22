// $Id: OPgetsetvarsM.nc,v 1.3 2006/02/06 09:40:40 chien-liang Exp $

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

/**
 * Saves and retrieves values from the heap, where the
 * address is stored on the stack.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module OPgetsetvarsM {
	provides interface BytecodeI;
	uses {
	interface ErrorMgrI as Error;	
	interface OpStackI as Stacks;
	}
}
implementation {	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable addr;	
	if (call Stacks.popOperand(context, &addr) == SUCCESS) 
	{ 
		// fetch the address
		if (addr.vtype != AGILLA_TYPE_VALUE) 
		{
		call Error.error(context, AGILLA_ERROR_TYPE_CHECK);
		dbg("DBG_USR1", "VM (%i:%i): Invalid heap address type (%i).\n", context->id.id, context->pc-1, (int)addr.vtype);
		return FAIL;
		}
		
		// check whether address is out of bounds
		if (addr.value.value >= AGILLA_HEAP_SIZE) {
		dbg("DBG_USR1", "VM (%i:%i): ERROR: Heap Index out of range %i.\n", context->id.id, context->pc-1, (int)addr.value.value);
		call Error.error(context, AGILLA_ERROR_INDEX_OUT_OF_BOUNDS);
		return FAIL;	
		}	 
		
		if (instr == IOPsetvars) { // set var	 
		AgillaVariable var;
		if (call Stacks.popOperand(context, &var) == SUCCESS) {			
			if (!(var.vtype & AGILLA_VAR_ASRTVL)) {
			dbg("DBG_USR1", "VM (%i:%i): ERROR: Variable not an agentid, name, reading, type, or value.\n", context->id.id, context->pc-1);
			call Error.errord(context, AGILLA_ERROR_INVALID_TYPE, 0x0d);
			return FAIL;
			}
			dbg("DBG_USR1", "VM (%i:%i): Executing setvars addr = %i.\n", context->id.id, context->pc-1, (int)addr.value.value);
			context->heap.pos[addr.value.value] = var;
			return SUCCESS;
		}
		} else { // get var
		dbg("DBG_USR1", "VM (%i:%i): Executing getvars %i.\n", context->id.id, context->pc-1, (int)addr.value.value);
		call Stacks.pushOperand(context, &context->heap.pos[addr.value.value]);
		return SUCCESS;
		}
	}
	return FAIL;
	}
}
