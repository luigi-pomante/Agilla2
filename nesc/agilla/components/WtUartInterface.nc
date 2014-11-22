/*
	WtUartInterface
	Interface used by the timestamp-retrivial module

	Author: Walter Tiberti <wtuniv@gmail.com>
*/
#include "WtStructs.h"

interface WtUartInterface
{
	command error_t SendToSerial();
	command bool isQueueFull();
	command void InsertMessage( uint8_t instr, uint32_t ts );
	command uint16_t GetQueueSize();
	command void ClearQueue();
}
