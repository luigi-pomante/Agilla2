// $Id: OPgetNumAgents.nc,v 1.2 2006/04/07 01:14:53 borndigerati Exp $

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
configuration OPgetNumAgents {
	provides interface BytecodeI;
}
implementation {
	components MainC, LocationMgrC, AgentMgrC, TupleUtilC;
	components OpStackC, QueueProxy, ErrorMgrProxy, LedsC;
	components AddressMgrC, MessageBufferM;
	/*
	components new NetworkInterfaceProxy(AM_AGILLAQUERYNUMAGENTSMSG) as Comm1;
	components new NetworkInterfaceProxy(AM_AGILLAQUERYREPLYNUMAGENTSMSG) as Comm2;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYNUMAGENTSMSG) as Comm3;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYREPLYNUMAGENTSMSG) as Comm4;
	*/

	components new AMSenderC(AM_AGILLAQUERYNUMAGENTSMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLAQUERYNUMAGENTSMSG) as ReceiveComm1;
	components new SerialAMSenderC(AM_AGILLAQUERYNUMAGENTSMSG) as SerialSendComm3;
	components new SerialAMReceiverC(AM_AGILLAQUERYNUMAGENTSMSG) as SerialReceiveComm3;

	components new AMSenderC(AM_AGILLAQUERYREPLYNUMAGENTSMSG) as SendComm2;
	components new AMReceiverC(AM_AGILLAQUERYREPLYNUMAGENTSMSG) as ReceiveComm2;
	components new SerialAMSenderC(AM_AGILLAQUERYREPLYNUMAGENTSMSG) as SerialSendComm4;
	components new SerialAMReceiverC(AM_AGILLAQUERYREPLYNUMAGENTSMSG) as SerialReceiveComm4;

	components new TimerMilliC() as Timer;
	components ActiveMessageC;
	#if ENABLE_CLUSTERING
	components NeighborListM as NbrList;
	components OPgetNumAgentsCM as OPgetNumAgents;
	#else
	components NeighborListProxy as NbrList;
	components OPgetNumAgentsM as OPgetNumAgents;
	#endif

	BytecodeI = OPgetNumAgents;

	//Main.StdControl -> OPgetNumAgents;
	//Main.StdControl -> MessageBufferM;
	//Main.StdControl -> TimerC;
	MainC.SoftwareInit -> MessageBufferM.Init;
	MainC.SoftwareInit -> OPgetNumAgents.Init;

	OPgetNumAgents.NeighborListI -> NbrList;
	#if ENABLE_CLUSTERING
	OPgetNumAgents.ClusteringI -> NbrList;
	#endif
	OPgetNumAgents.LocationMgrI -> LocationMgrC;

	OPgetNumAgents.SendRequest -> SendComm1.AMSend;
	OPgetNumAgents.ReceiveRequest -> ReceiveComm1.Receive;
	OPgetNumAgents.SerialSendRequest -> SerialSendComm3.AMSend;
	OPgetNumAgents.SerialReceiveRequest -> SerialReceiveComm3.Receive;

	OPgetNumAgents.SendResults -> SendComm2.AMSend;
	OPgetNumAgents.ReceiveResults -> ReceiveComm2.Receive;
	OPgetNumAgents.SerialSendResults -> SerialSendComm4.AMSend;
	OPgetNumAgents.SerialReceiveResults -> SerialReceiveComm4.Receive;

	OPgetNumAgents.MessageBufferI -> MessageBufferM;
	OPgetNumAgents.AddressMgrI -> AddressMgrC;
	OPgetNumAgents.AgentMgrI -> AgentMgrC;
	OPgetNumAgents.TupleUtilI -> TupleUtilC;
	OPgetNumAgents.OpStackI -> OpStackC;
	OPgetNumAgents.QueueI -> QueueProxy;
	OPgetNumAgents.ErrorMgrI -> ErrorMgrProxy;
	OPgetNumAgents.Leds -> LedsC;
	OPgetNumAgents.Timeout -> Timer;
	OPgetNumAgents.Packet -> ActiveMessageC;
}

