/*
 * Serial.nc
 * David Moore <dcm@mit.edu>
 *
 * Module to connect standard output to the serial port.  Allows use
 * of printf() for debugging and status messages.
 *
 * Usage:
 *   call Serial.SetStdoutSerial() to attach stdout to the Serial UART.
 *   Any further commands that use stdout such as printf() will output
 *   to the serial port.
 */

/*
      This software may be used and distributed according to the terms
      of the GNU General Public License (GPL), incorporated herein by reference.
      Drivers based on this skeleton fall under the GPL and must retain
      the authorship (implicit copyright) notice.

      This program is distributed in the hope that it will be useful, but
      WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
      General Public License for more details.
*/

interface Serial {
    command result_t SetStdoutSerial();
    event result_t Receive(char * buf, uint8_t len);
}
