// $Id: SwingAgentInjectorGUI.java,v 1.10 2006/04/05 10:28:21 borndigerati Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis
 * By Chien-Liang Fok.
 *
 * Washington University states that Agilla is free software;
 * you can redistribute it and/or modify it under the terms of
 * the current version of the GNU Lesser General Public License
 * as published by the Free Software Foundation.
 *
 * Agilla is distributed in the hope that it will be useful, but
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS",
 * OR OTHER HARMFUL CODE.
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to
 * indemnify, defend, and hold harmless WU, its employees, officers and
 * agents from any and all claims, costs, or liabilities, including
 * attorneys fees and court costs at both the trial and appellate levels
 * for any loss, damage, or injury caused by your actions or actions of
 * your officers, servants, agents or third parties acting on behalf or
 * under authorization from you, as a result of using Agilla.
 *
 * See the GNU Lesser General Public License for more details, which can
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */
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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>,
 Chien-Liang Fok <liang@cse.wustl.edu>
 * Date:        May 2 2005
 * Desc:        Main window for Agilla agent injector.
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @author Chien-Liang Fok <liang@cse.wustl.edu>
 */

package agilla;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;
import javax.swing.*;
import javax.swing.border.*;
import agilla.variables.*;
import net.tinyos.util.*;

public class SwingAgentInjectorGUI extends JFrame
	implements AgillaConstants, AgentInjectorGUI, ActionListener
{
	static final long serialVersionUID = 8178335523369145264L;
	private static final String rmiDisabledString = "<html><font face=\"Arial\" size=\"3\"><b>RMI Injector:</b> <font color=\"red\">Disabled</font>";
	private static final String rmiEnabledString = "<html><font face=\"Arial\" size=\"3\"><b>RMI Injector:</b> <font color=\"green\">Enabled</font> Registered as: ";
	//private static final String rmiClientEnabledString = "<html><font face=\"Arial\" size=\"3\"><b>RMI client:</b> <font color=\"green\">Enabled</font> connected to ";
	private static final String sfDisabledString = "<html><font face=\"Arial\" size=\"3\"><b>Serial Forwarder:</b> <font color=\"red\">Disconnected</font>";
	private static final String sfEnabledString = "<html><font face=\"Arial\" size=\"3\"><b>Serial Forwarder:</b> <font color=\"green\">Connected to ";
	private static final String cString = "<html><font face=\"Arial\" size=\"3\"><b>Grid Columns:</b> <font color=\"green\">";
	//private String initDir;
	private String initDir;
	private JMenuBar menuBar;
	private JLabel rmiStatusLabel;
	private JLabel sfStatusLabel;

	/**
	 * Displays the number of columns in the grid topology.
	 */
	private JLabel colLabel;
	private JTextField xPos, yPos, destTF;
	private JTextArea programArea;
	private String defaultProgram = "";
	private String filename;
	private File progFile;
	private AgentInjector injector;

	public SwingAgentInjectorGUI(final AgentInjector injector) {
		super("Agilla Agent Injector");
		this.injector = injector;
		initDir = AgillaProperties.getProperties().getInitDir();
//		System.out.println("user.home = " + System.getProperty("user.home"));
//		System.out.println("user.dir = " + System.getProperty("user.dir"));
//		System.out.println("os.name = " + System.getProperty("os.name"));
//		System.out.println("os.arch = " + System.getProperty("os.arch"));
//		System.out.println("os.version = " + System.getProperty("os.version"));
		createGUI();
		String defaultAgent = AgillaProperties.getProperties().getDefaultAgent();
		if (!defaultAgent.equals("")) {		
			String initFile = null;
			if (System.getProperty("os.name").equals("Windows XP"))
				initFile = initDir + "\\" + defaultAgent;
			else
				initFile = initDir + "/" + defaultAgent;
			if (initFile != null)
				openProgram(new File(initFile));
		}
	}

	/**
	 * Updates the Serial Forwarder status to be connected.
	 *
	 * @param source The MoteIF Source.
	 *
	 */
	public void setSFStatusConnected(String source) {
		sfStatusLabel.setText(sfEnabledString + source);
	}

	/**
	 * Updates the Serial Forwarder status to be connected.
	 */
	public void setSFStatusDisconnected() {
		sfStatusLabel.setText(sfDisabledString);
	}

	public void setRMIStatusConnected(String name) {
		rmiStatusLabel.setText(rmiEnabledString + name);
	}

	public void setRMIStatusDisconnected() {
		rmiStatusLabel.setText(rmiDisabledString);
	}

	public void updateNumColumns() {
		colLabel.setText(cString + AgillaLocation.NUM_COLUMNS);
	}

	private JPanel createStatusPanel(boolean useRMI) {
		JPanel sPanel = new JPanel();
		rmiStatusLabel = new JLabel(rmiDisabledString);
		sfStatusLabel = new JLabel(sfDisabledString);

		JPanel rmiPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
		rmiPanel.add(rmiStatusLabel);

		JPanel sfPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
		sfPanel.add(sfStatusLabel);
		sPanel.setLayout(new GridLayout(1, 2));
		sPanel.add(rmiStatusLabel);
		sPanel.add(sfPanel);
		return sPanel;
	}

	private void updateTitle() {
		if (filename != null)
			setTitle("Agilla Agent Injector - " + filename);
		else
			setTitle("Agilla Agent Injector");
	}

	private JPanel createProgramPanel() {
		JPanel panel = new JPanel();

		programArea = new JTextArea(25, 75);
		programArea.setText(defaultProgram);
		programArea.setFont(new Font("Courier",Font.PLAIN, 9).deriveFont((float) 13.0));
		programArea.setBorder(new EtchedBorder());

		JScrollPane scroller = new JScrollPane(programArea,
											   ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED,
											   ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);

		panel.setLayout(new BorderLayout());
		panel.add(scroller, BorderLayout.CENTER);
		return panel;
	}

	public void updateGridSize() {
		clearLocBox();
		injector.changeGridSize(AgillaLocation.NUM_COLUMNS);
		colLabel.setText(cString + AgillaLocation.NUM_COLUMNS);
	}

	private void clearLocBox() {
		xPos.setText("1");
		yPos.setText("1");
		destTF.setText("0");
	}

	public void updateLocBox() {

		short x = 0, y = 0;
		if (xPos.getText().length() != 0 && yPos.getText().length() != 0) {
			try {
				x = (short) Integer.valueOf(xPos.getText()).intValue();
				y = (short) Integer.valueOf(yPos.getText()).intValue();
				AgillaLocation locv = new AgillaLocation(x, y);
				System.out.println("location = " + locv);
				destTF.setText(String.valueOf(locv.getAddr()));
			} catch (NumberFormatException e) {
				e.printStackTrace();
			}
		}
	}

	/*private JPanel createLowerPanel() {
		xPos = new JTextField("1", 4);
		yPos = new JTextField("1", 4);
		destTF = new JTextField("0", 4);

		xPos.addKeyListener(new KeyAdapter() {
					public void keyReleased(KeyEvent e) {
						updateLocBox();
					}
				});
		yPos.addKeyListener(new KeyAdapter() {
					public void keyReleased(KeyEvent e) {
						updateLocBox();
					}
				});
		destTF.addKeyListener(new KeyAdapter() {
					public void keyReleased(KeyEvent e) {
					    try {
						int addr = Integer.valueOf(loc.getText()).intValue();
						AgillaLocation locv = new AgillaLocation(addr);
						xPos.setText(String.valueOf(locv.getx()));
						yPos.setText(String.valueOf(locv.gety()));
					    } catch(NumberFormatException nfe) {
					    }
					}
				});

		JPanel locPanel = new JPanel();
		locPanel.setLayout(new FlowLayout(FlowLayout.LEFT));
		locPanel.add(new JLabel("Destination: "));
//		locPanel.add(xPos);
//		locPanel.add(new JLabel(", "));
//		locPanel.add(yPos);
//		locPanel.add(new JLabel(")  TOS Address: "));
		locPanel.add(destTF);

//		colLabel = new JLabel(cString + AgillaLocation.NUM_COLUMNS);

//		JPanel colLabelPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
//		colLabelPanel.add(colLabel);

		JPanel lPanel = new JPanel(new GridLayout(1,2));
		lPanel.add(locPanel);
//		lPanel.add(colLabelPanel);

		InjectButton injectButton = new InjectButton();
		injectButton.setFont(TinyLook.boldFont().deriveFont((float) 14.0));
		injectButton.setAlignmentX(CENTER_ALIGNMENT);

		JPanel buttonPanel = new JPanel();
		buttonPanel.setLayout(new BorderLayout());
		buttonPanel.add(injectButton, BorderLayout.CENTER);
		buttonPanel.setBorder(new EmptyBorder(5, 5, 5, 5));

		JPanel panel = new JPanel();
		panel.setLayout(new GridLayout(2, 1));
		panel.add(lPanel);
		panel.add(injectButton);

		return panel;
	 }*/
	
		private JPanel createLowerPanel() {
		xPos = new JTextField("1", 4);
		yPos = new JTextField("1", 4);
		destTF = new JTextField("0", 4);

		xPos.addKeyListener(new KeyAdapter() {
					public void keyReleased(KeyEvent e) {
						updateLocBox();
					}
				});
		yPos.addKeyListener(new KeyAdapter() {
					public void keyReleased(KeyEvent e) {
						updateLocBox();
					}
				});
		destTF.addKeyListener(new KeyAdapter() {
					public void keyReleased(KeyEvent e) {
					    try {
						int addr = Integer.valueOf(destTF.getText()).intValue();
						AgillaLocation locv = new AgillaLocation(addr);
						xPos.setText(String.valueOf(locv.getx()));
						yPos.setText(String.valueOf(locv.gety()));
					    } catch(NumberFormatException nfe) {
					    }
					}
				});

		JPanel locPanel = new JPanel();
		locPanel.setLayout(new FlowLayout(FlowLayout.LEFT));
		locPanel.add(new JLabel("Destination ("));
		locPanel.add(xPos);
		locPanel.add(new JLabel(", "));
		locPanel.add(yPos);
		locPanel.add(new JLabel(")  TOS Address: "));
		locPanel.add(destTF);

		colLabel = new JLabel(cString + AgillaLocation.NUM_COLUMNS);

		JPanel colLabelPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
		colLabelPanel.add(colLabel);

		JPanel lPanel = new JPanel(new GridLayout(1,2));
		lPanel.add(locPanel);
		lPanel.add(colLabelPanel);

		InjectButton injectButton = new InjectButton();
		injectButton.setFont(new Font("Helvetica", Font.BOLD, 10).deriveFont((float) 14.0));
		injectButton.setAlignmentX(CENTER_ALIGNMENT);

		JPanel buttonPanel = new JPanel();
		buttonPanel.setLayout(new BorderLayout());
		buttonPanel.add(injectButton, BorderLayout.CENTER);
		buttonPanel.setBorder(new EmptyBorder(5, 5, 5, 5));

		JPanel panel = new JPanel();
		panel.setLayout(new GridLayout(2, 1));
		panel.add(lPanel);
		panel.add(injectButton);

		return panel;
	}
	

	private void inject() {
		int dest;
		try {
			dest = (short) Integer.valueOf(destTF.getText()).intValue();
		} catch (NumberFormatException e) {
			e.printStackTrace();
			JOptionPane.showMessageDialog(null, "Invalid destination.", "Error", JOptionPane.ERROR_MESSAGE);
			return;
		}
		try {
			injector.inject(programArea.getText(), dest);
		} catch (Exception e) {
			e.printStackTrace();
			JOptionPane.showMessageDialog(null, e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
		}
	}

	private void openProgram(File f) {
		progFile = f;
		filename = progFile.getName();
		updateTitle();

		try {
			FileReader fr = new FileReader(progFile);
			BufferedReader br = new BufferedReader(fr);

			String prog = "";
			String curr;

			while ((curr = br.readLine()) != null) {
				prog += curr + "\n";
			}
			br.close();
			fr.close();

			programArea.setText(prog);
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(0);
		}
	}

	private class ProgramOpener implements ActionListener {
		Component parent;

		public ProgramOpener(Component parent) {
			this.parent = parent;
		}

		public void actionPerformed(java.awt.event.ActionEvent evt) {
//			String dir = initDir;
//			File usrDir = new File(dir);
//			if (!usrDir.exists())
//				usrDir = new File(System.getProperties()
//									  .getProperty("user.home"));

//			JFileChooser fileChooser = new JFileChooser(usrDir);
			JFileChooser fileChooser;
			if (initDir != null)
				fileChooser = new JFileChooser(new File(initDir));
			else
				fileChooser = new JFileChooser();
			fileChooser.setDialogTitle("Open Agent");
			fileChooser.setDialogType(JFileChooser.OPEN_DIALOG);
			fileChooser.setMultiSelectionEnabled(false);

			int returnVal = fileChooser.showOpenDialog(parent);

			if (returnVal == JFileChooser.APPROVE_OPTION) {
				File f = fileChooser.getSelectedFile();
				initDir = f.getPath();
				openProgram(f);
			}
		}
	}

	private class ProgramSaver implements ActionListener {
		Component parent;

		public ProgramSaver(Component parent) {
			this.parent = parent;
		}

		public void actionPerformed(java.awt.event.ActionEvent evt) {
			String program = programArea.getText();
			File file = null;

			if (evt.getActionCommand().equals("Save As")) {
				String dir = initDir;
				File usrDir = new File(dir);
				if (!usrDir.exists())
					usrDir = new File(System.getProperties().getProperty(
										  "user.dir"));

				JFileChooser fileChooser = new JFileChooser(usrDir);
				fileChooser.setDialogTitle("Save Agent");
				fileChooser.setDialogType(JFileChooser.SAVE_DIALOG);
				fileChooser.setMultiSelectionEnabled(false);

				if (fileChooser.showSaveDialog(parent) == JFileChooser.APPROVE_OPTION) {
					try {
						file = fileChooser.getSelectedFile();
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
			} else
				file = progFile;

			if (file != null) {
				if (!file.exists()) {
                    try {
                        file.createNewFile();
                    } catch(IOException e) {
                        e.printStackTrace();
                        JOptionPane.showMessageDialog(null,
                                  "Cannot create the file.", "Error",
                                  JOptionPane.ERROR_MESSAGE);
                        return;
                    }                    
                }				
				if (file.canWrite()) {
					filename = file.getName();
					updateTitle();

					try {
						FileWriter fr = new FileWriter(file, false);
						BufferedWriter br = new BufferedWriter(fr);

						br.write(program);
						br.flush();
						br.close();
						fr.close();
					} catch (Exception e) {
						e.printStackTrace();
						JOptionPane.showMessageDialog(null,
													  "Cannot write to file.", "Error",
													  JOptionPane.ERROR_MESSAGE);
					}
				} else
					JOptionPane.showMessageDialog(null,
												  "Cannot write to file.", "Error",
												  JOptionPane.ERROR_MESSAGE);
			}
		}
	}

	private class InjectButton extends JButton {
		static final long serialVersionUID = -4319563816001977460L;
		
		public InjectButton() {
			super("Inject Agent!!");
			setAlignmentX(CENTER_ALIGNMENT);
			addActionListener(new InjectListener());
		}

		private class InjectListener implements ActionListener {
			public InjectListener() {
			}

			public void actionPerformed(ActionEvent e) {
				inject();
//				} catch (IOException exception) {
//					System.err.println("ERROR: Couldn't inject packet: "
//										   + exception);
//					JOptionPane.showMessageDialog(null, exception.getMessage(),
//												  "Error", JOptionPane.ERROR_MESSAGE);
//				} catch (InvalidInstructionException exception) {
//					System.err.println("Invalid instruction: "
//										   + exception.getMessage());
//					JOptionPane.showMessageDialog(null, exception.getMessage(),
//												  "Error", JOptionPane.ERROR_MESSAGE);
//				} catch (Exception exception) {
//					exception.printStackTrace();
//					JOptionPane.showMessageDialog(null, exception.getMessage(),
//												  "Error", JOptionPane.ERROR_MESSAGE);
//				}
			}
		}
	}

	public void actionPerformed(ActionEvent ae) {
		if (ae.getActionCommand().equals("changeAddress")) {
			ChangeAddressDialog cld = new ChangeAddressDialog(this);
			AddrLocPair lp = cld.getInput();
			if (lp != null) {
			    boolean success = injector.changeLocation(lp.addr, lp.newLoc);
			    if (success)
			        JOptionPane.showMessageDialog(this, "Move Successful");
			    else
					JOptionPane.showMessageDialog(
							null, "Move failed!",
							"Error", JOptionPane.ERROR_MESSAGE);
			}

			//String oldAddrS = JOptionPane.showInputDialog("Current Address?");
			//String newAddrS = JOptionPane.showInputDialog("New Address?");
			//injector.changeAddress(Integer.valueOf(oldAddrS).intValue(), Integer.valueOf(newAddrS).intValue());


		}
	}

	private void createGUI() {
		setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
		menuBar = new JMenuBar();
		menuBar.setFont(new Font("Helvetica",Font.PLAIN, 10));

		JMenu fileMenu = new JMenu();
		fileMenu.setText("File");
		JMenuItem openItem = new JMenuItem("Open", KeyEvent.VK_O);
		openItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O,
													   ActionEvent.CTRL_MASK));
		openItem.addActionListener(new ProgramOpener(this));
		openItem.setFont(new Font("Helvetica",Font.PLAIN, 10));

		JMenuItem closeItem = new JMenuItem("Close", KeyEvent.VK_C);
		closeItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						programArea.setText(defaultProgram);
						filename = null;
						progFile = null;
						updateTitle();
					}
				});
		closeItem.setFont(new Font("Helvetica",Font.PLAIN, 10));

		JMenuItem saveItem = new JMenuItem("Save", KeyEvent.VK_S);
		saveItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S,
													   ActionEvent.CTRL_MASK));
		saveItem.addActionListener(new ProgramSaver(this));
		saveItem.setActionCommand("Save");
		saveItem.setFont(new Font("Helvetica",Font.PLAIN, 10));

		JMenuItem saveAsItem = new JMenuItem("Save As", KeyEvent.VK_A);
		saveAsItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S,
														 ActionEvent.CTRL_MASK | ActionEvent.SHIFT_MASK));
		saveAsItem.addActionListener(new ProgramSaver(this));
		saveAsItem.setActionCommand("Save As");
		saveAsItem.setFont(new Font("Helvetica",Font.PLAIN, 10));

		JMenuItem quitItem = new JMenuItem("Quit", KeyEvent.VK_Q);
		quitItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_Q,
													   ActionEvent.CTRL_MASK));
		quitItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						System.exit(0);
					}
				});
		quitItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
		fileMenu.add(openItem);
		fileMenu.add(closeItem);
		fileMenu.add(saveItem);
		fileMenu.add(saveAsItem);
		fileMenu.add(quitItem);
		menuBar.add(fileMenu);

		JMenu snMenu = new JMenu("WSN");
		if (!injector.useRMI()) {
			final JCheckBoxMenuItem snConnectMI = new JCheckBoxMenuItem(
				"Connect", injector.isConnected());
			//try {
			snConnectMI.addActionListener(new ActionListener() {
						public void actionPerformed(ActionEvent e) {
							if (snConnectMI.isSelected()) {
								try {
									injector.connect();
								} catch(Exception ex) {
									ex.printStackTrace();
									JOptionPane.showMessageDialog(
										null, "Could not connect to "
											+ ex.getMessage() + ".",
										"Error", JOptionPane.ERROR_MESSAGE);
								}
							} else
								injector.disconnect();
						}
					});
//			} catch(Exception ite) {
//				ite.printStackTrace();
//			}
			snConnectMI.setFont(new Font("Helvetica",Font.PLAIN, 10));
			snMenu.add(snConnectMI);
			JMenuItem resetItem = new JMenuItem("Reset All", KeyEvent.VK_R);
			resetItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_R, ActionEvent.CTRL_MASK));
			resetItem.addActionListener(new java.awt.event.ActionListener() {
						public void actionPerformed(java.awt.event.ActionEvent evt) {
							//System.out.println("Sending reset.");
							injector.reset(TOS_BCAST_ADDRESS);
							//System.out.println("Showing reset dialog");
							//new ResetWaitDialog(null);
						}
					});
			resetItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
			snMenu.add(resetItem);

			JMenuItem resetMoteItem = new JMenuItem("Reset Mote (s)", KeyEvent.VK_R);
			resetMoteItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_R, java.awt.event.InputEvent.SHIFT_MASK | java.awt.event.InputEvent.CTRL_MASK));
			resetMoteItem
				.addActionListener(new java.awt.event.ActionListener() {
						public void actionPerformed(
							java.awt.event.ActionEvent evt) {
							String addrString = JOptionPane
								.showInputDialog("Please enter mote address(es) - use comma-separated values");
							if (addrString != null && !addrString.equals("")) {
								try {
									if (addrString.indexOf(",") != -1) {
										StringTokenizer st = new StringTokenizer(
											addrString, ",");
										while (st.hasMoreTokens()) {
											int addr = Integer.valueOf(
												st.nextToken()).intValue();
											System.out.println("Resetting mote " + addr + ".");
											injector.reset(addr);
											synchronized (this) {
												wait(1000);
											}
										}
									} else {
										int addr = Integer.valueOf(addrString).intValue();
										injector.reset(addr);
									}
								} catch (Exception e) {
									e.printStackTrace();
									JOptionPane.showMessageDialog(null,
																  "Problems resetting agent "
																	  + addrString, "Error",
																  JOptionPane.ERROR_MESSAGE);
								}
							}
						}
					});
			resetMoteItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
			snMenu.add(resetMoteItem);
		}

		// Changes the grid size
