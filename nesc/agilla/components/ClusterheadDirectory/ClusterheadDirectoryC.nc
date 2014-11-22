// $Id: ClusterheadDirectoryC.nc,v 1.2 2006/04/28 12:54:55 chien-liang Exp $

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
	* The Clusterhead Directory maintains clusterhead information like
	* bounding box and agents detected by cluster members and itself. This
	* module handles queries from agents and either replies to the query
	* if it has the required information or passes the query upto the GW
	* and then passes the query reply to cluster member on receiving it
	* from the GW.
	*
	* @author Sangeeta Bhattacharya
 */

#include "Agilla.h"
#include "Clustering.h"
#include "LocationDirectory.h"

configuration ClusterheadDirectoryC {
	provides {
	interface StdControl;
	interface ClusterheadDirectoryI;
	}
}
implementation {
	components Main;
	components ClusterheadDirectoryM, AddressMgrC, LedsC;
	components NetworkInterfaceProxy as Comm;
	components TimerC, SimpleTime;
	components RandomLFSR, LocationUtils, LocationMgrC, MessageBufferM, NeighborListC;

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#endif


	Main.StdControl -> SimpleTime;

	//Main.StdControl -> TimerC;
	Main.StdControl -> MessageBufferM;

	StdControl = ClusterheadDirectoryM;
	ClusterheadDirectoryI = ClusterheadDirectoryM;
	ClusterheadDirectoryM.Random -> RandomLFSR;
	ClusterheadDirectoryM.AddressMgrI -> AddressMgrC;
	ClusterheadDirectoryM.Time -> SimpleTime;
	ClusterheadDirectoryM.TimeUtil -> SimpleTime;
	ClusterheadDirectoryM.LocationMgrI -> LocationMgrC;
	ClusterheadDirectoryM.LocationUtilI -> LocationUtils;
	ClusterheadDirectoryM.MessageBufferI -> MessageBufferM;
	ClusterheadDirectoryM.NeighborListI -> NeighborListC;
	ClusterheadDirectoryM.ClusteringI -> NeighborListC;
	ClusterheadDirectoryM.Leds -> LedsC;

	/**************************************************************/
	/*						TIMERS								*/
	/**************************************************************/

	ClusterheadDirectoryM.ClusterTimer -> TimerC.Timer[unique("Timer")];
	ClusterheadDirectoryM.AgentExpTimer -> TimerC.Timer[unique("Timer")];

	/**************************************************************/
	/*					Message Handlers						*/
	/**************************************************************/

	ClusterheadDirectoryM.SendClusterMsg -> Comm.SendMsg[AM_AGILLACLUSTERMSG];
	ClusterheadDirectoryM.RcvClusterMsg -> Comm.ReceiveMsg[AM_AGILLACLUSTERMSG];

	#if ENABLE_EXP_LOGGING
	ClusterheadDirectoryM.ExpLoggerI -> ExpLoggerC;
	#endif
}
