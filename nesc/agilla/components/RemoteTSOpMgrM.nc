// $Id: RemoteTSOpMgrM.nc,v 1.20 2006/04/20 22:05:58 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2006, Washington University in Saint Louis
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
#include "AgillaOpcodes.h"
#include "Timer.h"

/**
 * Processes the _results of a group operation.
 * Handles the reception of remote TupleSpaceI requests.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
module RemoteTSOpMgrM
{
	provides
	{
		interface Init;
		interface RemoteTSOpMgrI;
	}

	uses
	{
		interface Receive as Rcv_Req;
		interface Receive as Rcv_Res;
		interface Receive as Rcv_GRes;
		interface Receive as SerialRcv_Req;
		interface Receive as SerialRcv_Res;
		interface Receive as SerialRcv_GRes;

		interface AMSend as Send_Req;
		interface AMSend as SerialSend_Req;
		interface AMSend as Send_Res;
		interface AMSend as SerialSend_Res;
		interface AMSend as Send_GRes;
		interface AMSend as SerialSend_GRes;

		interface Timer<TMilli> as Timeout;

		interface Timer<TMilli> as BackoffTimer;
		interface Random;

		interface AddressMgrI;
		interface NeighborListI;
		interface TupleSpaceI;
		interface TupleUtilI;
		interface ErrorMgrI;
		interface MessageBufferI;
		interface LocationMgrI;

		interface Leds; // debug;
		interface Packet;
		interface AMPacket;
	}
}
implementation
{
	/**
	 * Only one agent per mote can issue a remote tuple space
	 * operation, _currAgent is a pointer to this agent's context.
	 * If another agent attempts to perform a remote tuple space
	 * operation while the _currAgent is waiting for results,
	 * it's context is stored in the waitQueue and resumed when
	 * the current agent finishes.
	 */
	AgillaAgentContext* _currAgent;

	/**
	 * The tuple used in the remote tuple space operation being executed.
	 */
	AgillaTuple _tuple;

	/**
	 * The current instruction.
	 */
	uint8_t _op;

	/**
	 * The destination of the remote tuple space operation.
	 */
	uint16_t _dest;

	/**
	 * Keeps track of the number of results that have been received.
	 * This is used by group operations.
	 */
	uint8_t _numResults;

	/**
	 * The number of times this node has tried to perform a remote TS operation.
	 */
	uint8_t _numTries;

	// pre-declarations
	inline void backoff();
	inline error_t isUnique(uint16_t addr);
	task void doRemoteOp();
	void bounceMsg(uint16_t addr, message_t* m);

	command error_t Init.init()
	{
		_currAgent = NULL;
		return SUCCESS;
	}

	/**
	 * This is executed when the RemoteTSOpMgr finishes executing
	 * an agent's remote TS Op.
	 */
	inline error_t finish(error_t success)
	{
		signal RemoteTSOpMgrI.done(_currAgent, _dest, success);
		_currAgent = NULL;
		return success;
	}

	default event error_t RemoteTSOpMgrI.done(AgillaAgentContext* agent, uint16_t dest, error_t success)
	{
		return SUCCESS;
	}

	command error_t RemoteTSOpMgrI.execute(AgillaAgentContext* agent, uint16_t op, uint16_t dest, AgillaTuple tuple)
	{
		_currAgent = agent;
		_dest = dest;
		_op = op;
		_tuple = tuple;
		_numResults = 0;
		_numTries = 0;

		if (post doRemoteOp() != SUCCESS)
		{
			dbg("DBG_USR1", "VM (%i:%i): RemoteTSOpMgrM: ERROR: Could not post doRemoteOp().\n", agent->id.id, agent->pc-1);
			return finish(FAIL);
		}
		return SUCCESS;
	} // RemoteTSOpMgrI.execute()

	/**
	 * Sends the request.
	 *
	 * If the destination is TOS_UART_ADDR and this is not a base station,
	 * forward it to the nearest base station.
	 */
	task void doRemoteOp()
	{
		message_t* msg = call MessageBufferI.getMsg();

		if (msg != NULL)
		{
			AgillaTSReqMsg *request = (AgillaTSReqMsg *)(call Packet.getPayload(msg, sizeof(AgillaTSReqMsg)));
			error_t success = FALSE;
			uint16_t onehop_dest;
			bool sendMsg = TRUE;

			request->dest = _dest;
			request->reply = TOS_NODE_ID;
			request->op = _op;
			request->template = _tuple;
			onehop_dest = _dest;


			// If the destination is the UART but this mote am not the gateway,
			// find the neighbor that is closest to the gateway.
			if (onehop_dest == AM_UART_ADDR && call AddressMgrI.isGW() != SUCCESS)
			{
				// If there is no known gateway, abort.
				if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
				{
					dbg("DBG_USR1", "RemoteTSOpMgrM: doRemoteOp: ERROR: No neighbor closer to a gateway.	Freeing message buffer, allowing timeout timer to fire\n");
					sendMsg = FALSE;
					call MessageBufferI.freeMsg(msg);
				}
			}

			// Send the request if we have a valid destination address
			if (sendMsg)
			{
				#if DEBUG_REMOTE_TS_OP_MGR
					dbg("DBG_USR1", "RemoteTSOpMgrM: Sending TS request to %i.\n", onehop_dest);
				#endif

				if(onehop_dest == AM_UART_ADDR)
					success = call SerialSend_Req.send(onehop_dest, msg, sizeof(AgillaTSReqMsg));
				else
					success = call Send_Req.send(onehop_dest, msg, sizeof(AgillaTSReqMsg));

				if (success != SUCCESS)
				{
					dbg("DBG_USR1", "RemoteTSOpMgrM: doRemoteOp: ERROR: Could not send message.	Freeing message buffer, allowing timeout timer to fire.\n");
					call MessageBufferI.freeMsg(msg);
				}
			}

			// If the message was sent and this is an ROUT to the UART, no response
			// is expected.	Otherwise, set a timer to wait for the response.
			if (success == SUCCESS && _dest == AM_UART_ADDR && request->op == IOProut)
			{
				#if DEBUG_REMOTE_TS_OP_MGR
					dbg("DBG_USR1", "RemoteTSOpMgrM: doRemoteOP: Op was a ROUT to UART, done.\n");
				#endif

				// Don't need to call MessageBufferI.freeMsg() because the send was successful,
				// and the sendDone event will free the message buffer.

				finish(SUCCESS);
				return;
			}
			else
			{
				#if DEBUG_REMOTE_TS_OP_MGR
					dbg("DBG_USR1", "RemoteTSOpMgrM: Timer set, waiting for response.\n");
				#endif
				call Timeout.startOneShot(AGILLA_RTS_TIMEOUT);
			}
		}
		else
		{
			dbg("DBG_USR1", "VM (%i:%i): RemoteTSOpMgrM: doRemoteOP: ERROR: Failed to allocate free message.\n", _currAgent->id.id, _currAgent->pc-1);
		}

	} // doRemoteOp()

	/**
	 * This event indicates that a response to a tuple space operation
	 * was not received in time, or that a group operation has completed.
	 */
	event void Timeout.fired()
	{
		if (_currAgent != NULL)
		{
			if (_op == IOPrrdpg)
			{
				_currAgent->heap.pos[0].vtype = AGILLA_TYPE_VALUE;	// store # results in heap[0]
				_currAgent->heap.pos[0].value.value = _numResults;
				finish(SUCCESS);
			}
			else if (_op == IOProutg)
				finish(SUCCESS);
			else
			{
				dbg("DBG_USR1", "VM (%i:%i): RemoteTSOpMgrM: Time.fired(): ERROR: Timed out while waiting for ACK! num tries = %i\n", _currAgent->id.id, _currAgent->pc-1, _numTries+1);
				if (++_numTries > AGILLA_RTS_MAX_NUM_TRIES)
				{
					dbg("DBG_USR1", "VM (%i:%i): RemoteTSOpMgrM: Time.fired(): ERROR: Aborting...\n", _currAgent->id.id, _currAgent->pc-1);
					finish(FAIL);
				} else
				{
					dbg("DBG_USR1", "VM (%i:%i): RemoteTSOpMgrM: Time.fired(): ERROR: Backing off...\n", _currAgent->id.id, _currAgent->pc-1);
					backoff(); // try again
				}
			}
		}

	} // Timeout.fired()

	/**
	 * Choose a random time between 511-1023 and set the backoff timer.
	 */
	inline void backoff()
	{
		uint16_t length = call Random.rand32();
		length &= 0x1ff; // 0-511
		length += 0x200; // add 512
		call BackoffTimer.startOneShot(length);
	}

	/**
	 * When the backoff timer fires, repeat the remote tuple space operation.
	 */
	event void BackoffTimer.fired()
	{
		post doRemoteOp();
	}

	/**
	 * Handles the results of group operations.
	 */
	event message_t* Rcv_GRes.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaTSGResMsg *results = (AgillaTSGResMsg*)payload;

		if (_currAgent != NULL && _op == IOPrrdpg)
		{
			if (isUnique(results->addr) == SUCCESS && _numResults < MAX_PRDPG_RESULTS)
			{
				AgillaLocation loc;
				call LocationMgrI.getLocation(results->addr, &loc);
				_numResults++;	// remember how many results were returned
				_currAgent->heap.pos[_numResults].vtype = AGILLA_TYPE_LOCATION;
				_currAgent->heap.pos[_numResults].loc = loc;
			}
		}
		return m;
	} // Rcv_GRes.receive()

	event message_t* SerialRcv_GRes.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaTSGResMsg *results = (AgillaTSGResMsg*)payload;

		if (_currAgent != NULL && _op == IOPrrdpg)
		{
			if (isUnique(results->addr) == SUCCESS && _numResults < MAX_PRDPG_RESULTS)
			{
				AgillaLocation loc;
				call LocationMgrI.getLocation(results->addr, &loc);
				_numResults++;	// remember how many results were returned
				_currAgent->heap.pos[_numResults].vtype = AGILLA_TYPE_LOCATION;
				_currAgent->heap.pos[_numResults].loc = loc;
			}
		}
		return m;
	} // SerialRcv_GRes.receive()

	/**
	 * Determines whether the specified address has been received before
	 * and stored on the heap.
	 */
	inline error_t isUnique(uint16_t addr)
	{
		int i;
		AgillaLocation loc;
		call LocationMgrI.getLocation(addr, &loc);

		for (i = 0; i < _numResults; i++)
		{
			//if (addr == _currAgent->heap.pos[i+1].value.value)
			if (loc.x == _currAgent->heap.pos[i+1].loc.x &&
					loc.y == _currAgent->heap.pos[i+1].loc.y)
				return FAIL;
		}
		return SUCCESS;
	} // isUnique()

	/**
	 * Handles the results of non-group operations.
	 *
	 * When a results message is received, check to make sure the tuple is
	 * indeed for the waiting agent.	If it is, stop the timer, save the
	 * tuple in the waiting agen'ts opstack, and resume running.
	 */
	event message_t* Rcv_Res.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaTSResMsg *results = (AgillaTSResMsg*)payload;

