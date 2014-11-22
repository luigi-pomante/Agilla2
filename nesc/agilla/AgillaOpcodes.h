// $Id: AgillaOpcodes.h,v 1.17 2006/05/06 00:26:57 chien-liang Exp $

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
 * INFRINGEMENT OF THIRD PARTY PATENT, CIOPYRIGHT, OR OTHER
 * PRIOPRIETARY RIGHTS.	THERE ARE NO WARRANTIES THAT SOFTWARE IS
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

/*					tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University	of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.	THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*					tab:4
 *	IMPORTANT: READ BEFORE DOWNLOADING, CIOPYING, INSTALLING OR USING.	By
 *	downloading, copying, installing or using the software you agree to
 *	this license.	If you do not agree to this license, do not download,
 *	install, copy or use the software.
 *
 *	Intel Open Source License
 *
 *	Copyright (c) 2002 Intel Corporation
 *	All rights reserved.
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are
 *	met:
 *
 *	Redistributions of source code must retain the above copyright
 *	notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *	notice, this list of conditions and the following disclaimer in the
 *	documentation and/or other materials provided with the distribution.
 *		Neither the name of the Intel Corporation nor the names of its
 *	contributors may be used to endorse or promote products derived from
 *	this software without specific prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE CIOPYRIGHT HOLDERS AND CONTRIBUTORS
 *	``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *	PARTICULAR PURPOSE ARE DISCLAIMED.	IN NO EVENT SHALL THE INTEL OR ITS
 *	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

/**
 * Authors:	 Neil Patel
 * History:	 created 6/20/2003
 */

/**
 * @author Neil Patel
 * @author Chien-Liang Fok
 */


#ifndef AGILLA_CONSTANTS_H_INCLUDED
#define AGILLA_CONSTANTS_H_INCLUDED

typedef enum {

/* B-class instructions */

	// zero operand instructions
	IOPhalt = 0x00,
	IOPaddr = 0x01,
	IOPaid = 0x02,
	IOPrand = 0x03,
	IOPcpush = 0x04,
	IOPloc = 0x05,
	IOPvicinity = 0x06,
	IOPclear = 0x07,
	IOPnumnbrs = 0x08,
	IOPrandnbr = 0x09,
	IOPwait = 0x0a,

	// One operand instructions
	IOPinc = 0x0b,
	IOPclearvar = 0x0c,
	IOPinv = 0x0d,
	IOPnot = 0x0e,
	IOPlnot = 0x0f,
	IOPcopy = 0x10,
	IOPpop = 0x11,
	IOPcpull = 0x12,
	IOPsleep = 0x13,
	IOPjumpc = 0x14,
	IOPjumps = 0x15,
	IOPputled = 0x16,
	IOPsmove = 0x17,
	IOPwmove = 0x18,
	IOPsclone = 0x19,
	IOPwclone = 0x1a,
	IOPgetvars = 0x1b,
	IOPsetvars = 0x1c,
	IOPgetnbr = 0x1d,
	IOPcisnbr = 0x1e,
	IOPsense = 0x1f,
	IOPdec = 0x20,

	// Two and three operand-instructions
	IOPdist = 0x21,
	IOPswap = 0x22,
	IOPland = 0x23,
	IOPlor = 0x24,
	IOPand = 0x25,
	IOPor = 0x26,
	IOPmul = 0x27,
	IOPdiv = 0x28,
	IOPadd = 0x29,
	IOPmod = 0x2a,
	IOPceq = 0x2b, // LSB = 1
	IOPcneq = 0x2c, // LSB = 0
	IOPclt = 0x2d,
	IOPcgt = 0x2e,
	IOPclte = 0x2f,
	IOPcgte = 0x30,
	IOPceqtype = 0x31,
	IOPcistype = 0x32,

	IOPout = 0x33,
	IOPinp = 0x34,
	IOPrdp = 0x35,
	IOPin = 0x36,
	IOPrd = 0x37,
	IOPendrxn = 0x38,

	IOProut = 0x39,
	IOPrinp = 0x3a,
	IOPrrdp = 0x3b,
	IOProutg = 0x3c,
	IOPrrdpg = 0x3d,
	IOPregrxn = 0x3e,
	IOPderegrxn = 0x3f,

/*	T class	Instruction format: 0100 ixxx*/
	IOPpushrt = 0x40,
	IOPpusht = 0x48,

/*	 E-Class Instruction, format: 0101 ixxx yyyy yyyy yyyy yyyy]*/
	IOPpushn = 0x50,
	IOPpushcl = 0x51,
	IOPpushloc = 0x52,

	IOPextend1 = 0x53, // put the mote into extended ISA 1
	IOPextend2 = 0x54, // put the mote into extended ISA 2
	IOPextend3 = 0x55, // put the mote into extended ISA 3
	IOPextend4 = 0x56, // put the mote into extended ISA 4
	IOPextend5 = 0x57, // put the mote into extended ISA 5
	IOPextend6 = 0x58, // put the mote into extended ISA 6
	IOPextend7 = 0x59, // put the mote into extended ISA 7
	IOPextend8 = 0x5a, // put the mote into extended ISA 8
	IOPextend9 = 0x5b, // put the mote into extended ISA 9
	IOPextend10 = 0x5c, // put the mote into extended ISA 10
	IOPextend11 = 0x5d, // put the mote into extended ISA 11
	IOPextend12 = 0x5e, // put the mote into extended ISA 12
	IOPextend13 = 0x5f, // put the mote into extended ISA 13

/*	 V-Class Instruction, format:	011i xxxx */
	IOPgetvar = 0x60,	// 5th bit must = 1
	IOPsetvar = 0x70,	// 5th bit must = 0

/*	 J class	 Instruction format:	10ix xxxx */
	IOPrjumpc = 0x80,	// 100x xxxx conditional relative jump
	IOPrjump = 0xa0,	// 101x xxxx unconditional relative jump

/*	 xclass	 Instruction format:	11xx xxxx*/
	IOPpushc = 0xc0	 // push a constant onto op stack
} BasicInstruction;

typedef enum {
	IOPshiftr = 0x00,
	IOPshiftl = 0x01,
	IOPdepth = 0x02,
	IOPerr = 0x03,
	IOPtcount = 0x04,
	IOProutgs = 0x05,
	IOPremove = 0x06,
	IOPhid = 0x07,
	IOPlocToValue = 0x08,
	IOPrrdpgs = 0x09,
	IOPsub = 0x0a,

	IOPgetAgents = 0x10,
	IOPgetLocation = 0x11,
	IOPgetNumAgents = 0x12,
	IOPgetClosestAgent = 0x13,

	IOPtoAgentID = 0x14,

	IOPsetdesc = 0x1a,
	IOPgetdesc = 0x1b,
	
	IOPfindMatch = 0x1c,

	IOPbattery = 0x1d,
	IOPclearts = 0x1e,
	IOPmorse = 0x1f,

	IOPegetvar = 0x80,	// 10xx xxxx 
	IOPesetvar = 0xc0,	// 11xx xxxx

} ExtendedISA1;

#endif
