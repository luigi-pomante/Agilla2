// $Id: AgentSender.java,v 1.12 2006/02/13 18:05:14 chien-liang Exp $

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

import agilla.messages.*;
import agilla.opcodes.BasicOpcodes;

import java.util.*;

/**
 *  Sends an agent into the wireless sensor network.
 *
 * @author Chien-Liang Fok <liangfok@wustl.edu>
 */
public class AgentSender implements AgillaConstants, BasicOpcodes, MessageListenerJ, Runnable 
{
	private static int timerid = 0;
	
	private SNInterface sni;
	private Vector queue;  // a queue of outgoing agents
	private Vector msgQueue = new Vector();
	private boolean waitForAcks;
	
	/**
	 *  Creates an AgentSender.
	 *
	 * @param sni The sensor network interface
	 * @param waitForAcks Whether to wait for ACKs.
	 */
	public AgentSender(SNInterface sni, boolean waitForAcks) {
		this.sni = sni;
		this.queue = new Vector();
		this.waitForAcks = waitForAcks;
//		sni.registerListener(new AgillaAckStateMsgJ(), this);
//		if (waitForAcks) {
//				sni.registerListener(new AgillaAckCodeMsgJ(), this);
//				sni.registerListener(new AgillaAckHeapMsgJ(), this);
//				sni.registerListener(new AgillaAckOpStackMsgJ(), this);
//				sni.registerListener(new AgillaAckRxnMsgJ(), this);
//		}
		new Thread(this).start();
	}
	
	/**
	 * Sends an agent to the specified destination.
	 * 
	 * @param dest The TinyOS address of the destination.
	 * @param Agent The agent to send.
	 */
	public void send(int dest, Agent agent) 
	{
		log("Sending " + agent);
		queue.add(new PendingAgent(dest, agent));
		synchronized(queue) {
			try {
				queue.notifyAll();
			} catch(IllegalMonitorStateException e) {
				e.printStackTrace();
			}
		}
	}

	/**
	 *  The sender thread sits in a loop sending agents placed into the queue.
	 * */
	public void run() 
	{
		while(true) 
		{
			// wait for next agent to send
			synchronized(queue) {  
				while (queue.size() == 0) {
					try {
						queue.wait();
					} catch(Exception e) {
						e.printStackTrace();
					}
				}
			}
			if (queue.size() > 0) {
				PendingAgent cAgent = (PendingAgent)queue.remove(0);
				if (sendStateMsg(cAgent))
					if (sendCodeMsgs(cAgent))
						if (cAgent.nHeapMsgs == 0 || (cAgent.nHeapMsgs > 0 && sendHpMsgs(cAgent)))
							if (cAgent.nOSMsgs == 0 || (cAgent.nOSMsgs > 0 && sendOsMsgs(cAgent))) {
								if (cAgent.nRxnMsgs == 0 || (cAgent.nRxnMsgs > 0 && sendRxnMsgs(cAgent))) {
									log("Done sending agent.");
									continue;
								}
							}
				log("ERROR: Failed to send agent " + cAgent.agent.getID() + "!");
				DialogFactory.messageDialog("Error", "Failed to send agent " + cAgent.agent.getID() + "!");
				//engine.runAgent(cAgent);
			}
		}
	}
	
	public void messageReceived(int to, MessageJ m) 
	{
		log("messageReceived(): " + m);
		msgQueue.add(m);
		synchronized(msgQueue) {
			msgQueue.notifyAll();
		}
//		if (m.getType() == AgillaAckStateMsg.AM_TYPE || (waitForAcks && (
//			m.getType() == AgillaAckCodeMsg.AM_TYPE ||
//			m.getType() == AgillaAckHeapMsg.AM_TYPE||
//			m.getType() == AgillaAckOpStackMsg.AM_TYPE ||
//			m.getType() == AgillaAckRxnMsg.AM_TYPE))) {
//			if (timeoutTimer != null)
//				timeoutTimer.kill();
//			synchronized(lock) {
//				this.ackMsg = m;
//				try {
//					lock.notifyAll();
//				} catch (Exception e) {
//					e.printStackTrace();
//				}
//			}
//		}
	}
	
