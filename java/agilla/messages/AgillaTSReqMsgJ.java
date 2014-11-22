// $Id: AgillaTSReqMsgJ.java,v 1.4 2005/12/09 07:24:06 chien-liang Exp $

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
import agilla.opcodes.BasicOpcodes;

public class AgillaTSReqMsgJ implements MessageJ, AgillaConstants, BasicOpcodes {
	private int dest, reply;
	private short op;
	private Tuple template;
	
	public AgillaTSReqMsgJ() {}
	
	public AgillaTSReqMsgJ(int dest, int reply, short op, Tuple template) {
		this.dest = dest;
		this.reply = reply;
		this.op = op;
		this.template = template;
	}
	
	public AgillaTSReqMsgJ(AgillaTSReqMsg msg) {
		this.dest = msg.get_dest();
		this.reply = msg.get_reply();
		this.op = msg.get_op();		
		this.template = new Tuple(msg.get_template_flags());
		
		short[] tupleData = msg.get_template_data();
		int byteIndex = 0;
		for (int i = 0; i < msg.get_template_size(); i++) {
			AgillaStackVariable sv = VarUtil.getField(byteIndex, tupleData);
			template.addField(sv);
			byteIndex += sv.getSize()+1; // add one for sv type
		}
	}
	
	public int getType() {
		return AgillaTSReqMsg.AM_TYPE;
	}
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaTSReqMsg msg = new AgillaTSReqMsg();
		
		msg.set_dest(dest);		
		msg.set_reply(reply);
		msg.set_op(op);
		
		msg.set_template_flags(template.flags());
		msg.set_template_size(template.getSize());
		
		short dataIndex = 0;
		for (int i = 0; i < template.size(); i++) {
			AgillaStackVariable sv = template.getField(i);
			short[] bytes = sv.toBytes();
			msg.setElement_template_data(dataIndex++, sv.getType());  // save type
			for (int j = 0; j < sv.getSize(); j++) {
				msg.setElement_template_data(dataIndex++, bytes[j]);  // save var
			}
		}
		return msg;
	}
	
	private String getString(short op) {
		switch(op) {
			case OProut:
				return "rout";
			case OPrinp:
				return "rinp";
			case OPrrdp:
				return "rrdp";
			default:
				return "UNKNOWN";
		}
	}
	
	public int getReply() {
		return reply;
	}
	
	public short getOp() {
		return op;
	}
	
	public Tuple getTemplate() {
		return template;
	}
	
	public String toString() {
		String result = "AgillaTSReqMsg:\n";
		result += "\top = 0x" + Integer.toHexString(op) + " ("+getString(op)+")\n";
		result += "\tdest = " + dest + "\n";
		result += "\treply = " + reply + "\n\ttemplate = ";
		if (template == null)
			result += template;
		else
			result += template.toString().replaceAll("\n", "\n\t");
		return result;
	}	
}

