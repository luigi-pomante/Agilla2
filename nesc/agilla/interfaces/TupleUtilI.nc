// $Id: TupleUtilI.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
#include "TupleSpace.h"

interface TupleUtilI {
	/**
	 * Add a field to a tuple.
	 *
	 * @param tuple The tuple to modify.
	 * @param fieldNum The position within the tuple to add the field.
	 * @param var The field to add.
	 * @return the pos of the beginning of the next field in the tuple space.
	 */
	command int16_t addField(AgillaTuple* tuple, int16_t fieldNum, AgillaVariable* var);
	
	/**
	 * Get a field from a tuple.
	 * 
	 * @param tuple The tuple containing the field.
	 * @param pos The field number (0 being the first)
	 * @param var The field to store the results in.
	 * @return SUCCESS if the field was obtained
	 */
	command error_t getField(AgillaTuple* tuple, uint16_t pos, AgillaVariable* var);

	/** 
	 * Returns the size, in bytes, of a tuple.
	 */
	command int16_t sizeOf(AgillaTuple *tuple);
	
	/**
	 * Removes a tuple from the operand stack and saves it in the 
	 * specified tuple pointer.
	 *
	 * @param context The context containing the operand stack with the tuple.
	 * @param tuple The tuple to store the results in.	 
	 */
	command error_t getTuple(AgillaAgentContext* context, AgillaTuple* tuple);
	
	/**
	 * Determines whether a template field matches a tuple's field. 
	 */	
	command error_t fMatches(AgillaVariable* tmplt, AgillaVariable* tuple);
	
	/**
	 * Determines whether the two fields are identical.
	 */
	command error_t fEquals(AgillaVariable* field1, AgillaVariable* field2);
	
	/**
	 * Returns SUCCESS if the template matches the tuple, FAIL otherwise.
	 * If isRemove is TRUE, it bypasses system tuples and checks that the 
	 * owner is a match.
	 */
	command error_t tMatches(AgillaTuple* template, AgillaTuple* tuple, bool isRemove);
	
	/**
	 * Returns SUCCESS if the two tuples are equal, FALSE otherwise.
	 */
	command error_t isEqual(AgillaTuple* tuple1, AgillaTuple* tuple2);
	
	/**
	 * Pushes a tuple onto the operand stack.
	 *
	 * @param tuple The tuple.
	 * @param context The context containing the operand stack.
	 */
	command error_t pushTuple(AgillaTuple* tuple, AgillaAgentContext* context);
	
	/**
	 * Returns SUCCESS if all of the fields in the tuple are one of the types specified.
	 */
	command error_t checkFieldTypes(AgillaAgentContext* context, 
	AgillaTuple* tuple, uint16_t type);

	/**
	 * Prints a textual representation of a field.
	 * 
	 * @param field The field to print.
	 */
	command error_t printField(AgillaVariable* field);
	
	/**
	 * Prints a textual representation of a tuple.
	 *
	 * @param tuple The tuple to print.
	 */	
	command error_t printTuple(AgillaTuple* tuple);
	
	/**
	 * Creates a HostID tuple.
	 *
	 * @param tuple A pointer to the tuple to modify.
	 */
	command error_t createHostIDTuple(AgillaTuple* tuple);
	
	/**
	 * Creates an AgentID tuple.
	 *
	 * @param tuple A pointer to the tuple to modify.
	 */	
	command error_t createAgentIDTuple(AgillaTuple* tuple, AgillaAgentID id);
}
