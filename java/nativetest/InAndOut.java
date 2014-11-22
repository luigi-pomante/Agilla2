package nativetest;

import java.awt.*;
import java.io.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.packet.*;

public class ControlLEDs extends JFrame implements ActionListener {
	static int group_id = 1;
	static String source = "COM1:19200"; // for NMRC motes

	private MoteIF mote;
	private ToggleLEDMsg packet;

	/**
	 * Initializes the frame.
	 */
	public ControlLEDs() {
		super("LED Controller");

		try {
			// uncomment for NMRC mote
			mote = new MoteIF(BuildSource.makePhoenix(BuildSource.makeArgsSerial(source),net.tinyos.util.PrintStreamMessenger.err));
			//mote = new MoteIF(PrintStreamMessenger.err, group_id);
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(0);
		}

		// Add menu.
		ActionListener exitMenuItemListener = new ActionListener() {
			/**
			 * Invoked when an action occurs.
			 */
			public void actionPerformed(ActionEvent e) {
				ControlLEDs.this.close();
			}
		};
		JMenuItem exitMenuItem = new JMenuItem("Exit");
		exitMenuItem.addActionListener(exitMenuItemListener);
		JMenu fileMenu = new JMenu("File");
		fileMenu.add(exitMenuItem);
		JMenuBar menuBar = new JMenuBar();
		menuBar.add(fileMenu);
		setJMenuBar(menuBar);

		// Add window listener.
		this.addWindowListener(
			new WindowAdapter() {
				/**
				 * Called when window close button was pressed.
				 */
				public void windowClosing(WindowEvent e){
					ControlLEDs.this.close();
				}
			}
		);

		JButton rb = new JButton("Toggle Red");
		JButton gb = new JButton("Toggle Green");
		JButton yb = new JButton("Toggle Yellow");

		rb.setActionCommand("red");
		gb.setActionCommand("green");
		yb.setActionCommand("yellow");

		rb.addActionListener(this);
		gb.addActionListener(this);
		yb.addActionListener(this);

		getContentPane().setLayout(new GridLayout(3,1));
		getContentPane().add(rb);
		getContentPane().add(gb);
		getContentPane().add(yb);

		show();
	}

	public void actionPerformed(ActionEvent ae) {
		packet = new ToggleLEDMsg();
		if (ae.getActionCommand().equals("red")) {
			packet.dataSet(new byte[] {1});
		} else if (ae.getActionCommand().equals("green")) {
			packet.dataSet(new byte[] {2});
		} if (ae.getActionCommand().equals("yellow")) {
			packet.dataSet(new byte[] {3});
		}
		try {
			mote.send(mote.TOS_BCAST_ADDR, packet);
		} catch (IOException ioe) {
			ioe.printStackTrace();
			System.exit(0);
		}
	}

	/**
	 * Shows the frame.
	 */
	public void show() {
		Dimension size = new Dimension(600,440);
		Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
		setBounds(
					 (screenSize.width - size.width) / 2,
					 (screenSize.height - size.height) / 2,
			size.width,
			size.height);
		super.show();
	}

	/**
	 * Closes the frame.
	 */
	private void close() {
		setVisible(false);
		System.exit(0); // Delete this line if necessary.
	}

	public static final void main(String[] args) {
		if (args.length > 0)
			group_id = Integer.valueOf(args[0]).intValue();
		new ControlLEDs();
	}
}

