/**
 * Tester.java
 *
 * @author Created by Omnicore CodeGuide
 */

package agilla;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

import agilla.messages.AgillaRxnMsgJ;
import agilla.variables.*;

public class Tester implements Runnable, AgillaConstants
{
	private AgentInjector injector;
	
	public Tester(AgentInjector injector) {
		this.injector = injector;
		new Thread(this).start();
	}
	
	/**
	 * Test remote out, rdp, and inp operations.
	 */
	/*public void run () {
	 
	 try {
	 Thread.sleep(3000);
	 } catch(Exception e) {
	 e.printStackTrace();
	 return;
	 }
	 
	 injector.reset();
	 
	 String outAgentString =
	 "BEGIN		pushc 1\n" +
	 "		pushn ncr\n" +
	 "		pushc 2\n" +
	 "		pushc 3\n" +
	 "		out\n" +
	 "		pushc RETURN\n" +
	 "		rjump THREEBLINK\n" +
	 "RETURN		halt\n" +
	 "THREEBLINK  	pushc 0\n" +
	 "TBLOOP  	copy\n" +
	 "        	pushc 6\n" +
	 "        	cneq\n" +
	 "        	rjumpc TBCONT\n" +
	 "        	pop     // clear the opstack\n" +
	 "        	jumps   // return to caller\n" +
	 "TBCONT  	pushc 31\n" +
	 "        	putled        // toggle all three LEDs\n" +
	 "        	pushc 1\n" +
	 "        	sleep\n" +
	 "        	inc\n" +
	 "        	rjump TBLOOP\n";
	 Agent outAgent = new Agent(outAgentString);
	 int dest = 1;
	 dbg("Injecting out agent into " + dest);
	 injector.inject(outAgent, dest);
	 
	 try {
	 Thread.sleep(3000);
	 } catch(Exception e) {
	 e.printStackTrace();
	 return;
	 }
	 
	 Tuple template = new Tuple();
	 template.addField(new AgillaType(AGILLA_TYPE_ANY));
	 template.addField(new AgillaType(AGILLA_TYPE_ANY));
	 template.addField(new AgillaType(AGILLA_TYPE_ANY));
	 
	 dbg("Doing rrdp on " + dest + " with template " + template);
	 Tuple result = injector.getTS().rrdp(template, dest);
	 dbg("Result of rrdp = " + result);
	 
	 try {
	 Thread.sleep(3000);
	 } catch(Exception e) {
	 e.printStackTrace();
	 return;
	 }
	 
	 dbg("Doing rinp on " + dest + " with template " + template);
	 Tuple result2 = injector.getTS().rinp(template, dest);
	 dbg("Result of inp = " + result);
	 
	 dbg("Testing done.");
	 }*/
	
