// $Id: Argument.java,v 1.2 2005/12/08 23:09:38 chien-liang Exp $

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
package agilla;

/**
 * An instruction's argument (parameter).  Some instructions have one
 * argument, others have two.  This class handles both cases.  
 * 
 * <p>When the instruction only has a one parameter, arg1 is used.
 *
 * @author Chien-Liang Fok
 */
public class Argument
{
	private String arg1, arg2;
	
	/**
	 * A one-argument constructor.
	 * 
	 * @param arg1 argument 1.
	 */
	public Argument(String arg1) {
		this.arg1 = arg1;
	}
	
	/**
	 * A two-argument constructor.
	 * 
	 * @param arg1 argument one.
	 * @param arg2 argument two.
	 */
	public Argument(String arg1, String arg2) {
		this(arg1);
		this.arg2 = arg2;
	}
	
	/**
	 * An accessor to argument 1.
	 * 
	 * @return argument 1.
	 */
	public String arg1() {
		return arg1;
	}
	
	/**
	 * An accessor to argument 2.
	 * 
	 * @return argument 2.
	 */
	public String arg2() {
		return arg2;
	}
	
	/**
	 * Returns a String representation of this class.
	 * 
	 * @param return a String representation of this class.
	 */
	public String toString() {
		return arg1 + " " + arg2;
	}
}

