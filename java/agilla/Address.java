package agilla;

/**
 * A motes address and whether it is a base station.
 *
 * @author Chien-Liang Fok <liangfok@wustl.edu>
 */
public class Address
{
	private int addr;
	private int hopsToGW;
	private int lqi;
	
	public Address(int addr, int hopsToGW) {
		this.addr = addr;
		this.hopsToGW = hopsToGW;
		this.lqi = 0;
	}
	
	public Address(int addr, int hopsToGW, int lqi) {
		this.addr = addr;
		this.hopsToGW = hopsToGW;
		this.lqi = lqi;
	}
	
	public int addr() {
		return addr;
	}
	
	public int hopsToGW() {
		return hopsToGW;
	}
	
	public int lqi() {
		return lqi;
	}
	
	public String toString() {
		return "" + addr + ":" + hopsToGW + ":" + lqi;
	}
}

