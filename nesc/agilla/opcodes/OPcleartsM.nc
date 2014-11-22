#include "Agilla.h"

module OPcleartsM
{
	provides
	{
		interface BytecodeI;
	}

	uses
	{
		interface TupleUtilI;
		interface ErrorMgrI as Error;
		interface TupleSpaceI;
	}
}


implementation
{
	command error_t BytecodeI.execute( uint8_t instr, AgillaAgentContext* context )
	{
		call TupleSpaceI.reset();
		return SUCCESS;
	}

	event error_t TupleSpaceI.newTuple(AgillaTuple* tuple) {
	return SUCCESS;
	}

	event error_t TupleSpaceI.byteShift(uint16_t from, uint16_t amount) {
	return SUCCESS;
	}
}

