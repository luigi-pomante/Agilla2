// $Id: Agent.java,v 1.4 2005/12/09 07:24:05 chien-liang Exp $

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
 * Agent.java
 *
 * This is a Java-implementation of an Agilla agent.
 *
 * @author Chien-Liang Fok
 */

package agilla;
import agilla.messages.*;
import agilla.opcodes.BasicOpcodes;
import agilla.variables.*;

import java.io.*;

public class Agent implements AgillaConstants, BasicOpcodes, Serializable {
	static final long serialVersionUID = 8825485772863901849L;
	private AgillaAgentID id;
	private byte[] code;
	private int pc, condition, codeSize;
	private OpStack os = new OpStack();
	private AgillaStackVariable[] heap = new AgillaStackVariable[AGILLA_HEAP_SIZE];
	private AgillaRxnMsgJ [] rxns = new AgillaRxnMsgJ[0];
	//private Thread thread;  // this is the thread that executes AgentThread
	
	public Agent(String codeString) {		
		StringReader reader = new StringReader(codeString);
		try {
			ProgramTokenizer tok = new ProgramTokenizer(reader);
			code = AgillaAssembler.getAssembler().toByteCode(tok);			
		} catch(Exception e) {
			e.printStackTrace();
			return;
		}
		id = new AgillaAgentID();
		pc = 0; condition = 0; codeSize = code.length;		
		for (int i = 0; i < heap.length; i++) {
			heap[i] = new AgillaInvalidVariable();
		}
	}
	
	public Agent(AgillaAgentID id, String code, int pc, int condition, OpStack os,
			AgillaStackVariable[] heap, AgillaRxnMsgJ[] rxns)
	{
		this(code);
		this.id = id;
		this.pc = pc;
		this.condition = condition;
		this.os = os;
		System.arraycopy(heap, 0, this.heap, 0, heap.length);
		this.rxns = new AgillaRxnMsgJ[rxns.length];
		System.arraycopy(rxns, 0, this.rxns, 0, rxns.length);
	}

	public Agent(String code, int pc, int condition, OpStack os,
			AgillaStackVariable[] heap, AgillaRxnMsgJ[] rxns)
	{
		this(new AgillaAgentID(), code, pc, condition, os, heap, rxns);				
	}
	
	public Agent(String code, OpStack os, AgillaStackVariable[] heap, AgillaRxnMsgJ[] rxns)
	{
		this(new AgillaAgentID(), code, 0, 0, os, heap, rxns);				
	}
	
	
	public Agent(AgillaAgentID id, byte[] code) {
		this(id, 0, code, 0);
	}
	
	public Agent(AgillaAgentID id, int pc, byte[] code) {
		this(id, pc, code, 0);
	}
	
	public Agent(AgillaAgentID id, int pc, byte[] code, int condition) {
		this(id, pc, code.length, condition);
		
		System.arraycopy(code, 0, this.code, 0, code.length);
	}
	
	public Agent(AgillaAgentID id, byte [] code, int pc, int condition, OpStack os, 
			AgillaStackVariable [] heap, AgillaRxnMsgJ [] rxns) 
	{
		this(new AgillaAgentID(), pc, code, condition);
		
		this.os = os;
		this.rxns = new AgillaRxnMsgJ[rxns.length];
		System.arraycopy(heap, 0, this.heap, 0, heap.length);
		this.rxns = new AgillaRxnMsgJ[rxns.length];
		System.arraycopy(rxns, 0, this.rxns, 0, rxns.length);
	}
	
	public Agent(AgillaAgentID id, int pc, int codeSize, int condition) {
		this.id = id;
		this.pc = pc;
		this.codeSize = codeSize;
		this.condition = condition;
		code = new byte[codeSize];
		for (int i = 0; i < AGILLA_HEAP_SIZE; i++) {
			heap[i] = new AgillaInvalidVariable();
		}
	}
	
	public Agent deepClone() {
		Agent a = new Agent((AgillaAgentID)id.deepClone(), pc, code, condition);
		a.os = os.deepClone();
		for (int i = 0; i < AGILLA_HEAP_SIZE; i++) {
			a.heap[i] = heap[i].deepClone();
		}
		return a;
	}
	