#if DEBUG_REMOTE_TS_OP_MGR
		dbg("DBG_USR1", "RemoteTSOpMgrM: received a results message for %i containing tuple:\n", results->dest);
		call TupleUtilI.printTuple(&results->tuple);
#endif

		if (results->dest == TOS_NODE_ID)
		{
#if DEBUG_REMOTE_TS_OP_MGR
			dbg("DBG_USR1", "RemoteTSOpMgrM: The results are for destined for me!\n");
#endif

			if (_currAgent != NULL
					&& _op == results->op
					&& call TupleUtilI.tMatches(&_tuple, &results->tuple, FALSE) == SUCCESS)
			{

#if DEBUG_REMOTE_TS_OP_MGR
				dbg("DBG_USR1", "RemoteTSOpMgrM: Tuple Match! Processing results!\n");
#endif

				call Timeout.stop();
				if (_op != IOProut && results->success)
					call TupleUtilI.pushTuple(&results->tuple, _currAgent);	// save results on stack

				if(results->success) finish(SUCCESS);
				else finish(FAIL);
			} else
			{
				// The results message was destined for this mote, but
				// this mote wasn't waiting for it.	Assume the results
				// message is actually for the base station.
				//#if DEBUG_REMOTE_TS_OP_MGR
				// dbg("DBG_USR1", "RemoteTSOpMgrM: Bouncing results to PC...\n");
				//#endif

				//results->dest = AM_UART_ADDR;
				//bounceMsg(AM_UART_ADDR, m);	// result was not for the agent blocked on this host
			}
		}
		else
			bounceMsg(results->dest, m);
		return m;

	} // Rcv_Res.receive()

	event message_t* SerialRcv_Res.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaTSResMsg *results = (AgillaTSResMsg*)payload;

