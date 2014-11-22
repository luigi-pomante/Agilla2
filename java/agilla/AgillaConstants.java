// $Id: AgillaConstants.java,v 1.5 2006/02/13 18:05:14 chien-liang Exp $

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
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS
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
package agilla;

public interface AgillaConstants {
	static final short SUCCESS = 1;
	static final short FAIL = 0;
	
	// tuple specification
	public static final int AGILLA_MAX_TUPLE_SIZE = 25;  // maximum size of a tuple in bytes
	
	// network topology
	//static final short BS_X = 0, BS_Y = 0;
	static final short UART_X = 0, UART_Y = 1;
	static final short BCAST_X = 0, BCAST_Y = 2;
	
	// address constants
	static final int TOS_BASE_ADDRESS = 0;  // address of mote attached to base station
	static final int TOS_UART_ADDRESS  = 0x007e;
	static final int TOS_LOCAL_ADDRESS = TOS_UART_ADDRESS; //0x0000;
	static final int TOS_BCAST_ADDRESS = 0xffff;
	
	// Agent context specification
	public static int AGILLA_OPDEPTH          = 105;      // depth of operand stack
	public static int AGILLA_TS_SIZE          = 100;      // size of tuple space stored in data memory
	public static int AGILLA_NUM_AGENTS       = 4;       // max number of agents on a node
	public static int AGILLA_HEAP_SIZE        = 12;      // size of heap on each agent
	//public static int AGILLA_CODE_BLOCK_SIZE  = 22;      // the size of each code block
	public static int AGILLA_NUM_CODE_BLOCKS  = 20;      // the total number of code blocks
	public static int AGILLA_SENSOR_PERIOD    = 2048;    // time between taking sensor measurements
	public static int AGILLA_MSG_TIMEOUT      = 512;
	public static int AGILLA_MSG_RETRY        = 256;
	
	// Active message types
//	static final int AM_AGILLASTATEMSG     = 0x10; // 16
//	static final int AM_AGILLACODEMSG      = 0x11; // 17
//	static final int AM_AGILLAHEAPMSG      = 0x12; // 18
//	static final int AM_AGILLAOPSTACKMSG   = 0x13; // 19
//	static final int AM_AGILLARXNMSG       = 0x14; // 20
//	
//	static final int AM_AGILLAACKSTATEMSG    = 0x15; // 21
//	static final int AM_AGILLAACKCODEMSG     = 0x16; // 22
//	static final int AM_AGILLAACKHEAPMSG     = 0x17; // 23
//	static final int AM_AGILLAACKOPSTACKMSG  = 0x18; // 24
//	static final int AM_AGILLAACKRXNMSG      = 0x19; // 25
	
//	static final int AM_AGILLATSREQMSG     = 0x30;
//	static final int AM_AGILLATSRESMSG     = 0x31;
//	static final int AM_AGILLATSMODMSG     = 0x32;
//	static final int AM_AGILLAERRORMSG     = 0x20;
//	static final int AM_AGILLARESETMSG     = 0x21;
//	static final int AM_AGILLABEACONMSG	   = 0x22;
//	static final int AM_AGILLAEXPMSG       = 0x23;
//	static final int AM_AGILLASTARTEXPMSG  = 0x24;
//	static final int AM_AGILLAADDRESSMSG   = 0x25;
//	static final int AM_AGILLAGETNBRMSG    = 0x26;
//	static final int AM_AGILLANBRMSG       = 0x27;
//	static final int AM_AGILLASETBSMSG     = 0x28;
//	static final int AM_AGILLAGRIDSIZEMSG  = 0x29;
	
	//static final int AM_AGILLABEACONBSMSG = 0x40;
//	static final int AM_AGILLAADDRESSACKMSG   = 0x41;
	
	//static final int AM_AGILLACODEUSEDMSG  = 0x25;   // 37
  	//static final int AM_AGILLANXTBLOCKPTRMSG = 0x26; // 38
	
	//static final int AGILLA_OS_MSG_SIZE    = 24;
	//static final int AGILLA_HEAP_MSG_SIZE  = 25;
	
	// Remote operation specification
	static final int AGILLA_RTS_TIMEOUT       = 3000;    // remote op timeout in milliseconds
	static final int AGILLA_RTS_MAX_NUM_TRIES = 2;        // the max number of times a request is sent
	
