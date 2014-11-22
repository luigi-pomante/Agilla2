// $Id: AgillaErrorMsgJ.java,v 1.2 2005/11/11 02:15:49 chien-liang Exp $

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
package agilla.messages;
import agilla.*;
import agilla.variables.*;
/**
 * AgillaErrorMsgJ.java
 *
 * @author Chien-Liang Fok
 */
public class AgillaErrorMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID id;
	private short cause, instr, sp;
	private int src, pc, reason1, reason2;
	public AgillaErrorMsgJ() {}
	public AgillaErrorMsgJ(AgillaAgentID id, int src,
	                       short cause, short pc, short instr,
						   short sp, int reason1, int reason2) 
	{
		this.id = id;
		this.src = src;
		this.cause = cause;
		this.pc = pc;
		this.instr = instr;
		this.sp = sp;
		this.reason1 = reason1;
		this.reason2 = reason2;
	}
	public AgillaErrorMsgJ(AgillaErrorMsg msg) {
		id = new AgillaAgentID(msg.get_id_id());
		src = msg.get_src();
		cause = msg.get_cause();
		pc = msg.get_pc();
		instr = msg.get_instr();
		sp = msg.get_sp();
		reason1 = msg.get_reason1();
		reason2 = msg.get_reason2();
	}
	public AgillaAgentID getID() {
		return id;
	}
	public int getSrc() {
		return src;
	}
	
	public short getCause() {
		return cause;
	}
	
	public int getPC() {
		return pc;
	}
	
	public short getInstr() {
		return instr;
	}
	
	public short getSP() {
		return sp;
	}
	public int getReason1() {
		return reason1;
	}
	public int getReason2() {
		return reason2;
	}
	public int getType() {
		//return AM_AGILLAERRORMSG;
		return AgillaErrorMsg.AM_TYPE;
	}
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaErrorMsg msg = new AgillaErrorMsg();
		msg.set_id_id(id.getID());
		msg.set_src(src);
		msg.set_cause(cause);
		msg.set_pc(pc);
		msg.set_instr(instr);
		msg.set_sp(sp);
		msg.set_reason1(reason1);
		msg.set_reason2(reason2);
		return msg;
	}
	public String toString() {
		String result = "AgillaErrorMessage: \n";
		result += "\t" + id + "\n";
		result += "\tSource: " + src + "\n";
		result += "\tCause: " + cause + " (" + ErrorDisplayer.getCause(cause) + ")\n";
		result += "\tpc: " + pc + "\n";
		result += "\tinstruction: 0x" + Integer.toHexString(instr) + "\n";
		result += "\tsp: " + sp + "\n";
		result += "\treason1: " + reason1 + "\n";
		result += "\treason2: " + reason2 + "\n";
		return result;
	}
}

