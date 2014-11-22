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

public interface BasicOpcodes
{
	/* B-class instructions (no embedded operands)*/

  // zero operand instructions
	public static final byte OPhalt      = 0x00;
	public static final byte OPaddr      = 0x01;
	public static final byte OPaid       = 0x02;
	public static final byte OPrand      = 0x03;
	public static final byte OPcpush     = 0x04;
	public static final byte OPloc       = 0x05;
	public static final byte OPvicinity  = 0x06;
	public static final byte OPclear     = 0x07;
	public static final byte OPnumnbrs   = 0x08;
	public static final byte OPrandnbr   = 0x09;
	public static final byte OPwait      = 0x0a;

  // One operand instructions
	public static final byte OPinc       = 0x0b;
	public static final byte OPclearvar  = 0x0c;
	public static final byte OPinv       = 0x0d;
	public static final byte OPnot       = 0x0e;
	public static final byte OPlnot      = 0x0f;
	public static final byte OPcopy      = 0x10;
	public static final byte OPpop       = 0x11;
	public static final byte OPcpull     = 0x12;
	public static final byte OPsleep     = 0x13;
	public static final byte OPjumpc     = 0x14;
	public static final byte OPjumps     = 0x15;
	public static final byte OPputled    = 0x16;
	public static final byte OPsmove     = 0x17;
	public static final byte OPwmove     = 0x18;
	public static final byte OPsclone    = 0x19;
	public static final byte OPwclone    = 0x1a;
	public static final byte OPgetvars   = 0x1b;
	public static final byte OPsetvars   = 0x1c;
	public static final byte OPgetnbr    = 0x1d;
	public static final byte OPcisnbr    = 0x1e;
	public static final byte OPsense     = 0x1f;
	public static final byte OPdec       = 0x20;

  // Two and three operand-instructions
	public static final byte OPdist      = 0x21;
	public static final byte OPswap      = 0x22;
	public static final byte OPland      = 0x23;
	public static final byte OPlor       = 0x24;
	public static final byte OPand       = 0x25;
	public static final byte OPor        = 0x26;
	public static final byte OPmul       = 0x27;
	public static final byte OPdiv       = 0x28;
	public static final byte OPadd       = 0x29;
	public static final byte OPmod       = 0x2a;
	public static final byte OPceq       = 0x2b;
	public static final byte OPcneq      = 0x2c;
	public static final byte OPclt       = 0x2d;
	public static final byte OPcgt       = 0x2e;
	public static final byte OPclte      = 0x2f;
	public static final byte OPcgte      = 0x30;
	public static final byte OPceqtype   = 0x31;
	public static final byte OPcistype   = 0x32;

	public static final byte OPout       = 0x33;
	public static final byte OPinp       = 0x34;
	public static final byte OPrdp       = 0x35;
	public static final byte OPin        = 0x36;
	public static final byte OPrd        = 0x37;
	public static final byte OPendrxn    = 0x38;

	public static final byte OProut      = 0x39;
	public static final byte OPrinp      = 0x3a;
	public static final byte OPrrdp      = 0x3b;
	public static final byte OProutg     = 0x3c;
	public static final byte OPrrdpg     = 0x3d;
	public static final byte OPregrxn      = 0x3e;
	public static final byte OPderegrxn    = 0x3f;


/*  T class  Instruction format: 0100 ixxx*/
	public static final String[] ClassT = new String[]{"pushrt", "pusht"};
	
	public static final byte OPpushrt    = 0x40;
	public static final int ArgNumOPpushrt = 1;							// the number of arguments, default 0
	public static final int ArgNumBitsOPpushrt = 3;						// the number of bits in an embedded operand (only used when ArgSize = 0)
	//public static final int ArgSizeOPpushrt = 0;  					// the number of additional bytes consumed by the argument 
	//public static final String ArgTypeOPpushrt = "value"; 			// the argument's type
	public static final String[][] ArgValOPpushrt = new String[][] { 	// possible string values of the argument and their byte values
		{"photo", "1"},
		{"temp", "2"},
		{"temperature", "2"},
		{"mic", "3"},
		{"microphone", "3"},
		{"magx", "4"},
		{"magnetometerx", "4"},
		{"magy", "5"},
		{"magnetometery", "5"},
		{"accelx", "6"},
		{"accelerometerx", "6"},
		{"accely", "7"},
		{"accelerometery", "7"}
	};
	
