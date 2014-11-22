// $Id: AddressMgrC.nc,v 1.6 2006/02/11 08:11:53 chien-liang Exp $

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
#include "LEDBlinker.h"

/**
 * Manages address information, e.g., determines if a mote is a base
 * station and what the original address is.
 *
 * @author Chien-Liang Fok
 */
configuration AddressMgrC {
	provides interface AddressMgrI;	
}
implementation {
	components AddressMgrM; 
	/*
	components new NetworkInterfaceProxy(AM_AGILLASETBSMSG) as Comm1;
	components new NetworkInterfaceProxy(AM_AGILLAADDRESSMSG) as Comm2;
	components new NetworkInterfaceProxy(AM_AGILLAADDRESSACKMSG) as Comm3;
	components new SerialNetworkInterfaceProxy(AM_AGILLASETBSMSG) as Comm4;
	components new SerialNetworkInterfaceProxy(AM_AGILLAADDRESSMSG) as Comm5;
	components new SerialNetworkInterfaceProxy(AM_AGILLAADDRESSACKMSG) as Comm6;
	*/
	components new AMReceiverC(AM_AGILLASETBSMSG) as ReceiveComm1;
	components new SerialAMReceiverC(AM_AGILLASETBSMSG) as SerialReceiveComm4; 
	
	components new AMSenderC(AM_AGILLAADDRESSMSG) as SendComm2;
	components new AMReceiverC(AM_AGILLAADDRESSMSG) as ReceiveComm2;
	components new SerialAMReceiverC(AM_AGILLAADDRESSMSG) as SerialReceiveComm5; 
	
	components new AMSenderC(AM_AGILLAADDRESSACKMSG) as SendComm3;
	components new AMReceiverC(AM_AGILLAADDRESSACKMSG) as ReceiveComm3;
	components new SerialAMSenderC(AM_AGILLAADDRESSACKMSG) as SerialSendComm6; 
	components new SerialAMReceiverC(AM_AGILLAADDRESSACKMSG) as SerialReceiveComm6; 

 


	components new TimerMilliC() as BSTimer;
	components MainC;
	components LEDBlinkerC;
	components ActiveMessageC;
	
	AddressMgrI = AddressMgrM;

	//MainC.StdControl -> AddressMgrM; 
	//MainC.StdControl -> TimerC;
	//MainC.StdControl -> LEDBlinkerC;
	MainC.SoftwareInit -> AddressMgrM.Init;
	MainC.SoftwareInit -> LEDBlinkerC.Init;
	AddressMgrM.Boot -> MainC;
	AddressMgrM.Packet -> ActiveMessageC;

	AddressMgrM.ReceiveSetBSMsg -> ReceiveComm1.Receive;
	AddressMgrM.ReceiveAddress -> ReceiveComm2.Receive;
	AddressMgrM.SendAddress -> SendComm2.AMSend;
	AddressMgrM.ReceiveAddressAck -> ReceiveComm3.Receive;
	AddressMgrM.SendAddressAck -> SendComm3.AMSend;
	AddressMgrM.SerialReceiveSetBSMsg -> SerialReceiveComm4.Receive;
	AddressMgrM.SerialReceiveAddress -> SerialReceiveComm5.Receive;
	AddressMgrM.SerialSendAddressAck -> SerialSendComm6.AMSend;
	AddressMgrM.SerialReceiveAddressAck -> SerialReceiveComm6.Receive;
	//AddressMgrM.AddrTimer -> TimerC.Timer[unique("Timer")];
	
	//AddressMgrM.SendDebugMsg -> Comm.SendMsg[0x99];
	
	/**
	 * This is used to timeout a base station, setting the node to be a 
	 * non-base station.
	 */
	//AddressMgrM.BSTimer -> TimerC.Timer[unique("Timer")];
	AddressMgrM.BSTimer -> BSTimer;
	//AddressMgrM.Leds -> LedsC; 
	AddressMgrM.LEDBlinkerI -> LEDBlinkerC;
}

