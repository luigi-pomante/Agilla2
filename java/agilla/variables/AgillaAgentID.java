// $Id: AgillaAgentID.java,v 1.1 2005/10/13 17:12:19 chien-liang Exp $

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
package agilla.variables;
import agilla.*;
/**
 * AgillaSVInvalid.java
 *
 * @author Chien-Liang Fok
 */
public class AgillaAgentID implements AgillaConstants, AgillaStackVariable, java.io.Serializable {
	private static int idCount = 0;
	private int id;  // top 8 bits = hostID, lower 8 bits = count
	/**
	 * Creates a new unique AgillaAgentID.
	 */
	public AgillaAgentID () {
		id = idCount++;
	}
	public AgillaAgentID(int id) {
		this.id = id;
	}
	public AgillaStackVariable deepClone() {
		return new AgillaAgentID(id);
	}	
	public int getID() {
		return id;
	}
	/**
	 * An AgillaAgentID is two bytes.
	 */
	public short getSize() {
		return 2;
	}
	public short[] toBytes() {
		short[] result = new short[2];
		result[0] = (short)(getID() & 0xff);
		result[1] = (short)(getID() >> 8 & 0xff);
		return result;
	}
	public boolean equals(Object o) {
		if (o instanceof AgillaAgentID) {
			return ((AgillaAgentID)o).getID() == id;
		} else
			return false;
	}
	public int hashCode() {
		return 0;
	}
	public short getType() {
		return AGILLA_TYPE_AGENTID;
	}
	public boolean matches(AgillaStackVariable v) {
		if (v instanceof AgillaAgentID) {
			AgillaAgentID av = (AgillaAgentID)v;
			return av.getID() == av.getID();
		} else return false;
	}
	public String toString() {
		return "[AgillaAgentID: " + id + "]";
	}
}

