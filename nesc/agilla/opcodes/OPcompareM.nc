// $Id: OPcompareM.nc,v 1.3 2006/01/21 03:18:20 chien-liang Exp $

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
 * Implements cgt, cgte, clt, clte, ceq, and cneq.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module OPcompareM {
	provides interface BytecodeI;	
	uses {
	interface OpStackI as Stacks;
	interface ErrorMgrI;
	}
}
implementation {

	inline void printDebug(AgillaAgentContext* context, uint8_t instr) {
	switch(instr) {
	case IOPcgt:
		dbg("DBG_USR1", "VM (%i:%i): Executing cgt.\n", context->id.id, context->pc-1);
		break;
	case IOPcgte:
		dbg("DBG_USR1", "VM (%i:%i): Executing cgte.\n", context->id.id, context->pc-1);
		break;
	case IOPclt:
		dbg("DBG_USR1", "VM (%i:%i): Executing clt.\n", context->id.id, context->pc-1);
		break;
	case IOPclte:
		dbg("DBG_USR1", "VM (%i:%i): Executing clte.\n", context->id.id, context->pc-1);
		break;		
	case IOPceq:
		dbg("DBG_USR1", "VM (%i:%i): Executing ceq.\n", context->id.id, context->pc-1);
		break;		
	case IOPcneq:
		dbg("DBG_USR1", "VM (%i:%i): Executing cneq.\n", context->id.id, context->pc-1);
		break;				 
	default:
		dbg("DBG_USR1", "OPcompareM: ERROR: OPcompareM: Invalid instruction %i.\n", instr);
	}
	}
	
	inline error_t compare2values(uint8_t instr, AgillaAgentContext* context, 
	int16_t val1, int16_t val2)
	{
	switch(instr) {
	case IOPcgt:
		context->condition = (val2 > val1);
		break;
	case IOPcgte:
		context->condition = (val2 >= val1);
		break;
	case IOPclt:
		context->condition = (val2 < val1);
		break;
	case IOPclte:
		context->condition = (val2 <= val1);
		break;		
	case IOPceq:
		context->condition = (val2 == val1);
		break;		
	case IOPcneq:
		context->condition = (val2 != val1);		
		break;				 
	default:
		context->condition = 0;	
	}
	return SUCCESS;
	}
	
	inline error_t compare2readings(uint8_t instr, AgillaAgentContext* context, 
	AgillaReading* reading1, AgillaReading* reading2)
	{
	#if DEBUG_OPCOMPARE
		dbg("DBG_USR1", "OPcompareM: Comparing 2 readings: %i:%i, %i:%i.\n", reading1->type, reading1->reading, reading2->type, reading2->reading);
	#endif
	if (reading1->type == reading2->type) {
		switch(instr) {
		case IOPcgt:
		context->condition = (reading2->reading > reading1->reading);
		break;
		case IOPcgte:
		context->condition = (reading2->reading >= reading1->reading);
		break;
		case IOPclt:
		context->condition = (reading2->reading < reading1->reading);
		break;
		case IOPclte:
		context->condition = (reading2->reading <= reading1->reading);
		break;		
		case IOPceq:
		context->condition = (reading2->reading == reading1->reading);
		break;		
		case IOPcneq:
		context->condition = (reading2->reading != reading1->reading);		
		break;				 
		default:				
		context->condition = 0;
		}
	} else
		context->condition = 0; // sensor types do not match
	return SUCCESS;			
	}

	inline error_t compare2locations(uint8_t instr, AgillaAgentContext* context, 
	AgillaLocation* loc1, AgillaLocation* loc2)
	{			
	bool compareX = TRUE, compareY = TRUE;

	#if DEBUG_OPCOMPARE
		dbg("DBG_USR1", "OPcompareM: Comparing two locations (%i, %i), (%i, %i)..\n",
		loc1->x, loc1->y, loc2->x, loc2->y);
	#endif
		
	if (context->heap.pos[AGILLA_HEAP_LOC_INDEX].vtype == AGILLA_TYPE_VALUE) 
	{
		if (context->heap.pos[AGILLA_HEAP_LOC_INDEX].value.value == 1)
		compareY = FALSE;
		else if (context->heap.pos[AGILLA_HEAP_LOC_INDEX].value.value == 2)
		compareX = FALSE;				
	}
					
	switch(instr) {
	case IOPcgt:
		if (compareX && compareY)
		context->condition = (loc2->x > loc1->x && loc2->y > loc1->y);
		else if (compareX)
		context->condition = (loc2->x > loc1->x);
		else
		context->condition = (loc2->y > loc1->y);
		break;
	case IOPcgte:
		if (compareX && compareY)
		context->condition = (loc2->x >= loc1->x && loc2->y >= loc1->y);
		else if (compareX)
		context->condition = (loc2->x >= loc1->x);
		else
		context->condition = (loc2->y >= loc1->y);
		break;
	case IOPclt:
		if (compareX && compareY)
		context->condition = (loc2->x < loc1->x && loc2->y < loc1->y);
		else if (compareX)
		context->condition = (loc2->x < loc1->x);
		else
		context->condition = (loc2->y < loc1->y);
		break;
	case IOPclte:
		if (compareX && compareY)
		context->condition = (loc2->x <= loc1->x && loc2->y <= loc1->y);
		else if (compareX)
		context->condition = (loc2->x <= loc1->x);
		else
		context->condition = (loc2->y <= loc1->y);
		break;		
	case IOPceq:
		if (compareX && compareY)
		context->condition = (loc2->x == loc1->x && loc2->y == loc1->y);
		else if (compareX)
		context->condition = (loc2->x == loc1->x);
		else
		context->condition = (loc2->y == loc1->y);
		break;		
	case IOPcneq:
	
		#if DEBUG_OPCOMPARE
		dbg("DBG_USR1", "OPcompareM: Performing cneq...\n");
		#endif
	
		if (compareX && compareY) {
	
		#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing both X and Y axis...\n");
		#endif		
		
		context->condition = (loc2->x != loc1->x || loc2->y != loc1->y);
		
		#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: condition = %i\n", context->condition);
		#endif				
		
		} else if (compareX)
		context->condition = (loc2->x != loc1->x);
		else
		context->condition = (loc2->y != loc1->y);
		break;						
	default:				
		context->condition = 0;
	}				
	return SUCCESS;
	}
	
/*	inline error_t compareValLoc(uint8_t instr, AgillaAgentContext* context, 
	AgillaValue* val, AgillaLocation* loc) 
	{			
	bool compareX = TRUE, compareY = TRUE;
	if (context->heap.pos[AGILLA_HEAP_SIZE-1].vtype == AGILLA_TYPE_VALUE) {
		if (context->heap.pos[AGILLA_HEAP_SIZE-1].value.value == 1)
		compareY = FALSE;
		else if (context->heap.pos[AGILLA_HEAP_SIZE-1].value.value == 2)
		compareX = FALSE;				
	}
					
	switch(instr) {
	case IOPcgt:
		if (compareX && compareY)
		context->condition = (loc->x > val->val && loc->y > val->val);
		else if (compareX)
		context->condition = (loc->x > loc1->x);
		else
		context->condition = (loc->y > loc1->y);
		break;
	case IOPcgte:
		if (compareX && compareY)
		context->condition = (loc2->x >= loc1->x && loc2->y >= loc1->y);
		else if (compareX)
		context->condition = (loc2->x >= loc1->x);
		else
		context->condition = (loc2->y >= loc1->y);
		break;
	case IOPclt:
		if (compareX && compareY)
		context->condition = (loc2->x < loc1->x && loc2->y < loc1->y);
		else if (compareX)
		context->condition = (loc2->x < loc1->x);
		else
		context->condition = (loc2->y < loc1->y);
		break;
	case IOPclte:
		if (compareX && compareY)
		context->condition = (loc2->x <= loc1->x && loc2->y <= loc1->y);
		else if (compareX)
		context->condition = (loc2->x <= loc1->x);
		else
		context->condition = (loc2->y <= loc1->y);
		break;		
	case IOPceq:
		if (compareX && compareY)
		context->condition = (loc2->x == loc1->x && loc2->y == loc1->y);
		else if (compareX)
		context->condition = (loc2->x == loc1->x);
		else
		context->condition = (loc2->y == loc1->y);
		break;		
	case IOPcneq:
		if (compareX && compareY)
		context->condition = (loc2->x != loc1->x && loc2->y != loc1->y);
		else if (compareX)
		context->condition = (loc2->x != loc1->x);
		else
		context->condition = (loc2->y != loc1->y);
		break;						
	default:				
		context->condition = 0;
	}				
	return SUCCESS;
	}	*/
	
	inline error_t compare2ids(uint8_t instr, AgillaAgentContext* context, 
	AgillaAgentID* id1, AgillaAgentID* id2)
	{	 
	switch(instr) {
	case IOPcgt:
		context->condition = (id2->id > id1->id);
		break;
	case IOPcgte:
		context->condition = (id2->id >= id1->id);
		break;
	case IOPclt:
		context->condition = (id2->id < id1->id);
		break;
	case IOPclte:
		context->condition = (id2->id <= id1->id);
		break;		
	case IOPceq:
		context->condition = (id2->id == id1->id);
		break;		
	case IOPcneq:
		context->condition = (id2->id != id1->id);		
		break;				 
	default:
		context->condition = 0;	
	} 
	return SUCCESS;
	}
	
	inline error_t compare2strings(uint8_t instr, AgillaAgentContext* context, 
	AgillaString* string1, AgillaString* string2)
	{	
	switch(instr) {
	case IOPcgt:
		context->condition = (string2->string > string1->string);
		break;
	case IOPcgte:
		context->condition = (string2->string >= string1->string);
		break;
	case IOPclt:
		context->condition = (string2->string < string1->string);
		break;
	case IOPclte:
		context->condition = (string2->string <= string1->string);
		break;		
	case IOPceq:
		context->condition = (string2->string == string1->string);
		break;		
	case IOPcneq:
		context->condition = (string2->string != string1->string);		
		break;				 
	default:
		context->condition = 0;	
	}	 
	return SUCCESS;
	}
	
	inline error_t compare2types(uint8_t instr, AgillaAgentContext* context, 
	AgillaType* type1, AgillaType* type2)
	{	
	switch(instr) {		 
	case IOPceq:
		context->condition = (type2->type == type1->type);
		break;		
	case IOPcneq:
		context->condition = (type2->type != type1->type);		
		break;				 
	default:
		context->condition = 0;	
	}	 
	return SUCCESS;
	}	
	
	inline error_t compare2rtypes(uint8_t instr, AgillaAgentContext* context, 
	AgillaRType* rtype1, AgillaRType* rtype2)
	{	
	switch(instr) {		 
	case IOPceq:
		context->condition = (rtype2->stype == rtype1->stype);
		break;		
	case IOPcneq:
		context->condition = (rtype2->stype != rtype1->stype);		
		break;				 
	default:
		context->condition = 0;	
	}	 
	return SUCCESS;
	}	 
	
	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable arg1, arg2;	
	printDebug(context, instr);
	if (call Stacks.popOperand(context, &arg1) == SUCCESS) {
		if (call Stacks.popOperand(context, &arg2) == SUCCESS) {
		
		if (arg1.vtype == AGILLA_TYPE_VALUE && arg2.vtype == AGILLA_TYPE_VALUE) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing 2 values.\n");
			#endif
			return compare2values(instr, context, arg1.value.value, arg2.value.value);
		}
		
		if (arg1.vtype == AGILLA_TYPE_READING && arg2.vtype == AGILLA_TYPE_READING) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing 2 readings.\n");
			#endif
			return compare2readings(instr, context, &arg1.reading, &arg2.reading);
		}
		
		if (arg1.vtype == AGILLA_TYPE_LOCATION && arg2.vtype == AGILLA_TYPE_LOCATION) {
			return compare2locations(instr, context, &arg1.loc, &arg2.loc);
		}
		
		if (arg1.vtype == AGILLA_TYPE_AGENTID && arg2.vtype == AGILLA_TYPE_AGENTID) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing 2 agent IDs.\n");
			#endif
			return compare2ids(instr, context, &arg1.id, &arg2.id);
		}
		
		if (arg1.vtype == AGILLA_TYPE_STRING && arg2.vtype == AGILLA_TYPE_STRING) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing 2 strings.\n");
			#endif
			return compare2strings(instr, context, &arg1.string, &arg2.string);
		}
		
		if (arg1.vtype == AGILLA_TYPE_TYPE && arg2.vtype == AGILLA_TYPE_TYPE) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing 2 types.\n");
			#endif
			return compare2types(instr, context, &arg1.type, &arg2.type);		
		}
		
		if (arg1.vtype == AGILLA_TYPE_STYPE && arg2.vtype == AGILLA_TYPE_STYPE) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing 2 sensor types.\n");
			#endif
			return compare2rtypes(instr, context, &arg1.rtype, &arg2.rtype);	 
		}
		
		if (arg1.vtype == AGILLA_TYPE_VALUE && arg2.vtype == AGILLA_TYPE_READING) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing value to reading.\n");
			#endif
			return compare2values(instr, context, arg1.value.value, arg2.reading.reading);
		}		
		
		if (arg1.vtype == AGILLA_TYPE_READING && arg2.vtype == AGILLA_TYPE_VALUE) {
			#if DEBUG_OPCOMPARE
			dbg("DBG_USR1", "OPcompareM: Comparing reading to value.\n");
			#endif
			return compare2values(instr, context, arg1.reading.reading, arg2.value.value);
		}						
		
		dbg("DBG_USR1", "OPcompareM: Two values not same type.\n"); 
		//call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_TYPE, 0x09);		
		context->condition = 0;
		return SUCCESS;		
		} else {		 
		dbg("DBG_USR1", "OPcompareM: Problem getting SECOND argument.\n");		 
		return FAIL;
		}
	} else {
		dbg("DBG_USR1", "OPcompareM: Problem getting FIRST argument.\n");
		return FAIL;
	}
	return SUCCESS;
	}
}
