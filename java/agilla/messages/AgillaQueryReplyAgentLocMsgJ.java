// $Id: AgillaQueryReplyAgentLocMsgJ.java,v 1.2 2006/04/05 10:28:19 borndigerati Exp $
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
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHE
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
package agilla.messages;

import agilla.*;
import agilla.variables.*;

/**
 * AgillaQueryReplyAgentLocMsgJ.java
 *
 * @author Sangeeta Bhattacharya
 */
public class AgillaQueryReplyAgentLocMsgJ implements MessageJ, AgillaConstants {
		
	private AgillaAgentID id;
	private int dest;
	private int qid;
	private int flags;
	private AgillaLocation loc;
	private AgillaString networkName;
	
	public AgillaQueryReplyAgentLocMsgJ() {		
	}
	
	/**
	 *  Constructor.
	 *  
	 * @param id The AgentID of the agent sending the query.
	 * @param dest The ID of the host on which the agent resides.
	 * @param qid The query id
	 * @param flags The flags as defined within agilla.messages.QueryReplyConstants
	 * @param loc The location of the agent.
	 */
	public AgillaQueryReplyAgentLocMsgJ(AgillaAgentID id, 
			int dest, int qid, int flags, AgillaLocation loc, AgillaString networkName)
	{
		this.id = id;
		this.dest = dest;
		this.qid = qid;
		this.flags = flags;
		this.loc = loc;
		this.networkName = networkName;
	}
	
	public AgillaQueryReplyAgentLocMsgJ(AgillaQueryReplyAgentLocMsg msg) {
		this.id = new AgillaAgentID(msg.get_agent_id_id());
		this.dest = msg.get_dest();
		this.qid = msg.get_qid();
		this.flags = msg.get_flags();
		this.loc = new AgillaLocation(msg.get_loc_x(), msg.get_loc_y());
		this.networkName = new AgillaString(msg.get_nw_desc_string());
	}
	
	public int getType() {	
		return AgillaQueryReplyAgentLocMsg.AM_TYPE;
	}
	
	public AgillaAgentID id() {
		return id;
	}
	
	public int dest() {
		return dest;
	}
	
	public int qid() {
		return qid;
	}
	
	public int flags() {
		return flags;
	}

	public AgillaLocation loc() 
	{
		return loc;
	}
	
	public AgillaString networkName(){
		return networkName;
	}
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaQueryReplyAgentLocMsg msg = new AgillaQueryReplyAgentLocMsg();
		msg.set_agent_id_id(id.getID());
		msg.set_dest(dest);
		msg.set_qid(qid);	
		msg.set_flags(flags);
		msg.set_loc_x(loc.getx());
		msg.set_loc_y(loc.gety());
		msg.set_nw_desc_string(networkName.getString());
		//System.out.println("TOSMsg of Location Query reply message: " + msg);
		return msg;
	}
	
	public String toString() {
		return "QueryReplyAgentLocMsg: \n\t" + "ID: " + id + "\n\tdest: " + 
				dest + "\n\tqid: " + qid + "(" + ((qid >> 8)& 0xff) + ":" + (qid & 0xff) + ")" +  
				"\n\tflags: 0x" + Integer.toHexString(flags) + 
				"\n\tloc: " + loc + "\n\tnetworkName: " + networkName.toString();
	}
}


