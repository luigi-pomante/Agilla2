// $Id: ResetMgrC.nc,v 1.9 2006/04/07 01:14:35 borndigerati Exp $

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

/**
 * @author Chien-Liang Fok
 */
configuration ResetMgrC {
	provides {
	interface StdControl;
	interface Init;
	interface ResetMgrI;
	}
}

implementation {
	components ResetMgrM, ResetC;
	components AddressMgrC;
	components new AMSenderC(AM_AGILLARESETMSG) as SendComm;
	components new AMReceiverC(AM_AGILLARESETMSG) as ReceiveComm;
	components new SerialAMReceiverC(AM_AGILLARESETMSG) as SerialReceiveComm1;
	components LEDBlinkerC;
	components ErrorMgrProxy;
	components AgentMgrC, TupleSpaceProxy;
	components MessageBufferM, LedsC;

	#if ENABLE_CLUSTERING
	components ClusterheadDirectoryM;
	#endif

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#endif

	StdControl = ResetMgrM;
	Init = ResetMgrM;
	Init = LEDBlinkerC;

	ResetMgrI = ResetMgrM;

	ResetMgrM.TupleSpaceI -> TupleSpaceProxy;
	ResetMgrM.AgentMgrI -> AgentMgrC;
	ResetMgrM.Reset -> ResetC;
	ResetMgrM.AddressMgrI -> AddressMgrC;
	ResetMgrM.ErrorMgrI -> ErrorMgrProxy;
	ResetMgrM.ReceiveReset -> ReceiveComm.Receive;
	ResetMgrM.SerialReceiveReset -> SerialReceiveComm1.Receive;
	ResetMgrM.SendReset -> SendComm.AMSend;
	ResetMgrM.LEDBlinkerI -> LEDBlinkerC;
	ResetMgrM.MessageBufferI -> MessageBufferM;

	#if ENABLE_EXP_LOGGING
	ResetMgrM.ExpLoggerI -> ExpLoggerC;
	#endif
	ResetMgrM.Leds -> LedsC;
	#if ENABLE_CLUSTERING
	ResetMgrM.CHDir -> ClusterheadDirectoryM;
	#endif
}
