// $Id: AgillaNbrMsgJ.java,v 1.5 2006/04/05 10:28:19 borndigerati Exp $

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
import java.util.Vector;

/**
 * This message is sent from a sensor node in response to an AgillaGetNbrMsgJ.  
 * It contains a list of neighbors in the sensor's neighbor list.
 * 
 * @author liang
 *
 */
public class AgillaNbrMsgJ implements MessageJ, AgillaConstants {
	private Vector neighbors = new Vector();
	private static final int AGILLA_NBR_MSG_SIZE = AgillaNbrMsg.numElements_nbr();
	
	public AgillaNbrMsgJ() {}
	
	public void addNeighbor(int nbr, int hopsToGW) {
		neighbors.add(new Address(nbr, hopsToGW));
	}
	
	public void addNeighbor(int nbr, int hopsToGW, int lqi) {
		neighbors.add(new Address(nbr, hopsToGW, lqi));
	}
	
	public AgillaNbrMsgJ(AgillaNbrMsg msg) {
		for (int i = 0; i < AGILLA_NBR_MSG_SIZE; i++) {
			int nbr = msg.getElement_nbr(i);
			int hopsToGW = msg.getElement_hopsToGW(i);
			int lqi = msg.getElement_lqi(i);
			if (nbr != TOS_BCAST_ADDRESS)
				addNeighbor(nbr, hopsToGW, lqi);
		}
	}
	
	public int getType() {
		//return AM_AGILLANBRMSG;
		return AgillaNbrMsg.AM_TYPE;
	}
	
	public Message toTOSMsg() {
		AgillaNbrMsg msg = new AgillaNbrMsg();
		int i = 0;
		for (; i < neighbors.size(); i++) {
			Address curr = (Address)neighbors.get(i);
			msg.setElement_nbr(i, curr.addr());
			msg.setElement_hopsToGW(i, curr.hopsToGW());
			msg.setElement_lqi(i, curr.lqi());
		}
		if (i < AGILLA_NBR_MSG_SIZE)
			msg.setElement_nbr(i++, TOS_BCAST_ADDRESS);
		return msg;
	}
	
	
	public Vector getNbrs() {
		return neighbors;
	}

	public String toString() {
		return "AgillaNbrMsg: " + getNbrs();
	}
}

