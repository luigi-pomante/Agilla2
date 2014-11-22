// $Id: TupleUtilM.nc,v 1.7 2006/02/11 08:11:56 chien-liang Exp $

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

/**
 * Various utility methods for obtaining and saving tuples, and for
 * comparing and accessing tuple fields.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module TupleUtilM {
	provides interface TupleUtilI;
	uses {
	interface ErrorMgrI;
	interface OpStackI; 
	interface VarUtilI;
	}
}
implementation {
	inline void clearTuple(AgillaTuple* tuple) {
	tuple->flags = AGILLA_TUPLE_RESET;
	tuple->size = 0;
	}
	
	/**
	 * Add a field to a tuple.	Updtes the size field within the tuple.
	 *
	 * @param tuple The tuple to modify.
	 * @param pos The position within the tuple from which to add the field.
	 * @param var The field to add.
	 * @return the pos of the beginning of the next field in the tuple space,
	 *	 or -1 if the operation failed.
	 */
	command int16_t TupleUtilI.addField(AgillaTuple* tuple, int16_t pos, AgillaVariable* var)
	{
		int16_t varSize = call VarUtilI.getSize(NULL, var->vtype);
	
		/*
		#if DEBUG_TUPLE_UTIL
		  dbg("DBG_USR1", "TupleUtilM.addField: Adding field to tuple, varSize = %i\n", varSize);	
		  call TupleUtilI.printField(var);
		  call TupleUtilI.printTuple(tuple);
		#endif*/

		if (varSize != 0)
		{
			tuple->size++;
			tuple->data[pos++] = var->vtype;		

			if (pos + varSize <= AGILLA_MAX_TUPLE_SIZE)
			{
				memcpy( (void*)&tuple->data[pos], (void*)&var->loc, varSize );
				return pos + varSize;
			}
			else 
			{
				dbg("DBG_USR1", "ErrorMgrI: TupleUtilM.addField: Tuple overflow: %i\n", pos + varSize);
				call ErrorMgrI.errord(NULL, AGILLA_ERROR_TUPLE_SIZE, 2);				
			}		
		}
		return -1;
	}
	
	/**
	 * Get a field from a tuple.
	 * 
	 * @param tuple The tuple containing the field.
	 * @param fieldNum The field number (0 being the first)
	 * @param var The field to store the results in.
	 * @return SUCCESS if the field was obtained
	 */
	command error_t TupleUtilI.getField(AgillaTuple* tuple, uint16_t fieldNum, AgillaVariable* var) {
	uint16_t pos=0, currField;
	int16_t varSize;
	
	// Iterate through all of the fields
	for (currField = 0; currField < fieldNum; currField++) {		
		var->vtype = tuple->data[pos++];
		varSize = call VarUtilI.getSize(NULL, var->vtype);
		if (varSize != -1)
		pos += varSize;
		else
		return FAIL;
	}
	
	// save the field
	var->vtype = tuple->data[pos++];
	varSize = call VarUtilI.getSize(NULL, var->vtype);
	if (varSize != -1) {
		memcpy((void*)&var->loc, (void*)&tuple->data[pos], varSize);
		return SUCCESS;
	} else
		return FAIL;	
	}	
	
	/** 
	 * Returns the size, in bytes, of a tuple.	This includes
	 * the two bytes of header.
	 */
	command int16_t TupleUtilI.sizeOf(AgillaTuple *tuple) {
	int16_t i, pos = 0;
	
	#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilI.sizeOf(): calculating size of:\n");
		call TupleUtilI.printTuple(tuple);
	#endif
	
	for (i = 0; i < tuple->size; i++) {
		int16_t varSize = call VarUtilI.getSize(NULL, tuple->data[pos++]);
		if (varSize != -1)
		pos += varSize;
		else
		return -1;
	}		
	i = pos+2;
	
	#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilI.sizeOf(): Size of tuple = %i bytes\n", i);
	#endif	
	
	return i; // add two bytes for flags and size
	}	

	/**
	 * Determines whether a template field matches a tuple's field.
	 */
	command error_t TupleUtilI.fMatches(AgillaVariable* tempField, AgillaVariable* tupField) {
	if (tempField->vtype == tupField->vtype)	// actual match
		return call TupleUtilI.fEquals(tempField, tupField);	
	else if (tempField->vtype == AGILLA_TYPE_TYPE) { // formal match, non-sensor type
		switch(tempField->type.type) {
		case AGILLA_TYPE_ANY:		 
		return SUCCESS;
		case AGILLA_TYPE_AGENTID:	 
		//return tupField->vtype == AGILLA_TYPE_AGENTID;
		if(tupField->vtype == AGILLA_TYPE_AGENTID) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_LOCATION:	
		//return tupField->vtype == AGILLA_TYPE_LOCATION;
		if(tupField->vtype == AGILLA_TYPE_LOCATION) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_STRING:	
		//return tupField->vtype == AGILLA_TYPE_STRING;
		if(tupField->vtype == AGILLA_TYPE_STRING) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_VALUE:	 
		//return tupField->vtype == AGILLA_TYPE_VALUE;
		if(tupField->vtype == AGILLA_TYPE_VALUE) return SUCCESS;
		else return FAIL;
		default:
		dbg("DBG_USR1", "ERROR: TupleUtilM.fMatches: Invalid template field type %i.\n", tempField->type.type);
		call ErrorMgrI.error(NULL, AGILLA_ERROR_INVALID_FIELD_TYPE);
		return FAIL;
		}
	} else if (tempField->vtype == AGILLA_TYPE_STYPE) { // formal match, sensor type
		if (tupField->vtype == AGILLA_TYPE_READING) {
			if (tempField->rtype.stype == AGILLA_STYPE_ANY)	// the template matches ANY reading regardless of sensor type
			return SUCCESS;
			else
			//return tupField->reading.type == tempField->rtype.stype; // template matches a particular type of sensor reading
			if(tupField->reading.type == tempField->rtype.stype) return SUCCESS;
			else return FAIL;
		}
	}
	return FAIL;
	}
	
	/**
	 * Determines whether the two fields are identical.
	 */
	command error_t TupleUtilI.fEquals(AgillaVariable* field1, AgillaVariable* field2) {
	if (field1->vtype == field2->vtype) { // actual match
		switch(field1->vtype) {
		case AGILLA_TYPE_AGENTID:	 

		if(field1->id.id == field2->id.id) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_LOCATION:	
		//return field1->loc.x == field2->loc.x && field1->loc.y == field2->loc.y;	
		if(field1->loc.x == field2->loc.x && field1->loc.y == field2->loc.y) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_STRING:	
		//return field1->string.string == field2->string.string;
		if(field1->string.string == field2->string.string) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_READING:	 
		//return field1->reading.type == field2->reading.type &&
				 //field1->reading.reading == field2->reading.reading;
		if(field1->reading.type == field2->reading.type && field1->reading.reading == field2->reading.reading) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_VALUE:	 
		//return field1->value.value == field2->value.value;
		if(field1->value.value == field2->value.value) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_TYPE:
		//return field1->type.type == field2->type.type;
		if(field1->type.type == field2->type.type) return SUCCESS;
		else return FAIL;
		case AGILLA_TYPE_STYPE:
		//return field1->rtype.stype == field2->rtype.stype;
		if(field1->rtype.stype == field2->rtype.stype) return SUCCESS;
		else return FAIL;
		default:
		dbg("DBG_USR1", "ERROR: TupleUtilM.fEquals: Invalid field1 type %i.\n", field1->vtype);		
		call ErrorMgrI.errord(NULL, AGILLA_ERROR_INVALID_FIELD_TYPE, field1->vtype);
		return FAIL;
		} // switch
	} else
		return FAIL;
	}

	/**
	 * Returns SUCCESS if the template matches the tuple, FAIL otherwise.
	 * If isRemove is TRUE, it bypasses system tuples and checks that the
	 * owner is a match.
	 */
	command error_t TupleUtilI.tMatches(AgillaTuple* template, AgillaTuple* tuple, bool isRemove) {
	AgillaVariable tempField, tupField;
	int i;

	#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilM.tMatches: Start method...\n");	
	#endif	


	if (template->size != tuple->size) {
		#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilM.tMatches: No match, unequal sizes (%i, %i)\n", template->size, tuple->size);	
		#endif	
		return FAIL;
	}
	
	if (isRemove && ((tuple->flags & AGILLA_TUPLE_SYSTEM) && 
		!(template->flags & AGILLA_TUPLE_SYSTEM))) 
	{
		#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilM.tMatches: No match, cannot remove system tuple\n");	
		#endif		
		return FAIL;			
	}
	
	// check that each template field matches the tuple field
	for (i = 0; i < template->size; i++) {

		#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilM.tMatches: Comparing field %i...\n", i);	
		#endif	
	
		if (call TupleUtilI.getField(template, i, &tempField) == SUCCESS && 
			call TupleUtilI.getField(tuple, i, &tupField) == SUCCESS)
		{
		if (call TupleUtilI.fMatches(&tempField, &tupField) != SUCCESS) {
			#if DEBUG_TUPLE_UTIL
			dbg("DBG_USR1", "TupleUtilM.tMatches: No match, field %i does not match:\n", i);	
			call TupleUtilI.printField(&tempField);
			call TupleUtilI.printField(&tupField);
			#endif		
			return FAIL;		
		}
		} else
		return FAIL;
	}
	return SUCCESS;
	}

	/**
	 * Returns SUCCESS if the two tuples are equal, FALSE otherwise.
	 */	
	command error_t TupleUtilI.isEqual(AgillaTuple* tuple1, AgillaTuple* tuple2) {
	AgillaVariable tup1Field, tup2Field;
	int i;
	
	if (tuple1->flags != tuple2->flags) return FAIL;	// flags must match
	if (tuple1->size != tuple2->size)	 return FAIL;	// size must match
	 
	for (i = 0; i < tuple1->size; i++) {
		if (call TupleUtilI.getField(tuple1, i, &tup1Field) == SUCCESS &&
		call TupleUtilI.getField(tuple2, i,	&tup2Field) == SUCCESS)
		{
		if (call TupleUtilI.fEquals(&tup1Field, &tup2Field) != SUCCESS) return FAIL;
		} else
		return FAIL;
	}
	return SUCCESS;
	}
	
	/**
	 * Removes a tuple from the operand stack and saves it in the 
	 * specified tuple pointer.
	 *
	 * @param context The context containing the operand stack with the tuple.
	 * @param tuple The tuple to store the results in.	 
	 */	
	command error_t TupleUtilI.getTuple(AgillaAgentContext* context, AgillaTuple* tuple) {
	uint16_t i, size;
	int pos = 0;
	AgillaVariable field;	 

	#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilI.getTuple(): Getting a tuple from agent %i\n", context->id.id);
	#endif

	if(call OpStackI.popOperand(context, &field) == SUCCESS) {
	
		// Get the number of fields
		if (!(field.vtype & AGILLA_VAR_V)) {
		dbg("DBG_USR1", "ERROR: TupleUtilI.getTuple: Invalid type for number of fields: type=%i.\n", (int)field.vtype);
		call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_FIELD_COUNT, field.vtype);
		return FAIL;
		} else
		size = field.value.value;
		
		#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilI.getTuple(): Tuple size = %i\n", size);
		#endif
	
		tuple->size = 0;
		tuple->flags = AGILLA_TUPLE_RESET;
		
		for (i = 0; i < size; i++) {
		
		//#if DEBUG_TUPLE_UTIL
			//dbg("DBG_USR1", "TupleUtilI.getTuple(): Getting field %i\n", i);
		//#endif		
		
		if (call OpStackI.popOperand(context, &field) == SUCCESS) {
		
			//#if DEBUG_TUPLE_UTIL
			//dbg("DBG_USR1", "TupleUtilI.getTuple(): Field %i has type %i\n", i, field.vtype);
			//#endif		
		
			pos = call TupleUtilI.addField(tuple, pos, &field);
			if (pos == -1) return FAIL;
		} else
			return FAIL;				
		}

		#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilI.getTuple(): The final tuple is: \n");
		call TupleUtilI.printTuple(tuple);		
		#endif		
	}
	return SUCCESS;
	}

	/**
	 * Returns SUCCESS if all of the fields in the tuple are one of the types specified.
	 */
	command error_t TupleUtilI.checkFieldTypes(AgillaAgentContext* context, 
	AgillaTuple* tuple, uint16_t type)
	{
	int i;
	AgillaVariable field;
	 
	for (i = 0; i < tuple->size; i++) {
		if (call TupleUtilI.getField(tuple, i, &field) == SUCCESS) {
		if (!(field.vtype & type)) {
			call ErrorMgrI.error2d(context, AGILLA_ERROR_ILLEGAL_FIELD_TYPE, i, field.vtype);		
			return FAIL;
		}
		}
	}
	return SUCCESS;
	}

	/**
	 * Pushes a tuple onto the operand stack of the specified agent.
	 */
	command error_t TupleUtilI.pushTuple(AgillaTuple* tuple, AgillaAgentContext* context) {
	int i;
	AgillaVariable field;
	uint16_t tupleSize = call TupleUtilI.sizeOf(tuple);

	if (tuple->size == 0 || tupleSize > AGILLA_MAX_TUPLE_SIZE+2) {		
		call ErrorMgrI.error2d(context, AGILLA_ERROR_TUPLE_SIZE, tupleSize, 3);
		return FAIL;
	}

	for (i = tuple->size-1; i >= 0; i--) {
		if (call TupleUtilI.getField(tuple, i, &field) == SUCCESS) {
		call OpStackI.pushOperand(context, &field);		
		} else
		return FAIL;
	}
	return call OpStackI.pushValue(context, (int16_t)tuple->size);
	}
	
	/**
	 * Prints a textual representation of a field.
	 * 
	 * @param field The field to print.
	 */	
	command error_t TupleUtilI.printField(AgillaVariable* field) {
	switch(field->vtype) {
	case AGILLA_TYPE_VALUE:
		dbg("DBG_USR1", "\t\t\tFIELD: Value = %i (0x%x)\n", field->value.value & 0xFFFF, field->value.value & 0xFFFF);
		break;
	case AGILLA_TYPE_READING:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading, sensor = %i, data = %i\n", field->reading.type, field->reading.reading);
		break;
	case AGILLA_TYPE_STRING:
		dbg("DBG_USR1", "\t\t\tFIELD: String = %i (0x%x)\n", field->string.string, field->string.string);
		break;
	case AGILLA_TYPE_TYPE:
		switch(field->type.type) {
		case AGILLA_TYPE_INVALID:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = INVALID\n");
		break;
		case AGILLA_TYPE_VALUE:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = VALUE\n");
		break;		
		case AGILLA_TYPE_READING:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = READING\n");
		break;		
		case AGILLA_TYPE_STRING:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = STRING\n");
		break;		
		case AGILLA_TYPE_TYPE:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = TYPE\n");
		break;		
		case AGILLA_TYPE_STYPE:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = STYPE\n");
		break;		
		case AGILLA_TYPE_AGENTID:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = AGENTID\n");
		break;		
		case AGILLA_TYPE_LOCATION:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = LOCATION\n");
		break;		
		case AGILLA_TYPE_ANY:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = ANY\n");
		break;	 
		default:
		dbg("DBG_USR1", "\t\t\tFIELD: Type = UNKNOWN\n");
		}
		break;
	case AGILLA_TYPE_STYPE:
		switch(field->rtype.stype) {
		case AGILLA_STYPE_ANY:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = ANY or BEEP\n");
		break;
		case AGILLA_STYPE_PHOTO:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = PHOTO\n");
		break;
		case AGILLA_STYPE_TEMP:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = TEMP\n");
		break;
		case AGILLA_STYPE_MIC:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = MIC\n");
		break;
		case AGILLA_STYPE_MAGX:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = MAGX\n");
		break;
		case AGILLA_STYPE_MAGY:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = MAGY\n");
		break;
		case AGILLA_STYPE_ACCELX:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = ACCELX\n");
		break;
		case AGILLA_STYPE_ACCELY:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = ACCELY\n");
		break;
		default:
		dbg("DBG_USR1", "\t\t\tFIELD: Reading Type = UNKOWN\n");
		}		
		break;
	case AGILLA_TYPE_AGENTID:
		dbg("DBG_USR1", "\t\t\tFIELD: AgentID = %i\n", field->id.id);
		break;
	case AGILLA_TYPE_LOCATION:
		dbg("DBG_USR1", "\t\t\tFIELD: Location(%i,%i)\n", field->loc.x, field->loc.y);
		break;
	default:
	 dbg("DBG_USR1", "\t\t\tFIELD: ERROR: Unknown field type: %i\n", field->type);
	}
	return SUCCESS;
	}

	/**
	 * Prints a textual representation of a tuple.
	 *
	 * @param tuple The tuple to print.
	 */	
	command error_t TupleUtilI.printTuple(AgillaTuple* tuple)
	{
	int i;
	AgillaVariable field;
	
	dbg("DBG_USR1", "\t\tTUPLE:\n");
	dbg("DBG_USR1", "\t\t\tflags = 0x%x\n", tuple->flags);
	dbg("DBG_USR1", "\t\t\tsize = %i\n", tuple->size);

	for (i = 0; i < tuple->size; i++) 
	{
		if (call TupleUtilI.getField(tuple, i, &field) == SUCCESS)
		call TupleUtilI.printField(&field);
		else
		return FAIL;
	}
	return SUCCESS;
	} 
	
	/**
	 * Creates a HostID tuple.
	 *
	 * @param tuple A pointer to the tuple to modify.
	 */
	command error_t TupleUtilI.createHostIDTuple(AgillaTuple* tuple) {
	AgillaVariable field1, field2;
	int i = 0;		
	
	#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilI.createHostIDTuple(): Creating a HostID tuple...\n");
	#endif	
	
	clearTuple(tuple);
	field1.vtype = AGILLA_TYPE_STRING;
	field1.string.string = AGILLA_TUPLE_STRING_HOST;
	field2.vtype = AGILLA_TYPE_VALUE;
	field2.value.value = TOS_NODE_ID;
	
	tuple->flags = AGILLA_TUPLE_SYSTEM;		
	i = call TupleUtilI.addField(tuple, i, &field1);
	i = call TupleUtilI.addField(tuple, i, &field2);
	return SUCCESS;
	}	
	
	/**
	 * Creates an AgentID tuple.
	 *
	 * @param tuple A pointer to the tuple to modify.
	 */	
	command error_t TupleUtilI.createAgentIDTuple(AgillaTuple* tuple, AgillaAgentID id) {
	AgillaVariable field1, field2;
	int i = 0;	
	
	#if DEBUG_TUPLE_UTIL
		dbg("DBG_USR1", "TupleUtilI.createHostIDTuple(): Creating an AgentID tuple...\n");
	#endif	
	
	clearTuple(tuple);
	field1.vtype = AGILLA_TYPE_STRING;
	field1.string.string = AGILLA_TUPLE_STRING_AGENT;	
	field2.vtype = AGILLA_TYPE_AGENTID;
	field2.id = id;
	tuple->flags =	AGILLA_TUPLE_SYSTEM;
	i = call TupleUtilI.addField(tuple, i, &field1);
	i = call TupleUtilI.addField(tuple, i, &field2);
	return SUCCESS;
	}
	
	//event error_t SendMsg.sendDone(TOS_MsgPtr M, error_t success) { return SUCCESS;}	// debug
}
