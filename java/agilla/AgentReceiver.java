// $Id: AgentReceiver.java,v 1.2 2005/11/11 02:15:49 chien-liang Exp $

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

import java.io.*;
import java.util.*;

import net.tinyos.message.*;
import agilla.messages.*;
import agilla.variables.*;

/**
 * AgentReceiver.java
 *
 * @author Greg Hackmann
 * @author Chien-Liang Fok
 */
public class AgentReceiver implements MessageListener, AgillaConstants
{
	private MoteIF moteIF;
	private Vector listeners = new Vector();
	private boolean useAcks;
	
	/**
	 * Creates an AgentReceiver.
	 *
	 * @param moteIF the {@link MoteIF} to listen for agents on
	 * @param useAcks whether ACKs should be sent
	 */
	public AgentReceiver(MoteIF moteIF, boolean useAcks)
	{
		this.moteIF = moteIF;
		this.useAcks = useAcks;
		moteIF.registerListener(new AgillaStateMsg(), this);
	}
	
	/**
	 * Add a listener for migrating agents.
	 *
	 * @param listener the listener to add
	 */
	public void addMigrationListener(MigrationListener listener)
	{
		listeners.add(listener);
	}

	/**
	 * Removes a listener for migrating agents.
	 *
	 * @param listener the listener to remove
	 */
	public void removeMigrationListener(MigrationListener listener)
	{
		listeners.remove(listener);
	}

	public void messageReceived(int to, Message msg)
	{
		AgillaStateMsg state = (AgillaStateMsg)msg;
		Debugger.dbg("AgentReceiver", "Received state message: " + state);
		if(state.get_dest() == TOS_UART_ADDRESS)
			new CaptureMigrationThread(state).start();
		/* Start listening for an agent if the destination is UART_X, UART_Y */
	}
	
	private class CaptureMigrationThread extends Thread implements MessageListener
	{
		private final AgillaStateMsg state;
		private TimedResultLock lock = null;

		private CaptureMigrationThread(AgillaStateMsg state)
		{
			super("AgentReceiver.CaptureMigrationThread");
			this.state = state;
		}

		public void messageReceived(int to, Message m)
		{
			//log("Received " + m);
			if(lock != null && lock.isLocked())
				lock.unlock(m);
		}
		
		public void run()
		{
			try
			{
				AgillaAckStateMsgJ stateAck = new AgillaAckStateMsgJ(new AgillaAgentID(state.get_id_id()), AgillaConstants.AGILLA_ACCEPT);
				log("Sending state ACK " + stateAck + " to " + state.get_replyAddr());
				moteIF.send(state.get_replyAddr(), stateAck.toTOSMsg());

				byte [] code = getCode();
				if(code == null)
				{
					log("Could not receive code");
					return;
				}

				AgillaStackVariable [] heap = getHeap();
				if(heap == null)
				{
					log("Could not receive heap");
					return;
				}
				
				OpStack opStack = getOpStack();
				if(opStack == null)
				{
					log("Could not receive op stack");
					return;
				}
				
				AgillaRxnMsgJ [] rxns = getRxns();
				if(rxns == null)
				{
					log("Could not receive rxns");
					return;
				}
				
				Agent agent = new Agent(new AgillaAgentID(), code, state.get_pc(), state.get_condition(), opStack, heap, rxns);
				
				log("Received Agent: " + agent);
				
				synchronized(listeners)
				{
					for(Iterator iter = listeners.iterator(); iter.hasNext();)
					{
						MigrationListener listeners = (MigrationListener)iter.next();
						listeners.agentMigrated(agent);
					}
				}
			}
			catch(IOException e)
			{
				e.printStackTrace();
			}
		}
		