	private boolean sendStateMsg(PendingAgent cAgent) 
	{
		// create the state message
		AgillaStateMsgJ msg = new AgillaStateMsgJ(
			cAgent.dest,
			TOS_LOCAL_ADDRESS, // reply address
			cAgent.agent.getID(), BasicOpcodes.OPsmove, cAgent.agent.getOpStack().sizeInBytes(),
			cAgent.agent.getPC(),
			cAgent.agent.getCondition(),
			cAgent.agent.codeSize(),
			cAgent.nHeapMsgs,
			cAgent.nRxnMsgs); // numRxnMsgs
		logSendState("StateMsg:\n" + msg + "\n\n");
				
		int nTries = 0;
				
		while(nTries++ < AGILLA_MIGRATE_NUM_TIMEOUTS) 
		{
			logSendState("Sending state message to " + cAgent.dest + "...");
			
			// register listener to receive ack state messages
			sni.registerListener(new AgillaAckStateMsgJ(), this);
			
			// send the state message
			sendMsg(msg);
			
			// start the timer
			TimeoutTimer timer = new TimeoutTimer(msgQueue, AGILLA_SNDR_RXMIT_TIMER, timerid++);
			
			boolean done = false;			
			int nBadAcks = 0;
			
			// loop over the message queue...
			while (!done) 
			{
				logSendState("Awaiting ACK state message from " + cAgent.dest + "...");
				
				MessageJ rMsg = waitForMsg();
				
				if (rMsg instanceof TimeoutMsgJ && ((TimeoutMsgJ)rMsg).id() == timer.id())
				{
					done = true;  // break out of inner while loop
					sni.deregisterListener(new AgillaAckStateMsgJ(), this);									
					logSendState("Timed out while waiting for ack from " + cAgent.dest + ", nTries = " + nTries +"...");						
				}
				
				else if (rMsg instanceof AgillaAckStateMsgJ) 
				{
					AgillaAckStateMsgJ ack = (AgillaAckStateMsgJ)rMsg;
					
					if (ack.id().equals(cAgent.agent.getID())) 
					{
						logSendState("... got an ACK message, " + (ack.accept() == AGILLA_ACCEPT ? "ACCEPT" : "REJECT"));
						timer.kill();		
						sni.deregisterListener(new AgillaAckStateMsgJ(), this);
						return (ack.accept() == AGILLA_ACCEPT);												
					} else 
					{
						logSendState("Ack was for the wrong agent " + ack.id());
						if (++nBadAcks == AGILLA_MIGRATE_NUM_BAD_ACKS) 
						{
							done = true;
							timer.kill();
							sni.deregisterListener(new AgillaAckStateMsgJ(), this);
							logSendState("Exceeded max number of bad acks while sending state.");							
						}
					}			
				}			
			} // while(!done)
		} // while(nTries < AGILLA_MIGRATE_NUM_TIMEOUTS) 	
		logSendState("ERROR: Exceeded maximum number of timeouts when sending state.");
		return false;
	} // sendStateMsg

	
	/**
	 * Sends all of the code messages belonging to an agent.
	 *
	 * @param cAgent The agent being migrated.
	 * @return true if successful, false otherwise.
	 */
	private boolean sendCodeMsgs(PendingAgent cAgent) 
	{
		// For each code block...
		for (short msgNum = 0; msgNum < cAgent.nCodeBlocks; msgNum++) 
		{
			// Create the code message
			AgillaCodeMsgJ msg = new AgillaCodeMsgJ(cAgent.agent.getID(), TOS_LOCAL_ADDRESS, msgNum);			
			int firstBlockAddr = msgNum*AgillaCodeMsg.numElements_code();
			int lastBlockAddr = firstBlockAddr + AgillaCodeMsg.numElements_code();
			for (int j = firstBlockAddr; j < cAgent.agent.codeSize() && j < lastBlockAddr; j++) {
				msg.setCode(j-firstBlockAddr, cAgent.agent.getInstr(j));
			}
			logSendCode("CODE message " + msgNum + ": \n" + msg);
			logSendCode("Sending CODE message " + msgNum + " to " + cAgent.dest + "...");
			msgQueue.clear();
			if (!sendCodeMsg(msg))
				return false;
		}
		logSendCode("Sent Code.");
		return true;
	}
	
