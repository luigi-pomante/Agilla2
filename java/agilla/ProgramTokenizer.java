// $Id: ProgramTokenizer.java,v 1.7 2006/05/03 00:36:42 chien-liang Exp $

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
 * Reads in an ASCII assembly program and tokenizes it into
 * individual instructions.
 * 
 * <p>Note that it does not determine the value of labels, nor
 * expand exteded instructions.  It simply produces a list of
 * Instruction objects that is used by the AgillaAssembler.
 * 
 * @author Chien-Liang Fok
 */
public class ProgramTokenizer implements AgillaConstants, Serializable {
	/**
	 * A reference to the AgillaAssembler singleton.
	 */
	private static AgillaAssembler assembler = AgillaAssembler.getAssembler();

	/**
	 * The program, a list of Instruction objects.
	 */
	private Vector program = new Vector();
	
	/**
	 * The current position within the program that the user is accessing.
	 * This is used by the reset(), hasMoreInstructions(), and nextInstruction()
	 * methods.
	 */
	private int currPos = 0;
	
	/**
	 * A hashtable that maps #define macros to their values.
	 */
	private Hashtable<String, String> macros = new Hashtable<String, String>();

	/**
	 * A constructor.
	 * 
	 * @param code The agent's code.
	 * @throws IOException
	 */
	public ProgramTokenizer(String code) throws IOException {
		this(new StringReader(code));
	}
	
	/**
	 * A constructor.
	 * 
	 * @param reader The reader that is reading the agent's code.
	 * @throws IOException
	 */
	public ProgramTokenizer(Reader reader) throws IOException {		
		StreamTokenizer tokenizer = new StreamTokenizer(reader);
		tokenizer.resetSyntax();
		tokenizer.slashSlashComments(true);
		tokenizer.slashStarComments(true);
		tokenizer.wordChars('A', 'Z');
		tokenizer.wordChars('a', 'z');
		tokenizer.wordChars('_', '_');
		tokenizer.wordChars('0','9');
		tokenizer.wordChars('-', '-');
		tokenizer.whitespaceChars(0, 32); // Unreadable chars and whitespace
		tokenizer.whitespaceChars(127, 127); // DEL
		tokenizer.wordChars('#', '#');
		//tokenizer.parseNumbers();
		tokenizer.eolIsSignificant(true);
		tokenizer.commentChar('%');
		
		parseProgram(tokenizer);
	}

	private void parseProgram(StreamTokenizer tokenizer)
	throws java.io.IOException {
		int ttype;
		
		while ((ttype = tokenizer.nextToken()) != StreamTokenizer.TT_EOF) 
		{
			switch(ttype) {
			case StreamTokenizer.TT_WORD:						
				if (assembler.isInstruction(tokenizer.sval))
					parseInstruction(null, tokenizer);
				else if (tokenizer.sval.toLowerCase().equals("#define")) {
					ttype = tokenizer.nextToken();
					if (ttype != StreamTokenizer.TT_WORD)
						throw new IOException("Invalid macro definition type.");
					String key = tokenizer.sval;
					ttype = tokenizer.nextToken();
					String value = "";
					if (ttype == StreamTokenizer.TT_WORD)
						value = tokenizer.sval;
					else if (ttype == StreamTokenizer.TT_NUMBER) 
						value += tokenizer.nval;
					else
						throw new IOException("Invalid macro replacement for " + key);
//					System.out.println("Adding " + key + ", " + value + " to the macros table.");
					macros.put(key, value);
				} else {			
					String label = tokenizer.sval;
					tokenizer.nextToken();
					parseInstruction(label, tokenizer);
				}
			break;
			case StreamTokenizer.TT_EOL:				
				break;
			}
		}
		
		// Check to ensure the last instruction is a halt
		Instruction i = (Instruction)program.get(program.size()-1);
		if (!i.opcode().equals("halt"))
		{
			program.add(new Instruction("halt", i.lineno()+1));
		}
	}

	/**
	 * Parses an instruction and inserts it into the program vector.
	 * 
	 * @param label The instruction's line's label.
	 * @param tokenizer The tokenizer.
	 */
	private void parseInstruction(String label, StreamTokenizer tokenizer)
	throws java.io.IOException {
		String opcode = tokenizer.sval;		
		if (opcode == null)
			throw new IOException("Invalid instruction or label \"" + label + "\"");
		int lineno = tokenizer.lineno();
		
		if (!assembler.isInstruction(opcode))
			throw new  IOException("Unknown instruction (" + opcode + ") on line " + lineno);
		
		// Fetch the argument
		Argument arg = null;
		if (assembler.hasArgs(opcode)) {
			if (assembler.numArgs(opcode) == 1) {
				int ttype;
				if ((ttype = tokenizer.nextToken()) != StreamTokenizer.TT_WORD)
					throw new IOException("Invalid argument type for instr " 
							+ opcode + "(" + ttype + ")");
				else {
					if (macros.containsKey(tokenizer.sval))
						arg = new Argument(macros.get(tokenizer.sval));
					else
						arg = new Argument(tokenizer.sval);
				}
			}
			else {
				int ttype;
				String arg1, arg2;
				if ((ttype = tokenizer.nextToken()) != StreamTokenizer.TT_WORD)
					throw new IOException("Invalid argument 1 type for instr " 
							+ opcode + "(" + ttype + ")");
				else {
					arg1 = tokenizer.sval;
					if (macros.containsKey(arg1)) arg1 = macros.get(arg1);
					
					if ((ttype = tokenizer.nextToken()) != StreamTokenizer.TT_WORD)				
						throw new IOException("Invalid argument 2 type for instr " 
								+ opcode + "(" + ttype + ")");
					else {
						arg2 = tokenizer.sval;
						if (macros.containsKey(arg2)) arg2 = macros.get(arg2);
						arg = new Argument(arg1, arg2);
					}
				}
			}
		}
				
		Instruction instr = new Instruction(opcode, lineno, arg, label);
		program.add(instr);
	}

	/**
	 * An accessor to the tokenized program.
	 * 
	 * @return the tokenized program as a vector of Instruction objects.
	 */
	public Vector getProgram() {
		return program;
	}
	
	/**
	 * Returns the number of bytes of code memory this program consumes.
	 * 
	 * @return The number of bytes of code memory this program consumes.
	 */
	public int size() {
		return ((Instruction)program.get(program.size()-1)).pc()+1;	
	}
	
	/**
	 * Resets this tokenizer to point to the beginning of the agent.
	 */
	public void reset() {
		currPos = 0;
	}
	
	/**
	 * Determines whether there are more instructions in the agent.
	 * 
	 * @return true if there there are more instructions.
	 */
	public boolean hasMoreInstructions() {
		return currPos < program.size();
	}
	
	/**
	 * Returns the agent's next instruction.
	 * @return The next instruction.
	 */
	public Instruction nextInstruction() {
		return (Instruction)program.get(currPos++);
	}
	
	/**
	 * Returns a String representation of this class.
	 * 
	 * @param return a String representation of this class.
	 */
	public String toString() {
		String result = "";
		for (int i = 0; i < program.size(); i++) {
			result += program.get(i).toString() + "\n";
		}
		return result;
	}
}
