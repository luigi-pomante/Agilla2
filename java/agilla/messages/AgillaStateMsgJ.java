// $Id: AgillaStateMsgJ.java,v 1.2 2005/11/11 02:15:49 chien-liang Exp $
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
 * AgillaStateMsgJ.java
 *
 * @author Chien-Liang Fok
 */
public class AgillaStateMsgJ implements MessageJ, AgillaConstants {
	private int dest;
	private int replyAddr;
	private AgillaAgentID id;
	private short op, sp;
	private int pc, condition, codeSize;
	private short numHpMsgs, numRxnMsgs;
	
	public AgillaStateMsgJ(int dest,
						   int replyAddr,
						   AgillaAgentID id,
						   short op, short sp,
						   int pc, int condition, int codeSize,
						   short numHpMsgs,
						   short numRxnMsgs)
	{
		this.dest = dest;
		this.replyAddr = replyAddr;
		this.id = id;
		this.op = op;
		this.sp = sp;
		this.pc = pc;
		this.condition = condition;
		this.codeSize = codeSize;
		this.numHpMsgs = numHpMsgs;
		this.numRxnMsgs = numRxnMsgs;
	}
	public AgillaStateMsgJ(AgillaStateMsg msg) {
		this.dest = msg.get_dest();
		this.replyAddr = msg.get_replyAddr();
		this.id = new AgillaAgentID(msg.get_id_id());
		this.op = msg.get_op();
		this.sp = msg.get_sp();
		this.pc = msg.get_pc();
		this.condition = msg.get_condition();
		this.codeSize = msg.get_codeSize();
		this.numHpMsgs = msg.get_numHpMsgs();
		this.numRxnMsgs = msg.get_numRxnMsgs();
	}
	public int getType() {
		//return AM_AGILLASTATEMSG;
		return AgillaStateMsg.AM_TYPE;
	}
	
	public int getReply() {
	  return replyAddr;
	}
	public net.tinyos.message.Message toTOSMsg() {
		AgillaStateMsg msg = new AgillaStateMsg();
		msg.set_dest(dest);
		msg.set_replyAddr(replyAddr);
		msg.set_id_id(id.getID());
		msg.set_op(op);
		msg.set_sp(sp);
		msg.set_pc(pc);
		msg.set_condition(condition);
		msg.set_codeSize(codeSize);
		msg.set_numHpMsgs(numHpMsgs);
		msg.set_numRxnMsgs(numRxnMsgs);
		return msg;
	}
	public String toString() {
		String result = "STATE MESSAGE:\n";
		result += "\tAgentID = " + id + "\n";
		result += "\tDest = " + dest + "\n";
		result += "\tReply Address = " + replyAddr + "\n";
		result += "\tStack Pointer = " + sp + "\n";
		result += "\tOpcode = " + op + "\n";
		result += "\tCondition = " + Long.toHexString(condition) + "\n";
		result += "\tCodesize = " + codeSize + "\n";
		result += "\tNumber of Heap Msgs = " + numHpMsgs + "\n";
		result += "\tNumber of Reaction Msgs = " + numRxnMsgs;
		return result;
	}
}