	public static final byte OPpusht     = 0x48;
	public static final int ArgNumOPpusht = 1;
	public static final int ArgNumBitsOPpusht = 3;
	//public static final int ArgSizeOPpusht = 0;
	//public static final String ArgTypeOPpusht = "value";
	public static final String[][] ArgValOPpusht = new String[][] {
		{"any", "0"},
		{"agentid", "1"},
		{"string", "2"},
		{"type", "3"},
		{"value", "4"},
		{"location", "5"}
	};

/*   E-Class Instruction; format: 0101 ixxx yyyy yyyy yyyy yyyy]*/
	public static final String[] ClassE = new String[]{"pushn", "pushcl", "pushloc"};
	
	public static final byte OPpushn     = 0x50;
	public static final int ArgNumOPpushn = 1;				// the number of arguments
	public static final int ArgSizeOPpushn = 2;				// the number of add'n bytes consumed
	public static final String ArgTypeOPpushn = "string"; 	// the argument's type (default value)
		
	public static final byte OPpushcl    = 0x51;
	public static final int ArgNumOPpushcl = 1;				// the number of arguments
	public static final int ArgSizeOPpushcl = 2;			// the number of add'n bytes consumed
	//public static final String ArgTypeOPpushcl = "value";
	public static final String[][] ArgValOPpushcl = new String[][] {
		{"uart", "126"}
	};
	
	public static final byte OPpushloc   = 0x52;
	public static final int ArgNumOPpushloc = 2;
	public static final int ArgSizeOPpushloc = 2;
	public static final String[][] ArgValOPpushloc = new String[][] {
		{"uart_x", "0"},
		{"uart_y", "1"}
	};
	
	// NOTE: 0x53 through 0x5F are reserved for extended ISA
	public static final byte OPextend1   = 0x53;
	public static final byte OPextend2   = 0x54;
	public static final byte OPextend3   = 0x55;
	public static final byte OPextend4   = 0x56;
	public static final byte OPextend5   = 0x57;
	public static final byte OPextend6   = 0x58;
	public static final byte OPextend7   = 0x59;
	public static final byte OPextend8   = 0x5a;
	public static final byte OPextend9   = 0x5b;
	public static final byte OPextend10  = 0x5c;
	public static final byte OPextend11  = 0x5d;
	public static final byte OPextend12  = 0x5e;
	public static final byte OPextend13  = 0x5f;

/*   V-Class Instruction; format:  011i xxxx */
	public static final String[] ClassV = new String[]{"getvar", "setvar"};
	public static final byte OPgetvar    = 0x60;  // 5th bit must = 1
	public static final int ArgNumOPgetvar = 1;
	public static final int ArgNumBitsOPgetvar = 4;
	
	public static final byte OPsetvar    = 0x70;  // 5th bit must = 0
	public static final int ArgNumOPsetvar = 1;
	public static final int ArgNumBitsOPsetvar = 4;

/*   J class   Instruction format:  10ix xxxx */
	public static final String[] ClassJ = new String[]{"rjumpc", "rjump"};
	
	public static final short OPrjumpc    = 0x80;  		// 100x xxxx conditional relative jump
	public static final int ArgNumOPrjumpc = 1;			// number of arguments
	public static final boolean ArgRelAddrOPrjumpc = true;  	// number of bits in relative address
	public static final int ArgNumBitsOPrjumpc = 5;
	
	public static final short OPrjump     = 0xa0;  		// 101x xxxx unconditional relative jump
	public static final int ArgNumOPrjump = 1;			// number of arguments
	public static final boolean ArgRelAddrOPrjump = true; 		// number of bits in relative address
	public static final int ArgNumBitsOPrjump = 5;

/*   xclass   Instruction format:  11xx xxxx*/
	public static final String[] ClassX = new String[] {"pushc"};
	
	public static final short OPpushc     = 0xc0;   // push a constant onto op stack
	public static final int ArgNumOPpushc = 1;
	public static final int ArgNumBitsOPpushc = 6;
	public static final String[][] ArgValOPpushc = new String[][] {
		{"temperature", "1"},
		{"temp", "1"},
		{"photo", "2"},
		{"mic", "3"},
		{"microphone", "3"},
		{"magx", "4"},
		{"magnetometerx", "4"},
		{"magy", "5"},
		{"magnetometery", "5"},
		{"accelx", "6"},
		{"accelerometerx", "6"},
		{"accely", "7"},
		{"accelerometery", "7"},
		
		// the following are for changing an agent's description
		{"unknown", "3"},
		{"unspecified","0"},
		{"cargo","1"},
		{"fire","2"}
	};
}

