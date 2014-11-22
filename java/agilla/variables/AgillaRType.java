// $Id: AgillaRType.java,v 1.1 2005/10/13 17:12:19 chien-liang Exp $

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
 * AgillaSVInvalid.java
 *
 * @author Chien-Liang Fok
 */

package agilla.variables;
import agilla.*;


public class AgillaRType implements AgillaConstants, AgillaStackVariable,
	java.io.Serializable {
	private int stype;
	
	public AgillaRType(int stype) {
		this.stype= stype;
	}
	
	/**
	 * An AgillaType is four bytes.
	 */
	public short getSize() {
		return 2;
	}
	
	public short[] toBytes() {
		short[] result = new short[getSize()];
		result[0] = (short)(stype & 0xff);
		result[1] = (short)(stype >> 8 & 0xff);
		return result;
	}
	
	public AgillaStackVariable deepClone() {
		return new AgillaRType(stype);
	}
	
	/**
	 * Returns AGILLA_TYPE_TYPE.
	 */
	public short getType() {
		return AGILLA_TYPE_TYPE;
	}
	
	public int getReadingType() {
		return stype;
	}
	
	public boolean equals(Object o) {
		if (o instanceof AgillaRType) {
			AgillaRType t = (AgillaRType)o;
			return t.getReadingType() == getReadingType();
		}
		return false;
	}
	
	public boolean matches(AgillaStackVariable v) {
		if (v instanceof AgillaReading) {
			if (getReadingType() == AGILLA_STYPE_ANY)
				return true;
			else {
				AgillaReading reading = (AgillaReading)v;
				return reading.getReadingType() == getReadingType();
			}
		}
		return false;
	}
	
	public static String sensor2String(int sType) {
		switch(sType) {
			case AGILLA_STYPE_ANY:
				return "ANY";
			case AGILLA_STYPE_PHOTO:
				return "PHOTO";
			case AGILLA_STYPE_TEMP:
				return "TEMPERATURE";
			case AGILLA_STYPE_MIC:
				return "MICROPHONE";
			case AGILLA_STYPE_MAGX:
				return "MAG_X";
			case AGILLA_STYPE_MAGY:
				return "MAG_Y";
			case AGILLA_STYPE_ACCELX:
				return "ACCEL_X";
			case AGILLA_STYPE_ACCELY:
				return "ACCEL_Y";
			default:
				return "INVALID";
		}
	}
	
	public String toString() {
		return "[Reading Type Variable: " + sensor2String(stype) + "]";
	}
}

