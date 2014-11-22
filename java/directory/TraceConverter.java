package directory;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

import agilla.variables.AgillaLocation;

public class TraceConverter {
	private boolean debug;	
	
	public TraceConverter(String file, boolean debug) throws Exception {		
		this.debug = debug;
		
		// Read in the data
		File f = new File(file);
		BufferedReader reader = new BufferedReader(new FileReader(f));			
		String nextLine = reader.readLine();
		while (nextLine != null) {
			log("Processing line " + nextLine);
			if (nextLine.startsWith("TRACE:"))
				System.out.println(new TraceLine(nextLine));
			else
				System.out.println(nextLine);
			nextLine = reader.readLine();
		}					
	}	
	
	private class TraceLine implements Comparable<TraceLine> {
		long timeStamp;
		int agentID, nodeID;
		String action; 
		boolean success;
		AgillaLocation loc;
		
		public TraceLine(String line) {
			int sIndex = line.indexOf(" ");
			int eIndex = line.indexOf(" ", sIndex+1);
			timeStamp = Long.valueOf(line.substring(sIndex+1, eIndex));
			//log("timeStamp = " + timeStamp);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			agentID = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("agentID = " + agentID);

			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			nodeID = Integer.valueOf(line.substring(sIndex+1, eIndex));
			//log("nodeID = " + nodeID);
						
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			action = line.substring(sIndex+1, eIndex);
			//log("action = " + action);
			
			sIndex = eIndex;
			eIndex = line.indexOf(" ", sIndex+1);
			success = (Integer.valueOf(line.substring(sIndex+1, eIndex)) == 1);
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
				action + " " + (success ? "1" : "0") + " " + 
				loc.getx() + " " + loc.gety();
		}
	} // TraceLine
	
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
			new TraceConverter(file, debug);
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	private static void usage() {
		System.err.println("Usage: TraceConverter [-h | -d | -q | -i | -f <file>]");
		System.err.println("\t-h Print this help message");
		System.err.println("\t-d Enable Debug mode");
		System.err.println("\t-f <file> Where <file> is contains the experiment trace data.");		
	}

}
