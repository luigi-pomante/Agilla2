package directory;

import agilla.variables.*;
import java.util.*;
import java.io.*;

public class TraceAnalyser {
	static int INTRUDER_AGENT_ID = 0;
	static int QUERIER_AGENT_ID = 1;
	
	static int NUM_INTRUDER_AGENTS = 10; // the number of intruder agents within the system
	
	static final int MAX_AGENT_NUM = 2; // max number of agents within a GetAgentsResults message.

	/**
	 *  These are the possible values of the "success" variable within
	 *  a QUERY_GET_LOCATION_RESULTS_RECEIVED traceline.
	 */
	public static final int INVALID = 1;
	public static final int VALID = 2;
	public static final int COARSE = 4;
	
	public static final int NO_ANSWER = 3;
	
	private boolean debug;
	private Vector<TraceLine> trace = new Vector<TraceLine>();
	private Hashtable<AgillaAgentID, AgillaLocation> agentLocTable = new Hashtable<AgillaAgentID, AgillaLocation>();
	private Hashtable<Integer, GetAgentsResults> getAgentsResultsTable = new Hashtable<Integer, GetAgentsResults>();
	
	public TraceAnalyser(String file, boolean debug) throws Exception {		
		this.debug = debug;
		
		// Read in the data
		File f = new File(file);
		BufferedReader reader = new BufferedReader(new FileReader(f));			
		String nextLine = reader.readLine();
		while (nextLine != null) {
			if (nextLine.startsWith("TRACE:"))
				trace.add(new TraceLine(nextLine));
			else if (nextLine.startsWith("TRACE_GET_AGENTS"))
				trace.add(new TraceLineGetAgents(nextLine));
			nextLine = reader.readLine();
		}
		Collections.sort(trace);
		
//		log("Sorted trace: ");
//		for (int i = 0; i < trace.size(); i++)
//			log(trace.get(i).toString());
		analyze();
	}
	
