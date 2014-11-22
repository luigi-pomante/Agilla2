// $Id: ResetMgrM.nc,v 1.7 2006/04/07 01:14:37 borndigerati Exp $

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

#include "Agilla.h"

/**
 * Resets the mote when it receives a reset command from the
 * basestation.
 *
 * @author Chien-Liang Fok
 */
module ResetMgrM {
	provides {
	interface StdControl;
	interface Init;
	interface ResetMgrI;
	}
	uses {
	interface Reset;
	
	interface AgentMgrI;
	interface TupleSpaceI;
	interface AddressMgrI;
	interface LEDBlinkerI;
	interface ErrorMgrI;
	interface Receive as ReceiveReset;
	interface AMSend as SendReset;
	interface Receive as SerialReceiveReset;
	interface MessageBufferI;

	interface Leds;
	#if ENABLE_CLUSTERING
	interface ClusterheadDirectoryI as CHDir;
	#endif


	#if ENABLE_EXP_LOGGING
		interface ExpLoggerI;
	#endif

	}
}
implementation {
	/**
	 * Remembers whether the mote is resetting, used to ensure
	 * each mote only sends out one reset message while resetting.
	 */
	bool resetting;

	/**
	 * Remembers whether the mote is waiting for a reset operation
	 * to complete.	This is used to prevent continuous reset message
	 * flooding when only a single mote in the network needs to be reset.
	 */
	bool waiting;

	command error_t Init.init()
	{
	resetting = waiting = FALSE;
	//call Leds.init();
	return SUCCESS;
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
	 * When the first reset message is received, re-broadcast it then
	 * set a reset timer.	When the reset timer fires, reset the mote.
	 * After re-broadcasting the reset message, and before the reset
	 * timer fires, ignore all other reset messages.
	 */
	event message_t* ReceiveReset.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaResetMsg* rmsg = (AgillaResetMsg*)payload;

	// Reset this mote only.
	if (call AddressMgrI.isOrigAddress(rmsg->address) == SUCCESS)
	{
		if (!resetting)
		{
		resetting = TRUE;
		call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
		}
	}

	// Reset all motes.	Re-broadcast the reset message before resetting.
	else if (rmsg->address == AM_BROADCAST_ADDR)
	{
		if (!resetting)	// only re-broadcast once (prevents recursive flooding)
		{
		message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
			resetting = TRUE;
			rmsg->from = TOS_NODE_ID;
			*msg = *m;
			if (call SendReset.send(AM_BROADCAST_ADDR, msg, sizeof(AgillaResetMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
		}
		}
	}

	// Reset a specific mote.	Get the neighbor closest to the destination
	// and send it to it
	else {
		if (!waiting) // only re-broadcast once
		{
		message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
			waiting = TRUE;
			rmsg->from = TOS_NODE_ID;
			*msg = *m;
			if (call SendReset.send(AM_BROADCAST_ADDR, msg, sizeof(AgillaResetMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
		}
		}
	}
	return m;
	} // ReceiveReset.receive()
	
	event message_t* SerialReceiveReset.receive(message_t* m, void* payload, uint8_t len)
	{
	AgillaResetMsg* rmsg = (AgillaResetMsg*)payload;

	// Reset this mote only.
	if (call AddressMgrI.isOrigAddress(rmsg->address) == SUCCESS)
	{
		if (!resetting)
		{
		resetting = TRUE;
		call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
		}
	}

	// Reset all motes.	Re-broadcast the reset message before resetting.
	else if (rmsg->address == AM_BROADCAST_ADDR)
	{
		if (!resetting)	// only re-broadcast once (prevents recursive flooding)
		{
		message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
			resetting = TRUE;
			rmsg->from = TOS_NODE_ID;
			*msg = *m;
			if (call SendReset.send(AM_BROADCAST_ADDR, msg, sizeof(AgillaResetMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
		}
		}
	}

	// Reset a specific mote.	Get the neighbor closest to the destination
	// and send it to it
	else {
		if (!waiting) // only re-broadcast once
		{
		message_t* msg = call MessageBufferI.getMsg();
		if (msg != NULL)
		{
			waiting = TRUE;
			rmsg->from = TOS_NODE_ID;
			*msg = *m;
			if (call SendReset.send(AM_BROADCAST_ADDR, msg, sizeof(AgillaResetMsg)) != SUCCESS)
			call MessageBufferI.freeMsg(msg);
			call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
		}
		}
	}
	return m;
	} // SerialReceiveReset.receive()

	/**
	 * Signalled when the blinking is done and blink(...) can be called again.
	 */
	event error_t LEDBlinkerI.blinkDone()
	{
	if (waiting)
		waiting = FALSE;
	else if (resetting)
	{
		dbg("DBG_USR1", "ResetMgrM: Resetting...\n");
		call Reset.reset();
		
		call AgentMgrI.resetAll();
		call TupleSpaceI.reset();
		call ErrorMgrI.reset();
		call Leds.led0Off();
		call Leds.led2Off();
		call Leds.led1Off();

		#if ENABLE_EXP_LOGGING
		call ExpLoggerI.reset();
		#endif

		resetting = FALSE;
		#if ENABLE_CLUSTERING
		call CHDir.reset();
		#endif
	}
	return SUCCESS;
	}

	event void SendReset.sendDone(message_t* m, error_t success)
	{
	call MessageBufferI.freeMsg(m);
	//return SUCCESS;
	}

	/**
	 * Returns true if the mote is in the process or resetting.
	 */
	command error_t ResetMgrI.isResetting() {

	if(resetting) return SUCCESS;
	else return FAIL;
	}

	event error_t TupleSpaceI.newTuple(AgillaTuple* tuple) {
	return SUCCESS;
	}

	event error_t TupleSpaceI.byteShift(uint16_t from, uint16_t amount) {
	return SUCCESS;
	}
}
