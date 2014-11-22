// $Id: AgillaOpStackMsgJ.java,v 1.5 2006/02/13 08:40:40 chien-liang Exp $

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

//import java.util.*;
import agilla.*;
import agilla.variables.*;
/**
 * AgiilaOpStackMsgJ.java
 *
 * @author Chien-Liang Fok
 */
public class AgillaOpStackMsgJ implements MessageJ, AgillaConstants  {
	private AgillaAgentID id;
	private short startAddr;
	//private Vector data = new Vector(); // a vector of AgillaStackVariables
	private short data[];
	
	private AgillaOpStackMsgJ()  {
		data = new short[AgillaOpStackMsg.numElements_data()];
	}
	
	public AgillaOpStackMsgJ(AgillaAgentID id, int replyAddr, short startAddr /*, byte data[]*/)  {
		this();
		this.id = id;
		this.startAddr = startAddr;
		//this.data = new short[data.length];
		//System.arraycopy(data, 0, this.data, 0, data.length);
	}
	
	public AgillaOpStackMsgJ(AgillaOpStackMsg msg)  {
		this();
		this.id  = new AgillaAgentID(msg.get_id_id());
		this.startAddr = msg.get_startAddr();

//		short[] msgdata = msg.get_data();
//		
//		int i = 0;
//		boolean done = false;
//		while (!done && i < msgdata.length - 2) {
//			AgillaStackVariable sv = VarUtil.getField(i, msgdata);
//			data.add(sv);
//			i += sv.getSize()+1;
//		}
		System.arraycopy(msg.get_data(), 0, data, 0, data.length);
	}
	
	public int dataLength() {
		return data.length;
	}
	
	public void setData(int pos, short data) {
		this.data[pos] = data;
	}
	
	public AgillaAgentID id() {
		return id;
	}
	
//	/**
//	 * Returns the number of data bytes used.
//	 */
//	public int size() {
//		int result = 0;
//		for (int i = 0; i < data.size(); i++) {
//			AgillaStackVariable sv = (AgillaStackVariable)data.get(i);
//			result += sv.getSize()+1;
//		}
//		return result;
//		return data.length;
//	}
	
//	public void addVar(AgillaStackVariable v)  {
//		data.add(v);
//	}
	
	public int getType()  {
		return AgillaOpStackMsg.AM_TYPE;
	}
	
	public net.tinyos.message.Message toTOSMsg()  {
		AgillaOpStackMsg msg = new AgillaOpStackMsg();
		msg.set_id_id(id.getID());
		msg.set_startAddr(startAddr);
		msg.set_data(data);
//		int dataIndex = 0;
		
		// the data is stored as ([type], [var])*
//		for (int i = 0; i < data.size(); i++) {
//			AgillaStackVariable sv = (AgillaStackVariable)data.get(i);
//			short[] bytes = sv.toBytes();    // save the variable
//			msg.setElement_data(dataIndex++, (short)sv.getType());
//			for (int j = 0; j < sv.getSize(); j++) {
//				msg.setElement_data(dataIndex++, bytes[j]);
//			}
//		}
//		while (dataIndex < AgillaOpStackMsg.numElements_data() /*AGILLA_OS_MSG_SIZE*/) {
//			msg.setElement_data(dataIndex++, AGILLA_TYPE_INVALID);
//		}
		
		return msg;
	}
	public String toString()  {
		String result = "AgillaOpStackMsg:\n";
		result += "Start address = " + startAddr + "\n";
		result += "Data: ";
		for (int i = 0; i < data.length; i++) {
			//AgillaStackVariable sv = (AgillaStackVariable)data.get(i);
			String curr = Long.toHexString(data[i]& 0xff);
			if (curr.length() == 1)
				curr = "0" + curr;
			result += "0x" + curr + " ";
		}
		return result;
	}
}
