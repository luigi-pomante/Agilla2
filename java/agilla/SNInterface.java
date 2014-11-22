// $Id: SNInterface.java,v 1.11 2006/04/27 01:55:04 chien-liang Exp $

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
import net.tinyos.message.*;
import java.util.*;

/**
 * Provides a higher level abstraction to the sensor network than that provided
 * by TinyOS.
 *
 * @author Chien-Liang Fok
 */
public class SNInterface implements AgillaConstants, MessageListener {
	private MoteIF moteIF;
	
	/**
	 * Maps AM number -> vector of listeners.
	 */
	private Hashtable lTable = new Hashtable();
	private boolean promiscuous;
	
	public SNInterface() {
		this(false);
	}
	
	public SNInterface(boolean promiscuous) {
		this.promiscuous = promiscuous;
	}
	
	public void setMoteIF(MoteIF moteIF) {
		this.moteIF = moteIF;
		moteIF.registerListener(new AgillaErrorMsg(), this);
		moteIF.registerListener(new AgillaCodeMsg(), this);
		moteIF.registerListener(new AgillaStateMsg(), this);
		moteIF.registerListener(new AgillaHeapMsg(), this);
		moteIF.registerListener(new AgillaOpStackMsg(), this);
		moteIF.registerListener(new AgillaResetMsg(), this);
		moteIF.registerListener(new AgillaAckStateMsg(), this);
		moteIF.registerListener(new AgillaAckCodeMsg(), this);
		moteIF.registerListener(new AgillaAckHeapMsg(), this);
		moteIF.registerListener(new AgillaAckOpStackMsg(), this);
		moteIF.registerListener(new AgillaAckRxnMsg(), this);
		moteIF.registerListener(new AgillaTSReqMsg(), this);
		moteIF.registerListener(new AgillaTSResMsg(), this);
		//moteIF.registerListener(new AgillaTSModMsg(), this);
		//moteIF.registerListener(new AgillaExpMsg(), this);
		//moteIF.registerListener(new AgillaStartExpMsg(), this);
		//moteIF.registerListener(new AgillaCodeUsedMsg(), this);
		//moteIF.registerListener(new AgillaNxtBlockPtrMsg(), this);
		moteIF.registerListener(new AgillaAddressMsg(), this);
		moteIF.registerListener(new AgillaAddressAckMsg(), this);
		moteIF.registerListener(new AgillaGetNbrMsg(), this);
		moteIF.registerListener(new AgillaNbrMsg(), this);
		moteIF.registerListener(new AgillaBeaconMsg(), this);
		//moteIF.registerListener(new AgillaBeaconBSMsg(), this);
		moteIF.registerListener(new AgillaRxnMsg(), this);
		// TimeSync message
		moteIF.registerListener(new AgillaTimeSyncMsg(), this);
		// Location Manager messages
		moteIF.registerListener(new AgillaLocMsg(), this);
		moteIF.registerListener(new AgillaQueryNumAgentsMsg(), this);
		moteIF.registerListener(new AgillaQueryAgentLocMsg(), this);
		moteIF.registerListener(new AgillaQueryNearestAgentMsg(), this);
		moteIF.registerListener(new AgillaQueryAllAgentsMsg(), this);
		moteIF.registerListener(new AgillaClusterMsg(), this);
		moteIF.registerListener(new AgillaQueryReplyAgentLocMsg(), this);
		moteIF.registerListener(new AgillaQueryReplyNearestAgentMsg(), this);
		moteIF.registerListener(new AgillaQueryReplyAllAgentsMsg(), this);
		moteIF.registerListener(new AgillaClusterDebugMsg(), this);
	}
	
