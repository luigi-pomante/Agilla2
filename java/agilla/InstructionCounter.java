// $id$

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

/**
 * Traverses a directory and all sub-directories counting
 * the number of instructions used in all agents contained
 * within these directories.
 * 
 * @author liang
 */
public class InstructionCounter {

	public static String dir = "C:\\tinyos\\cygwin\\opt\\tinyos-1.x\\contrib\\wustl\\apps\\AgillaAgents";
	
	private Hashtable table = new Hashtable();
	
	public InstructionCounter() throws IOException {
		File f = new File(dir);		
		log("Analyzing agents in " + f.getAbsolutePath());
		analyze(f);
		printResults();
	}
	
	private void printResults() {		
	     for (Enumeration e = table.keys(); e.hasMoreElements() ;) {
	    	 String instr = (String)e.nextElement();
	         Integer count = (Integer)table.get(instr);
	         System.out.println(instr + "\t" + count);
	     }
	}
	
	private void analyze(File f) throws IOException {
		String[] list = f.list();
		if (list != null) {			
			for (int i = 0; i < list.length; i++)
				analyze(new File(f.getCanonicalPath() + "\\"+ list[i]));
		} else {
			if (f.getName().endsWith(".ma") || f.getName().endsWith(".fg"))
				count(f);
		}
	}
	
	private void count(File f) throws FileNotFoundException, IOException {
		ProgramTokenizer tokenizer = new ProgramTokenizer(new FileReader(f));
		AgillaAssembler.getAssembler().expandMode(tokenizer);
		
		while(tokenizer.hasMoreInstructions()) {
			Instruction instr = tokenizer.nextInstruction();
			Integer count = (Integer)table.remove(instr);
			if (count == null)
				table.put(instr.opcode(), new Integer(1));
			else
				table.put(instr.opcode(), new Integer(count.intValue()+1));
		}
	}
	
	private void log(String msg) {
		System.out.println(msg);
	}
	
	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException {
		new InstructionCounter();
	}

}
