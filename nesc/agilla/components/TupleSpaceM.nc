// $Id: TupleSpaceM.nc,v 1.12 2006/02/11 20:04:48 chien-liang Exp $

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
#include "AgillaOpcodes.h"

/**
 * The Agilla tuple space implementation.	Uses the mote's internal data memory.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module TupleSpaceM {
	provides {
	interface TupleSpaceI as TS;
	interface StdControl;
	interface Init;
	}
	uses {
	interface OpStackI;
	interface ErrorMgrI;
	interface TupleUtilI; 
	interface Leds;
	}
}

implementation {
	enum {
	COPY = 0,
	REMOVE = 1
	};
	
	uint8_t ts[AGILLA_TS_SIZE];		 // The tuple space
	uint16_t freeIndex;				// The pos of the next free space in the TS

	inline uint16_t getTuple(uint16_t tsIndex, AgillaTuple* tuple);

//-------------------------------------------------------------------------------------------
// THE FOLLOWING METHODS IMPLEMENT THE StdControl INTERFACE
//
	command error_t Init.init() {
	call TS.reset();
	return SUCCESS;
	}

	command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}

//-------------------------------------------------------------------------------------------
// THE FOLLOWING ARE UTILITY METHODS
//

	/**
	 * Returns the size (in bytes) of a tuple starting at the
	 * specified pos.
	 */
	inline int16_t sizeInTS(uint16_t pos) {
	uint16_t i, spos = pos, size = ts[++pos];
	pos++;
	for (i = 0; i < size; i++) {
		switch(ts[pos++]) {
		case AGILLA_TYPE_LOCATION:
			pos += sizeof(AgillaLocation);
			break;
		case AGILLA_TYPE_AGENTID:
			pos += sizeof(AgillaAgentID);
			break;
		case AGILLA_TYPE_STRING:
			pos += sizeof(AgillaString);
			break;
		case AGILLA_TYPE_READING:
			pos += sizeof(AgillaReading);
			break;
		case AGILLA_TYPE_TYPE:
			pos += sizeof(AgillaType);
			break;
		case AGILLA_TYPE_VALUE:
			pos += sizeof(AgillaValue);
			break;			
		default:	
			dbg("DBG_USR1", "Error: Invalid tuple type: %i\n", ts[--pos]);	
			call ErrorMgrI.error2d(NULL, AGILLA_ERROR_INVALID_TYPE, 0x01, ts[pos-1]);
			return -1;
		break;
		}
	}	
	return pos - spos;
	}

	/**
	 * Removes a tuple from the tuple space.	
	 * 
	 * @param tsIndex The first position of the tuple.
	 */
	void deleteTuple(uint16_t tsIndex) {
	uint16_t i, tupleSize = sizeInTS(tsIndex);
	for (i = tsIndex; i < freeIndex; i++) {	// shift everything forward
		ts[i] = ts[i + tupleSize];
	}
	freeIndex -= tupleSize;	
	
	// Tells the reactions that the tuple space bytes have been
	// shifted to the left due to a tuple deletion.
	signal TS.byteShift(tsIndex+tupleSize, tupleSize);
	
	#if DEBUG_TS
		dbg("DBG_USR1", "TupleSpaceM: Deleted tuple at pos %i, size = %i, new freeIndex = %i\n", tsIndex, tupleSize, freeIndex);
	#endif
	}
	
	/**
	 * Gets a tuple from the tuplespace.
	 *
	 * @param tsIndex The starting point of the tuple
	 * @param tuple A pointer to where to store the tuple
	 * @return The pos of the next tuple
	 */
	inline uint16_t getTuple(uint16_t tsIndex, AgillaTuple* tuple) {
	if (tsIndex < freeIndex) {
		int16_t tupleSize = sizeInTS(tsIndex);	
		memcpy((void *)tuple, (void *)&ts[tsIndex], tupleSize);
		return tsIndex + tupleSize;
	} else
		return tsIndex;
	}

	/**
	 * Searches the tuple space starting at the specified index for a tuple matching 
	 * the specified template.
	 *
	 * One can tell if no tuple was found if the resulting tuple's size = 0, or if
	 * the return value = freeIndex.
	 *
	 * @param i The index from which to start searching.
	 * @param template The template.
	 * @param tuple The tuple to store the results in.
	 * @param type Either REMOVE or COPY
	 * @return The index of the tuple immediately after the matching tuple.
	 */
	uint16_t findTuple(uint16_t i, AgillaTuple *template, AgillaTuple *tuple, uint8_t type) {
	uint16_t tsIndex = i, nextTsIndex;
	bool isRemove = (type == REMOVE);	 
	AgillaTuple currTuple;
	
	//dbg(DBG_USR1, "****** type = %i\n", type);
	
	while (tsIndex < freeIndex) {
		nextTsIndex = getTuple(tsIndex, &currTuple);
		
		#if DEBUG_TS
		dbg("DBG_USR1", "TupleSpaceM: Checking if the following tuple is a match.\n");
		call TupleUtilI.printTuple(&currTuple);
		#endif
		
		if (call TupleUtilI.tMatches(template, &currTuple, isRemove) == SUCCESS) {
		#if DEBUG_TS
			dbg("DBG_USR1", "TupleSpaceM: Match found at pos %i\n", tsIndex);
		#endif		
		*tuple = currTuple;
		if (type == REMOVE) {
			deleteTuple(tsIndex);						
			return tsIndex;
		} else
			return nextTsIndex;
		} else {
		#if DEBUG_TS
			dbg("DBG_USR1", "----> Tuple did not match, skipping to next tuple...\n");
		#endif		 
		}
		tsIndex = nextTsIndex; // move to the next tuple
	}
	#if DEBUG_TS
		dbg("DBG_USR1", "TupleSpaceM: Reached end of TS without finding match.\n");
	#endif
	tuple->size = 0; // indicate failure
	return tsIndex;
	} // findTuple

	/**
	 * Searches the entire tuple space for a tuple matching the specified 
	 * template.
	 *
	 * @param template The template.
	 * @param tuple The tuple to store the results in.
	 * @param type Either REMOVE or COPY
	 * @return The size of the tuple in bytes, or 0 if no match was found.
	 */
	uint16_t getMatch(AgillaTuple *template, AgillaTuple *tuple, uint8_t type) {
	return findTuple(0, template, tuple, type);
	}

