// $Id: AgillaAssembler.java,v 1.13 2006/04/26 20:21:44 chien-liang Exp $

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
import java.lang.reflect.*;
import java.util.*;
import agilla.messages.AgillaCodeMsg;
import agilla.variables.*;


/**
 * Assembles an Agilla agent.  Note that one instance of this class can be
 * used to assemble as many Agilla agents as desired.  
 * 
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @author Chien-Liang Fok <liangfok@wustl.edu>
 */
public class AgillaAssembler implements AgillaConstants {
	
	/**
	 * Defines the classes that contain the Agilla ISA and extended ISA
	 */
	private static final String[] opcodeClasses = new String[] {
		"agilla.opcodes.BasicOpcodes",
		"agilla.opcodes.ExtendedOpcodes1",
		"agilla.opcodes.ExtendedOpcodes2",
		"agilla.opcodes.ExtendedOpcodes3",
		"agilla.opcodes.ExtendedOpcodes4",
		"agilla.opcodes.ExtendedOpcodes5",
		"agilla.opcodes.ExtendedOpcodes6",
		"agilla.opcodes.ExtendedOpcodes7",
		"agilla.opcodes.ExtendedOpcodes8",
		"agilla.opcodes.ExtendedOpcodes9",
		"agilla.opcodes.ExtendedOpcodes10",
		"agilla.opcodes.ExtendedOpcodes11",
		"agilla.opcodes.ExtendedOpcodes12",
		"agilla.opcodes.ExtendedOpcodes13"		
	};
	
	/**
	 *  The assembler is a singleton.
	 */
	private static final AgillaAssembler assembler = new AgillaAssembler();
	
	private static final String EXTENDED_ISA_FILE_PREFIX = "ExtendedOpcodes";
	private static final String EXTENDED_ISA_INSTR_PREFIX = "extend";
	
	/**
	 * Maps an instruction to its mode (remembers whether an instruction
	 * is part of the extended ISA, and if so which).  The key is the opcode
	 * (a String), and the value is the mode opcode (a String). 
	 */
	private Hashtable exTable = new Hashtable();
	
	/**
	 * Maps an instruction (String) to its byte code (Byte).
	 */
    private Hashtable s2bTable = new Hashtable();
    
    /**
     * Maps a byte code (Byte) to an instruction (String).
     */
    private Hashtable b2sTable = new Hashtable();
    
    /**
     * Maps an instruction to the number of arguments it takes.
     * The key is the opcode (a String), and the value is the 
     * number of arguments (an Integer).  By default instructions do
     * not have any arguments.  These instructions are not placed
     * in this table.
     */
    private Hashtable argNumTable = new Hashtable();

    /**
     * Maps an instruction to possible argument String values.  
     * These String values are then mapped to an Integer value.  It
     * is a hashtable within a hashtable where the first key is the
     * opcode that maps to a hashtable, and the second hashtable's key
     * is a string, which maps to its integer representation.
     * 
     * <p>For example, OPpushrt has many text parameters like VALUE, 
     * STRING, etc., that are mapped to integers.
     */
    private Hashtable argValTable = new Hashtable();
    
    /**
     * Maps an instruction to the size of the argument.  The size of
     * the argument is defined as the number of additional bytes the 
     * instruction requires.  For example, pushcl requires an additional
     * 2 bytes, thus it's size is 2.  The key is the instruction, the
     * value is the number of additional bytes required (an Integer).
     * By default, the size is 0 and the instruction is not stored
     * in this hashtable.
     */
    private Hashtable argSizeTable = new Hashtable();
    
    /**
     * Maps an instruction to the operand type.  The default type is
     * "value".  Other possible types include "string".  If the instruction
     * is not in this table, it is assumed to be type "value".
     */
    private Hashtable argTypeTable = new Hashtable();
    
    /**
     * Maps an instruction to the number of embedded argument bits
     * it has.  The key is the instruction (a string), and the value
     * is an Integer. 
     */
    private Hashtable argNumBitsTable = new Hashtable();
    
    /**
     * Contains a list of instructions that use arguments with relative 
     * addresses.
     */
    private Vector argRelAddr = new Vector();
    
