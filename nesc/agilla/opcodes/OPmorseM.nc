#include "Agilla.h"
#include "MorseCodes.h"

#define MAX_NAME_LENGTH 2

module OPmorseM
{
	provides
	{
		interface BytecodeI;
	}

	uses
	{
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
	void SingleBlink( uint8_t bit )
	{
		uint16_t symdelay;

		bit &= 1; // select only the LSB
		if( bit == 1 )
			symdelay = DASH_MSEC;
		else
			symdelay = DOT_MSEC;
			

#ifdef MORSE_LED_TEST
		call Leds.set( 1 );
#else
		// TODO
#endif
		call BW.wait( DASH_MSEC );
#ifdef MORSE_LED_TEST
		call Leds.set( 0 );
#else
		// TODO
#endif

		// in-symbol delay
		call BW.wait( DOT_MSEC );
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
		AgillaVariable n_arg;
		AgillaVariable name_arg;
		int i;

		uint16_t arg_number = 0;
		uint8_t name[ MAX_NAME_LENGTH ];
		uint8_t *ptr;

		if( call OpStackI.popOperand(context, &name_arg) != SUCCESS ||
			call OpStackI.popOperand(context, &n_arg) != SUCCESS ||
			name_arg.vtype != AGILLA_TYPE_STRING ||
			n_arg.vtype != AGILLA_TYPE_VALUE )
		{
			return FAIL;
		}

		arg_number = n_arg.value.value;
		if( arg_number >= MAX_NAME_LENGTH )
			return FAIL;

		ptr = (uint8_t*) &( name_arg.string.string );
		// WARNING: little or big endian?
		for( i=0; i<arg_number; i++ )
		{
			name[i] = ptr[i];
		};

		StringBlink( name, arg_number );
		return SUCCESS;
	}
}