	/*public void kill() {
	 if (agentThread != null) {
	 agentThread.kill();
	 agentThread = null;
	 try {
	 thread.join();
	 } catch(InterruptedException e) {
	 e.printStackTrace();
	 }
	 }
	 }*/
	
	public AgillaAgentID getID() {
		return id;
	}
	
	
	public int getPC() {
		return pc;
	}
	
	public void setPC(int pc) {
		this.pc = pc;
	}
	
	public void setCode(int pc, byte instr) {
		code[pc] = instr;
	}
	
	public void setReactions(AgillaRxnMsgJ[] rxns) {
		this.rxns = rxns;
	}
	
	public short getInstr(int pc) {
		return code[pc];
	}
	
	public short getNextInstr() {
		return code[pc++];
	}
	
	public int getCondition() {
		return condition;
	}
	
	public void setCondition(int condition) {
		this.condition = condition;
	}
	
	public OpStack getOpStack() {
		return os;
	}
	
	public AgillaStackVariable[] getHeap() {
		return heap;
	}
	
	public AgillaRxnMsgJ [] getRxns() {
		return rxns;
	}
	
	public int codeSize() {
		return codeSize;
	}
	
	/*public void start(Mote mote) {
	 this.mote = mote;
	 agentThread = new AgentThread();
	 thread = new Thread(agentThread);
	 thread.start();
	 }*/
	
	public boolean equals(Object o) {
		if (o instanceof Agent) {
			Agent a = (Agent)o;
			return a.id.getID() == id.getID();
		} else return false;
	}
	
	/**
	 * Executes the next instruction, returns true if the agent
	 * should halt execution, false otherwise.
	 */
	/*private boolean executeNextInstr() {
	 //System.out.println("Executing next instruction: " + code[pc]);
	 if (pc >= codeSize) {
	 //System.out.println("pc exceeds codeSize");
	 return true;
	 }
	 byte instr = code[pc++];
	 
	 String val = Integer.toHexString(instr & 0x00ff);
	 if (val.length() == 1) {
	 val = "0" + val;
	 }
	 val = "0x"+val;
	 //System.out.println("next instruction is: " + (instr & 0x00ff) + " = " + val);
	 
	 Opcode opc = null;
	 try {
	 opc = mote.getOpcode(instr);
	 } catch(AgentException e) {
	 e.printStackTrace();
	 return true;
	 }
	 
	 //System.out.println("Executing " + opc);
	 return opc.execute(this, instr);
	 }*/
	
	
	/*private class AgentThread implements Runnable {
	 boolean done = false;
	 boolean killed = false;
	 
	 public AgentThread() {
	 }
	 
	 public void kill() {
	 killed = true;
	 }
	 
	 public void run() {
	 
	 //System.out.println("code[3] = " + Integer.toHexString(code[3]));
	 while (!done && !killed) {
	 done = executeNextInstr();
	 }
	 System.out.println("Agent " + getID() + " done.");
	 mote.done(id);
	 }
	 }*/
	
	public String toString() {
		String result = "Agent:\nID: " + id + "\nPC: " + pc + "\nCondition: "
			+ condition + "\nOpStack: " + os + "\nHeap: ";
		for (int i = 0; i < AGILLA_HEAP_SIZE; i++) {
			result += heap[i];
			if (i < AGILLA_HEAP_SIZE - 1)
				result += ", ";
		}
		result += "\nReactions: ";
		if (rxns.length == 0)
			result += "[none]";
		else {
			for (int i = 0; i < rxns.length; i++) {
				result += rxns[i];
				if (i < rxns.length - 1)
					result += ", ";
			}
		}
		result += "\nCode: ";
		for (int i = 0; i < codeSize; i++) {
			String val = Integer.toHexString(code[i] & 0x00ff);
			if (val.length() == 1) {
				val = "0" + val;
			}
			result += "0x"+val;
			result += " ";
		}
		return result;
	}
}

