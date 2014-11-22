// $Id: OPvicinityM.nc,v 1.1 2005/10/13 17:12:14 chien-liang Exp $

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

module OPvicinityM {	
	provides interface BytecodeI;	
	uses {
	interface OpStackI;
	interface LocationUtilI;
	interface ErrorMgrI;
	}
}
implementation {	
	#define DEBUG_OP_VICINITY

	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable refLoc;	 
	if (call OpStackI.popOperand(context, &refLoc) == SUCCESS) {
		if ((refLoc.vtype & AGILLA_VAR_L) && context->heap.pos[0].vtype & AGILLA_VAR_V) {		
		int i;
		
		dbg("DBG_USR1", "VM (%i:%i): Executing OPvicinity (%i,%i).\n", context->id.id, context->pc-1, refLoc.loc.x, refLoc.loc.y);
		
		for (i = 0; i < context->heap.pos[0].value.value; i++) {
			if (context->heap.pos[i+1].vtype & AGILLA_VAR_L) {
			uint16_t dist = call LocationUtilI.dist(&context->heap.pos[i+1].loc, &refLoc.loc);
			
			#ifdef DEBUG_OP_VICINITY
			dbg("DBG_USR1", "\tOpVicinity: Comparing (%i, %i) with (%i, %i), dist = %i\n", context->heap.pos[i+1].loc.x, context->heap.pos[i+1].loc.y, refLoc.loc.x, refLoc.loc.y, dist);
			#endif
			
			if (dist <= 2) {

				#ifdef DEBUG_OP_VICINITY
				dbg("DBG_USR1", "\tOPVicinity: distance <= 2, setting cond=1, returning\n");
				#endif			
				
				context->condition = 1;
				return SUCCESS;
			}
			} else {
			dbg("DBG_USR1", "VM (%i:%i): Executing OPvicinity ... FAILED heap %i is not a location (%i).\n", context->id.id, context->pc-1, i+1, context->heap.pos[i+1].vtype);							
			call ErrorMgrI.error2d(context, AGILLA_ERROR_INVALID_TYPE, i+1, context->heap.pos[i+1].vtype);
			return FAIL;
			}
		}
		#ifdef DEBUG_OP_VICINITY
		dbg("DBG_USR1", "\tOPVicinity: no neighbors within vicinity, returning\n");
		#endif			
		
		context->condition = 0;
		return SUCCESS;			
		} else {
		dbg("DBG_USR1", "VM (%i:%i): Executing OPvicinity ... FAILED invalid types %i, %i.\n", context->id.id, context->pc-1, refLoc.vtype, context->heap.pos[0].vtype);					
		call ErrorMgrI.error2d(context, AGILLA_ERROR_INVALID_TYPE, refLoc.vtype, context->heap.pos[0].vtype);
		return FAIL;
		}
	}
	return FAIL;
	}	
}
