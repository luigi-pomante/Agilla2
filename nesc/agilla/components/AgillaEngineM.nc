// $Id: AgillaEngineM.nc,v 1.12 2006/02/06 09:40:39 chien-liang Exp $

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

/*					tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University	of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.	THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*					tab:4
 *
 *	IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *	By downloading, copying, installing or using the software you
 *	agree to this license.	If you do not agree to this license, do
 *	not download, install, copy or use the software.
 *
 *	Intel Open Source License
 *
 *	Copyright (c) 2002 Intel Corporation
 *	All rights reserved.
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are
 *	met:
 *
 *	Redistributions of source code must retain the above copyright
 *	notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *	notice, this list of conditions and the following disclaimer in the
 *	documentation and/or other materials provided with the distribution.
 *		Neither the name of the Intel Corporation nor the names of its
 *	contributors may be used to endorse or promote products derived from
 *	this software without specific prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *	``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *	PARTICULAR PURPOSE ARE DISCLAIMED.	IN NO EVENT SHALL THE INTEL OR ITS
 *	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

/*
 * Authors:	 Philip Levis <pal@cs.berkeley.edu>
 *			Neil Patel
 * History:	 Apr 11, 2003		 Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 * @author Neil Patel
 * @author Chien-Liang Fok <liangfok@wustl.edu>
 */
#include "AM.h"
#include "Agilla.h"

#ifdef EDIT_TIMESTAMP
	#include "WtStructs.h"
#endif