	public void disconnect() {
		if (moteIF != null) {
			moteIF.deregisterListener(new AgillaErrorMsg(), this);
			moteIF.deregisterListener(new AgillaCodeMsg(), this);
			moteIF.deregisterListener(new AgillaStateMsg(), this);
			moteIF.deregisterListener(new AgillaHeapMsg(), this);
			moteIF.deregisterListener(new AgillaOpStackMsg(), this);
			moteIF.deregisterListener(new AgillaResetMsg(), this);
			moteIF.deregisterListener(new AgillaAckStateMsg(), this);
			moteIF.deregisterListener(new AgillaAckCodeMsg(), this);
			moteIF.deregisterListener(new AgillaAckHeapMsg(), this);
			moteIF.deregisterListener(new AgillaAckOpStackMsg(), this);
			moteIF.deregisterListener(new AgillaAckRxnMsg(), this);
			moteIF.deregisterListener(new AgillaTSReqMsg(), this);
			moteIF.deregisterListener(new AgillaTSResMsg(), this);
			//moteIF.deregisterListener(new AgillaTSModMsg(), this);
			//moteIF.deregisterListener(new AgillaExpMsg(), this);
			//moteIF.deregisterListener(new AgillaStartExpMsg(), this);
			//moteIF.deregisterListener(new AgillaCodeUsedMsg(), this);
			//moteIF.deregisterListener(new AgillaNxtBlockPtrMsg(), this);
			moteIF.deregisterListener(new AgillaAddressMsg(), this);
			moteIF.deregisterListener(new AgillaAddressAckMsg(), this);
			moteIF.deregisterListener(new AgillaGetNbrMsg(), this);
			moteIF.deregisterListener(new AgillaNbrMsg(), this);
			moteIF.deregisterListener(new AgillaBeaconMsg(), this);
			//moteIF.deregisterListener(new AgillaBeaconBSMsg(), this);
			moteIF.deregisterListener(new AgillaRxnMsg(), this);
			// TimeSync message
			moteIF.deregisterListener(new AgillaTimeSyncMsg(), this);
			// Location Manager messages
			moteIF.deregisterListener(new AgillaLocMsg(), this);
			moteIF.deregisterListener(new AgillaQueryNumAgentsMsg(), this);
			moteIF.deregisterListener(new AgillaQueryAgentLocMsg(), this);
			moteIF.deregisterListener(new AgillaQueryNearestAgentMsg(), this);
			moteIF.deregisterListener(new AgillaQueryAllAgentsMsg(), this);
			moteIF.deregisterListener(new AgillaClusterMsg(), this);
			moteIF.deregisterListener(new AgillaQueryReplyAgentLocMsg(), this);
			moteIF.deregisterListener(new AgillaQueryReplyNearestAgentMsg(), this);
			moteIF.deregisterListener(new AgillaQueryReplyAllAgentsMsg(), this);
			moteIF.deregisterListener(new AgillaClusterDebugMsg(), this);
			moteIF = null;
		}
	}
	
	public void registerListener(MessageJ msg, MessageListenerJ listener) {
		Integer key = new Integer(msg.getType());
		if (!lTable.containsKey(key)) {
			lTable.put(key, new Vector());
		}
		
		Vector list = (Vector)lTable.get(key);
		if (!list.contains(listener))
			list.add(listener);
	}
	
	public void deregisterListener(MessageJ msg, MessageListenerJ listener) {
		Integer key = new Integer(msg.getType());
		Vector list = (Vector)lTable.get(key);
		if (list != null)
			list.remove(listener);
	}

	/**
	 *  Sends a message to the base station mote.
	 *  
	 *  @param msg The message to send.
	 *  @param address The TinyOS address of the base station mote.
	 */
	public void send(MessageJ msg, int address) throws java.io.IOException {
		if (moteIF != null) {
			if (Debugger.printAllMsgs && msg.getType() != AgillaBeaconMsg.AM_TYPE
					&& msg.getType() != AgillaSetBSMsg.AM_TYPE) {
				System.err.println("\nSNInterface: Sending " + msg + "\n to " + address + "\n == \n" + msg.toTOSMsg());
				//System.out.println("SNInterface: send: sending " + msg.toTOSMsg());
			}
			moteIF.send(address, msg.toTOSMsg());
		}
	}
	
	/**
	 *  Sends a message to the base station mote.  Sends the message using TOS_BCAST_ADDRESS,
	 *  assumes TinyOS's components will deliver this message to only the mote connected to 
	 *  the base station.
	 *  
	 *  @param msg The message to send.
	 */
	public void send(MessageJ msg) throws java.io.IOException {
		send(msg, TOS_BCAST_ADDRESS);
	}
	