#if DEBUG_REMOTE_TS_OP_MGR
		dbg("DBG_USR1", "RemoteTSOpMgrM: received a results message for %i containing tuple:\n", results->dest);
		call TupleUtilI.printTuple(&results->tuple);
#endif

		if (results->dest == TOS_NODE_ID)
		{
#if DEBUG_REMOTE_TS_OP_MGR
			dbg("DBG_USR1", "RemoteTSOpMgrM: The results are for destined for me!\n");
#endif

			if (_currAgent != NULL
					&& _op == results->op
					&& call TupleUtilI.tMatches(&_tuple, &results->tuple, FALSE) == SUCCESS)
			{

#if DEBUG_REMOTE_TS_OP_MGR
				dbg("DBG_USR1", "RemoteTSOpMgrM: Tuple Match! Processing results!\n");
#endif

				call Timeout.stop();
				if (_op != IOProut && results->success)
					call TupleUtilI.pushTuple(&results->tuple, _currAgent);	// save results on stack

				if(results->success) finish(SUCCESS);
				else finish(FAIL);
			} else
			{
				// The results message was destined for this mote, but
				// this mote wasn't waiting for it.	Assume the results
				// message is actually for the base station.
				//#if DEBUG_REMOTE_TS_OP_MGR
				// dbg("DBG_USR1", "RemoteTSOpMgrM: Bouncing results to PC...\n");
				//#endif

				//results->dest = AM_UART_ADDR;
				//bounceMsg(AM_UART_ADDR, m);	// result was not for the agent blocked on this host
			}
		}
		else
			bounceMsg(results->dest, m);
		return m;

	} // SerialRcv_Res.receive()

	/**
	 * Sends the message to the specified address.
	 */
	void bounceMsg(uint16_t addr, message_t* m)
	{
		bool sendMsg = TRUE;
		uint16_t dest = addr;

		if (addr == AM_UART_ADDR && call AddressMgrI.isGW() != SUCCESS)
		{
			// The destination is the UART but this mote is not a GW.
			// Try to find the neighbor that is closest to the GW.
			uint16_t numHops = call NeighborListI.getGW(&dest);
			if (numHops == NO_GW)
			{
				dbg("DBG_USR1", "RemoteTSOpMgrM.bounceMsg: ERROR: Unable to send message to the UART (no known GW).\n");
				sendMsg = FALSE;
			}
		}

#if DEBUG_REMOTE_TS_OP_MGR
		dbg("DBG_USR1", "RemoteTSOpMgrM: Bouncing the message to %i.\n", dest);
#endif

		if (sendMsg)
		{
			message_t* msg = call MessageBufferI.getMsg();
			if (msg != NULL)
			{
				error_t success = FAIL;
				error_t forward = SUCCESS;
				uint16_t oneHopDest = dest;

#if ENABLE_GRID_ROUTING
				forward = call NeighborListI.getClosestNeighbor(&oneHopDest);
#endif

				if (forward == SUCCESS)
				{
					*msg = *m;

					// if (msg->type == AM_AGILLATSRESMSG)
					if (call AMPacket.type(msg) == AM_AGILLATSRESMSG)
					{
						if (oneHopDest == AM_UART_ADDR)
							success = call SerialSend_Res.send(oneHopDest, msg, sizeof(AgillaTSResMsg));
						else	
							success = call Send_Res.send(oneHopDest, msg, sizeof(AgillaTSResMsg));
					} 
					else if (call AMPacket.type(msg) == AM_AGILLATSREQMSG)
					{
						if (oneHopDest == AM_UART_ADDR)
							success = call SerialSend_Req.send(oneHopDest, msg, sizeof(AgillaTSReqMsg));
						else
							success = call Send_Req.send(oneHopDest, msg, sizeof(AgillaTSReqMsg));
					}
					else
					{
						dbg("DBG_USR1", "RemoteTSOpMgrM.bounceMsg: ERROR: Unknown message type %i.\n", call AMPacket.type(msg));
					}
				} else
				{
					dbg("DBG_USR1", "RemoteTSOpMgrM.bounceMsg: ERROR: forward = false.\n");
				}

				if (success != SUCCESS)
				{
					dbg("DBG_USR1", "RemoteTSOpMgrM.bounceMsg: ERROR: Unable to send message to %i.\n", dest);
					call MessageBufferI.freeMsg(msg);
				} else
				{
					// message is actually for the base station.
#if DEBUG_REMOTE_TS_OP_MGR
					dbg("DBG_USR1", "RemoteTSOpMgrM: Bounced message to %i.\n", dest);
#endif
				}
			} else
			{
				dbg("DBG_USR1", "RemoteTSOpMgrM.bounceMsg: ERROR: Unable to allocate free message.\n");
			}
		}
	} // bounceMsg()



	/**
	 * This is called whenever a remote TS request is received.
	 */
	event message_t* Rcv_Req.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaTSReqMsg* request = (AgillaTSReqMsg*)payload;

