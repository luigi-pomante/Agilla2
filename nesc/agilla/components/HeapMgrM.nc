// $Id: HeapMgrM.nc,v 1.4 2006/01/10 07:45:14 chien-liang Exp $

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
#include "MigrationMsgs.h"

module HeapMgrM {
	provides interface HeapMgrI; 
	uses interface VarUtilI;	
}
implementation {
	
	/**
	 * Finds the highest address used in the heap.
	 *
	 * @param context The context containing the heap.
	 * @return The highest used address, or 0xffff if none are used.
	 */
	command uint16_t HeapMgrI.maxAddr(AgillaAgentContext* context) {
	int16_t i;

	#if DEBUG_HEAPMGR
	dbg("DBG_USR1", "HeapMgrM: HeapMgrI.maxAddr(): Finding the max heap address being used by agent %i.\n", context->id.id);
	#endif
		
	for (i = AGILLA_HEAP_SIZE - 1; i >= 0; i--) {
		#if DEBUG_HEAPMGR
		dbg("DBG_USR1", "HeapMgrM: HeapMgrI.maxAddr(): heap[%i].vtype = %i.\n", i, context->heap.pos[i].vtype);
		#endif				
		if (context->heap.pos[i].vtype != AGILLA_TYPE_INVALID) {
		#if DEBUG_HEAPMGR
		dbg("DBG_USR1", "HeapMgrM: HeapMgrI.maxAddr(): Max heap address is %i.\n", i);
		#endif		
		return i;
		}
	}
	
	#if DEBUG_HEAPMGR
	dbg("DBG_USR1", "HeapMgrM: HeapMgrI.maxAddr(): Agent %i is not using her heap.\n", context->id.id);
	#endif
	
	return 0xffff;
	}
	
	/**
	 * Retrieves the heap data starting at the specified address
	 * by storing it in the provided heap message.
	 *
	 * @param context The context containing the heap
	 * @param addr The heap address from which to start
	 * @param heapMsg A pointer to the heap message to fill.
	 * @return The heap address to start at next time
	 */
	command uint8_t HeapMgrI.fillMsg(AgillaAgentContext* context, uint8_t addr, 
	AgillaHeapMsg* heapMsg) 
	{			
	uint16_t i = 0;	// memory address in heapMsg->data to store next byte
	bool msgFull = FALSE;
		 
	// find the next used heap address	
	while (addr < AGILLA_HEAP_SIZE	&& !msgFull)
	{
		uint8_t vType = context->heap.pos[addr].vtype;
		if (vType != AGILLA_TYPE_INVALID) 
		{
		uint16_t varSize = call VarUtilI.getSize(context, vType);		
		if (varSize != 0 && i + varSize + 2 < AGILLA_HEAP_MSG_SIZE) 
		{
			heapMsg->data[i++] = addr;
			heapMsg->data[i++] = vType;
			memcpy((void*)&heapMsg->data[i], (void*)&context->heap.pos[addr].loc, varSize);
			i += varSize;
		} else 
			msgFull = TRUE;
		}
		if (!msgFull)
		addr++;				
	}
	
	// fill the rest of the message with TYPE=INVALID
	while (i < AGILLA_HEAP_MSG_SIZE) {
		heapMsg->data[i++] = AGILLA_TYPE_INVALID; 
	}
	return addr;
	}
	
	/**
	 * Saves the data within an heap message into the
	 * specified agent's context.
	 *
	 * @param context The context containing the opstack
	 * @param heapMsg The heap message to save.
	 * @return SUCCESS if the message was saved, FAIL if the message was
	 * a duplicate.
	 */
	command error_t HeapMgrI.saveMsg(AgillaAgentContext* context, AgillaHeapMsg* heapMsg)
	{
	uint8_t addr, vtype;
	uint16_t i = 0;
	bool done;
	
	addr = heapMsg->data[i++];
	vtype = heapMsg->data[i++];	
	done = (vtype == AGILLA_TYPE_INVALID);
	
	if (context->heap.pos[addr].vtype != AGILLA_TYPE_INVALID) 
	{
		dbg("DBG_USR1", "HeapMgrM: HeapMsgI.saveMsg(): ERROR: The heap message was a duplicate.\n");
		return SUCCESS;
	}
	
	while (!done) 
	{
		uint16_t varSize = call VarUtilI.getSize(context, vtype);
		if (varSize != 0) 
		{
		
		#if DEBUG_HEAP_MGR
			dbg("DBG_USR1", "HeapMgrM: HeapMsgI.saveMsg(): Saving variable	type %i in heap[%i].\n", vtype, addr);
		#endif
		
		context->heap.pos[addr].vtype = vtype;
		memcpy((void*)&context->heap.pos[addr].loc, (void*)&heapMsg->data[i], varSize);
		i += varSize;
		
		if (i+3 < AGILLA_HEAP_MSG_SIZE) 
		{
			addr = heapMsg->data[i++];
			vtype = heapMsg->data[i++];
			if (vtype == AGILLA_TYPE_INVALID)
			done = TRUE;
		} else
			done = TRUE;
		} else
		{
		dbg("DBG_USR1", "HeapMgrM: HeapMsgI.saveMsg(): ERROR: Variable in HeapMsg is size 0.\n");
		}
	}
	return SUCCESS;	
	}	 

	
	/**
	 * Resets the context's heap.
	 */
	command error_t HeapMgrI.reset(AgillaAgentContext* context) {
	int i;
	for (i = 0; i < AGILLA_HEAP_SIZE; i++) {
		context->heap.pos[i].vtype = AGILLA_TYPE_INVALID;
	}
	return SUCCESS;
	}
	
	
	/**
	 * Returns the number of messages required to transfer the
	 * agent's heap.
	 */
	command uint8_t HeapMgrI.numHeapMsgs(AgillaAgentContext* context) 
	{	
	uint8_t i, result = 0, counter = 0;	
	
	for (i = 0; i < AGILLA_HEAP_SIZE; i++) 
	{
		if (context->heap.pos[i].vtype != AGILLA_TYPE_INVALID) 
		{
		uint16_t varSize = call VarUtilI.getSize(context, 
			context->heap.pos[i].vtype) + 2; // add 2 bytes to include address and type
		if (counter + varSize < AGILLA_HEAP_MSG_SIZE)			 
			counter += varSize;
		else {
			result++;
			counter = varSize;
		}
		}
	}
	if (counter > 0)
		result++;
	return result;
	}
	
	/**
	 * Determines whether the agent is using its heap.
	 */
	command error_t HeapMgrI.hasHeap(AgillaAgentContext* context) {
	if (call HeapMgrI.maxAddr(context) == 0xffff)
		return FAIL;
	else
		return SUCCESS;
	}
}