module AgillaEngineM {
	provides {
	//interface StdControl;
	interface Init;
	interface AgentExecutorI;
	}
	uses {
	interface CodeMgrI;
	interface ErrorMgrI;
	interface ResetMgrI;
	interface RxnMgrI;
	interface QueueI;
	interface BytecodeI as BasicISA[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA1[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA2[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA3[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA4[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA5[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA6[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA7[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA8[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA9[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA10[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA11[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA12[uint8_t bytecode]; 
	interface BytecodeI as ExtendedISA13[uint8_t bytecode];

#ifdef EDIT_TIMESTAMP
		interface WtUartInterface;
		interface LocalTime<TMicro> as TS_Time;
		interface Init as UARTControl;
#endif
	}
}

implementation {	
	/**
	 * This queue holds agents that are ready to execute.
	 */
	Queue runQueue;

	command error_t Init.init()
	{
	dbg("DBG_BOOT", "VM: Agilla initializing.\n");				
	call QueueI.init(&runQueue);

	//dbg(DBG_USR1, "size of AgillaRxnMsg is %i\n", sizeof(AgillaRxnMsg));

	/*dbg(DBG_USR1, "size of AgillaLocation is %i\n", sizeof(AgillaLocation));
	dbg(DBG_USR1, "size of AgillaAgentID is %i\n", sizeof(AgillaAgentID));
	dbg(DBG_USR1, "size of AgillaString is %i\n", sizeof(AgillaString));
	dbg(DBG_USR1, "size of AgillaReading is %i\n", sizeof(AgillaReading));
	dbg(DBG_USR1, "size of AgillaType is %i\n", sizeof(AgillaType));
	dbg(DBG_USR1, "size of AgillaValue is %i\n", sizeof(AgillaValue));
	dbg(DBG_USR1, "size of AgillaType is %i\n", sizeof(AgillaType));
	dbg(DBG_USR1, "size of AgillaVariable is %i\n", sizeof(AgillaVariable));

	dbg(DBG_USR1, "size of AgillaStateMsg is %i\n", sizeof(AgillaStateMsg));
	dbg(DBG_USR1, "size of AgillaCodeMsg is %i\n", sizeof(AgillaCodeMsg));
	dbg(DBG_USR1, "size of AgillaHeapMsg is %i\n", sizeof(AgillaHeapMsg));
	dbg(DBG_USR1, "size of OpStackMsg is %i\n", sizeof(OpStackMsg));

	dbg(DBG_USR1, "size of AgillaAckMsg is %i\n", sizeof(AgillaAckMsg));

	dbg(DBG_USR1, "size of AgillaTSReqMsg is %i\n", sizeof(AgillaTSReqMsg));
	dbg(DBG_USR1, "size of AgillaTSResMsg is %i\n", sizeof(AgillaTSResMsg));
	*/

	/* #ifdef TOSH_HARDWARE_MICA2
		//call CC1000Control.SetRFPower(0x04); // reduce radio range
		#endif
	 */
#ifdef EDIT_TIMESTAMP
		call UARTControl.init();
#endif
	return SUCCESS;
	}

/*	command result_t StdControl.start() {
	dbg(DBG_BOOT, "VM: Starting.\n");
	return SUCCESS;
	}

	command result_t StdControl.stop() {
	dbg(DBG_BOOT, "VM: Stopping.\n");
	return SUCCESS;
	} */

	void doNextInstr(AgillaAgentContext* context)
	{
		if (call ResetMgrI.isResetting() != SUCCESS && call ErrorMgrI.inErrorState() != SUCCESS) 
		{
			uint8_t instr = call CodeMgrI.getInstruction(context, context->pc++);	

			#if DEBUG_AGILLA_ENGINE
			dbg("DBG_USR1", "AgillaEngineM: Fetched instr = 0x%x\n", instr);
			#endif 
			
		// If the instruction is an ISA extension, fetch the next instruction
		// and execute it using the appropriate extension interface.
		switch(instr) {
		case IOPextend1:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			#if DEBUG_AGILLA_ENGINE
			dbg("DBG_USR1", "AgillaEngineM: Extended mode 1 instr = 0x%x\n", instr);
			#endif					 
			call ExtendedISA1.execute[instr](instr, context);
		break;
		case IOPextend2:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA2.execute[instr](instr, context);
		break;
		case IOPextend3:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA3.execute[instr](instr, context);
		break;
		case IOPextend4:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA4.execute[instr](instr, context);
		break;
		case IOPextend5:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA5.execute[instr](instr, context);
		break;
		case IOPextend6:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA6.execute[instr](instr, context);
		break;
		case IOPextend7:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA7.execute[instr](instr, context);
			break;
		case IOPextend8:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA8.execute[instr](instr, context);
			break;
		case IOPextend9:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA9.execute[instr](instr, context);
			break;
		case IOPextend10:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA10.execute[instr](instr, context);
			break;
		case IOPextend11:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA11.execute[instr](instr, context);
			break;
		case IOPextend12:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA12.execute[instr](instr, context);
			break;		
		case IOPextend13:
			instr = call CodeMgrI.getInstruction(context, context->pc++);	
			call ExtendedISA13.execute[instr](instr, context);
			break;				
		default:
#ifdef EDIT_TIMESTAMP
//------------------------------------------------------------------------------
		{
			uint32_t before = call TS_Time.get();
#endif
			call BasicISA.execute[instr](instr, context);
#ifdef EDIT_TIMESTAMP
			call WtUartInterface.InsertMessage( instr, before );
			if( call WtUartInterface.isQueueFull() || instr == 0 )
				call WtUartInterface.SendToSerial();
		}
#endif
//------------------------------------------------------------------------------
		}			 
	} else {
		dbg("DBG_USR1", "AgilleEngineM: doNextInstr: called but resetting or in error state...\n");
	}
	} // doNextInstr
	/**
	 * If Agilla is not in an error state, fetch the next context from the
	 * run queue and execute up to 8 intructions.	If the agent enters a 
	 * non-running state, abort without putting the agent back into the 
	 * run queue.
	 *
	 * Since an engin() task is posted whenever an agent is inserted into
	 * the runQueue, there will always be at least one task for each agent
	 * in the queue (there will never be a case where an agent gets stuck
	 * in the runQueue).
	 *
	 * After executing an agent, let the RxnMgr run to see whether any
	 * reactions should fire.
	 */
	task void engine()
	{	
		if (call ErrorMgrI.inErrorState() != SUCCESS)
		{
			int i;
			AgillaAgentContext* context = call QueueI.dequeue(NULL, &runQueue);

			for (i=0; i < 8; i++)
			{
				// this is an arbitrary number of instructions
				doNextInstr(context);

				if (context->state != AGILLA_STATE_RUN)
				{
					#if DEBUG_AGILLA_ENGINE
					dbg("DBG_USR1", "AgillaEngineM: Agent %i is no longer in run state.\n", context->state);	
					dbg("DBG_USR1", "AgillaEngineM: Running reaction manager....\n");
					#endif

					call RxnMgrI.runRxnMgr();

					#if DEBUG_AGILLA_ENGINE
					dbg("DBG_USR1", "AgillaEngineM: Done running reaction manager....\n");
					#endif

					return;	// leave agent out of run queue		
				}
			}

			if (call ResetMgrI.isResetting() != SUCCESS)
			{
				call QueueI.enqueue(context, &runQueue, context); // re-enqueue context
				post engine();
				call RxnMgrI.runRxnMgr();
			}
		}
	}

	/**
	 * Run the specified agent.	The agent's state must be AGILLA_STATE_RUN.
	 */
	command error_t AgentExecutorI.run(AgillaAgentContext* context) 
	{	
	#if DEBUG_AGILLA_ENGINE
		dbg("DBG_USR1", "AgillaEngineM: run() called on agent %i.\n", context->id.id);	
	#endif	
	
	if (call ResetMgrI.isResetting() == SUCCESS || context->state != AGILLA_STATE_RUN) 
	{
		dbg("DBG_USR1", "AgillaEngineM: run() ERROR: mote resetting or context not in run state (%i).\n", context->state);	
		return FAIL;
	}
	//else if (context->queue != &runQueue) 
	else if (context->queue == NULL) // do not run the agent if it is in any other queue
	{
		call QueueI.enqueue(context, &runQueue, context);	
		post engine();

	} else
	{
		dbg("DBG_USR1", "AgillaEngineM: run() ERROR: context in another queue 0x%x.\n", context->queue);	
	}
	return SUCCESS;
	}
	
	/**
	 * Returns whether the AgentExecutor is idle.
	 *
	 * @param SUCCESS or FAIL
	 */
	command error_t AgentExecutorI.isIdle() {
	if(call QueueI.empty(&runQueue))
		return SUCCESS;
	else
		 return FAIL;	
	}
	
	
	inline error_t defaultExecute(uint8_t instr, AgillaAgentContext* context) {
	dbg("DBG_ERROR|DBG_USR1", "VM: Executing default instruction: halt!\n");
	context->state = AGILLA_STATE_HALT;
	call ErrorMgrI.error2d(context, AGILLA_ERROR_INVALID_INSTRUCTION, 2, instr);
	return FAIL;
	}	
	
	/**
	 * Define the default instruction as HALT.
	 */
	default command error_t BasicISA.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA1.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA2.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA3.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA4.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA5.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA6.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	 
	default command error_t ExtendedISA7.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA8.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA9.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA10.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA11.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	
	default command error_t ExtendedISA12.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	 
	default command error_t ExtendedISA13.execute[uint8_t opcode](uint8_t instr, 
	AgillaAgentContext* context) 
	{
	return defaultExecute(instr, context);
	}	 
}
