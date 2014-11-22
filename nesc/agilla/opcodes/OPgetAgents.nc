// $Id: OPgetAgents.nc,v 1.4 2006/04/15 05:33:52 borndigerati Exp $

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
configuration OPgetAgents {
	provides interface BytecodeI;
}
implementation {
	components MainC, LocationMgrC, AgentMgrC, TupleUtilC;
	components OpStackC, QueueProxy, ErrorMgrProxy, LedsC;
	/*
	components new NetworkInterfaceProxy(AM_AGILLAQUERYALLAGENTSMSG) as Comm1;
	components new NetworkInterfaceProxy(AM_AGILLAQUERYREPLYALLAGENTSMSG) as Comm2;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYALLAGENTSMSG) as Comm3;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYREPLYALLAGENTSMSG) as Comm4;
	*/

	components new AMSenderC(AM_AGILLAQUERYALLAGENTSMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLAQUERYALLAGENTSMSG) as ReceiveComm1;
	components new SerialAMSenderC(AM_AGILLAQUERYALLAGENTSMSG) as SerialSendComm3;
	components new SerialAMReceiverC(AM_AGILLAQUERYALLAGENTSMSG) as SerialReceiveComm3;

	components new AMSenderC(AM_AGILLAQUERYREPLYALLAGENTSMSG) as SendComm2;
	components new AMReceiverC(AM_AGILLAQUERYREPLYALLAGENTSMSG) as ReceiveComm2;
	components new SerialAMSenderC(AM_AGILLAQUERYREPLYALLAGENTSMSG) as SerialSendComm4;
	components new SerialAMReceiverC(AM_AGILLAQUERYREPLYALLAGENTSMSG) as SerialReceiveComm4;

	components AddressMgrC, MessageBufferM;
	components new TimerMilliC() as Timer;
	components ActiveMessageC;
	#if ENABLE_CLUSTERING
	components ClusterheadDirectoryM;
	components NeighborListM as NbrList;
	components OPgetAgentsCM as OPgetAgents;
	#else
	components NeighborListProxy as NbrList;
	components OPgetAgentsM as OPgetAgents;
	#endif

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#ifdef _H_msp430hardware_h
		components LocalTimeMicroC;
	#endif
	#endif

	BytecodeI = OPgetAgents;

	MainC.SoftwareInit -> MessageBufferM.Init;
	MainC.SoftwareInit -> OPgetAgents.Init;

	OPgetAgents.NeighborListI -> NbrList;
	OPgetAgents.LocationMgrI -> LocationMgrC;

	OPgetAgents.SendRequest -> SendComm1.AMSend;
	OPgetAgents.ReceiveRequest -> ReceiveComm1.Receive;
	OPgetAgents.SerialSendRequest -> SerialSendComm3.AMSend;
	OPgetAgents.SerialReceiveRequest -> SerialReceiveComm3.Receive;
 
	OPgetAgents.SendResults -> SendComm2.AMSend;
	OPgetAgents.ReceiveResults -> ReceiveComm2.Receive;
	OPgetAgents.SerialSendResults -> SerialSendComm4.AMSend;
	OPgetAgents.SerialReceiveResults -> SerialReceiveComm4.Receive;

	OPgetAgents.MessageBufferI -> MessageBufferM;
	OPgetAgents.AddressMgrI -> AddressMgrC;
	OPgetAgents.AgentMgrI -> AgentMgrC;
	OPgetAgents.TupleUtilI -> TupleUtilC;
	OPgetAgents.OpStackI -> OpStackC;
	OPgetAgents.QueueI -> QueueProxy;
	OPgetAgents.ErrorMgrI -> ErrorMgrProxy;
	OPgetAgents.Leds -> LedsC;
	OPgetAgents.Timeout -> Timer;
	
	OPgetAgents.Packet -> ActiveMessageC;

	#if ENABLE_CLUSTERING
	OPgetAgents.ClusteringI -> NbrList;
	OPgetAgents.ClusterheadDirectoryI -> ClusterheadDirectoryM;
	#endif


	#if ENABLE_EXP_LOGGING
	OPgetAgents.ExpLoggerI -> ExpLoggerC;
	#ifdef _H_msp430hardware_h
		OPgetAgents.LocalTime -> LocalTimeMicroC;
	#endif
	#endif
}

