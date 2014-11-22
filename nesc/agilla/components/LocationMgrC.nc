// $Id: LocationMgrC.nc,v 1.6 2006/02/07 02:19:43 chien-liang Exp $

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
#include "SpaceLocalizer.h"

/**
 * Implements a virtual grid topology through which mote addresses may be
 * mapped to specific location and vice-versa.	Also interfaces with the
 * components that interact with the Cricket motes to obtain physical 
 * location data.
 *
 * @author Chien-Liang Fok
 */
configuration LocationMgrC {
	provides interface LocationMgrI; 
}
implementation {
	components MainC, LocationMgrM;


	
	components new AMSenderC(AM_AGILLAGRIDSIZEMSG) as SendComm1;
	components new AMReceiverC(AM_AGILLAGRIDSIZEMSG) as ReceiveComm1;
	components new SerialAMReceiverC(AM_AGILLAGRIDSIZEMSG) as SerialReceiveComm2;
	
	components new TimerMilliC() as GridSizeTimer;
	components LedsC;

	#if ENABLE_SPACE_LOCALIZER && defined(PLATFORM_MICA2)	 //Non utilizzato
	components LEDBlinkerC, SpaceLocalizerC, CC1000RadioC;
	#endif

	//Main.StdControl -> LocationMgrM;
	//Main.StdControl -> TimerC;
	MainC.SoftwareInit -> LocationMgrM.Init;
	
	#if ENABLE_SPACE_LOCALIZER && defined(PLATFORM_MICA2)	//Non utilizzato
	Main.StdControl -> CC1000RadioC;
	#endif

	LocationMgrI = LocationMgrM;
	
	// Grid size change
	LocationMgrM.GridSizeTimer -> GridSizeTimer;
	LocationMgrM.ReceiveGridSizeMsg -> ReceiveComm1.Receive;
	LocationMgrM.SendGridSizeMsg -> SendComm1.AMSend;
	LocationMgrM.SerialReceiveGridSizeMsg -> SerialReceiveComm2.Receive;

	#if ENABLE_SPACE_LOCALIZER && defined(PLATFORM_MICA2)	//non utilizzato
	LocationMgrM.SpaceLocalizerI -> SpaceLocalizerC;
	LocationMgrM.RadioControl -> CC1000RadioC;
	LocationMgrM.CC1000Control -> CC1000RadioC;
	//LocationMgrM.MoveTimer -> TimerC.Timer[unique("Timer")];
	LocationMgrM.LEDBlinkerI -> LEDBlinkerC;
	#endif
	
	LocationMgrM.Leds -> LedsC;
}
