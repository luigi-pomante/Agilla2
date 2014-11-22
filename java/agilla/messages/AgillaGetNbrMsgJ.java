// $Id: AgillaGetNbrMsgJ.java,v 1.6 2006/04/06 01:06:08 chien-liang Exp $

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
import net.tinyos.message.*;

/**
 * This message is sent to a node in the network to query its neighbor list.
 * 
 * @author liang
 */
public class AgillaGetNbrMsgJ implements MessageJ, AgillaConstants {
	private int fromPC, replyAddr, destAddr;
	
	private AgillaGetNbrMsgJ() {
	}
	
	/**
	 * Constructor.
	 * @param destAddr The original address of the destination mote.
	 */
	public AgillaGetNbrMsgJ(int fromPC, int replyAddr, int destAddr) {
		this();
		this.fromPC = fromPC;
		this.replyAddr = replyAddr;
		this.destAddr = destAddr;
	}
	public AgillaGetNbrMsgJ(AgillaGetNbrMsg msg) {
		destAddr = msg.get_destAddr();
		replyAddr = msg.get_replyAddr();
		fromPC = msg.get_fromPC();
	}
	
	public int getType() {
		//return AM_AGILLAGETNBRMSG;
		return AgillaGetNbrMsg.AM_TYPE;
	}
	public Message toTOSMsg() {
		AgillaGetNbrMsg msg = new AgillaGetNbrMsg();
		msg.set_destAddr(destAddr);
		msg.set_replyAddr(replyAddr);
		msg.set_fromPC(fromPC);
		return msg;
	}

	public String toString() {
		return "AgillaGetNbrMsg: replyAddr = " + replyAddr +
			", destAddr = " + destAddr + ", fromPC = " + fromPC;
	}
}