	// values for AgillaAckMsg.type
	static final short ACK_STATE_MSG         = 1;
	static final short ACK_CODE_MSG          = 2;
	static final short ACK_HEAP_MSG          = 3;
	static final short ACK_OS_MSG            = 4;
	static final short AGILLA_ACCEPT = 1;
	static final short AGILLA_REJECT = 0;
	
	// migration settings
	static final int AGILLA_SNDR_RXMIT_TIMER      = 768;
	static final int AGILLA_RCVR_ABORT_TIMER      = 2048;
	static final int AGILLA_RCVR_FIN_TIMER        = 1024;
	static final int AGILLA_MIGRATE_NUM_TIMEOUTS  = 4;
	static final int AGILLA_MIGRATE_NUM_BAD_ACKS  = 3;
	static final int AGILLA_MIGRATE_RETRY_TIMER   = 3072;
	
	
	//public static int AGILLA_RCV_TIMEOUT      = 1024;    // how long the agent receiver will wait for an agent
	//public static int AGILLA_MIGRATE_TIMEOUTS = 4;
	
	// AgillaSensorType
	/*public static int AGILLA_DATA_NONE    = 255;
	public static int AGILLA_DATA_PHOTO   = 1;
	public static int AGILLA_DATA_TEMP    = 2;
	public static int AGILLA_DATA_MIC     = 3;
	public static int AGILLA_DATA_MAGX    = 4;
	public static int AGILLA_DATA_MAGY    = 5;
	public static int AGILLA_DATA_ACCELX  = 6;
	public static int AGILLA_DATA_ACCELY  = 7;
	 public static int AGILLA_DATA_ANY     = 8;*/
	
	//AgillaDataType
	public static short AGILLA_TYPE_INVALID  = 0;
	public static short AGILLA_TYPE_VALUE    = 1;
	public static short AGILLA_TYPE_READING  = 2;
	public static short AGILLA_TYPE_STRING   = 4;
	public static short AGILLA_TYPE_TYPE     = 8;
	public static short AGILLA_TYPE_RTYPE    = 16;
	public static short AGILLA_TYPE_AGENTID  = 32;
	public static short AGILLA_TYPE_LOCATION = 64;
	public static short AGILLA_TYPE_ANY =
		AGILLA_TYPE_VALUE | AGILLA_TYPE_READING |
		AGILLA_TYPE_STRING | AGILLA_TYPE_TYPE |
		AGILLA_TYPE_RTYPE | AGILLA_TYPE_AGENTID | AGILLA_TYPE_LOCATION;
	
	// OPsense contants
	public static int AGILLA_STYPE_ANY     = 0;
	public static int AGILLA_STYPE_SOUNDER = 0;
	public static int AGILLA_STYPE_PHOTO   = 1;
	public static int AGILLA_STYPE_TEMP    = 2;
	public static int AGILLA_STYPE_MIC     = 3;
	public static int AGILLA_STYPE_MAGX    = 4;
	public static int AGILLA_STYPE_MAGY    = 5;
	public static int AGILLA_STYPE_ACCELX  = 6;
	public static int AGILLA_STYPE_ACCELY  = 7;
	
	// OPpushtSensorConstants
	/*public static int OP_PUSHT_ARG_PHOTO = 1;
	public static int OP_PUSHT_ARG_TEMP = 2;
	public static int OP_PUSHT_ARG_MIC = 3;
	public static int OP_PUSHT_ARG_MAGX = 4;
	public static int OP_PUSHT_ARG_MAGY = 5;
	public static int OP_PUSHT_ARG_ACCELX = 6;
	 public static int OP_PUSHT_ARG_ACCELY = 7;*/
	
	//OPpushtConstants
//	public static int OP_PUSHT_ARG_ANY = 0;
//	public static int OP_PUSHT_ARG_AGENTID = 1;
//	public static int OP_PUSHT_ARG_STRING = 2;
//	public static int OP_PUSHT_ARG_TYPE = 3;
//	public static int OP_PUSHT_ARG_VALUE = 4;
//	public static int OP_PUSHT_ARG_LOCATION = 5;
	
	
	// tuple constants
	//public static int AGILLA_TUPLE_RESET      = 0x0000;
	//public static int AGILLA_TUPLE_SYSTEM     = 0x0100;  // bit 9  = is system tuple
	//public static int AGILLA_TUPLE_HAS_OWNER  = 0x0200;  // bit 10 = tuple has owner
	//public static int AGILLA_TUPLE_EXISTS     = 0x0400;  // bit 11 = tuple exists
}

