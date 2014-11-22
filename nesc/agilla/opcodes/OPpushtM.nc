// $Id: OPpushtM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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

module OPpushtM {
	provides interface BytecodeI;	
	uses {
	interface OpStackI as OpStackI;
	interface ErrorMgrI;
	}
}
implementation {

	enum {
	OP_PUSHT_ARG_MASK = 7,	 // last 3 bits is argument
	
	OP_PUSHT_ARG_ANY = 0,
	OP_PUSHT_ARG_AGENTID = 1,
	OP_PUSHT_ARG_NAME = 2,
	OP_PUSHT_ARG_TYPE = 3,
	OP_PUSHT_ARG_VALUE = 4,
	OP_PUSHT_ARG_LOCATION = 5,
	};
	
	enum {
	OP_PUSHRT_ARG_SOUNDER = 0,
	OP_PUSHRT_ARG_PHOTO = 1,
	OP_PUSHRT_ARG_TEMP = 2,
	OP_PUSHRT_ARG_MIC = 3,
	OP_PUSHRT_ARG_MAGX = 4,
	OP_PUSHRT_ARG_MAGY = 5,
	OP_PUSHRT_ARG_ACCELX = 6,
	OP_PUSHRT_ARG_ACCELY = 7,	
	};	

	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	uint8_t arg = (instr & OP_PUSHT_ARG_MASK);						
	if (instr & 8) {	// pusht		
		switch(arg) {
		case OP_PUSHT_ARG_ANY:
		dbg("DBG_USR1", "VM (%i:%i): Executing pusht with type AGILLA_TYPE_ANY\n", context->id.id, context->pc-1);
		return call OpStackI.pushType(context, AGILLA_TYPE_ANY);
		break;
		case OP_PUSHT_ARG_AGENTID:
		dbg("DBG_USR1", "VM (%i:%i): Executing pusht with type AGILLA_TYPE_AGENTID\n", context->id.id, context->pc-1);
		return call OpStackI.pushType(context, AGILLA_TYPE_AGENTID);
		break;
		case OP_PUSHT_ARG_NAME:
		dbg("DBG_USR1", "VM (%i:%i): Executing pusht with type AGILLA_TYPE_STRING\n", context->id.id, context->pc-1);
		return call OpStackI.pushType(context, AGILLA_TYPE_STRING);
		break;
		case OP_PUSHT_ARG_TYPE:
		dbg("DBG_USR1", "VM (%i:%i): Executing pusht with type AGILLA_TYPE_TYPE\n", context->id.id, context->pc-1);
		return call OpStackI.pushType(context, AGILLA_TYPE_TYPE);
		break;
		case OP_PUSHT_ARG_VALUE:
		dbg("DBG_USR1", "VM (%i:%i): Executing pusht with type AGILLA_TYPE_VALUE\n", context->id.id, context->pc-1);
		return call OpStackI.pushType(context, AGILLA_TYPE_VALUE);
		break;
		case OP_PUSHT_ARG_LOCATION:
		dbg("DBG_USR1", "VM (%i:%i): Executing pusht with type AGILLA_TYPE_LOCATION\n", context->id.id, context->pc-1);
		return call OpStackI.pushType(context, AGILLA_TYPE_LOCATION);		
		break;
		default:
		dbg("DBG_USR1", "VM (%i:%i): ERROR: Invalid type %i.\n", context->id.id, context->pc-1, arg);
		call ErrorMgrI.error(context, AGILLA_ERROR_INVALID_FIELD_TYPE);
		return FAIL;		
		} 
	} else {	// pushrt
		switch(arg) {		 
		/*case IOP_PUSHRT_ARG_SOUNDER:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_SOUNDER\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_SOUNDER);
		break;*/
		case OP_PUSHRT_ARG_PHOTO:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_PHOTO\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_PHOTO);
		break;
		case OP_PUSHRT_ARG_TEMP:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_TEMP\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_TEMP);
		break;
		case OP_PUSHRT_ARG_MIC:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_MIC\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_MIC);
		break;
		case OP_PUSHRT_ARG_MAGX:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_MAGX\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_MAGX);
		break;
		case OP_PUSHRT_ARG_MAGY:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_MAGY\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_MAGY);
		break;
		case OP_PUSHRT_ARG_ACCELX:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_ACCELX\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_ACCELX);
		break;
		case OP_PUSHRT_ARG_ACCELY:
		dbg("DBG_USR1", "VM (%i:%i): Executing pushrt with READING type AGILLA_STYPE_ACCELY\n", context->id.id, context->pc-1);
		return call OpStackI.pushReadingType(context, AGILLA_STYPE_ACCELY);
		break;
		default:
		dbg("DBG_USR1", "VM (%i:%i): ERROR: Invalid reading type %i.\n", context->id.id, context->pc-1, arg);
		call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_FIELD_TYPE, arg);
		}
		return FAIL;
	}
	}
}