	private boolean sendCodeMsg(AgillaCodeMsgJ msg) 
	{
		if (waitForAcks) 
		{
			int nTries = 0;
			
			while(nTries++ < AGILLA_MIGRATE_NUM_TIMEOUTS) 
			{				
				
				// register listener to receive ack code messages
				sni.registerListener(new AgillaAckCodeMsgJ(), this);
				
				// send the code message
				sendMsg(msg);
				
				// start the timer
				TimeoutTimer timer = new TimeoutTimer(msgQueue, AGILLA_SNDR_RXMIT_TIMER, timerid++);
				
				boolean done = false;			
				int nBadAcks = 0;
				
				// loop over the message queue...
				while (!done) 
				{
					logSendCode("Awaiting ACK code message ...");
					
					MessageJ rMsg = waitForMsg();
					
					if (rMsg instanceof TimeoutMsgJ && ((TimeoutMsgJ)rMsg).id() == timer.id())
					{
						done = true;  // break out of inner while loop
						sni.deregisterListener(new AgillaAckCodeMsgJ(), this);									
						logSendCode("Timed out while waiting for ack, nTries = " + nTries +"...");						
					}
					
					else if (rMsg instanceof AgillaAckCodeMsgJ) 
					{
						AgillaAckCodeMsgJ ack = (AgillaAckCodeMsgJ)rMsg;
						
						if (ack.getID().equals(msg.id()) && ack.getMsgNum() == msg.msgNum()) 
						{
							logSendCode("... got an ACK message, " + (ack.getAccept() == AGILLA_ACCEPT ? "ACCEPT" : "REJECT"));
							timer.kill();
							sni.deregisterListener(new AgillaAckCodeMsgJ(), this);	
							return (ack.getAccept() == AGILLA_ACCEPT); 								
						} 
						else 
						{
							logSendCode("ACK for wrong agent (" + ack.getID() + "!=" + msg.id() + ") or wrong msgNum (" + ack.getMsgNum() + "!=" + msg.msgNum() + ")");								
							
							if (++nBadAcks == AGILLA_MIGRATE_NUM_BAD_ACKS) 
							{
								logSendCode("Exceeded maximum number of bad acknowledgements while sending code.");
								done = true;
								timer.kill();
								sni.deregisterListener(new AgillaAckCodeMsgJ(), this);								
								return false;
							}
						}
					}
				} // while(!done)
			} // while(nTries < AGILLA_MIGRATE_NUM_TIMEOUTS)
						
			logSendCode("Exceeded number of timeouts while sending code messages.");
			return false;			
		}
		
		// do not wait for ACKs
		else 
		{			
			sendMsg(msg);
			return true;
		}
	}
	
	private int fillHeapMsg(PendingAgent cAgent, AgillaHeapMsgJ msg) 
	{
		AgillaStackVariable[] heap = cAgent.agent.getHeap();
		boolean foundFirst = false;
		int hpAddr1 = 0;
		
		while (msg.size() < AgillaHeapMsg.numElements_data()/*AGILLA_HEAP_MSG_SIZE*/ && cAgent.hpIndex < AGILLA_HEAP_SIZE) {
			if (heap[cAgent.hpIndex].getType() != AGILLA_TYPE_INVALID) {
				msg.addHeapItem(cAgent.hpIndex, heap[cAgent.hpIndex]);
				if (!foundFirst) {
					foundFirst = true;
					hpAddr1 = cAgent.hpIndex;
				}
			}
			cAgent.hpIndex++;
		}
		return hpAddr1;
	} // fillHeapMsg
	
