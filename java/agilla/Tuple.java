// $Id: Tuple.java,v 1.3 2005/11/18 00:41:44 chien-liang Exp $

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
/**
 * Tuple.java
 *
 * @author Chien-Liang Fok
 */

package agilla;

import java.io.Serializable;
import java.util.*;
import agilla.variables.*;

public class Tuple implements AgillaConstants, Serializable {
	private static final long serialVersionUID = -7592530006399035044L;
	private short flags;
	private Vector fields = new Vector();
	
	public Tuple() {
		this((short)0);
	}
	
	public Tuple(short flags) {
		this.flags = flags;
	}
	
	public Tuple deepClone() {
		Tuple result = new Tuple(flags);
		for (int i = 0; i < fields.size(); i++) {
			result.addField(((AgillaStackVariable)fields.get(i)).deepClone());
		}
		return result;
	}
	
	public short flags() {
		return flags;
	}
	
	public void setFlags(short flags) {
		this.flags = flags;
	}
	
	/**
	 * Returns the number of bytes contained within the fields of the tuple.
	 */
	private short getSizeBytes() {
		short result = 0;
		for (int i = 0; i < fields.size(); i++) {
			result += ((AgillaStackVariable)fields.get(i)).getSize();
		}
		return result;
	}
	
	public short getSize() {
		return (short)fields.size();
	}
	
	public boolean addField(AgillaStackVariable v) {
		if (getSizeBytes() + v.getSize() < AGILLA_MAX_TUPLE_SIZE) {
			fields.add(v);
			return true;
		} else
			return false;
	}
	
	public AgillaStackVariable getField(int pos) {
		if (pos < fields.size())
			return (AgillaStackVariable)fields.get(pos);
		else
			return new AgillaInvalidVariable();
	}
	
	public int size() {
		return fields.size();
	}
	
	/**
	 * Returns true if this tuple matches t.
	 */
	public boolean matches(Tuple t) {
		boolean result = true;
		if (t.size() == size()) {
			for (int i = 0; i < size() && result; i++) {
				Debugger.dbg("Tuple.matches()", "" + i + " Comparing: " + getField(i) + ", with " + t.getField(i));
				result = getField(i).matches(t.getField(i));
			}
		} else result = false;
		return result;
	}
	
	public boolean equals(Tuple t) {
		boolean result = true;
		if (t.size() == size()) {
			for (int i = 0; i < size() && result; i++) {
				Debugger.dbg("Tuple.equals()", "" + i + " Comparing: " + getField(i) + ", with " + t.getField(i));
				result = getField(i).equals(t.getField(i));
			}
		} else result = false;
		return result;
	}
	
	
	public String toString() {
		String result = "TUPLE: flags = 0x" + Long.toHexString(flags) + ", numFields = " + getSize() + "\n";
		for (int i = 0; i < getSize(); i++) {
			result += "\tField " + i + ": " + fields.get(i).toString() + "\n";
		}
		return result;
	}
}

