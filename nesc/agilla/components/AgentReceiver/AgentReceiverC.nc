// $Id: AgentReceiverC.nc,v 1.6 2006/02/06 09:40:39 chien-liang Exp $

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
	components MessageBufferM;
	components AgentMgrC, CodeMgrC, HeapMgrC, OpStackC, RxnMgrProxy;
	components new AMReceiverC(AM_AGILLASTATEMSG) as ReceiveComm1;
	components new SerialAMReceiverC(AM_AGILLASTATEMSG) as SerialReceiveComm11;
	components new AMSenderC(AM_AGILLAACKSTATEMSG) as SendComm2;
	components new SerialAMSenderC(AM_AGILLAACKSTATEMSG) as SerialSendComm12;
	components new AMReceiverC(AM_AGILLACODEMSG) as ReceiveComm3;
	components new SerialAMReceiverC(AM_AGILLACODEMSG) as SerialReceiveComm13;	
	components new AMSenderC(AM_AGILLAACKCODEMSG) as SendComm4;
	components new SerialAMSenderC(AM_AGILLAACKCODEMSG) as SerialSendComm14;
	components new AMReceiverC(AM_AGILLAHEAPMSG) as ReceiveComm5;
	components new SerialAMReceiverC(AM_AGILLAHEAPMSG) as SerialReceiveComm15; 
	components new AMSenderC(AM_AGILLAACKHEAPMSG) as SendComm6;
	components new SerialAMSenderC(AM_AGILLAACKHEAPMSG) as SerialSendComm16;
	components new AMReceiverC(AM_AGILLAOPSTACKMSG) as ReceiveComm7;
	components new SerialAMReceiverC(AM_AGILLAOPSTACKMSG) as SerialReceiveComm17;
	components new AMSenderC(AM_AGILLAACKOPSTACKMSG) as SendComm8;
	components new SerialAMSenderC(AM_AGILLAACKOPSTACKMSG) as SerialSendComm18;
	components new AMReceiverC(AM_AGILLARXNMSG) as ReceiveComm9;
	components new SerialAMReceiverC(AM_AGILLARXNMSG) as SerialReceiveComm19;
	components new AMSenderC(AM_AGILLAACKRXNMSG) as SendComm10;
	components new SerialAMSenderC(AM_AGILLAACKRXNMSG) as SerialSendComm20;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	components ActiveMessageC;
	components LedsC;

	AgentReceiverI = ReceiverCoordinatorM;
	StdControl = ReceiverCoordinatorM;
	Init = ReceiverCoordinatorM;

	StdControl = MessageBufferM;
	Init = MessageBufferM;
	
	// Wire up the MessageBufferI interface
	ReceiveStateM.MessageBufferI -> MessageBufferM;
	ReceiveCodeM.MessageBufferI -> MessageBufferM;
	ReceiveOpStackM.MessageBufferI -> MessageBufferM;
	ReceiveHeapM.MessageBufferI -> MessageBufferM;
	ReceiveRxnM.MessageBufferI -> MessageBufferM;

	ReceiveStateM.Packet -> ActiveMessageC;
	ReceiveCodeM.Packet -> ActiveMessageC;
	ReceiveOpStackM.Packet -> ActiveMessageC;
	ReceiveHeapM.Packet -> ActiveMessageC;
	ReceiveRxnM.Packet -> ActiveMessageC;
	
	ReceiverCoordinatorM.AgentMgrI -> AgentMgrC;
	ReceiverCoordinatorM.RecvTimeout0 -> Timer0;
	ReceiverCoordinatorM.RecvTimeout1 -> Timer1;
	ReceiverCoordinatorM.RecvTimeout2 -> Timer2;
	ReceiverCoordinatorM.Leds -> LedsC;

	ReceiveStateM.CoordinatorI -> ReceiverCoordinatorM;
	ReceiveStateM.AgentMgrI -> AgentMgrC;
	ReceiveStateM.Rcv_State -> ReceiveComm1.Receive;
	ReceiveStateM.Send_State_Ack -> SendComm2.AMSend;
	ReceiveStateM.SerialRcv_State -> SerialReceiveComm11.Receive;
	ReceiveStateM.SerialSend_State_Ack -> SerialSendComm12.AMSend;
	ReceiveStateM.Leds -> LedsC;
	
	ReceiveCodeM.CoordinatorI -> ReceiverCoordinatorM;	
	ReceiveCodeM.CodeMgrI -> CodeMgrC;
	ReceiveCodeM.Rcv_Code -> ReceiveComm3.Receive;
	ReceiveCodeM.Send_Code_Ack -> SendComm4.AMSend;
	ReceiveCodeM.SerialRcv_Code -> SerialReceiveComm13.Receive;
	ReceiveCodeM.SerialSend_Code_Ack -> SerialSendComm14.AMSend;

	ReceiveHeapM.CoordinatorI -> ReceiverCoordinatorM;
	ReceiveHeapM.HeapMgrI -> HeapMgrC;
	ReceiveHeapM.Rcv_Heap -> ReceiveComm5.Receive;
	ReceiveHeapM.Send_Heap_Ack -> SendComm6.AMSend;
	ReceiveHeapM.SerialRcv_Heap -> SerialReceiveComm15.Receive;
	ReceiveHeapM.SerialSend_Heap_Ack -> SerialSendComm16.AMSend;
	
	ReceiveOpStackM.CoordinatorI -> ReceiverCoordinatorM;	
	ReceiveOpStackM.OpStackI -> OpStackC;
	ReceiveOpStackM.Rcv_OpStack -> ReceiveComm7.Receive;
	ReceiveOpStackM.Send_OpStack_Ack -> SendComm8.AMSend;
	ReceiveOpStackM.SerialRcv_OpStack -> SerialReceiveComm17.Receive;
	ReceiveOpStackM.SerialSend_OpStack_Ack -> SerialSendComm18.AMSend;

	ReceiveRxnM.CoordinatorI -> ReceiverCoordinatorM;
	ReceiveRxnM.RxnMgrI -> RxnMgrProxy;
	ReceiveRxnM.Rcv_Rxn -> ReceiveComm9.Receive;
	ReceiveRxnM.Send_Rxn_Ack -> SendComm10.AMSend;
	ReceiveRxnM.SerialRcv_Rxn -> SerialReceiveComm19.Receive;
	ReceiveRxnM.SerialSend_Rxn_Ack -> SerialSendComm20.AMSend;
}
