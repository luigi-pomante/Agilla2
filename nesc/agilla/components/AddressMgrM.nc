// $Id: AddressMgrM.nc,v 1.10 2006/04/27 23:53:18 chien-liang Exp $

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
#include "Timer.h"

/**
 * Manages address information, e.g., determines if a mote is a base
 * station and what the mote's original address is.
 *
 * @author Chien-Liang Fok <liangfok@wustl.edu>
 */
module AddressMgrM {
	provides {
	//interface StdControl;
	interface Init;
	interface AddressMgrI;
	}
	uses {
	interface Receive as ReceiveSetBSMsg;
	interface Receive as SerialReceiveSetBSMsg;
	interface Timer<TMilli> as BSTimer; // for base station heartbeat
	
	interface Receive as ReceiveAddress;
	interface AMSend as SendAddress;
	interface Receive as ReceiveAddressAck;
	interface AMSend as SendAddressAck;
	interface AMSend as SerialSendAddressAck;
	interface Receive as SerialReceiveAddressAck;
	interface Receive as SerialReceiveAddress;
	interface Packet;
	interface Boot;
	
	interface LEDBlinkerI;
	}
}

// This is the period of the base station timer.	If a heartbeat
// is not received in two periods, the mote assumes it is no longer
// the base station.
#define BS_TIMEOUT 7000