//		JMenuItem gridSizeItem = new JMenuItem("Change Grid Topology", KeyEvent.VK_G);
//		gridSizeItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_G, ActionEvent.CTRL_MASK));
//		gridSizeItem.addActionListener(new java.awt.event.ActionListener() {
//					public void actionPerformed(java.awt.event.ActionEvent evt) {
//						//new GridSizeDialog(SwingAgentInjectorGUI.this);
//						String ncString = JOptionPane.showInputDialog("Number of Columns?");
//						if (ncString != null && !ncString.equals("")) {
//							AgillaLocation.NUM_COLUMNS = Integer.valueOf(ncString).intValue();
//							updateGridSize();
//						}
//					}
//				});
//		gridSizeItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
//		snMenu.add(gridSizeItem);


		JMenuItem addressItem = new JMenuItem("Move a Node", KeyEvent.VK_M);
		addressItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_M, ActionEvent.CTRL_MASK));
		addressItem.setActionCommand("changeAddress");
		addressItem.addActionListener(this);
		addressItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
		snMenu.add(addressItem);

		JMenuItem nbrItem = new JMenuItem("Query Neighbor List");
		nbrItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_N, ActionEvent.CTRL_MASK));
		nbrItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						String addrS = JOptionPane.showInputDialog("Address?");
						if (addrS != null && !addrS.equals("")) {
							Vector nbrs = injector.queryNbrList(Integer.valueOf(addrS).intValue(), (short)0);
							if (nbrs.size() != 0) {
							    //System.out.println("Node " + addrS + " replied with:");
							    //System.out.println(nbrMsg.toString());
								String nbrString = "";
								for (int i = 0; i < nbrs.size(); i++) {
									nbrString += (Address)nbrs.get(i);
									if (i < nbrs.size()-1)
										nbrString += ", ";
								}
							    JOptionPane.showMessageDialog(null, nbrString, "Neighbors of node " + addrS, JOptionPane.INFORMATION_MESSAGE);
							} else
							    JOptionPane.showMessageDialog(
										null, "Node " + addrS + " did not reply or has no neighbors!!",
										"Error", JOptionPane.ERROR_MESSAGE);
						}
						
					}
				});
		nbrItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
		snMenu.add(nbrItem);

		// Removed and replaced with heartbeat, implemented in AgentInjector
		/*JMenuItem setBSItem = new JMenuItem("Set Basestation");
		setBSItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_B, ActionEvent.CTRL_MASK));
		setBSItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						injector.setBS();
					}
				});
		setBSItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
		snMenu.add(setBSItem);*/

		menuBar.add(snMenu);

		JMenu limoneMenu = new JMenu("Limone");
		JMenuItem loadAgentMI = new JMenuItem("Load Limone Agent",
											  KeyEvent.VK_L);
		loadAgentMI.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_L,
														  ActionEvent.CTRL_MASK));
		loadAgentMI.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						// implement!!
						JOptionPane.showMessageDialog(null, "Not implemented yet.",
													  "Error", JOptionPane.ERROR_MESSAGE);
					}
				});
		loadAgentMI.setFont(new Font("Helvetica",Font.PLAIN, 10));
		limoneMenu.add(loadAgentMI);
		menuBar.add(limoneMenu);
	
		
		JMenu expMenu = new JMenu("Cients");