    /**
     * The constructor.
     */
    private AgillaAssembler() {
    	
    	// Load the opcodes into the s2b, b2s, argsTable, and exTable hashtables
		try { 
			for (int j = 0; j < opcodeClasses.length; j++) {
				Class constants = this.getClass().getClassLoader().loadClass(opcodeClasses[j]);
				String modeInstr = getMode(opcodeClasses[j]);				
				
				Field[] fields = constants.getFields();
				for (int i = 0; i < fields.length; i++) {
					Field field = fields[i];
					String name = field.getName();
					if (name.startsWith("OP")) {
						String code = name.substring("OP".length());
						byte val = (byte)(field.getShort(constants) & 0xff);
						//System.out.println("Putting into s2bTable: " + code + " " + val);
						s2bTable.put(code, new Byte(val));
						b2sTable.put(new Short(val), code);
						if (modeInstr != null)
							exTable.put(code, modeInstr);
					}
					else if (name.startsWith("ArgNumOP")) {
						String code = name.substring("ArgNumOP".length());
						int val = (int)field.getInt(constants);
						argNumTable.put(code, new Integer(val));
					}
					else if (name.startsWith("ArgValOP")) {
						String code = name.substring("ArgValOP".length());
						String[][] argVals = (String[][])field.get(null);
						Hashtable vals = new Hashtable();
						for (int k = 0; k < argVals.length; k++) {
							vals.put(argVals[k][0], new Integer(argVals[k][1]));
						}
						argValTable.put(code, vals);
					}
					else if (name.startsWith("ArgSizeOP")) {
						String code = name.substring("ArgSizeOP".length());
						int size = (int)field.getInt(constants);
						argSizeTable.put(code, new Integer(size));
					}
					else if (name.startsWith("ArgTypeOP")) {
						String code = name.substring("ArgTypeOP".length());
						String argType = (String)field.get(null);
						argTypeTable.put(code, argType);
					}
					else if (name.startsWith("ArgRelAddrOP")) {
						String code = name.substring("ArgRelAddrOP".length());						
						argRelAddr.add(code);
					}
					else if (name.startsWith("ArgNumBitsOP")) {
						String code = name.substring("ArgNumBitsOP".length());	
						int size = (int)field.getInt(constants);
						argNumBitsTable.put(code, new Integer(size));
					}
				}
			}
		}
		catch (Exception e) {
			e.printStackTrace();
			System.exit(0);
		}
    }
    
    /**
     * Determines which mode instruction should be used.
     * 
     * @param name The name of the file defining the instructions.
     * @return The opcode that should be placed in front of these
     * instructions.
     */
    private String getMode(String name) {
    	int i = name.indexOf(EXTENDED_ISA_FILE_PREFIX); 
		if (i != -1) {
			return EXTENDED_ISA_INSTR_PREFIX + 
			name.substring(i+EXTENDED_ISA_FILE_PREFIX.length());
		} else
			return null;
    }
    
    /**
     * An accessor to the AgillaAssembler singleton.
     * @return The AgillaAssembler.
     */
    public static AgillaAssembler getAssembler() {
    	return assembler;
    }

    
    /**
     * Determines whether an instruction has arguments.
     *  
     * @param opcode The instruction.
     * @return true if the instruction has arguments.
     */
    public boolean hasArgs(String opcode) {
    	return argNumTable.containsKey(opcode);
    }
    
    /**
     * Determines the number of arguments an instruction has.
     * 
     * @param opcode The instruction.
     * @return the number of arguments an instruction has.
     */
    public int numArgs(String opcode) {
    	return ((Integer)argNumTable.get(opcode)).intValue();
    }
    
    /**
     * Converts a byte into its string representation.
     * 
     * <p>TODO: detect whether there are embedded operands and
     * adjust byte code for that.
     * 
     * @param b The instruction byte
     * @return The opcode.
     */
	public String byte2String(short b) {
		return (String)b2sTable.get(new Short(b));
	}
	
	/**
	 * Converts a string opcode into its byte representation.
	 * 
	 * @param opcode The opcode string.
	 * @return It's byte representation.
	 */
	public byte string2byte(String opcode) {
//		System.out.println("calling string2byte " + opcode);
		return ((Byte)s2bTable.get(opcode)).byteValue();
	}
	
	/**
	 * Determines whether an instruction is part Agilla's extended ISA.
	 * 
	 * @param instr The Instruction to consider.
	 * @return true if the opcode is part of Agilla's extended ISA, 
	 * false otherwise.
	 */
	private boolean isExtendedInstr(Instruction instr) {
		return exTable.containsKey(instr.opcode());
	}
	
