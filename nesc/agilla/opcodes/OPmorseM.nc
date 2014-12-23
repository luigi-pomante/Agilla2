#include "Agilla.h"
#include "MorseCodes.h"

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

	unsigned char *ptr;
	char string_buffer[ 3 ];
	uint8_t index;
	uint8_t sym_index;

	uint8_t delay;
	uint8_t pause;

	uint8_t endstring;


	command error_t Init.init()
	{
		call QueueI.init( &waitqueue );
		call GeneralIO.makeOutput();
		call GeneralIO.clr();
		index = 0;
		sym_index = 0;
		delay = 0;
		pause = 0;
		endstring = 0;
		return SUCCESS;
	}


	AgillaMorseCode *getCode( char c )
	{
		int i;
		for( i=0; i<NUMOFMORSECODES; i++ )
		{
			if( MorseCodes[i].ascii == c )
				return &MorseCodes[i];
		}
		return NULL;
	}


	event void MainTimer.fired()
	{
		AgillaMorseCode *current;
		

		if( delay > 0 )
		{
			delay--;
			return;
		}

		if( pause > 0 )
		{
			#ifdef MORSE_LED_TEST
			call Leds.set(0);
			#endif
			call GeneralIO.clr();
			pause --;
			return;
		}

		if( endstring == 1 )
		{
			endstring = 0;
			#ifdef MORSE_LED_TEST
			call Leds.set(0);
			#endif
			call GeneralIO.clr();
			call MainTimer.stop();
			return;
		}

		if( current == NULL )
			current = getCode( string_buffer[index] );
		if( current == NULL )
		{
			call Error.error( saved_context, 8 );
			call MainTimer.stop();
			return;
		}

		switch( current->code[sym_index] )
		{
			case '.':
				delay = 1;
				#ifdef MORSE_LED_TEST
				call Leds.set(1);
				#endif
				break;
			case '-':
				delay = 3;
				#ifdef MORSE_LED_TEST
				call Leds.set(2);
				#endif
				break;
			default:
				call Error.error( saved_context, 8 );
				call MainTimer.stop();
				break;
		}

		call GeneralIO.set();
		pause = 1; // post-symbol pause
		sym_index++;

		if( sym_index >= current->size )
		{
			// end of char
			pause += 2;
			sym_index = 0;

			index++;

			if( index > 2 )
			{
				// end of string
				pause += 2;
				index = 0;
				endstring = 1;
			}
		}

	}

	command error_t BytecodeI.execute( uint8_t instr, AgillaAgentContext* context )
	{
		AgillaVariable name_arg;


		context->state = AGILLA_STATE_WAITING;
		if( saved_context != NULL )
		{
			context->pc--;
			call QueueI.enqueue( context, &waitqueue, context );
			return SUCCESS;
		}
		saved_context = context;

		if(	call OpStackI.popOperand(context, &name_arg) != SUCCESS )
			return FAIL;
		if( name_arg.vtype != AGILLA_TYPE_STRING )
		{
			call Error.error( context, 8 );
			return FAIL;
		}

		//string_buffer[0] = (char) ((name_arg.string.string >> 8) & 0xFF);
		//tring_buffer[1] = (char) (name_arg.string.string & 0xFF);

		/*  In Agilla, the 3-char string is stored in a 16bit variable
			in a 5-5-6 pattern ( [a-z][a-z][a-z0-9] ).
		 	The char are also stored with a fixed number (eg. a=1...0=27...) */
		// First char
		string_buffer[0] = (char)( ((name_arg.string.string>>(5+6)) & 0x1F) + 0x60 );
		// Second char
		string_buffer[1] = (char)( ((name_arg.string.string>>6) & 0x1F) + 0x60 );
		// Third char
		string_buffer[2] = (char)( name_arg.string.string & 0x3F );
		if( string_buffer[2] >= 27 ) // number
			string_buffer[2] += 3;
		else
			string_buffer[2] += 0x60;

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