//		JMenuItem expItem = new JMenuItem("Start Experiment", KeyEvent.VK_S);
//		expItem.addActionListener(new java.awt.event.ActionListener() {
//					public void actionPerformed(java.awt.event.ActionEvent evt) {
//						String inputValue = JOptionPane.showInputDialog("Please enter number of hops.");
//						int numHops = Integer.valueOf(inputValue).intValue();
//						inputValue = JOptionPane.showInputDialog("Please enter number of resets.");
//						int numResets = Integer.valueOf(inputValue).intValue();
//						injector.startExp(numHops, numResets);
//					}
//				});
//		expItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_E,
//													  ActionEvent.CTRL_MASK));
		
//		expMenu.add(expItem);

		JMenuItem showOscope = new JMenuItem("Oscilloscope", KeyEvent.VK_O);
		showOscope.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						new agilla.clients.oscope.oscilloscope(
							injector.getTS());
					}
				});
		expMenu.add(showOscope);
		menuBar.add(expMenu);

		JMenu dbMenu = new JMenu();
		dbMenu.setText("Debug");

		JMenuItem regRxn = new JMenuItem("Register Local Reaction", KeyEvent.VK_R);
		regRxn.setFont(new Font("Helvetica",Font.PLAIN, 10));
		regRxn.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						new agilla.clients.rxn_tester.RxnTester(
							injector.getTS());
					}
				});
		dbMenu.add(regRxn);


		JMenuItem dbItem = new JMenuItem("Print Debug Code", KeyEvent.VK_P);
		dbItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_P,
													 ActionEvent.CTRL_MASK));
		dbItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						String program = programArea.getText();
						if (program.equals(""))
							return;
						try {
							injector.printDebugCode(filename, program);
						} catch(Exception e) {
							JOptionPane.showMessageDialog(
								null, e.getMessage(),
								"Error", JOptionPane.ERROR_MESSAGE);
						}
					}
				});
		dbItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
		dbMenu.add(dbItem);

		JMenuItem dbPrintDivItem = new JMenuItem("Print Divider", KeyEvent.VK_D);
		dbPrintDivItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D,
															 ActionEvent.ALT_MASK));
		dbPrintDivItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						System.out
							.println("--------------------------------------------------------------------------------");
						System.out
							.println("--------------------------------------------------------------------------------");
					}
				});
		dbPrintDivItem.setFont(new Font("Helvetica",Font.PLAIN, 10));
		dbMenu.add(dbPrintDivItem);

		final JCheckBoxMenuItem printAllMsgsMI = new JCheckBoxMenuItem(
			"Print All Msgs", false);
		//printAllMsgsMI.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A,
			//												 ActionEvent.CTRL_MASK));
		printAllMsgsMI.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {
						Debugger.printAllMsgs = printAllMsgsMI.isSelected();
					}
				});
		printAllMsgsMI.setFont(new Font("Helvetica",Font.PLAIN, 10));
		dbMenu.add(printAllMsgsMI);

		final JCheckBoxMenuItem debugModeMI = new JCheckBoxMenuItem(
			"Debug Mode", Debugger.debug);
		debugModeMI.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {
						Debugger.debug = debugModeMI.isSelected();
					}
				});
		debugModeMI.setFont(new Font("Helvetica",Font.PLAIN, 10));
		dbMenu.add(debugModeMI);


		JMenuItem rout = new JMenuItem("Do rout");
		rout.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D,
												   ActionEvent.CTRL_MASK | ActionEvent.SHIFT_MASK));
		rout.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						Tuple t = new Tuple();
						t.addField(new AgillaLocation(1));
						t.addField(new AgillaLocation(1));
						t.addField(new AgillaLocation(1));
						t.addField(new AgillaValue((short)1));
						
