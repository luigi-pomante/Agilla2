// $Id: TimeSync.java,v 1.2 2006/03/28 01:58:52 borndigerati Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


package timesync;

import java.io.*;
import java.util.Vector;

import agilla.messages.AgillaTimeSyncMsg;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class TimeSync implements MessageListener {
	static final short MAX_PORTS = 50;
	static final short TOS_UART_ADDR = 0x007e;
	//private int val;
	private MoteIF m_moteif;
	//private int m_nSend;
	Vector<MoteIF> writers;
	
	TimeSync(String args[]){
		try
	    {
	        m_moteif = new MoteIF(PrintStreamMessenger.err);
	        m_moteif.registerListener(new AgillaTimeSyncMsg(), this);

		    //m_nSend = -1;
		    m_moteif.start();
	    }
	    catch (Exception e)
	    {
	      System.out.println("ERROR: Couldn't contact serial forwarder.");
	      System.exit(1);
	    }
	      
	    String ports[] = new String[args.length];
	    System.out.print("Ports to be opened: ");
	    for(int i = 0; i < args.length; i++){
	    	ports[i] = args[i];
	    	System.out.print(ports[i]+ " ");
	    }
	    System.out.println("");
	    
	    writers = new Vector<MoteIF>();
	    for(int i = 0; i < ports.length; i++){
	    	//String cport = "serial@" + ports[i]+ ":tmote";
	    	String cport = "sf@localhost:" + ports[i];
	    	MoteIF writer = new MoteIF(BuildSource.makePhoenix(cport, PrintStreamMessenger.err));
	    	
	    	if(writer == null){
	    		System.err.println("Could not open writer to "+cport);
	    	    System.exit(2);
	    	}
	    	writers.add(writer);
	    }
	    try {
	    	 for(int i = 0; i < writers.size(); i++){
	    		  ((MoteIF)writers.get(i)).start();
	    	}
	   	}
	   	catch (Exception e) {
	   	    System.err.println("Error in starting writer! " + e);
	   	    System.exit(2);
	   	}
	    System.out.println("Started writers");
	}
	
	synchronized public void messageReceived( int destAddr, Message m )
	{
	    System.out.println( "Recv> " + ((AgillaTimeSyncMsg)m).toString() );
	    send(m);
	}
	
	public synchronized void send( Message m )
	{
	    try
	    {
	    	//System.out.println("Number of writers = "+ writers.size());
	    	for(int i = 0; i < writers.size(); i++){
	    		((MoteIF)writers.elementAt(i)).send( MoteIF.TOS_BCAST_ADDR, new AgillaTimeSyncMsg(m.dataGet()) );
	  	      	System.out.println( "Send to writer " + i + "> " + m );
	    	}
	      
	    }
	    catch (IOException e)
	    {
	      e.printStackTrace();
	      System.out.println("ERROR: Can't send message");
	      System.exit(1);
	    }
	}
	
    public static void main(String args[]) throws IOException {
    	if (args.length == 0) {
    		System.err.println("usage: java net.tinyos.timesync.TimeSync COMx ...");
    		System.exit(2);
    	}
	
    	
    	TimeSync tsync = new TimeSync(args);
	
    }
}

