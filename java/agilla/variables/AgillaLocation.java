// $Id: AgillaLocation.java,v 1.4 2006/04/10 04:03:07 chien-liang Exp $

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

public class AgillaLocation implements AgillaConstants, AgillaStackVariable,
	java.io.Serializable
{
	private static final long serialVersionUID = 3356993013462026563L;

	//public static int NUM_ROWS = 5;
	public static int NUM_COLUMNS = agilla.AgillaProperties.numCol();

	private int x,y;

	public AgillaLocation(int addr) {
		if (addr == TOS_UART_ADDRESS) {
			x = UART_X;
			y = UART_Y;
		} else if (addr == TOS_BCAST_ADDRESS) {
			x = BCAST_X;
			y = BCAST_Y;
		}
		else {
			//x = (short)((addr-1) % NUM_COLUMNS + 1);
			//y = (short)((addr-x)/NUM_COLUMNS + 1);
			x = (short)((addr) % NUM_COLUMNS + 1);
			y = (short)((addr-x+1)/NUM_COLUMNS + 1);
		}
	}

	public AgillaLocation(int x, int y) {
		this.x = x;
		this.y = y;
	}

	/**
	 * An AgillaLocation is four bytes.
	 */
	public short getSize() {
		return 4;
	}

	public short[] toBytes() {
		short[] result = new short[getSize()];
		result[0] = (short)(x & 0xff);
		result[1] = (short)(x >> 8 & 0xff);
		result[2] = (short)(y & 0xff);
		result[3] = (short)(y >> 8 & 0xff);
		return result;
	}

	public AgillaStackVariable deepClone() {
		return new AgillaLocation(x,y);
	}

	public short getType() {
		return AGILLA_TYPE_LOCATION;
	}

	public int getx() {
		return x;
	}

	public int gety() {
		return y;
	}

	public int getAddr() {
		if (x == UART_X && y == UART_Y)
			return TOS_UART_ADDRESS;
		else if (x == BCAST_X && y == BCAST_Y)
			return TOS_BCAST_ADDRESS;
		else
			return x + (y-1)*NUM_COLUMNS-1;
	}

	public boolean matches(AgillaStackVariable v) {
		if (v instanceof AgillaLocation) {
			AgillaLocation loc = (AgillaLocation)v;
			return loc.getx() == getx() && loc.gety() == gety();
		} else return false;
	}

	public String toString() {
		return "[location: (" + x + ", " + y + ")]";
	}
	
	public boolean equals(Object other)
	{
		if(!(other instanceof AgillaLocation)) return false;
		AgillaLocation o = (AgillaLocation)other;
		
		return matches(o);
	}
	
	/**
	 *  Calculates the distance between two AgillaLocation coordinates.
	 * @param loc The other location coordinate.
	 * @return The distance to the other location coordinate.
	 */
	public double dist(AgillaLocation loc) {
		return Math.sqrt(Math.pow(x-loc.getx(),2) + Math.pow(y - loc.gety(),2));
	}
}