//						AgillaLocation loc = new AgillaLocation(2,1);
						int destAddr = 1;
						System.out.println("Performing rout to " + destAddr + " with tuple\n" + t);
						injector.getTS().rout(t, destAddr);
					}
				});
		rout.setFont(new Font("Helvetica",Font.PLAIN, 10));
		dbMenu.add(rout);

		menuBar.add(dbMenu);

		//dani
		if (!injector.useRMI()) {
			JMenu remoteMenu = new JMenu();
			remoteMenu.setText("Remote");
			final JCheckBoxMenuItem enableRMI = new JCheckBoxMenuItem("Enable",
																	  false);
			enableRMI.addActionListener(new ActionListener() {
						public void actionPerformed(ActionEvent e) {
							if (enableRMI.isSelected()) {
								try {
									injector.enableRMI();
								} catch(Exception ex) {
									ex.printStackTrace();
									System.out.println("Problems enabling RMI!");
									System.out.println("   Did you start the rmiregistry?");
									System.out.println("   Did you include the -D options when calling java?");
									System.out.println("   Did you have the java.policy file at the /opt/tinyos-1.x/tools/java (or from wherever path the agilla injector is started) ?");
									JOptionPane.showMessageDialog(
										null,
										"Problems starting RMI. Check stub, policy, and rmi server.",
										"Error",
										JOptionPane.ERROR_MESSAGE);
								}
							} else {
								injector.disableRMI();
							}
						}
					});
			enableRMI.setFont(new Font("Helvetica",Font.PLAIN, 10));
			remoteMenu.add(enableRMI);
			menuBar.add(remoteMenu);//dani
		}

		//enddani
		
		JMenu helpMenu = new JMenu();
		helpMenu.setText("Help");
		JMenuItem helpMI = new JMenuItem("About AgentInjector");		
		helpMI.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						 JOptionPane.showMessageDialog(null, "AgentInjector version 3.0", 
								 "About", JOptionPane.INFORMATION_MESSAGE);
					}
				});
		helpMI.setFont(new Font("Helvetica",Font.PLAIN, 10));
		helpMenu.add(helpMI);
		menuBar.add(helpMenu);

		this.setJMenuBar(menuBar);

		getContentPane().setLayout(new BorderLayout());
		getContentPane().add(createStatusPanel(injector.useRMI()), BorderLayout.NORTH);
		getContentPane().add(createProgramPanel(), BorderLayout.CENTER);
		getContentPane().add(createLowerPanel(), BorderLayout.SOUTH);

		this.addWindowListener(new java.awt.event.WindowAdapter() {
					public void windowClosed(java.awt.event.WindowEvent e) {
						injector.disconnect();
					}
				});

		pack();

		// The following code centers the frame in the center of default
		// screen.
		GraphicsEnvironment ge = GraphicsEnvironment.
			getLocalGraphicsEnvironment();
		GraphicsDevice gd = ge.getDefaultScreenDevice();
		GraphicsConfiguration gc = gd.getDefaultConfiguration();
		Rectangle sb = gc.getBounds();
		Dimension frameSize = this.getSize();
		setLocation((sb.width - frameSize.width) / 2,
						(sb.height - frameSize.height) / 2);

		/*Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
		 Dimension frameSize = this.getSize();
		 if (frameSize.height > screenSize.height)
		 frameSize.height = screenSize.height;
		 if (frameSize.width > screenSize.width)
		 frameSize.width = screenSize.width;
		 setLocation((screenSize.width - frameSize.width) / 2,
		 (screenSize.height - frameSize.height) / 2);*/
		show();
	}

	/**
	 * Show a progress bar that delays the sending of the base station message.
	 * This allows the mote's network interface to resume working after being
	 * reset.
	 */
