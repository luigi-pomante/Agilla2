// $Id: TupleSpace.java,v 1.16 2006/04/19 19:03:29 chien-liang Exp $

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

import java.util.*;
import java.io.*;
import agilla.messages.*;
import agilla.opcodes.BasicOpcodes;

/**
 * An implementation of the local tuple space.  Also provides an interface
 * for accessing the tuple spaces within the wireless sensor network.
 * CURRENTLY ASSUMES SINGLE-THREADED OPERATION!!!
 *
 * @author Chien-Liang Fok
 */
public class TupleSpace implements AgillaConstants, MessageListenerJ {
	public static final int REMOVE = 0;
	public static final int NOREMOVE = 1;
	private static int timerid = 0;
	
	private SNInterface sni;
	//private AgillaTSResMsgJ results;
	//private TimeoutTimer timer;
	private Vector ts, reactions, response;
	private Object blocked = new Object();
	//waiting = new Object();
	
	public TupleSpace(SNInterface sni) {
		this.sni = sni;
		ts = new Vector();
		reactions = new Vector();
		response = new Vector();
		sni.registerListener(new AgillaTSResMsgJ(), this);
		sni.registerListener(new AgillaTSReqMsgJ(), this);
		//sni.registerListener(new AgillaTSModMsgJ(), this);
	}
	
	
	//--------------------------------------------------------------------------
	// BEGIN LOCAL TS OPERATIONS
	public void out(Tuple t) {
		ts.add(t);
		checkRxns(t);
		synchronized(blocked) {
			blocked.notifyAll();
		}
	}
	
	public Tuple inp(Tuple template) {
		for (int i = 0; i < ts.size(); i++) {
			Tuple tuple = (Tuple)ts.get(i);
			log("INP: Comparing:\n" + template + "\nwith:\n" + tuple);
			if (template.matches(tuple)) {
				log("INP: Match!");
				ts.remove(i);
				return tuple;
			}
		}
		return null;
	}
	
	public Tuple [] ingp(Tuple template) {
		Vector matchingTuples = new Vector();
		for (int i = 0; i < ts.size(); i++) {
			Tuple tuple = (Tuple)ts.get(i);
			if (template.matches(tuple))
				matchingTuples.add(tuple);
		}
		if(matchingTuples.size() == 0)
			return null;
		ts.removeAll(matchingTuples);
		return (Tuple [])matchingTuples.toArray(new Tuple[0]);
	}
	
	public Tuple [] ing(Tuple template) {
		Tuple [] tuples = ingp(template);
		if(tuples != null)
			return tuples;
		
		Tuple tuple = in(template);
		return new Tuple [] { tuple };
	}
		
	public Tuple rdp(Tuple template) {
		for (int i = 0; i < ts.size(); i++) {
			Tuple tuple = (Tuple)ts.get(i);
			if (template.matches(tuple))
				return tuple;
		}
		return null;
	}
	
	public Tuple [] rdgp(Tuple template) {
		Vector matchingTuples = new Vector();
		for (int i = 0; i < ts.size(); i++) {
			Tuple tuple = (Tuple)ts.get(i);
			if (template.matches(tuple))
				matchingTuples.add(tuple);
		}
		if(matchingTuples.size() == 0)
			return null;
		return (Tuple [])matchingTuples.toArray(new Tuple[0]);
	}
	
	public Tuple [] rdg(Tuple template) {
		Tuple [] tuples = rdgp(template);
		if(tuples != null)
			return tuples;
		
		Tuple tuple = rd(template);
		return new Tuple [] { tuple };
	}

	/**
	 * Returns a tuple matching the specified template.  If no match is found,
	 * block until one is found. If more than one match is found, choose and
	 * return one randomly.  The tuple is removed from the tuple space.
	 */
	public Tuple in(Tuple template) {
		log("IN: Performing an in() operation.");
		Tuple result = inp(template);
		if (result != null) {
			return result;
		} else {
			while(true) {
				synchronized(blocked) {
					try {
						log("IN: BLOCKED while doing an in().");
						blocked.wait();
						log("IN: UNBLOCKED while doing an in().");
					} catch(Exception e) {
						e.printStackTrace();
					}
					log("IN: Trying to find a match.");
					result = inp(template);
					if (result != null)
						return result;
				}
			}
		}
	}
	
