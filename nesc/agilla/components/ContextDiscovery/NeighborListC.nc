// $Id: NeighborListC.nc,v 1.12 2006/04/25 22:27:38 chien-liang Exp $

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
#include "Clustering.h"

configuration NeighborListC {
	provides interface NeighborListI;
	
	#if ENABLE_CLUSTERING
	provides interface ClusteringI;
	#endif
}
implementation {
	components MainC;
	components NeighborListM, AddressMgrC, LedsC;
	/*
	components new NetworkInterfaceProxy(AM_AGILLABEACONMSG) as Comm1;
	components new NetworkInterfaceProxy(AM_AGILLAGETNBRMSG) as Comm2;
	components new NetworkInterfaceProxy(AM_AGILLANBRMSG) as Comm3;
	components new SerialNetworkInterfaceProxy(AM_AGILLABEACONMSG) as Comm4;
	components new SerialNetworkInterfaceProxy(AM_AGILLAGETNBRMSG) as Comm5;
	components new SerialNetworkInterfaceProxy(AM_AGILLANBRMSG) as Comm6;
	*/
	
	components new AMSenderC(AM_AGILLABEACONMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLABEACONMSG) as ReceiveComm1;
	components new SerialAMReceiverC(AM_AGILLABEACONMSG) as SerialReceiveComm4;

	components new AMSenderC(AM_AGILLAGETNBRMSG) as SendComm2;
	components new AMReceiverC(AM_AGILLAGETNBRMSG) as ReceiveComm2;
	components new SerialAMReceiverC(AM_AGILLAGETNBRMSG) as SerialReceiveComm5;

	components new AMSenderC(AM_AGILLANBRMSG) as SendComm3;
	components new AMReceiverC(AM_AGILLANBRMSG) as ReceiveComm3;
	components new SerialAMSenderC(AM_AGILLANBRMSG) as SerialSendComm6;
	components new SerialAMReceiverC(AM_AGILLANBRMSG) as SerialReceiveComm6;

	
	components RandomC, SimpleTime;
	components LocationUtils, LocationMgrC, MessageBufferM;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components ActiveMessageC;
	
	#if ENABLE_CLUSTERING
	components ClusterheadDirectoryC;
	#endif

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#endif


	//Main.StdControl -> NeighborListM;
	MainC.SoftwareInit -> NeighborListM.Init;
	NeighborListM.Boot -> MainC;
	//Main.StdControl -> SimpleTime;
	MainC.SoftwareInit -> SimpleTime.Init;
	SimpleTime.Boot -> MainC;

	//Main.StdControl -> MessageBufferM;
	MainC.SoftwareInit -> MessageBufferM.Init;

	NeighborListI = NeighborListM;

	#if ENABLE_CLUSTERING
	ClusteringI = NeighborListM;
	NeighborListM.CHDir -> ClusterheadDirectoryC;
	NeighborListM.CHDirControl -> ClusterheadDirectoryC;
	#endif

	NeighborListM.AddressMgrI -> AddressMgrC;

	NeighborListM.Random -> RandomC;

	NeighborListM.Time -> SimpleTime;
	NeighborListM.TimeUtil -> SimpleTime;

	NeighborListM.BeaconTimer -> Timer0;
	NeighborListM.DisconnectTimer-> Timer1;

	NeighborListM.SendBeacon -> SendComm1.AMSend;
	NeighborListM.RcvBeacon -> ReceiveComm1.Receive;
	NeighborListM.SerialRcvBeacon -> SerialReceiveComm4.Receive;

	//Finder.SendBeaconBS -> Comm.SendMsg[AM_AGILLABEACONBSMSG];
	//Finder.RcvBeaconBS -> Comm.ReceiveMsg[AM_AGILLABEACONBSMSG];

	NeighborListM.RcvGetNbrList -> ReceiveComm2.Receive;
	NeighborListM.SendGetNbrList -> SendComm2.AMSend;
	NeighborListM.SerialRcvGetNbrList -> SerialReceiveComm5.Receive;

	//NeighborListM.SendNbrListTimer -> TimerC.Timer[unique("Timer")];
	NeighborListM.SendNbrList -> SendComm3.AMSend;
	NeighborListM.RcvNbrList	-> ReceiveComm3.Receive;
	NeighborListM.SerialSendNbrList -> SerialSendComm6.AMSend;
	NeighborListM.SerialRcvNbrList	-> SerialReceiveComm6.Receive;

	NeighborListM.LocationMgrI -> LocationMgrC;
	NeighborListM.LocationUtilI -> LocationUtils;

	NeighborListM.MessageBufferI -> MessageBufferM;
	NeighborListM.Leds -> LedsC;
	NeighborListM.Packet -> ActiveMessageC;

	#if DEBUG_CLUSTERING
	NeighborListM.SendClusterDebugMsg -> Comm.SendMsg[AM_AGILLACLUSTERDEBUGMSG];
	NeighborListM.RcvClusterDebugMsg -> Comm.ReceiveMsg[AM_AGILLACLUSTERDEBUGMSG];
	#endif

	#if ENABLE_EXP_LOGGING
	NeighborListM.ExpLoggerI -> ExpLoggerC;
	#endif
}
