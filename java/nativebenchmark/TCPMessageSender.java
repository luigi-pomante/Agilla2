//$Id: TCPMessageSender.java,v 1.2 2005/11/22 20:05:18 chien-liang Exp $

package nativebenchmark;

import java.io.*;
import java.net.*;

public class TCPMessageSender implements java.io.Serializable {
	private static final long serialVersionUID = 4512630202802842237L;
	InetAddress addr;
	int port;
	
	/**
     * Creates a TCPMessageSender.
     */
    public TCPMessageSender(InetAddress addr, int port) {
    	this.addr = addr;
    	this.port = port;
    }
    
    /**
     * Forces the TCPMessageSender to close all sockets and stop
     * functioning.
     */
    public void kill() {
    }
    
    public void sendMessage(Object o) {
                       
            // open a TCP socket to the destination host
            try {
            	ByteArrayOutputStream baos = new ByteArrayOutputStream();
            	ObjectOutputStream oos = new ObjectOutputStream(baos);
            	oos.writeObject(o);
            	oos.flush();
            	
				log("Opening TCP socket to destination host \naddress:"
						+ addr + "\n port: " + port);
                //Socket socket = new Socket(dest.getAddress(), dest.getPort());
				Socket socket = new Socket(addr, port);
                socket.setTcpNoDelay(true);
                
                OutputStream os = socket.getOutputStream();
                InputStream is = socket.getInputStream();
                
                DataOutputStream dos = new DataOutputStream(os);
                //ObjectOutputStream oos = new ObjectOutputStream(os);
                //ObjectInputStream ois = ObjectInputStreamFactory.createStream(is);
                
				log("Sending the object to the destination.");
//                oos.writeObject(msg);
//                oos.flush();
				dos.write(baos.toByteArray());
				dos.flush();
                os.flush();
                
				log("Closing the socket to the destination host.");
                socket.close();
                
            } catch(Exception e) {
                e.printStackTrace();
            }
    }
	
	void log(String msg) {
		//System.out.println("TCPMessageSender: " + msg);
	}
}
