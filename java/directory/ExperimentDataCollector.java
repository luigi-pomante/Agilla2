package directory;

import java.awt.BorderLayout;
import java.awt.event.ActionEvent;
import java.util.*;
import java.io.*;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;

import agilla.AgillaConstants;
import agilla.messages.*;

import net.tinyos.message.*;
import net.tinyos.packet.BuildSource;
import net.tinyos.util.PrintStreamMessenger;

public class ExperimentDataCollector implements AgillaConstants {
	public static final int AGENT_MOVED   = 0;
	public static final int QUERY_GET_LOCATION_ISSUED  = 1;
	public static final int QUERY_GET_LOCATION_RESULTS_RECEIVED = 2;
	public static final int QUERY_GET_LOCATION_FORWARDED = 3;
	public static final int QUERY_GET_LOCATION_RESULTS_FORWARDED = 4;
	public static final int SET_CLUSTER_HEAD = 5;
	public static final int AGENT_MIGRATING = 6;
	public static final int QUERY_GET_CLOSEST_AGENT_ISSUED = 7; 
	public static final int QUERY_GET_CLOSEST_AGENT_RESULTS_RECEIVED = 8;	 
	public static final int CLUSTER_AGENT_ADDED = 9;
	public static final int CLUSTER_AGENT_REMOVED = 10;
	public static final int CLUSTER_AGENT_CLEARED = 11;
	public static final int CLUSTERHEAD_DIRECTORY_STARTED = 12;
	public static final int CLUSTERHEAD_DIRECTORY_STOPPED = 13;
	public static final int AGENT_LOCATION_SENT = 14;
	public static final int QUERY_GET_CLOSEST_AGENT_FORWARDED = 15;
	public static final int QUERY_GET_CLOSEST_AGENT_RESULTS_FORWARDED = 16;
	public static final int QUERY_GET_AGENTS_ISSUED = 17;
	public static final int QUERY_GET_AGENTS_RESULT_RECEIVED = 18;
	public static final int QUERY_GET_AGENTS_FORWARDED = 19;
	public static final int QUERY_GET_AGENTS_RESULTS_FORWARDED = 20;
	public static final int SENDING_AGENT_LOCATION = 21;
	public static final int CLUSTER_AGENT_UPDATED = 22;
	
	
	public static final int MAX_NUM_QUERIES = 50;  // how many queries to wait for before stopping experiment
	public static final int GATEWAY_PORT = 9001;
	
	private boolean debug;
	private Vector<Mote> motes = new Vector<Mote>();	
	private TraceReceiver traceRcvr = new TraceReceiver();
	private int numQs = 0;
	private JFrame frame;
	private JLabel resultCountLabel;
	
	public ExperimentDataCollector(int[] ports, boolean debug) {
		this.debug = debug;				
		
		for (int i = 0; i < ports.length; i++) {
			String source = "sf@localhost:" + ports[i];
			log("Connecting to " + source);
			MoteIF moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
			Mote mote = new Mote(ports[i], moteIF);			
			moteIF.registerListener(new AgillaExpLatencyMsg(), mote);
//			moteIF.registerListener(new AgillaExpResultsMsg(), mote);
			moteIF.registerListener(new AgillaTraceMsg(), traceRcvr);
			moteIF.registerListener(new AgillaTraceGetAgentsMsg(), traceRcvr);
			motes.add(mote);
		}		
		createGUI();
	}
	
/*	public ExperimentDataCollector(int port, boolean debug) {
		this.debug(debug);
		String source = "sf@localhost:" + ports[i];
		MoteIF moteIF = new MoteIF(BuildSource.makePhoenix(source), PrintStreamMessenger.err));
		Mote mote = new Mote(ports[i], moteIF);
		
	}*/

