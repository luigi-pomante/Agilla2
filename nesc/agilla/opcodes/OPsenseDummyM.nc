// $Id: OPsenseDummyM.nc,v 1.2 2006/02/06 09:40:40 chien-liang Exp $

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
#include "TupleSpace.h"

/**
 * This is a dummy sense opcode that pushes dummy values onto
 * the stack.
 */
module OPsenseDummyM {
	provides interface BytecodeI;
	uses {
	interface AgentMgrI;
	interface OpStackI;
	interface ErrorMgrI;
	}
}
implementation {
	
	/*inline void resume() {
	call AgentMgrI.run(_context);
	//_context = NULL;
	
	// Resume all agents in the wait queue.	It is necessary to
	// resume all agents because some of them might have reacted
	// while waiting.
	//while (!call QueueI.empty(&waitQueue)) {
	// call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));		
	//}	
	}*/
	
	/*task void senseDone() {
	call OpStackI.pushReading(_context, reading.type, reading.reading);
	resume();
	}*/

	/*event result_t SounderTimer.fired() {
	if (sounding) {		
		call SounderControl.stop();
	} else {
		call SounderControl.start();
	}
	sounding = !sounding;
	//resume();
	return SUCCESS;
	}*/
	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable arg;	
	AgillaReading reading;
	//context->state = AGILLA_STATE_WAITING;	// this prevents VM from running agent 
	
	// only one agent can sense at a time
	/*if (_context != NULL) {		
		context->pc--;			// re-run this instruction 
		call QueueI.enqueue(context, &waitQueue, context); // store waiting context
		return SUCCESS;
	}*/
	
	//_context = context;
	if (call OpStackI.popOperand(context, &arg) == SUCCESS) {
		if (!(arg.vtype & AGILLA_TYPE_VALUE)) {
		 dbg("DBG_USR1", "VM (%i:%i): ERRROR: OPsenseM.execute(): Invalid sensor argument type.\n", context->id.id, context->pc-1);
		 call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_SENSOR, arg.vtype);
		 return FAIL;
		}		 
	
		reading.type = arg.value.value;
		reading.reading = 0xffff; // save dummy value as the reading
		dbg("DBG_USR1", "VM (%i:%i): Executing OPsense with value %i.\n", context->id.id, context->pc-1, reading.type);
		switch(reading.type) {
		case AGILLA_STYPE_SOUNDER:
			/*if (sounderOn) {
			atomic {
				call SounderTimer.stop();			 
				call SounderControl.stop();
				sounderOn = FALSE;
				sounding = FALSE;
			}
			} else {
			atomic {
				//call SounderControl.start();
				//reading.value = 0;
				//call SounderTimer.start(TIMER_ONE_SHOT, 256);
				call SounderTimer.start(TIMER_REPEAT, 256);		
				sounderOn = TRUE;
			}
			}*/
			//sounderOn = !sounderOn;
			//resume();
			return SUCCESS;
		break;
		case AGILLA_STYPE_PHOTO:
			/*atomic {		 
			call ADC_Photo.getData();
			}
		break;*/
		case AGILLA_STYPE_TEMP:
			/*atomic {
			call ADC_Temp.getData();
			}
		break;*/
		case AGILLA_STYPE_MIC:
			/*atomic {
			call ADC_Mic.getData();
			}
		break;*/
		case AGILLA_STYPE_MAGX:
			/*atomic {
			call ADC_MagX.getData();
			}
		break;*/
		case AGILLA_STYPE_MAGY:
			/*atomic {
			call ADC_MagY.getData();
			}
		break;*/ 
		case AGILLA_STYPE_ACCELX:
			/*atomic {
			call ADC_AccelX.getData();
			}
		break;*/
		case AGILLA_STYPE_ACCELY:
			/*atomic {
			call ADC_AccelY.getData();
			}*/
			call OpStackI.pushReading(context, reading.type, reading.reading);
		break;		
		default:
			dbg("DBG_USR1", "VM (%i:%i): ERRROR: Invalid sensor argument.\n", context->id.id, context->pc-1);
			call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_SENSOR, reading.type);		
		}	 
		return SUCCESS;
	} 
	return FAIL; 
	}	
	
	/*inline result_t saveData(uint16_t data) {
	reading.reading = data;
	return post senseDone();	 
	}

	async event result_t ADC_Photo.dataReady(uint16_t data) { 
	return saveData(data);	
	}

	async event result_t ADC_Temp.dataReady(uint16_t data) {	
	return saveData(data);	 
	}

	async event result_t ADC_Mic.dataReady(uint16_t data) {
	return saveData(data);
	}

	async event result_t ADC_MagX.dataReady(uint16_t data) {
	return saveData(data);
	}

	async event result_t ADC_MagY.dataReady(uint16_t data) {
	return saveData(data);
	}

	async event result_t ADC_AccelX.dataReady(uint16_t data) {
	return saveData(data);
	}

	async event result_t ADC_AccelY.dataReady(uint16_t data) {
	return saveData(data);
	}*/
}
