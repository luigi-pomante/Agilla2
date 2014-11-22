// $Id: AgillaString.java,v 1.3 2006/04/27 01:19:29 chien-liang Exp $

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

import java.io.*;

public class AgillaString implements AgillaConstants, AgillaStackVariable,
	java.io.Serializable
{
	private int string;
	
	public AgillaString(int string) {
		this.string = string;
	}
	
	public AgillaString(String string) {
		try {
			this.string = string2byte(string);
		} catch(IOException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Converts an ASCII character into its integer representation within Agilla.
	 * 
	 * @param c The ASCII character.
	 * @return The integer encoding of it in Agilla
	 * @throws IOException
	 */
	private static final int char2int(char c) throws IOException {
		if (c == 'a') return 1;
		if (c == 'b') return 2;
		if (c == 'c') return 3;
		if (c == 'd') return 4;
		if (c == 'e') return 5;
		if (c == 'f') return 6;
		if (c == 'g') return 7;
		if (c == 'h') return 8;
		if (c == 'i') return 9;
		if (c == 'j') return 10;
		if (c == 'k') return 11;
		if (c == 'l') return 12;
		if (c == 'm') return 13;
		if (c == 'n') return 14;
		if (c == 'o') return 15;
		if (c == 'p') return 16;
		if (c == 'q') return 17;
		if (c == 'r') return 18;
		if (c == 's') return 19;
		if (c == 't') return 20;
		if (c == 'u') return 21;
		if (c == 'v') return 22;
		if (c == 'w') return 23;
		if (c == 'x') return 24;
		if (c == 'y') return 25;
		if (c == 'z') return 26;
		
		if (c == '0') return 27;
		if (c == '1') return 28;
		if (c == '2') return 29;
		if (c == '3') return 30;
		if (c == '4') return 31;
		if (c == '5') return 32;
		if (c == '6') return 33;
		if (c == '7') return 34;
		if (c == '8') return 35;
		if (c == '9') return 36;
		
		throw new IOException("Invalid character: " + c);
	}
	
	/**
	 * Converts an ASCII string into the encoding used by Agilla.  Note that
	 * Agilla only supports strings up to 3 characters with the following 
	 * format: [a-z][a-z][a-z,1-9].
	 *  
	 * @param s An ASCII string.
	 * @return The byte representation of the string.
	 * @throws IOException
	 */
	public static final int string2byte(String s) throws IOException {
		char c1 = 0, c2 = 0, c3 = 0;
		
		switch(s.length()) {
		case 1:
			c1 = c2 = 0;
			c3 = s.charAt(0);
			break;
		case 2:
			c1 = 0;
			c2 = s.charAt(0);
			c3 = s.charAt(1);
			break;
		case 3:
			c1 = s.charAt(0);
			c2 = s.charAt(1);
			c3 = s.charAt(2);
			break;
		default:
			throw new IOException("Exceeded maximum length of string (" + s.length() + ")");
		}
				
		if ((char2int(c1) >> 5) > 0)
			throw new IOException("First character (" + c1 + ") is invalid, only [a-z] are valid");		
		if ((char2int(c2) >> 5) > 0)
			throw new IOException("Second character (" + c2 + ") is invalid, only [a-z] are valid");		
		Integer intValue = new Integer(char2int(c1) << 11 | char2int(c2) << 6 | char2int(c3));
		Debugger.dbg("AgillaString", s + " = " + intValue);
		return intValue.intValue();
	}
	
	public AgillaStackVariable deepClone() {
		return new AgillaString(string);
	}
	
	/**
	 * An AgillaString is two bytes.
	 */
	public int getString() {
		return string;
	}
	
	public short getSize() {
		return 2;
	}
	
	/**
	 * Returns the byte representation of the variable in little Endian.
	 */
	public short[] toBytes() {
		short[] result = new short[getSize()];
		result[0] = (short)(getString() & 0xff);
		result[1] = (short)(getString() >> 8 & 0xff);
		return result;
	}
	
	public short getType() {
		return AGILLA_TYPE_STRING;
	}
	
	public boolean matches(AgillaStackVariable v) {
		if (v instanceof AgillaString) {
			AgillaString an = (AgillaString)v;
			return an.getString()==getString();
		} else return false;
	}
	
	private char int2char(int i) {
		switch(i) {
			case 1:
				return 'a';
			case 2:
				return 'b';
			case 3:
				return 'c';
			case 4:
				return 'd';
			case 5:
				return 'e';
			case 6:
				return 'f';
			case 7:
				return 'g';
			case 8:
				return 'h';
			case 9:
				return 'i';
			case 10:
				return 'j';
			case 11:
				return 'k';
			case 12:
				return 'l';
			case 13:
				return 'm';
			case 14:
				return 'n';
			case 15:
				return 'o';
			case 16:
				return 'p';
			case 17:
				return 'q';
			case 18:
				return 'r';
			case 19:
				return 's';
			case 20:
				return 't';
			case 21:
				return 'u';
			case 22:
				return 'v';
			case 23:
				return 'w';
			case 24:
				return 'x';
			case 25:
				return 'y';
			case 26:
				return 'z';
			case 27:
				return '0';
			case 28:
				return '1';
			case 29:
				return '2';
			case 30:
				return '3';
			case 31:
				return '4';
			case 32:
				return '5';
			case 33:
				return '6';
			case 34:
				return '7';
			case 35:
				return '8';
			default:
				return '9';
		}
	}
	
	/**
	 * Translates an AgillaString into an ASCII string.
	 * 
	 * @return The ASCII string representation of this AgillaString.
	 */
	public String toChars() {
		int int1 = string >> 11,
			int2 = (string >> 6) & 0x1f,
			int3 = string & 0x3f;
		return "" + int2char(int1) + int2char(int2) + int2char(int3);
	}
	
	public AgillaValue xor(AgillaString key) {
		return new AgillaValue((short)(string ^ key.getString()));
	}
	
	public boolean equals(Object v) {
		if (v instanceof AgillaString) {
			AgillaString as = (AgillaString)v;
			return as.string == string;
		} else
			return false;
	}
	
	public String toString() {
		return "[string: " + string + " = " + toChars() + "]";
	}
}