	/**
	 *  Gather all of the data from the experiment and print them to StdOut.
	 */
	private void doFinish() {
		// for each mote, get the number of queries and updates
		//int totalNumQueries = 0, totalNumUpdates = 0;
		long totalLatencies = 0, totalLatenciesCount = 0;
		
		// stop receiving trace messages
		for (int i = 0; i < motes.size(); i++) {
			Mote c = motes.get(i);
			c.moteIF.deregisterListener(new AgillaTraceMsg(), traceRcvr);
		}

		for (int i = 0; i < motes.size(); i++) {
			Mote c = motes.get(i);
			if (c.tcpPort != GATEWAY_PORT) {
				//c.fetchResults();
				if (c.hasLatencies())
					System.out.println(c);
				//totalNumQueries += c.numQueries;
				//totalNumUpdates += c.numUpdates;
				totalLatencies += c.totalLatency();
				totalLatenciesCount += c.numLatencies();
			}
		}
		
		System.out.println("-------- Overall Results --------");
		//System.out.println("Total Number of Queries: " + totalNumQueries);
		//System.out.println("Total Number of Updates: " + totalNumUpdates);
		System.out.println("Average Query Latency (us): " + (totalLatenciesCount == 0 ? "NaN" : totalLatencies/totalLatenciesCount));		
		System.exit(0);
	}
	
	private void createGUI() {				
		JButton button = new JButton("Stop");
		button.addActionListener(new java.awt.event.ActionListener() {
			public void actionPerformed(ActionEvent ae) {
				doFinish();
			}
		});
		frame = new JFrame();
		frame.setTitle("Exp Data Collector");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.add(button, java.awt.BorderLayout.CENTER);
		resultCountLabel = new JLabel("0");
		frame.add(resultCountLabel, BorderLayout.SOUTH);
		frame.pack();
		frame.setVisible(true);
	}
	
	/**
	 *  Receives trace messages and prints them to the screen.  The text can then
	 *  be piped into a file that can be analyzed using TraceAnalyser.
	 *  
	 * @author liang	 
	 */
	private class TraceReceiver implements MessageListener {		
		public TraceReceiver() {
		}
				
		private String convString(int action) {
			switch(action) {
			case AGENT_MOVED:
				return "AGENT_MOVED";
			case QUERY_GET_LOCATION_ISSUED:
				return "QUERY_GET_LOCATION_ISSUED";
			case QUERY_GET_LOCATION_RESULTS_RECEIVED:
				return "QUERY_GET_LOCATION_RESULTS_RECEIVED";
			case QUERY_GET_LOCATION_FORWARDED :
				return "QUERY_GET_LOCATION_FORWARDED";
			case QUERY_GET_LOCATION_RESULTS_FORWARDED:
				return "QUERY_GET_LOCATION_RESULTS_FORWARDED";
			case SET_CLUSTER_HEAD:
				return "SET_CLUSTER_HEAD";
			case AGENT_MIGRATING:
				return "AGENT_MIGRATING";		
			case QUERY_GET_CLOSEST_AGENT_ISSUED:
				return "QUERY_GET_CLOSEST_AGENT_ISSUED";
			case QUERY_GET_CLOSEST_AGENT_RESULTS_RECEIVED:
				return "QUERY_GET_CLOSEST_AGENT_RESULTS_RECEIVED";
			case CLUSTER_AGENT_ADDED:
				return "CLUSTER_AGENT_ADDED";
			case CLUSTER_AGENT_REMOVED:
				return "CLUSTER_AGENT_REMOVED";
			case CLUSTER_AGENT_CLEARED:
				return "CLUSTER_AGENT_CLEARED";
			case CLUSTERHEAD_DIRECTORY_STARTED:
				return "CLUSTERHEAD_DIRECTORY_STARTED";
			case CLUSTERHEAD_DIRECTORY_STOPPED:
				return "CLUSTERHEAD_DIRECTORY_STOPPED";
			case AGENT_LOCATION_SENT:
				return "AGENT_LOCATION_SENT";
			case QUERY_GET_CLOSEST_AGENT_FORWARDED:
				return "QUERY_GET_CLOSEST_AGENT_FORWARDED";
			case QUERY_GET_CLOSEST_AGENT_RESULTS_FORWARDED:
				return "QUERY_GET_CLOSEST_AGENT_RESULTS_FORWARDED";
			case QUERY_GET_AGENTS_ISSUED:
				return "QUERY_GET_AGENTS_ISSUED";
			case QUERY_GET_AGENTS_RESULT_RECEIVED:
				return "QUERY_GET_AGENTS_RESULT_RECEIVED";
			case QUERY_GET_AGENTS_FORWARDED:
				return "QUERY_GET_AGENTS_FORWARDED";
			case QUERY_GET_AGENTS_RESULTS_FORWARDED:
				return "QUERY_GET_AGENTS_RESULTS_FORWARDED";
			case SENDING_AGENT_LOCATION:
				return "SENDING_AGENT_LOCATION";
			case CLUSTER_AGENT_UPDATED:
				return "CLUSTER_AGENT_UPDATED";
			}
			return "UNKNOWN";
		}
		
