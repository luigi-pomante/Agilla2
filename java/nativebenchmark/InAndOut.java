package nativebenchmark;

import java.io.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;

public class InAndOut implements MessageListener {
	static int group_id = 7;
	static String source = "COM1:115200";
	static int NUM_ROUNDS = 1000;

	private MoteIF mote;
	private CodeMsg cmsg;
	private StateMsg smsg;
	private AckMsg amsg;
	
	private int round = -2;
	private long stime;
	private boolean sentState = false;
	
	/**
	 * Initializes the frame.
	 * @throws IOException 
	 * @throws InterruptedException 
	 */
	public InAndOut() throws IOException, InterruptedException {

		try {
			mote = new MoteIF(BuildSource.makePhoenix(BuildSource.makeArgsSerial(source),net.tinyos.util.PrintStreamMessenger.err));
			//mote = new MoteIF(PrintStreamMessenger.err, group_id);
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(0);
		}
		smsg = new StateMsg();
		cmsg = new CodeMsg();
		amsg = new AckMsg();
		
		mote.registerListener(new StateMsg(), this);
		mote.registerListener(new CodeMsg(), this);
		mote.registerListener(new AckMsg(), this);
		Thread.sleep(1000);
		doBenchmark();
	}
	
	private void doBenchmark() throws IOException {		
		stime = System.nanoTime();
		sentState = true;
		dbg("sending state...");
		mote.send(0, smsg);
	}
	
	public void messageReceived(int to, Message m) {
		long length = System.nanoTime() - stime;
		try {
			if (m.amType() == AckMsg.AM_TYPE) {
				if (sentState) {
					sentState = false;
					dbg("sending code...");
					mote.send(0, cmsg); // send code msg
				} else
					dbg("...got code ack");
			} else if (m.amType() == StateMsg.AM_TYPE) {
				dbg("received state...");
				mote.send(0, amsg); // send ack
			} else if (m.amType() == CodeMsg.AM_TYPE) {
				dbg("received code...");
				mote.send(0, amsg); 
				if (++round > 0)
					System.out.println(round + "\t" + (length/1000000.0));
				if (round < NUM_ROUNDS)
					doBenchmark();				
			}
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	private static final void printUsage() {
		System.err.println("Usage: InAndOut -comm <comm settings>");
		System.err.println("\t<comm settings> defaults to COM1:115200");
	}
	
	public static final void main(String[] args) throws Exception {
		try {
			for (int i = 0; i < args.length; i++) {
				if (args[i].toLowerCase().equals("-comm"))
				  source = args[++i];
				else if (args[i].toLowerCase().equals("-group"))
				  group_id = Integer.valueOf(args[++i]).intValue();
			}
		} catch(Exception e) {
			printUsage();
		}
		new InAndOut();
	}
	
	private void dbg(String msg) {
		//System.err.println(msg);
	}
}

