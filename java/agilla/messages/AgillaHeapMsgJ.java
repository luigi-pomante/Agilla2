// $Id: AgillaHeapMsgJ.java,v 1.3 2006/02/13 08:40:40 chien-liang Exp $

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
import net.tinyos.message.*;
import java.util.Vector;

public class AgillaHeapMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID id;
	private Vector data = new Vector();
	
	private AgillaHeapMsgJ() {
	}
	
	public AgillaHeapMsgJ(AgillaAgentID id) {
		this();
		this.id = id;
	}
	
	public AgillaHeapMsgJ(AgillaHeapMsg msg) {
		this.id = new AgillaAgentID(msg.get_id_id());
		short[] msgdata = msg.get_data();
		
		int i = 0;
		boolean done = false;
		while (!done && i < msgdata.length - 2) {
			short addr = msgdata[i++];
			AgillaStackVariable sv = VarUtil.getField(i, msgdata);
			if (sv.getType() != AGILLA_TYPE_INVALID) {
				data.add(new HeapItem(sv, addr));
				i += sv.getSize()+1;
			} else
				done = true;
		}
	}
	
	public int getType() {
		//return AM_AGILLAHEAPMSG;
		return AgillaHeapMsg.AM_TYPE;
	}
	
	public void addHeapItem(short address, AgillaStackVariable sv) {
		if (size() + sv.getSize() < AgillaHeapMsg.numElements_data()/*AGILLA_HEAP_MSG_SIZE*/)
			data.add(new HeapItem(sv, address));
		else {
			System.err.println("ERROR: AgillaHeapMsgJ: not enough space to add heap item.");
		}
	}
	
	public Message toTOSMsg() {
		AgillaHeapMsg msg = new AgillaHeapMsg();
		msg.set_id_id(id.getID());
		int dataIndex = 0;
		
		// the data is stored as ([addr], [type], [var])*
		for (int i = 0; i < data.size(); i++) {
			HeapItem hi = (HeapItem)data.get(i);
			msg.setElement_data(dataIndex++, hi.pos); // save the address
			short[] bytes = hi.sv.toBytes();    // save the variable
			msg.setElement_data(dataIndex++, (short)hi.sv.getType());
			for (int j = 0; j < hi.sv.getSize(); j++) {
				msg.setElement_data(dataIndex++, bytes[j]);
			}
		}
		while (dataIndex < AgillaHeapMsg.numElements_data()/*AGILLA_HEAP_MSG_SIZE*/) {
			msg.setElement_data(dataIndex++, AGILLA_TYPE_INVALID);
		}
		return msg;
	}
	
	public AgillaAgentID id() {
		return id;
	}
	
	/**
	 * Returns the number of bytes used in the data field.
	 */
	public int size() {
		int result = 0;
		for (int i = 0; i < data.size(); i++) {
			HeapItem hi = (HeapItem)data.get(i);
			result += hi.sv.getSize()+2;
		}
		return result;
	}
	
	/**
	 * Returns the number of variables stored in the data field.
	 */
	public short numVariables() {
		return (short)data.size();
	}
	
	/**
	 * Returns the address of a particular entry.
	 */
	public short getAddr(short pos) {
		HeapItem h = (HeapItem)data.get(pos);
		return h.pos;
	}
	
	/**
	 * Returns the data of a particular entry.
	 */
	public AgillaStackVariable getData(short pos) {
		HeapItem h = (HeapItem)data.get(pos);
		return h.sv;
	}
	
	public String toString() {
		String result = "HEAP MESSAGE:\n";
		for (int i = 0; i < data.size(); i++) {
			HeapItem hi = (HeapItem)data.get(i);
			result += "\tvar" + i + ": addr=" + hi.pos + ", var=" + hi.sv + "\n";
		}
		return result;
	}
	
	private class HeapItem {
		AgillaStackVariable sv;
		short pos;
		
		public HeapItem(AgillaStackVariable sv, short pos) {
			this.sv = sv;
			this.pos = pos;
		}
	}
}

