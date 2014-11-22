// $Id: OPsenseMTS310CAM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
#include "Timer.h"

/**
 * This module accesses all o the sensors on the MTS310 sensor board.
 *
 * @author Chien-Liang Fok
 */
module OPsenseMTS310CAM {
	provides {
	interface BytecodeI;

	interface Init;
	}
	uses {
	interface AgentMgrI;
	interface OpStackI;
	
	interface Mts300Sounder as Sounder;
	 	interface Read<uint16_t> as Read_Temp;
		interface Read<uint16_t> as Read_Photo;
	 	interface Read<uint16_t> as Read_Mic;
		interface Read<uint16_t> as Read_AccelX;
	 	interface Read<uint16_t> as Read_AccelY;
	interface Timer<TMilli> as SounderTimer;
	interface QueueI;
	interface ErrorMgrI;
	}
}
implementation {
	Queue waitQueue;
	AgillaAgentContext* _context;
	norace AgillaReading reading;	
	bool sounderOn;

	command error_t Init.init() {
	call QueueI.init(&waitQueue);	

	sounderOn = FALSE;

	return SUCCESS;
	}

	inline void resume() {
	call AgentMgrI.run(_context);
	_context = NULL;
	
	// Resume all agents in the wait queue.	It is necessary to
	// resume all agents because some of them might have reacted
	// while waiting.
	while (!call QueueI.empty(&waitQueue)) {
		call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));		
	}	
	}
	
	task void senseDone() {
		call OpStackI.pushReading(_context, reading.type, reading.reading);
		resume();
	}

	event void SounderTimer.fired() {
		call Sounder.beep(256);
	}
	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	AgillaVariable arg;	
	context->state = AGILLA_STATE_WAITING;	// this prevents VM from running agent 
	
	// only one agent can sense at a time
	if (_context != NULL) {		
		context->pc--;			// re-run this instruction 
		call QueueI.enqueue(context, &waitQueue, context); // store waiting context
		return SUCCESS;
	}
	
	_context = context;
	if (call OpStackI.popOperand(context, &arg) == SUCCESS) {
		if (!(arg.vtype & AGILLA_TYPE_VALUE)) {
		 dbg("DBG_USR1", "VM (%i:%i): ERRROR: OPsenseM.execute(): Invalid sensor argument type.\n", context->id.id, context->pc-1);
		 call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_SENSOR, arg.vtype);
		 return FAIL;
		}		 
	
		reading.type = arg.value.value;
		dbg("DBG_USR1", "VM (%i:%i): Executing OPsense with value %i.\n", context->id.id, context->pc-1, reading.type);
		switch(reading.type) {
		case AGILLA_STYPE_SOUNDER:
			if (sounderOn) {
			atomic {
				call SounderTimer.stop();			 
				sounderOn = FALSE;
			}
			} else {
			atomic {
				call SounderTimer.startPeriodic(512);
				sounderOn = TRUE;
			}
			}
			_context = NULL;
			context->state = AGILLA_STATE_RUN;
		break;
		case AGILLA_STYPE_PHOTO:
			atomic {		 
			call Read_Photo.read();
			}
		break;
		case AGILLA_STYPE_TEMP:
			atomic {
			call Read_Temp.read();
			}
		break;
		case AGILLA_STYPE_MIC:
			atomic {
			call Read_Mic.read();
			}
		break;
		case AGILLA_STYPE_ACCELX:
			atomic {
			call Read_AccelX.read();
			}
		break;
		case AGILLA_STYPE_ACCELY:
			atomic {
			call Read_AccelY.read();
			}
		break;		
		default:
			dbg("DBG_USR1", "VM (%i:%i): ERRROR: Invalid sensor argument.\n", context->id.id, context->pc-1);
			call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_SENSOR, reading.type);		
		}	 
		return SUCCESS;
	} 
	return FAIL; 
	}	
	
	inline error_t saveData(uint16_t data) {
	reading.reading = data;
	if(post senseDone() == SUCCESS) return SUCCESS;
	else return FAIL;
	}

	event void Read_Photo.readDone(error_t result, uint16_t data) {
	if (result == SUCCESS) saveData(data);
	}

	event void Read_Temp.readDone(error_t result, uint16_t data) {
	if (result == SUCCESS) saveData(data);
	}

	event void Read_Mic.readDone(error_t result, uint16_t data) {
	if (result == SUCCESS) saveData(data);
	}

	event void Read_AccelX.readDone(error_t result, uint16_t data) {
	if (result == SUCCESS) saveData(data);
	}

	event void Read_AccelY.readDone(error_t result, uint16_t data) {
	if (result == SUCCESS) saveData(data);
	}
}
