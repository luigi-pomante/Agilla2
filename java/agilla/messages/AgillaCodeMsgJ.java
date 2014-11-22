// $Id: AgillaCodeMsgJ.java,v 1.3 2006/02/13 08:40:40 chien-liang Exp $
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
/**
 * AgillaCodeMsgJ.java
 *
 * @author Chien-Liang Fok
 */
package agilla.messages;
import agilla.*;
import agilla.variables.*;
import net.tinyos.message.*;
public class AgillaCodeMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID id;
	private int msgNum;
	private short[] code = new short[AgillaCodeMsg.numElements_code()/*AGILLA_CODE_BLOCK_SIZE*/];
	
	public AgillaCodeMsgJ() {}
	
	public AgillaCodeMsgJ(AgillaAgentID id, int replyAddr, short msgNum) {
		this.id = id;
		this.msgNum = msgNum;
	}
	
	public AgillaCodeMsgJ(AgillaCodeMsg msg) {
		this.id = new AgillaAgentID(msg.get_id_id());
		this.msgNum = msg.get_msgNum();
		short[] c = msg.get_code();
		for (int i = 0; i < c.length; i++) {
			this.code[i] = c[i];
		}
	}
	public void setCode(int pos, short instr) {
		code[pos] = instr;
	}
	
	public AgillaAgentID id() {
		return id;
	}
	
	public int msgNum() {
		return msgNum;
	}
	
	public Message toTOSMsg() {
		AgillaCodeMsg msg = new AgillaCodeMsg();
		msg.set_id_id(id.getID());
		msg.set_msgNum(msgNum);
		msg.set_code(code);
		return msg;
	}
	public int getType() {
		//return AM_AGILLACODEMSG;
		return AgillaCodeMsg.AM_TYPE;
	}
	
	public String toString() {
		String result = "CODE MESSAGE:\n";
		result += "\t" + id + "\n";
		result += "\tMsgNum: " + msgNum + "\n";
		result += "\tCode: \n\t\t";
		
		for (int i = 0; i < code.length/2; i++) {
			String curr = Long.toHexString(code[i]& 0xff);
			if (curr.length() == 1)
				curr = "0" + curr;
			result += msgNum*AgillaCodeMsg.numElements_code()+i + ":0x" + curr + " ";
		}
		result += "\n\t\t";
		for (int i = code.length/2; i < code.length; i++) {
			String curr = Long.toHexString(code[i]& 0xff);
			if (curr.length() == 1)
				curr = "0" + curr;
			result += msgNum*AgillaCodeMsg.numElements_code()+i + ":0x" + curr + " ";
		}
		return result;
	}
}

