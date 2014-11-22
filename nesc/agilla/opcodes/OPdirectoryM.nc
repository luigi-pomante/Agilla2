// $Id: OPdirectoryM.nc,v 1.2 2006/03/20 14:31:46 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2006, Washington University in Saint Louis 
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
 * Handles the initiation and termination of an agent directory 
 * service operation.
 *
 * @author Chien-Liang Fok
 */
module OPdirectoryM {
	provides {
	interface BytecodeI;
	//interface StdControl;
	interface Init;
	}
	uses {		
	// operation getAgents messages
	interface SendMsg as SendGetAgentsRequest;
	interface SendMsg as SendGetAgentsResults;		 // for routing	
	interface ReceiveMsg as ReceiveGetAgentsRequest; // for routing		
	interface ReceiveMsg as ReceiveGetAgentsResults;

	// operation getLocation messages
	interface SendMsg as SendGetLocationRequest;
	interface SendMsg as SendGetLocationResults;		 // for routing	
	interface ReceiveMsg as ReceiveGetLocationRequest; // for routing		
	interface ReceiveMsg as ReceiveGetLocationResults;
	
	// operation getNumAgents messages
	interface SendMsg as SendGetNumAgentsRequest;
	interface SendMsg as SendGetNumAgentsResults;		 // for routing	
	interface ReceiveMsg as ReceiveGetNumAgentsRequest; // for routing		
	interface ReceiveMsg as ReceiveGetNumAgentsResults;

	// operation getClosestAgent messages
	interface SendMsg as SendGetClosestAgentRequest;
	interface SendMsg as SendGetClosestAgentResults;		 // for routing	
	interface ReceiveMsg as ReceiveGetClosestAgentRequest; // for routing		
	interface ReceiveMsg as ReceiveGetClosestAgentResults;	
	
	interface NeighborListI;
	interface LocationMgrI;
	interface DirectoryMgrI;
	interface AgentMgrI;
	interface TupleUtilI;
	interface OpStackI;
	interface QueueI;		
	interface ErrorMgrI;	
	interface Leds; // debug
	}
}
implementation {

	/**
	 * Only one agent per mote can issue a directory service
	 * operation, _currAgent is a pointer to this agent's context.
	 * If another agent attempts to perform a directory service
	 * operation while the _currAgent is waiting for results,
	 * it's context is stored in the waitQueue and resumed when
	 * the current agent finishes.
	 */
	AgillaAgentContext* _currAgent;	
	
	/**
	 * Holds pending agents that are waiting for the current agent 
	 * to finish.
	 */
	Queue waitQueue;
	
	/**
	 * The instruction.
	 */
	uint16_t _instr;
	
	command error_t Init.init()
	{	
	_currAgent = NULL;	
	call QueueI.init(&waitQueue);
	return SUCCESS;
	}

 /* command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}	*/

	inline result_t finish(result_t success)
	{
	//_currAgent->condition = (uint16_t)success;
	if (success == SUCCESS) _currAgent->condition = 1;
	else _currAgent->condition = 0;
	call AgentMgrI.run(_currAgent);
	_currAgent = NULL;
	
	// If there are pending agents, execute them
	if (!call QueueI.empty(&waitQueue)) 
	{
		#if DEBUG_OP_DIRECTORY
		dbg(DBG_USR1, "OPdirectoryM: finish(): WaitQueue (0x%x) not empty, running next agent.\n", &waitQueue);
		#endif	
		
		call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));		
	}
	return SUCCESS;
	}

	
	event result_t DirectoryMgrI.done(AgillaAgentContext* agent, 
	uint16_t dest, result_t success)
	{	
		return finish(success);	
	}
	
	event result_t SendGetAgentsRequest.send(TOS_MsgPtr msg, result_t success)
	{
	call MessageBufferI.freeMsg(msg);
	return SUCCESS;
	}
	
	command result_t SendGetAgentsResults;		 // for routing	
	interface ReceiveMsg as ReceiveGetAgentsRequest; // for routing		
	interface ReceiveMsg as ReceiveGetAgentsResults;	

	/**
	 * For debugging purposes.
	 */
	inline void printDebug(AgillaAgentContext* context, uint8_t instr) 
	{
	switch(instr)	// print debug message
	{	
		case IOPgetagents:
		dbg(DBG_USR1, "VM (%i:%i): Executing OPgetagents.\n", context->id.id, context->pc-1);
		break;
		case IOPgetlocation:
		dbg(DBG_USR1, "VM (%i:%i): Executing OPgetlocation.\n", context->id.id, context->pc-1);
		break;
		case IOPgetnumagents:
		dbg(DBG_USR1, "VM (%i:%i): Executing OPgetnumagents.\n", context->id.id, context->pc-1);
		break;
		case IOPgetclosestagent:
		dbg(DBG_USR1, "VM (%i:%i): Executing OPgetclosestagent.\n", context->id.id, context->pc-1);
		break;		
	}		 
	} // printDebug()
	
	/**
	 * Execute a directory operation.
	 *
	 * @param instr The directory operation instruction.
	 * @param context The agent performing the operation.
	 * @return SUCCESS If the operation is being perfomed.
	 */
	command result_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) 
	{		
	// Change the context's state to WAITING.	This prevents the VM
	// from continuing to execute the agent.
	context->state = AGILLA_STATE_WAITING;
		
	// Mutual Exclusion.	Only allow one agent to perform
	// a remote tuple space operation at a time.
	if (_currAgent != NULL) 
	{
		#if DEBUG_OP_DIRECTORY
		dbg(DBG_USR1, "OPdirectoryM: execute(): Another agent is performing a directory operation, waiting...\n");
		#endif	
		
		context->pc--;		
		return call QueueI.enqueue(context, &waitQueue, context);
	} else
	{		
		uint16_t dest;
		_instr = instr;	 
		_currAgent = context;
		
		printDebug(context, instr);

		// Get the final destination address
		AgillaVariable destV;	 
		if (call OpStackI.popOperand(_currAgent, &destV)) 
		{		 
		if (destV.vtype & AGILLA_VAR_V)
			dest = destV.value.value;
		else if (destV.vtype & AGILLA_VAR_L)
			dest = call LocationMgrI.getAddress(&destV.loc);	// convert location to address
		else 
		{
			dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: ERROR: Invalid destination type [%i].\n", 
			_currAgent->id.id, _currAgent->pc-1, destV.vtype);
			call ErrorMgrI.error2d(_currAgent, AGILLA_ERROR_INVALID_TYPE, 0x11, destV.vtype);
			return finish(FAIL);
		}
		} else
		{
		dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: ERROR: Could not pop destination off stack.\n", 
			_currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);
		}
		

		#if DEBUG_OP_DIRECTORY
		dbg(DBG_USR1, "OPdirectoryM: final destination = %i\n", dest);	 
		#endif		

		// Get the template or tuple	
		if(!call TupleUtilI.getTuple(_currAgent, &tuple))
		{
		dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: ERROR: Could not get tuple.\n", _currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);	// could not get tuple	
		} else
		{
		#if DEBUG_OP_DIRECTORY
			call TupleUtilI.printTuple(&tuple);
		#endif
		}

		if (instr == IOProutgs)
		{
		_cNbrIndex = 0;
		if (!post doOProutgs())
		{
			dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: ERROR: RemoteTSOpMgrI.execute() could not post dOProutgs().\n", _currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		} else
		{
			#if DEBUG_OP_DIRECTORY
			dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: posted task dOProutgs().\n", _currAgent->id.id, _currAgent->pc-1);
			#endif
			return SUCCESS;
		}
		} 
		
		else if (instr == IOPrrdpgs)
		{
		_cNbrIndex = 0;
		
		// initialize the number of results
		_currAgent->heap.pos[0].vtype = AGILLA_TYPE_VALUE;
		_currAgent->heap.pos[0].value.value = 0;
		
		if (!post doOPrrdpgs())
		{
			dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: ERROR: RemoteTSOpMgrI.execute() could not post dOPrrdpgs().\n", _currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		} else
		{
			#if DEBUG_OP_DIRECTORY
			dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: posted task dOPrrdpgs().\n", _currAgent->id.id, _currAgent->pc-1);
			#endif
			return SUCCESS;
		}	 
		}
		
		else
		{
		if (!call RemoteTSOpMgrI.execute(_currAgent, instr, dest, tuple))
		{
			dbg(DBG_USR1, "VM (%i:%i): OPdirectoryM: ERROR: RemoteTSOpMgrI.execute() returned fail.\n", _currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		} else
			return SUCCESS;
		}
	}
	} // BytecodeI.execute
}