		private byte [] getCode() throws IOException
		{
			int numCodeBlocks = state.get_codeSize() / AgillaCodeMsg.numElements_code()/*AgillaConstants.AGILLA_CODE_BLOCK_SIZE*/;
			if(state.get_codeSize() % AgillaCodeMsg.numElements_code()/*AgillaConstants.AGILLA_CODE_BLOCK_SIZE*/ > 0) numCodeBlocks++;
			log("Expecting " + numCodeBlocks + " code blocks");
			/* Compute the number of code blocks expected */
						
			byte [][] codeBlocks = new byte[numCodeBlocks][];
			/* For each block */
			for(int i = 0; i < codeBlocks.length; i++)
			{
				boolean done = false;
				/* Until we get an acceptable code block */
				while(!done)
				{
					lock = new TimedResultLock(AgillaConstants.AGILLA_RCVR_ABORT_TIMER);
					
					log("Waiting for code block " + i);
					moteIF.registerListener(new AgillaCodeMsg(), this);
					Message msg = (Message)lock.lock();
					if(msg == null) return null;
					moteIF.deregisterListener(new AgillaCodeMsg(), this);
					/* Wait for the incoming code block, or return null if we time out */
					
					if(!(msg instanceof AgillaCodeMsg))
						continue;
					/* Skip messages that aren't code blocks */
					
					AgillaCodeMsg code = (AgillaCodeMsg)msg;
					if(/*code.get_replyAddr() != state.get_replyAddr() ||*/ code.get_id_id() != state.get_id_id())
						continue;
					/* Skip code blocks that don't belong to the right agent */
					log("Received code block " + code);
					
					if (useAcks) {
						AgillaAckCodeMsgJ codeAck = new AgillaAckCodeMsgJ(new AgillaAgentID(state.get_id_id()), AgillaConstants.AGILLA_ACCEPT, (short)code.get_msgNum());
						log("Sending code ACK " + codeAck + " to " + state.get_replyAddr());
						moteIF.send(state.get_replyAddr(), codeAck.toTOSMsg());
						/* ACK the block */
					}
					
					if(code.get_msgNum() < i)
						continue;
					/* Throw it away if we've already ACKed it before.  We don't throw it away before ACKing, since one of the
					   previous ACKs could have been lost. */
					
					codeBlocks[i] = new byte[code.get_code().length];
					System.arraycopy(code.dataGet(), code.baseOffset() + AgillaCodeMsg.offset_code(0), codeBlocks[i], 0, codeBlocks[i].length);
					log("Saved code block #" + i);
					
					done = true;
				}
			}
			
			ByteArrayOutputStream out = new ByteArrayOutputStream();
			for(int i = 0; i < codeBlocks.length; i++)
				out.write(codeBlocks[i]);
			
			return out.toByteArray();
		}
		
		private AgillaStackVariable [] getHeap() throws IOException
		{
			AgillaHeapMsg [] heapBlocks = new AgillaHeapMsg[state.get_numHpMsgs()];
			log("Expecting " + state.get_numHpMsgs() + " heap blocks");
			
			short lastHeapAcked = -1;
			for(int i = 0; i < heapBlocks.length; i++)
			{
				boolean done = false;
				while(!done)
				{
					lock = new TimedResultLock(AgillaConstants.AGILLA_RCVR_ABORT_TIMER);
					
					log("Waiting for heap block " + i);
					moteIF.registerListener(new AgillaHeapMsg(), this);
					Message msg = (Message)lock.lock();
					if(msg == null) return null;
					moteIF.deregisterListener(new AgillaHeapMsg(), this);
					
					if(!(msg instanceof AgillaHeapMsg))
						continue;
					
					AgillaHeapMsg heap = (AgillaHeapMsg)msg;
					short firstHeap = heap.get_data()[0];
					if(/*heap.get_replyAddr() != state.get_replyAddr() ||*/ heap.get_id_id() != state.get_id_id())
						continue;
					log("Received heap block " + new AgillaHeapMsgJ(heap));
					
					if (useAcks) {
						AgillaAckHeapMsgJ heapAck = new AgillaAckHeapMsgJ(new AgillaAgentID(state.get_id_id()), AgillaConstants.AGILLA_ACCEPT, firstHeap);
						log("Sending heap ACK " + heapAck + " to " + state.get_replyAddr());
						moteIF.send(state.get_replyAddr(), heapAck.toTOSMsg());
					}
					
					if(firstHeap <= lastHeapAcked)
						continue;
					
					heapBlocks[i] = heap;
					log("Saved heap block #" + i);
					
					lastHeapAcked = firstHeap;
					done = true;
				}
			}
			
			AgillaStackVariable [] heap = new AgillaStackVariable[AgillaConstants.AGILLA_HEAP_SIZE];

			for(int i = 0; i < heapBlocks.length; i++)
			{
				AgillaHeapMsgJ msg = new AgillaHeapMsgJ(heapBlocks[i]);
				for(short j = 0; j < msg.numVariables(); j++)
				{
					AgillaStackVariable v = msg.getData(j);
					short addr = msg.getAddr(j);
					if(addr < heap.length)
						heap[addr] = v;
				}
			}
			
			for(int i = 0; i < heap.length; i++)
				if(heap[i] == null)
					heap[i] = new AgillaInvalidVariable();
			
			return heap;
		}
		