	private void analyze() {		
		
		int numRcvdAccurate = 0, numRcvdInaccurate = 0, numDontKnow = 0, numNoAns = 0; //, numErrors = 0;
		int numQueryMessages = 0, numResultsMessages = 0, numLocationUpdateMessages = 0, numCoarse = 0;
		double errorSum = 0;
		
		// Find out the number of erroneous location lookups
		for (int i = 0; i < trace.size(); i++) {
			TraceLine line = trace.get(i);
					
			if (line.action.equals("QUERY_GET_LOCATION_ISSUED") || 
					line.action.equals("QUERY_GET_LOCATION_FORWARDED") ||
					line.action.equals("QUERY_GET_CLOSEST_AGENT_ISSUED") ||
					line.action.equals("QUERY_GET_CLOSEST_AGENT_FORWARDED") ||
					line.action.equals("QUERY_GET_AGENTS_ISSUED") ||
					line.action.equals("QUERY_GET_AGENTS_FORWARDED")) 
			{
				numQueryMessages++;
			}
			
			if (line.action.equals("QUERY_GET_LOCATION_RESULTS_FORWARDED") ||
					line.action.equals("QUERY_GET_LOCATION_RESULTS_RECEIVED") ||
					line.action.equals("QUERY_GET_CLOSEST_AGENT_RESULTS_FORWARDED") ||
					line.action.equals("QUERY_GET_CLOSEST_AGENT_RESULTS_RECEIVED") ||
					line.action.equals("QUERY_GET_AGENTS_RESULT_RECEIVED") ||
					line.action.equals("QUERY_GET_AGENTS_RESULTS_FORWARDED")) 
			{
				numResultsMessages++;
				
			}
			
			if (line.action.equals("AGENT_LOCATION_SENT")) 
			{
				numLocationUpdateMessages++;
			}
			
			if (line.action.equals("AGENT_MOVED")) 
			{						
				AgillaAgentID key = new AgillaAgentID(line.agentID);
				if (agentLocTable.containsKey(key))
					agentLocTable.remove(key);
				agentLocTable.put(key,line.loc);
				
//				if (line.agentID == INTRUDER_AGENT_ID) {
//					if (intruderLoc != null) {
//						if (Math.abs(intruderLoc.getx() - line.loc.getx()) > 1 || Math.abs(intruderLoc.gety() - line.loc.gety()) > 1) {
//							System.err.println("ERROR: intruder made an illegal move from (" + intruderLoc.getx() + ", " + intruderLoc.gety() + ") to (" + line.loc.getx() + ", " + line.loc.gety() + ")");
//							numErrors++;
//						}
//					}
//					
//					intruderLoc = line.loc;
//				} else {					
//					if(querierLoc != null) {
//						if (Math.abs(querierLoc.getx() - line.loc.getx()) > 1 || Math.abs(querierLoc.gety() - line.loc.gety()) > 1) {
//							System.err.println("ERROR: querier made an illegal move from (" + querierLoc.getx() + ", " + querierLoc.gety() + ") to (" + line.loc.getx() + ", " + line.loc.gety() + ")");
//							numErrors++;
//						}
//					}
//					querierLoc = line.loc;
//				}
			}
			
			if (line.action.equals("QUERY_GET_LOCATION_RESULTS_RECEIVED")) {
				if (line.agentID == QUERIER_AGENT_ID) {
					if (line.success == NO_ANSWER) {									
						log(line.timeStamp + " Qid: " + line.qid + " Result contained FAIL");
						numNoAns++;
												
					} else if ((line.success & INVALID) > 0) {
						numDontKnow++;
					} else if ((line.success & VALID) > 0) {
						AgillaLocation intruderLoc = agentLocTable.get(new AgillaAgentID(INTRUDER_AGENT_ID));
						if (line.loc.equals(intruderLoc))
							numRcvdAccurate++;
						else {
							log(line.timeStamp +" Qid: " + line.qid + " Bad Result: (" + line.loc.getx() + ", " + line.loc.gety() + "), Reality: (" + intruderLoc.getx() + ", " + intruderLoc.gety()  + "), Dist: " + line.loc.dist(intruderLoc));
							numRcvdInaccurate++;
							errorSum += line.loc.dist(intruderLoc);
						}
						if ((line.success & COARSE) > 0) {
							numCoarse++;
						}
					}
				}
			}
			
//			if (line.action.equals("QUERY_GET_CLOSEST_AGENT_RESULTS_RECEIVED")) {
//				if (line.agentID == QUERIER_AGENT_ID) {	
//					if (line.success == 1) {						
//						AgillaLocation qLoc = agentLocTable.get(new AgillaAgentID(QUERIER_AGENT_ID));
//						
//						// Check to see whether there is an agent at the specified location
//						if (agentLocTable.containsValue(line.loc)) {							
//							double closestDist = qLoc.dist(line.loc);
//							
//							// See if there are any agents closer to the specified agent
//							AgillaLocation closestNode = findClosestAgent(qLoc);
//							if (closestNode.dist(qLoc) < closestDist) {
//								log("Detected a bad GetClosestAgent result:");
//								log("\tQuerier location: " + qLoc);
//								log("\tReported closest agent location: " + line.loc + " (" + closestDist + ")");
//								log("\tEven closer agent at: (" + closestNode.getx() + ", " + closestNode.gety() + "), dist = " + closestNode.dist(qLoc));
//								numBadQueries++;
//								errorSum += closestDist - closestNode.dist(qLoc);
//							} else {
//								numGoodQueries++;								
//							}
//						} else {
//							log(line.timeStamp + " GetClosestAgent returned (" + line.loc.getx() + ", " + 
//									line.loc.gety() + ") at which there is no agent.");
//							AgillaLocation closestAgent = findClosestAgent(qLoc);
//							double error = Math.abs(qLoc.dist(line.loc) - qLoc.dist(closestAgent));
//							log("\tError amount: " + error);
//							numBadQueries++;
//							errorSum += error;
//						}
//					} else
//						numFailedQueries++;
//				}
//			}
			
//			if (line.action.equals("QUERY_GET_AGENTS_ISSUED")) {
//				Integer qid = new Integer(line.qid);
//				if (!getAgentsResultsTable.containsKey(qid)) {
//					getAgentsResultsTable.put(qid, new GetAgentsResults(line.qid));
//				}				
//			}
			
//			if (line.action.equals("QUERY_GET_AGENTS_RESULT_RECEIVED_DATA")) {
//				if (line.agentID == QUERIER_AGENT_ID) {
//					TraceLineGetAgents currLine = (TraceLineGetAgents)line;
//					Integer qid = new Integer(currLine.qid);
//					
//					// Create a GetAgentsResults object for storing the results
//					// if one does not already exist.
//					if (!getAgentsResultsTable.containsKey(qid)) {
//						//getAgentsResultsTable.put(qid, new GetAgentsResults(currLine.qid));
//						System.err.println("ERROR: Received GET_AGENTS data without first receiving an ISSUED command.");
//						System.exit(1);
//					}
//					
//					
//					GetAgentsResults result = getAgentsResultsTable.get(qid);
//					if (result != null) {
//						int count = currLine.numAgents;
//						if (count > MAX_AGENT_NUM)
//							count = MAX_AGENT_NUM;
//						for (int j = 0; j < count; j++) {
//							AgillaAgentID aID = currLine.agentids.get(j);
//							AgillaLocation loc = currLine.agentLocs.get(j);
//							AgillaLocation actualLoc = agentLocTable.get(aID);
//							if (actualLoc == null) {
//								System.err.println("ERROR: could not get location of agent " + aID);
//								System.exit(0);
//							}
//							result.add(new GetAgentsResultsEntry(aID, loc, actualLoc));
//						}					
//					} else
//						log("ERROR: could not get GetAgentsResults message for qid = " + qid);
//					
//				}
//			}				
			
		}
		
//		log("getAgentsResultsTable.size() = " + getAgentsResultsTable.size());
//		// Analyze the results of the GetAgents Query
//		for (Enumeration<GetAgentsResults> e = getAgentsResultsTable.elements(); e.hasMoreElements();) {
//			GetAgentsResults result = e.nextElement();
//			
//			if (result.numResults() == 0)
//				numFailedQueries++;
//			else if (result.numResults() != NUM_INTRUDER_AGENTS || result.errorSum() != 0) {
//				//System.out.println("result.numResults() = " + result.numResults());
//				//System.out.println("NUM_INTRUDER_AGENTS = " + NUM_INTRUDER_AGENTS);
//				//System.out.println("result.errorSum() = " + result.errorSum());
//				numBadQueries++;
//			} else
//				numGoodQueries++;
//			
//			errorSum += result.errorSum();			
//		}
		
//		System.out.println("\nQuery Statistics:  Good: " + numGoodQueries + ", Bad: " + numBadQueries + ", Failed: " + numFailedQueries);
//		System.out.println("Total Number of Queries: " + (numGoodQueries + numBadQueries + numFailedQueries));
		System.out.println("\nQuery Statistics:  Accurate: " + numRcvdAccurate+ ", Inaccurate: " + numRcvdInaccurate 
				+ ", Unknown: " + numDontKnow + ", Timeout: " + numNoAns);
		System.out.println("Number of Query Messages: " + numQueryMessages);
		System.out.println("Number of Results Messages: " + numResultsMessages);
		System.out.println("Number of Location Update Messages: " + numLocationUpdateMessages);
		System.out.println("Average Error: " + (numRcvdInaccurate == 0 ? 0 : errorSum/numRcvdInaccurate));
		System.out.println("Number of Coarse Results: " + numCoarse);
//		System.out.println("Overall Average Error (hops): " + ((numGoodQueries+numBadQueries) == 0 ? 0 : errorSum/(numGoodQueries+numBadQueries)));
//		System.out.println("Average Error (hops): " + (numBadQueries == 0 ? 0 : errorSum/numBadQueries));
		//System.out.println("Number of Errors: " + numErrors);
	}
	