	/**
	 * Method messageReceived
	 *
	 * @param    to                  an int
	 * @param    m                   a  Message
	 *
	 */
	public void messageReceived(int to, Message m) {
		MessageJ msgJ = null;
		
		switch(m.amType()) {
			case AgillaErrorMsg.AM_TYPE:
				msgJ = new AgillaErrorMsgJ((AgillaErrorMsg)m);
				break;
			case AgillaResetMsg.AM_TYPE:
				msgJ = new AgillaResetMsgJ((AgillaResetMsg)m);
				break;
			case AgillaStateMsg.AM_TYPE:
				msgJ = new AgillaStateMsgJ((AgillaStateMsg)m);
				break;
			case AgillaCodeMsg.AM_TYPE:
				msgJ = new AgillaCodeMsgJ((AgillaCodeMsg)m);
//				AgillaCodeMsg codeMsg = (AgillaCodeMsg)m;
//				if (codeMsg.get_id_id() == 0xffff) {
//					String print = "CODE MSG: Index(" + codeMsg.get_msgNum() + ")";
//					for (int i = 0; i < codeMsg.totalSize_code(); i++) {
//						print += " " + codeMsg.getElement_code(i);
//					}
//					System.out.println(print);
//				}
				break;
			case AgillaHeapMsg.AM_TYPE:
				msgJ = new AgillaHeapMsgJ((AgillaHeapMsg)m);
				break;
			case AgillaOpStackMsg.AM_TYPE:
				msgJ = new AgillaOpStackMsgJ((AgillaOpStackMsg)m);
				break;
			case AgillaAckStateMsg.AM_TYPE:
				msgJ = new AgillaAckStateMsgJ((AgillaAckStateMsg)m);
				break;
			case AgillaAckCodeMsg.AM_TYPE:
				msgJ = new AgillaAckCodeMsgJ((AgillaAckCodeMsg)m);
				break;
			case AgillaAckHeapMsg.AM_TYPE:
				msgJ = new AgillaAckHeapMsgJ((AgillaAckHeapMsg)m);
				break;
			case AgillaAckOpStackMsg.AM_TYPE:
				msgJ = new AgillaAckOpStackMsgJ((AgillaAckOpStackMsg)m);
				break;
			case AgillaAckRxnMsg.AM_TYPE:
				msgJ = new AgillaAckRxnMsgJ((AgillaAckRxnMsg)m);
				break;
			case AgillaTSReqMsg.AM_TYPE:
				msgJ = new AgillaTSReqMsgJ((AgillaTSReqMsg)m);
				break;
			case AgillaTSResMsg.AM_TYPE:
				msgJ = new AgillaTSResMsgJ((AgillaTSResMsg)m);
				break;
				//case AM_AGILLATSMODMSG:
				//msgJ = new AgillaTSModMsgJ();
				//break;
//			case AM_AGILLAEXPMSG:
//				AgillaExpMsg expMsg = (AgillaExpMsg)m;
//				if (expMsg.get_round() == 0)
//					System.out.println("\n");
//				System.out.println((expMsg.get_round()+1) + "\t" +  expMsg.get_results());
				/*for (int i = 0; i < 7; i++) {
				 if (expMsg.getElement_round(i) == 0)
				 System.out.println("\n");
				 System.out.println((expMsg.getElement_round(i)+1) + "\t" +  expMsg.getElement_results(i));
				 }*/
//				break;
				/*case AM_AGILLASTARTEXPMSG:
				 System.out.println("Experimental agent lost!");
				 break;
				 case AM_AGILLACODEUSEDMSG:
				 AgillaCodeUsedMsg usedMsg = (AgillaCodeUsedMsg)m;
				 
				 String output = "CODE USED MSG: ";
				 for (int i = 0; i < usedMsg.totalSize_used(); i++) {
				 output += " " + usedMsg.getElement_used(i);
				 }
				 System.out.println(output);
				 break;
				 case AM_AGILLANXTBLOCKPTRMSG:
				 AgillaNxtBlockPtrMsg nbMsg = (AgillaNxtBlockPtrMsg)m;
				 output = "NEXT BLOCK MSG: ";
				 for (int i = 0; i < nbMsg.totalSize_nbPtr(); i++) {
				 output += " " + nbMsg.getElement_nbPtr(i);
				 }
				 System.out.println(output);
				 break;*/
			case AgillaAddressMsg.AM_TYPE:
				msgJ = new AgillaAddressMsgJ((AgillaAddressMsg)m);
				break;
			case AgillaAddressAckMsg.AM_TYPE:
				msgJ = new AgillaAddressAckMsgJ((AgillaAddressAckMsg)m);
				break;
			case AgillaNbrMsg.AM_TYPE:
				msgJ = new AgillaNbrMsgJ((AgillaNbrMsg)m);
				break;
			case AgillaGetNbrMsg.AM_TYPE:
				msgJ = new AgillaGetNbrMsgJ((AgillaGetNbrMsg)m);
				break;
			case AgillaBeaconMsg.AM_TYPE:
				msgJ = new AgillaBeaconMsgJ((AgillaBeaconMsg)m);
				break;
//			case AM_AGILLABEACONBSMSG:
//				msgJ = new AgillaBeaconBSMsgJ((AgillaBeaconBSMsg)m);
//				break;
			case AgillaRxnMsg.AM_TYPE:
				msgJ = new AgillaRxnMsgJ((AgillaRxnMsg)m);
				break;
			case AgillaTimeSyncMsg.AM_TYPE:
				msgJ = new AgillaTimeSyncMsgJ((AgillaTimeSyncMsg)m);
				break;
			case AgillaLocMsg.AM_TYPE:
				msgJ = new AgillaLocMsgJ((AgillaLocMsg)m);
				break;
			case AgillaQueryNumAgentsMsg.AM_TYPE:
				msgJ = new AgillaQueryNumAgentsMsgJ((AgillaQueryNumAgentsMsg)m);
				break;
			case AgillaQueryAgentLocMsg.AM_TYPE:
				msgJ = new AgillaQueryAgentLocMsgJ((AgillaQueryAgentLocMsg)m);
				break;
			case AgillaQueryNearestAgentMsg.AM_TYPE:
				msgJ = new AgillaQueryNearestAgentMsgJ((AgillaQueryNearestAgentMsg)m);
				break;
			case AgillaQueryAllAgentsMsg.AM_TYPE:
				msgJ = new AgillaQueryAllAgentsMsgJ((AgillaQueryAllAgentsMsg)m);
				break;
			case AgillaClusterMsg.AM_TYPE:
				msgJ = new AgillaClusterMsgJ((AgillaClusterMsg)m);
				break;
			case AgillaQueryReplyAgentLocMsg.AM_TYPE:
				msgJ = new AgillaQueryReplyAgentLocMsgJ((AgillaQueryReplyAgentLocMsg)m);
				break;
			case AgillaQueryReplyNearestAgentMsg.AM_TYPE:
				msgJ = new AgillaQueryReplyNearestAgentMsgJ((AgillaQueryReplyNearestAgentMsg)m);
				break;
			case AgillaQueryReplyAllAgentsMsg.AM_TYPE:
				msgJ = new AgillaQueryReplyAllAgentsMsgJ((AgillaQueryReplyAllAgentsMsg)m);
				break;
			case AgillaClusterDebugMsg.AM_TYPE:
				msgJ = new AgillaClusterDebugMsgJ((AgillaClusterDebugMsg)m);
				break;
			default:
				if (Debugger.debug)
					System.out.println("SNInterface: ERROR: Received Unknown Message (type: " + m.amType() + ") " + m);
				return;
		}
		
		
		if (Debugger.printAllMsgs) {
		    //if (m.amType() != AM_AGILLABEACONMSG && m.amType() != AM_AGILLABEACONBSMSG)
		    //if (m.amType() == AM_AGILLATSREQMSG || m.amType() == AM_AGILLATSRESMSG
		    //        || m.amType() == AM_AGILLANBRMSG || m.amType() == AM_AGILLAGETNBRMSG)
			if (msgJ.getType() != AgillaBeaconMsg.AM_TYPE || Debugger.printBeacons) {

				String toString = "";
				if (to == TOS_BCAST_ADDRESS)
					toString += "TOS_BCAST_ADDR";
				else if (to == TOS_UART_ADDRESS)
					toString += "TOS_UART_ADDRESS";
				else
					toString += to;
				
				System.err.println("\nSNInterface: Received  message!  Dest: " + toString + ":\n" + msgJ.toString() + "\n");
			}
		}
		
		if (to == TOS_LOCAL_ADDRESS || promiscuous) {
			Vector listeners = (Vector)lTable.get(new Integer(m.amType()));
			if (listeners != null) {
				for (int i = 0; i < listeners.size(); i++) {
					MessageListenerJ mlj = (MessageListenerJ)listeners.get(i);
					mlj.messageReceived(to, msgJ);
				}
			}
		} else {
			Debugger.dbg("SNInterface", "Dropped message because not destined for this base station (to = " + to + ").");
			Debugger.dbg("SNInterface", "Dropped message: " + msgJ);
		}
	}
	
}




