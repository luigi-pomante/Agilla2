// $Id: AgillaAckOpStackMsgJ.java,v 1.3 2005/11/17 15:37:35 chien-liang Exp $

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

public class AgillaAckOpStackMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID aID;
	private short accept, startAddr;
	
	
	public AgillaAckOpStackMsgJ() {		
	}
	
	public AgillaAckOpStackMsgJ(AgillaAgentID aID, short accept, short startAddr) {
		this.aID = aID;
		this.accept = accept;
		this.startAddr = startAddr;
	}
		
	public AgillaAckOpStackMsgJ(AgillaAckOpStackMsg msg) {
		aID = new AgillaAgentID(msg.get_id_id());
		accept = msg.get_accept();
		startAddr = msg.get_startAddr();		
	}

	public AgillaAgentID getID() {
		return aID;
	}
	
	public short getAccept() {
		return accept;
	}
	
	public short getStartAddr() {
		return startAddr;
	}

	public int getType() {
		return AgillaAckOpStackMsg.AM_TYPE;
	}
	
	public Message toTOSMsg() {
		AgillaAckOpStackMsg msg = new AgillaAckOpStackMsg();
		msg.set_id_id(aID.getID());
		msg.set_accept(accept);
		msg.set_startAddr(startAddr);
		return msg;
	}
	
	
	public String toString() {
		return "ACK OPSTACK MESSAGE: " + aID.toString() + " accept = " + accept + " startAddr = " + startAddr;
	}
}

