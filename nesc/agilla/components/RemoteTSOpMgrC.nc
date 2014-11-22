// $Id: RemoteTSOpMgrC.nc,v 1.5 2006/02/06 09:40:39 chien-liang Exp $

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
 * Handles remote tuple space requests.
 *
 * @author Chien-Liang Fok
 */
configuration RemoteTSOpMgrC
{
	provides interface RemoteTSOpMgrI;
}

implementation
{
	components MainC, RemoteTSOpMgrM;
	components TupleUtilC, TupleSpaceProxy;

	components new AMSenderC(AM_AGILLATSREQMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLATSREQMSG) as ReceiveComm1;
	components new SerialAMSenderC(AM_AGILLATSREQMSG) as SerialSendComm4;
	components new SerialAMReceiverC(AM_AGILLATSREQMSG) as SerialReceiveComm4;

	components new AMSenderC(AM_AGILLATSRESMSG) as SendComm2;
	components new AMReceiverC(AM_AGILLATSRESMSG) as ReceiveComm2;
	components new SerialAMSenderC(AM_AGILLATSRESMSG) as SerialSendComm5;
	components new SerialAMReceiverC(AM_AGILLATSRESMSG) as SerialReceiveComm5;

	components new AMSenderC(AM_AGILLATSGRESMSG) as SendComm3;
	components new AMReceiverC(AM_AGILLATSGRESMSG) as ReceiveComm3;
	components new SerialAMSenderC(AM_AGILLATSGRESMSG) as SerialSendComm6;
	components new SerialAMReceiverC(AM_AGILLATSGRESMSG) as SerialReceiveComm6;

	components RandomC, NeighborListProxy, AddressMgrC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components ErrorMgrProxy, MessageBufferM;
	components LocationMgrC;
	components LedsC;
	components ActiveMessageC;
	


	MainC.SoftwareInit -> RemoteTSOpMgrM.Init;
	MainC.SoftwareInit -> TupleSpaceProxy.Init;
	MainC.SoftwareInit -> MessageBufferM.Init;

	
	RemoteTSOpMgrI = RemoteTSOpMgrM;
	RemoteTSOpMgrM.Rcv_Req -> ReceiveComm1.Receive;
	RemoteTSOpMgrM.Rcv_Res -> ReceiveComm2.Receive;
	RemoteTSOpMgrM.Rcv_GRes -> ReceiveComm3.Receive;
	RemoteTSOpMgrM.SerialRcv_Req -> SerialReceiveComm4.Receive;
	RemoteTSOpMgrM.SerialRcv_Res -> SerialReceiveComm5.Receive;
	RemoteTSOpMgrM.SerialRcv_GRes -> SerialReceiveComm6.Receive;

	RemoteTSOpMgrM.Send_Req -> SendComm1.AMSend;
	RemoteTSOpMgrM.SerialSend_Req -> SerialSendComm4.AMSend;
	RemoteTSOpMgrM.Send_Res -> SendComm2.AMSend;
	RemoteTSOpMgrM.SerialSend_Res -> SerialSendComm5.AMSend;
	RemoteTSOpMgrM.Send_GRes -> SendComm3.AMSend;
	RemoteTSOpMgrM.SerialSend_GRes -> SerialSendComm6.AMSend;
	RemoteTSOpMgrM.Timeout -> Timer0;
	
	RemoteTSOpMgrM.BackoffTimer -> Timer1;
	RemoteTSOpMgrM.Random -> RandomC;
	
	RemoteTSOpMgrM.AddressMgrI-> AddressMgrC;	
	RemoteTSOpMgrM.NeighborListI -> NeighborListProxy;
	RemoteTSOpMgrM.TupleSpaceI -> TupleSpaceProxy;
	RemoteTSOpMgrM.TupleUtilI -> TupleUtilC;	
	RemoteTSOpMgrM.ErrorMgrI -> ErrorMgrProxy;	
	RemoteTSOpMgrM.MessageBufferI -> MessageBufferM;
	RemoteTSOpMgrM.LocationMgrI -> LocationMgrC;
	
	RemoteTSOpMgrM.Leds -> LedsC;
	RemoteTSOpMgrM.Packet -> ActiveMessageC;
	RemoteTSOpMgrM.AMPacket -> ActiveMessageC;
}