//	public void showResetBar() {
//		new ResetWaitDialog(this);
//	}

	/**
	 * Show a progress bar that delays the sending of the base station message.
	 * This allows the mote's network interface to resume working after being
	 * reset.
	 */
//	public void showGridSizeBar() {
//		new ResetWaitDialog("Changing the grid size...", this);
//	}

	private class AddrLocPair {
		int addr;
		AgillaLocation newLoc;

		public AddrLocPair(int addr, AgillaLocation newLoc) {
			this.addr = addr;
			this.newLoc = newLoc;
		}
	}

	private class ChangeAddressDialog extends JDialog
		implements ActionListener
	{
		private static final long serialVersionUID = -8711450733201409703L;
		private JTextField addrString, newStringX, newStringY;
		private boolean gotInput;
		//private Frame owner;
		private int addr, newX, newY;

		public ChangeAddressDialog(Frame owner) {
			super(owner, "Change Mote Address", true);
			//this.owner = owner;

			JPanel leftPanel = new JPanel(new GridLayout(2,1));
			leftPanel.add(new JLabel("Mote Address:"));
			leftPanel.add(new JLabel("New Address:"));

			addrString = new JTextField(5);
			addrString.addActionListener(this);
			addrString.setActionCommand("ok");

			newStringX = new JTextField(5);
			newStringX.addActionListener(this);
			newStringX.setActionCommand("ok");

			newStringY = new JTextField(5);
			newStringY.addActionListener(this);
			newStringY.setActionCommand("ok");

			JPanel newPanel = new JPanel(new FlowLayout());
			newPanel.add(new JLabel("("));
			newPanel.add(newStringX);
			newPanel.add(new JLabel(","));
			newPanel.add(newStringY);
			newPanel.add(new JLabel(")"));

			JPanel rightPanel = new JPanel(new GridLayout(2,1));
			rightPanel.add(addrString);
			rightPanel.add(newPanel);

			JButton ok = new JButton("OK");
			ok.addActionListener(this);
			ok.setActionCommand("ok");

			JButton cancel = new JButton("Cancel");
			cancel.addActionListener(this);
			cancel.setActionCommand("cancel");

			JPanel buttonPanel = new JPanel(new FlowLayout());
			buttonPanel.add(ok);
			buttonPanel.add(cancel);

			getContentPane().add(leftPanel, BorderLayout.WEST);
			getContentPane().add(rightPanel, BorderLayout.CENTER);
			getContentPane().add(buttonPanel, BorderLayout.SOUTH);
			pack();
			Dimension ownerSize = owner.getSize();
			Point ownerLoc = owner.getLocation();

			Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
			Dimension frameSize = this.getSize();
			if (frameSize.height > screenSize.height)
				frameSize.height = screenSize.height;
			if (frameSize.width > screenSize.width)
				frameSize.width = screenSize.width;
			//setLocation((screenSize.width - frameSize.width) / 2,
			//				(screenSize.height - frameSize.height) / 2);
			setLocation((int)(ownerLoc.getX()+(ownerSize.width - frameSize.width) / 2),
							(int)(ownerLoc.getY() +(ownerSize.height - frameSize.height) / 2));
		}

		public AddrLocPair getInput() {


			//System.out.println("Showing the ChangeLocationDialog");
			show();

			//System.out.println("Checking the input");
			if (gotInput)
				return new AddrLocPair(addr, new AgillaLocation(newX, newY));
			else
				return null;
		}

		public void actionPerformed(ActionEvent ae) {
			if (ae.getActionCommand().equals("ok")) {
				try {
					//oldX = Integer.valueOf(oldStringX.getText()).intValue();
					//oldY = Integer.valueOf(oldStringY.getText()).intValue();
					addr = Integer.valueOf(addrString.getText()).intValue();
					newX = Integer.valueOf(newStringX.getText()).intValue();
					newY = Integer.valueOf(newStringY.getText()).intValue();
					gotInput = true;
					dispose();
				} catch(Exception e) {
					e.printStackTrace();
					JOptionPane.showMessageDialog(
						null, "Error",
						"Invalid location(s).", JOptionPane.ERROR_MESSAGE);
				}
			} else {
				gotInput = false;
				dispose();
			}
		}
	}

	/**
	 * This displays a progress dialog that delays the sending of the base
	 * station message until the network stack is ready.
	 */
