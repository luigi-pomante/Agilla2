#include "Agilla.h"
#include "MorseCodes.h"

#define MAX_NAME_LENGTH 3

module OPmorseM
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
		interface GeneralIO;
		interface Timer<TMilli> as MainTimer;
#ifdef MORSE_LED_TEST
		interface Leds;
#endif
	}
}


implementation
{
	Queue waitqueue;
	AgillaAgentContext *saved_context;


	int k = 0;


	command error_t Init.init()
	{
		call QueueI.init( &waitqueue );
		call GeneralIO.makeOutput();
		call GeneralIO.clr();
		return SUCCESS;
	}

	event void MainTimer.fired()
	{
		call GeneralIO.toggle();
#ifdef MORSE_LED_TEST
		call Leds.set( k );
#endif
		k++;
		if( k > 50 )
			call MainTimer.stop();
	}

	command error_t BytecodeI.execute( uint8_t instr, AgillaAgentContext* context )
	{
		uint8_t *ptr;
		AgillaVariable name_arg;


		context->state = AGILLA_STATE_WAITING;
		if( saved_context != NULL )
		{
			context->pc--;
			call QueueI.enqueue( context, &waitqueue, context );
			return SUCCESS;
		}
		saved_context = context;

		if(	call OpStackI.popOperand(context, &name_arg) != SUCCESS ||
			name_arg.vtype != AGILLA_TYPE_STRING )
		{
			return FAIL;
		}

		ptr = (uint8_t*) &( name_arg.string.string );

		// Launch the main "clock"
		call MainTimer.startPeriodic( DOT_MSEC );

		//TODO: simplify
		call AgentMgrI.run( saved_context );
		saved_context = NULL;
		while( ! call QueueI.empty( &waitqueue ) )
			call AgentMgrI.run( call QueueI.dequeue( NULL, &waitqueue ) );
		return SUCCESS;
	}
}