	private boolean sendHpMsgs(PendingAgent cAgent) 
	{
		cAgent.hpIndex = 0;
		
		for (int i = 0; i < cAgent.nHeapMsgs; i++) 
		{
			AgillaHeapMsgJ msg = new AgillaHeapMsgJ(cAgent.agent.getID());
			int rhpIndex =  fillHeapMsg(cAgent, msg);
			
			logSendHeap("HeapMsg: \n" + msg + "\n\n");
			if (!sendHpMsg(msg, rhpIndex))
				return false;			
		}
		logSendHeap("Sent Heap.");
		return true;
	}
	
	private boolean sendHpMsg(AgillaHeapMsgJ msg, int rhpIndex)
	{
		if (waitForAcks) 
		{
			int nTries = 0;
			
			while(nTries++ < AGILLA_MIGRATE_NUM_TIMEOUTS) 
			{				
				// register listener to receive ack heap messages
				sni.registerListener(new AgillaAckHeapMsgJ(), this);
				
				// send the heap message
				sendMsg(msg);
				
				// start the timer
				TimeoutTimer timer = new TimeoutTimer(msgQueue, AGILLA_SNDR_RXMIT_TIMER, timerid++);
				
				boolean done = false;			
				int nBadAcks = 0;
				
				// loop over the message queue...
				while (!done) 
				{
					logSendHeap("Awaiting ACK heap message ...");
					
					MessageJ rMsg = waitForMsg();
					
					if (rMsg instanceof TimeoutMsgJ && ((TimeoutMsgJ)rMsg).id() == timer.id())
					{
						done = true;  // break out of inner while loop
						sni.deregisterListener(new AgillaAckHeapMsgJ(), this);									
						logSendHeap("Timed out while waiting for ack, nTries = " + nTries +"...");						
					}
					
					else if (rMsg instanceof AgillaAckHeapMsgJ) 
					{					
						AgillaAckHeapMsgJ ack = (AgillaAckHeapMsgJ)rMsg;
						
						if (ack.getID().equals(msg.id()) && ack.getAddr1() == rhpIndex) 
						{
							logSendHeap("... got an ACK message, " + (ack.getAccept() == AGILLA_ACCEPT ? "ACCEPT" : "REJECT"));
							timer.kill();
							sni.deregisterListener(new AgillaAckCodeMsgJ(), this);	
							return (ack.getAccept() == AGILLA_ACCEPT); 								
						} 
						else 
						{
							logSendHeap("ACK for wrong agent (" + ack.getID() + "!=" + msg.id() + ") or wrong first address (" + ack.getAddr1() + "!=" + rhpIndex + ")");								
							
							if (++nBadAcks == AGILLA_MIGRATE_NUM_BAD_ACKS) 
							{
								logSendHeap("Exceeded maximum number of bad acknowledgements while sending heap.");
								done = true;
								timer.kill();
								sni.deregisterListener(new AgillaAckCodeMsgJ(), this);								
								return false;
							}
						}
					}
				} // while(!done)
			} // while(nTries < AGILLA_MIGRATE_NUM_TIMEOUTS)
						
			logSendHeap("Exceeded number of timeouts while sending heap messages.");
			return false;			
		}
		
		// do not wait for ACKs
		else 
		{			
			sendMsg(msg);
			return true;
		}
	}
	
	private void fillOpStackMsg(PendingAgent cAgent, AgillaOpStackMsgJ msg) {			
		byte[] osBytes = cAgent.agent.getOpStack().toByteArray();
		int curr = 0;
		
		while (cAgent.osIndex < osBytes.length &&
				curr < msg.dataLength()) {
		  msg.setData(curr++, osBytes[cAgent.osIndex++]);
		}
		
		// fill in the rest with zeros
		while (curr < msg.dataLength()) {
			msg.setData(curr++, (short)0);
		}
	} // fillOpStackMsg
	
