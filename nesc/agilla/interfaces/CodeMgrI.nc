// $Id: CodeMgrI.nc,v 1.2 2005/11/02 18:59:40 chien-liang Exp $

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

/**
 * Manages the agent code blocks.	The codespace is divided into a series of
 * blocks.	Each agent can utilize one or more blocks of code, provided there
 * are enough free code blocks on the host.	The code manager serves as a layer
 * of abstraction between the code blocks and a continuous sequence of code.
 *
 * The code blocks are enumerated.	Each code block has a pointer that can
 * point to the next code block.	The agent is given the number of the first
 * block, which is used in combination with the program counter to find the 
 * next instruction.
 */
 
/**
 * @author Chien-Liang Fok
 */
interface CodeMgrI {

	/**
	 * Allocate a set of blocks for an agent.	If successful, the sBlock field
	 * within the specified context will be set.
	 *
	 * @param context The calling agent's context.
	 * @param codeSize The number of instructon bytes needed.
	 * @return SUCCESS if the allocation was successful.
	 */
	command error_t allocateBlocks(AgillaAgentContext* context, uint16_t codeSize);
	
	/**
	 * Fills a block with code.
	 * 
	 * @param context The context that block belongs to.
	 * @param cMsg The message containing the block of code, which
	 *			 specifies which block to store the code in.
	 * @return SUCCESS if successful.
	 */ 
	command error_t setBlock(AgillaAgentContext* context, AgillaCodeMsg* cMsg);
	
	/**
	 * Deallocates all blocks allocated to an agent.
	 *
	 * @param context The agent that currently owns the blocks.	 
	 */
	command error_t deallocateBlocks(AgillaAgentContext* context);
	
	/**
	 * Get a particular instruction.
	 *
	 * @param context The calling agent context to modify.	 
	 * @param pc The agent's program counter.
	 * @return The instruction. 
	 */
	command uint8_t getInstruction(AgillaAgentContext* context, uint16_t pc);
	
	/**
	 * Fills a code message with a block of code.	Sets the "which" field in the message.
	 *
	 * @param context The agent context with the code.
	 * @param msg The message to modify.
	 * @param blockNum Which code block to save into the message.
	 * @return SUCCESS If the message was filled
	 */
	command error_t fillCodeMsg(AgillaAgentContext* context, AgillaCodeMsg* msg, int16_t blockNum);
	
	/**
	 * Transfer all of the code from one context to another.
	 * 
	 * @param fromContext The context containing the code.
	 * @param toContext The context to transfer the code into.
	 * @return SUCCESS If the transfer was successful
	 */
	/*command error_t transferCode(AgillaAgentContext* fromContext, 
	AgillaAgentContext* toContext);*/
}
