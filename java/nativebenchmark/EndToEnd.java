package nativebenchmark;

import java.io.*;
import java.net.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;

public class EndToEnd implements MessageListener, TCPListener {
	static int group_id = 7;
	static String source = "COM1:115200";
	static String address = "128.252.160.209";
	static int port = 4400;
	static int NUM_ROUNDS = 1000;
	static boolean master = false;

	private MoteIF mote;
	private CodeMsg cmsg;
	private StateMsg smsg;
	
	private int round = -2;
	private long stime;
	
	//private TCPMessageReceiver rcvr;
	private TCPMessageSender sndr;
	
	/**
	 * Initializes the frame.
	 * @throws IOException 
	 */
	public EndToEnd() throws IOException {

		try {
			mote = new MoteIF(BuildSource.makePhoenix(BuildSource.makeArgsSerial(source),net.tinyos.util.PrintStreamMessenger.err));
			//mote = new MoteIF(PrintStreamMessenger.err, group_id);
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(0);
		}
		smsg = new StateMsg();
		cmsg = new CodeMsg();
		
		mote.registerListener(new StateMsg(), this);
		mote.registerListener(new CodeMsg(), this);
		
		new TCPMessageReceiver(port, this);
		sndr = new TCPMessageSender(InetAddress.getByName(address), port);
		
		if (master) {
			try {
				Thread.sleep(1);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			doBenchmark();
		}
	}
	
	private void doBenchmark() {
		log("Sending local mote messages");
		stime = System.nanoTime();
		try {
			mote.send(0, smsg);
			mote.send(0, cmsg);
		} catch (IOException e) { 
			e.printStackTrace();
		}
	}
	
	// received from WSN
	public void messageReceived(int to, Message m) {
		try {
			if (m.amType() == CodeMsg.AM_TYPE) {
				logRcv("WSN: code");
				log("Sending remote host messages");
				sndr.sendMessage(smsg);
				sndr.sendMessage(cmsg);
			} else
				logRcv("WSN: state");
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	// received from IP network
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
			} else {
				logRcv("IP: state");
			}
		} else {			
			if (o instanceof CodeMsg) {
				logRcv("IP: code");
				doBenchmark();
			} else
				logRcv("IP: state");
		}
	}
	
	private void logRcv(String msg) {
		//System.out.println(msg);
	}
	
	private void log(String msg) {
		//System.out.println(msg);
	}
	
	private static final void printUsage() {
		System.err.println("Usage: InAndOut -comm <comm settings> -address <address> -port <port>");
		System.err.println("\t<comm settings> defaults to COM1:115200");
		System.err.println("\t<address> defaults to 128.252.160.209");
		System.err.println("\t<port> defaults to 4400");
	}
	
	public static final void main(String[] args) throws IOException {
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
		new EndToEnd();
	}
}

