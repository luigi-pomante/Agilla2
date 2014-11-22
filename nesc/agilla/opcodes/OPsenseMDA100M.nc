#include "Agilla.h"
#include "AgillaOpcodes.h"
#include "TupleSpace.h"

module OPsenseMDA100M
{
	provides interface BytecodeI;
	provides interface Init;
	
	uses
	{
		interface AgentMgrI;
		interface OpStackI;
		interface QueueI;
		interface ErrorMgrI;
		interface Read<uint16_t> as Photo;
		interface Read<uint16_t> as Temp;
	}
}

implementation
{
	Queue waitQueue;
	AgillaAgentContext* _context;
	norace AgillaReading reading;

	command error_t Init.init()
	{
		call QueueI.init(&waitQueue);
		return SUCCESS;
	}

	task void senseDone()
	{
		call OpStackI.pushReading(_context, reading.type, reading.reading);
		call AgentMgrI.run( _context );
		_context = NULL;
		while( ! call QueueI.empty(&waitQueue) )
		{
			call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));
		}
	}

	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context)
	{
		AgillaVariable arg;
		context->state = AGILLA_STATE_WAITING;
		if (_context != NULL)
		{
			context->pc--;
			call QueueI.enqueue(context, &waitQueue, context);
			return SUCCESS;
		}

		_context = context;

		if( call OpStackI.popOperand(context, &arg) == SUCCESS )
		{
			if (!(arg.vtype & AGILLA_TYPE_VALUE))
			{
				call ErrorMgrI.error(context, AGILLA_ERROR_INVALID_SENSOR);
				return FAIL;
			}

			reading.type = arg.value.value;

			switch(reading.type)
			{
				case AGILLA_STYPE_PHOTO:
					atomic { call Photo.read(); }
					break;
				case AGILLA_STYPE_TEMP:
					atomic { call Temp.read(); }
					break;
				default:
					call ErrorMgrI.errord(context, AGILLA_ERROR_INVALID_SENSOR, reading.type);
			}
			return SUCCESS;
		}
		return FAIL;
	}

	inline error_t saveData(uint16_t data)
	{
		reading.reading = data;
		if( post senseDone() == SUCCESS )
			return SUCCESS;
		else
			return FAIL;
	}

	event void Photo.readDone(error_t result, uint16_t data)
	{
		if (result == SUCCESS)
			saveData(data);
	}

	event void Temp.readDone(error_t result, uint16_t data)
	{
		if (result == SUCCESS)
			saveData(data);
	}
}