	/**
	 * Tests the PC performing a rrdp and rinp on a mote's tuple space.
	 */
	/*public void run () {
		Tuple tuple1 = new Tuple();
		tuple1.addField(new AgillaValue((short)1));
		tuple1.addField(new AgillaString("abc"));
		tuple1.addField(new AgillaValue((short)1));
		
		Tuple template1 = new Tuple();
		template1.addField(new AgillaType(AGILLA_TYPE_ANY));
		template1.addField(new AgillaType(AGILLA_TYPE_ANY));
		template1.addField(new AgillaType(AGILLA_TYPE_ANY));
		
		int dest = 1;
		dbg("OUTing tuple " + tuple1);
		boolean result = injector.getTS().rout(tuple1, dest);
		if (!result)
			dbg("Failed to out tuple");
		
		dbg("INPing the tuple");
		Tuple t = injector.getTS().rinp(template1, dest);
		
		if (t == null)
			dbg("failed to find tuple.");
		else
			dbg("found tuple " + t);
		
		dbg("Testing done.");
	 }*/
	
//	public void run() {
//		Tuple template = new Tuple();
//		template.addField(new AgillaType(AGILLA_TYPE_STRING));
//		template.addField(new AgillaType(AGILLA_TYPE_VALUE));
//		
//		while(true) {
//			dbg("Doing in...");
//			Tuple result = injector.getTS().in(template);
//			dbg("Got the following: " + result);
//		}
//	}

//	public void run() {		
//		try {
//			AgillaAgentID aID = new AgillaAgentID();
//			
//			String code = "BEGIN		pushc RETURN\n"
//			+ "getvar 0     // heap 0 must contain # of times to blink LED\n"
//			+ "pushcl BLINKGREENC\n"
//			+ "jumps\n"
//			+ "RETURN          halt\n"
//			+ "\n"
//			+ "BLINKGREENC 	pushc 26\n" 
//			+ "putled // blink green\n"
//			+ "pushc 1\n"
//			+ "sleep\n"
//			+ "dec\n"
//			+ "copy\n"
//			+ "pushc 0\n"
//			+ "ceq\n"
//			+ "rjumpc BLINKGREENCD\n"
//			+ "rjump BLINKGREENC\n"
//			+ "BLINKGREENCD	pop\n"
//			+ "jumps\n";
//		
//			OpStack os = new OpStack();
//			os.push(new AgillaValue((short)123));
//			os.push(new AgillaString("abc"));
//			
//			AgillaStackVariable heap[] = new AgillaStackVariable[AGILLA_HEAP_SIZE];
//			for (int i = 0; i < AGILLA_HEAP_SIZE; i++) {
//				heap[i] = new AgillaInvalidVariable();
//			}
//			heap[0] = new AgillaValue((short)6);
//			
//			Tuple template = new Tuple();
//			template.addField(new AgillaValue((short)123));
//			template.addField(new AgillaString("abc"));
//			AgillaRxnMsgJ rxnMsgs[] = new AgillaRxnMsgJ[1];
//			rxnMsgs[0] = new AgillaRxnMsgJ((short)0, new Reaction(aID, 0, template));
//			Agent a = new Agent(aID, code, 0, 0, os, heap, rxnMsgs);
//			
//			injector.inject(a, 0);
//		} catch(Exception e) {
//			e.printStackTrace();
//		}
//	}
	
	public void run() {
		String code = "";
		try {
			String fileName = AgillaProperties.getProperties().getInitDir()
				+ "\\" + "3Blink.ma";
			dbg("Reading agent: " + fileName);
			
			File f = new File(fileName);
			FileReader fr = new FileReader(f);
			BufferedReader br = new BufferedReader(fr);

			String curr;
			while ((curr = br.readLine()) != null) {
				code += curr + "\n";
			}
			br.close();
			fr.close();
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		
		Agent agent = new Agent(code);		
		
		/** Add 5 things to the stack **/
		for (int i = 0; i < 5; i++) {
			try {
				agent.getOpStack().add(new AgillaValue((short)i));
			} catch (OpStackException e) {
				e.printStackTrace();
			}
		}
		
		/** Add a variable to the heap **/
		AgillaStackVariable[] heap = agent.getHeap();
		for (int i = 0; i < AgillaConstants.AGILLA_HEAP_SIZE; i++) {
			if (heap[i].getType() == AgillaConstants.AGILLA_TYPE_INVALID) {
				heap[i] = new AgillaValue((short)i);
				continue;
			}
		}
		
		/** Add a reaction **/
		
		AgillaRxnMsgJ [] oldRxns = agent.getRxns();
		AgillaRxnMsgJ [] newRxns = new AgillaRxnMsgJ [oldRxns.length+1];
		System.arraycopy(oldRxns, 0, newRxns, 0, oldRxns.length);
		
		Tuple t = new Tuple();
		t.addField(new AgillaValue((short)1));
		
		newRxns[newRxns.length-1] = new AgillaRxnMsgJ((short)(newRxns.length-1), 
				new agilla.Reaction(agent.getID(), 1, t));
		agent.setReactions(newRxns);
		
		dbg("Agent: " + agent);
		
		try {
			Thread.sleep(2000);
		} catch (InterruptedException e) {			
			e.printStackTrace();
		}	
		
		dbg("Injecting agent...");
		injector.inject(agent, 0);
	}
	
	private void dbg(String msg) {
		System.out.println("Tester: " + msg);
	}
}

