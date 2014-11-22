// $Id: Agilla.h,v 1.23 2006/04/27 23:53:19 chien-liang Exp $

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

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University	of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.	THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *	IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.	By
 *	downloading, copying, installing or using the software you agree to
 *	this license.	If you do not agree to this license, do not download,
 *	install, copy or use the software.
 *
 *	Intel Open Source License
 *
 *	Copyright (c) 2002 Intel Corporation
 *	All rights reserved.
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are
 *	met:
 *
 *	Redistributions of source code must retain the above copyright
 *	notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *	notice, this list of conditions and the following disclaimer in the
 *	documentation and/or other materials provided with the distribution.
 *		Neither the name of the Intel Corporation nor the names of its
 *	contributors may be used to endorse or promote products derived from
 *	this software without specific prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *	``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *	PARTICULAR PURPOSE ARE DISCLAIMED.	IN NO EVENT SHALL THE INTEL OR ITS
 *	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */
/* Authors:	 Philip Levis
 * History:	 created 4/18/2002
 *			ported to nesC 6/19/2002
 */

/**
 * @author Philip Levis
 * @author Chien-Liang Fok
 */

#ifndef AGILLA_TYPES_H_INCLUDED
#define AGILLA_TYPES_H_INCLUDED

#include "list.h"
#include <stddef.h>
#include "AM.h"
#include "TosTime.h"

#define ENABLE_DELUGE 0

// LED migration indicator
#define ARRIVAL_LED_TIME 1024

// defined reserved locations
#define UART_X 0
#define UART_Y 1
#define BCAST_X 0
#define BCAST_Y 2

#define NO_GW 0xffff

enum {
	AM_UART_ADDR = 0x007e,	 
};

/**
 * Uncomment this to report all errors.	These include
 * errors generated due to queues being overflowed
 * that would otherwise be ignored.
 */
//#define REPORT_ALL_ERRORS

enum {
	AGILLA_OPSTACK_SIZE = 105,//150, // size of the operand stack in bytes
	AGILLA_HEAP_SIZE = 20,	// size of heap on each agent
	AGILLA_HEAP_LOC_INDEX = 15,	// the position on the heap used to choose between X, Y, or both coordinations
	AGILLA_CODE_BLOCK_SIZE = 22,	// the size of each code block
} AgillaSizeConstants;

typedef enum{
	UNSPECIFIED = 0,
	CARGO = 1,
	FIRE = 2,
} AgillaAgentType;

typedef enum {
	AGILLA_STATE_HALT = 0,		// no agent
	AGILLA_STATE_WAITING = 1,
	AGILLA_STATE_RUN = 2,
	AGILLA_STATE_ARRIVING = 3,
	AGILLA_STATE_LEAVING = 4,
	AGILLA_STATE_BLOCKED = 5,
	AGILLA_STATE_READY = 6,
	AGILLA_STATE_SLEEPING = 7,	// sleeping waiting for a reaction
	AGILLA_STATE_TS_WAIT = 8,
} AgillaAgentContextState;

typedef enum {
	AGILLA_RSTATE_IDLE = 0,
	AGILLA_RSTATE_EXEC = 1,	// executing a reaction
} AgillaRxnState;