	private boolean sendOsMsgs(PendingAgent cAgent) 
	{
		cAgent.osIndex = 0;
		for (int msgNum = 0; msgNum < cAgent.nOSMsgs; msgNum++) 
		{
			int startAddr = cAgent.osIndex;
			AgillaOpStackMsgJ msg = new AgillaOpStackMsgJ(cAgent.agent.getID(), TOS_LOCAL_ADDRESS, cAgent.osIndex);
			fillOpStackMsg(cAgent, msg);
			logSendOpStack("OpStack Message" + msgNum + ": \n" + msg + "\n\n");
			
			if (!sendOsMsg(msg, startAddr))
				return false;
		}
		logSendOpStack("Sent OpStack.");
		return true;
	}
	
	private boolean sendOsMsg(AgillaOpStackMsgJ msg, int startAddr)
	{		
		if (waitForAcks) 
		{
			int nTries = 0;
			
			while(nTries++ < AGILLA_MIGRATE_NUM_TIMEOUTS) 
			{				
				// register listener to receive ack opstack messages
				sni.registerListener(new AgillaAckOpStackMsgJ(), this);
				
				// send the opstack message
				sendMsg(msg);
				
				// start the timer
				TimeoutTimer timer = new TimeoutTimer(msgQueue, AGILLA_SNDR_RXMIT_TIMER, timerid++);
				
				boolean done = false;			
				int nBadAcks = 0;
				
				// loop over the message queue...
				while (!done) 
				{
					logSendOpStack("Awaiting ACK opstack message ...");
					
					MessageJ rMsg = waitForMsg();
					
					if (rMsg instanceof TimeoutMsgJ && ((TimeoutMsgJ)rMsg).id() == timer.id())
					{
						done = true;  // break out of inner while loop
						sni.deregisterListener(new AgillaAckOpStackMsgJ(), this);									
						logSendOpStack("Timed out while waiting for ack, nTries = " + nTries +"...");						
					}
					
					else if (rMsg instanceof AgillaAckOpStackMsgJ) 
					{					
						AgillaAckOpStackMsgJ ack = (AgillaAckOpStackMsgJ)rMsg;
						
						if (ack.getID().equals(msg.id()) && ack.getStartAddr() == startAddr) 
						{
							logSendOpStack("... got an ACK message, " + (ack.getAccept() == AGILLA_ACCEPT ? "ACCEPT" : "REJECT"));
							timer.kill();
							sni.deregisterListener(new AgillaAckOpStackMsgJ(), this);	
							return ack.getAccept() == AGILLA_ACCEPT; 								
						} 
						else 
						{
							logSendOpStack("ACK for wrong agent (" + ack.getID() + "!=" + msg.id() + ") or wrong start address (" + ack.getStartAddr() + "!=" + startAddr + ")");								
							
							if (++nBadAcks == AGILLA_MIGRATE_NUM_BAD_ACKS) 
							{
								logSendOpStack("Exceeded maximum number of bad acknowledgements while sending opstack.");
								done = true;
								timer.kill();
								sni.deregisterListener(new AgillaAckOpStackMsgJ(), this);								
								return false;
							}
						}
					}
				} // while(!done)
			} // while(nTries < AGILLA_MIGRATE_NUM_TIMEOUTS)
						
			logSendOpStack("Exceeded number of timeouts while sending opstack messages.");
			return false;			
		}
		
		// do not wait for ACKs
		else 
		{			
			sendMsg(msg);
			return true;
		}
	}
	
	private boolean sendRxnMsgs(PendingAgent cAgent) 
	{
		for (short msgNum = 0; msgNum < cAgent.nRxnMsgs; msgNum++) 
		{
			AgillaRxnMsgJ oldMsg = cAgent.agent.getRxns()[msgNum];
			AgillaRxnMsgJ msg = new AgillaRxnMsgJ(msgNum,
					new Reaction(cAgent.agent.getID(), oldMsg.getReaction().getPC(), oldMsg.getReaction().getTemplate()));
			logSendRxn("RxnMsg " + msgNum + ": \n" + msg + "\n\n");
			
			if (!sendRxnMsg(msg))
				return false;
		}
		log("Sent Reactions.");
		return true;
	}
	
