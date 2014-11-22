package agilla;

import java.io.Serializable;

/**
 * Encapsulates an instruction and program meta data.  This is
 * used by the ProgramTokenizer.  The ProgramTokenizer transforms 
 * Agilla code into a list of Instruction objects.
 * 
 * @author liang
 */
public class Instruction implements Serializable{
	private static final long serialVersionUID = 1457872207630899740L;
	
	/**
	 *  The instruction.
	 */
	private String opcode;
	
	/**
	 *  The line number that the instruction appeared in.
	 */
	private double lineno;
	
	/**
	 *  The label on the line number
	 */
	private String label;
	
	/**
	 * The parameter for the instruction.
	 */
	private Argument arg;
	
	/**
	 * The program counter.
	 */
	private int pc;
	
	/**
	 * A constructor.
	 * 
	 * @param opcode The instruction.
	 * @param lineno The line it appears in.
	 */
	public Instruction(String opcode, double lineno) {
		this.opcode = opcode;
		this.lineno = lineno;
	}
	
	/**
	 * A constructor.
	 * 
	 * @param opcode The instruction.
	 * @param lineno The line it appears in.
	 * @param arg The instruction's argument.
	 */
	public Instruction(String opcode, double lineno, Argument arg) {
		this(opcode, lineno);
		this.arg = arg;
	}
	
	/**
	 * A constructor.
	 * 
	 * @param opcode The instruction.
	 * @param lineno The line it appears in.
	 * @param arg The instruction's argument.
	 * @param label The line's label.
	 */
	public Instruction(String opcode, double lineno, Argument arg, String label) {
		this(opcode, lineno, arg);
		this.label = label;
	}
	
	/**
	 * A constructor.
	 * 
	 * @param opcode The instruction.
	 * @param lineno The line it appears in.
	 */
	public Instruction(String opcode, double lineno, String label) {
		this(opcode, lineno);
		this.label = label;
	}	
	
	/**
	 * Determines the equality of this object and another object.
	 */
	public boolean equals(Object o) {
		if (o instanceof Instruction) {
			Instruction i = (Instruction)o;
			return i.opcode().equals(opcode());
		} else
			return false;
	}
	
	/**
	 * An accessor to the opcode.
	 * 
	 * @return The opcode.
	 */
	public String opcode() {
		return opcode;
	}
	
	/**
	 * An accessor to the line number.
	 * 
	 * @return The line number.
	 */
	public int lineno() {
		return (int)lineno;
	}
	
	/**
	 * An accessor to the argument.
	 * 
	 * @return The instruction's argument.
	 */
	public Argument arg() {
		return arg;
	}
	
	/**
	 *  An accessor to the line's label.
	 *  
	 * @return The line's label.
	 */
	public String label() {
		return label;
	}
	
	/**
	 *  Sets the label of this instruction.
	 *  
	 * @param label
	 */
	public void setLabel(String label) {
		this.label = label;
	}
	
	/**
	 * Sets the value of the program counter.
	 * 
	 * @param pc The program counter.
	 */
	public void setPC(int pc) {
		this.pc = pc;
	}
	
	/**
	 *  An accessor to the program counter.
	 *  
	 * @return the program counter.
	 */
	public int pc() {
		return pc;
	}
	
	/**
	 * Returns a String representation of this class.
	 * 
	 * @param return a String representation of this class.
	 */
	public String toString() {
		return lineno + " (" + pc + "): " + label + "\t" + opcode + "\t" + " " + arg;
	}
}
