package nativebenchmark;

import java.io.*;
import java.net.InetAddress;

import net.tinyos.message.*;
import net.tinyos.packet.*;

public class EndToEndAck implements MessageListener, TCPListener {
	static int group_id = 7;
	static String source = "COM1:115200";
	static int NUM_ROUNDS = 1000;
	static String address = "128.252.160.209";
	static int port = 4400;
	static boolean master = false;
	
	private MoteIF mote;
	private CodeMsg cmsg;
	private StateMsg smsg;
	private AckMsg amsg;
	
	private int round = -2;
	private long stime;
	private boolean sentState = false;
	
	private TCPMessageSender sndr;
	
	/**
	 * Initializes the frame.
	 * @throws IOException 
	 * @throws InterruptedException 
	 */
	public EndToEndAck() throws IOException, InterruptedException {

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
		
		new TCPMessageReceiver(port, this);
		sndr = new TCPMessageSender(InetAddress.getByName(address), port);
		
		mote.registerListener(new StateMsg(), this);
		mote.registerListener(new CodeMsg(), this);
		mote.registerListener(new AckMsg(), this);
		
		
		if (master) {
			Thread.sleep(1000);
			doBenchmark();
		}
		
	}
	
	private void doBenchmark() {		
		stime = System.nanoTime();
		sentState = true;
		dbg("sending state...");
		try {
			mote.send(0, smsg);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	// from WSN
	public void messageReceived(int to, Message m) {
		try {
			if (m.amType() == AckMsg.AM_TYPE) {
				if (sentState) {
					sentState = false;
					dbg("sending code...");
					mote.send(0, cmsg); // send code msg
				} else
					dbg("...got code ack...waiting for agent to come back");
			} else if (m.amType() == StateMsg.AM_TYPE) {
				dbg("received state...");
				mote.send(0, amsg); // send ack
			} else if (m.amType() == CodeMsg.AM_TYPE) {
				dbg("received code...");
				mote.send(0, amsg);  // send ack
				dbg("sending state and code over IP...");
				sndr.sendMessage(smsg);
				sndr.sendMessage(cmsg);
//				if (++round > 0)
//					System.out.println(round + "\t" + (length/1000000.0));
//				if (round < NUM_ROUNDS)
//					doBenchmark();				
			}
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	// from IP
	public void messageReceived(Object o) {
		long length = System.nanoTime() - stime;		
		if (master) {
			if (o instanceof CodeMsg) {		
				logRcv("IP: code");
				if (++round > 0)
					System.out.println(round + "\t" + (length/1000000.0));
				else
					logRcv("-----");
				if (round < NUM_ROUNDS)
					doBenchmark();				
				else {
					System.out.println("Done...");
					System.exit(0);
				}
			} else
				logRcv("IP: state");
		} else {			
			if (o instanceof CodeMsg) {
				logRcv("IP: code");
				doBenchmark();
			} else
				logRcv("IP: state");
		}
	
	}
	
	private static final void printUsage() {
		System.err.println("Usage: InAndOutAck -comm <comm settings> -address <address> -port <port>");
		System.err.println("\t<comm settings> defaults to COM1:115200");
		System.err.println("\t<address> defaults to 128.252.160.209");
		System.err.println("\t<port> defaults to 4400");
	}
	
	public static final void main(String[] args) throws Exception {
		try {
			for (int i = 0; i < args.length; i++) {
				if (args[i].toLowerCase().equals("-comm"))
				  source = args[++i];
				else if (args[i].toLowerCase().equals("-group"))
				  group_id = Integer.valueOf(args[++i]).intValue();
				else if (args[i].toLowerCase().equals("-address"))
					address = args[++i];
				else if (args[i].toLowerCase().equals("-port"))
					port = Integer.valueOf(args[++i]).intValue();	
				else if (args[i].toLowerCase().equals("-master"))
					master = true;
			}
		} catch(Exception e) {
			printUsage();
		}
		new EndToEndAck();
	}
	
	private void dbg(String msg) {
		//System.err.println(msg);
	}
	
	private void logRcv(String msg) {
		//System.out.println(msg);
	}
}

