/*
	Module for retriving the value of a free-running counter (timestamp)
	and send it to serial

	Author: Walter Tiberti <wtuniv@gmail.com>
*/

#include "AM.h"
#include "Serial.h"

#include "WtStructs.h"

module toUARTM
{
	provides
	{
		interface Init;
		interface Init as ProvideInit;
		interface WtUartInterface;
	}
	uses
	{
		interface Packet as SerialPacket;
		interface AMPacket as SerialAMPacket;
		interface AMSend as SerialSend;
		interface SplitControl as SerialControl;

		interface Timer<TMilli> as Timer;
	}
}

implementation
{
	TimestampMsg queue[ QUEUE_SIZE ];
	uint16_t queue_n;
	uint16_t cursor;
	bool filled;


	command error_t Init.init() { call SerialControl.start(); return SUCCESS; }
	command error_t ProvideInit.init() { return SUCCESS; }
	event void SerialControl.startDone( error_t error )
	{
		if( error == SUCCESS )
			call WtUartInterface.ClearQueue();
	}
	event void SerialControl.stopDone( error_t error ){}



	command bool WtUartInterface.isQueueFull()
	{
		return ( filled || queue_n >= QUEUE_SIZE );
	}



	command uint16_t WtUartInterface.GetQueueSize()
	{
		return queue_n;
	}
	


	command void WtUartInterface.InsertMessage( uint8_t instr, uint32_t ts )
	{
		queue[cursor].instr = instr;
		queue[cursor].ts = ts;
		queue_n++;
		cursor++;
		if( cursor >= QUEUE_SIZE )
			filled = TRUE;
	}



	command error_t WtUartInterface.SendToSerial()
	{
		if( call Timer.isRunning() )
			return FAIL;
		cursor = 0;
		if( queue_n == 0 )
			return SUCCESS;
		call Timer.startPeriodic( 10 );
		return SUCCESS;
	}



	event void Timer.fired()
	{
		message_t msg;
		TimestampMsg *temp;
		temp = (TimestampMsg*) call SerialPacket.getPayload( &msg, sizeof(TimestampMsg) );
		*temp = queue[cursor];
		if( call SerialSend.send( AM_BROADCAST_ADDR, &msg, sizeof(TimestampMsg) ) != EBUSY )
			cursor++;
		if( cursor >= QUEUE_SIZE || queue_n <= 0 )
			call Timer.stop();
	}



	event void SerialSend.sendDone( message_t *msg, error_t error )
	{
		if( error == SUCCESS )
			queue_n--;
	}



	command void WtUartInterface.ClearQueue()
	{
		int i;

		queue_n = 0;
		cursor = 0;
		filled = FALSE;
		for( i=0; i<QUEUE_SIZE; i++ )
		{
			queue[i].signature = 'W';
			queue[i].instr = 0;
			queue[i].ts = 0;
		}
	}
}
