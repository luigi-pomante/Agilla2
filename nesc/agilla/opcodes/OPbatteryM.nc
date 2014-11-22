#include "Agilla.h"

module OPbatteryM
{
	provides
	{
		interface BytecodeI;
		interface Init;
	}

	uses
	{
		interface AgentMgrI;
		interface QueueI;
		interface OpStackI;
		interface TupleUtilI;
		interface ErrorMgrI as Error;
		interface Read<uint16_t> as Voltage;
	}
}


implementation
{
	Queue waitQueue;
	norace uint8_t powerValue;
	AgillaAgentContext* saved_context;

	command error_t Init.init()
	{
		call QueueI.init(&waitQueue);
		return SUCCESS;
	}

	command error_t BytecodeI.execute( uint8_t instr, AgillaAgentContext* context )
	{
		context->state = AGILLA_STATE_WAITING;
		if( saved_context != NULL)
		{
			context->pc--;
			call QueueI.enqueue(context, &waitQueue, context);
			return SUCCESS;
		}

		saved_context = context;
		atomic { call Voltage.read(); }

		return SUCCESS;
	}

	task void PushResult()
	{
		call OpStackI.pushValue( saved_context, powerValue );
		call AgentMgrI.run( saved_context );
		saved_context = NULL;
		while( ! call QueueI.empty(&waitQueue) )
			call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));
	}

	inline error_t saveData(uint16_t data)
	{
		/*
		The original formula is:
			1100*1024/val
		However, using it, the reported voltage is ~0.360 V above the
		misured one. so....*/
		powerValue = (uint16_t) ((10*1100*1024)/data) - 36;
		// On IRIS mote, voltage seembs to be 100mV * powerValue

		if( post PushResult() == SUCCESS )
			return SUCCESS;
		else
			return FAIL;
	}


	event void Voltage.readDone( error_t e, uint16_t val )
	{
		if( e == SUCCESS )
		{
			saveData( val );
		}
	}
}

