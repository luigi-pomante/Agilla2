// $Id: AgillaTSResMsgJ.java,v 1.6 2006/04/19 18:58:57 chien-liang Exp $

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

public class AgillaTSResMsgJ  implements MessageJ, AgillaConstants, BasicOpcodes {
	private int dest;
	private short op, success;
	private Tuple tuple;

	public AgillaTSResMsgJ() {}

	public AgillaTSResMsgJ(int dest, short op, short success, Tuple t) {
		this.dest = dest;
		this.op = op;
		this.success = success;
		this.tuple = t;
	}

	public AgillaTSResMsgJ(AgillaTSResMsg msg) {
		//System.out.println("Creating an AgillaTSResMsgJ from " + msg);
		dest = msg.get_dest();
		op = msg.get_op();
		success = msg.get_success();
		if (success == 1) {
			tuple = new Tuple(msg.get_tuple_flags());

			short[] tupleData = msg.get_tuple_data();
			int byteIndex = 0;
			for (int i = 0; i < msg.get_tuple_size(); i++) {
				AgillaStackVariable sv = VarUtil.getField(byteIndex, tupleData);
				//System.out.println("Adding field " + i + ": " + sv);
				tuple.addField(sv);
				byteIndex += sv.getSize()+1; // add one for sv type
			}
		}
	}

	public int getType() {
		//return AM_AGILLATSRESMSG;
		return AgillaTSResMsg.AM_TYPE;
	}

	public net.tinyos.message.Message toTOSMsg() {
		AgillaTSResMsg msg = new AgillaTSResMsg();
		msg.set_dest(dest);
		msg.set_op(op);
		msg.set_success(success);

		if(tuple != null) {
			msg.set_tuple_flags(tuple.flags());
			msg.set_tuple_size(tuple.getSize());
		}
		
		//if (success == 1) {
		short dataIndex = 0;
		for (int i = 0; i < tuple.size(); i++) {
			AgillaStackVariable sv = tuple.getField(i);
			short[] bytes = sv.toBytes();
			msg.setElement_tuple_data(dataIndex++, sv.getType());  // save type
			for (int j = 0; j < sv.getSize(); j++) {
				msg.setElement_tuple_data(dataIndex++, bytes[j]);  // save var
			}
		}
		//}
		return msg;
	}

	public Tuple getTuple() {
		return tuple;
	}

	public boolean isSuccess() {
		return success == 1;
	}

	private String getString(short op) {
		switch(op) {
			case OProut:
				return "AgillaTSResMsg: rout";
			case OPrinp:
				return "AgillaTSResMsg: rinp";
			case OPrrdp:
				return "AgillaTSResMsg: rrdp";
//			case OPrinpg:
//				return "AgillaTSResMsg: rinpg";
//			case OPrrdpg:
//				return "AgillaTSResMsg: rrdpg";
			default:
				return "UNKNOWN";
		}
	}

	public String toString() {
		String result = "AGILLA_TS_RES_MSG:\n";
		result += "\top = " + op + " ("+getString(op)+")\n";
		result += "\tdest = " + dest + "\n";
		result += "\tsuccess = " + success + "\n\ttuple = ";
		if (tuple == null)
			result += tuple;
		else
			result += tuple.toString().replaceAll("\n", "\n\t");
		return result;
	}
}

