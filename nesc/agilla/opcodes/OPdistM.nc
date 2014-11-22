// $Id: OPdistM.nc,v 1.4 2006/01/19 06:11:49 chien-liang Exp $

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

module OPdistM {	
	provides interface BytecodeI;
	
	uses {
	interface OpStackI;
	interface LocationUtilI;
	interface LocationMgrI;
	}
}
implementation 
{	

	error_t compare2Locs(AgillaAgentContext* context, AgillaLocation* loc1, 
	AgillaLocation* loc2)
	{
		uint16_t result = call LocationUtilI.dist(loc1, loc2);
		dbg("DBG_USR1", "VM (%i:%i): Executing OPdist (%i,%i) and (%i, %i) = %i.\n", 
		context->id.id, context->pc-1, loc1->x, loc1->y, loc2->x, loc2->y, result);
		return call OpStackI.pushValue(context, result);			
	}
	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) 
	{
	AgillaVariable sv1, sv2;	 
	if (call OpStackI.popOperand(context, &sv1) == SUCCESS)
	{
		if (call OpStackI.popOperand(context, &sv2) == SUCCESS)
		{		
		// Calculate the distance between two locations
		if ((sv1.vtype & AGILLA_VAR_L) && (sv2.vtype & AGILLA_VAR_L)) 
		{
			return compare2Locs(context, &sv1.loc, &sv2.loc);			
		} 
		
		// Calculate the distance between a location and tinyOS address
		else if ((sv1.vtype & AGILLA_VAR_V) && (sv2.vtype & AGILLA_VAR_L)) 
		{
			AgillaLocation loc1;
			call LocationMgrI.getLocation(sv1.value.value, &loc1);
			return compare2Locs(context, &loc1, &sv2.loc);
		}
		else if ((sv1.vtype & AGILLA_VAR_L) && (sv2.vtype & AGILLA_VAR_V)) 
		{
			AgillaLocation loc2;
			call LocationMgrI.getLocation(sv2.value.value, &loc2);
			return compare2Locs(context, &sv1.loc, &loc2);
		}		
		
		// Calculate the distance between two tinyos addresses
		else if ((sv1.vtype & AGILLA_VAR_V) && (sv2.vtype & AGILLA_VAR_V)) 
		{
			AgillaLocation loc1, loc2;
			call LocationMgrI.getLocation(sv1.value.value, &loc1);
			call LocationMgrI.getLocation(sv2.value.value, &loc2);
			return compare2Locs(context, &loc1, &loc2);
		}		
		
		
		// calculate the distance between two readings
		else if ((sv1.vtype & AGILLA_VAR_R) && (sv2.vtype & AGILLA_VAR_R)) 
		{
			uint16_t diff;
			if (sv1.reading.reading > sv2.reading.reading)
			diff = sv1.reading.reading - sv2.reading.reading;
			else
			diff = sv2.reading.reading - sv1.reading.reading;
			dbg("DBG_USR1", "VM (%i:%i): Executing OPdist (%i:%i) and (%i:%i) = %i.\n", 
			context->id.id, context->pc-1, sv1.reading.type, sv1.reading.reading, 
			sv2.reading.type, sv2.reading.reading, diff);			
			return call OpStackI.pushValue(context, diff);			
		}
		
		else {
			dbg("DBG_USR1", "VM (%i:%i): Executing OPdist ... FAILED invalid types %i, %i.\n", context->id.id, context->pc-1, sv1.vtype, sv2.vtype);			
		}
		}
	}
	return FAIL;
	}	
}