	/**
	 * This class stores the results of a GetAgents operation.
	 * 
	 * @author liang	 
	 */
	private class GetAgentsResults {
		int qid;
		Vector<GetAgentsResultsEntry> results = new Vector<GetAgentsResultsEntry>();
		
		public GetAgentsResults(int qid) {
			this.qid = qid;
		}
		
		public void add(GetAgentsResultsEntry entry) {
			results.add(entry);
		}
		
		public int numResults() {
			return results.size();
		}
		
		public double errorSum() {
			double result = 0;
			for (Enumeration<GetAgentsResultsEntry> e = results.elements(); e.hasMoreElements();) {
				GetAgentsResultsEntry entry = e.nextElement();
				result += entry.error();
			}
			return result;
		}
	}
	
	private class GetAgentsResultsEntry {
		AgillaAgentID aID;
		AgillaLocation reportedLocation, actualLocation;
		
		public GetAgentsResultsEntry(AgillaAgentID aID, AgillaLocation reportedLocation, AgillaLocation actualLocation) {
			this.aID = aID;
			this.reportedLocation = reportedLocation;
			this.actualLocation = actualLocation;
		}
		
		public double error() {
			return reportedLocation.dist(actualLocation);
		}
	}
	
	/**
	 * Finds the location of the agent closest to the specified location.
	 * 
	 * @param qLoc The relative location.
	 * @return The location closest to qLoc.
	 */
	private AgillaLocation findClosestAgent(AgillaLocation qLoc) {
		AgillaLocation closestLoc = null;
		double dist = 0;
		
		for (Enumeration<AgillaAgentID> keys = agentLocTable.keys(); keys.hasMoreElements();) {
			AgillaAgentID aid = keys.nextElement();
			if (aid.getID() != QUERIER_AGENT_ID) {
				AgillaLocation currLoc = agentLocTable.get(aid); 
				if (closestLoc == null) {
					closestLoc = currLoc;
					dist = currLoc.dist(qLoc);
				} else if (currLoc.dist(qLoc) < dist) {
					closestLoc = currLoc;
					dist = currLoc.dist(qLoc);
				}
			}
		}		
		return closestLoc;
	}
	