		public void messageReceived(int to, Message m) {			
			
			if (m.amType() == AgillaTraceMsg.AM_TYPE)
			{
				AgillaTraceMsg trace = (AgillaTraceMsg)m;									
				
				if (trace.get_agentID() > 1000) {					
					System.out.println("*** TRACE: " + trace.get_agentID() + " " + trace.get_nodeID() + " "
							+ trace.get_timestamp_high32() + "" + trace.get_timestamp_low32() + " "
							+ convString(trace.get_action()) + " " + trace.get_qid() + " " + trace.get_success() + " " 
							+ trace.get_loc_x()+ " " + trace.get_loc_y() + " ***");					
				} else
					System.out.println("TRACE: " + trace.get_agentID() + " " + trace.get_nodeID() + " "
							+ trace.get_timestamp_high32() + "" + trace.get_timestamp_low32() + " "
							+ convString(trace.get_action()) + " " + trace.get_qid() + " " + trace.get_success() + " " 
							+ trace.get_loc_x()+ " " + trace.get_loc_y());
				
				// Stop the experiment after MAX_NUM_QUERIES has been performed
				if (trace.get_action() == QUERY_GET_LOCATION_RESULTS_RECEIVED
						|| trace.get_action() == QUERY_GET_CLOSEST_AGENT_RESULTS_RECEIVED
						|| trace.get_action() == QUERY_GET_AGENTS_RESULT_RECEIVED) {
					if (++numQs == MAX_NUM_QUERIES) {
						frame.setVisible(false);
						doFinish();
					} else
						resultCountLabel.setText("" + numQs);
				}
			} else
			{
				AgillaTraceGetAgentsMsg trace = (AgillaTraceGetAgentsMsg)m;
				String logme = ("TRACE_GET_AGENTS: " + trace.get_agentID() + " " + trace.get_nodeID() + " "
						+ trace.get_timestamp_high32() + "" + trace.get_timestamp_low32() + " "
						+ trace.get_qid() + " " + trace.get_num_agents());
				int numResults = trace.get_num_agents();
				if (numResults > TraceAnalyser.MAX_AGENT_NUM)
					numResults = TraceAnalyser.MAX_AGENT_NUM;
				for (int i = 0; i < numResults; i++) {
					logme += " " + trace.getElement_agent_id_id(i) + " " + trace.getElement_loc_x(i) 
						+ " " + trace.getElement_loc_y(i);
				}
				System.out.println(logme);
			}
		}		
	}
	
	/**
	 * Keeps track of the statistics for a single mote.
	 * 
	 * @author liang	 
	 */
	private class Mote implements MessageListener  {
		int tcpPort;
		//int numQueries;
		//int numUpdates;
		MoteIF moteIF;
		Vector<AgillaExpLatencyMsgJ> latencies = new Vector<AgillaExpLatencyMsgJ>();
		//Object lock = new Object();
		//boolean gotResults = false;
		//FetchResultsTimer timer = null;
		
		public Mote(int tcpPort, MoteIF moteIF) {
			this.tcpPort = tcpPort;
			this.moteIF = moteIF;
		}
		
		public boolean hasLatencies() {
			return latencies.size() != 0;
		}
		