	/**
	 * Returns the mode instruction that should be placed
	 * in front of the specified extended instruction.
	 * 
	 * @param instr The Instruction to consider.
	 * @return The mode instruction that should be placed
	 * in front of the specified extended instruction.
	 */
	private Instruction getModeInstr(Instruction instr) {
		String modeInstr = (String)exTable.get(instr.opcode());
		return new Instruction(modeInstr, instr.lineno()-0.5);
	}
	
	/**
	 *  Swaps the labels of the two instructions.
	 *  This is needed when an extended mode instruction has a label.
	 *  
	 * @param instr
	 * @param modeInstr
	 */
	private void swapLabel(Instruction instr, Instruction modeInstr)
	{
		String temp = modeInstr.label();
		modeInstr.setLabel(instr.label());
		instr.setLabel(temp);
	}
	
	/**
	 *  Expands the program by inserting mode switch instructions.
	 *  
	 * @param tokenizer
	 * @return the expanded tokenizer
	 */
	public ProgramTokenizer expandMode(ProgramTokenizer tokenizer) 
	{
		Vector prog = tokenizer.getProgram();
		for (int i = 0; i < prog.size(); i++) 
		{
			Instruction instr = (Instruction)prog.get(i);
			if (isExtendedInstr(instr)) {
				Instruction modeInstr = getModeInstr(instr);
				if (i > 0) 
				{
					Instruction prev = (Instruction)prog.get(i-1);
					if (!prev.equals(modeInstr))
					{						
						swapLabel(instr , modeInstr);						
						prog.add(i++, modeInstr);
					}
				} else
				{
					swapLabel(instr, modeInstr);
					prog.add(i++, modeInstr);
				}
			}
		}
		return tokenizer;
	}    
    
	/**
	 *  Determines whether a string is an instruction.
	 *  
	 * @param instr
	 * @return true if the string is an instruction, false otherwise.
	 */
	public boolean isInstruction(String instr) {
		boolean result = s2bTable.containsKey(instr);
		return result;
	}
    
	/**
	 * Analyzes a program and determines the address of each label.
	 * Also updates the tokenizer to contain the program counter 
	 * within each instruction.
	 * 
	 * @param tokenizer
	 * @return a hashtable mapping labels (String) to their address (Integer)
	 */
	private Hashtable getLabelTable(ProgramTokenizer tokenizer) 
	throws AssemblerException {
		expandMode(tokenizer); // make sure the mode switch instructions are present
		Vector program = tokenizer.getProgram();
		Hashtable result = new Hashtable();
		
		// determine what the program counter is
		int pc = 0;
		for (int i = 0; i < program.size(); i++) {
			Instruction instr = (Instruction)program.get(i);
			instr.setPC(pc++);
			if (argSizeTable.containsKey(instr.opcode())) {
				pc += ((Integer)argSizeTable.get(instr.opcode())).intValue();
			}
			
			if (instr.label() != null) {
				if (result.containsKey(instr.label()))
					throw new AssemblerException("Duplicate label " + instr.label() + " on line " + instr.lineno());
				else
					result.put(instr.label(), new Integer(instr.pc()));
			}			
		}
		return result;
	}
	
	/**
	 * Returns the number of additional bytes of arguments the instruction has.
	 * 
	 * @param opcode The instruction
	 * @return the number of bytes consumed by the arguments
	 * @throws AssemblerException
	 */
	private int argSize(String opcode) 
	throws AssemblerException {
		if (!hasArgs(opcode))
			throw new AssemblerException("Tried to get the argument size of an instruction (" 
					+ opcode + ") that does not have arguments.");
		if (argSizeTable.containsKey(opcode))
			return ((Integer)argSizeTable.get(opcode)).intValue();
		else
			return 0;
	}
	
	/**
	 * Loops up the address of a label.
	 * 
	 * @param label The label
	 * @return The address of the label, or -1 if the label does not exist.
	 */
	private int lookupLabel(String label, Hashtable labelTable) {
		if (labelTable.containsKey(label))
			return ((Integer)labelTable.get(label)).intValue();
		else
			return -1;		
	}
	
	private int numArgBits(Instruction instr) throws AssemblerException {
		if (argNumBitsTable.containsKey(instr.opcode()))
			return ((Integer)argNumBitsTable.get(instr.opcode())).intValue();
		else
			throw new AssemblerException("Attempted to find number of argument bits in an instruction (" 
					+ instr.opcode() + ") with no embedded argument on line " + instr.lineno());
	}
	
