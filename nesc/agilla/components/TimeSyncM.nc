// $Id: TimeSyncM.nc,v 1.4 2006/04/06 02:10:05 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis 
 * By Chien-Liang Fok.
 * 
 * Washington University states that Agilla is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * Agilla is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.	THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.	
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using Agilla. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */

#include "TimeSync.h"

/**
 * Wires up all of the components used for synchronizing the time.
 *
 * @author Chien-Liang Fok
 */
module TimeSyncM
{
	provides interface StdControl;
	provides interface Init;
	uses 
	{
	interface AddressMgrI;
	interface Time;
	interface TimeSet;
	interface MessageBufferI;
	interface Timer<TMilli>;

	interface Receive as ReceiveTime;
	interface AMSend as SerialSendTime;
	interface Receive as SerialReceiveTime;
	interface Leds;
	interface Boot;
	interface Packet;
	}
}
implementation 
{
	
	command error_t Init.init()
	{
	tos_time_t t;
	t.high32 = 0;
	t.low32 = 0;
	call TimeSet.set(t);

	return SUCCESS;
	}
	
	event void Boot.booted(){
	call Timer.startPeriodic(1024*10);
	}

	command error_t StdControl.start()
	{
	
	return SUCCESS;
	}
	
	command error_t StdControl.stop()
	{
	return SUCCESS;
	}
	
	/**
	 * Send the time to the base station.
	 */
	task void sendTime() 
	{
		message_t* msg = call MessageBufferI.getMsg();

		if (msg != NULL)
		{
			AgillaTimeSyncMsg *timeMsg = (AgillaTimeSyncMsg *)(call Packet.getPayload(msg, sizeof(AgillaTimeSyncMsg)));
			timeMsg->time = call Time.get();

			if (call SerialSendTime.send(AM_UART_ADDR, msg, sizeof(AgillaTimeSyncMsg)) != SUCCESS)
			{
				call MessageBufferI.freeMsg(msg);
			}
		}
	}
	
	event void Timer.fired()
	{
	if (call AddressMgrI.isGW() == SUCCESS)
	{
		#if DEBUG_TIMESYNC
		dbg("DBG_USR1", "TimeSyncM: Timer.fired(): Sending time sync message\n");
		#endif	
		post sendTime();		
	} else
	{
		#if DEBUG_TIMESYNC
		dbg("DBG_USR1", "TimeSyncM: Timer.fired(): NOT sending time sync message\n");
		#endif		
	}

	}
	
	event message_t* ReceiveTime.receive(message_t* m, void *payload, uint8_t len)
	{

	AgillaTimeSyncMsg *timeMsg = (AgillaTimeSyncMsg *)payload;
	call TimeSet.set(timeMsg->time);
	//call Leds.yellowToggle();
	return m;
	}
	
	event message_t* SerialReceiveTime.receive(message_t* m, void *payload, uint8_t len)
	{

	AgillaTimeSyncMsg *timeMsg = (AgillaTimeSyncMsg *)payload;
	call TimeSet.set(timeMsg->time);
	//call Leds.yellowToggle();
	return m;
	}
	
	event void SerialSendTime.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);

	}
}
