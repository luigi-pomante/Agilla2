// $Id: AgentInjector.java,v 1.15 2006/04/11 22:20:41 borndigerati Exp $

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
/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>,
 Chien-Liang Fok <liang@cse.wustl.edu>
 * Date:        May 2 2005
 * Desc:        Main class for the Agilla Agent Injector.
 *
 */

package agilla;

import agilla.variables.*;

import java.util.*;
import java.io.*;
import java.lang.reflect.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import agilla.rmi.agentInjector.*;
import agilla.messages.*;

/**
 * @author Phil Levis
 * @author Chien-Liang Fok
 */
public class AgentInjector implements AgillaConstants,
	MessageListenerJ
{
	private MoteIF moteIF = null;
	private Injector injector = null;
	private String source;
	private PhoenixSource psource;
	private AgentInjectorGUI gui = null;
	private AgillaAddressMsgJ addrMsg;
	private Object addrLock = new Object();
	private ChangeLocationTimer addrTimer;
	private boolean successLocChange = false;
	private Object nbrLock = new Object();
	//private AgillaNbrMsgJ nbrMsg;
	private AgentReceiver agentReceiver;
	private Vector nbrMsgs;
	private QueryNbrListTimer nbrTimer;
	private AgentInjectorServerSide injectorServer = null; // This allows RMI connections
	
	/**
	 *  Creates an AgentInjector that serves as a basic interface to the sensor network.
	 *  It does not display a GUI and assumes that the number of columns is 5.
	 *  
	 * @param source The MoteIF source, e.g., COM4:mica2 or sf@localhost:9001
	 * @param debug Whether to be in debug mode
	 * @throws Exception
	 */
	public AgentInjector(String source, boolean debug) throws Exception {
		this(source, true, 5, false, debug);
	}
	
	/**
	 * Creates an AgentInjector.
	 *
	 * @param source The MoteIF source, e.g., COM4:mica2 or sf@localhost:9001
	 * @param connect Whether the AgentInjector should immediately connect to the
	 * base station, or wait for the connect() method to be called.
	 * @param col The number of columns in the network topology
	 * @param createGUI Whether to create a GUI
	 * @param debug Whether to be in debug mode
	 * @throws Exception
	 */
	public AgentInjector(String source, boolean connect, int col,
						 boolean createGUI, boolean debug) throws Exception
	{
		this.source = source;
		Debugger.debug = debug;
		injector = new Injector(source);
		injector.registerListener(new AgillaNbrMsgJ(), this);
		injector.registerListener(new AgillaAddressAckMsgJ(), this);
		new BaseStationHeartbeat();		
		if (createGUI) gui = createSwingGUI(this);
		if (connect && !injector.useRMI()) connect();
		if (AgillaProperties.getProperties().runTest())
			new Tester(this);
	}
	
	private static AgentInjectorGUI createSwingGUI(AgentInjector parent) {
		try {
			Class guiClass = Class.forName("agilla.SwingAgentInjectorGUI");
			Constructor constructor = guiClass.getConstructor(new Class [] { AgentInjector.class });
			return (AgentInjectorGUI)constructor.newInstance(new Object [] { parent });
		}
		catch(Exception e) {
			e.printStackTrace();
			return null;
		}
	}
	
	/**
	 * Connects the AgentInjector to the MoteIF.
	 */
	public void connect() throws Exception {
		if (moteIF == null) {
			if (source.startsWith("sf"))
				//moteIF = new MoteIF(PrintStreamMessenger.err); 
				//moteIF = new MoteIF(BuildSource.makePhoenix("sf@localhost:9001", PrintStreamMessenger.err));
				moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
			else {
				psource = BuildSource.makePhoenix(
					BuildSource.makeArgsSerial(source),
					net.tinyos.util.PrintStreamMessenger.err);
				moteIF = new MoteIF(psource);
			}
			injector.setMoteIF(moteIF);
			
			boolean useAcks = true;
			agentReceiver = new AgentReceiver(moteIF, useAcks);
			
			if (gui != null) gui.setSFStatusConnected(source);
			log("Created MoteIF: " + source);
		}
		try {
			Thread.sleep(1000);
		} catch(Exception e) {
			e.printStackTrace();
		}
		//changeGridSize(AgillaLocation.NUM_COLUMNS);
	}
	
	/**
	 * Disconnects the AgentInjector from the MoteIF.
	 */
	public void disconnect() {
		if (moteIF != null) {
			psource.shutdown();
			injector.disconnect();
			moteIF = null;
			agentReceiver = null;
			if (gui != null) gui.setSFStatusDisconnected();
		}
	}
	
	/**
	 * Returns the AgentReceiver, which provides a method for registering for
	 * agent received events.  Note, this method will return NULL if the the
	 * AgentInjector is not connected.
	 */
	public AgentReceiver getAgentReceiver() {
		return agentReceiver;
	}
	
//	public MoteIF getMoteIF()
//	{
//		return moteIF;
//	}
	
	/**
	 * Sends a message to the mote attached to the programming board notifying
	 * it that it is a base station.
	 */
//	public void setBS() {
//		if (Debugger.debug) System.out.println("Initializing base station.");
//		injector.sendMsg(new AgillaSetBSMsgJ()); // notify mote it is a base station
//	}
	
	public boolean useRMI() {
		return injector.useRMI();
	}
	
	public boolean isConnected() {
		return moteIF == null;
	}
	
	/**
	 * Changes the grid size.
	 *
	 * @param numCol The number of columns in the grid.
	 */
	public void changeGridSize(int numCol) {
		injector.sendMsg(new AgillaGridSizeMsgJ(numCol));
	}
	
	/**
	 * Method enableRMI
	 *
	 * @throws   Exception
	 *
	 */
	public void enableRMI() throws Exception {
		if (moteIF != null) {
			injectorServer = new AgentInjectorServerSide(injector);
			if (gui != null)
				gui.setRMIStatusConnected(injectorServer.getBoundName());
		} else
			throw new Exception("Working on local mode (moteIF==null), so RMI cannot be enabled");
	}
	
	public void disableRMI() {
		if (injectorServer != null) {
			injectorServer.unbind();
			if (gui != null) gui.setRMIStatusDisconnected();
		}
	}
	
	/**
	 * Changes the TOS address of a specific mote.
	 *
	 * @param oldAddr the original address of the mote.  Note that this is
	 * the original address that was programmed into the mote's EEPROM (not the
	 * address that the mote was set to using a previous call to this method).
	 * @param newAddr the new address.
	 */
	public void changeMoteAddress(int oldAddr, int newAddr){
		short fromPC = 1;
		injector.sendMsg(new AgillaAddressMsgJ(fromPC, oldAddr, newAddr));
	}
	
	/**
	 * Changes the location of a mote.
	 *
	 * @param addr The original address of the mote.  Note that this is
	 * the original address that was programmed into the mote's EEPROM (not the
	 * address that the mote was set to using a previous call to this method).
	 * @param newLoc The new location of the mote.
	 * @return true if successful, false otherwise
	 */
	public boolean changeLocation(int addr, AgillaLocation newLoc) {
		short fromPC = 1;
		addrMsg = new AgillaAddressMsgJ(fromPC, addr, newLoc.getAddr());
		successLocChange = false;
		injector.sendMsg(addrMsg);
		addrTimer = new ChangeLocationTimer(addrLock);
		try {
		    synchronized(addrLock) {
				addrLock.wait();
		    }
		} catch(InterruptedException ie) {
		    ie.printStackTrace();
		}
		return successLocChange;
	}
	
	private class ChangeLocationTimer implements Runnable {
		private static final int CHANGE_LOCATION_TIMER = 1000;
		private Object lock;
		private boolean alive = true;
		
		public ChangeLocationTimer(Object lock) {
			this.lock = lock;
			new Thread(this).start();
		}
		
		public void kill() {
			alive = false;
		}
		
		public void run () {
			try {
				Thread.sleep(CHANGE_LOCATION_TIMER);
			} catch(Exception e) {
				e.printStackTrace();
			}
			if (alive) {
				synchronized(lock) {
					lock.notify();
				}
			}
		}
	}
	
	/**
	 * Resets all motes in the network.  After reseting a mote, the user
	 * must wait 3 seconds before the mote's network interface is running again.
	 */
	public void reset() {
		reset(TOS_BCAST_ADDRESS);
	}
	
	/**
	 * Resets a mote at the specified address.  This method forces the
	 * calling thread to sleep for 3 seconds to allow the resetting mote
	 * to come back online.
	 *
	 * @param addr The original address of the mote to reset.
	 */
	public void reset(int addr) {
		
		if (addr == TOS_BCAST_ADDRESS)
			Debugger.dbg("AgentInjector", "Resetting the entire network reachable from base station.");
		else
			Debugger.dbg("AgentInjector", "Resetting mote " + addr + ".");
		
		injector.reset(addr);
		if (AgillaProperties.enableClustering()) 
			injector.getLocMgr().reset(addr);
		
		try {
			Thread.sleep(3000);  // pause for 3 seconds to allow mote to boot
		} catch(Exception e) {
			e.printStackTrace();
		}
			
//		setBS();
		changeGridSize(AgillaLocation.NUM_COLUMNS);
	}
	
	public TupleSpace getTS() {
		return injector.getTS();
	}
	
	/**
	 * Inject an agent into the network.
	 *
	 * @param dest The destination location of the agent.
	 * @param code The agent's code.
	 */
	public void inject(String code, int dest) throws Exception {
		if (!injector.useRMI() && moteIF == null)
			throw new Exception("Cannot inject agent while running in local mode.");
		else {
			if (code.equals(""))
				throw new Exception("Agent must have at least one instruction.");
			StringReader reader = new StringReader(code);
			ProgramTokenizer tok = new ProgramTokenizer(reader);
			byte[] byteCode = AgillaAssembler.getAssembler().toByteCode(tok);
			injector.inject(dest, new Agent(new AgillaAgentID(), byteCode));
		}
	}
	
	/**
	 * Inject an agent into the network.
	 *
	 * @param dest The destination location of the agent.
	 * @param bytecode The precompiled agent's bytecode.
	 */
	public void inject(byte [] bytecode, int dest) {
		injector.inject(dest, new Agent(new AgillaAgentID(), bytecode));
	}
	
	/**
	 * Inject an agent into the network.
	 *
	 * @param agent The agent.
	 * @param dest The destination.
	 */
	public void inject(Agent agent, int dest) {
		injector.inject(dest, agent);
	}
	
	/**
	 * Queries the neighbor list of an agent.
	 *
	 * @param directQuery 1 if the QueryNeighborList program is used to query
	 * the neighbor list.
	 * @return A vector containing the addresses within the mote's neighbor list.
	 * The addresses are stored as Address objects. 
	 */
	public Vector queryNbrList(int addr, short directQuery) {		
		AgillaGetNbrMsgJ msg = new AgillaGetNbrMsgJ(directQuery, TOS_UART_ADDRESS, addr);
		nbrMsgs = new Vector();
		injector.sendMsg(msg);
		nbrTimer = new QueryNbrListTimer(nbrLock);
		try {
		    synchronized(nbrLock) {
				nbrLock.wait();
		    }
		} catch(InterruptedException ie) {
		    ie.printStackTrace();
		}
		return nbrMsgs;
	}
	
	private class QueryNbrListTimer implements Runnable {
		private static final int QUERY_NEIGHBOR_LIST_TIMER = 1000;
		private Object lock;
		private boolean alive = true;
		
		public QueryNbrListTimer(Object lock) {
		    this.lock = lock;
		    new Thread(this).start();
		}
		
		public void kill() {
			alive = false;
		}
		
		public void run () {
		    try {
				Thread.sleep(QUERY_NEIGHBOR_LIST_TIMER);
		    } catch(Exception e) {
				e.printStackTrace();
		    }
		    if (alive) {
				synchronized(lock) {
					lock.notify();
				}
		    }
		}
	}
	
	/*public void startExp(int numHops, int numResets) {
	 if (moteIF != null) {
	 try {
	 AgillaStartExpMsg smsg = new AgillaStartExpMsg();
	 smsg.set_numHops((short) numHops);
	 smsg.set_numResets((short) numResets);
	 moteIF.send(0, smsg);
	 } catch (IOException ioe) {
	 ioe.printStackTrace();
	 }
	 }
	 }*/
	
	public void printDebugCode(String filename, String code) throws Exception {
		ProgramTokenizer tok = null;
		StringReader reader = new StringReader(code);
		tok = new ProgramTokenizer(reader);
		String result = AgillaAssembler.getAssembler().toDebugCode(tok, filename);
		System.out.println(result);
	}
	
	public void messageReceived(int dest, MessageJ msg) {
	    if (msg.getType() == AgillaAddressAckMsg.AM_TYPE && addrMsg != null) {
			AgillaAddressAckMsgJ ackMsg = (AgillaAddressAckMsgJ)msg;
			if (ackMsg.oldAddr() == addrMsg.oldAddr() && ackMsg.newAddr() == addrMsg.newAddr()) {
				successLocChange = ackMsg.success() == 1;
				if (addrTimer != null)
					addrTimer.kill();
				synchronized(addrLock){
					addrLock.notify();
				}
			}
	    } else if (msg.getType() == AgillaNbrMsg.AM_TYPE && nbrTimer != null) {
			if (Debugger.debug) System.out.println(msg.toString());
			AgillaNbrMsgJ nbrMsg = (AgillaNbrMsgJ)msg;
			//nbrMsg = (AgillaNbrMsgJ)msg;
//	        for (int i = 0; i < nbrMsg.size(); i++) {
//	        	nbrMsgs.add(nbrMsg.getNbr(i));
//	        }
			if (nbrMsgs != null)
				nbrMsgs.addAll(nbrMsg.getNbrs());
			//nbrTimer.kill();
			//synchronized(nbrLock) {
				//nbrLock.notify();
			//}
	    }
	}
	
	public static void main(String[] args) {
		try {
			int index = 0;
			int numColumns = AgillaLocation.NUM_COLUMNS;//, row = AgillaLocation.NUM_ROWS;
			String source = "COM1:mica2"; //"sf@localhost:9001";
			boolean connect = true;
			boolean debug = false;
			boolean showGUI = true;
			
			while (index < args.length) {
				String arg = args[index];
				if (arg.equals("-h") || arg.equals("--help")) {
					usage();
					System.exit(0);
				} else if (arg.equals("-comm")) {
					index++;
					source = args[index];
				} else if (arg.equals("-col"))
					numColumns = Integer.valueOf(args[++index]).intValue();
				else if (arg.toLowerCase().equals("-nogui"))
					showGUI = false;
				else if (arg.equals("-nc"))
					connect = false;
				else if (arg.equals("-d"))
					debug = true;
				else {
					usage();
					System.exit(1);
				}
				index++;
			}
			new AgentInjector(source, connect, numColumns, showGUI, debug);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	private static void usage() {
		System.err.println("usage: Agilla [-h|--help|-comm <source>|-nc|-col <num columns>|-d|-nogui]");
		System.err
			.println("\t-comm <source> where <source> is COMx:[platform] or sf@localhost:9001 or RMI:address, default COM4:mica2");
		System.err.println("\t-nc do not connect to serial forwarder");
		System.err.println("\t-col <number of columns> Specifies the number of columns in the grid topology");
		System.err.println("\t-d for debug mode");
		System.err.println("\t-nogui to hide the graphical user interface (for automated testing purposes)");
	}
	
	/**
	 * Periodically sends a message to the mote attached to the programming board
	 * notifying it that it is a base station.
	 */
	private class BaseStationHeartbeat implements Runnable {
		AgillaSetBSMsgJ bsMsg = new AgillaSetBSMsgJ(); // notify mote it is a base station
		
		public BaseStationHeartbeat() {
			new Thread(this).start();
		}
		
		public void run () {
			while(true) {
				injector.sendMsg(bsMsg);
				try {
					Thread.sleep(3000);
				} catch(Exception e) {
					e.printStackTrace();
				}
			}
		}
	}
	
	private void log(String msg) {
		Debugger.dbg("AgentInjector", msg);
	}
	
}

