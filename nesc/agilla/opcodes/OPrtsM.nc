// $Id: OPrtsM.nc,v 1.11 2006/01/23 22:53:41 chien-liang Exp $

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
 * Handles the initiation and termination of a remote tuple space
 * operation.
 *
 * @author Chien-Liang Fok
 */
module OPrtsM {
	provides {
	interface BytecodeI;

	interface Init;
	}
	uses {		
	interface NeighborListI;
	interface LocationMgrI;
	interface RemoteTSOpMgrI;
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
	 * Only one agent per mote can issue a remote tuple space
	 * operation, _currAgent is a pointer to this agent's context.
	 * If another agent attempts to perform a remote tuple space
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
	
	/**
	 * Remembers which neighbor we are dealing with.	Used by 
	 * instruction routgs.
	 */
	uint16_t _cNbrIndex;
	
	/**
	 * The tuple or template parameter.
	 */
	AgillaTuple tuple;
	
	task void doOProutgs();
	task void doOPrrdpgs();

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
	} */

	inline error_t finish(error_t success)
	{
	//_currAgent->condition = (uint16_t)success;	//<-QUI
	if(success == SUCCESS) _currAgent->condition = 1;
	else _currAgent->condition = 0;
	call AgentMgrI.run(_currAgent);
	_currAgent = NULL;
	
	// If there are pending agents, execute them
	if (!call QueueI.empty(&waitQueue)) 
	{
		#if DEBUG_OP_RTS
		dbg("DBG_USR1", "OPrtsM: finish(): WaitQueue (0x%x) not empty, running next agent.\n", &waitQueue);
		#endif	
		
		call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));		
	}
	return SUCCESS;
	}

	
	event error_t RemoteTSOpMgrI.done(AgillaAgentContext* agent, 
	uint16_t dest, error_t success)
	{ 
	if (_instr == IOProutgs)
	{
		if (post doOProutgs() == SUCCESS)
		return SUCCESS;
		else
		{
		dbg("DBG_USR1", "VM (%i:%i): OPrtsM: RemoteTSOpMgrI.done(): ERROR: Could not post doOProutgs().\n", _currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);
		}
	} else if (_instr == IOPrrdpgs)
	{
		if (success == SUCCESS) 
		{
		AgillaTuple buff; 
		AgillaLocation loc;
		 
		// remove the tuple from the agent's stack		 
		call TupleUtilI.getTuple(agent, &buff);
		 
		// get the destination's location
		if (call LocationMgrI.getLocation(dest, &loc) == SUCCESS)
		{
			agent->heap.pos[0].value.value++; // update number of results
			agent->heap.pos[agent->heap.pos[0].value.value].vtype = AGILLA_TYPE_LOCATION;
			agent->heap.pos[agent->heap.pos[0].value.value].loc = loc;
			
			#if DEBUG_OP_RTS
			dbg("DBG_USR1", "OPrtsM: OPrrdpgs: Saved location (%i, %i) onto heap[%i].\n",
				agent->heap.pos[agent->heap.pos[0].value.value].loc.x,
				agent->heap.pos[agent->heap.pos[0].value.value].loc.y,
				agent->heap.pos[0].value.value);
			#endif				
		}
		}
		
		if (post doOPrrdpgs() == SUCCESS)
		return SUCCESS;
		else
		{
		dbg("DBG_USR1", "VM (%i:%i): OPrtsM: RemoteTSOpMgrI.done(): ERROR: Could not post doOPrrdpgs().\n", _currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);
		}
	} else
		return finish(success);	
	}

	/**
	 * For debugging purposes.
	 */
	inline void printDebug(AgillaAgentContext* context, uint8_t instr) 
	{
	switch(instr)	// print debug message
	{	
		case IOProut:
		dbg("DBG_USR1", "VM (%i:%i): Executing OProut.\n", context->id.id, context->pc-1);
		break;
		case IOPrinp:
		dbg("DBG_USR1", "VM (%i:%i): Executing OPrinp.\n", context->id.id, context->pc-1);
		break;
		case IOPrrdp:
		dbg("DBG_USR1", "VM (%i:%i): Executing OPrrdp.\n", context->id.id, context->pc-1);
		break;
		case IOPrrdpg:
		dbg("DBG_USR1", "VM (%i:%i): Executing OPrrdpg.\n", context->id.id, context->pc-1);
		break;		
		case IOProutg:
		dbg("DBG_USR1", "VM (%i:%i): Executing OProutg.\n", context->id.id, context->pc-1);
		break;		
		case IOProutgs:
		dbg("DBG_USR1", "VM (%i:%i): Executing OProutgs.\n", context->id.id, context->pc-1);
		break;			
		case IOPrrdpgs:
		dbg("DBG_USR1", "VM (%i:%i): Executing OPrrdpgs.\n", context->id.id, context->pc-1);
		break;					
	}		 
	} // printDebug()
	
	/**
	 * Execute a remote tuple space operation.
	 *
	 * @param instr The remote tuple space operation instruction.
	 * @param context The agent performing the operation.
	 * @return SUCCESS If the operation is being perfomed.
	 */
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context)
	{		
	// Change the context's state to WAITING.	This prevents the VM
	// from continuing to execute the agent.
	context->state = AGILLA_STATE_WAITING;
		
	// Mutual Exclusion.	Only allow one agent to perform
	// a remote tuple space operation at a time.
	if (_currAgent != NULL) 
	{
		#if DEBUG_OP_RTS
		dbg("DBG_USR1", "OPrtsM: execute(): Another agent is performing remote TS Op, waiting...\n");
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
		if (instr == IOPrrdpg || instr == IOProutg || instr == IOProutgs || instr == IOPrrdpgs)
		dest = AM_BROADCAST_ADDR;
		else 
		{		
		AgillaVariable destV;	 
		if (call OpStackI.popOperand(_currAgent, &destV) == SUCCESS) 
		{		 
			if (destV.vtype & AGILLA_VAR_V)
			dest = destV.value.value;
			else if (destV.vtype & AGILLA_VAR_L)
			dest = call LocationMgrI.getAddress(&destV.loc);	// convert location to address
			else 
			{
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: ERROR: Invalid destination type [%i].\n", 
				_currAgent->id.id, _currAgent->pc-1, destV.vtype);
			call ErrorMgrI.error2d(_currAgent, AGILLA_ERROR_INVALID_TYPE, 0x11, destV.vtype);
			return finish(FAIL);
			}
		} else
		{
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: ERROR: Could not pop destination off stack.\n", 
			_currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		}
		}

		#if DEBUG_OP_RTS
		if (instr == IOProutgs || instr == IOPrrdpgs)
			dbg("DBG_USR1", "OPrtsM: final destination = every neighbor\n");
		else {
			dbg("DBG_USR1", "OPrtsM: final destination = %i\n", dest);
		}
		#endif		

		// Get the template or tuple	
		if(call TupleUtilI.getTuple(_currAgent, &tuple) != SUCCESS)
		{
		dbg("DBG_USR1", "VM (%i:%i): OPrtsM: ERROR: Could not get tuple.\n", _currAgent->id.id, _currAgent->pc-1);
		return finish(FAIL);	// could not get tuple	
		} else
		{
		#if DEBUG_OP_RTS
			call TupleUtilI.printTuple(&tuple);
		#endif
		}

		if (instr == IOProutgs)
		{
		_cNbrIndex = 0;
		if (post doOProutgs() != SUCCESS)
		{
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: ERROR: RemoteTSOpMgrI.execute() could not post dOProutgs().\n", _currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		} else
		{
			#if DEBUG_OP_RTS
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: posted task dOProutgs().\n", _currAgent->id.id, _currAgent->pc-1);
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
		
		if (post doOPrrdpgs() != SUCCESS)
		{
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: ERROR: RemoteTSOpMgrI.execute() could not post dOPrrdpgs().\n", _currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		} else
		{
			#if DEBUG_OP_RTS
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: posted task dOPrrdpgs().\n", _currAgent->id.id, _currAgent->pc-1);
			#endif
			return SUCCESS;
		}	 
		}
		
		else
		{
		if (call RemoteTSOpMgrI.execute(_currAgent, instr, dest, tuple) != SUCCESS)
		{
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: ERROR: RemoteTSOpMgrI.execute() returned fail.\n", _currAgent->id.id, _currAgent->pc-1);
			return finish(FAIL);
		} else
			return SUCCESS;
		}
	}
	} // BytecodeI.execute
	
	
	task void doOProutgs()
	{
	if (call NeighborListI.numNeighbors() > _cNbrIndex)
	{
		uint16_t dest;
		if (call NeighborListI.getNeighbor(_cNbrIndex++, &dest) == SUCCESS)
		{
		if (call RemoteTSOpMgrI.execute(_currAgent, IOProut, dest, tuple) != SUCCESS)
		{
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM.doOProutgs(): ERROR: RemoteTSOpMgrI.execute() returned fail.\n", _currAgent->id.id, _currAgent->pc-1);
			finish(FAIL);
		} else 
		{
			#if DEBUG_OP_RTS
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: performing rout on node %i.\n", _currAgent->id.id, _currAgent->pc-1, dest);
			#endif
		}
		} else
		{
		dbg("DBG_USR1", "VM (%i:%i): OPrtsM.doOProutgs(): ERROR: Could not get neighbor %i.\n", _currAgent->id.id, _currAgent->pc-1, _cNbrIndex-1);
		post doOProutgs();
		}
	} else
	{
		#if DEBUG_OP_RTS
		dbg("DBG_USR1", "VM (%i:%i): OPrtsM: done performing routgs.\n", _currAgent->id.id, _currAgent->pc-1);
		#endif
		finish(SUCCESS);
	}
	}
	
	task void doOPrrdpgs()
	{
	if (call NeighborListI.numNeighbors() > _cNbrIndex)
	{
		uint16_t dest;
		if (call NeighborListI.getNeighbor(_cNbrIndex++, &dest) == SUCCESS)
		{
		if (call RemoteTSOpMgrI.execute(_currAgent, IOPrrdp, dest, tuple) != SUCCESS)
		{
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM.doOPrrdpgs(): ERROR: RemoteTSOpMgrI.execute() returned fail.\n", _currAgent->id.id, _currAgent->pc-1);
			finish(FAIL);
		} else 
		{
			#if DEBUG_OP_RTS
			dbg("DBG_USR1", "VM (%i:%i): OPrtsM: performing rrdp on node %i.\n", _currAgent->id.id, _currAgent->pc-1, dest);
			#endif
		}
		} else
		{
		dbg("DBG_USR1", "VM (%i:%i): OPrtsM.doOProutgs(): ERROR: Could not get neighbor %i.\n", _currAgent->id.id, _currAgent->pc-1, _cNbrIndex-1);
		post doOProutgs();
		}
	} else
	{
		#if DEBUG_OP_RTS
		dbg("DBG_USR1", "VM (%i:%i): OPrtsM: done performing rrdpgs.\n", _currAgent->id.id, _currAgent->pc-1);
		#endif
		finish(SUCCESS);
	}	
	}
}