	private boolean sendRxnMsg(AgillaRxnMsgJ msg) 
	{
		if (waitForAcks) 
		{
			int nTries = 0;
			
			while(nTries++ < AGILLA_MIGRATE_NUM_TIMEOUTS) 
			{				
				// register listener to receive ack reaction messages
				sni.registerListener(new AgillaAckRxnMsgJ(), this);
				
				// send the reaction message
				sendMsg(msg);
				
				// start the timer
				TimeoutTimer timer = new TimeoutTimer(msgQueue, AGILLA_SNDR_RXMIT_TIMER, timerid++);
				
				boolean done = false;			
				int nBadAcks = 0;
				
				// loop over the message queue...
				while (!done) 
				{
					logSendRxn("Awaiting ACK reaction message ...");
					
					MessageJ rMsg = waitForMsg();
					
					if (rMsg instanceof TimeoutMsgJ && ((TimeoutMsgJ)rMsg).id() == timer.id())
					{
						done = true;  // break out of inner while loop
						sni.deregisterListener(new AgillaAckRxnMsgJ(), this);									
						logSendRxn("Timed out while waiting for ack, nTries = " + nTries +"...");						
					}
					
					else if (rMsg instanceof AgillaAckRxnMsgJ) 
					{					
						AgillaAckRxnMsgJ ack = (AgillaAckRxnMsgJ)rMsg;
						
						if (ack.getID().equals(msg.id()) && ack.getmsgNum() == msg.getMsgNum())
						{
							logSendRxn("... got an ACK message, " + (ack.getAccept() == AGILLA_ACCEPT ? "ACCEPT" : "REJECT"));
							timer.kill();
							sni.deregisterListener(new AgillaAckRxnMsgJ(), this);	
							return ack.getAccept() == AGILLA_ACCEPT; 								
						} 
						else 
						{
							logSendRxn("ACK for wrong agent (" + ack.getID() + "!=" + msg.id() + ") or wrong message number (" + ack.getmsgNum() + "!=" + msg.getMsgNum() + ")");								
							
							if (++nBadAcks == AGILLA_MIGRATE_NUM_BAD_ACKS) 
							{
								logSendRxn("Exceeded maximum number of bad acknowledgements while sending rxn msg.");
								done = true;
								timer.kill();
								sni.deregisterListener(new AgillaAckRxnMsgJ(), this);								
								return false;
							}
						}
					}
				} // while(!done)
			} // while(nTries < AGILLA_MIGRATE_NUM_TIMEOUTS)
						
			logSendRxn("Exceeded number of timeouts while sending opstack messages.");
			return false;			
		}
		
		// do not wait for ACKs
		else 
		{			
			sendMsg(msg);
			return true;
		}		
	}
	

	/**
	 *  Sends a message to the base station mote.  Sets the ackMsg variable to be
	 *  null.  If acknowledgements are enabled, start a timeout timer.
	 *  
	 * @param msg  The message to send.
	 * @return whether the message was sent.
	 */
	private boolean sendMsg(MessageJ msg) 
	{		
		try {
			// Send the message via broadcast so whatever mote is attached
			// to the base station will receive it.
			sni.send(msg, TOS_BCAST_ADDRESS);
			return true;
		} catch(Exception e) {
			e.printStackTrace();
			return false;
		}		
	}
	
	private MessageJ waitForMsg() {
		synchronized(msgQueue) 
		{  
			while (msgQueue.size() == 0) {
				try {
					msgQueue.wait();
				} catch(Exception e) {
					e.printStackTrace();
				}
			}
		}
		if (msgQueue.size() > 0) {
			return (MessageJ)msgQueue.remove(0);
		} else {
			log("BUG: Recursive call to waitForMsg()...");
			return waitForMsg();
		}			
	}
	
