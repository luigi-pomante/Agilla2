// $Id: AgillaAckHeapMsgJ.java,v 1.2 2005/11/11 02:15:49 chien-liang Exp $

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

public class AgillaAckHeapMsgJ implements MessageJ, AgillaConstants {
	private AgillaAgentID aID;
	private short accept, addr1;
	
	public AgillaAckHeapMsgJ() {
	}
	
	public AgillaAckHeapMsgJ(AgillaAgentID aID, short accept, short addr1) {
		this.aID = aID;
		this.accept = accept;
		this.addr1 = addr1;
	}
	
	public AgillaAckHeapMsgJ(AgillaAckHeapMsg msg) {
		aID = new AgillaAgentID(msg.get_id_id());
		accept = msg.get_accept();
		addr1 = msg.get_addr1();
	}
	
	public AgillaAgentID getID() {
		return aID;
	}
	
	public short getAccept() {
		return accept;
	}
	
	public int getAddr1() {
		return addr1;
	}
	
	public int getType() {
		//return AM_AGILLAACKHEAPMSG;
		return AgillaAckHeapMsg.AM_TYPE;
	}
	
	public Message toTOSMsg() {
		AgillaAckHeapMsg msg = new AgillaAckHeapMsg();
		msg.set_id_id(aID.getID());
		msg.set_accept(accept);
		msg.set_addr1(addr1);
		return msg;
	}
	
	public String toString() {
		return "ACK HEAP MESSAGE: " + aID.toString() + " accept = " + accept + " addr1 = " + addr1;
	}
}

