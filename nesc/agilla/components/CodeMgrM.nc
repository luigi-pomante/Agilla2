// $Id: CodeMgrM.nc,v 1.6 2006/01/13 00:02:44 chien-liang Exp $

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

//includes Agilla;
//includes MigrationMsgs;

#include "Agilla.h"
#include "MigrationMsgs.h"
/**
 * Manages the code memory allocated to an agent.
 * The code memory is divided into blocks where 
 * each block has a pointer to the next block.
 * The code manager links the minimal number of
 * blocks required to hold an agent's code.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module CodeMgrM
{
	provides
	{
		interface CodeMgrI;
		interface Init;
	}

	uses interface ErrorMgrI;	
}

implementation 
{
	bool used[ AGILLA_NUM_CODE_BLOCKS ];	// block usage
	int16_t nbPtr[ AGILLA_NUM_CODE_BLOCKS ];	// next block pointer 
	uint8_t code[ AGILLA_CODE_BLOCK_SIZE * AGILLA_NUM_CODE_BLOCKS ]; // the shared code buffer	 

	void clearBlock(int block)
	{
		int i, addr = block*AGILLA_CODE_BLOCK_SIZE;	

		used[block] = FALSE;

		#if DEBUG_CODEMGR
		dbg("DBG_USR1", "CodeMgrI: DEALLOCATED block %i.\n", block);
		#endif	

		nbPtr[block] = -1;
		for (i = addr; i < addr + AGILLA_CODE_BLOCK_SIZE; i++)
		{
			code[i] = 0;
		}	 
	}

	command error_t Init.init()
	{
		int i;		
		for (i = 0; i < AGILLA_NUM_CODE_BLOCKS; i++)
		{			
			clearBlock(i);
		}

		#ifdef INCLUDE_CODE_MGR_MSG_PRINTS
		sendingState = FALSE;
		#endif

		return SUCCESS;
	}

	int16_t numFreeBlocks()
	{
		int16_t i, result = 0;
		for (i = 0; i < AGILLA_NUM_CODE_BLOCKS; i++)
		{
			if (!used[i])
			{
				result++;

				#if DEBUG_CODEMGR
				dbg("DBG_USR1", "CodeMgrI: numFreeBlocks(): block %i is free.\n", i);
				#endif				 
			}
			else
			{
				#if DEBUG_CODEMGR
				dbg("DBG_USR1", "CodeMgrI: numFreeBlocks(): block %i is used.\n", i);
				#endif			 
			}
		}
		return result;
	} 


	int16_t getFreeBlock()
	{
		int16_t i;
		for (i = 0; i < AGILLA_NUM_CODE_BLOCKS; i++)
		{
			if (!used[i])
			{
				used[i] = TRUE;

				#if DEBUG_CODEMGR
				dbg("DBG_USR1", "CodeMgrI: ALLOCATED block %i.\n", i);
				#endif		 
				return i;
			}
		}
		return -1;
	}

	/**
	 * Returns the index of the block that is offset (an integer) away from
	 * sBlock (the start block).
	 */
	int16_t getBlock(int sBlock, int offset)
	{
		int16_t i, cBlock = sBlock;
		for (i = 0; i < offset; i++)
		{
			cBlock = nbPtr[cBlock];
			if (cBlock == -1) return -1;
		}
		return cBlock;
	}

	/**
	 * Allocate a set of blocks for an agent.	If successful, the sBlock field
	 * within the specified context will be set.
	 *
	 * @param context The calling agent's context.
	 * @param codeSize The number of bytes needed by the agent's code.
	 * @return SUCCESS if the allocation was successful.
	 */	
	command error_t CodeMgrI.allocateBlocks(AgillaAgentContext* context, uint16_t codeSize) 
	{
		int16_t i, numBlocks;

		numBlocks = (int)codeSize/AGILLA_CODE_BLOCK_SIZE;
		if (numBlocks*AGILLA_CODE_BLOCK_SIZE < codeSize)
			numBlocks++;

		#if DEBUG_CODEMGR
		dbg("DBG_USR1", "CodeMgrI: Must allocate %i blocks.\n", numBlocks);
		#endif	

		if (numBlocks > numFreeBlocks()) 
		{
			dbg("DBG_USR1", "CodeMgrI: ERROR: Not enough free blocks.\n");		
			//call ErrorMgrI.error(context, AGILLA_ERROR_CODE_OVERFLOW);
			return FAIL;
		}
		else 
		{	
			int16_t pBlock, nBlock;
			context->codeSize = codeSize;
			context->sBlock = getFreeBlock();

			if (context->sBlock == -1) 
			{
				call ErrorMgrI.errord(context, AGILLA_ERROR_GET_FREE_BLOCK, 1);
				return FAIL;
			}

			#if DEBUG_CODEMGR
			dbg("DBG_USR1", "CodeMgrI.allocateBlocks(): Allocating %i block(s) for agent %i, start block = %i.\n", numBlocks, context->id.id, context->sBlock);
			#endif

			pBlock = context->sBlock;		
			for (i = 0; i < numBlocks - 1; i++) // get rest of the blocks
			{
				nBlock = getFreeBlock();
				if (nBlock == -1) 
				{
					call CodeMgrI.deallocateBlocks(context);
					call ErrorMgrI.errord(context, AGILLA_ERROR_GET_FREE_BLOCK, 2);			
					return FAIL;
				}

				nbPtr[pBlock] = nBlock;
				pBlock = nBlock;

				#if DEBUG_CODEMGR
				dbg("DBG_USR1", "\tNext block: %i\n", pBlock);
				#endif		
			}
		}
		return SUCCESS;
	}

	/**
	 * Fills a block with code.
	 * 
	 * @param context The context that block belongs to.
	 * @param cMsg The message containing the block of code, which
	 *			 specifies which block to store the code in.
	 * @return SUCCESS if successful.
	 */	
	command error_t CodeMgrI.setBlock(AgillaAgentContext* context, AgillaCodeMsg* cMsg)
	{	
		int16_t i, cBlock;	
		cBlock = getBlock(context->sBlock, (int)cMsg->msgNum);	
		if (cBlock == -1)
		{
			dbg("DBG_USR1", "CodeMgrM: Problem in setBlock.	Could not get block %i\n", cMsg->msgNum);
			call ErrorMgrI.error2d(context, AGILLA_ERROR_ILLEGAL_CODE_BLOCK, 0x01, cMsg->msgNum);
			return FAIL;
		}
		else
		{	
			for (i = 0; i < AGILLA_CODE_BLOCK_SIZE; i++)
			{
				code[cBlock*AGILLA_CODE_BLOCK_SIZE + i] = cMsg->code[i];		
			}
			return SUCCESS;
		}
	}
	
	/**
	 * Deallocates all blocks allocated to an agent.
	 *
	 * @param context The agent that currently owns the blocks.	 
	 */
	command error_t CodeMgrI.deallocateBlocks(AgillaAgentContext* context)
	{
		int16_t nBlock, cBlock;
		cBlock = context->sBlock;

		while (cBlock != -1)
		{
			nBlock = nbPtr[cBlock];
			clearBlock(cBlock);
			cBlock = nBlock;
		}

		context->sBlock = -1;
		return SUCCESS;		 
	}

	/**
	 * Get a particular instruction.
	 *
	 * @param context The calling agent context to modify.	 
	 * @param pc The agent's program counter.
	 * @return The instruction. 
	 */
	command uint8_t CodeMgrI.getInstruction( AgillaAgentContext* context, uint16_t pc )
	{
		int16_t cBlock, boffset, coffset;	

		boffset = (int)(pc/AGILLA_CODE_BLOCK_SIZE);	// the block number
		coffset = pc - AGILLA_CODE_BLOCK_SIZE*boffset; // the offset within the block

		cBlock = getBlock(context->sBlock, boffset);

		if (cBlock == -1)
		{
			#if DEBUG_CODEMGR
			dbg("DBG_USR1", "CodeMgrM: Problem in getInstruction\n");
			dbg("DBG_USR1", "\tid = %i.\n", context->id.id);
			dbg("DBG_USR1", "\tpc = %i.\n", pc);
			dbg("DBG_USR1", "\tboffset = %i.\n", boffset);
			dbg("DBG_USR1", "\tcoffset = %i.\n", coffset);
			dbg("DBG_USR1", "\tsBlock = %i.\n", context->sBlock);
			dbg("DBG_USR1", "\tcBlock = %i.\n", cBlock);
			#endif
			call ErrorMgrI.error2d(context, AGILLA_ERROR_ILLEGAL_CODE_BLOCK, 0x02, boffset);
			return 0x00; // halt
		}
		else				 
			return code[ cBlock*AGILLA_CODE_BLOCK_SIZE + coffset ];
	}
	
	/**
	 * Fills a code message with a block of code.	Sets the "which" field in the message.
	 *
	 * @param context The agent context with the code.
	 * @param msg The message to modify.
	 * @param blockNum Which code block to save into the message.
	 * @return SUCCESS If the message was filled
	 */	
	command error_t CodeMgrI.fillCodeMsg(AgillaAgentContext* context, AgillaCodeMsg* msg, int16_t blockNum) 
	{
		int16_t i, cBlock = getBlock(context->sBlock, blockNum);	

		if (cBlock == -1)
		{
			dbg("DBG_USR1", "CodeMgrM: Problem in fillCodeMsg.\n");
			call ErrorMgrI.error2d(context, AGILLA_ERROR_ILLEGAL_CODE_BLOCK, 0x03, blockNum);

			#ifdef INCLUDE_CODE_MGR_MSG_PRINTS
			state = index = 0;
			sendingState = TRUE;
			post sendState();
			#endif

			return FAIL;
		}
		else
		{	
			for (i = 0; i < AGILLA_CODE_BLOCK_SIZE; i++)
			{
				msg->code[i] = code[cBlock*AGILLA_CODE_BLOCK_SIZE + i];
			}
			msg->msgNum = blockNum;
			return SUCCESS;
		}
	}
	
	/**
	 * Transfer all of the code from one context to another.
	 * 
	 * @param fromContext The context containing the code.
	 * @param toContext The context to transfer the code into.
	 * @return SUCCESS If the transfer was successful
	 */	
	/*command error_t CodeMgrI.transferCode(AgillaAgentContext* fromContext, 
	AgillaAgentContext* toContext) 
	{
	int16_t i, numMsgs = fromContext->codeSize / AGILLA_CODE_BLOCK_SIZE;	
	AgillaCodeMsg msg;	
	if (numMsgs * AGILLA_CODE_BLOCK_SIZE < fromContext->codeSize) numMsgs++;	
	for (i = 0; i < numMsgs; i++) {
		call CodeMgrI.fillCodeMsg(fromContext, &msg, i); // create a code message
		call CodeMgrI.setBlock(toContext, &msg);		 // set code message in new context
	}
	return SUCCESS;
	}*/	 
}