//-------------------------------------------------------------------------------------------
// THE IMPLEMENT THE TS INTERFACE
//

	/**
	 * Places a tuple into the tuple space.
	 *
	 * @param tuple The tuple to insert.
	 * @return SUCCESS if the operation was completed, FAIL if the tuple space
	 * is full.
	 */
	command error_t TS.out(AgillaTuple* tuple)
	{
	int16_t tupleSize = call TupleUtilI.sizeOf(tuple);	
	
	#if AGILLA_TS_NO_DUPLICATE
		AgillaTuple template = *tuple;
	#endif
	
	if (tupleSize == -1 || tupleSize == 0) 
	{
		dbg("DBG_USR1", "TS.out: ERROR: tupleSize = %i\n", tupleSize);
		call ErrorMgrI.error2d(NULL, AGILLA_ERROR_TUPLE_SIZE, 1, tupleSize);
		return FAIL;
	}
	 
	#if AGILLA_TS_NO_DUPLICATE
		dbg("DBG_USR1", "TS.out: Checking to see if this is a duplicate OUT. Template = \n");
		call TupleUtilI.printTuple(&template);
		
		if (call TS.rdp(&template) == SUCCESS)
		{
			dbg("DBG_USR1", "TS.out: Duplicate out! Refusing out OUT this tuple, but returning SUCCESS\n");
			return SUCCESS;
		}
	#endif
	 
	if (freeIndex + tupleSize >= AGILLA_TS_SIZE) 
	{
		dbg("DBG_USR1", "TS.out: Not enough space:	freeIndex = %i, tupleSize = %i, TS size = %i\n", freeIndex, tupleSize, AGILLA_TS_SIZE);
		return FAIL;
	} 
	
	memcpy((void *)&ts[freeIndex], (void *)tuple, tupleSize);
	freeIndex += tupleSize;	 
	
	//call Leds.redOn();
	//call Leds.greenOn();
	//call Leds.yellowOn();

	#if DEBUG_TS			
		dbg("DBG_USR1", "TS.out: freeIndex = %i\n", freeIndex);
		call TupleUtilI.printTuple(tuple);
	#endif		
	
	signal TS.newTuple(tuple);			
	return SUCCESS;
	}
	
	/**
	 * Remove a tuple from the tuple space matching the specified template.
	 * Return FAIL if no matching tuple was found.	If a match is found, return
	 * SUCCESS and store it within the template.	
	 *
	 * @param template The template.
	 * @return SUCCESS if a match was found, FAIL if no match was found.
	 */
	command error_t TS.hinp(AgillaTuple* template) {
	
	#if DEBUG_TS
		dbg("DBG_USR1", "TS.inp(...) called with template: \n");
		call TupleUtilI.printTuple(template);
	#endif
	
	getMatch(template, template, REMOVE);	
	

	if(template->size > 0) return SUCCESS;
	else return FAIL;
	}

	/**
	 * Find a tuple matching the specified template.
	 * Return FAIL if no matching tuple was found.
	 * Return SUCCESS If a match is found, and store the results in the template
	 *
	 * @param template The template.
	 * @return SUCCESS if a match was found, FAIL if no match was found, or RETRY
	 * if the tuple space is busy.
	 */
	command error_t TS.rdp(AgillaTuple* template) {
	
	#if DEBUG_TS
		dbg("DBG_USR1", "TS.rdp(...) called with template: \n");
		call TupleUtilI.printTuple(template);
	#endif
	
	getMatch(template, template, COPY);

	if(template->size > 0) return SUCCESS;
	else return FAIL;
	}

	command error_t TS.count(AgillaAgentContext* context, AgillaTuple* template) {
	int16_t tsIndex = 0, result = 0;		
	bool isRemove = FALSE;
	AgillaTuple tuple;
	
	#if DEBUG_TS
	dbg("DBG_USR1", "TS.count(...) called.\n");
	call TupleUtilI.printTuple(template);
	#endif	
	
	while(tsIndex != freeIndex) {
		tsIndex = getTuple(tsIndex, &tuple);
		if (call TupleUtilI.tMatches(template, &tuple, isRemove) == SUCCESS)
		result++;			 
	}	
	
	#if DEBUG_TS
	dbg("DBG_USR1", "Number of matches = %i\n", result);
	#endif		
	
	return call OpStackI.pushValue(context, result);
	}
	
	/**
	 * Fetches the next tuple matching the specified template starting 
	 * at the specified index. Saves the resulting tuple in the supplied 
	 * tuple pointer.	If the resulting tuple's size is 0, no tuple is found
	 * and the return value is the free index within the tuple space.
	 *
	 * @param start The starting address of the tuple
	 * @param tuple A pointer to where the results should be stored.
	 * @return The index at which to start next time.
	 */
	command uint16_t TS.getMatchingTuple(uint16_t start, AgillaTuple* template,
	AgillaTuple* tuple) 
	{
	return findTuple(start, template, tuple, COPY);
	}

	/**
	 * Prints the contents of the tuplespace.	This is only used while
	 * debugging in TOSSIM.
	 */	
	command error_t TS.toString() {
	#ifdef __CYGWIN__
	uint16_t i = 0;

	dbg("DBG_USR1", "\t\t------ TUPLE SPACE STATE ------\n");
	while (i < freeIndex) {
		AgillaTuple tuple;
		i = getTuple(i, &tuple);
		call TupleUtilI.printTuple(&tuple);		
	}
	dbg("DBG_USR1", "\t\t-------------------------------\n");	
	#endif
	return SUCCESS;
	}
	
	
	command error_t TS.reset()
	{
		AgillaTuple tuple;	
		uint16_t tupleSize;	 
		call TupleUtilI.createHostIDTuple(&tuple);	
		tupleSize = call TupleUtilI.sizeOf(&tuple); 
		freeIndex = 0;
		memset( (void*)ts, 0, AGILLA_TS_SIZE );
		memcpy((void *)&ts[freeIndex], (void *)&tuple, tupleSize);
		freeIndex += tupleSize;		
		return SUCCESS;
	}
}
