// $Id: TimeSyncC.nc,v 1.2 2006/03/20 14:31:46 chien-liang Exp $

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
configuration TimeSyncC 
{
	provides interface StdControl; 
	provides interface Init;
}
implementation 
{
	components TimeSyncM, AddressMgrC, SimpleTime, MessageBufferM;
	components LedsC;
	components new TimerMilliC() as Timer;
	components new AMReceiverC(AM_AGILLATIMESYNCMSG) as ReceiveComm1;
	components new SerialAMSenderC(AM_AGILLATIMESYNCMSG) as SerialSendComm2;
	components new SerialAMReceiverC(AM_AGILLATIMESYNCMSG) as SerialReceiveComm2;
	components ActiveMessageC;

	StdControl = TimeSyncM;
	Init = TimeSyncM;
	StdControl = MessageBufferM;
	Init = MessageBufferM;

	TimeSyncM.AddressMgrI -> AddressMgrC;
	TimeSyncM.Time -> SimpleTime;
	TimeSyncM.TimeSet -> SimpleTime;
	TimeSyncM.MessageBufferI -> MessageBufferM;
	TimeSyncM.Timer -> Timer;

	TimeSyncM.ReceiveTime -> ReceiveComm1.Receive;
	TimeSyncM.SerialSendTime -> SerialSendComm2.AMSend;
	TimeSyncM.SerialReceiveTime -> SerialReceiveComm2.Receive;
	TimeSyncM.Leds -> LedsC;
	TimeSyncM.Packet -> ActiveMessageC;
}
