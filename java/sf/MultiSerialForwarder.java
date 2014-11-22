package sf;

public class MultiSerialForwarder {

	/**
	 * @param args An array containing {COM port, TCP port} pairs
	 */
	public static void main(String[] args) throws Exception{
		for (int i = 0; i < args.length; i++) {
			String[] arguments = {"-no-gui", "-quiet", "-comm", "serial@"+args[i++]+":tmote", "-port", args[i]};
			new net.tinyos.sf.SerialForwarder(arguments);
		}

	}

}
