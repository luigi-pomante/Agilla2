package agilla;

import java.util.Vector;

public class QueryNeighborList implements AgillaConstants {
	private SNInterface sni;
	
	public QueryNeighborList(String source, boolean debug) throws Exception {
		AgentInjector injector = new AgentInjector(source, debug);
		
		Vector nbrs = injector.queryNbrList(TOS_BCAST_ADDRESS, (short)1);
		
		if (nbrs.size() != 0) {
			String nbrString = "\nAddress\t\tHops To Gateway\t\tLink Quality\n";
			for (int i = 0; i < nbrs.size(); i++) {
				Address addr = (Address)nbrs.get(i);
				nbrString += addr.addr() + "\t\t" + addr.hopsToGW() + "\t\t\t" + addr.lqi();
				if (i < nbrs.size()-1)
					nbrString += "\n";
			}		    
			System.out.println(nbrString);
		} else {
		    System.out.println("No neighbors!");
		}
		System.exit(0);
	}
	
	public static void main(String[] args) {
		String source = "COM1:mica2"; //"sf@localhost:9001";
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
				} else if (arg.equals("-comm")) {
					index++;
					source = args[index];
				}else if (arg.equals("-d")) {
					debug = true;
				} else {
					usage();
					System.exit(1);
				}
				index++;
			}			
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		System.out.println("Connecting to: " + source);
		try {
			new QueryNeighborList(source, debug);
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	private static void usage() {
		System.err.println("Usage: QueryNeithborList [-h | -comm <source> | -d]");
		System.err.println("\t-h Print this help message");
		System.err.println("\t-d Enable Debug mode");
		System.err.println("\t-comm <source> where <source> is COMx:[platform], sf@localhost:[port]");		
	}

}