	/**
	 * Gets an instruction's arguments.  Calculates the values of these arguments.
	 * 
	 * @param instr The instruction
	 * @param labels The labels within the program and their address
	 * @return the arguments
	 * @throws AssemblerException
	 * @thors IOException
	 */
	public byte[] getArgs(Instruction instr, Hashtable labels) 
	throws AssemblerException, IOException {
		String opcode = instr.opcode();
		Argument arg = instr.arg();
		int numArgs = numArgs(opcode);		
		
		// Get the arguments
		String[] args = new String[numArgs];
		args[0] = arg.arg1();		
		if (numArgs > 1)
			args[1] = arg.arg2();
		if (numArgs > 2)		
			throw new AssemblerException("Unexpected number of arguments: " + numArgs);		
		
		// Get the type of the argument(s) (default type is a value)
		String type = (String)argTypeTable.get(opcode);
		if (type == null) type = "value";
		
		// allocate memory to store the results in
		int metaResult[] = new int[numArgs];
		
		// Parse each argument
		for (int i = 0; i < args.length; i++) {	
			if (type.equals("value")) {
				try {
					// First assume the argument is an integer
					metaResult[i] = Integer.valueOf(args[i]).intValue();
				} catch(Exception e) {
					// The argument is obviously not an integer, check whether the opcode has text operands
					try {
						Hashtable h = (Hashtable)argValTable.get(opcode);
						if (h.containsKey(args[i].toLowerCase()))
							metaResult[i] = ((Integer)h.get(args[i].toLowerCase())).intValue();
						else 
							throw new Exception("opcode doesn't have text operand");					
					} catch(Exception e1) {
						//assume it's a label					
						metaResult[i] = lookupLabel(args[i], labels);
						if (metaResult[i] == -1)
							throw new AssemblerException("Invalid value or label (" + args[i] + ") on line " + instr.lineno());
					}
				}
				
				// If the value is a relative address, calculate the
				// change in address
				if (argRelAddr.contains(opcode)) {
					metaResult[i] -= instr.pc();
				}				
				
				// If the argument is embedded, make sure there are enough bits
				if (argSize(opcode) == 0) {
					if ((Math.abs(metaResult[i]) >> numArgBits(instr)) > 0)
						throw new AssemblerException("Argument " + args[i] + " on line " 
								+ instr.lineno() + " exceeded number of available bits (" + numArgBits(instr) + ")");
				}
				
				// If the argument is not embedded, ensure that it can fit in in the available bytes
				else {
					int bytesPerOperand = argSize(opcode)/numArgs(opcode); 
					if (Math.abs(metaResult[i]) > Math.pow(2, 8*bytesPerOperand)-1)
						throw new AssemblerException("Argument " + args[i] + " on line " 
								+ instr.lineno() + " cannot fit within " + bytesPerOperand
								+ (bytesPerOperand > 1 ? " bytes" : " byte"));
				}
			}
			else if (type.equals("string")) {
				metaResult[i] = AgillaString.string2byte(args[i]);
			}
		}
				
		byte[] result = new byte[argSize(opcode) == 0 ? 1 : argSize(opcode)];
		if (result.length == 1)
			result[0] = (byte)metaResult[0];
		else {			
			if (metaResult.length == 1) {
				result[0] = (byte)(metaResult[0] >> 8);    // higher 8 bits
				result[1] = (byte)(0xff & metaResult[0]);  // lower 8 bits
			} else {
				result[0] = (byte)metaResult[0];
				result[1] = (byte)metaResult[1];
			}
		}
		return result;
	}
	
	private byte getMask(Instruction instr) 
	throws AssemblerException {
		byte result = 0;
		for (int i = 0; i < numArgBits(instr); i++) {
			result = (byte)((result << 1) | 1);
		}
		return result;
	}
	