	/**
	 *  Encapsulates an agent context and the destination it wants migrate to.
	 */
	private class PendingAgent {
		Agent agent;
		int dest, nCodeBlocks;
		short nHeapMsgs, nOSMsgs, nRxnMsgs;
		short hpIndex, osIndex = 0;
		
		/**
		 *  Creates a PendingAgent object.  This object encapsulates an
		 *  agent that is being sent.
		 *  
		 * @param dest The destination address.
		 * @param agent The agent to send.
		 */
		public PendingAgent(int dest, Agent agent) {
			this.agent = agent;
			this.dest = dest;
			this.nCodeBlocks = nCodeBlocks(agent);
			this.nHeapMsgs = nHeapMsgs(agent);
			this.nOSMsgs = nOSMsgs(agent);
			this.nRxnMsgs = nRxnMsgs(agent);
				
			log("PendingAgent: nCodeBlocks = " + nCodeBlocks);
			log("PendingAgent: nHeapMsgs = " + nHeapMsgs);
			log("PendingAgent: nOSMsgs = " + nOSMsgs);
			log("PendingAgent: nRxnMsgs = " + nRxnMsgs);
		}

		private int nCodeBlocks(Agent agent) {
			int result = agent.codeSize() / AgillaCodeMsg.numElements_code()/*AgillaConstants.AGILLA_CODE_BLOCK_SIZE*/;
			if(result * AgillaCodeMsg.numElements_code()/*AgillaConstants.AGILLA_CODE_BLOCK_SIZE*/ < agent.codeSize())
				result++;
			return result;
		}
		
		private short nHeapMsgs(Agent agent) {
			int counter = 0, numBytes = 0;
			AgillaStackVariable[] heap = agent.getHeap();
			
			for (int i = 0; i < AGILLA_HEAP_SIZE; i++) {
				if (heap[i].getType() != AGILLA_TYPE_INVALID) {
					int nextSize = heap[i].getSize() + 2;
					if (numBytes + nextSize < AgillaHeapMsg.numElements_data()/*AGILLA_HEAP_MSG_SIZE*/) {
						numBytes += nextSize;
					} else {
						numBytes = nextSize;
						counter++;
					}
				}
			}
			if (numBytes == 0)
				return (short)counter;
			else
				return (short)(counter + 1);
		}
		
		/**
		 * Calculate the number of operand stack messages.
		 * 
		 * @param agent The agent holding the op stack
		 * @return The number of op stack messages.
		 */
		private short nOSMsgs(Agent agent)  {
			byte[] osBytes = agent.getOpStack().toByteArray();
			short result = (short)(osBytes.length / AgillaOpStackMsg.numElements_data());
			if (result * AgillaOpStackMsg.numElements_data() < osBytes.length)
				result++;
			return result;
			/*int counter = 0, numBytes = 0;
			OpStack os = agent.getOpStack();
			try {
				for (int i = 0; i < os.size(); i++) {
					AgillaStackVariable sv = os.get(i);
					int nextSize = sv.getSize() + 1;
					if (numBytes + nextSize < AgillaOpStackMsg.numElements_data()) {
						numBytes += nextSize;
					} else {
						numBytes = nextSize;
						counter++;
					}
				}
			} catch(OpStackException e) {
				e.printStackTrace();
				System.exit(0);
			}
			if (numBytes == 0)
				return (short)counter;
			else
				return (short)(counter+1);
			*/
			
		}
		
		private short nRxnMsgs(Agent agent) {
			return (short)agent.getRxns().length;
		}
	}
	
	private void logSendState(String msg) {
		log("SendState(): " + msg);
	}
	
	private void logSendCode(String msg) {
		log("SendCode(): " + msg);
	}

	private void logSendHeap(String msg) {
		log("SendHeap(): " + msg);
	}
	
	private void logSendOpStack(String msg) {
		log("SendOpStack(): " + msg);
	}

	private void logSendRxn(String msg) {
		log("SendRxn(): " + msg);
	}
	
	private void log(String msg) {
		Debugger.dbg("AgentSender", msg);
	}
}


