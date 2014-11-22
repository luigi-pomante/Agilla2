// $Id: OpStack.java,v 1.2 2005/11/17 15:37:35 chien-liang Exp $

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
 * OpStack.java
 *
 * @author Chien-Liang Fok
 */

package agilla;

import java.util.*;

import agilla.messages.*;

public class OpStack implements AgillaConstants, java.io.Serializable {
	static final long serialVersionUID = 6333906346705810964L;
	private Vector os = new Vector();
	
	public OpStack() {
	}
	
	public OpStack(AgillaOpStackMsg [] blocks, short sp) {
		short [] stack = new short[sp];
		final int blockSize = AgillaOpStackMsg.numElements_data();
		
		for(int i = 0; i < sp; i++)
		{
			int blockNum = i / blockSize;
			int offset = i % blockSize;
			stack[i] = blocks[blockNum].getElement_data(offset);
		}
		
		while(sp > 0)
		{
			sp--;
			AgillaStackVariable v = VarUtil.pop(sp, stack);
			os.add(v);
			sp -= v.getSize();
		}
	}
	
	public OpStack deepClone() {
		OpStack nos = new OpStack();
		for (int i = 0; i < os.size(); i++) {
			try {
				nos.add(get(i).deepClone());
			} catch(Exception e) {
				e.printStackTrace();
			}
		}
		return nos;
	}
	
	
	/**
	 *  Returns this op stack represented as a byte array for storing in
	 *  opstack messages.
	 *  
	 * @return This op stack represented as a byte array. 
	 */
	public byte[] toByteArray() {
		byte[] result = new byte[sizeInBytes()];
		int pos = 0;
		for (int i = size()-1; i >= 0; i--) {
			try {				
				byte[] b = VarUtil.toStackBytes(get(i));
				System.arraycopy(b, 0, result, pos, b.length);
				pos += b.length;
			} catch (OpStackException e) {
				e.printStackTrace();
			}
		}		
		return result;
	}
	
	public void push(AgillaStackVariable v) throws OpStackException {
		if (os.size() > AGILLA_OPDEPTH)
			throw new OpStackException("Overflow");
		else
			os.add(0, v);
	}
	
	/**
	 * Returns the number of elements in the opstack.
	 */
	public short size() {
		return (short)os.size();
	}
	
	/**
	 * Returns the number of bytes the opstack consumes.
	 * @return The number of bytes the opstack consumes.
	 */
	public short sizeInBytes() {
	  short result = 0;
	  for (int i = 0; i < size(); i++) {
		  try {
			  result += (short)(get(i).getSize()+1);
		  } catch (OpStackException e) {
			  e.printStackTrace();
		  }
	  }
	  return result;
	}
	
	/**
	 * Adds a variable to the bottom of the operand stack.
	 */
	public void add(AgillaStackVariable v) throws OpStackException {
		if (os.size() > AGILLA_OPDEPTH)
			throw new OpStackException("Overflow");
		else
			os.add(v);
	}
	
	public void clear() {
		os.clear();
	}
	
	public AgillaStackVariable get(int i) throws OpStackException {
		if (i < 0 || i >= os.size())
			throw new OpStackException("Invalid OpStack Index");
		else
			return (AgillaStackVariable)os.get(i);
	}
	
	public AgillaStackVariable pop() throws OpStackException {
		if (os.size() == 0)
			throw new OpStackException("Underflow.");
		else
			return (AgillaStackVariable)os.remove(0);
	}
	
	public String toString() {
		String result = "";
		if (os.size() == 0)
			result = "[empty]";
		try {
			for (int i = 0; i < os.size(); i++) {
				result += os.get(i);
				if (i < os.size() - 1)
					result += ", ";
			}
		} catch(Exception e) {
			e.printStackTrace();
		}
		return result;
	}
}