	private class TraceLine implements Comparable<TraceLine> {
		long timeStamp;
		int agentID, nodeID, qid;
		String action; 
		int success;
		AgillaLocation loc;
		
		public TraceLine() {		
		}
		
		public TraceLine(String line) {
			int sIndex = line.indexOf(" ");
			int eIndex = line.indexOf(" ", sIndex+1);
			agentID = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("agentID = " + agentID);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			nodeID = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("nodeID = " + nodeID);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			timeStamp = Long.valueOf(line.substring(sIndex+1, eIndex));
			//log("timeStamp = " + timeStamp);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			action = line.substring(sIndex+1, eIndex);
			//log("action = " + action);

			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			qid = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("qid = " + qid);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			success = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("success = " + success);
			
			int x, y;
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			x = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("x = " + x);
			
			sIndex = eIndex;
			y = Integer.valueOf(line.substring(sIndex+1));
			loc = new AgillaLocation(x,y);
			//log("y = " + y + "\n");
		}
		
		public int compareTo(TraceLine o) {
			if (this.timeStamp < o.timeStamp)
				return -1;
			else if (this.timeStamp == o.timeStamp)
				return 0;
			else
				return 1;
		}
		
		public String toString() {
			return "TRACE: " + agentID + " " + nodeID + " " + timeStamp + " " +  
				action + " " + qid + " " + success + " " + 
				loc.getx() + " " + loc.gety();
		}
	} // TraceLine
	
	private class TraceLineGetAgents extends TraceLine 
	{
		int numAgents;
		Vector<AgillaAgentID> agentids = new Vector<AgillaAgentID>();
		Vector<AgillaLocation> agentLocs = new Vector<AgillaLocation>();
		
