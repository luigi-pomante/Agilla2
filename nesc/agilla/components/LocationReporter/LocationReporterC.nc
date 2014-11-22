// $Id: LocationReporterC.nc,v 1.7 2006/04/11 04:20:54 chien-liang Exp $

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

#include "LocationDirectory.h"


/**
 * Wires up all of the components used for reporting
 * agent location.
 *
 * @author Sangeeta Bhattacharya
 * @author Chien-Liang Fok
 */
configuration LocationReporterC {
	provides {
	interface StdControl;
	interface Init;
	interface LocationReporterI;
	}
}
implementation {
	components LocationReporterM, AgentReceiverC, AddressMgrC, MessageBufferM;


	
	components new AMSenderC(AM_AGILLALOCMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLALOCMSG) as ReceiveComm1;
	components new SerialAMSenderC(AM_AGILLALOCMSG) as SerialSendComm2;
	components new SerialAMReceiverC(AM_AGILLALOCMSG) as SerialReceiveComm2;

	components NeighborListProxy;
	components LocationMgrC, SimpleTime, AgentMgrC, LedsC; 
	components ActiveMessageC;
	
	#if ENABLE_CLUSTERING
	components NeighborListM, ClusterheadDirectoryM;
	#endif

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#endif


	StdControl = LocationReporterM;
	StdControl = MessageBufferM;
	StdControl = AgentReceiverC;
	Init = LocationReporterM;
	Init = MessageBufferM;
	Init = AgentReceiverC;
	LocationReporterI = LocationReporterM;
	LocationReporterM.Time -> SimpleTime;
	LocationReporterM.AgentMgrI -> AgentMgrC;
	LocationReporterM.LocationMgrI -> LocationMgrC;
	LocationReporterM.NeighborListI -> NeighborListProxy;
	LocationReporterM.AddressMgrI -> AddressMgrC;
	LocationReporterM.MessageBufferI -> MessageBufferM;
	LocationReporterM.AgentReceiverI -> AgentReceiverC;
	LocationReporterM.SendLocation -> SendComm1.AMSend;
	LocationReporterM.SerialSendLocation -> SerialSendComm2.AMSend;
	LocationReporterM.ReceiveLocation -> ReceiveComm1.Receive;
	LocationReporterM.SerialReceiveLocation -> SerialReceiveComm2.Receive;

	#if ENABLE_CLUSTERING
	LocationReporterM.ClusteringI -> NeighborListM;
	LocationReporterM.CHDir -> ClusterheadDirectoryM;
	#endif

	#if ENABLE_EXP_LOGGING
	LocationReporterM.ExpLoggerI -> ExpLoggerC;
	#endif

	LocationReporterM.Leds -> LedsC;
	LocationReporterM.Packet -> ActiveMessageC;

}
