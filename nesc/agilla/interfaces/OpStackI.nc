// $Id: OpStackI.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
 * The interface of an Agilla Operand Stack.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
interface OpStackI {
	/**
	 * Push an agent ID onto the operand stack.
	 *
	 * @param aID the AgillaAgentID
	 * @return SUCCESS if the value was placed on the stack, FAIL
	 * otherwise (e.g. stack overflow).
	 */
	command error_t pushAgentID(AgillaAgentContext* context, AgillaAgentID* aID);

	/**
	 * Pushes an location onto the operand stack.
	 *
	 * @param context The context to modify.
	 * @param loc The AgillaLocation to push.
	 * @return SUCCESS if the location was placed on the stack.
	 */
	command error_t pushLocation(AgillaAgentContext* context, AgillaLocation* loc);

	/**
	 * Pushes a string onto the operand stack.
	 *
	 * @param context The context to modify.
	 * @param string The string to push.
	 * @return SUCCESS if the name was placed on the stack
	 */
	command error_t pushString(AgillaAgentContext* context, uint16_t string);

	/**
	 * Push a sensor reading onto a context's operand stack.
	 *
	 * @param context The context to modify.
	 * @param type The sensor reading type (one of AGILLA_STYPE_*)
	 * @param val The value to push
	 * @return SUCCESS if the value was placed on the stack, FAIL
	 * otherwise (e.g. stack overflow).
	 */
	command error_t pushReading(AgillaAgentContext* context, uint16_t type, int16_t val);

	/**
	 * Pushes an AgillaType onto the operand stack.
	 *
	 * @param context The context to modify.
	 * @param type The type of the data to match.
	 * @return SUCCESS if TYPE was placed on the stack.
	 */
	command error_t pushType(AgillaAgentContext* context, uint16_t type);

	/**
	 * Pushes an AgillaRType for a reading onto the operand stack.
	 *
	 * @param context The context to modify.
	 * @param rType The type of the reading data to match.
	 * @return SUCCESS if TYPE was placed on the stack.
	 */
	command error_t pushReadingType(AgillaAgentContext* context, uint16_t rType);

	/**
	 * Push a 16-bit signed value onto a context's operand stack.
	 *
	 * @param context The context to modify.
	 * @param val The value to push.
	 * @return SUCCESS if the value was placed on the stack.
	 */
	command error_t pushValue(AgillaAgentContext* context, int16_t val);

	/**
	 * Push a generic operand onto a context's operand stack. This is
	 * useful when the type of the operand is irrelevant or unknown
	 * (e.g. pushing a variable that was popped).
	 *
	 * @param context The context to modify
	 *
	 * @param var The variable to push.
	 *
	 * @return SUCCESS if the value was placed on the stack, FAIL
	 * otherwise (e.g. stack overflow).
	 */
	command error_t pushOperand(AgillaAgentContext* context, AgillaVariable* var);

	/**
	 * Pop an operand off of a context's operand stack. If the stack is empty,
	 * a variable of type AGILLA_TYPE_INVALID is returned.
	 *
	 * @param context The context to pop from.
	 * @param var The variable to store the operand in.
	 * @return SUCCESS If there was an operand to pop.
	 */
	command error_t popOperand(AgillaAgentContext* context, AgillaVariable* var);

	/**
	 * Peek at the top operand of a context's operand stack. If the stack is empty,
	 * a variable of type AGILLA_TYPE_INVALID is returned.
	 *
	 * @param context The context to pop from.
	 * @param var The variable to store the operand in.
	 * @return SUCCESS If there was an operand to pop.
	 */
	command error_t peekOperand(AgillaAgentContext* context, AgillaVariable* var);
	
	/**
	 * Gets the depth of the operand stack in bytes.
	 *
	 * @return The depth.
	 */
	command uint8_t getOpStackDepth(AgillaAgentContext* context);
	
	/**
	 * Returns the number of messages required to transfer the
	 * agent's operand stack.
	 */
	command uint8_t numOpStackMsgs(AgillaAgentContext* context);
	
	/**
	 * Retrieves the operand stack data starting at the specified address
	 * by storing it in the provided op stack message.
	 *
	 * @param context The context containing the opstack
	 * @param addr The opstack address from which to start
	 * @param osMsg A pointer to the op stack message to fill.
	 * @return The op stack address to start at next time
	 */	
	command uint8_t fillMsg(AgillaAgentContext* context, uint8_t startAddr, 
	AgillaOpStackMsg* osMsg);
	
	/**
	 * Saves the data within an op stack message into the
	 * specified agent's context.
	 *
	 * @param context The context containing the opstack
	 * @param osMsg The op stack message.
	 * @return SUCCESS if the message is new, FAIL otherwise
	 */
	command error_t saveMsg(AgillaAgentContext* context, AgillaOpStackMsg* osMsg);
	
	/**
	 * Resets the context's operand stack.
	 */
	command error_t reset(AgillaAgentContext* context);
	
	/**
	 * Prints a string representation of the Operand Stack.
	 */
	command error_t toString(AgillaAgentContext* context);
}

