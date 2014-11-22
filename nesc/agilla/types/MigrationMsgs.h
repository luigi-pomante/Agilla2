// $Id: MigrationMsgs.h,v 1.13 2006/03/27 00:38:21 chien-liang Exp $

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
#include "TupleSpace.h"
#include "Timer.h"

#ifndef AGILLA_MIGRATION_MSGS_H_INCLUDED
#define AGILLA_MIGRATION_MSGS_H_INCLUDED

#define AGILLA_ACCEPT 1
#define AGILLA_REJECT 0

enum {
	AGILLA_HEAP_MSG_SIZE = 24,
	AGILLA_OS_MSG_SIZE = 23,
};

enum {
	//SEND_ACK_TIMER=unique("Timer"),
	SEND_ACK_TIMER=unique(UQ_TIMER_MILLI),
};

enum {	/* A third value for result_t */
	REJECT = 3,
};

// Agent migration state
typedef enum {
	AGILLA_RECEIVED_NOTHING = 0,
	AGILLA_RECEIVED_CODE = 1,
	AGILLA_RECEIVED_STATE = 2,
	AGILLA_RECEIVED_OPSTACK = 4,
	AGILLA_RECEIVED_HEAP = 8,
	AGILLA_RECEIVED_RXN = 16,
	AGILLA_AGENT_READY = AGILLA_RECEIVED_CODE | AGILLA_RECEIVED_STATE |
						 AGILLA_RECEIVED_OPSTACK | AGILLA_RECEIVED_HEAP |
						 AGILLA_RECEIVED_RXN
} AgillaAgentIntegrity;

//------------------------------------------------------------------------------
// Active message port numbers
enum {
	AM_AGILLASTATEMSG = 0x10,
	AM_AGILLACODEMSG = 0x11,
	AM_AGILLAHEAPMSG = 0x12,
	AM_AGILLAOPSTACKMSG = 0x13,
	AM_AGILLARXNMSG = 0X14,
	AM_AGILLAACKSTATEMSG = 0x15,
	AM_AGILLAACKCODEMSG = 0x16,
	AM_AGILLAACKHEAPMSG = 0x17,
	AM_AGILLAACKOPSTACKMSG = 0x18,
	AM_AGILLAACKRXNMSG = 0x19,
};

typedef struct AgillaAgentInfo {
	AgillaAgentID id;
	uint16_t reply, dest, numHpMsgs, nCBlocks, nRxnMsgs;
	uint8_t integrity;
	AgillaAgentContext* context;
} AgillaAgentInfo;

//------------------------------------------------------------------------------
// Agent migration message contents
typedef nx_struct AgillaStateMsg {
	nx_uint16_t replyAddr;		 // 2: original sender
	AgillaAgentID id;			 // 2: the ID of the incomming agent
	nx_uint16_t dest;				// 2: the ultimate destination
	nx_uint8_t op;				 // 1: smove, wmove, sclone, or wclone
	nx_uint8_t	sp;				// 1: stack pointer
	nx_uint16_t pc;				// 2: program counter
	nx_uint16_t condition;		 // 2: condition code
	nx_uint16_t codeSize;			// 2: number of bytes of code
	nx_uint8_t numHpMsgs;			// 1: the number of heap messages
	nx_uint8_t numRxnMsgs;		 // 1: the number of reaction messages
	AgillaValue desc;			// 2: a description of the agent
} AgillaStateMsg; // 18 bytes

// The state msg needs and ACK to tell the sending node whether it is
// capable of receiving an agent.	If REJECT, the sender will abort.
typedef nx_struct AgillaAckStateMsg {
	//uint16_t dest;	// the final destination
	AgillaAgentID id;
	nx_uint16_t	accept;	// AGILLA_ACCEPT or AGILLA_REJECT
} AgillaAckStateMsg; // 4 bytes

typedef nx_struct AgillaCodeMsg {
	AgillaAgentID id;					 // 2
	nx_uint16_t msgNum;						// 2
	nx_uint8_t code[AGILLA_CODE_BLOCK_SIZE]; // 22
} AgillaCodeMsg;	// 26 bytes

typedef nx_struct AgillaAckCodeMsg {
	AgillaAgentID id;
	nx_uint16_t	accept;	// AGILLA_ACCEPT or AGILLA_REJECT
	nx_uint16_t msgNum;
} AgillaAckCodeMsg; // 6 bytes

typedef nx_struct AgillaHeapMsg {
	AgillaAgentID id;	// the ID of the migrating agent
	nx_uint8_t data[AGILLA_HEAP_MSG_SIZE]; // 24: [addr][type][dat],...
} AgillaHeapMsg; // 26 bytes

typedef nx_struct AgillaAckHeapMsg {
	AgillaAgentID id;
	nx_uint8_t	accept;	// AGILLA_ACCEPT or AGILLA_REJECT
	nx_uint8_t addr1;	// The first heap address
} AgillaAckHeapMsg; // 4 bytes

typedef nx_struct AgillaOpStackMsg {
	AgillaAgentID id;
	nx_uint8_t startAddr;	 // the starting address of the data
	nx_uint8_t data[AGILLA_OS_MSG_SIZE];	//[dat],[type]...
} AgillaOpStackMsg; // 26 bytes

typedef nx_struct AgillaAckOpStackMsg {
	AgillaAgentID id;
	nx_uint8_t accept;	 // AGILLA_ACCEPT or AGILLA_REJECT
	nx_uint8_t startAddr;	// the starting address of the data
} AgillaAckOpStackMsg; // 4 bytes

typedef nx_struct AgillaRxnMsg {
	nx_uint16_t msgNum;
	Reaction rxn;			 // id, pc, tuple
} AgillaRxnMsg;	// 26 bytes	
//} __attribute__((packed)) AgillaRxnMsg;	// 27 bytes

typedef nx_struct AgillaAckRxnMsg {
	AgillaAgentID id;
	nx_uint8_t	accept;	// AGILLA_ACCEPT or AGILLA_REJECT
	nx_uint8_t msgNum;	 // misc info (e.g., which code msg or starting heap address)
} AgillaAckRxnMsg;	// 4 bytes

#endif