	/**
	 * Returns a tuple matching the specified template.  If no match is found,
	 * block until one is found. If more than one match is found, choose and
	 * return one randomly.  The tuple is kept in the tuple space.
	 */
	public Tuple rd(Tuple template) {
		log("RD: Performing an rd() operation.");
		Tuple result = rdp(template);
		if (result != null)
			return result;
		else {
			while(true) {
				synchronized(blocked) {
					try {
						log("RD: Blocking while doing an rd().");
						blocked.wait();
					} catch(Exception e) {
						e.printStackTrace();
					}
					result = rdp(template);
					if (result != null)
						return result;
				}
			}
		}
	}
	
	private void processRequest(AgillaTSReqMsgJ reqMsg) {
		switch(reqMsg.getOp()) {
			case BasicOpcodes.OProut:
				Tuple t = reqMsg.getTemplate();
				log("processRequest(): OUTing tuple: "  + t);
				out(t);
				
				/*try {
					sni.send(new AgillaTSResMsgJ(reqMsg.getReply(), reqMsg.getOp(), SUCCESS, reqMsg.getTemplate()));
				} catch (IOException ioe) {
					ioe.printStackTrace();
				}*/
				break;
			case BasicOpcodes.OPrrdp:
			case BasicOpcodes.OPrinp:
				Tuple template = reqMsg.getTemplate();
				Tuple result = null;
				if (reqMsg.getOp() == BasicOpcodes.OPrinp)
					result = inp(template);
				else
					result = rdp(template);
				AgillaTSResMsgJ resMsg = null;
				if (result == null)
					resMsg = new AgillaTSResMsgJ(reqMsg.getReply(), reqMsg.getOp(), FAIL, template);
				else
					resMsg = new AgillaTSResMsgJ(reqMsg.getReply(), reqMsg.getOp(), SUCCESS, result);
				log("processRequest(): Sending results: " + resMsg);

//				*** Added this for benchmarking Agillimone agents *** //
//				agillimone.microbenchmarks.TimeKeeper.start();
				try {
					// Do not send to the reply address because the mote may be multiple hops away
					// Instead, send it to the bcast address
					//sni.send(resMsg, reqMsg.getReply());  // send the results back					
					sni.send(resMsg, TOS_BCAST_ADDRESS);
				} catch (IOException ioe) {
					ioe.printStackTrace();
				}
//				*** Added this for benchmarking Agillimone agents *** //
//				agillimone.microbenchmarks.TimeKeeper.end();
				break;
			default:
				log("processRequest(): Invalid Request " + reqMsg);
				resMsg = new AgillaTSResMsgJ(reqMsg.getReply(), reqMsg.getOp(), FAIL, null);
				try {
					sni.send(resMsg);
				} catch (IOException ioe) {
					ioe.printStackTrace();
				}
		}
	}
	
