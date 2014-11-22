// $Id: AgillaQueryReplyAllAgentsMsgJ.java,v 1.3 2006/04/05 10:28:20 borndigerati Exp $
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
import java.util.*;

/**
 * AgillaQueryReplyAllAgentsMsgJ.java
 *
 * @author Sangeeta Bhattacharya
 */
public class AgillaQueryReplyAllAgentsMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID id;
	private int src;
	private int dest;
	private int qid;
	private int flags;
	private int num_agents;
	private Vector<AgillaLocMAgentInfo> agents;
	public static final int MAX_NUM_AGENTS = 2;
	
	public AgillaQueryReplyAllAgentsMsgJ() {		
	}
	
	/**
	 *  Constructor.
	 *  
	 * @param id The AgentID of agent that issued the query.
	 * @param dest The ID of the host on which the agent resides.
	 * @param qid The query id.
	 * @param flags The flags as defined within agilla.messages.QueryReplyConstants
	 * @param num_agents The number of agents in the system.
	 */
	public AgillaQueryReplyAllAgentsMsgJ(AgillaAgentID id, int src,	int dest, int qid, int flags, int num_agents)
	{
		this.id = id;
		this.src = src;
		this.dest = dest;
		this.qid = qid;
		this.flags = flags;
		this.num_agents = num_agents;
		agents = new Vector<AgillaLocMAgentInfo>();
	}
	
	public AgillaQueryReplyAllAgentsMsgJ(AgillaQueryReplyAllAgentsMsg msg) {
		this.id = new AgillaAgentID(msg.get_agent_id_id());
		this.src = msg.get_src();
		this.dest = msg.get_dest();
		this.qid = msg.get_qid();
		this.flags = msg.get_flags();
		this.num_agents = msg.get_num_agents();
		agents = new Vector<AgillaLocMAgentInfo>();
		int size = num_agents;
		if(size > MAX_NUM_AGENTS) size = MAX_NUM_AGENTS;
		assert size >= 0;
		for(int i = 0; i < size; i++){
			AgillaLocMAgentInfo agentInf = 
				new AgillaLocMAgentInfo(new AgillaAgentID(msg.getElement_agent_info_agent_id_id(i)),
					new AgillaLocation(msg.getElement_agent_info_loc_x(i), msg.getElement_agent_info_loc_y(i)));
			agents.add(agentInf);
		}
	}
	
	public void addAgentInfo(AgillaLocMAgentInfo agentInf) throws IllegalAccessException{
		if(agents.size() >= MAX_NUM_AGENTS) 
			throw new IllegalAccessException("Cannot add more than " + MAX_NUM_AGENTS + "elements");
		agents.add(agentInf);
	}
	
	public void addAgentInfo(AgillaAgentID id, AgillaLocation loc) throws IllegalAccessException{
		if(agents.size() >= MAX_NUM_AGENTS) 
			throw new IllegalAccessException("Cannot add more than " + MAX_NUM_AGENTS + "elements");
		AgillaLocMAgentInfo agentInf = new AgillaLocMAgentInfo(id, loc);
		agents.add(agentInf);
	}
	
	public void addAgentInfo(int id, int x, int y) throws IllegalAccessException{
		if(agents.size() >= MAX_NUM_AGENTS) 
			throw new IllegalAccessException("Cannot add more than " + MAX_NUM_AGENTS + "elements");
		AgillaLocMAgentInfo agentInf = new AgillaLocMAgentInfo(new AgillaAgentID(id), new AgillaLocation(x, y));
		agents.add(agentInf);
	}
	
	public int getType() {	
		return AgillaQueryReplyAllAgentsMsg.AM_TYPE;
	}
	
	public AgillaAgentID id() {
		return id;
	}
	
	public int dest() {
		return dest;
	}
	
	public int src() {
		return src;
	}
	
	public int qid() {
		return qid;
	}

	public int flags() {
		return flags;
	}
	
	public int num_agents() 
	{
		return num_agents;
	}
	
	public Vector<AgillaLocMAgentInfo> getAgentInfo(){
		return agents;
	}
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaQueryReplyAllAgentsMsg msg = new AgillaQueryReplyAllAgentsMsg();
		msg.set_agent_id_id(id.getID());
		msg.set_src(src);
		msg.set_dest(dest);
		msg.set_qid(qid);	
		msg.set_flags(flags);
		msg.set_num_agents(num_agents);
		//assert (num_agents >= 0 && num_agents <= msg.numElements_agent_info_agent_id_id());
		assert (agents.size() <= msg.numElements_agent_info_agent_id_id());
		for(int i = 0; i < agents.size(); i++){
			AgillaLocMAgentInfo agentInf = (AgillaLocMAgentInfo)agents.elementAt(i);
			msg.setElement_agent_info_agent_id_id(i, agentInf.getID().getID());
			msg.setElement_agent_info_loc_x(i, agentInf.getLoc().getx());
			msg.setElement_agent_info_loc_y(i, agentInf.getLoc().gety());
		}
		return msg;
	}
	
	public String toString() {
		String res = "QueryReplyAllAgentsMsg: \n\t" + "ID: " + id + "\n\tsrc: " + src + "\n\tdest: " + dest + 
						"\n\tqid: " + qid + "(" + ((qid >> 8)& 0xff) + ":" + (qid & 0xff) + ")" +  
						"\n\tflags: " + flags +
						"\n\tnum_agents: " + num_agents + "\n\tagents:[";
		for(int i = 0; i < agents.size(); i++){
			AgillaLocMAgentInfo agentInf = (AgillaLocMAgentInfo)agents.elementAt(i);
			res += "\n\t\t" + agentInf.toString();
		}
		res += "\n\t]";
		return res;
	}
}