//	private class ResetWaitDialog extends JDialog implements Runnable {
//		static final int MAX_VALUE = 300;
//		JProgressBar pb = null;
//		int count = 0;
//
//		public ResetWaitDialog(Frame owner) {
//			super(owner, "Resetting Mote(s)...", true);
//			pb = new JProgressBar(0,MAX_VALUE);
//			getContentPane().add(pb);
//			new Thread(this).start();
//			setResizable(false);
//			pack();
//			//setSize(350, 100);
//			Dimension ownerSize = owner.getSize();
//			Point ownerLoc = owner.getLocation();
//
//			Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
//			Dimension frameSize = this.getSize();
//			if (frameSize.height > screenSize.height)
//				frameSize.height = screenSize.height;
//			if (frameSize.width > screenSize.width)
//				frameSize.width = screenSize.width;
//			//setLocation((screenSize.width - frameSize.width) / 2,
//			//				(screenSize.height - frameSize.height) / 2);
//			setLocation((int)(ownerLoc.getX()+(ownerSize.width - frameSize.width) / 2),
//							(int)(ownerLoc.getY() +(ownerSize.height - frameSize.height) / 2));
//			show();
//		}
//
//		public void run() {
//			while (count++ < MAX_VALUE) {
//				try {
//					Thread.sleep(10);
//				} catch(Exception e) {
//					e.printStackTrace();
//				}
//				pb.setValue(count);
//			}
//			dispose();
//		}
//	}
}

