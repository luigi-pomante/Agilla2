// $Id$

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
 * AgillaOpCodes.java
 *
 * @author Chien-Liang Fok
 */

package agilla.opcodes;

public interface ExtendedOpcodes1
{
	//public static final String ModeName     = "OPextend1";
	public static final byte OPshiftl      	= 0x00;
	public static final byte OPshiftr   	= 0x01;
	public static final byte OPdepth    	= 0x02;
	public static final byte OPerr     	 	= 0x03;	
	public static final byte OPtcount		= 0x04;
	public static final byte OProutgs		= 0x05;
	public static final byte OPremove		= 0x06;
	public static final byte OPhid			= 0x07;
	public static final byte OPlocToValue	= 0x08;
	public static final byte OPrrdpgs		= 0x09;
	public static final byte OPsub			= 0x0a;
	
	public static final byte OPgetAgents      	 = 0x10;
	public static final byte OPgetAgentLocation  = 0x11;
	public static final byte OPgetNumAgents   	 = 0x12;
	public static final byte OPgetClosestAgent	 = 0x13;
	
	public static final byte OPsetdesc = 0x1a;
	public static final byte OPgetdesc = 0x1b;
	
	public static final short OPfindMatch = 0x1c;

	public static final short OPbattery = 0x1d;
	public static final short OPclearts = 0x1e;
	public static final short OPmorse = 0x1f;
	
	public static final short OPegetvar    = 0x80;  // 7th bit must = 0
	public static final int ArgNumOPegetvar = 1;
	public static final int ArgNumBitsOPegetvar = 6;

	public static final short OPesetvar    = 0xc0;  // 7th bit must = 1
	public static final int ArgNumOPesetvar = 1;
	public static final int ArgNumBitsOPesetvar = 6;	
	
}

