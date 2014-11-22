// $Id: ErrorDisplayer.java,v 1.4 2005/12/21 17:13:43 chien-liang Exp $
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

import agilla.messages.*;
import java.awt.*;
/**
 * AgillaErrorDisplayer.java
 *
 * @author Chien-Liang Fok
 */
public class ErrorDisplayer implements AgillaConstants, MessageListenerJ {
    private ErrorDialog dialog = null;
    private String agentID = "";
    private String cause = "";
	private String pc = "";
    private String instruction = "";
	private String sp = "";
    private String reason1 = "";
	private String reason2 = "";
	
	/**
	 * The constructor.
	 */
	public ErrorDisplayer() {
	}
	
	private void updateDialog(String context, String cause, String pc,
							  String instruction, String sp, String reason1, String reason2) {
		Point p = null;
		if (dialog != null) {
			p = dialog.getLocation();
			dialog.dispose();
		}
		
		dialog = DialogFactory.errorDialog(context, cause, pc, instruction, sp, reason1, reason2);
		if (p != null) {
			dialog.setLocation(p);
		}
		
		dialog.show();
	}
	
	
	private void displayErrorMsg(AgillaErrorMsgJ msg) {
		agentID = msg.getID().toString();
		pc = String.valueOf(msg.getPC());
		cause = getCause((int)msg.getCause());
		instruction = Integer.toHexString(msg.getInstr() & 0xff);
		if (instruction.length() == 1)
			instruction = "0" + instruction;
		String instr = AgillaAssembler.getAssembler().byte2String(msg.getInstr());
		if (instr == null) instr = "INVALID";
		instruction = "0x" + instruction + " (" + instr + ")";
		String sp = String.valueOf(msg.getSP());
		reason1 = String.valueOf(msg.getReason1());
		reason2 = String.valueOf(msg.getReason2());
		if ((!this.agentID.equals(agentID)) ||
				(!this.pc.equals(pc)) ||
				(!this.cause.equals(cause)) ||
				(!this.instruction.equals(instruction)) ||
				(!this.sp.equals(sp)) ||
				(!this.reason1.equals(reason1))) {
//			this.agentID = agentID;
//			this.pc = pc;
//			this.cause = cause;
//			this.instruction = instruction;
//			this.sp = sp;
//			this.reason1 = reason1;
//			this.reason2 = reason2;
			System.out.println("Error received:");
			System.out.println("  AgentID:         " + agentID);
			System.out.println("  Cause:           " + cause);
			System.out.println("  Program counter: " + pc);
			System.out.println("  Instruction: " + instruction);
			System.out.println("  Stack Pointer: " + sp);
			System.out.println("  Reason1: " + reason1);
			System.out.println("  Reason2: " + reason2);
			System.out.println();
			updateDialog(agentID, cause, pc, instruction, sp, reason1, reason2);
		}
	}
	
	public static String getCause(int cause) {
		switch(cause) {
			case 0:
				return "TRIGGERED";
			case 1:
				return "INVALID_RUNNABLE";
			case 2:
				return "STACK_OVERFLOW ";
			case 3:
				return "STACK_UNDERFLOW";
			//case 4:
				//return "TS_FULL";
			case 5:
				return "AGENT_NOT_RUNNING";
			case 6:
				return "INDEX_OUT_OF_BOUNDS";
			case 7:
				return "INSTRUCTION_RUNOFF ";
			case 8:
				return "INVALID_FIELD_TYPE";
			case 9:
				return "AGILLA_ERROR_CODE_OVERFLOW";
			case 10:
				return "ILLEGAL_TUPLE_NAME";
			case 11:
				return "QUEUE_ENQUEUE";
			case 12:
				return "QUEUE_DEQUEUE";
			case 13:
				return "QUEUE_REMOVE";
			case 14:
				return "QUEUE_INVALID";
			case 15:
				return "RSTACK_OVERFLOW";
			case 16:
				return "RSTACK_UNDERFLOW";
			case 17:
				return "INVALID_ACCESS";
			case 18:
				return "TYPE_CHECK";
			case 19:
				return "INVALID_TYPE";
			case 20:
				return "INVALID_LOCK";
			case 21:
				return "INVALID_INSTRUCTION";
			case 22:
				return "INVALID SENSOR";
			case 23:
				return "ILLEGAL CODE BLOCK";
			case 24:
				return "ILLEGAL FIELD TYPE";
			case 25:
				return "INVALID FIELD COUNT";
		    case 26:
				return "GET FIELD INVALID TYPE";
			//case 27:
			//	return "AGILLA_ERROR_UNKOWN_AGENT_CODE";
			case 28:
				return "AGILLA_ERROR_UNKOWN_AGENT_HEAP";
			case 29:
				return "AGILLA_ERROR_UNKOWN_AGENT_OPSTACK";
			case 30:
				return "AGILLA_ERROR_REQUEST_Q_FULL";
			case 31:
				return "AGILLA_ERROR_OPrtsM_AGENT_NULL";
			case 32:
				return "AGILLA_ERROR_OPrtsM_AGENTID_MISMATCH";
			case 33:
				return "AGILLA_ERROR_OPrtsM_INSTR_MISMATCH";
			case 34:
				return "AGILLA_ERROR_OPrtsM_NO_RESPONSE";
			case 35:
				return "AGILLA_ERROR_RCV_BUFF_FULL";
			case 36:
				return "AGILLA_ERROR_UNKNOWN_MSG_TYPE";
			case 37:
				return "AGILLA_ERROR_TUPLE_SIZE";
			case 38:
				return "AGILLA_ERROR_SEND_BUFF_FULL";
			case 39:
				return "AGILLA_ERROR_NO_CLOSER_NEIGHBOR";
			case 40:
				return "AGILLA_ERROR_DROPPED_RESULTS_MESSAGE";
			case 41:
				return "AGILLA_ERROR_OPrtsM_BOUNCE_QUEUE_FULL";
			case 42:
				return "AGILLA_ERROR_RXN_NOT_FOUND";
			case 43:
				return "AGILLA_ERROR_TASK_QUEUE_FULL";
			case 44:
				return "AGILLA_ERROR_INVALID_VARIABLE_SIZE";
			case 45:
				return "AGILLA_ERROR_OPSLEEP_BUFFER_UNDERFLOW";
			case 46:
				return "AGILLA_ERROR_GET_FREE_BLOCK";
			case 47:
				return "AGILLA_ERROR_ILLEGAL_RXN_OP";
			default:
				return "UNKNOWN ERROR TYPE: " + cause;
		}
	}
	public void messageReceived(int to, MessageJ msg) {
		if (msg.getType() == AgillaErrorMsg.AM_TYPE)
			displayErrorMsg((AgillaErrorMsgJ)msg);
	}
}