typedef enum {
	AGILLA_ERROR_TRIGGERED =	0,
	AGILLA_ERROR_INVALID_RUNNABLE =	1,
	AGILLA_ERROR_STACK_OVERFLOW =	2,
	AGILLA_ERROR_STACK_UNDERFLOW =	3,
	//AGILLA_ERROR_TS_FULL =	4,
	AGILLA_ERROR_AGENT_NOT_RUNNING =	5,
	AGILLA_ERROR_INDEX_OUT_OF_BOUNDS =	6,
	AGILLA_ERROR_INSTRUCTION_RUNOFF =	7,
	AGILLA_ERROR_INVALID_FIELD_TYPE =	8,
	AGILLA_ERROR_CODE_OVERFLOW =	9,
	AGILLA_ERROR_ILLEGAL_TUPLE_NAME = 10,
	AGILLA_ERROR_QUEUE_ENQUEUE = 11,
	AGILLA_ERROR_QUEUE_DEQUEUE = 12,
	AGILLA_ERROR_QUEUE_REMOVE = 13,
	AGILLA_ERROR_QUEUE_INVALID = 14,
	AGILLA_ERROR_RSTACK_OVERFLOW = 15,
	AGILLA_ERROR_RSTACK_UNDERFLOW = 16,
	AGILLA_ERROR_INVALID_ACCESS = 17,
	AGILLA_ERROR_TYPE_CHECK = 18,
	AGILLA_ERROR_INVALID_TYPE = 19,
	AGILLA_ERROR_INVALID_LOCK = 20,
	AGILLA_ERROR_INVALID_INSTRUCTION = 21,
	AGILLA_ERROR_INVALID_SENSOR = 22,
	AGILLA_ERROR_ILLEGAL_CODE_BLOCK = 23,
	AGILLA_ERROR_ILLEGAL_FIELD_TYPE = 24,
	AGILLA_ERROR_INVALID_FIELD_COUNT = 25,
	AGILLA_ERROR_GET_FIELD_INVALID_TYPE = 26,
// AGILLA_ERROR_UNKOWN_AGENT_CODE = 27,
	AGILLA_ERROR_UNKOWN_AGENT_HEAP = 28,
	AGILLA_ERROR_UNKOWN_AGENT_OPSTACK = 29,
	AGILLA_ERROR_REQUEST_Q_FULL = 30,
	AGILLA_ERROR_OPrtsM_AGENT_NULL = 31,
	AGILLA_ERROR_OPrtsM_AGENTID_MISMATCH = 32,
	AGILLA_ERROR_OPrtsM_INSTR_MISMATCH = 33,
	AGILLA_ERROR_OPrtsM_NO_RESPONSE = 34,
	AGILLA_ERROR_RCV_BUFF_FULL = 35,
	AGILLA_ERROR_UNKNOWN_MSG_TYPE = 36,
	AGILLA_ERROR_TUPLE_SIZE = 37,
	AGILLA_ERROR_SEND_BUFF_FULL = 38,
	AGILLA_ERROR_NO_CLOSER_NEIGHBOR = 39,
	AGILLA_ERROR_DROPPED_RESULTS_MESSAGE = 40,
	AGILLA_ERROR_OPrtsM_BOUNCE_QUEUE_FULL = 41,
	AGILLA_ERROR_RXN_NOT_FOUND = 42,
	AGILLA_ERROR_TASK_QUEUE_FULL = 43,
	AGILLA_ERROR_INVALID_VARIABLE_SIZE = 44,
	AGILLA_ERROR_OPSLEEP_BUFFER_UNDERFLOW = 45,
	AGILLA_ERROR_GET_FREE_BLOCK = 46,
	AGILLA_ERROR_ILLEGAL_RXN_OP = 47,
} ErrorICode;

typedef enum {
	JARG_MASK = 0x1f
} AgillaInstructionMasks;

typedef enum {
	AGILLA_TYPE_INVALID = 0,
	AGILLA_TYPE_VALUE = 1,
	AGILLA_TYPE_READING = 2,
	AGILLA_TYPE_STRING = 4,
	AGILLA_TYPE_TYPE = 8,
	AGILLA_TYPE_STYPE = 16,
	AGILLA_TYPE_AGENTID = 32,
	AGILLA_TYPE_LOCATION = 64,
	AGILLA_TYPE_ANY = AGILLA_TYPE_VALUE | AGILLA_TYPE_READING |
						 AGILLA_TYPE_STRING | AGILLA_TYPE_TYPE |
						 AGILLA_TYPE_STYPE | AGILLA_TYPE_AGENTID | AGILLA_TYPE_LOCATION,
} AgillaDataType;