		private OpStack getOpStack() throws IOException
		{
			int numOpStackBlocks = state.get_sp() / AgillaOpStackMsg.numElements_data()/*AgillaConstants.AGILLA_OS_MSG_SIZE*/;
			if(state.get_sp() % AgillaOpStackMsg.numElements_data()/*AgillaConstants.AGILLA_OS_MSG_SIZE*/ > 0) numOpStackBlocks++;
			log("Expecting " + numOpStackBlocks + " opstack blocks");
			
			AgillaOpStackMsg [] opStackBlocks = new AgillaOpStackMsg[numOpStackBlocks];
			short lastOpStackAcked = -1;
			for(int i = 0; i < opStackBlocks.length; i++)
			{
				boolean done = false;
				while(!done)
				{
					lock = new TimedResultLock(AgillaConstants.AGILLA_RCVR_ABORT_TIMER);

					log("Waiting for op stack block " + i);
					moteIF.registerListener(new AgillaOpStackMsg(), this);
					Message msg = (Message)lock.lock();
					if(msg == null) return null;
					moteIF.deregisterListener(new AgillaOpStackMsg(), this);
					
					if(!(msg instanceof AgillaOpStackMsg))
						continue;
					
					AgillaOpStackMsg opStack = (AgillaOpStackMsg)msg;
					if(/*opStack.get_replyAddr() != state.get_replyAddr() ||*/ opStack.get_id_id() != state.get_id_id())
						continue;
					log("Received op stack block " + opStack);
					
					if (useAcks) {
						AgillaAckOpStackMsgJ opStackAck = new AgillaAckOpStackMsgJ(new AgillaAgentID(state.get_id_id()), AgillaConstants.AGILLA_ACCEPT, (short)opStack.get_startAddr());
						log("Sending op stack ACK " + opStackAck + " to " + state.get_replyAddr());
						moteIF.send(state.get_replyAddr(), opStackAck.toTOSMsg());
					}
					
					if(opStack.get_startAddr() <= lastOpStackAcked)
						continue;
					
					opStackBlocks[i] = opStack;
					log("Saved op stack block #" + i);
					
					lastOpStackAcked = opStack.get_startAddr();
					done = true;
				}
			}
			
			OpStack opStack = new OpStack(opStackBlocks, state.get_sp());
			return opStack;
		}
		
