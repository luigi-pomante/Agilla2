// $Id: NetworkInterfaceM.nc,v 1.12 2006/04/20 22:05:58 chien-liang Exp $

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

#include "TupleSpace.h"

#if ENABLE_EXP_LOGGING
	includes ExpLogger;
	includes LocationDirectory;
#endif

/**
 * Serializes the sending of messages.	This is required
 * when there are multiple components that want to send messages
 * but have no way of coordinating.	By buffering
 * the messages, one component does not have to wait for another
 * component to receive the sendDone() event before it sends a
 * message.
 *
 * Interface SendMsg is a split-phase operation.	After calling
 * SendMsg.send, the message being sent must not be modified
 * until a corresponding SendMsg.sendDone event is signalled.	On
 * a MICA2 mote, the time between calling SendMsg.send and getting
 * a sendMsg.sendDone is approximtely 47 binary ms.
 *
 *
 * @author Chien-Liang Fok
 * @version 3.0
 */
//#include "NetworkInterface.h"

module SerialNetworkInterfaceM {
	provides {
	interface StdControl;
	interface Init;
	interface AMSend as BufferedSendMsg[uint8_t id];
	interface Receive as BufferedReceiveMsg[uint8_t id];
	}
	uses {
	interface AMSend;
	interface Receive;
	interface AMPacket;
	interface Packet;
	interface Boot;
	interface SplitControl as AMControl;
	interface MessageBufferI;

	
	#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
		interface CC2420Control;
	#endif
	#ifdef TOSH_HARDWARE_MICA2
		interface MacControl;	 // enable MAC-level ACKs
		//interface CC1000Control;	// used to reduce the radio range
	#endif
	
	#if ENABLE_EXP_LOGGING
		interface ExpLoggerI;
	#endif
	}
}
implementation {

	// send buffer
	struct BufferedMsg {
	message_t* msg;
	bool used;
	} sbuf[MESSAGE_BUFFER_SIZE];
	uint8_t head, tail;
	bool doingSend;

	// receive buffer
	struct BufferedMsg rbuf[MESSAGE_BUFFER_SIZE];
	uint8_t rhead, rtail;

	task void doSend();
	task void sigRcv();


	/**
	 * For debugging purposes.
	 */
	inline void printSendQState()
	{
	int i;
	dbg("DBG_USR1", "Send Queue State: head = %i, tail = %i\n", head, tail);
	for (i = 0; i < MESSAGE_BUFFER_SIZE; i++) {
		if (sbuf[i].used) {
		dbg("DBG_USR1", "%i:USED ", i);
		} else {
		dbg("DBG_USR1", "%i:EMPTY ", i);
		}
	}
	dbg("DBG_USR1", "\n");
	}

	event void Boot.booted() {
	call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
	if(err != SUCCESS) call AMControl.start();
	}

	event void AMControl.stopDone(error_t err) {
	}

	command error_t Init.init()
	{
	int i;
	#ifdef TOSH_HARDWARE_MICA2
		atomic {
		call MacControl.enableAck();
		}
	#endif
	doingSend = FALSE;

	// Initialize the send queue
	head = tail = 0;
	for (i = 0; i < MESSAGE_BUFFER_SIZE; i++) {
		sbuf[i].used = FALSE;
	}

	// Initialize the receive queue
	rhead = rtail = 0;
	for (i = 0; i < MESSAGE_BUFFER_SIZE; i++) {
		rbuf[i].used = FALSE;
	}

	#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
		// set the transmit power
		call CC2420Control.SetRFPower(AGILLA_RF_POWER);
	#endif
	return SUCCESS;
	}

	command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}

	/**
	 * Calculates the next index of the queue's head.
	 */
	inline uint8_t nextHead() {
	uint8_t result = head + 1;
	result %= MESSAGE_BUFFER_SIZE;
	return result;
	}

	/**
	 * Calculates the next index of the queue's tail.
	 */
	inline uint8_t nextTail() {
	uint8_t result = tail + 1;
	result %= MESSAGE_BUFFER_SIZE;
	return result;
	}

	/**
	 * Increments the tail of the send queue.	If there are
	 * still messages in the queue, post a task to process
	 * them.	If the task queue is full, abort by clearing out
	 * the send queue.
	 */
	inline void advanceSendQ() {
	sbuf[tail].used = FALSE;
	tail = nextTail();

	#if DEBUG_NETWORK_INTERFACE
		dbg("DBG_USR1", "NetworkInterfaceM: advanceSendQ(): tail = %i, head = %i\n", tail, head);
	#endif

	if (sbuf[tail].used) {
		if(post doSend() != SUCCESS) {
		dbg("DBG_USR1", "NetworkInterfaceM: advanceSendQ(): ERROR: Task queue full, could not post doSend().\n");
		// If the task queue is full, there is no hope of
		// sending the remaining messages in the send queue.
		// Thus, clear them out.
		while (tail != head) {
			am_id_t type;
			type= call AMPacket.type(sbuf[tail].msg);
			signal BufferedSendMsg.sendDone[type](sbuf[tail].msg, FAIL);
			sbuf[tail].used = FALSE;
			tail = nextTail();
		}
		doingSend = FALSE;
		} else {
		#if DEBUG_NETWORK_INTERFACE
		dbg("DBG_USR1", "NetworkInterfaceM: advanceSendQ(): Posted task to send nxt msg.\n");
		#endif
		}
	} else
		doingSend = FALSE;
	}

	uint8_t nxtrHead() {
	return (uint8_t)((rhead+1) % MESSAGE_BUFFER_SIZE);
	}

	/**
	 * Removes the next message from the send queue and sends
	 * it over the generic comm interface.	If the send was not
	 * successful, notify the user and advance the queue.
	 */
	task void doSend()
	{
	message_t *msg = sbuf[tail].msg;
	am_addr_t addr;
	addr= call AMPacket.destination(msg);
	if (addr == TOS_NODE_ID)
	{
		error_t result = FAIL;

		if (!rbuf[rhead].used)
		{
		rbuf[rhead].msg = call MessageBufferI.getMsg();
		if (rbuf[rhead].msg != NULL)
		{
			if (post sigRcv() == SUCCESS)
			{
			*(rbuf[rhead].msg) = *msg;
			rbuf[rhead].used = TRUE;
			rhead = nxtrHead();
			result = SUCCESS;
			} else
			{
			call MessageBufferI.freeMsg(rbuf[rhead].msg);
			}
		} else
		{
			dbg("DBG_USR1", "NetworkInterfaceM.doSend: ERROR: Message Sent to self, but no free message buffer.\n");
		}
		}

		signal BufferedSendMsg.sendDone[call AMPacket.type(msg)](msg, result);
		advanceSendQ();

	} else	// msg sent to a remote host
	{

		if (call AMSend.send(call AMPacket.destination(msg), msg, call Packet.payloadLength(msg)) == SUCCESS)
		{
		#if DEBUG_NETWORK_INTERFACE
			dbg("DBG_USR1", "NetworkInterfaceM.doSend: Sent a message of type %i (0x%x) to %i.\n", call AMPacket.type(msg), call AMPacket.type(msg), call AMPacket.destination(msg));
		#endif

		} else
		{
		dbg("DBG_USR1", "NetworkInterfaceM.doSend: ERROR: Failed to send message!\n\ttype=%i\n\tdest address = %i\n\tlength = %i\n",
			call AMPacket.type(msg), call AMPacket.destination(msg), call Packet.payloadLength(msg));
		signal BufferedSendMsg.sendDone[call AMPacket.type(msg)](msg, FAIL);
		advanceSendQ();
		}
	}

	} // task doSend()

	/**
	 * Signal the user that the send was complete, then
	 * advance the send queue.
	 *
	 * @param msg A pointer to the message that was send.
	 * @param success Indicates whether the send was successful.
	 * @return SUCCESS
	 */
	event void AMSend.sendDone(message_t *msg, error_t success)
	{
	if (sbuf[tail].msg == msg)
	{
		#if DEBUG_NETWORK_INTERFACE
		dbg("DBG_USR1", "NetworkInterfaceM: SendMsg.sendDone(): id = %i, success = %i\n", call AMPacket.type(msg), success);
		#endif

		signal BufferedSendMsg.sendDone[call AMPacket.type(msg)](msg, success);
		advanceSendQ();
	}

	} // SendMsg.sendDone()

	/**
	 * Enqueue the message being sent.
	 *
	 * @return SUCCESS if the message was enqueued.
	 */
	command error_t BufferedSendMsg.send[uint8_t id](am_addr_t address, message_t *msg, uint8_t length)
	{
	#if DEBUG_NETWORK_INTERFACE
		dbg("DBG_USR1", "NetworkInterfaceM: BufferedSendMsg.send(): Begin method call...\n");
	#endif
	
/*	#if ENABLE_EXP_LOGGING
		if (id == AM_AGILLAQUERYNUMAGENTSMSG ||
			id == AM_AGILLAQUERYAGENTLOCMSG ||
			id == AM_AGILLAQUERYNEARESTAGENTMSG ||
			id == AM_AGILLAQUERYALLAGENTSMSG)
		call ExpLoggerI.incQueryMsg();
		else if (id == AM_AGILLALOCMSG)
		call ExpLoggerI.incNumUpdates();
		else if (id == AM_AGILLAQUERYREPLYNUMAGENTSMSG ||
				 id == AM_AGILLAQUERYREPLYAGENTLOCMSG ||
				 id == AM_AGILLAQUERYREPLYNEARESTAGENTMSG ||
				 id == AM_AGILLAQUERYREPLYALLAGENTSMSG)
		call ExpLoggerI.incNumReplies();
	#endif
*/

	if (!sbuf[head].used) {	// if there is space in the send queue
		//am_id_t type1 = call AMPacket.type(msg); 
		//am_addr_t addr1 = call AMPacket.destination(msg);

		//type1 = id;
		//addr1 = address;
		//length1 = length;
		call AMPacket.setType(msg, id);
		call AMPacket.setDestination(msg, address);
		call Packet.setPayloadLength(msg, length);
		sbuf[head].msg = msg;

		#if DEBUG_NETWORK_INTERFACE
		dbg("DBG_USR1", "NetworkInterfaceM: BufferedSendMsg.send(): Enqueued message type = %i (0x%x), head = %i\n", id, id, head);
		#endif

		if (!doingSend) {
		if (post doSend() == SUCCESS) {
			sbuf[head].used = TRUE;
			head = nextHead();	// only accept message in send queue if task could be posted
			doingSend = TRUE;
		} else {
			dbg("DBG_USR1", "ERROR: NetworkInterfaceM.BufferedSendMsg.send: Task queue full!\n");
			return FAIL;
		}
		} else {
		sbuf[head].used = TRUE;
		head = nextHead();	// accept message in send queue
		}
	} else {
		dbg("DBG_USR1", "ERROR: NetworkInterfaceM.BufferedSendMsg.send: Send queue full!\n");
		//#if DEBUG_NETWORK_INTERFACE
		printSendQState();
		//#endif
		return FAIL;
	}
	return SUCCESS;
	}

	/**
	 * Signal the receiption of a message.	Since this
	 * is done using a task, components signaled by this
	 * can take their time processing the received message.
	 */
	task void sigRcv() {
	rbuf[rtail].msg = signal BufferedReceiveMsg.receive[call AMPacket.type(rbuf[tail].msg)](rbuf[rtail].msg, call Packet.getPayload(rbuf[rtail].msg, call Packet.payloadLength(rbuf[rtail].msg)), call Packet.payloadLength(rbuf[rtail].msg));
	call MessageBufferI.freeMsg(rbuf[rtail].msg);
	rbuf[rtail].msg = NULL;
	rbuf[rtail].used = FALSE;
	rtail++;
	rtail %= MESSAGE_BUFFER_SIZE;	 // advance the receive queue
	}

	/**
	 * Whenever a message is received, enqueue it in the receive buffer
	 * and post a task to process it.	This quickly frees up the network
	 * stack's buffer and allows higher-level components to spend as much
	 * time processing the message as they like.
	 */
	event message_t* Receive.receive(message_t* m, void* payload, uint8_t len)
	{
	message_t* mptr = call MessageBufferI.getMsg();

	#if DEBUG_NETWORK_INTERFACE
		dbg("DBG_USR1", "NetworkInterfaceM: Received	message of type 0x%x\n", call AMPacket.type(m));
	#endif

	if (mptr != NULL)
	{
		if (!rbuf[rtail].used)
		{
		if (post sigRcv() == SUCCESS)
		{
			rbuf[rhead].msg = m;
			//am_id_t id1 = call AMPacket.type(rbuf[rhead].msg);
			//id1 = id;
			call AMPacket.setType(rbuf[rhead].msg, call AMPacket.type(m));
			rbuf[rhead].used = TRUE;
			rhead = nxtrHead();
		} else
		{
			dbg("DBG_USR1", "NetworkInterfaceM: Receive.receive: could not post task!\n");
			call MessageBufferI.freeMsg(mptr);
			mptr = m;
		}
		} else
		{
		dbg("DBG_USR1", "NetworkInterfaceM: Receive.receive: receive buffer full.\n");
		call MessageBufferI.freeMsg(mptr);
		mptr = m;
		}
	} else
	{
		dbg("DBG_USR1", "NetworkInterfaceM: Receive.receive: Could not allocate message buffer.\n");
		mptr = m;
	}
	return mptr;
	}


	default event void BufferedSendMsg.sendDone[uint8_t id](message_t* m, error_t error) {
	//return SUCCESS;
	}

	default event message_t* BufferedReceiveMsg.receive[uint8_t id](message_t* m, void* payload, uint8_t len) {
	return m;
	}
 
	command error_t BufferedSendMsg.cancel[uint8_t id](message_t* msg){
	return SUCCESS;
	}

	command uint8_t BufferedSendMsg.maxPayloadLength[uint8_t id](){
	return call Packet.maxPayloadLength();
	}

	command void* BufferedSendMsg.getPayload[uint8_t id](message_t* msg, uint8_t len){
	return call Packet.getPayload(msg, len);
	}
}
