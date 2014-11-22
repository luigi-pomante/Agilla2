// $Id: AgentMgrC.nc,v 1.11 2006/04/09 00:02:56 chien-liang Exp $

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
 * Manages agent contexts.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
configuration AgentMgrC {
	provides {
	interface StdControl;
	interface Init;
	interface AgentMgrI;
	}
}
implementation {
	components AgentMgrM, AgillaEngineC, CodeMgrC, NeighborListProxy;
	
	#if OMIT_AGENT_SENDER
	components AgentSenderDummy as AgentSender;	
	#else
	components AgentSenderC as AgentSender;
	#endif
	
	#if OMIT_AGENT_RECEIVER
	components AgentReceiverDummy as AgentReceiver;
	#else
	components AgentReceiverC as AgentReceiver;
	#endif
	
	components SystemTSMgrC, TupleUtilC, RxnMgrProxy;
	components OpStackC, HeapMgrC;	
	components LEDBlinkerC;
	components LocationMgrC;

	components LocationReporterC;
	components new TimerMilliC() as Timer;

	#if ENABLE_EXP_LOGGING
	components ExpLoggerC;
	#endif	
	
	
	AgentMgrI = AgentMgrM;
	
	StdControl = AgentMgrM;	//fatto (stdcontrol vuoto)
	StdControl = AgentSender;	//fatto
	StdControl = AgentReceiver;	//fatto
	StdControl = RxnMgrProxy;	//fatto


	StdControl = LocationReporterC;	//fatto

	Init = AgentMgrM;
	Init = AgentSender;
	Init = AgentReceiver;	
	Init = RxnMgrProxy;
	Init = LEDBlinkerC;
	//Init = TimerC;
	Init = LocationReporterC;
	
	AgentMgrM.CodeMgrI -> CodeMgrC;
	AgentMgrM.AgentExecutorI -> AgillaEngineC;
	AgentMgrM.AgentSenderI -> AgentSender;
	AgentMgrM.AgentReceiverI -> AgentReceiver;
	AgentMgrM.SystemTSMgrI -> SystemTSMgrC;
	AgentMgrM.TupleUtilI -> TupleUtilC;	
	AgentMgrM.OpStackI -> OpStackC;
	AgentMgrM.HeapMgrI -> HeapMgrC;
	AgentMgrM.RxnMgrI -> RxnMgrProxy;
	AgentMgrM.NeighborListI -> NeighborListProxy;
	AgentMgrM.LocationMgrI -> LocationMgrC;
	
	AgentMgrM.LEDBlinkerI -> LEDBlinkerC;
	//AgentMgrM.RadioControl -> CC1000RadioC.StdControl;	

	AgentMgrM.LocationReporterI -> LocationReporterC;

	AgentMgrM.LocationUpdateTimer -> Timer;

	#if ENABLE_EXP_LOGGING
	AgentMgrM.ExpLoggerI -> ExpLoggerC;
	#endif	 
}
