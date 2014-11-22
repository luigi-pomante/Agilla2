// $Id: LocationMgrM.nc,v 1.5 2005/12/19 16:22:38 chien-liang Exp $

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
#include "SpaceLocalizer.h"
#include "LEDBlinker.h"
#include "Timer.h"

/**
 * Implements a virtual grid topology through which mote addresses may be
 * mapped to specific location and vice-versa.	Also interfaces with the
 * components that interact with the Cricket motes to obtain physical 
 * location data.
 *
 * @author Chien-Liang Fok
 */
module LocationMgrM {
	provides {
	//interface StdControl;
	interface Init;
	interface LocationMgrI;
	}
	uses {
	// The following interfaces allow the grid size to change.
	//interface Timer as GridSizeTimer;
	interface Timer<TMilli> as GridSizeTimer;
	interface Receive as ReceiveGridSizeMsg;
	interface AMSend as SendGridSizeMsg;
	interface Receive as SerialReceiveGridSizeMsg;
	
	// Interfaces with the Cricket 2 Motes.
	#if ENABLE_SPACE_LOCALIZER && defined(PLATFORM_MICA2)	//non utilizzato
		interface SpaceLocalizerI;
		interface StdControl as RadioControl;
		interface CC1000Control;
		interface LEDBlinkerI;
		//interface Timer as MoveTimer;
	#endif
	
	interface Leds;
	}
}
implementation {
	/**
	 * This is the number of rows and columns.	It is initialized to
	 * DEFAULT_NUM_COLUMNS as defined within Makefile.Agilla.
	 * It can be changed by broadcasting an AgillaGridSizeMsg
	 */
	uint16_t numColumns;

	/**
	 * Keeps track of whether this mote is in the midst of changing
	 * grid sizes.
	 */
	bool changingGridSize;	
	
	/**
	 * A buffer for sending grid update messages.
	 */
	message_t msg;
	
	/**
	 * The number of times the LEDs blinked after the mote changed spaces.
	 */
	//uint8_t moveCount;
	
	command error_t Init.init() {
	numColumns = DEFAULT_NUM_COLUMNS;
	changingGridSize = FALSE;

	return SUCCESS;
	}

 /* command result_t StdControl.start() {
	return SUCCESS;
	}

	command result_t StdControl.stop()	{
	return SUCCESS;
	} */ 
	
	/**
	 * Converts an address to a location.
	 *
	 * @param addr The address.
	 * @param loc The location.
	 */
	command error_t LocationMgrI.getLocation(uint16_t addr, AgillaLocation* loc) {
	if (addr == AM_BROADCAST_ADDR) {
		loc->x = BCAST_X;
		loc->y = BCAST_Y;
	} 
	else if (addr == AM_UART_ADDR) {
		loc->x = UART_X;
		loc->y = UART_Y;
	} 
	else {
		//loc->x = (addr-1) % numColumns + 1;
		//loc->y = (addr - loc->x)/numColumns + 1;	 
		loc->x = (addr) % numColumns + 1;
		loc->y = (addr - loc->x + 1)/numColumns + 1;		 
	}
	return SUCCESS;
	}
	
	/**
	 * Converts a location to an address.
	 *
	 * @param loc The location to convert.
	 * @return The address of the node at that location.
	 */
	command uint16_t LocationMgrI.getAddress(AgillaLocation* loc) {	
	if (loc->x == UART_X && loc->y == UART_Y)				 
		return AM_UART_ADDR;
	else if (loc->x == BCAST_X && loc->y == BCAST_Y)
		return AM_BROADCAST_ADDR;
	else
	 return loc->x + (loc->y - 1) * numColumns - 1;
	}	

	#if ENABLE_SPACE_LOCALIZER && defined(PLATFORM_MICA2)	 //non utilizzato
	/**
	 * This event is generated whenever the closest
	 * cricket beacon mote changes.	It passes the
	 * name of the new closest space.
	 */	
	event void SpaceLocalizerI.moved(char* spaceID) {
		uint32_t freq;
		call RadioControl.stop();
		if (strcmp("DOCK", spaceID) == 0) {
		freq = call CC1000Control.TuneManual(CC1000_CHANNEL_2);
		 if (freq == CC1000_CHANNEL_2) {
			 //moveCount = 0;
			 //call MoveTimer.start(TIMER_REPEAT, 128);
			 call LEDBlinkerI.blink(YELLOW | GREEN, 3, 128);
		 }
		} else	{
		freq = call CC1000Control.TuneManual(CC1000_CHANNEL_4);
		if (freq == CC1000_CHANNEL_4) {
			//moveCount = 0;
			//call MoveTimer.start(TIMER_REPEAT, 128);
			call LEDBlinkerI.blink(YELLOW | GREEN, 3, 128);
		}
		}
		call RadioControl.start();	 
	}

	/*event void MoveTimer.fired() {
		call Leds.led1Toggle();
		call Leds.led2Toggle();
		if (++moveCount == 6)
		call MoveTimer.stop();
		//return SUCCESS;
	}*/
	
	event error_t LEDBlinkerI.blinkDone() {
		return SUCCESS;
	}	
	#endif

	// -----------------------------------------------------------------------------------------
	// The following methods allow the grid size to change.
	
	/**
	 * Floods the grid size message.	Each mote only broadcasts once.	 
	 */
	event message_t* ReceiveGridSizeMsg.receive(message_t* m, void* payload, uint8_t len) {
	AgillaGridSizeMsg* gsmsg = (AgillaGridSizeMsg*)payload;
			 
	if (!changingGridSize) {	// only re-broadcast once (prevents recursive flooding)
		if (numColumns != gsmsg->numCol) {
		changingGridSize = TRUE;
		call Leds.led0On();
		call Leds.led1On();
		call Leds.led2On();
		msg = *m;
		numColumns = gsmsg->numCol;
		call SendGridSizeMsg.send(AM_BROADCAST_ADDR, &msg, sizeof(AgillaGridSizeMsg));
		//call GridSizeTimer.start(TIMER_ONE_SHOT, 1024);	// wait for flooding to finish	 
		call GridSizeTimer.startOneShot(1024);
		 }
	}		 
	return m;
	}

	//RECEIVE SERIAL
	event message_t* SerialReceiveGridSizeMsg.receive(message_t* m, void* payload, uint8_t len) {
	AgillaGridSizeMsg* gsmsg = (AgillaGridSizeMsg*)payload;
			 
	if (!changingGridSize) {	// only re-broadcast once (prevents recursive flooding)
		if (numColumns != gsmsg->numCol) {
		changingGridSize = TRUE;
		call Leds.led0On();
		call Leds.led1On();
		call Leds.led2On();
		msg = *m;
		numColumns = gsmsg->numCol;
		call SendGridSizeMsg.send(AM_BROADCAST_ADDR, &msg, sizeof(AgillaGridSizeMsg));
		//call GridSizeTimer.start(TIMER_ONE_SHOT, 1024);	// wait for flooding to finish	 
		call GridSizeTimer.startOneShot(1024);
		 }
	}		 
	return m;
	}
	
	/**
	 * Whenever the gridsize timer fires, turn off all LEDs and update the
	 * new possible neighbors.
	 */
	event void GridSizeTimer.fired() {
	call Leds.led0Off();
	call Leds.led1Off();
	call Leds.led2Off();	
	changingGridSize = FALSE;	
	//return SUCCESS;
	}	

	event void SendGridSizeMsg.sendDone(message_t* mesg, error_t success) {
	//return SUCCESS;
	}	
}

