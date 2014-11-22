// $Id: OPgetlocation.nc,v 1.7 2006/04/15 05:33:52 borndigerati Exp $

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
#include "TupleSpace.h"
#include "LocationDirectory.h"

/**
 * Handles the initiating side of a remote tuple space
 * operation.
 *
 * @author Chien-Liang Fok
 */
configuration OPgetlocation {
	provides interface BytecodeI;
}
implementation {
	components MainC, LocationMgrC, AgentMgrC, TupleUtilC;
	components OpStackC, QueueProxy, ErrorMgrProxy, LedsC;
	/*
	components new NetworkInterfaceProxy(AM_AGILLAQUERYAGENTLOCMSG) as Comm1;
	components new NetworkInterfaceProxy(AM_AGILLAQUERYREPLYAGENTLOCMSG) as Comm2;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYAGENTLOCMSG) as Comm3;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYREPLYAGENTLOCMSG) as Comm4;
	*/

	components new AMSenderC(AM_AGILLAQUERYAGENTLOCMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLAQUERYAGENTLOCMSG) as ReceiveComm1;
	components new SerialAMSenderC(AM_AGILLAQUERYAGENTLOCMSG) as SerialSendComm3;
	components new SerialAMReceiverC(AM_AGILLAQUERYAGENTLOCMSG) as SerialReceiveComm3;

	components new AMSenderC(AM_AGILLAQUERYREPLYAGENTLOCMSG) as SendComm2;
	components new AMReceiverC(AM_AGILLAQUERYREPLYAGENTLOCMSG) as ReceiveComm2;
	components new SerialAMSenderC(AM_AGILLAQUERYREPLYAGENTLOCMSG) as SerialSendComm4;
	components new SerialAMReceiverC(AM_AGILLAQUERYREPLYAGENTLOCMSG) as SerialReceiveComm4;

	components AddressMgrC, MessageBufferM;
	components new TimerMilliC() as Timer;
	components ActiveMessageC;

	#if ENABLE_CLUSTERING
	components ClusterheadDirectoryM;
	components NeighborListM as NbrList;
	components OPgetlocationCM as OPgetlocation;
	#else
	components NeighborListProxy as NbrList;
	components OPgetlocationM as OPgetlocation;
	#endif

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#ifdef _H_msp430hardware_h
		components LocalTimeMicroC;
	#endif
	#endif


	BytecodeI = OPgetlocation;




	MainC.SoftwareInit -> MessageBufferM.Init;
	MainC.SoftwareInit -> OPgetlocation.Init;

	OPgetlocation.NeighborListI -> NbrList;
	OPgetlocation.LocationMgrI -> LocationMgrC;

	#if ENABLE_CLUSTERING
	OPgetlocation.ClusteringI -> NbrList;
	OPgetlocation.ClusterheadDirectoryI -> ClusterheadDirectoryM;
	#endif

	OPgetlocation.SendRequest -> SendComm1.AMSend;
	OPgetlocation.ReceiveRequest -> ReceiveComm1.Receive;
	OPgetlocation.SerialSendRequest -> SerialSendComm3.AMSend;
	OPgetlocation.SerialReceiveRequest -> SerialReceiveComm3.Receive;

	OPgetlocation.SendResults -> SendComm2.AMSend;
	OPgetlocation.ReceiveResults -> ReceiveComm2.Receive;
	OPgetlocation.SerialSendResults -> SerialSendComm4.AMSend;
	OPgetlocation.SerialReceiveResults -> SerialReceiveComm4.Receive;

	OPgetlocation.MessageBufferI -> MessageBufferM;
	OPgetlocation.AddressMgrI -> AddressMgrC;
	OPgetlocation.AgentMgrI -> AgentMgrC;
	OPgetlocation.TupleUtilI -> TupleUtilC;
	OPgetlocation.OpStackI -> OpStackC;
	OPgetlocation.QueueI -> QueueProxy;
	OPgetlocation.ErrorMgrI -> ErrorMgrProxy;
	OPgetlocation.Leds -> LedsC;
	OPgetlocation.Timeout -> Timer;
	
	OPgetlocation.Packet -> ActiveMessageC;

	#if ENABLE_EXP_LOGGING

	OPgetlocation.ExpLoggerI -> ExpLoggerC;
		#ifdef _H_msp430hardware_h
		OPgetlocation.LocalTime -> LocalTimeMicroC;
		#endif

	#endif

}

