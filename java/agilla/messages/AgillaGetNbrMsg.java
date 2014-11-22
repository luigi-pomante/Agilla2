/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'AgillaGetNbrMsg'
 * message type.
 */

package agilla.messages;

public class AgillaGetNbrMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 6;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 38;

    /** Create a new AgillaGetNbrMsg of size 6. */
    public AgillaGetNbrMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new AgillaGetNbrMsg of the given data_length. */
    public AgillaGetNbrMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AgillaGetNbrMsg with the given data_length
     * and base offset.
     */
    public AgillaGetNbrMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AgillaGetNbrMsg using the given byte array
     * as backing store.
     */
    public AgillaGetNbrMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AgillaGetNbrMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public AgillaGetNbrMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AgillaGetNbrMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public AgillaGetNbrMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AgillaGetNbrMsg embedded in the given message
     * at the given base offset.
     */
    public AgillaGetNbrMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AgillaGetNbrMsg embedded in the given message
     * at the given base offset and length.
     */
    public AgillaGetNbrMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <AgillaGetNbrMsg> \n";
      try {
        s += "  [fromPC=0x"+Long.toHexString(get_fromPC())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [replyAddr=0x"+Long.toHexString(get_replyAddr())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [destAddr=0x"+Long.toHexString(get_destAddr())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: fromPC
    //   Field type: int, unsigned
    //   Offset (bits): 0
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'fromPC' is signed (false).
     */
    public static boolean isSigned_fromPC() {
        return false;
    }

    /**
     * Return whether the field 'fromPC' is an array (false).
     */
    public static boolean isArray_fromPC() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'fromPC'
     */
    public static int offset_fromPC() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'fromPC'
     */
    public static int offsetBits_fromPC() {
        return 0;
    }

    /**
     * Return the value (as a int) of the field 'fromPC'
     */
    public int get_fromPC() {
        return (int)getUIntBEElement(offsetBits_fromPC(), 16);
    }

    /**
     * Set the value of the field 'fromPC'
     */
    public void set_fromPC(int value) {
        setUIntBEElement(offsetBits_fromPC(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'fromPC'
     */
    public static int size_fromPC() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'fromPC'
     */
    public static int sizeBits_fromPC() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: replyAddr
    //   Field type: int, unsigned
    //   Offset (bits): 16
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'replyAddr' is signed (false).
     */
    public static boolean isSigned_replyAddr() {
        return false;
    }

    /**
     * Return whether the field 'replyAddr' is an array (false).
     */
    public static boolean isArray_replyAddr() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'replyAddr'
     */
    public static int offset_replyAddr() {
        return (16 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'replyAddr'
     */
    public static int offsetBits_replyAddr() {
        return 16;
    }

    /**
     * Return the value (as a int) of the field 'replyAddr'
     */
    public int get_replyAddr() {
        return (int)getUIntBEElement(offsetBits_replyAddr(), 16);
    }

    /**
     * Set the value of the field 'replyAddr'
     */
    public void set_replyAddr(int value) {
        setUIntBEElement(offsetBits_replyAddr(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'replyAddr'
     */
    public static int size_replyAddr() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'replyAddr'
     */
    public static int sizeBits_replyAddr() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: destAddr
    //   Field type: int, unsigned
    //   Offset (bits): 32
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'destAddr' is signed (false).
     */
    public static boolean isSigned_destAddr() {
        return false;
    }

    /**
     * Return whether the field 'destAddr' is an array (false).
     */
    public static boolean isArray_destAddr() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'destAddr'
     */
    public static int offset_destAddr() {
        return (32 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'destAddr'
     */
    public static int offsetBits_destAddr() {
        return 32;
    }

    /**
     * Return the value (as a int) of the field 'destAddr'
     */
    public int get_destAddr() {
        return (int)getUIntBEElement(offsetBits_destAddr(), 16);
    }

    /**
     * Set the value of the field 'destAddr'
     */
    public void set_destAddr(int value) {
        setUIntBEElement(offsetBits_destAddr(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'destAddr'
     */
    public static int size_destAddr() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'destAddr'
     */
    public static int sizeBits_destAddr() {
        return 16;
    }

}