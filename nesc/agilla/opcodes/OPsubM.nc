// $Id: OPsubM.nc,v 1.1 2006/01/28 23:18:46 chien-liang Exp $

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
 * @author Chien-Liang Fok <liangfok@wustl.edu>
 */


#include "Agilla.h"

module OPsubM {
	provides interface BytecodeI;
	uses {
	interface OpStackI as Stacks;
	interface ErrorMgrI as Error;
	}
}
implementation {
	error_t subLocLoc(AgillaAgentContext* context, AgillaLocation* loc1, 
	AgillaLocation* loc2, AgillaLocation *newLoc) 
	{
	bool compareX = TRUE, compareY = TRUE;
	int16_t mode = 0;
	if (context->heap.pos[AGILLA_HEAP_LOC_INDEX].vtype == AGILLA_TYPE_VALUE) 
	{
		mode = context->heap.pos[AGILLA_HEAP_LOC_INDEX].value.value;
		if (mode == 1)
		compareY = FALSE;
		else if (mode == 2)
		compareX = FALSE;				 
	}
	
	newLoc->x = loc1->x;
	newLoc->y = loc1->y;
	
	if (compareX) newLoc->x -= loc2->x;	
	if (compareY) newLoc->y -= loc2->y;	

	dbg("DBG_USR1", "VM (%i:%i): Executing sub of two locations (%i, %i) - (%i, %i) = (%i, %i), mode = %i:	Result = (%i, %i)\n", 
		context->id.id, context->pc-1, loc1->x, loc1->y, loc2->x, loc2->y, mode, newLoc->x, newLoc->y);		 
	return SUCCESS;
	}
	
	
	error_t subLocVal(AgillaAgentContext* context, AgillaValue* value, 
	AgillaLocation* loc, AgillaLocation* newLoc) 
	{
	bool compareX = TRUE, compareY = TRUE;
	int16_t mode = 0;
	if (context->heap.pos[AGILLA_HEAP_LOC_INDEX].vtype == AGILLA_TYPE_VALUE) {
		mode = context->heap.pos[AGILLA_HEAP_LOC_INDEX].value.value;
		if (mode == 1)
		compareY = FALSE;
		else if (mode == 2)
		compareX = FALSE;				 
	}
	
	newLoc->x = loc->x;
	newLoc->y = loc->y;
	
	if (compareX) newLoc->x -= value->value;	
	if (compareY) newLoc->y -= value->value;	

	dbg("DBG_USR1", "VM (%i:%i): Executing sub of a value (%i) and location (%i, %i), mode = %i:	Result = (%i, %i)\n", 
		context->id.id, context->pc-1, value->value, loc->x, loc->y, mode, newLoc->x, newLoc->y);		 
	return SUCCESS;
	}
	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) 
	{
	AgillaVariable arg1, arg2; 
	
	dbg("DBG_USR1", "VM (%i:%i): Executing sub\n", context->id.id, context->pc-1);			 
	if (call Stacks.popOperand(context, &arg1) == SUCCESS)
	{
		if (call Stacks.popOperand(context, &arg2) == SUCCESS) 
		{
		if (arg1.vtype == AGILLA_TYPE_VALUE && arg2.vtype == AGILLA_TYPE_VALUE) 
		{
			int sum = arg1.value.value - arg2.value.value;
			call Stacks.pushValue(context, sum);			
			return SUCCESS;
		} 
		else if (arg1.vtype == AGILLA_TYPE_VALUE && arg2.vtype == AGILLA_TYPE_LOCATION) 
		{
			AgillaLocation newLoc;
			if (subLocVal(context, &arg1.value, &arg2.loc, &newLoc) == SUCCESS) 
			{
			call Stacks.pushLocation(context, &newLoc);
			return SUCCESS;
			} else
			return FAIL;
		} 
		else if (arg1.vtype == AGILLA_TYPE_LOCATION && arg2.vtype == AGILLA_TYPE_VALUE) 
		{
			AgillaLocation newLoc;
			if (subLocVal(context, &arg2.value, &arg1.loc, &newLoc) == SUCCESS) 
			{
			call Stacks.pushLocation(context, &newLoc);
			return SUCCESS;
			} else
			return FAIL;		
		} 
		else if (arg1.vtype == AGILLA_TYPE_LOCATION && arg2.vtype == AGILLA_TYPE_LOCATION) 
		{
			AgillaLocation newLoc;				
			if (subLocLoc(context, &arg1.loc, &arg2.loc, &newLoc) == SUCCESS) 
			{
			call Stacks.pushLocation(context, &newLoc);
			return SUCCESS;
			} else
			return FAIL;		 
		} 
		else if (arg1.vtype == AGILLA_TYPE_READING && arg2.vtype == AGILLA_TYPE_READING) 
		{
			if (arg1.reading.type == arg2.reading.type) 
			{
			arg1.reading.reading -= arg2.reading.reading;			
			call Stacks.pushOperand(context, &arg1);
			return SUCCESS;
			} else
			return FAIL;				 
		}		 
		else 
		{
			call Error.errord(context, AGILLA_ERROR_INVALID_TYPE, 0x06);
			dbg("DBG_USR1", "VM (%i:%i): ERROR: OPsubM: Invalid add arg1.vtype = %i, arg1.vtype = %i.\n", context->id.id, context->pc-1, arg1.vtype, arg1.vtype);
		}	
		}
		else 
		{
		dbg("DBG_USR1", "VM (%i:%i): ERROR: OPsubM: Failed to get second argument.\n");
		}
	}
	else
	{
		dbg("DBG_USR1", "VM (%i:%i): ERROR: OPsubM: Failed to get first argument.\n");
	}
	return FAIL;
	}
}
