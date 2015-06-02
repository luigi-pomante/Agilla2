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
		interface Leds;
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
		call Leds.set(0); /* shut down the tutti i led */

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
		call Leds.led1On(); /* light up the GREEN LED */
		atomic { call mic.read( SAMPLERATE ); }

		return SUCCESS;
	}


	task void PushResult()
	{
		call OpStackI.pushValue( saved_context, resultDips );

		call AgentMgrI.run(saved_context);
		saved_context = NULL;

		call Leds.led2On(); /* light up the YELLOW LED */

		while( call QueueI.empty(&waitQueue) == FALSE )
		{
			call AgentMgrI.run(call QueueI.dequeue(NULL, &waitQueue));
		}

		call Leds.led2Off(); /* shut down the YELLOW LED */
	}


	uint16_t isThereHumanVoice()
	{
		return 31; // test value
	}


	event void mic.readDone( error_t result, uint32_t usActualPeriod )
	{
		call Leds.led1Off(); /* shut down the GREEN LED */
		if( result == SUCCESS )
		{
			call Leds.led0On(); /* light up the RED LED */
			resultDips = isThereHumanVoice();
			if( post PushResult() == SUCCESS )
				call Leds.led0Off(); /* shut down the RED LED */
		}
	}


	event void mic.bufferDone(error_t result, uint16_t* buf, uint16_t count)
	{
		call Leds.set(7);
	}
}

