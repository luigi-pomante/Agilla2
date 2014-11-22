// $Id: OPmoveM.nc,v 1.5 2006/02/08 12:27:37 chien-liang Exp $

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
 * Implements both move and clone operations.
 */
module OPmoveM {
	provides interface BytecodeI;
	
	uses {
	interface OpStackI;
	interface AgentMgrI;
	interface AddressMgrI;
	interface LocationMgrI;
	interface NeighborListI;
	interface ErrorMgrI;
	}
}
implementation {	

	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable arg;	
	uint16_t dest;
	
	// Get the destination address.
	if (call OpStackI.popOperand(context, &arg) == SUCCESS) {					
		if (arg.vtype & AGILLA_VAR_V)
		dest = arg.value.value;
		else if (arg.vtype & AGILLA_VAR_L)
		dest = call LocationMgrI.getAddress(&arg.loc);
		else {
		dbg("DBG_USR1", "VM (%i): MOVE failed, argument not a value or location (%i).\n", context->id.id, arg.vtype);
		call ErrorMgrI.error(context, AGILLA_ERROR_TYPE_CHECK);
		return FAIL;
		}
		
		// print debug statements
		switch(instr) {
		case IOPwmove:
			//dbg("DBG_USR1", "VM (%i:%i): Executing wmove to (%i,%i) = %i\n", context->id.id, context->pc-1, arg.loc.x, arg.loc.y, addr);
			dbg("DBG_USR1", "VM (%i:%i): Executing wmove to %i\n", context->id.id, context->pc-1, dest);
			break;
		case IOPwclone:
			//dbg("DBG_USR1", "VM (%i:%i): Executing wclone to (%i,%i) = %i\n", context->id.id, context->pc-1, arg.loc.x, arg.loc.y, addr);
			dbg("DBG_USR1", "VM (%i:%i): Executing wclone to %i\n", context->id.id, context->pc-1, dest);
			break;
		case IOPsmove:
			//dbg("DBG_USR1", "VM (%i:%i): Executing smove to (%i,%i) = %i\n", context->id.id, context->pc-1, arg.loc.x, arg.loc.y, addr);
			dbg("DBG_USR1", "VM (%i:%i): Executing smove to %i\n", context->id.id, context->pc-1, dest);
			break;
		case IOPsclone:
			//dbg("DBG_USR1", "VM (%i:%i): Executing sclone to (%i,%i) = %i\n", context->id.id, context->pc-1, arg.loc.x, arg.loc.y, addr);
			dbg("DBG_USR1", "VM (%i:%i): Executing sclone to %i\n", context->id.id, context->pc-1, dest);
			break;
		}
 
		// If the destination is the UART and this is not the base station,
		// migrate to the base station mote.
		if (dest == AM_UART_ADDR && call AddressMgrI.isGW() != SUCCESS) {
		uint16_t bsAddr;
		if (call NeighborListI.getGW(&bsAddr) != NO_GW)
			return call AgentMgrI.migrate(context, bsAddr, dest, instr);					
		else {
			dbg("DBG_USR1", "OPmoveM: ERROR: Failed to find base station address.\n");
			context->condition = 0; // failed to find a base station
			return SUCCESS;
		}
		} else 
		{
		uint16_t oneHopDest = dest;
		error_t forward = SUCCESS;
		
		#if ENABLE_GRID_ROUTING
			forward = call NeighborListI.getClosestNeighbor(&oneHopDest);			
		#endif
		
		if (forward == SUCCESS)
			return call AgentMgrI.migrate(context, oneHopDest, dest, instr);				
		else {
			context->condition = 0;
			return SUCCESS;
		}
		}
	}
	return FAIL;
	}
}