		private AgillaRxnMsgJ [] getRxns() throws IOException
		{
			AgillaRxnMsg [] rxnBlocks = new AgillaRxnMsg[state.get_numRxnMsgs()];
			log("Expecting " + state.get_numRxnMsgs() + " rxn blocks");
			
			for(int i = 0; i < rxnBlocks.length; i++)
			{
				boolean done = false;
				while(!done)
				{
					lock = new TimedResultLock(AgillaConstants.AGILLA_RCVR_ABORT_TIMER);
					
					log("Waiting for rxn block " + i);
					moteIF.registerListener(new AgillaRxnMsg(), this);
					Message msg = (Message)lock.lock();
					if(msg == null) return null;
					moteIF.deregisterListener(new AgillaRxnMsg(), this);
										
					if(!(msg instanceof AgillaRxnMsg))
						continue;
					
					AgillaRxnMsg rxn = (AgillaRxnMsg)msg;
					if(/*rxn.get_replyAddr() != state.get_replyAddr() ||*/ rxn.get_rxn_id_id() != state.get_id_id())
						continue;
					log("Received rxn block " + rxn);
					
					if (useAcks) {
						AgillaAckRxnMsgJ rxnAck = new AgillaAckRxnMsgJ(new AgillaAgentID(state.get_id_id()), AgillaConstants.AGILLA_ACCEPT, (short)rxn.get_msgNum());
						log("Sending rxn ack " + rxnAck + " to " + state.get_replyAddr() + " type = " + rxnAck.getType());
						moteIF.send(state.get_replyAddr(), rxnAck.toTOSMsg());
					}
					if(rxn.get_msgNum() < i)
						continue;
					
					rxnBlocks[i] = rxn;
					log("Saved rxn block #" + i);
					
					done = true;
				}
			}
			
			AgillaRxnMsgJ [] rxns = new AgillaRxnMsgJ[rxnBlocks.length];
			for(int i = 0; i < rxns.length; i++)
				rxns[i] = new AgillaRxnMsgJ(rxnBlocks[i]);
			
			return rxns;
		}
		
		private final void log(String text) { Debugger.dbg("AgentReceiver.CaptureMigrationThread", text); }
	}
}

class TimedResultLock
{
	private Object result = null;
	private boolean timedOut = false;
	private Thread timeoutThread = null;

	private final long timeout;
	
	public TimedResultLock(long timeout)
	{
		this.timeout = timeout;
	}
	
	/**
	 * Blocks until the lock is released.  When {@link #unlock(Object)} is
	 * called, it will release the lock; whatever <tt>Object</tt> was passed
	 * to <tt>unlock()</tt> will be returned by this method.
	 *
	 * @return the <tt>Object</tt> passed to <tt>unlock()</tt>
	 */
	public synchronized Object lock()
	{
		/* Start a thread to notify us on timeouts */
		timeoutThread = new Thread("TimedResultLock")
		{
			public void run()
			{
				/* Try to sleep during the timeout */
				synchronized(this)
				{
					try
					{
						sleep(timeout);
					}
					catch(InterruptedException e)
					{
						if(result != null) return;
						e.printStackTrace();
					}
				}
				
				/* If we weren't interrupted with a result, wake up the lock's thread */
				log("Timeout fired");
				timedOut = true;
				synchronized(TimedResultLock.this)
				{
					TimedResultLock.this.notifyAll();
				}
			};
		};
		timeoutThread.start();
		
		while(result == null && !timedOut)
		{
			try
			{
				wait();
			}
			catch(InterruptedException e)
			{
				e.printStackTrace();
			}
		}
		/* Until we either get a result or a timeout, wait */
		
		return result;
	}
	
	/**
	 * Releases the lock.  Any threads that are blocking on
	 * {@link #lock()} will be unblocked, and the <tt>lock()</tt> calls will
	 * return the parameter passed to this method.
	 *
	 * @param result the <tt>Object</tt> that will be returned by <tt>lock()</tt>
	 */
	public synchronized void unlock(Object result)
	{
		this.result = result;
		timeoutThread.interrupt();
		notifyAll();
		/* Store the result, kill the timeout thread, and wake up everybody */
	}
	
	public boolean isLocked() { return result == null; }
	
	private final void log(String text) { Debugger.dbg("TimedResultLock", text); }
}
