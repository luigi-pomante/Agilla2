// $Id: AgentSenderC.nc,v 1.2 2006/02/06 09:40:39 chien-liang Exp $

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
#include "MigrationMsgs.h"

/**
 * Wires up all of the components used for sending
 * an agent to a remote node.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
configuration AgentSenderC {
	provides {
	interface AgentSenderI;
	interface StdControl;
	interface Init;
	}
}
implementation {
	components SenderCoordinatorM;
	components SendStateM, SendCodeM, SendOpStackM, SendHeapM, SendRxnM;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;

	components new NetworkInterfaceProxy(AM_AGILLASTATEMSG) as Comm1;
	components new SerialNetworkInterfaceProxy(AM_AGILLASTATEMSG) as Comm12;
	components new NetworkInterfaceProxy(AM_AGILLAACKSTATEMSG) as Comm2;
	components new SerialNetworkInterfaceProxy(AM_AGILLAACKSTATEMSG) as Comm7;
	components new NetworkInterfaceProxy(AM_AGILLACODEMSG) as Comm3;
	components new SerialNetworkInterfaceProxy(AM_AGILLACODEMSG) as Comm8;
	components new NetworkInterfaceProxy(AM_AGILLAOPSTACKMSG) as Comm4;
	components new SerialNetworkInterfaceProxy(AM_AGILLAOPSTACKMSG) as Comm10;
	components new NetworkInterfaceProxy(AM_AGILLAHEAPMSG) as Comm5;
	components new SerialNetworkInterfaceProxy(AM_AGILLAHEAPMSG) as Comm9;
	components new NetworkInterfaceProxy(AM_AGILLARXNMSG) as Comm6;
	components new SerialNetworkInterfaceProxy(AM_AGILLARXNMSG) as Comm11;
	
	components QueueProxy, ErrorMgrProxy;
	components CodeMgrC, HeapMgrC, OpStackC, RxnMgrProxy;
	components LedsC;
	components NoLedsC;
	components ActiveMessageC;
	
	AgentSenderI = SenderCoordinatorM;
	StdControl = SenderCoordinatorM;
	Init = SenderCoordinatorM;
 
	StdControl = SendStateM;
	StdControl = SendCodeM;
	StdControl = SendOpStackM;
	StdControl = SendHeapM;
	StdControl = SendRxnM;

	Init = SendStateM;
	Init = SendCodeM;
	Init = SendOpStackM;
	Init = SendHeapM;
	Init = SendRxnM;
	

	StdControl = RxnMgrProxy;
	
	SenderCoordinatorM.SendState	 -> SendStateM;
	SenderCoordinatorM.SendCode	-> SendCodeM;
	SenderCoordinatorM.SendOpStack -> SendOpStackM;
	SenderCoordinatorM.SendHeap	-> SendHeapM;
	SenderCoordinatorM.SendRxn	 -> SendRxnM;

	SenderCoordinatorM.Retry_Timer -> Timer0;
	
	SenderCoordinatorM.HeapMgrI -> HeapMgrC;
	SenderCoordinatorM.OpStackI -> OpStackC;
	SenderCoordinatorM.RxnMgrI -> RxnMgrProxy;
	SenderCoordinatorM.ErrorMgrI -> ErrorMgrProxy;
	
	// Wire up the Leds interface;
	SenderCoordinatorM.Leds -> NoLedsC;
	SendCodeM.Leds -> LedsC;
 
	// Wire up the MessageBufferI interface
	SendStateM.MessageBufferI -> SenderCoordinatorM;
	SendCodeM.MessageBufferI -> SenderCoordinatorM;
	SendOpStackM.MessageBufferI -> SenderCoordinatorM;
	SendHeapM.MessageBufferI -> SenderCoordinatorM;
	SendRxnM.MessageBufferI -> SenderCoordinatorM;	

	// Wire up the Send message interfaces
	SendStateM.Send_State	 -> Comm1.AMSend[AM_AGILLASTATEMSG];
	SendStateM.SerialSend_State	 -> Comm12.AMSend[AM_AGILLASTATEMSG];
	SendCodeM.Send_Code		 -> Comm3.AMSend[AM_AGILLACODEMSG];
	SendCodeM.SerialSend_Code		 -> Comm8.AMSend[AM_AGILLACODEMSG];
	SendOpStackM.Send_OpStack -> Comm4.AMSend[AM_AGILLAOPSTACKMSG];
	SendOpStackM.SerialSend_OpStack -> Comm10.AMSend[AM_AGILLAOPSTACKMSG];
	SendHeapM.Send_Heap		 -> Comm5.AMSend[AM_AGILLAHEAPMSG];
	SendHeapM.SerialSend_Heap		 -> Comm9.AMSend[AM_AGILLAHEAPMSG];
	SendRxnM.Send_Rxn		 -> Comm6.AMSend[AM_AGILLARXNMSG];
	SendRxnM.SerialSend_Rxn		 -> Comm11.AMSend[AM_AGILLARXNMSG];

	// Wire up the ReceiveMsg interfaces
	SendStateM.Rcv_Ack	 -> Comm2.Receive[AM_AGILLAACKSTATEMSG];
	SendStateM.SerialRcv_Ack	 -> Comm7.Receive[AM_AGILLAACKSTATEMSG];
	/*SendCodeM.Rcv_Ack	-> Comm.ReceiveMsg[AM_AGILLAACKCODEMSG];
	SendOpStackM.Rcv_Ack -> Comm.ReceiveMsg[AM_AGILLAACKOPSTACKMSG];
	SendHeapM.Rcv_Ack	-> Comm.ReceiveMsg[AM_AGILLAACKHEAPMSG];
	SendRxnM.Rcv_Ack	 -> Comm.ReceiveMsg[AM_AGILLAACKRXNMSG];*/

	// Wire up the Ack Timer interfaces
	SendStateM.Ack_Timer	 -> Timer1;
	/*SendCodeM.Ack_Timer	-> TimerC.Timer[unique("Timer")];
	SendOpStackM.Ack_Timer -> TimerC.Timer[unique("Timer")];
	SendHeapM.Ack_Timer	-> TimerC.Timer[unique("Timer")];
	SendRxnM.Ack_Timer	 -> TimerC.Timer[unique("Timer")];*/

	SendStateM.Packet -> ActiveMessageC;
	SendCodeM.Packet -> ActiveMessageC;
	SendOpStackM.Packet -> ActiveMessageC;
	SendHeapM.Packet -> ActiveMessageC;
	SendRxnM.Packet -> ActiveMessageC;
	
	// Wire up the Error interfaces
	SendStateM.Error	 -> ErrorMgrProxy;
	SendCodeM.Error	-> ErrorMgrProxy;
	SendOpStackM.Error -> ErrorMgrProxy;
	SendHeapM.Error	-> ErrorMgrProxy;
	SendRxnM.Error	 -> ErrorMgrProxy;

	// Component-specific interfaces
	SendStateM.HeapMgrI -> HeapMgrC;
	SendStateM.RxnMgrI	-> RxnMgrProxy;	 
	
	SendCodeM.CodeMgrI -> CodeMgrC;
	SendHeapM.HeapMgrI -> HeapMgrC;
	
	SendOpStackM.OpStackI -> OpStackC;
	
	SendRxnM.RxnMgrI -> RxnMgrProxy;
}
