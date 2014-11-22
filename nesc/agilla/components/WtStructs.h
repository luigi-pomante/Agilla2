/*
	Definition of the payload used in the timestamp retrivial module

	Author: Walter Tiberti <wtuniv@gmail.com>
*/
#ifndef WTSTRUCTS_H
	#define WTSTRUCTS_H

	#define QUEUE_SIZE 64

	typedef nx_struct _uartmsg
	{
		nx_uint8_t signature;
		nx_uint8_t instr;
		nx_uint32_t ts;
	} TimestampMsg;
#endif
