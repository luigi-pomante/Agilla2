#include "Agilla.h"
#include "MorseCodes.h"

#define MAX_NAME_LENGTH 2

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
		interface BusyWait<TMicro,uint16_t> as BW;
#ifdef MORSE_LED_TEST
		interface Leds;
#endif
	}
}


implementation
{
	Queue waitqueue;
	AgillaAgentContext *saved_context;


	command error_t Init.init()
	{
		call QueueI.init( &waitqueue );
		return SUCCESS;
	}

	void SingleBlink( uint8_t bit )
	{
		uint16_t symdelay;

		bit &= 1; // select only the LSB
		if( bit == 1 )
		{
			symdelay = DASH_MSEC;
			#ifdef MORSE_LED_TEST
			call Leds.set( 1 );
			#endif
		}
		else
		{
			symdelay = DOT_MSEC;
			#ifdef MORSE_LED_TEST
			call Leds.set( 2 );
			#endif
		}

		//TODO: on
		call BW.wait( symdelay );
		//TODO: off

		// in-symbol delay
		call BW.wait( DOT_MSEC );
		#ifdef MORSE_LED_TEST
		call Leds.set( 0 );
		#endif
	}


	void SymbolBlink( uint8_t sym )
	{
		int currentBitIndex;
		int i;
		AgillaMorseCode *ptr = NULL;

		for( i=0; i<NUMOFMORSECODES; i++ )
		{
			if( MorseCodes[i].ascii == sym )
			{
				ptr = &MorseCodes[i];
				break;
			}
		}
		if( ptr != NULL )
		{
			for( currentBitIndex = ptr->size-1; currentBitIndex>=0; currentBitIndex-- )
				SingleBlink( (ptr->code >> currentBitIndex)&1 );
			call BW.wait( LETTER_SEPARATOR );
		}
	}


	void StringBlink( uint8_t *word, size_t wordsize )
	{
		int i;

		for( i=0; i<wordsize; i++ )
		{
			SymbolBlink( word[i] );
		}
		call BW.wait( WORD_SEPARATOR );
	}


	command error_t BytecodeI.execute( uint8_t instr, AgillaAgentContext* context )
	{
		uint16_t arg_number = 0;
		uint8_t name[ MAX_NAME_LENGTH ];
		uint8_t *ptr;
		AgillaVariable n_arg;
		AgillaVariable name_arg;
		int i;


		context->state = AGILLA_STATE_WAITING;
		if( saved_context != NULL )
		{
			context->pc--;
			call QueueI.enqueue( context, &waitqueue, context );
			return SUCCESS;
		}
		saved_context = context;


		if( call OpStackI.popOperand(context, &n_arg) != SUCCESS ||
			call OpStackI.popOperand(context, &name_arg) != SUCCESS ||
			name_arg.vtype != AGILLA_TYPE_STRING ||
			n_arg.vtype != AGILLA_TYPE_VALUE )
		{
			return FAIL;
		}

		arg_number = n_arg.value.value;
		if( arg_number >= MAX_NAME_LENGTH )
			return FAIL;

		ptr = (uint8_t*) &( name_arg.string.string );

		// TODO: little or big endian?
		for( i=0; i<arg_number; i++ )
		{
			name[i] = ptr[i];
		};


		// TEST
		SingleBlink( 1 );
		SingleBlink( 0 );
		SingleBlink( 1 );


		// Real code:
		//StringBlink( name, arg_number );


		//TODO: simplify
		call AgentMgrI.run( saved_context );
		saved_context = NULL;
		while( ! call QueueI.empty( &waitqueue ) )
			call AgentMgrI.run( call QueueI.dequeue( NULL, &waitqueue ) );
		return SUCCESS;
	}
}
