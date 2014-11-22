// $Id: AgillaQueryNearestAgentMsgJ.java,v 1.4 2006/04/05 10:28:19 borndigerati Exp $
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
 * AgillaQueryNearestAgentMsgJ.java
 *
 * @author Sangeeta Bhattacharya
 */
public class AgillaQueryNearestAgentMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID id;
	private AgillaAgentType agent_type;
	private int src;
	private int dest;
	private int qid;
	private int flags;
	private AgillaLocation loc;
	
	public AgillaQueryNearestAgentMsgJ() {		
	}
	
	/**
	 *  Constructor.
	 *  
	 * @param id The AgentID.
	 * @param src The ID of the host on which the agent resides.
	 * @param qid The query id.
	 * @param loc The location of the agent/host.
	 * @param agent_type The agent type
	 */
	public AgillaQueryNearestAgentMsgJ(AgillaAgentID id, 
			int src, int dest, int qid, int flags, AgillaLocation loc, AgillaAgentType agent_type)
	{
		this.id = id;
		this.src = src;
		this.dest = dest;
		this.qid = qid;
		this.flags = flags;
		this.loc = loc;
		this.agent_type = agent_type;
	}
	
	public AgillaQueryNearestAgentMsgJ(AgillaQueryNearestAgentMsg msg) {
		this.id = new AgillaAgentID(msg.get_agent_id_id());
		this.src = msg.get_src();
		this.dest = msg.get_dest();
		this.qid = msg.get_qid();
		this.flags = msg.get_flags();
		this.loc = new AgillaLocation(msg.get_loc_x(), msg.get_loc_y());
		this.agent_type = new AgillaAgentType(msg.get_agent_type());
	}
	
	public int getType() {	
		return AgillaQueryNearestAgentMsg.AM_TYPE;
	}
	
	public AgillaAgentID id() {
		return id;
	}
	
	public int src() {
		return src;
	}
	
	public int dest() {
		return dest;
	}
	
	public int qid() {
		return qid;
	}
	
	public int flags(){
		return flags;
	}
	
	public boolean queryAllNetworks(){
		if((flags & 0x1) == 1) return true; else return false;
	}

	public AgillaLocation loc() 
	{
		return loc;
	}
	
	public AgillaAgentType agentType(){
		return agent_type;
	}
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaQueryNearestAgentMsg msg = new AgillaQueryNearestAgentMsg();
		msg.set_agent_id_id(id.getID());
		msg.set_src(src);
		msg.set_dest(dest);
		msg.set_qid(qid);	
		msg.set_flags(flags);
		msg.set_loc_x(loc.getx());
		msg.set_loc_y(loc.gety());
		msg.set_agent_type(agent_type.getVal());
		return msg;
	}
	
	public String toString() {
		return "QueryNearestAgentMsg: \n\t" + "ID: " + id + "\n\tsrc: " + src + "\n\tdest: " + dest
			+ "\n\tqid: " + qid + "(" + ((qid >> 8)& 0xff) + ":" + (qid & 0xff) + ")" +  
			"\n\tflags: "  + flags + "\n\tloc: " + loc + "\n\tagent_type: " + agent_type;
	}
}


