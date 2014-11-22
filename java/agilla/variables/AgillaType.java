// $Id: AgillaType.java,v 1.2 2006/04/27 01:19:29 chien-liang Exp $

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


/**
 * An AgillaType is used for matching by types within templates.
 * 
 * @author liang
 *
 */
public class AgillaType implements AgillaConstants, AgillaStackVariable,
	java.io.Serializable
{
	private int dType;  // data type
	
	/**
	 * Creates an AgillaType.  Value parameter values are defined within
	 * AgillaConstants.
	 * @param dType
	 */
	public AgillaType(int dType) {
		this.dType = dType;
	}
	
	/**
	 * An AgillaType is two bytes.
	 */
	public short getSize() {
		return 2;
	}
	
	public short[] toBytes() {
		short[] result = new short[getSize()];
		result[0] = (short)(dType & 0xff);
		result[1] = (short)(dType >> 8 & 0xff);
		return result;
	}
	
	public AgillaStackVariable deepClone() {
		return new AgillaType(dType);
	}
	
	/**
	 * Returns AGILLA_TYPE_TYPE.
	 */
	public short getType() {
		return AGILLA_TYPE_TYPE;
	}
	
	public int getDataType() {
		return dType;
	}
	
	public boolean equals(Object o) {
		if (o instanceof AgillaType) {
			AgillaType t = (AgillaType)o;
			return t.getDataType() == getDataType();
		}
		return false;
	}
	
	public boolean matches(AgillaStackVariable v) {
		switch(dType) {
			case AGILLA_TYPE_ANY:
				return true;
			case AGILLA_TYPE_VALUE:
				return v instanceof AgillaValue;
			case AGILLA_TYPE_LOCATION:
				return v instanceof AgillaLocation;
			case AGILLA_TYPE_STRING:
				return v instanceof AgillaString;
			case AGILLA_TYPE_TYPE:
				if (v instanceof AgillaType) {
					return ((AgillaType)v).equals(this);
				} else return false;
			case AGILLA_TYPE_AGENTID:
				return v instanceof AgillaAgentID;
		}
		return false;
	}
	
	private String type2String(int dType) {
		switch(dType) {
			case AGILLA_TYPE_INVALID:
				return "INVALID";
			case AGILLA_TYPE_VALUE:
				return "VALUE";
			case AGILLA_TYPE_READING:
				return "READING";
			case AGILLA_TYPE_STRING:
				return "STRING";
			case AGILLA_TYPE_ANY:
				return "ANY";
			case AGILLA_TYPE_TYPE:
				return "TYPE";
			case AGILLA_TYPE_AGENTID:
				return "AGENTID";
			case AGILLA_TYPE_LOCATION:
				return "LOCATION";
			default:
				return "UNKNOWN";
		}
	}
	
	/*private String sensor2String(int sType) {
		switch(sType) {
			case AGILLA_STYPE_NONE:
				return "NONE";
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
	 }*/
	
	public String toString() {
		return "[Type Variable: data type = " + type2String(dType) + "]";
	}
}

