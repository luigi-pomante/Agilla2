// $Id: NetworkInterfaceC.nc,v 1.4 2006/04/05 18:04:38 chien-liang Exp $

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
 * Serializes the sending of multiple messages.
 *
 * @author Chien-Liang Fok
 * @version 3.0
 */
//#include "NetworkInterface.h"
#include "AM.h"

generic configuration SerialNetworkInterfaceC(am_id_t amId) {
	provides {
	interface StdControl;
	interface Init;
	interface AMSend[uint8_t id];
	interface Receive[uint8_t id];
	//interface Send as MultihopSend[uint8_t id];
	}
}
implementation {
	components new SerialAMSenderC(amId) as AMS, new SerialAMReceiverC(amId) as AMR;
	components NetworkInterfaceM as NIM;
	components MessageBufferM; 
	#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
		components CC2420RadioC;
	#endif

	#ifdef TOSH_HARDWARE_MICA2
	components CC1000RadioC;
	#endif
	
	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#endif

	StdControl = NIM;
	Init = NIM;
	StdControl = MessageBufferM;
	Init = MessageBufferM;
	AMSend = NIM;
	Receive = NIM;
	NIM.AMSend -> AMS.AMSend;
	NIM.Receive -> AMR.Receive;
	NIM.AMPacket -> AMS;
	NIM.Packet -> AMS;

	NIM.MessageBufferI -> MessageBufferM;

	#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
			NIM.CC2420Control -> CC2420RadioC.CC2420Control;
	#endif

	#ifdef TOSH_HARDWARE_MICA2
	NIM.MacControl -> CC1000RadioC;
	#endif
	
	#if ENABLE_EXP_LOGGING
	NIM.ExpLoggerI -> ExpLoggerC;
	#endif	
}

