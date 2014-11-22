// $Id: OPincM.nc,v 1.2 2006/01/21 03:18:21 chien-liang Exp $

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
 * Increments the value on top of the stack.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module OPincM {
	provides interface BytecodeI;	
	uses {
	interface OpStackI as Stacks;
	interface ErrorMgrI as Error;
	}
}
implementation {	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable arg;
	if (call Stacks.popOperand(context, &arg) == SUCCESS) {
		if (arg.vtype == AGILLA_TYPE_VALUE) {
		dbg("DBG_USR1", "VM (%i:%i): Executing inc of value %i = %i\n", context->id.id, context->pc-1, arg.value.value, arg.value.value + 1);
		return call Stacks.pushValue(context, arg.value.value + 1);				
		} else if (arg.vtype == AGILLA_TYPE_LOCATION) {
		AgillaLocation newLoc;
		int16_t mode = 0;			
		bool compareX = TRUE, compareY = TRUE;
		if (context->heap.pos[AGILLA_HEAP_LOC_INDEX].vtype == AGILLA_TYPE_VALUE) 
		{
			mode = context->heap.pos[AGILLA_HEAP_LOC_INDEX].value.value;
			if (mode == 1)
			compareY = FALSE;
			else if (mode == 2)
			compareX = FALSE;				 
		} 
		newLoc.x = arg.loc.x;
		newLoc.y = arg.loc.y;
		
		/*if (newLoc.x == BS_X && newLoc.y == BS_Y) {
			newLoc.x++;
			newLoc.y++;
		} else {*/
		if (compareX) newLoc.x++;
		if (compareY) newLoc.y++;
		/*if (newLoc.x > NUM_COLUMNS) {
			newLoc.x = 1;
			newLoc.y++;
			}
			if (newLoc.y > NUM_ROWS) {
			newLoc.y = 1;
			}
		}*/
		dbg("DBG_USR1", "VM (%i:%i): Executing inc of location (%i,%i), mode %i, result = (%i,%i)\n", 
			context->id.id, context->pc-1, arg.loc.x, arg.loc.y, mode, newLoc.x, newLoc.y);			
		return call Stacks.pushLocation(context, &newLoc);				
		
		} else {
		call Error.error(context, AGILLA_ERROR_TYPE_CHECK);
		dbg("DBG_USR1", "VM (%i:%i): Invalid inc argument arg.vtype = %i.\n", context->id.id, context->pc-1, arg.vtype);
		return FAIL;
		}	
	}
	return FAIL;
	}
}
