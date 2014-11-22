// $Id: TupleSpace.h,v 1.7 2006/02/11 08:11:56 chien-liang Exp $

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

#ifndef AGILLA_TS_TUPLESPACE_H_INCLUDED
#define AGILLA_TS_TUPLESPACE_H_INCLUDED

typedef enum {	
	AGILLA_MAX_TUPLE_SIZE = 20,		// the max number of field bytes in a tuple, a
										// tuple's actual size is this + 2
	MAX_PRDPG_RESULTS = 11,
} TupleSpaceIConstants;

typedef enum {
	AGILLA_TUPLE_RESET = 0x00,
	AGILLA_TUPLE_SYSTEM = 0x01,
} AgillaTupleFlags;

//typedef enum {
// BUSY = 0x02,
//} TupleSpaceReturnConstant;

// Tuple string constants
#define AGILLA_TUPLE_STRING_AGENT	2628	// "aid"
#define AGILLA_TUPLE_STRING_HOST	 16964 // "hid"
#define AGILLA_TUPLE_STRING_PHOTO	39184 // "sdp"
#define AGILLA_TUPLE_STRING_TEMP	 39188 // "sdt"
#define AGILLA_TUPLE_STRING_MIC	39181 // "sdm"
#define AGILLA_TUPLE_STRING_MAGX	 39192 // "sdx"
#define AGILLA_TUPLE_STRING_MAGY	 39193 // "sdy"
#define AGILLA_TUPLE_STRING_ACCELX 39169 // "sda"
#define AGILLA_TUPLE_STRING_ACCELY 39170 // "sdb"

typedef nx_struct AgillaTuple {
	nx_uint8_t flags;	 // whether the tuple exists & is a system tuple
	nx_uint8_t size;	// number of fields
	nx_uint8_t data[AGILLA_MAX_TUPLE_SIZE]; // [type], [var], ...
} AgillaTuple; // 20 bytes

typedef nx_struct Reaction {
	AgillaAgentID id;
	nx_uint16_t pc;
	AgillaTuple template;
} Reaction; // 24 bytes

//------------------------------------------------------------------------------
// Active message port numbers
enum {
	AM_AGILLATSREQMSG = 0x30,
	AM_AGILLATSRESMSG = 0x31,
	//AM_AGILLATSMODMSG = 0x32,
	AM_AGILLATSGRESMSG = 0x33,
};

//------------------------------------------------------------------------------
// Tuple Space operation request/response messages

//typedef struct AgillaTSModMsg {
// uint8_t dummy;
//} AgillaTSModMsg;

typedef nx_struct AgillaTSReqMsg {
	nx_uint16_t dest;		// 2
	nx_uint16_t reply;	 // 2
	nx_uint8_t op;		 // 1
	nx_uint8_t dummy;		// 1 space holder
	AgillaTuple template; // 20
} AgillaTSReqMsg; // 26 bytes

typedef nx_struct AgillaTSResMsg {
	nx_uint16_t dest; 
	nx_uint8_t op;
	nx_uint8_t success; //bool success;
	AgillaTuple tuple;	// 20 bytes, the info.flags field is set by the sender
} AgillaTSResMsg; // 26 bytes

/* This message contains the location of the
	 neighbor with a matching tuple.	It is used
	 to return the results of a rrdpg request. */
typedef nx_struct AgillaTSGResMsg {
	nx_uint16_t addr;	// the address of the mote with the matching tuple
} AgillaTSGResMsg; // 2 bytes


// If sent from base station to mote, register reaction.
// If sent from mote to base station, reaction fired.
//typedef struct AgillaBSRxnMsg {
// Reaction rxn;
//} AgillaBSRxnMsg;
#endif