		public TraceLineGetAgents(String line) 
		{
//			System.out.println("TraceLineGetAgents: " + line);
			
			int sIndex = line.indexOf(" ");
			int eIndex = line.indexOf(" ", sIndex+1);
			agentID = Integer.valueOf(line.substring(sIndex+1, eIndex));
//			log("agentID = " + agentID);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			nodeID = Integer.valueOf(line.substring(sIndex+1, eIndex));
//			log("nodeID = " + nodeID);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			timeStamp = Long.valueOf(line.substring(sIndex+1, eIndex));
//			log("timeStamp = " + timeStamp);
						
			action = "QUERY_GET_AGENTS_RESULT_RECEIVED_DATA";
//			log("action = " + action);

			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			qid = Integer.valueOf(line.substring(sIndex+1, eIndex));
//			log("qid = " + qid);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			numAgents = Integer.valueOf(line.substring(sIndex+1, eIndex));
//			log("numAgents = " + numAgents);
			
			int count = numAgents;
			if (count > MAX_AGENT_NUM)
				count = MAX_AGENT_NUM;
			
//			log("count = " + count);
			
			for (int i = 0; i < count; i++) 
			{
				int id, x, y;
				sIndex = eIndex;
				eIndex = line.indexOf(" ", sIndex+1);
				id = Integer.valueOf(line.substring(sIndex+1, eIndex));
				
				sIndex = eIndex;
				eIndex = line.indexOf(" ", sIndex+1);
				x = Integer.valueOf(line.substring(sIndex+1, eIndex));
								
				sIndex = eIndex;
				eIndex = line.indexOf(" ", sIndex+1);
				System.out.println("sIndex = " + sIndex + ", eIndex = " + eIndex);
				if (eIndex < 0)
					y = Integer.valueOf(line.substring(sIndex+1));
				else
					y = Integer.valueOf(line.substring(sIndex+1, eIndex));
				agentids.add(new AgillaAgentID(id));
				agentLocs.add(new AgillaLocation(x,y));
			}
//			int x, y;
//			sIndex = eIndex;
//			eIndex = line.indexOf(" ", sIndex+1);
//			x = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("x = " + x);
			
//			sIndex = eIndex;
//			y = Integer.valueOf(line.substring(sIndex+1));
//			loc = new AgillaLocation(x,y);
			//log("y = " + y + "\n");
			
//			String logme = ("TRACE_GET_AGENTS: " + trace.get_agentID() + " " + trace.get_nodeID() + " "
//					+ trace.get_timestamp_high32() + "" + trace.get_timestamp_low32() + " "
//					+ trace.get_qid() + " " + trace.get_num_agents() + " ");
//			for (int i = 0; i < trace.get_num_agents(); i++) {
//				logme += trace.getElement_agent_id_id(i) + " " + trace.getElement_loc_x(i) + " " + trace.getElement_loc_y(i);
//			}
		}
		
		public String toString() {
			String result = "TRACE: " + agentID + " " + nodeID + " " + timeStamp + " " +  action + " " + qid + " " + numAgents;
			for (int i = 0; i < agentids.size(); i++) {				
				result += " " + agentids.get(i).getID() + " " + agentLocs.get(i).getx() + " " + agentLocs.get(i).gety(); 
			}
			return result;
		}
	}
	private void log(String msg) {
		if (debug)
			System.out.println(msg);
	}
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		String file = null;
		boolean debug = false;
		
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
				} else if (arg.equals("-f")) {
					index++;
					file = args[index];
				} else if (arg.equals("-d")) {
					debug = true;
				} else if (arg.equals("-i")) {
					INTRUDER_AGENT_ID = Integer.valueOf(args[++index]);
				} else if (arg.equals("-q")) {
					QUERIER_AGENT_ID = Integer.valueOf(args[++index]); 
				} else if (arg.equals("-n")) {
					NUM_INTRUDER_AGENTS = Integer.valueOf(args[++index]);
				} else {
					System.err.println("Unknown argument \"" + arg + "\"");
					usage();
					System.exit(1);
				}
				index++;
			}
			if (file == null)
				throw new Exception();
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		try {
			new TraceAnalyser(file, debug);
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	private static void usage() {
		System.err.println("Usage: TraceAnalyser [-h | -d | -q <num> | -i <num> | -n <num> | -f <file>]");
		System.err.println("\t-h Print this help message");
		System.err.println("\t-d Enable Debug mode");
		System.err.println("\t-i <num> AgentID of intruder");		
		System.err.println("\t-q <num> AgentID of querier");		
		System.err.println("\t-n <num> Number of agents (used by GetAgents)");
		System.err.println("\t-f <file> Where <file> is contains the experiment trace data.");		
	}
}
