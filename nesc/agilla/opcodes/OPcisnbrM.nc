// $Id: OPcisnbrM.nc,v 1.2 2005/12/07 10:41:01 chien-liang Exp $

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

module OPcisnbrM {
	provides interface BytecodeI;	
	uses {
	interface OpStackI;
	interface NeighborListI;
	interface ErrorMgrI;
	interface LocationMgrI;
	}
}
implementation {	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable arg;
	
	dbg("DBG_USR1", "VM (%i:%i): Executing isnbr\n", context->id.id, context->pc-1);
	
	if (call OpStackI.popOperand(context, &arg) == SUCCESS) {
		if (arg.vtype & AGILLA_VAR_V){	 
		if(call NeighborListI.isNeighbor(arg.value.value) == SUCCESS) context->condition = 1;	
		else context->condition = 0;
		}
		else {
		if (arg.vtype & AGILLA_VAR_L)
			if(call NeighborListI.isNeighbor(call LocationMgrI.getAddress(&arg.loc)) == SUCCESS) context->condition = 1;
			else context->condition = 0;
		else {
			dbg("DBG_USR1", "VM (%i): MOVE failed, argument not a value (%i).\n", context->id.id, arg.vtype);
			call ErrorMgrI.error(context, AGILLA_ERROR_TYPE_CHECK);
			return FAIL;
		}
		}			
	} else
		return FAIL;
	return SUCCESS;
	}
}