#if DEBUG_REMOTE_TS_OP_MGR
		dbg("DBG_USR1", "RemoteTSOpMgr(): Processing request dest=%i, reply=%i, op=%i.\n",
				request->dest, request->reply, request->op);
		call TupleUtilI.printTuple(&request->template);
#endif

		if (request->op == IOPrrdpg)
		{

#if DEBUG_REMOTE_TS_OP_MGR
			dbg("DBG_USR1", "RemoteTSOpMgr(): The request is a rrdpg.\n");
#endif

			if (call TupleSpaceI.rdp(&request->template) == SUCCESS)
			{
				message_t* reply = call MessageBufferI.getMsg();

#if DEBUG_REMOTE_TS_OP_MGR
				dbg("DBG_USR1", "RemoteTSOpMgr(): Match found!\n");
#endif

				if (reply != NULL)
				{
					AgillaTSGResMsg* gresponse = (AgillaTSGResMsg*)(call Packet.getPayload(reply, sizeof(AgillaTSGResMsg)));
					gresponse->addr = TOS_NODE_ID;
					if(request->reply == AM_UART_ADDR){
						if (call SerialSend_GRes.send(request->reply, reply, sizeof(AgillaTSGResMsg)) == SUCCESS)
						{
#if DEBUG_REMOTE_TS_OP_MGR
							dbg("DBG_USR1", "RemoteTSOpMgr(): Sent group response.\n");
#endif
						} else
						{
							dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send group response.\n");
							call MessageBufferI.freeMsg(reply);
						}
					}
					else
					{	
						if (call Send_GRes.send(request->reply, reply, sizeof(AgillaTSGResMsg)) == SUCCESS)
						{
#if DEBUG_REMOTE_TS_OP_MGR
							dbg("DBG_USR1", "RemoteTSOpMgr(): Sent group response.\n");
#endif
						} else
						{
							dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send group response.\n");
							call MessageBufferI.freeMsg(reply);
						}
					}
				} else
				{
					dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: no free message buffer.\n");
				}
			} else
			{
#if DEBUG_REMOTE_TS_OP_MGR
				dbg("DBG_USR1", "RemoteTSOpMgr(): No match found.\n");
#endif
			}
		}

		else if (request->op == IOProutg)
		{
			call TupleSpaceI.out(&request->template);

#if DEBUG_REMOTE_TS_OP_MGR
			dbg("DBG_USR1", "RemoteTSOpMgr(): OUTed tuple in routg operation.\n");
			call TupleUtilI.printTuple(&request->template);
#endif
		}

		else
		{
			if (request->dest == TOS_NODE_ID)
			{
				// The request is destined for this mote.	Perform the request.
				message_t* reply = call MessageBufferI.getMsg();

				if (reply != NULL)
				{
					AgillaTSResMsg* response = (AgillaTSResMsg*)(call Packet.getPayload(reply, sizeof(AgillaTSResMsg)));
					bool send_result = TRUE;

					response->dest = request->reply;
					response->op = request->op;

					// By default send the template back to the requester if
					// no results are found.
					response->tuple = request->template;

					if (request->op == IOProut)
					{

						if (call TupleSpaceI.out(&response->tuple) == SUCCESS) response->success = TRUE;
						else response->success = FALSE;
#if DEBUG_REMOTE_TS_OP_MGR
						dbg("DBG_USR1", "RemoteTSOpMgr(): Performed rout, success = %i\n", response->success);
#endif
					} else if (request->op == IOPrinp)
					{

						if (call TupleSpaceI.hinp(&response->tuple) == SUCCESS) response->success = TRUE;
						else response->success = FALSE;
#if DEBUG_REMOTE_TS_OP_MGR
						dbg("DBG_USR1", "RemoteTSOpMgr(): Performing rinp, success = %i\n", response->success);
#endif
					} else
					{

						if (call TupleSpaceI.rdp(&response->tuple) == SUCCESS) response->success = TRUE;
						else response->success = FALSE;
#if DEBUG_REMOTE_TS_OP_MGR
						dbg("DBG_USR1", "RemoteTSOpMgr(): Performing rrdp, success = %i\n", response->success);
#endif
					}

					// The only time a result should not be sent is when the
					// operation is a remote OUT and the destination is the UART
					if (request->op == IOProut && response->dest == AM_UART_ADDR)
						send_result = FALSE;

					if (send_result)
					{
						if (response->dest == AM_UART_ADDR) {
							if (call SerialSend_Res.send(response->dest, reply, sizeof(AgillaTSResMsg)))
							{
#if DEBUG_REMOTE_TS_OP_MGR
								dbg("DBG_USR1", "RemoteTSOpMgr(): Sent response to %i.\n", response->dest);
#endif
							} else
							{
								dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send response.\n");
								call MessageBufferI.freeMsg(reply);
							}
						} else{
							if (call Send_Res.send(response->dest, reply, sizeof(AgillaTSResMsg)))
							{
#if DEBUG_REMOTE_TS_OP_MGR
								dbg("DBG_USR1", "RemoteTSOpMgr(): Sent response to %i.\n", response->dest);
#endif
							} else
							{
								dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send response.\n");
								call MessageBufferI.freeMsg(reply);
							}
						}
					}
				} else
				{
					dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: no free message buffer.\n");
				}
			}
			else
			{

				// Forward the request to the appropriate node.	If the destination
				// is the UART, then the request must have been sent from a remote
				// node to this node.	If the destination is not the UART, then
				// the request must have come from the BS.
				//if (call AddressMgrI.isGW())
				bounceMsg(request->dest, m);
				/*TOS_MsgPtr msg = call MessageBufferI.getMsg();
				  if (msg != NULL)
				  {
				  AgillaTSReqMsg* fwdReq = (AgillaTSReqMsg*)msg->data;
				  uint16_t dest = reqest->dest;
				  fwdReq = *request;

				  if (request->dest != TOS_UART_ADDR)
				  bufferedReq->reply = TOS_LOCAL_ADDRESS;	// route message back through *this* base station
				  else
				  {
				// The destination is the UART.	If this is not the GW,
				// find a neighbor that is close to the GW.
				if (!call AddressMgrI.isGW())
				{
				uint8_t numHops = call NeighborListI.getGW(&dest);
				if (numHops == NO_GW)
				{
				dbg(DBG_USR1, "RemoteTSOpMgr(): ERROR: Could not forward request to the UART (no known GW).\n");
				call MessageBufferI.freeMsg(msg);
				return m;
				}
				}
				}
				if (call Send_Req.send(dest, sizeof(AgillaTSReqMsg), &msg))
				{
#if DEBUG_REMOTE_TS_OP_MGR
dbg(DBG_USR1, "RemoteTSOpMgr(): Forwarded reuest to %i.\n", dest);
#endif
} else
{
dbg(DBG_USR1, "RemoteTSOpMgr(): ERROR: Unable to send message.\n");
call MessageBufferI.freeMsg(msg);
}
} else
{
dbg(DBG_USR1, "RemoteTSOpMgr(): ERROR: no free message buffer.\n");
}*/
				}
		}
		return m;
	} // Rcv_Req.receive()


	event message_t* SerialRcv_Req.receive(message_t* m, void* payload, uint8_t len)
	{
		AgillaTSReqMsg* request = (AgillaTSReqMsg*)payload;

#if DEBUG_REMOTE_TS_OP_MGR
		dbg("DBG_USR1", "RemoteTSOpMgr(): Processing request dest=%i, reply=%i, op=%i.\n",
				request->dest, request->reply, request->op);
		call TupleUtilI.printTuple(&request->template);
#endif

		if (request->op == IOPrrdpg)
		{

#if DEBUG_REMOTE_TS_OP_MGR
			dbg("DBG_USR1", "RemoteTSOpMgr(): The request is a rrdpg.\n");
#endif

			if (call TupleSpaceI.rdp(&request->template) == SUCCESS)
			{
				message_t* reply = call MessageBufferI.getMsg();

#if DEBUG_REMOTE_TS_OP_MGR
				dbg("DBG_USR1", "RemoteTSOpMgr(): Match found!\n");
#endif

				if (reply != NULL)
				{
					AgillaTSGResMsg* gresponse = (AgillaTSGResMsg*)(call Packet.getPayload(reply, sizeof(AgillaTSGResMsg)));
					gresponse->addr = TOS_NODE_ID;
					if(request->reply == AM_UART_ADDR){
						if (call SerialSend_GRes.send(request->reply, reply, sizeof(AgillaTSGResMsg)) == SUCCESS)
						{
#if DEBUG_REMOTE_TS_OP_MGR
							dbg("DBG_USR1", "RemoteTSOpMgr(): Sent group response.\n");
#endif
						} else
						{
							dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send group response.\n");
							call MessageBufferI.freeMsg(reply);
						}
					}
					else
					{	
						if (call Send_GRes.send(request->reply, reply, sizeof(AgillaTSGResMsg)) == SUCCESS)
						{
#if DEBUG_REMOTE_TS_OP_MGR
							dbg("DBG_USR1", "RemoteTSOpMgr(): Sent group response.\n");
#endif
						} else
						{
							dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send group response.\n");
							call MessageBufferI.freeMsg(reply);
						}
					}
				} else
				{
					dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: no free message buffer.\n");
				}
			} else
			{
#if DEBUG_REMOTE_TS_OP_MGR
				dbg("DBG_USR1", "RemoteTSOpMgr(): No match found.\n");
#endif
			}
		}

		else if (request->op == IOProutg)
		{
			call TupleSpaceI.out(&request->template);

#if DEBUG_REMOTE_TS_OP_MGR
			dbg("DBG_USR1", "RemoteTSOpMgr(): OUTed tuple in routg operation.\n");
			call TupleUtilI.printTuple(&request->template);
#endif
		}

		else
		{
			if (request->dest == TOS_NODE_ID)
			{
				// The request is destined for this mote.	Perform the request.

				message_t* reply = call MessageBufferI.getMsg();
				if (reply != NULL)
				{
					AgillaTSResMsg* response = (AgillaTSResMsg*)(call Packet.getPayload(reply, sizeof(AgillaTSResMsg)));
					bool send_result = TRUE;

					response->dest = request->reply;
					response->op = request->op;

					// By default send the template back to the requester if
					// no results are found.
					response->tuple = request->template;

					if (request->op == IOProut)
					{

						if (call TupleSpaceI.out(&response->tuple) == SUCCESS) response->success = TRUE;
						else response->success = FALSE;
#if DEBUG_REMOTE_TS_OP_MGR
						dbg("DBG_USR1", "RemoteTSOpMgr(): Performed rout, success = %i\n", response->success);
#endif
					} else if (request->op == IOPrinp)
					{

						if (call TupleSpaceI.hinp(&response->tuple) == SUCCESS) response->success = TRUE;
						else response->success = FALSE;
#if DEBUG_REMOTE_TS_OP_MGR
						dbg("DBG_USR1", "RemoteTSOpMgr(): Performing rinp, success = %i\n", response->success);
#endif
					} else
					{

						if (call TupleSpaceI.rdp(&response->tuple) == SUCCESS) response->success = TRUE;
						else response->success = FALSE;
#if DEBUG_REMOTE_TS_OP_MGR
						dbg("DBG_USR1", "RemoteTSOpMgr(): Performing rrdp, success = %i\n", response->success);
#endif
					}

					// The only time a result should not be sent is when the
					// operation is a remote OUT and the destination is the UART
					if (request->op == IOProut && response->dest == AM_UART_ADDR)
						send_result = FALSE;

					if (send_result)
					{
						if (response->dest == AM_UART_ADDR) {
							if (call SerialSend_Res.send(response->dest, reply, sizeof(AgillaTSResMsg)))
							{
#if DEBUG_REMOTE_TS_OP_MGR
								dbg("DBG_USR1", "RemoteTSOpMgr(): Sent response to %i.\n", response->dest);
#endif
							} else
							{
								dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send response.\n");
								call MessageBufferI.freeMsg(reply);
							}
						} else{
							if (call Send_Res.send(response->dest, reply, sizeof(AgillaTSResMsg)))
							{
#if DEBUG_REMOTE_TS_OP_MGR
								dbg("DBG_USR1", "RemoteTSOpMgr(): Sent response to %i.\n", response->dest);
#endif
							} else
							{
								dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: failed to send response.\n");
								call MessageBufferI.freeMsg(reply);
							}
						}
					}
				} else
				{
					dbg("DBG_USR1", "RemoteTSOpMgr(): ERROR: no free message buffer.\n");
				}
			} else
			{

				// Forward the request to the appropriate node.	If the destination
				// is the UART, then the request must have been sent from a remote
				// node to this node.	If the destination is not the UART, then
				// the request must have come from the BS.
				//if (call AddressMgrI.isGW())
				bounceMsg(request->dest, m);
				/*TOS_MsgPtr msg = call MessageBufferI.getMsg();
				  if (msg != NULL)
				  {
				  AgillaTSReqMsg* fwdReq = (AgillaTSReqMsg*)msg->data;
				  uint16_t dest = reqest->dest;
				  fwdReq = *request;

				  if (request->dest != TOS_UART_ADDR)
				  bufferedReq->reply = TOS_LOCAL_ADDRESS;	// route message back through *this* base station
				  else
				  {
				// The destination is the UART.	If this is not the GW,
				// find a neighbor that is close to the GW.
				if (!call AddressMgrI.isGW())
				{
				uint8_t numHops = call NeighborListI.getGW(&dest);
				if (numHops == NO_GW)
				{
				dbg(DBG_USR1, "RemoteTSOpMgr(): ERROR: Could not forward request to the UART (no known GW).\n");
				call MessageBufferI.freeMsg(msg);
				return m;
				}
				}
				}
				if (call Send_Req.send(dest, sizeof(AgillaTSReqMsg), &msg))
				{
#if DEBUG_REMOTE_TS_OP_MGR
	dbg(DBG_USR1, "RemoteTSOpMgr(): Forwarded reuest to %i.\n", dest);
#endif
	} else
	{
	dbg(DBG_USR1, "RemoteTSOpMgr(): ERROR: Unable to send message.\n");
	call MessageBufferI.freeMsg(msg);
	}
	} else
	{
	dbg(DBG_USR1, "RemoteTSOpMgr(): ERROR: no free message buffer.\n");
	}*/
			}
		}
		return m;
	} // SerialRcv_Req.receive()


	event error_t TupleSpaceI.newTuple(AgillaTuple* tuple)
	{
		return SUCCESS;
	}


	event error_t TupleSpaceI.byteShift(uint16_t from, uint16_t amount)
	{
		return SUCCESS;
	}


	event void Send_Req.sendDone(message_t* m, error_t success)
	{
		call MessageBufferI.freeMsg(m);
		//return SUCCESS;
	}


	event void Send_GRes.sendDone(message_t* m, error_t success)
	{
		call MessageBufferI.freeMsg(m);
		//return SUCCESS;
	}


	event void Send_Res.sendDone(message_t* m, error_t success)
	{
		call MessageBufferI.freeMsg(m);
		//return SUCCESS;
	}

	event void SerialSend_Req.sendDone(message_t* m, error_t success)
	{
		call MessageBufferI.freeMsg(m);
		//return SUCCESS;
	}


	event void SerialSend_GRes.sendDone(message_t* m, error_t success)
	{
		call MessageBufferI.freeMsg(m);
		//return SUCCESS;
	}


	event void SerialSend_Res.sendDone(message_t* m, error_t success)
	{
		call MessageBufferI.freeMsg(m);
		//return SUCCESS;
	}
}

