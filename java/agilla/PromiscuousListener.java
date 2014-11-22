// $Id: PromiscuousListener.java,v 1.4 2006/04/27 01:55:04 chien-liang Exp $

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
/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors: Chien-Liang Fok <liang@cse.wustl.edu>
 * Date:        May 2 2005
 * Desc:        Main class for promiscuous message listener
 *
 */
package agilla;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

/**
 * @author Chien-Liang Fok <liang@cse.wustl.edu>
 */
public class PromiscuousListener implements AgillaConstants {
	private MoteIF moteIF = null;
	private PhoenixSource psource;
	private SNInterface sni;
	
	public PromiscuousListener(String source, boolean debug, boolean printBeacons) throws Exception {
		Debugger.debug = debug;
		Debugger.printAllMsgs = true;
		Debugger.printBeacons = printBeacons;
		
		try {
			if (source.startsWith("sf"))
				moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
			else {
				psource = BuildSource.makePhoenix(
					BuildSource.makeArgsSerial(source),
					net.tinyos.util.PrintStreamMessenger.err);
				moteIF = new MoteIF(psource);
			}
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		sni = new SNInterface(true);
		sni.setMoteIF(moteIF);		
	}
	
	public static void main(String[] args) {
		try {
			String source = "COM1:mica2"; //"sf@localhost:9001";
			boolean debug = false;
			boolean printBeacons = false;
			int index = 0;
			
			while (index < args.length) {
				String arg = args[index];
				if (arg.equals("-h") || arg.equals("--help")) {
					usage();
					System.exit(0);
				} else if (arg.equals("-comm")) {
					index++;
					source = args[index];
				} else if (arg.equals("-d"))
					debug = true;
				else if (arg.equals("-b"))
					printBeacons = true;
				else {
					usage();
					System.exit(1);
				}
				index++;
			}
			new PromiscuousListener(source, debug, printBeacons);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	private static void usage() {
		System.err.println("usage: PromiscuousListener[-h | -comm <source> | -b | -d]");
		System.err.println("\t-h prints this help message");
		System.err.println("\t-comm <source> where <source> is COMx:[platform] or sf@localhost:[port]");
		System.err.println("\t-d for debug mode");
		System.err.println("\t-b for printing beacons");
		System.err.println("\nExample usage:\njava agilla.PromiscuousListener -comm COM51:tmote 2>&1 | tee text.txt");
	}
}
