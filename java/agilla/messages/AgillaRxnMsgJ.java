// $Id: AgillaRxnMsgJ.java,v 1.4 2006/02/13 08:40:40 chien-liang Exp $

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

import java.io.*;
import agilla.*;
import agilla.variables.*;

/**
 * AgillaRxnMsgJ.java
 *
 * @author Greg Hackmann
 * @author Chien-Liang Fok
 */
public class AgillaRxnMsgJ implements MessageJ, AgillaConstants, Serializable
{
	static final long serialVersionUID = -2389141470255801302L;
	private int msgNum;
	private Reaction rxn;
	
	public AgillaRxnMsgJ() {}

	public AgillaRxnMsgJ(short msgNum, Reaction rxn) {
		this.msgNum = msgNum;
		this.rxn = rxn;
	}

	public AgillaRxnMsgJ(AgillaRxnMsg msg) {		
		AgillaAgentID id = new AgillaAgentID(msg.get_rxn_id_id());				
		int pc = msg.get_rxn_pc();
		
		// create the tuple
		Tuple template = new Tuple(msg.get_rxn_template_flags());			
		short [] tupleData = msg.get_rxn_template_data();
		int byteIndex = 0;
		for(int i = 0; i < msg.get_rxn_template_size(); i++)
		{
			AgillaStackVariable sv = VarUtil.getField(byteIndex, tupleData);
			template.addField(sv);
			byteIndex += sv.getSize() + 1;
		}
		
		this.msgNum = msg.get_msgNum();
		this.rxn = new Reaction(id, pc, template);
	}
	
	
	public AgillaAgentID id() 
	{
		return rxn.getID();
	}

	public int getType() {
		//return AM_AGILLARXNMSG;
		return AgillaRxnMsg.AM_TYPE;
	}

	public int getMsgNum() {
		return msgNum;
	}

	public Reaction getReaction() {
		return rxn;
	}

	public net.tinyos.message.Message toTOSMsg() {
		AgillaRxnMsg msg = new AgillaRxnMsg();
		msg.set_msgNum(msgNum);
		msg.set_rxn_id_id(rxn.getID().getID());
		msg.set_rxn_pc(rxn.getPC());

		msg.set_rxn_template_flags(rxn.getTemplate().flags());
		msg.set_rxn_template_size(rxn.getTemplate().getSize());

		short dataIndex = 0;
		for(int i = 0; i < rxn.getTemplate().size(); i++)
		{
			AgillaStackVariable sv = rxn.getTemplate().getField(i);
			short [] bytes = sv.toBytes();
			msg.setElement_rxn_template_data(dataIndex++, sv.getType()); // save type
			for(int j = 0; j < sv.getSize(); j++)
				msg.setElement_rxn_template_data(dataIndex++, bytes[j]); // save var
		}

		return msg;
	}

	public String toString() {
		String result = "AgillaRxnMsg:\n";
		result += "\tMessage Number = " + msgNum + "\n";
		result += "\t" + rxn + "\n";
		return result;
	}
}
