// $Id: AgentReceiverC.nc,v 1.3 2006/02/06 09:40:39 chien-liang Exp $

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

#include "AM.h"
#include "Agilla.h"
#include "MigrationMsgs.h"

/**
 * Wires up all of the components used for receiving
 * an agent.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
configuration AgentReceiverC {
	provides {
	interface StdControl;
	interface AgentReceiverI;	
	interface Init;
	}
}
implementation {
	components ReceiverCoordinatorM;
	components ReceiveStateM, ReceiveCodeM, ReceiveHeapM;
	components ReceiveOpStackM, ReceiveRxnM;
	
	components AgentMgrC, CodeMgrC, HeapMgrC, OpStackC, RxnMgrProxy;
	//components new TimerMilliC() as Timer0;
	//components new TimerMilliC() as Timer1; 
	components new TimerMilliC() as Timer2;
	components new NetworkInterfaceProxy(AM_AGILLASTATEMSG) as Comm1;
	components new NetworkInterfaceProxy(AM_AGILLAACKSTATEMSG) as Comm2;
	components new NetworkInterfaceProxy(AM_AGILLACODEMSG) as Comm3;
	components new NetworkInterfaceProxy(AM_AGILLAHEAPMSG) as Comm4;
	components new NetworkInterfaceProxy(AM_AGILLAOPSTACKMSG) as Comm5;
	components new NetworkInterfaceProxy(AM_AGILLARXNMSG) as Comm6;
	components new SerialNetworkInterfaceProxy(AM_AGILLASTATEMSG) as Comm7;
	components new SerialNetworkInterfaceProxy(AM_AGILLAACKSTATEMSG) as Comm8;
	components new SerialNetworkInterfaceProxy(AM_AGILLACODEMSG) as Comm9;
	components new SerialNetworkInterfaceProxy(AM_AGILLAHEAPMSG) as Comm10;
	components new SerialNetworkInterfaceProxy(AM_AGILLAOPSTACKMSG) as Comm11;
	components new SerialNetworkInterfaceProxy(AM_AGILLARXNMSG) as Comm12;

	components ActiveMessageC;
	components LedsC; // debug

	AgentReceiverI = ReceiverCoordinatorM;
	StdControl = ReceiverCoordinatorM;
	Init = ReceiverCoordinatorM;

	ReceiveStateM.Packet -> ActiveMessageC;
	ReceiverCoordinatorM.AgentMgrI -> AgentMgrC;
	ReceiverCoordinatorM.RecvTimeout2 -> Timer2;
	ReceiverCoordinatorM.Leds -> LedsC;

	ReceiveStateM.CoordinatorI -> ReceiverCoordinatorM;
	ReceiveStateM.AgentMgrI -> AgentMgrC;
	ReceiveStateM.Rcv_State -> Comm1.Receive[AM_AGILLASTATEMSG];
	ReceiveStateM.SerialRcv_State -> Comm7.Receive[AM_AGILLASTATEMSG];
	ReceiveStateM.Send_State_Ack -> Comm2.AMSend[AM_AGILLAACKSTATEMSG];
	ReceiveStateM.SerialSend_State_Ack -> Comm8.AMSend[AM_AGILLAACKSTATEMSG];
	ReceiveStateM.Leds -> LedsC;
	
	ReceiveCodeM.CoordinatorI -> ReceiverCoordinatorM;	
	ReceiveCodeM.CodeMgrI -> CodeMgrC;
	ReceiveCodeM.Rcv_Code -> Comm3.Receive[AM_AGILLACODEMSG];
	ReceiveCodeM.SerialRcv_Code -> Comm9.Receive[AM_AGILLACODEMSG];

	ReceiveHeapM.CoordinatorI -> ReceiverCoordinatorM;
	ReceiveHeapM.HeapMgrI -> HeapMgrC;
	ReceiveHeapM.Rcv_Heap -> Comm4.Receive[AM_AGILLAHEAPMSG];
	ReceiveHeapM.SerialRcv_Heap -> Comm10.Receive[AM_AGILLAHEAPMSG];
	
	ReceiveOpStackM.CoordinatorI -> ReceiverCoordinatorM;	
	ReceiveOpStackM.OpStackI -> OpStackC;
	ReceiveOpStackM.Rcv_OpStack -> Comm5.Receive[AM_AGILLAOPSTACKMSG];
	ReceiveOpStackM.SerialRcv_OpStack -> Comm11.Receive[AM_AGILLAOPSTACKMSG];
	
	ReceiveRxnM.CoordinatorI -> ReceiverCoordinatorM;
	ReceiveRxnM.RxnMgrI -> RxnMgrProxy;
	ReceiveRxnM.Rcv_Rxn -> Comm6.Receive[AM_AGILLARXNMSG];
	ReceiveRxnM.SerialRcv_Rxn -> Comm12.Receive[AM_AGILLARXNMSG];
}
