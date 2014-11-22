// $Id: AgillaQueryReplyNearestAgentMsgJ.java,v 1.2 2006/04/05 10:28:19 borndigerati Exp $
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
 * AgillaQueryReplyNearestAgentMsgJ.java
 *
 * @author Sangeeta Bhattacharya
 */
public class AgillaQueryReplyNearestAgentMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID id;
	private int src;
	private int dest;
	private int qid;
	private int flags;
	private AgillaAgentID nearest_agent_id;
	private AgillaLocation nearest_agent_loc;
	
	public AgillaQueryReplyNearestAgentMsgJ() {		
	}
	
	/**
	 *  Constructor.
	 *  
	 * @param id The AgentID issuing the query.
	 * @param dest The ID of the host to which the query must be routed.
	 * @param qid The query id
	 * @param flags The flags as defined within agilla.messages.QueryReplyConstants
	 * @param nearest_agent_id AgentID of nearest agent.
	 * @param nearest_agent_loc Location of nearest agent.
	 */
	public AgillaQueryReplyNearestAgentMsgJ(AgillaAgentID id, int src, 
			int dest, int qid, int flags,
			AgillaAgentID nearest_agent_id, AgillaLocation nearest_agent_loc)
	{
		this.id = id;
		this.src = src;
		this.dest = dest;
		this.qid = qid;
		this.flags = flags;
		this.nearest_agent_id = nearest_agent_id;
		this.nearest_agent_loc = nearest_agent_loc;
	}
	
	public AgillaQueryReplyNearestAgentMsgJ(AgillaQueryReplyNearestAgentMsg msg) {
		this.id = new AgillaAgentID(msg.get_agent_id_id());
		this.src =msg.get_src();
		this.dest = msg.get_dest();
		this.qid = msg.get_qid();
		this.flags = msg.get_flags();
		this.nearest_agent_id = new AgillaAgentID(msg.get_nearest_agent_id_id());
		this.nearest_agent_loc = new AgillaLocation(msg.get_nearest_agent_loc_x(), msg.get_nearest_agent_loc_y());
	}
	
	public int getType() {	
		return AgillaQueryReplyNearestAgentMsg.AM_TYPE;
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

	public int flags() {
		return flags;
	}
	
	public AgillaAgentID nearestAgentId() 
	{
		return nearest_agent_id;
	}

	public AgillaLocation nearestAgentLoc() 
	{
		return nearest_agent_loc;
	}
	
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaQueryReplyNearestAgentMsg msg = new AgillaQueryReplyNearestAgentMsg();
		msg.set_agent_id_id(id.getID());
		msg.set_src(src);
		msg.set_dest(dest);
		msg.set_qid(qid);	
		msg.set_flags(flags);
		msg.set_nearest_agent_id_id(nearest_agent_id.getID());
		msg.set_nearest_agent_loc_x(nearest_agent_loc.getx());
		msg.set_nearest_agent_loc_y(nearest_agent_loc.gety());
		return msg;
	}
	
	public String toString() {
		return "QueryReplyNearestAgentMsg: \n\t" + "ID: " + id + "\n\tsrc: " + src + "\n\tdest: " + dest + 
			"\n\tqid: " + qid + "(" + ((qid >> 8)& 0xff) + ":" + (qid & 0xff) + ")" +  
			"\n\tflags: " + Integer.toHexString(flags) + 
			"\n\tnearest_agent_id: " + nearest_agent_id + "\n\tnearest_agent_loc: " + nearest_agent_loc;
	}
}