typedef enum {
	AGILLA_VAR_I = AGILLA_TYPE_INVALID,
	AGILLA_VAR_A = AGILLA_TYPE_AGENTID,
	AGILLA_VAR_S = AGILLA_TYPE_STRING,
	AGILLA_VAR_R = AGILLA_TYPE_READING,
	AGILLA_VAR_T = AGILLA_TYPE_TYPE | AGILLA_TYPE_STYPE,
	AGILLA_VAR_V = AGILLA_TYPE_VALUE,
	AGILLA_VAR_L = AGILLA_TYPE_LOCATION,

	// value or reading
	AGILLA_VAR_VR = AGILLA_VAR_R | AGILLA_VAR_V,

	// string, reading, value, or location
	AGILLA_VAR_SRVL = AGILLA_VAR_S | AGILLA_VAR_R | AGILLA_VAR_V | AGILLA_VAR_L,

	// string, reading, value, or invalid
	AGILLA_VAR_SRVLI = AGILLA_VAR_SRVL | AGILLA_VAR_I,

	// agentID, string, reading, value, location
	AGILLA_VAR_ASRVL = AGILLA_VAR_SRVL | AGILLA_VAR_A,

	// agentID, string,	reading,	type, value, and location
	AGILLA_VAR_ASRTVL = AGILLA_VAR_SRVL | AGILLA_VAR_A | AGILLA_VAR_T,
} AgillaDataCondensed;

typedef enum {
	AGILLA_STYPE_ANY = 0,
	AGILLA_STYPE_SOUNDER = 0,	// both are 0 b/c sounder can never be tuple field.
	AGILLA_STYPE_PHOTO = 1,
	AGILLA_STYPE_TEMP = 2,
	AGILLA_STYPE_MIC = 3,
	AGILLA_STYPE_MAGX = 4,
	AGILLA_STYPE_MAGY = 5,
	AGILLA_STYPE_ACCELX = 6,
	AGILLA_STYPE_ACCELY = 7,
} AgillaSensorType;

typedef struct Queue {
	list_t queue;
} Queue;

typedef nx_struct AgillaLocation {
	nx_uint16_t x;
	nx_uint16_t y;
} AgillaLocation;

typedef nx_struct AgillaAgentID {
	nx_uint16_t id;				// unique ID
} AgillaAgentID;

typedef nx_struct AgillaString {
	nx_uint16_t string;
} AgillaString;

typedef nx_struct AgillaReading {
	nx_uint16_t type;	// the sensor ID
	nx_uint16_t reading;
} AgillaReading;

typedef nx_struct AgillaRType {	// reading type
	nx_uint16_t stype;	// sensor type
} AgillaRType;

typedef nx_struct AgillaType {
	nx_uint16_t type;
} AgillaType;

typedef nx_struct AgillaValue {
	nx_int16_t value;
} AgillaValue;

typedef struct AgillaVariable {
	uint8_t vtype;	// variable type
	union {
	AgillaType		type;
	AgillaRType		 rtype;
	AgillaAgentID	 id;
	AgillaString		string;
	AgillaReading	 reading;
	AgillaValue		 value;
	AgillaLocation	loc;
	};
} AgillaVariable;

typedef struct {
	uint8_t sp;
	uint8_t byte[AGILLA_OPSTACK_SIZE];
} AgillaOperandStack;

typedef struct {
	AgillaVariable pos[AGILLA_HEAP_SIZE];
} AgillaHeap;

typedef struct {
	AgillaAgentID		 id;		 // a unique agent ID
	uint16_t				pc;		 // the program counter
	uint16_t				codeSize;	 // the number of bytes of instructions
	uint16_t				condition;	// the condition code
	AgillaOperandStack	opStack;	// the operand stack
	AgillaHeap			heap;		 // the heap
	AgillaValue			 desc;		 // a description of the agent

	// The following are used internally by the VM and not migrated
	uint8_t				 rstate;		// possible values: AGILLA_RSTATE_IDLE, AGILLA_RSTATE_EXEC
	uint8_t				 pstate;		// the previous state of the agent prior to executing rxn
	int16_t				 sBlock;		// starting code block ID
	uint8_t				 state;		 // state of the agent (AGILLA_STATE_IDLE)
	list_link_t			 link;		// allows this struct to be inserted into a queue
	Queue*				queue;		 // allows this struct to be inserted into a queue
} AgillaAgentContext;


//--------------------------------------------------------------------------------------
// Message definitions

