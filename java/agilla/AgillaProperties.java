// $Id: AgillaProperties.java,v 1.9 2006/04/05 23:57:24 chien-liang Exp $

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

import java.io.*;
import java.util.*;

public class AgillaProperties extends Properties {
	static final long serialVersionUID = -4478107165233435498L;
	private static final AgillaProperties singleton = new AgillaProperties();
	
	private static final String DEFAULT_INIT_DIR = "agents";
	private static final String DEFAULT_AGENT = "";
	private static final String DEFAULT_RUN_TEST = "false";
	private static final String DEFAULT_NUM_COL = "20";
	private static final String DEFAULT_ENABLE_CLUSTERING = "false";
	private static final String DEFAULT_NETWORK_NAME = "unk";
	private static String initDir, defaultAgent, nwName;
	private static int numCol;
	private static boolean runTest, enableClustering;
	
	private AgillaProperties() {
		super();
		initDir = DEFAULT_INIT_DIR;
		defaultAgent = DEFAULT_AGENT;
		runTest = Boolean.valueOf(DEFAULT_RUN_TEST).booleanValue();
		numCol = Integer.valueOf(DEFAULT_NUM_COL).intValue();
		enableClustering = Boolean.valueOf(DEFAULT_ENABLE_CLUSTERING).booleanValue();
		nwName = DEFAULT_NETWORK_NAME;
		try {
			load(new FileInputStream("agilla.properties"));
		}
		catch(IOException e) { 
			System.err.println("No agilla.properties file found.  "
					+ "Consider creating an agilla.properties file. "
					+ "See http://mobilab.wustl.edu/projects/agilla/docs/tutorials/2_inject.html#aiproperties for "
					+ "details");
			return;
		}
		try {
			initDir = getProperty("initDir", DEFAULT_INIT_DIR);
			defaultAgent = getProperty("defaultAgent", DEFAULT_AGENT);
			runTest = Boolean.valueOf(getProperty("runTest", DEFAULT_RUN_TEST)).booleanValue();
			numCol = Integer.valueOf(getProperty("numCol", DEFAULT_NUM_COL)).intValue();
			enableClustering = Boolean.valueOf(getProperty("enableClustering", DEFAULT_ENABLE_CLUSTERING)).booleanValue();
			nwName = getProperty("nwName", DEFAULT_NETWORK_NAME);
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	public static int numCol() {
		return numCol;
	}
	
	public boolean runTest() {
		return runTest;
	}
	
	public static boolean enableClustering() {
		return enableClustering;
	}
	
	public static String networkName(){
		return nwName;
	}
	
	public String getInitDir() {
		return initDir;
	}
	
	public String getDefaultAgent() {
		return defaultAgent;
	}
	
	static AgillaProperties getProperties() {
		return singleton;
	}	
}