		public void messageReceived(int to, Message m) {
			if (m instanceof AgillaExpLatencyMsg) {				
				AgillaExpLatencyMsg ajm = (AgillaExpLatencyMsg)m;
				AgillaExpLatencyMsgJ msgj = new AgillaExpLatencyMsgJ(ajm);
				//log("Port " + tcpPort + ": Latency " + msgj);
				log("Port " + tcpPort + ": Latency " + ajm.get_latency() + " " + msgj);
				latencies.add(msgj);
			} 
			/*else if (m instanceof AgillaExpResultsMsg) {
				synchronized(lock) {
					numQueries = ((AgillaExpResultsMsg)m).get_numQueries();
					numUpdates = ((AgillaExpResultsMsg)m).get_numUpdates();
					log("\tnumQueries = " + numQueries + ", numUpdates = " + numUpdates);
					gotResults = true;
					if (timer != null) {
						timer.kill();
						timer = null;
					}
					lock.notify();
				}
			}*/		
		}
		
		/*public void fetchResults() {
			gotResults = false;
			int numTries = 0;
			while (!gotResults && numTries++ < 5) {
				try {				
					synchronized(lock) {
						System.out.println("Fetching results from TCP Port " + tcpPort + "...");
						moteIF.send(TOS_BCAST_ADDRESS, new AgillaExpQueryResultsMsg());
						timer = new FetchResultsTimer(lock);
						try {
							lock.wait();
						} catch(InterruptedException e) {
							e.printStackTrace();
						}
						if (!gotResults)
							log("Did not get results, trying again...");
					}
				} catch(IOException ioe) {
					ioe.printStackTrace();
				}
			}
			if (!gotResults) {
				System.out.println("Failed to get results from TCP Port " + tcpPort + ".");
				numQueries = numUpdates = 0;
			}
		}
		
		private class FetchResultsTimer implements Runnable {
			private static final int FETCH_RESULTS_TIMER = 2000;
			private Object lock;
			private boolean alive = true;
			
			public FetchResultsTimer(Object lock) {
			    this.lock = lock;
			    new Thread(this).start();
			}
			
			public void kill() {
				synchronized(lock) {
					alive = false;
				}
			}
			
			public void run () {
			    try {
					Thread.sleep(FETCH_RESULTS_TIMER);
			    } catch(Exception e) {
					e.printStackTrace();
			    }
			    synchronized(lock) {
			    	if (alive) lock.notify();				
			    }
			}
		}*/
		
		public int numLatencies() {
			return latencies.size();
		}
		
		public long totalLatency() {
			long result = 0;
			if (latencies.size() == 0)
				return 0;
			for (int i = 0; i < latencies.size(); i++) {
				result += latencies.get(i).latency();
			}
			return result;
		}
		
		public long avgLatency() {
			return totalLatency() / numLatencies();
		}
		
		public String printLatencies() {
			String result = "";
			for (int i = 0; i < latencies.size(); i++) {
				result += latencies.get(i) + " ";
			}
			return result;
		}
		
		public String toString() {
			return "Latencies from mote attached to TCP Port " + tcpPort + /*", numQueries = " + numQueries + ", numUpdates = " + numUpdates +*/ "\n" + printLatencies();
		}
	}
	
	private void log(String msg) {
		if (debug)
			System.out.println("ExpDataCollector: " + msg);
	}
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		boolean debug = false;
		Vector<String> portStrings = new Vector<String>();

		if (args.length == 0) {
			usage();
			System.exit(0);
		}
					
		try {
			int index = 0;
			while (index < args.length) {
				String arg = args[index];
				if (arg.equals("-h") || arg.equals("--help")) {
					usage();
					System.exit(0);
				} else if (arg.equals("-p")) {
					index++;
					while (index < args.length) {
						portStrings.add(args[index++]);
					}
					//numMotes = Integer.valueOf(args[index]);
				}else if (arg.equals("-d")) {
					debug = true;
				} else {
					usage();
					System.exit(1);
				}
				index++;
			}			
			if (portStrings.size() == 0)
				throw new Exception();
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		int ports[] = new int[portStrings.size()];
		for (int i = 0; i < portStrings.size(); i++) {
			ports[i] = Integer.valueOf(portStrings.get(i));
		}
		
		try {
			new ExperimentDataCollector(ports, debug);
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	private static void usage() {
		System.err.println("Usage: ExperimentDataCollector [-h | -d | -p ports]");
		System.err.println("\t-h Print this help message");
		System.err.println("\t-d Enable Debug mode");		
		System.err.println("\tports A list of TCP ports to connect to.");		
	}
}
