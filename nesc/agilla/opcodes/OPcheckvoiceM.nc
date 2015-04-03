#include "Agilla.h"


#define SAMPLERATE 125
#define NUM_OF_SAMPLES 90


module OPcheckvoiceM
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
		interface ErrorMgrI as Error;
		interface ReadStream<uint16_t> as mic;
	}
}


implementation
{
	Queue waitQueue;
	AgillaAgentContext* saved_context;
	uint16_t resultDips;
	uint16_t samples[ NUM_OF_SAMPLES ];
	uint16_t amdt[ NUM_OF_SAMPLES/2 ];


	command error_t Init.init()
	{
		call QueueI.init(&waitQueue);
		return SUCCESS;
	}


	command error_t BytecodeI.execute( uint8_t instr, AgillaAgentContext* context )
	{
		context->state = AGILLA_STATE_WAITING;
		resultDips = 0;
		if( saved_context != NULL)
		{
			context->pc--;
			call QueueI.enqueue(context, &waitQueue, context);
			return SUCCESS;
		}

		saved_context = context;

		call mic.postBuffer( samples, sizeof(uint16_t)*NUM_OF_SAMPLES );
		atomic { call mic.read( SAMPLERATE ); }

		return SUCCESS;
	}


	task void PushResult()
	{
		call OpStackI.pushValue( saved_context, resultDips );

		while( SUCCESS!=call AgentMgrI.run( saved_context ) );

		saved_context = NULL;
		while( ! call QueueI.empty(&waitQueue) )
			call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));
	}


	inline error_t saveData(uint16_t data)
	{
		resultDips = data;
		if( post PushResult() == SUCCESS )
			return SUCCESS;
		else
			return FAIL;
	}

	
	inline uint16_t isThereHumanVoice()
	{
		return 31; // test value
	}


	event void mic.readDone( error_t result, uint32_t usActualPeriod )
	{
		if( result == SUCCESS )
			saveData( isThereHumanVoice() );
	}


	event void mic.bufferDone(error_t result, uint16_t* buf, uint16_t count)
	{

	}
}

