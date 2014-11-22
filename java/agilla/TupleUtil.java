// $Id: TupleUtil.java,v 1.1 2005/10/13 17:12:19 chien-liang Exp $

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
 * TupleUtil.java
 *
 * @author Chien-Liang Fok
 */

package agilla;
import agilla.variables.*;

public class TupleUtil implements AgillaConstants {
	public TupleUtil() {}
	
	public static Tuple getTuple(Agent a) throws TupleSpaceException {
		Tuple result = new Tuple();
		try {
			AgillaStackVariable length = a.getOpStack().pop();
			if (length.getType() == AGILLA_TYPE_VALUE) {
				short numFields = ((AgillaValue)length).getValue();
				for (int i = 0; i < numFields; i++) {
					result.addField(a.getOpStack().pop());
				}
			} else {
				Debugger.dbg("Agent[" + a.getID().getID() + ", " + (a.getPC()-1) + "]", "ERROR executing TupleUtil.getTuple(): invalid number of fields: " + result);
				throw new TupleSpaceException("Invalid number of fields.");
			}
		} catch(OpStackException e) {
			e.printStackTrace();
			throw new TupleSpaceException();
		}
		
		return result;
	}
	
	public static void saveTuple(Agent a, Tuple t) throws TupleSpaceException {
		if (t.size() != (short)t.size()) {
			Debugger.dbg("Agent[" + a.getID().getID() + ", " + (a.getPC()-1) + "]", "ERROR executing TupleUtil.saveTuple(): overflow number of fields: " + t.size());
			throw new TupleSpaceException("Invalid number of fields.");
		}
		try {
			int index = t.size()-1;
			while (index >= 0) {
				a.getOpStack().push(t.getField(index--));
			}
			a.getOpStack().push(new AgillaValue((short)t.size()));
		} catch(OpStackException e) {
			e.printStackTrace();
			throw new TupleSpaceException();
		}
	}
}