enum {
	AM_AGILLAERRORMSG = 0x20,
	AM_AGILLARESETMSG = 0x21,
	AM_AGILLABEACONMSG = 0x22,
	AM_AGILLAEXPMSG = 0x23,
	//AM_AGILLASTARTEXPMSG = 0x24,
	AM_AGILLAADDRESSMSG = 0x25,
	AM_AGILLAGETNBRMSG = 0x26,
	AM_AGILLANBRMSG = 0x27,
	AM_AGILLASETBSMSG = 0x28,
	AM_AGILLAGRIDSIZEMSG = 0x29,
	AM_AGILLABEACONBSMSG = 0x40,
	AM_AGILLAADDRESSACKMSG = 0x41,
};

/**
 * This message is broadcasted across all nodes similar to how
 * a reset message is.	It is used to change the grid size of
 * a network.
 */
typedef nx_struct AgillaGridSizeMsg {
	nx_uint16_t numCol;
} AgillaGridSizeMsg; // 2 bytes

typedef nx_struct AgillaErrorMsg {
	AgillaAgentID id;	 // uint16_t
	nx_uint16_t src;
	nx_uint8_t cause;
	nx_uint16_t pc;
	nx_uint8_t instr;
	nx_uint8_t sp;
	nx_uint8_t dummy; // to make it an even number of bytes
	nx_uint16_t reason1;			 // extra data
	nx_uint16_t reason2;
} AgillaErrorMsg; // 14 bytes

typedef nx_struct AgillaResetMsg {
	nx_uint16_t from; // who sent it?
	nx_uint16_t address;
} AgillaResetMsg; // 4 bytes

/**
 * This message is broadcasted when the location of
 * a base station is not known.
 */
typedef nx_struct AgillaBeaconMsg {
	nx_uint16_t id;		// the ID of the node
	nx_uint16_t hopsToGW;	// The number of hops to the gateway node.
						// Zero implies that this node is the gateway.					 
	//#if ENABLE_CLUSTERING
	nx_int16_t chId;	 // The id of cluster head of the cluster to which it belongs; -1 if not set
					// If this node is the cluster head, then it sends its own id
	nx_uint16_t energy;	// The residual energy of the node
	//uint16_t range;	 // Communication range of the node
	//#endif
} AgillaBeaconMsg;	// 4 bytes / 10 bytes

/**
 * This message is sent to the mote connected to the base station
 * informing it that it is the base station.
 */
typedef struct AgillaSetBSMsg {
	uint16_t dummy;
} AgillaSetBSMsg; // 1 byte


/**
 * This message is sent from the base station to a node
 * to change its address.	The destination address is the
 * original address of the mote (the address that is burned
 * into the mote's instruction memory).
 */
typedef nx_struct AgillaAddressMsg {
	nx_uint16_t fromPC;
	nx_uint16_t oldAddr;		// this is the *original* address stored in the flash memory
	nx_uint16_t newAddr;
} AgillaAddressMsg; // 6 bytes

/**
 * This message is sent from the mote to the laptop acknowledging
 * whether the address was changed.
 */
typedef nx_struct AgillaAddressAckMsg {
	nx_uint16_t success;
	nx_uint16_t oldAddr;	// this is the *original* address stored in the flash memory
	nx_uint16_t newAddr;
} AgillaAddressAckMsg; // 6 bytes

/**
 * This message is sent from the base station to a node.
 * When a node receives it, it replies with its neighbor list.
 */
typedef nx_struct AgillaGetNbrMsg {
	nx_uint16_t fromPC;
	nx_uint16_t replyAddr;
	nx_uint16_t destAddr;
} AgillaGetNbrMsg; // 6 bytes

/**
 * This message is sent from a node to the base station.
 * It contains the node's neighbor list.	It is used when
 * the user queries a node for its neighbor list for debugging
 * purposes.
 */

#define AGILLA_NBR_MSG_SIZE 4
//#define AGILLA_NBR_MSG_SIZE 8


typedef nx_struct AgillaNbrMsg {
	nx_uint16_t hopsToGW[AGILLA_NBR_MSG_SIZE];	// the number of hops to the gateway
	nx_uint16_t nbr[AGILLA_NBR_MSG_SIZE];	// the address of the neighbor
	nx_uint16_t lqi[AGILLA_NBR_MSG_SIZE];
} AgillaNbrMsg; // 24 bytes
#endif