implementation {	
	/**
	 * Remembers the original address of this node.
	 */
	uint16_t origAddr;
	
	/**
	 * Whether this node is a base station.
	 */
	bool isGW;
	
	/**
	 * A message buffer for sending address acknowledgements.
	 */
	message_t msg;
	
	/**
	 * Whether this mote has received a base station heartbeat.
	 */
	bool recvBS;
	
	command error_t Init.init() 
	{
	origAddr = TOS_NODE_ID;
	recvBS = isGW = FALSE;	 
	return SUCCESS;
	}
	
	event void Boot.booted() {
	call BSTimer.startPeriodic(BS_TIMEOUT);
	}

 /* command error_t StdControl.start() //Non li utilizziamo
	{
	return SUCCESS;
	}
	
	command error_t StdControl.stop() //Non li utilizziamo
	{
	return SUCCESS;
	} */
	
	/**
	 * Checks whether this mote has received a base station heartbeat
	 * in the past BSTimer period.	If not, set this mote to be a 
	 * non-basestation.
	 */
	event void BSTimer.fired() 
	{
	if (recvBS)
		recvBS = FALSE;
	else if (isGW) 
	{
		#if DEBUG_ADDRESS_MGR
		dbg("DBG_USR1", "AddressMgrM: isGW = FALSE.\n");
		#endif
		isGW = FALSE;
	}	
	
	}
	
	/**
	 * Returns TRUE if this mote is a base station.	In TOSSIM,
	 * the base station is always mote 0.	Since TOSSIM is not 
	 * real-time, the mote 0 is hard-coded to be the base station
	 * when running in simulation mode.
	 */
	command error_t AddressMgrI.isGW() 
	{
// #ifdef PACKET_SIM_H_INCLUDED
// return TOS_NODE_ID == 0;
// #else	
		if(isGW) return SUCCESS;
		else return FAIL;
// #endif
	}
	
	/**
	 * Returns TRUE if the specified address is the one
	 * that this mote was programmed as.
	 */	
	command error_t AddressMgrI.isOrigAddress(uint16_t addr) {

	if(addr == origAddr) return SUCCESS;
	else return FAIL;
	}
	
	/**
	 * The base station periodically sends the gateway mote a heartbeat
	 * informing it that it is a gateway.
	 */
	event message_t* ReceiveSetBSMsg.receive(message_t* m, void* payload, uint8_t len) {	
	isGW = TRUE;
	recvBS = TRUE; 
	#if DEBUG_ADDRESS_MGR
		dbg("DBG_USR1", "AddressMgrM: isGW = TRUE.\n");
	#endif	
	return m;
	}

	//RECEIVE SERIAL
	event message_t* SerialReceiveSetBSMsg.receive(message_t* m, void* payload, uint8_t len) {	
	isGW = TRUE;
	recvBS = TRUE; 
	#if DEBUG_ADDRESS_MGR
		dbg("DBG_USR1", "AddressMgrM: isGW = TRUE.\n");
	#endif	
	return m;
	}
	
	/**
	 * This method allows a user to change the address of a mote.
	 */
	event message_t* ReceiveAddress.receive(message_t* m, void* payload, uint8_t len) {
	AgillaAddressMsg* addrMsg = (AgillaAddressMsg*)payload;

	// If the address change message is destined for me, change my address
	if (addrMsg->oldAddr == origAddr) {		
		AgillaAddressAckMsg* addrAckMsg = (AgillaAddressAckMsg*)(call Packet.getPayload(&msg, sizeof(AgillaAddressAckMsg)));
		addrAckMsg->success = 1;
		addrAckMsg->oldAddr = origAddr;
		addrAckMsg->newAddr = addrMsg->newAddr;
		
		#if DEBUG_ADDRESS_MGR
		dbg("DBG_USR1", "AddressMgrM: Changing address of mote %i to %i.\n", 
			TOS_NODE_ID, addrMsg->newAddr);
		#endif
		
		atomic {
		TOS_NODE_ID = addrMsg->newAddr;
		}
			
		// Send an acknowledgement
		if (isGW)
		call SerialSendAddressAck.send(AM_UART_ADDR, &msg, sizeof(AgillaAddressAckMsg));	//UART DA FARE
		else
		call SendAddressAck.send(AM_BROADCAST_ADDR, &msg, sizeof(AgillaAddressAckMsg));
		
		// Blink the LEDs to acknowledge the change in address
		call LEDBlinkerI.blink((uint8_t)GREEN|YELLOW, 3, 128);	//DA FARE
	}
	
	// Otherwise, if I am the base station, send it to the appropriate mote
	// (This assumes all motes are in reality a single hop away)
	else if (addrMsg->fromPC && isGW) { 
		addrMsg->fromPC = 0;
		msg = *m;		
		call SendAddress.send(AM_BROADCAST_ADDR, &msg, sizeof(AgillaAddressMsg));			
	}
	
	return m;
	}

	//RECEIVE SERIAL
	event message_t* SerialReceiveAddress.receive(message_t* m, void* payload, uint8_t len) {
	AgillaAddressMsg* addrMsg = (AgillaAddressMsg*)payload;

	// If the address change message is destined for me, change my address
	if (addrMsg->oldAddr == origAddr) {		
		AgillaAddressAckMsg* addrAckMsg = (AgillaAddressAckMsg*)(call Packet.getPayload(&msg, sizeof(AgillaAddressAckMsg)));
		addrAckMsg->success = 1;
		addrAckMsg->oldAddr = origAddr;
		addrAckMsg->newAddr = addrMsg->newAddr;
		
		#if DEBUG_ADDRESS_MGR
		dbg("DBG_USR1", "AddressMgrM: Changing address of mote %i to %i.\n", 
			TOS_NODE_ID, addrMsg->newAddr);
		#endif
		
		atomic {
		TOS_NODE_ID = addrMsg->newAddr;
		}
			
		// Send an acknowledgement
		if (isGW)
		call SerialSendAddressAck.send(AM_UART_ADDR, &msg, sizeof(AgillaAddressAckMsg));	//UART DA FARE
		else
		call SendAddressAck.send(AM_BROADCAST_ADDR, &msg, sizeof(AgillaAddressAckMsg));
		
		// Blink the LEDs to acknowledge the change in address
		call LEDBlinkerI.blink((uint8_t)GREEN|YELLOW, 3, 128);	//DA FARE
	}
	
	// Otherwise, if I am the base station, send it to the appropriate mote
	// (This assumes all motes are in reality a single hop away)
	else if (addrMsg->fromPC && isGW) { 
		addrMsg->fromPC = 0;
		msg = *m;		
		call SendAddress.send(AM_BROADCAST_ADDR, &msg, sizeof(AgillaAddressMsg));			
	}
	
	return m;
	}	
	
	/**
	 * Signalled when the blinking is done and blink(...) can be called again.
	 */
	event error_t LEDBlinkerI.blinkDone() {
	return SUCCESS;
	}	

	/**
	 * Relays the address ack message over the UART if this node is a base station.
	 */
	event message_t* ReceiveAddressAck.receive(message_t* m, void* payload, uint8_t len) {
	if (isGW) {
		msg = *m;
		call SerialSendAddressAck.send(AM_UART_ADDR, &msg, sizeof(AgillaAddressAckMsg)); //DA FARE UART
	}
	return m;
	}	

	//RECEIVE SERIAL
	event message_t* SerialReceiveAddressAck.receive(message_t* m, void* payload, uint8_t len) {
	if (isGW) {
		msg = *m;
		call SerialSendAddressAck.send(AM_UART_ADDR, &msg, sizeof(AgillaAddressAckMsg)); //DA FARE UART
	}
	return m;
	} 

	event void SendAddressAck.sendDone(message_t* m, error_t success) {
	//return SUCCESS;
	}	 

	event void SendAddress.sendDone(message_t* m, error_t success) {
	//return SUCCESS;
	}
	
	event void SerialSendAddressAck.sendDone(message_t* m, error_t success) {
	//return SUCCESS;
	}		
}