	public void messageReceived(int to, MessageJ m) 
	{
		try 
		{
			if (m.getType() == AgillaTSResMsg.AM_TYPE) 
			{
				log("Got a results message: " + m);
				//results = (AgillaTSResMsgJ)m;
				synchronized(response) 
				{
					response.add(m);
					//if (timer != null) timer.kill();
					response.notifyAll();
				}
			} else if (m.getType() == AgillaTSReqMsg.AM_TYPE) {
				AgillaTSReqMsgJ reqMsg = (AgillaTSReqMsgJ)m;
				log("Got a request message: " + m);
				processRequest(reqMsg);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	//--------------------------------------------------------------------------
	// BEGIN REMOTE TS OPERATIONS
	
	/**
	 * Inserts a tuple into the tuple space.
	 */
	public boolean rout(Tuple t, int dest) {
		AgillaTSReqMsgJ request = new AgillaTSReqMsgJ(dest, TOS_UART_ADDRESS,
													  BasicOpcodes.OProut, t);
		try {
			sni.send(request);
		} catch(IOException e) {
			e.printStackTrace();
			return false;
		}
		log("rout: Request sent, no reply expected.");
		
		/*log("rout: Request sent, awaiting reply.");
		synchronized(waiting) {
			if (results == null){
				timer = new TimeoutTimer(waiting, AGILLA_RTS_TIMEOUT);
				try {
					waiting.wait();
				} catch(Exception e) {
					e.printStackTrace();
				}
			}
		}
		if (results != null)
			log("rout: Reply received, success = " + results.isSuccess());
		else
			log("rout: The operation timed out");
		if (results != null)
			return results.isSuccess();
		else
			return false;*/
		return true;
	}
	
	
	/**
	 * A remote INP operation.
	 *
	 * @param template The template.
	 * @param dest The address of the node on which to perform the operation.
	 * @return The matching tuple or null if none was found.
	 */
	public Tuple rinp(Tuple template, int dest) {
		return doMonoOp(template, dest, REMOVE);
	}
	
	/**
	 * A remote RDP operation.
	 *
	 * @param template The template.
	 * @param dest The address of the node on which to perform the operation.
	 * @return The matching tuple or null if none was found.
	 */
	public Tuple rrdp(Tuple template, int dest) {
		return doMonoOp(template, dest, NOREMOVE);
	}
	
	/**
	 * Performs a remote tuple space operation.
	 *
	 * @param template
	 * @param dest
	 * @param type
	 * @return The matching tuple or null if none was found.
	 */
	private Tuple doMonoOp(Tuple template, int dest, int type) {
		AgillaTSReqMsgJ request;
		if (type == REMOVE)
			request = new AgillaTSReqMsgJ(dest, TOS_UART_ADDRESS, BasicOpcodes.OPrinp, template);
		else
			request = new AgillaTSReqMsgJ(dest, TOS_UART_ADDRESS, BasicOpcodes.OPrrdp, template);
		
		log("doMonoOp: request = " + request + ", dest = " + dest);
		
		response.clear();
		
		try {
			log("doMonoOp: Sent inp or rdp request.");
			//results = null;
			sni.send(request);
		} catch(IOException e) {
			e.printStackTrace();
			return null;
		}
		
		TimeoutTimer timer = new TimeoutTimer(response, AGILLA_RTS_TIMEOUT, timerid++);
		MessageJ rMsg = waitForResponse();
		
		if (rMsg instanceof TimeoutMsgJ && ((TimeoutMsgJ)rMsg).id() == timer.id())
		{
			log("doMonoOp: Remote TS operation timed out.");
			return null;
		}
		else if (rMsg instanceof AgillaTSResMsgJ) 
		{		
			AgillaTSResMsgJ results = (AgillaTSResMsgJ)rMsg; 
			log("doMonoOp: Got results, " + (results.isSuccess() ? "SUCCESS" : "FAIL"));
			if (results.isSuccess()) 					
				return results.getTuple();		
			else
				return null;			
		}
		return null;
	}
	
	private MessageJ waitForResponse() {
		synchronized(response) 
		{  
			while (response.size() == 0) {
				try {
					response.wait();
				} catch(Exception e) {
					e.printStackTrace();
				}
			}
		}
		if (response.size() > 0) {
			return (MessageJ)response.remove(0);
		} else {
			log("BUG: Recursive call to waitForResponse()...");
			return waitForResponse();
		}			
	}
	
	
	private void checkRxns(Tuple t) {
		for (int i = 0; i < reactions.size(); i++) {
			RegisteredReaction rr = (RegisteredReaction)reactions.get(i);
			if (rr.getReaction().getTemplate().matches(t)) {
				rr.getListener().reactionFired(t);
			}
		}
	}
	
	/**
	 * Registers a reaction on this tuple space.
	 *
	 * @param rxn The reaction to register
	 * @param listener The reaction callback function
	 */
	public void registerReaction(Reaction rxn, ReactionListener listener) {
		reactions.add(new RegisteredReaction(rxn, listener));
		for (int i = 0; i < ts.size(); i++) {
			Tuple t = (Tuple)ts.get(i);
			if (rxn.getTemplate().matches(t))
				listener.reactionFired(t);
		}
	}
	
	/**
	 * Deregisters a reaction.
	 *
	 * @param r The reaction to register.
	 * @return true if successful, false otherwise.
	 */
	public boolean deregisterReaction(Reaction r) {
		for (int i = 0; i < reactions.size(); i++) {
			RegisteredReaction rxn = (RegisteredReaction)reactions.get(i);
			if (rxn.rxn.equals(r)) {
				reactions.remove(i);
				return true;
			}
		}
		return false;
	}
	
	private class RegisteredReaction {
		private Reaction rxn;
		private ReactionListener rl;
		
		public RegisteredReaction(Reaction rxn, ReactionListener rl) {
			this.rxn = rxn;
			this.rl = rl;
		}
		
		public Reaction getReaction() {
			return rxn;
		}
		
		public ReactionListener getListener() {
			return rl;
		}
	}
	
	private void log(String msg) {
		Debugger.dbg("TupleSpace", msg);
	}
}

