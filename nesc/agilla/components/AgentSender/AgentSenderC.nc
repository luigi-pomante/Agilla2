// $Id: AgentSenderC.nc,v 1.5 2006/02/06 09:40:39 chien-liang Exp $

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
	components new AMSenderC(AM_AGILLASTATEMSG) as SendComm1;
	components new SerialAMSenderC(AM_AGILLASTATEMSG) as SerialSendComm11;

	components new AMReceiverC(AM_AGILLAACKSTATEMSG) as ReceiveComm2;
	components new SerialAMReceiverC(AM_AGILLAACKSTATEMSG) as SerialReceiveComm12;

	components new AMSenderC(AM_AGILLACODEMSG) as SendComm3;
	components new SerialAMSenderC(AM_AGILLACODEMSG) as SerialSendComm13;

	components new AMReceiverC(AM_AGILLAACKCODEMSG) as ReceiveComm4;
	components new SerialAMReceiverC(AM_AGILLAACKCODEMSG) as SerialReceiveComm14;

	components new AMSenderC(AM_AGILLAOPSTACKMSG) as SendComm5;
	components new SerialAMSenderC(AM_AGILLAOPSTACKMSG) as SerialSendComm15;

	components new AMReceiverC(AM_AGILLAACKOPSTACKMSG) as ReceiveComm6;
	components new SerialAMReceiverC(AM_AGILLAACKOPSTACKMSG) as SerialReceiveComm16;

	components new AMSenderC(AM_AGILLAHEAPMSG) as SendComm7;
	components new SerialAMSenderC(AM_AGILLAHEAPMSG) as SerialSendComm17;

	components new AMReceiverC(AM_AGILLAACKHEAPMSG) as ReceiveComm8;
	components new SerialAMReceiverC(AM_AGILLAACKHEAPMSG) as SerialReceiveComm18;

	components new AMSenderC(AM_AGILLARXNMSG) as SendComm9;
	components new SerialAMSenderC(AM_AGILLARXNMSG) as SerialSendComm19;

	components new AMReceiverC(AM_AGILLAACKRXNMSG) as ReceiveComm10;
	components new SerialAMReceiverC(AM_AGILLAACKRXNMSG) as SerialReceiveComm20;
	
	components new TimerMilliC() as Timer0;
	components TimerMilliP;
	components QueueProxy, ErrorMgrProxy, MessageBufferM;
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
	StdControl = MessageBufferM;
	
	Init = SendStateM;
	Init = SendCodeM;
	Init = SendOpStackM;
	Init = SendHeapM;
	Init = SendRxnM;
	Init = MessageBufferM;
	

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
	SendStateM.MessageBufferI -> MessageBufferM;
	SendCodeM.MessageBufferI -> MessageBufferM;
	SendOpStackM.MessageBufferI -> MessageBufferM;
	SendHeapM.MessageBufferI -> MessageBufferM;
	SendRxnM.MessageBufferI -> MessageBufferM;	

	// Wire up the Send message interfaces
	SendStateM.Send_State	 -> SendComm1.AMSend;
	SendStateM.SerialSend_State	 -> SerialSendComm11.AMSend;
	SendCodeM.Send_Code		 -> SendComm3.AMSend;
	SendCodeM.SerialSend_Code		 -> SerialSendComm13.AMSend;
	SendOpStackM.Send_OpStack -> SendComm5.AMSend;
	SendOpStackM.SerialSend_OpStack -> SerialSendComm15.AMSend;
	SendHeapM.Send_Heap		 -> SendComm7.AMSend;
	SendHeapM.SerialSend_Heap		 -> SerialSendComm17.AMSend;
	SendRxnM.Send_Rxn		 -> SendComm9.AMSend;
	SendRxnM.SerialSend_Rxn		 -> SerialSendComm19.AMSend;

	// Wire up the ReceiveMsg interfaces
	SendStateM.Rcv_Ack	 -> ReceiveComm2.Receive;
	SendStateM.SerialRcv_Ack	 -> SerialReceiveComm12.Receive;
	SendCodeM.Rcv_Ack	-> ReceiveComm4.Receive;
	SendCodeM.SerialRcv_Ack	-> SerialReceiveComm14.Receive;
	SendOpStackM.Rcv_Ack -> ReceiveComm6.Receive;
	SendOpStackM.SerialRcv_Ack -> SerialReceiveComm16.Receive;
	SendHeapM.Rcv_Ack	-> ReceiveComm8.Receive;
	SendHeapM.SerialRcv_Ack	-> SerialReceiveComm18.Receive;
	SendRxnM.Rcv_Ack	 -> ReceiveComm10.Receive;
	SendRxnM.SerialRcv_Ack	 -> SerialReceiveComm20.Receive;

	// Wire up the Ack Timer interfaces	

	SendStateM.Ack_Timer	 -> TimerMilliP.TimerMilli[SEND_ACK_TIMER];
	SendCodeM.Ack_Timer	-> TimerMilliP.TimerMilli[SEND_ACK_TIMER]; 
	SendOpStackM.Ack_Timer -> TimerMilliP.TimerMilli[SEND_ACK_TIMER]; 
	SendHeapM.Ack_Timer	-> TimerMilliP.TimerMilli[SEND_ACK_TIMER]; 
	SendRxnM.Ack_Timer	 -> TimerMilliP.TimerMilli[SEND_ACK_TIMER]; 

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
	SendStateM.Leds -> LedsC;	
	
	SendCodeM.CodeMgrI -> CodeMgrC;
	SendHeapM.HeapMgrI -> HeapMgrC;
	SendOpStackM.OpStackI -> OpStackC;
	SendRxnM.RxnMgrI -> RxnMgrProxy;
}
