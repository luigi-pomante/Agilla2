// $Id: OPgetClosestAgent.nc,v 1.5 2006/04/15 05:33:52 borndigerati Exp $

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
configuration OPgetClosestAgent {
	provides interface BytecodeI;
}
implementation {
	components MainC, OPgetClosestAgentM, LocationMgrC, AgentMgrC, TupleUtilC;
	components OpStackC, QueueProxy, ErrorMgrProxy, LedsC;
	components AddressMgrC, MessageBufferM;
	/*
	components new NetworkInterfaceProxy(AM_AGILLAQUERYNEARESTAGENTMSG) as Comm1;
	components new NetworkInterfaceProxy(AM_AGILLAQUERYREPLYNEARESTAGENTMSG) as Comm2;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYNEARESTAGENTMSG) as Comm3;
	components new SerialNetworkInterfaceProxy(AM_AGILLAQUERYREPLYNEARESTAGENTMSG) as Comm4;
	*/

	components new AMSenderC(AM_AGILLAQUERYNEARESTAGENTMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLAQUERYNEARESTAGENTMSG) as ReceiveComm1;
	components new SerialAMSenderC(AM_AGILLAQUERYNEARESTAGENTMSG) as SerialSendComm3;
	components new SerialAMReceiverC(AM_AGILLAQUERYNEARESTAGENTMSG) as SerialReceiveComm3;

	components new AMSenderC(AM_AGILLAQUERYREPLYNEARESTAGENTMSG) as SendComm2;
	components new AMReceiverC(AM_AGILLAQUERYREPLYNEARESTAGENTMSG) as ReceiveComm2;
	components new SerialAMSenderC(AM_AGILLAQUERYREPLYNEARESTAGENTMSG) as SerialSendComm4;
	components new SerialAMReceiverC(AM_AGILLAQUERYREPLYNEARESTAGENTMSG) as SerialReceiveComm4;

	components new TimerMilliC() as Timer;
	components ActiveMessageC;

	#if ENABLE_CLUSTERING
	components ClusterheadDirectoryM;
	components NeighborListM as NbrList;
	components OPgetClosestAgentCM as OPgetClosestAgent;
	#else
	components NeighborListProxy as NbrList;
	components OPgetClosestAgentM as OPgetClosestAgent;
	#endif

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#ifdef _H_msp430hardware_h
		components LocalTimeMicroC;
	#endif
	#endif

	BytecodeI = OPgetClosestAgent;

	//Main.StdControl -> OPgetClosestAgent;
	//Main.StdControl -> MessageBufferM;
	//Main.StdControl -> TimerC;
	MainC.SoftwareInit -> MessageBufferM.Init;
	MainC.SoftwareInit -> OPgetClosestAgent.Init;

	OPgetClosestAgent.NeighborListI -> NbrList;
	OPgetClosestAgent.LocationMgrI -> LocationMgrC;

	OPgetClosestAgent.SendRequest -> SendComm1.AMSend;
	OPgetClosestAgent.ReceiveRequest -> ReceiveComm1.Receive;
	OPgetClosestAgent.SerialSendRequest -> SerialSendComm3.AMSend;
	OPgetClosestAgent.SerialReceiveRequest -> SerialReceiveComm3.Receive;

	OPgetClosestAgent.SendResults -> SendComm2.AMSend;
	OPgetClosestAgent.ReceiveResults -> ReceiveComm2.Receive;
	OPgetClosestAgent.SerialSendResults -> SerialSendComm4.AMSend;
	OPgetClosestAgent.SerialReceiveResults -> SerialReceiveComm4.Receive;

	OPgetClosestAgent.MessageBufferI -> MessageBufferM;
	OPgetClosestAgent.AddressMgrI -> AddressMgrC;
	OPgetClosestAgent.AgentMgrI -> AgentMgrC;
	OPgetClosestAgent.TupleUtilI -> TupleUtilC;
	OPgetClosestAgent.OpStackI -> OpStackC;
	OPgetClosestAgent.QueueI -> QueueProxy;
	OPgetClosestAgent.ErrorMgrI -> ErrorMgrProxy;
	OPgetClosestAgent.Leds -> LedsC;
	OPgetClosestAgent.Timeout -> Timer;

	OPgetClosestAgent.Packet -> ActiveMessageC;

	#if ENABLE_CLUSTERING
	OPgetClosestAgent.ClusteringI -> NbrList;
	OPgetClosestAgent.ClusterheadDirectoryI -> ClusterheadDirectoryM;
	#endif
	#if ENABLE_EXP_LOGGING
	OPgetClosestAgent.ExpLoggerI -> ExpLoggerC;
	#ifdef _H_msp430hardware_h
		OPgetClosestAgent.LocalTime -> LocalTimeMicroC;
	#endif
	#endif

}

