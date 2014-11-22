// $Id: NetworkInterfaceM.nc,v 1.12 2006/04/20 22:05:58 chien-liang Exp $

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

/**
 * Serializes the sending of messages.	This is required
 * when there are multiple components that want to send messages
 * but have no way of coordinating.	By buffering
 * the messages, one component does not have to wait for another
 * component to receive the sendDone() event before it sends a
 * message.
 *
 * Interface SendMsg is a split-phase operation.	After calling
 * SendMsg.send, the message being sent must not be modified
 * until a corresponding SendMsg.sendDone event is signalled.	On
 * a MICA2 mote, the time between calling SendMsg.send and getting
 * a sendMsg.sendDone is approximtely 47 binary ms.
 *
 *
 * @author Chien-Liang Fok
 * @version 3.0
 */

module BootRadioSerial
{ 
	uses
	{
		interface Boot;
		interface SplitControl as RadioAMControl;
		interface SplitControl as SerialAMControl;
	}
}
implementation
{
	event void Boot.booted()
	{
		call RadioAMControl.start();
		call SerialAMControl.start();
	}


	//RADIO
	event void RadioAMControl.startDone(error_t err)
	{
		if(err != SUCCESS)
			call RadioAMControl.start();
	}


	event void RadioAMControl.stopDone(error_t err) { }


	//SERIALE
	event void SerialAMControl.startDone(error_t err)
	{
		if(err != SUCCESS) call SerialAMControl.start();
	}


	event void SerialAMControl.stopDone(error_t err) { }
}