	/**
	 * Generates a String of NesC code that can be copy-pasted into 
	 * AgentMgrM.nc for including a default agent that is hard coded
	 * into the mote and immediately runs when the mote is turned on.
	 * 
	 * @param tokenizer
	 * @param filename
	 * @throws IOException
	 * @throws InvalidInstructionException
	 */
	public String toDebugCode(ProgramTokenizer tokenizer, String filename)
		throws Exception 
	{
		Vector stringVector = new Vector(); // a vector of Bytes to hold the results		
		Hashtable labels = getLabelTable(tokenizer);

		while (tokenizer.hasMoreInstructions()) {
			Instruction instr = tokenizer.nextInstruction();
			log("Processing instruction " + instr);
			byte opcode = string2byte(instr.opcode());
			byte[] args = null;
			if (hasArgs(instr.opcode())) {
				args = getArgs(instr, labels); 			
				if (argSize(instr.opcode()) == 0) {				
					if (args != null) 
						stringVector.add("IOP" + instr.opcode() + " | " + (getMask(instr) & args[0]));
					else
						stringVector.add("IOP" + instr.opcode());					
				} else {
					stringVector.add("IOP" + instr.opcode());
					for (int i = 0; i < args.length; i++) {
						stringVector.add(new Byte(args[i]));
					}				
				}
			} else
				stringVector.add("IOP" + instr.opcode());
		}
		
		String space = "        ";
		String result 
		        = "-----------------------------------------------------------\n\n";
		result += space + "agents[0].id.id = getNewID();\n";
		result += space + "agents[0].pc = 0;\n";		
		result += space + "agents[0].state = AGILLA_STATE_READY;\n";
		result += space + "call CodeMgrI.allocateBlocks(&agents[0], " + tokenizer.size() + ");\n";				
		result += space + "dbg(DBG_USR1, \"||||||||||||||||||||||||||||||||||||||||||||||||||||||||\\n\");\n";
		if (filename == null)
			result += space + "dbg(DBG_USR1, \"Running untitled\\n\");\n";
		else
			result += space + "dbg(DBG_USR1, \"Running " + filename + "\\n\");\n";		
		int msgNum = 0;
		int i = 0;
		while (i < stringVector.size()){
			result += space + "cMsg.msgNum = " + (msgNum++) + ";\n";
			int msgSize = 0;
			while (msgSize < AgillaCodeMsg.numElements_code()  && i < stringVector.size()) {
				result += space + "cMsg.code[" + (msgSize++) + "] = " + stringVector.get(i++) + ";\n";			
			}
			result += space + "call CodeMgrI.setBlock(&agents[0], &cMsg);\n\n";
		}		
		result += "\n\n-----------------------------------------------------------";
		return result;
	}	
	
	/**
	 * Assembles an agent into a sequence of bytes.
	 * 
	 * @param tokenizer The tokenizer that has processed the agent.
	 * @return The byte represenation of a program.
	 */
	public byte[] toByteCode(ProgramTokenizer tokenizer)
		throws Exception 
	{
		Vector program = new Vector(); // a vector of Bytes to hold the results		
		Hashtable labels = getLabelTable(tokenizer);

		while (tokenizer.hasMoreInstructions()) {
			Instruction instr = tokenizer.nextInstruction();
			byte opcode = string2byte(instr.opcode());
			byte[] args = null;
			if (hasArgs(instr.opcode())) {
				args = getArgs(instr, labels); 			
				if (argSize(instr.opcode()) == 0) {				
					if (args != null) 
						program.add(new Byte((byte)(opcode | (getMask(instr) & args[0]))));
					else
						program.add(new Byte(opcode));					
				} else {
					program.add(new Byte(opcode));
					for (int i = 0; i < args.length; i++) {
						program.add(new Byte(args[i]));
					}				
				}
			} else
				program.add(new Byte(opcode));
		}

		int size = program.size();
		byte[] result = new byte[size];
		for (int i = 0; i < size; i++) {
			Byte instr = (Byte)program.elementAt(i);
			result[i] = instr.byteValue();
		}
		return result;
	}
	
	private void log(String msg) {
		Debugger.dbg("AgillaAssembler", msg);
	}
	
	/**
	 * This tests the functionality of the AgillaAssembler.
	 * 
	 * @param args The first parameter must be the name of the file containing
	 * the agent's code.
	 */
	public static void main(String[] args) {
		try {			
			FileReader reader = new FileReader(args[0]);
			ProgramTokenizer tokenizer = new ProgramTokenizer(reader);			
			byte[] program = AgillaAssembler.getAssembler().toByteCode(tokenizer);
			String bytes = "";
			for (int i = 0; i < program.length; i++) {
				String val = Integer.toHexString(program[i] & 0x00ff);
				if (val.length() == 1) {
					val = "0" + val;
				}
				bytes += "0x"+val;
				bytes += " ";
			}

			System.out.println(bytes);
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	}
}
