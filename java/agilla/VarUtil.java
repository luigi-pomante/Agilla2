// $Id: VarUtil.java,v 1.3 2005/11/17 23:24:59 chien-liang Exp $

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
 * VarUtil.java
 *
 * @author Created by Omnicore CodeGuide
 */

package agilla;

import agilla.variables.*;

public class VarUtil implements AgillaConstants
{
	/**
	 * Retrieves the fields stored as a byte array.
	 * The byte array must be of the form [vtype], [var], [vtype], [var], ...
	 * startIndex must point to a vtype.
	 * 
	 * @param startIndex The array index where the variable is stored
	 * @param data The data bytes.
	 * @return The stack variable being pointed to by startIndex
	 */
	public static AgillaStackVariable getField(int startIndex, short[] data) {
		short vtype = data[startIndex++];
		if (vtype == AGILLA_TYPE_VALUE) {
			short val = data[startIndex++];
			val |= (data[startIndex++] << 8);
			return new AgillaValue(val);
		} else if (vtype == AGILLA_TYPE_READING) {
			int rtype = 0, reading = 0;
			rtype = data[startIndex++];
			rtype |= (data[startIndex++] << 8);
			reading = data[startIndex++];
			reading |= (data[startIndex++] << 8);
			return new AgillaReading(rtype, reading);
		} else if (vtype == AGILLA_TYPE_STRING) {
			int string = data[startIndex++];
			string |= (data[startIndex++] << 8);
			return new AgillaString(string);
		} else if (vtype == AGILLA_TYPE_TYPE) {
			int dtype = 0;
			dtype = data[startIndex++];
			dtype |= (data[startIndex++] << 8);
			return new AgillaType(dtype);
		} else if (vtype == AGILLA_TYPE_RTYPE) {
			int stype = 0;
			stype = data[startIndex++];
			stype |= (data[startIndex++] << 8);
			return new AgillaRType(stype);
		} else if (vtype == AGILLA_TYPE_AGENTID) {
			int id = data[startIndex++];
			id |= (data[startIndex++]<< 8);
			return new AgillaAgentID(id);
		} else if (vtype == AGILLA_TYPE_LOCATION) {
			int x, y;
			x = data[startIndex++];
			x |= (data[startIndex++] << 8);
			y = data[startIndex++];
			y |= (data[startIndex++] << 8);
			return new AgillaLocation(x,y);
		} else
			return new AgillaInvalidVariable();
	}
	
	
	public static AgillaStackVariable pop(int sp, short [] data) {
		short vtype = data[sp--];
		if (vtype == AGILLA_TYPE_VALUE) {
			short val = data[sp - 1];
			val |= (data[sp] << 8);
			return new AgillaValue(val);
		} else if (vtype == AGILLA_TYPE_READING) {
			int rtype = 0, reading = 0;
			rtype = data[sp - 3];
			rtype |= (data[sp - 2] << 8);
			reading = data[sp - 1];
			reading |= (data[sp] << 8);
			return new AgillaReading(rtype, reading);
		} else if (vtype == AGILLA_TYPE_STRING) {
			int string = data[sp - 1];
			string |= (data[sp] << 8);
			return new AgillaString(string);
		} else if (vtype == AGILLA_TYPE_TYPE) {
			int dtype = 0;
			dtype = data[sp - 1];
			dtype |= (data[sp] << 8);
			return new AgillaType(dtype);
		} else if (vtype == AGILLA_TYPE_RTYPE) {
			int stype = 0;
			stype = data[sp - 1];
			stype |= (data[sp] << 8);
			return new AgillaRType(stype);
		} else if (vtype == AGILLA_TYPE_AGENTID) {
			int id = data[sp - 1];
			id |= (data[sp]<< 8);
			return new AgillaAgentID(id);
		} else if (vtype == AGILLA_TYPE_LOCATION) {
			int x, y;
			x = data[sp - 3];
			x |= (data[sp - 2] << 8);
			y = data[sp - 1];
			y |= (data[sp] << 8);
			return new AgillaLocation(x,y);
		} else
			return new AgillaInvalidVariable();
		
	}
	
	private static byte[] save5Bytes(int vtype, int data1, int data2) {
		byte[] result = new byte[5];
		result[0] = (byte)(data1 & 0xff);
		result[1] = (byte)(data1 >> 8);
		result[2] = (byte)(data2 & 0xff);
		result[3] = (byte)(data2 >> 8);
		result[4] = (byte)vtype;
		return result;
	}
	
	private static byte[] save3Bytes(int vtype, int data) {
		byte[] result = new byte[3];
		result[0] = (byte)(data & 0xff);
		result[1] = (byte)(data >> 8);
		result[2] = (byte)vtype;
		return result;
	}
	/**
	 * Returns a byte array for storing the variable in an operand stack.
	 * 
	 * @param v The variable to convert into bytes
	 * @return The variable in the form of a byte array
	 */
	public static byte[] toStackBytes(AgillaStackVariable v) {
		short vtype = v.getType();
		switch(vtype) {
		case AGILLA_TYPE_VALUE:
			return save3Bytes(vtype, ((AgillaValue)v).getValue());
		case AGILLA_TYPE_READING:
			AgillaReading r = (AgillaReading)v;
			int rtype = r.getReadingType(), reading = r.getReading();
			return save5Bytes(vtype, rtype, reading);
		case AGILLA_TYPE_STRING:
			return save3Bytes(vtype, ((AgillaString)v).getString());
		case AGILLA_TYPE_TYPE:
			return save3Bytes(vtype, ((AgillaType)v).getDataType());
		case AGILLA_TYPE_RTYPE:
			return save3Bytes(vtype, ((AgillaRType)v).getReadingType());
		case AGILLA_TYPE_AGENTID:
			return save3Bytes(vtype, ((AgillaAgentID)v).getID());
		case AGILLA_TYPE_LOCATION:
			return save5Bytes(vtype, ((AgillaLocation)v).getx(),((AgillaLocation)v).gety());
		default:
			return null;		
		}
	}
}

