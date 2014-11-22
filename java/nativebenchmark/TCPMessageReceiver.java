//$Id: TCPMessageReceiver.java,v 1.5 2005/11/22 23:06:30 chien-liang Exp $

package nativebenchmark;

import java.io.*;
import java.net.*;

public class TCPMessageReceiver implements Runnable, Serializable {
    
    /**
	 * The server socket.
	 */
    private ServerSocket ss;
    
    /**
	 * The thread that accepts incomming connections.
	 */
    private Thread acceptThread;
	
	/**
	 * The port being listened to.
	 */
	private int port;
	
	private TCPListener rcvr;
    
    /**
	 * This message receiver listens for TCP connections
	 * and reads in commands from them.
	 *
	 * @param port the port on which to listen for connections
	 */
    public TCPMessageReceiver(int port, TCPListener rcvr){
		this.rcvr = rcvr;
		
		// create the server socket
		try{
			ss = new ServerSocket(port);
		}
		catch(Exception e) {
			e.printStackTrace();
			System.exit(0);
		}
		
		// start the thread that accepts connections
		acceptThread = new Thread(this, "TCPMessageReceiver");
		acceptThread.start();
    }
    
    /**
	 * Stop the operation of the Message Receiver.
	 * Once the MessageReceiver has been terminated, it can no
	 * longer resume operation and should be discarded.
	 */
    public void kill() {
		
		try {
			ss.close();
			acceptThread.join();
		} catch(Exception e){
			e.printStackTrace();
		}
    }
	
	void log(String msg) {
		//System.err.println("TCPMessageReceiver: " + msg);
	}
    
    /**
	 * Sits in a loop waiting for clients to connect.  When a client connects,
	 * it creates a ClientHandler for it.
	 */
    public void run() {
		// continue to loop until an IOException is thrown
		try {
			while(true) {
				Socket s = null;
				log("Waiting for a connection on port " + port);
				if ((s = ss.accept()) != null) {
					log("Connection accepted, passing to client handler.");
					s.setTcpNoDelay(true);
					new ClientHandler(s);
				}
			}
		} catch(IOException e) {
			//if (!ss.isClosed())
			//	e.printStackTrace();
		} finally {
			try {
				ss.close();
			} catch(Exception e){}
		}
    }
    
    /**
	 * Handles incomming messages from a particular client.
	 */
    private class ClientHandler implements Runnable {
		/**
		 * The sock et to the client.
		 */
		Socket socket;
		/**
		 * The output streams.
		 */
		//ObjectOutputStream out;
		/**
		 * The input streams.
		 */
		ObjectInputStream in;
		/**
		 * The thread that reads messages sent from the client.
		 */
		Thread chThread;
		/**
		 * Creates a clientHandler.
		 */
		public ClientHandler(Socket socket) {
			this.socket = socket;
			
			// extract the input and output streams
			try {
				// be sure to create the output stream before the input stream
				//out = new ObjectOutputStream(socket.getOutputStream());
				//in = ObjectInputStreamFactory.createStream(socket.getInputStream());
				in = new ObjectInputStream(socket.getInputStream());
			} catch(IOException e) {
				e.printStackTrace();
				return;
			}
			
			new Thread(this).start();
		}
		
		/**
		 * Sits in a loop listening for incomming messages.
		 */
		public void run() {
			try {
				log("Reading in object");
				Object o = in.readObject();
				
				if (o!= null) {
					rcvr.messageReceived(o);
				}
			} catch(ClassNotFoundException e) {
				e.printStackTrace();
			} catch(IOException e) {
				e.printStackTrace();
			} finally {
				try {
					socket.close();
				} catch(Exception e) {}
			}
		}
		
		void log(String msg) {
			//System.out.println("TCPMessageReceiver: ClientHandler: " + msg);
		}
    }
}
