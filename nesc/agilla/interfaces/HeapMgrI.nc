// $Id: HeapMgrI.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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

interface HeapMgrI {
	/**
	 * Finds the highest address used in the heap.
	 *
	 * @param context The context containing the heap.
	 * @return The highest used address, or 0xffff if none are used.
	 */
	command uint16_t maxAddr(AgillaAgentContext* context);
	
	/**
	 * Retrieves the heap data starting at the specified address
	 * by storing it in the provided heap message.
	 *
	 * @param context The context containing the heap
	 * @param addr The heap address from which to start
	 * @param heapMsg A pointer to the heap message to fill.
	 * @return The heap address to start at next time
	 */
	command uint8_t fillMsg(AgillaAgentContext* context, uint8_t addr, AgillaHeapMsg* heapMsg);
	
	/**
	 * Saves the data within an heap message into the
	 * specified agent's context.
	 *
	 * @param context The context containing the opstack
	 * @param heapMsg The heap message to save.
	 */
	command error_t saveMsg(AgillaAgentContext* context, AgillaHeapMsg* heapMsg);

	/**
	 * Resets the context's heap.
	 */
	command error_t reset(AgillaAgentContext* context);
	
	/**
	 * Determines whether the agent is using its heap.
	 */
	command error_t hasHeap(AgillaAgentContext* context);
	
	/**
	 * Returns the number of messages required to transfer the
	 * agent's heap.
	 */
	command uint8_t numHeapMsgs(AgillaAgentContext* context);	
}
