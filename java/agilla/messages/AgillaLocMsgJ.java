// $Id: AgillaLocMsgJ.java,v 1.5 2006/04/05 10:28:19 borndigerati Exp $
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
 * AgillaLocMsgJ.java
 *
 * @author Chien-Liang Fok
 */
public class AgillaLocMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID id;
	private int src, seq, dest;
	AgillaAgentType agent_type;
	private AgillaLocation loc;
	private long time_low32, time_high32;
	
	
	public AgillaLocMsgJ() {		
	}
	
	/**
	 *  Constructor.
	 *  
	 * @param id The AgentID.
	 * @param agent_type The agent type
	 * @param src The ID of the host on which the agent resides.
	 * @param loc The location of the host.
	 * @param time_high32 timestamp
	 * @param time_low32  timestamp
	 */
	public AgillaLocMsgJ(AgillaAgentID id, AgillaAgentType agent_type,
			int src, int seq, AgillaLocation loc, 
			long time_high32, long time_low32, int dest)
	{
		this.id = id;
		this.agent_type = agent_type;
		this.src = src;
		this.seq = seq;
		this.loc = loc;
		this.time_high32 = time_high32;
		this.time_low32 = time_low32;
		this.dest = dest;
	}
	
	public AgillaLocMsgJ(AgillaLocMsg msg) {
		this.id = new AgillaAgentID(msg.get_agent_id_id());
		this.agent_type = new AgillaAgentType(msg.get_agent_type());
		this.src = msg.get_src();
		this.seq = msg.get_seq();
		this.loc = new AgillaLocation(msg.get_loc_x(), msg.get_loc_y());		
		this.time_high32 = msg.get_timestamp_high32();
		this.time_low32 = msg.get_timestamp_low32();
		this.dest = msg.get_dest();
	}
	
	public int getType() {	
		return AgillaLocMsg.AM_TYPE;
	}
	
	public AgillaAgentID id() {
		return id;
	}
	
	public AgillaAgentType agentType(){
		return agent_type;
	}
	
	public int src() {
		return src;
	}
	
	public int seq() {
		return seq;
	}
	
	public int dest() {
		return dest;
	}
	
	public AgillaLocation loc() {
		return loc;
	}
	
	public long time_high32() {
		return time_high32;
	}
	
	public long time_low32() {
		return time_low32;
	}

	public long time()
	{
		return (time_high32 << 32 ) + time_low32;
	}
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaLocMsg msg = new AgillaLocMsg();
		msg.set_agent_id_id(id.getID());
		msg.set_agent_type(agent_type.getVal());
		msg.set_src(src);
		msg.set_seq(seq);
		msg.set_loc_x(loc.getx());
		msg.set_loc_y(loc.gety());
		msg.set_timestamp_high32(time_high32);
		msg.set_timestamp_low32(time_low32);
		msg.set_dest(dest);
		return msg;
	}
	
	public String toString() {
		return "LocMsg: \n\t" + "ID: " + id + "\n\ttype:" + agent_type + "\n\tsrc: " + src + "\n\tseq: " + seq + "\n\tloc: " 
			+ loc +"\n\ttimestamp: " + time() + "\n\tdest: " + dest;
	}
}


