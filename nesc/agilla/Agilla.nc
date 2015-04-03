// $Id: Agilla.nc,v 1.23 2006/05/06 00:26:57 chien-liang Exp $

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
 * PROPRIETARY RIGHTS.	THERE ARE NO WARRANTIES THAT SOFTWARE IS
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

/*
 * "Copyright (c) 2002 and The Regents of the University
 * of California.	All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.	THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	 Philip Levis
 *				Neil Patel
 * Date last modified:	9/10/02
 *
 */

/**
 * @author Philip Levis
 * @author Neil Patel
 * @author Chien-Liang Fok
 */

#include "Agilla.h"
#include "AgillaOpcodes.h"

configuration Agilla {}
implementation
{
	components MainC, AgillaEngineC;

	// B-Class instructions: zero operand instructions
	components OPhalt, OPaddr, OPaid, OPrand, OPcpush;
	components OPcistype,	OPloc, /*OPvicinity,*/ OPclear, OPnumnbrs;
	components OPrandnbr;
	components OPwait;

	// One operand instructions
	components OPinc;
	components OPnot, OPcopy, OPpop, OPcpull, OPsleep;
	components OPjump, OPputled, OPmove, OPgetsetvars;
	components OPdec;

	#if !ENABLE_CLUSTERING
	components OPclearvar, OPcisnbr, OPinv, OPgetnbr;
	
	#if ENABLE_MTS310
		components OPsenseMTS310CAC as OPsense;
	#else
		#if ENABLE_MDA100
			// Sensor board MDA100
			components OPsenseMDA100C as OPsense;
		#else
		components OPsenseDummyC as OPsense;
		#endif
	#endif
	//

	// Two and three operand-instructions
	components OPdist, OPswap, OPlogical, OPmul, OPdiv, OPadd;
	components OPmod, OPceqtype;
	#endif
	components	OPts, OPcompare;

	#if !ENABLE_CLUSTERING
		components OPrts, OPrxn;
	#endif

	// T-class instructions
	components OPpusht;

	// E-Class instructions
	components OPpushn, OPpushcl, OPpushloc;

	// V-Class instructions
	components OPgetsetvar4;

	// J-Class instructions
	components OPrjump5;

	// X-Class instructions
	components OPpushc6;

	#if OPBATTERY
		// Battery monitor instruction
		components OPbatteryC;
	#endif

	#if OPCLEARTS
		// Tuplespace cleaning instruction
		components OPcleartsC;
	#endif

	#if OPMORSE
		// Morse istruction (modded MDA100 sensorboard only)
		components OPmorseC;
	#endif

	#if CHECKVOICE
		components OPcheckvoiceC;
	#endif

	/**	 Extended ISA 1 **/
	#if !ENABLE_CLUSTERING
		components OPshift, OPdepth, OPerr, OPhid;
		components OPlocToValue;
		components OPegetsetvar6, OPsub;
	#endif

	components OPdesc;
	components OPgetlocation, OPgetNumAgents, OPgetAgents, OPgetClosestAgent;
	components OPfindMatch;
	
	#if ENABLE_DELUGE
		components DelugeC;
		Main.StdControl -> DelugeC;
	#endif

	components ActiveMessageC, SerialActiveMessageC, BootRadioSerial as BRS;

	BRS.Boot -> MainC;
	BRS.RadioAMControl -> ActiveMessageC;
	BRS.SerialAMControl -> SerialActiveMessageC;	 

 // Main.StdControl -> AgillaEngineC; 
	MainC.SoftwareInit -> AgillaEngineC.Init;
	
	components AgentMgrM;
	AgentMgrM.Boot -> MainC;

	components TimeSyncM;
	TimeSyncM.Boot -> MainC;
 
	

	// B-Class instructions
	// zero operand instructions
	AgillaEngineC.BasicISA[IOPhalt] -> OPhalt;
	AgillaEngineC.BasicISA[IOPaddr] -> OPaddr;
	AgillaEngineC.BasicISA[IOPaid] -> OPaid;
	AgillaEngineC.BasicISA[IOPrand] -> OPrand;
	AgillaEngineC.BasicISA[IOPcpush] -> OPcpush;
	AgillaEngineC.BasicISA[IOPloc] -> OPloc;
	AgillaEngineC.BasicISA[IOPcistype] -> OPcistype;
	//AgillaEngineC.BasicISA[IOPvicinity] -> OPvicinity;
	AgillaEngineC.BasicISA[IOPclear] -> OPclear;
	AgillaEngineC.BasicISA[IOPnumnbrs] -> OPnumnbrs;
	AgillaEngineC.BasicISA[IOPrandnbr] -> OPrandnbr;

	AgillaEngineC.BasicISA[IOPwait] -> OPwait;

	// One operand instructions
	AgillaEngineC.BasicISA[IOPinc] -> OPinc;
	AgillaEngineC.BasicISA[IOPnot]	-> OPnot;
	AgillaEngineC.BasicISA[IOPlnot] -> OPnot;
	AgillaEngineC.BasicISA[IOPcopy] -> OPcopy;
	AgillaEngineC.BasicISA[IOPpop] -> OPpop;
	AgillaEngineC.BasicISA[IOPcpull] -> OPcpull;
	AgillaEngineC.BasicISA[IOPsleep] -> OPsleep;
	AgillaEngineC.BasicISA[IOPjumps] -> OPjump;	 // 16-bit hard jumps
	AgillaEngineC.BasicISA[IOPjumpc] -> OPjump;
	AgillaEngineC.BasicISA[IOPputled] -> OPputled;
	AgillaEngineC.BasicISA[IOPsmove]	-> OPmove;
	AgillaEngineC.BasicISA[IOPwmove]	-> OPmove;
	AgillaEngineC.BasicISA[IOPsclone] -> OPmove;
	AgillaEngineC.BasicISA[IOPwclone] -> OPmove;
	AgillaEngineC.BasicISA[IOPgetvars] -> OPgetsetvars;
	AgillaEngineC.BasicISA[IOPsetvars] -> OPgetsetvars;
	AgillaEngineC.BasicISA[IOPdec] -> OPdec;

	#if !ENABLE_CLUSTERING
	AgillaEngineC.BasicISA[IOPclearvar] -> OPclearvar;
	AgillaEngineC.BasicISA[IOPcisnbr] -> OPcisnbr;
	AgillaEngineC.BasicISA[IOPinv] -> OPinv;
	AgillaEngineC.BasicISA[IOPsense] -> OPsense;
	AgillaEngineC.BasicISA[IOPgetnbr] -> OPgetnbr;
	#endif

	#if !ENABLE_CLUSTERING
	// Two and three operand-instructions
	AgillaEngineC.BasicISA[IOPdist] -> OPdist;
	AgillaEngineC.BasicISA[IOPswap] -> OPswap;
	AgillaEngineC.BasicISA[IOPland] -> OPlogical;
	AgillaEngineC.BasicISA[IOPlor]	-> OPlogical;
	AgillaEngineC.BasicISA[IOPand]	-> OPlogical;
	AgillaEngineC.BasicISA[IOPor]	 -> OPlogical;
	AgillaEngineC.BasicISA[IOPmul] -> OPmul;
	AgillaEngineC.BasicISA[IOPdiv] -> OPdiv;
	AgillaEngineC.BasicISA[IOPadd] -> OPadd;
	AgillaEngineC.BasicISA[IOPmod] -> OPmod;
	AgillaEngineC.BasicISA[IOPceqtype] -> OPceqtype;
	#endif
	AgillaEngineC.BasicISA[IOPout]	-> OPts;	 // local TS Ops
	AgillaEngineC.BasicISA[IOPinp]	-> OPts;
	AgillaEngineC.BasicISA[IOPrdp]	-> OPts;
	AgillaEngineC.BasicISA[IOPin]	 -> OPts;
	AgillaEngineC.BasicISA[IOPrd]	 -> OPts;

	#if !ENABLE_CLUSTERING
	AgillaEngineC.BasicISA[IOPendrxn] -> OPrxn;
	AgillaEngineC.BasicISA[IOProut]	-> OPrts;	// remote TS Ops
	AgillaEngineC.BasicISA[IOPrinp]	-> OPrts;
	AgillaEngineC.BasicISA[IOPrrdp]	-> OPrts;
	AgillaEngineC.BasicISA[IOPrrdpg]	-> OPrts;
	AgillaEngineC.BasicISA[IOProutg]	-> OPrts;
	AgillaEngineC.BasicISA[IOPregrxn]	 -> OPrxn;
	AgillaEngineC.BasicISA[IOPderegrxn] -> OPrxn;
	#endif
	AgillaEngineC.BasicISA[IOPceq]	-> OPcompare;
	AgillaEngineC.BasicISA[IOPclt]	-> OPcompare;
	AgillaEngineC.BasicISA[IOPcgt]	-> OPcompare;
	AgillaEngineC.BasicISA[IOPclte] -> OPcompare;
	AgillaEngineC.BasicISA[IOPcgte] -> OPcompare;
	AgillaEngineC.BasicISA[IOPcneq] -> OPcompare;

	// T-Class instructions
	AgillaEngineC.BasicISA[IOPpushrt]	 -> OPpusht; // 0x41
	AgillaEngineC.BasicISA[IOPpushrt+1] -> OPpusht;
	AgillaEngineC.BasicISA[IOPpushrt+2] -> OPpusht;
	AgillaEngineC.BasicISA[IOPpushrt+3] -> OPpusht;
	AgillaEngineC.BasicISA[IOPpushrt+4] -> OPpusht;
	AgillaEngineC.BasicISA[IOPpushrt+5] -> OPpusht;
	AgillaEngineC.BasicISA[IOPpushrt+6] -> OPpusht;
	AgillaEngineC.BasicISA[IOPpushrt+7] -> OPpusht;
	AgillaEngineC.BasicISA[IOPpusht]	-> OPpusht; // 0x48
	AgillaEngineC.BasicISA[IOPpusht+1]	-> OPpusht;
	AgillaEngineC.BasicISA[IOPpusht+2]	-> OPpusht;
	AgillaEngineC.BasicISA[IOPpusht+3]	-> OPpusht;
	AgillaEngineC.BasicISA[IOPpusht+4]	-> OPpusht;
	AgillaEngineC.BasicISA[IOPpusht+5]	-> OPpusht;
	AgillaEngineC.BasicISA[IOPpusht+6]	-> OPpusht;



	// E-Class instructions
	AgillaEngineC.BasicISA[IOPpushn] -> OPpushn;
	AgillaEngineC.BasicISA[IOPpushcl] -> OPpushcl;
	AgillaEngineC.BasicISA[IOPpushloc] -> OPpushloc;

	// V-Class instructions
	AgillaEngineC.BasicISA[IOPgetvar]	 -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+1] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+2] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+3] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+4] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+5] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+6] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+7] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+8] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+9] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+10] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+11] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+12] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+13] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+14] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPgetvar+15] -> OPgetsetvar4;

	AgillaEngineC.BasicISA[IOPsetvar]	 -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+1] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+2] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+3] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+4] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+5] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+6] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+7] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+8] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+9] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+10] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+11] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+12] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+13] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+14] -> OPgetsetvar4;
	AgillaEngineC.BasicISA[IOPsetvar+15] -> OPgetsetvar4;

	// J Class instructions
	AgillaEngineC.BasicISA[IOPrjumpc] -> OPrjump5;		// 100 00000
	AgillaEngineC.BasicISA[IOPrjumpc+1] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+2] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+3] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+4] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+5] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+6] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+7] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+8] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+9] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+10] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+11] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+12] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+13] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+14] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+15] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+16] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+17] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+18] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+19] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+20] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+21] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+22] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+23] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+24] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+25] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+26] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+27] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+28] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+29] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+30] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjumpc+31] -> OPrjump5;		 // 100 11111

	AgillaEngineC.BasicISA[IOPrjump] -> OPrjump5;			// 101 xxxxx
	AgillaEngineC.BasicISA[IOPrjump+1] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+2] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+3] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+4] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+5] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+6] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+7] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+8] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+9] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+10] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+11] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+12] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+13] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+14] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+15] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+16] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+17] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+18] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+19] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+20] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+21] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+22] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+23] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+24] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+25] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+26] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+27] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+28] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+29] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+30] -> OPrjump5;
	AgillaEngineC.BasicISA[IOPrjump+31] -> OPrjump5;

	// x class instructions
	AgillaEngineC.BasicISA[IOPpushc] -> OPpushc6;		 // OPpushc = 0xc0 =11 000000
	AgillaEngineC.BasicISA[IOPpushc+1] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+2] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+3] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+4] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+5] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+6] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+7] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+8] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+9] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+10] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+11] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+12] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+13] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+14] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+15] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+16] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+17] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+18] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+19] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+20] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+21] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+22] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+23] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+24] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+25] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+26] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+27] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+28] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+29] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+30] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+31] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+32] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+33] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+34] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+35] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+36] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+37] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+38] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+39] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+40] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+41] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+42] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+43] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+44] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+45] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+46] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+47] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+48] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+49] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+50] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+51] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+52] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+53] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+54] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+55] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+56] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+57] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+58] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+59] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+60] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+61] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+62] -> OPpushc6;
	AgillaEngineC.BasicISA[IOPpushc+63] -> OPpushc6;

	#if !ENABLE_CLUSTERING
	AgillaEngineC.ExtendedISA1[IOPshiftr] -> OPshift;
	AgillaEngineC.ExtendedISA1[IOPshiftl] -> OPshift;
	AgillaEngineC.ExtendedISA1[IOPdepth] -> OPdepth;
	AgillaEngineC.ExtendedISA1[IOPerr] -> OPerr;
	AgillaEngineC.ExtendedISA1[IOPtcount] -> OPts;
	AgillaEngineC.ExtendedISA1[IOProutgs] -> OPrts;
	AgillaEngineC.ExtendedISA1[IOPremove] -> OPts;
	AgillaEngineC.ExtendedISA1[IOPhid] -> OPhid;
	AgillaEngineC.ExtendedISA1[IOPlocToValue] -> OPlocToValue;
	AgillaEngineC.ExtendedISA1[IOPrrdpgs] -> OPrts;
	AgillaEngineC.ExtendedISA1[IOPsub] -> OPsub;
	#endif

	AgillaEngineC.ExtendedISA1[IOPgetAgents] -> OPgetAgents;
	AgillaEngineC.ExtendedISA1[IOPgetLocation] -> OPgetlocation;
	AgillaEngineC.ExtendedISA1[IOPgetNumAgents] -> OPgetNumAgents;
	AgillaEngineC.ExtendedISA1[IOPgetClosestAgent] -> OPgetClosestAgent;

	AgillaEngineC.ExtendedISA1[IOPsetdesc] -> OPdesc;
	AgillaEngineC.ExtendedISA1[IOPgetdesc] -> OPdesc;
	
	AgillaEngineC.ExtendedISA1[IOPfindMatch] -> OPfindMatch;

	#if OPBATTERY
		AgillaEngineC.ExtendedISA1[IOPbattery] -> OPbatteryC;
	#endif

	#if OPCLEARTS
		AgillaEngineC.ExtendedISA1[IOPclearts] -> OPcleartsC;
	#endif

	#if OPMORSE
		AgillaEngineC.ExtendedISA1[IOPmorse] -> OPmorseC;
	#endif

	#if CHECKVOICE
		AgillaEngineC.ExtendedISA1[IOPcheckvoice] -> OPcheckvoiceC;
	#endif



	#if !ENABLE_CLUSTERING
	AgillaEngineC.ExtendedISA1[IOPegetvar] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+1] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+2] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+3] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+4] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+5] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+6] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+7] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+8] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+9] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+10] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+11] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+12] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+13] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+14] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+15] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+16] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+17] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+18] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+19] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+20] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+21] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+22] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+23] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+24] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+25] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+26] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+27] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+28] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+29] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+30] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+31] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+32] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+33] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+34] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+35] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+36] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+37] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+38] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+39] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+40] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+41] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+42] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+43] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+44] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+45] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+46] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+47] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+48] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+49] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+50] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+51] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+52] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+53] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+54] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+55] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+56] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+57] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+58] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+59] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+60] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+61] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+62] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPegetvar+63] -> OPegetsetvar6;

	AgillaEngineC.ExtendedISA1[IOPesetvar] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+1] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+2] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+3] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+4] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+5] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+6] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+7] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+8] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+9] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+10] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+11] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+12] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+13] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+14] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+15] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+16] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+17] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+18] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+19] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+20] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+21] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+22] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+23] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+24] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+25] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+26] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+27] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+28] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+29] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+30] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+31] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+32] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+33] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+34] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+35] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+36] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+37] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+38] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+39] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+40] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+41] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+42] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+43] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+44] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+45] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+46] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+47] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+48] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+49] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+50] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+51] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+52] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+53] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+54] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+55] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+56] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+57] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+58] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+59] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+60] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+61] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+62] -> OPegetsetvar6;
	AgillaEngineC.ExtendedISA1[IOPesetvar+63] -> OPegetsetvar6;
	#endif
}

