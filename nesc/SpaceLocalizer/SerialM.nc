/*
 * SerialM.nc
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

module SerialM {
    provides {
        interface Serial;
    }
    uses {
        interface HPLUART;
        interface Leds;
    }
}
implementation {
#define IDLE    0xff
#define WAITING 0xfe
//#define BUF_LEN 32
#define RECV_BUF_LEN 85
    /*volatile uint8_t tx_head = IDLE;
    volatile uint8_t tx_tail = 0;
    uint8_t txbuf[BUF_LEN];*/
    uint8_t rx_state = IDLE;
    uint8_t rx_len = 0;
    uint8_t rxbuf[RECV_BUF_LEN];

/*    int put(char c) __attribute__ ((C,spontaneous))
    {
        uint8_t start_tx = 0;
        uint8_t new_tx_tail = 0;
        uint8_t new_tx_head = 1;

        /* Do the busy wait if the tx buffer is full */
/*        while (new_tx_head != IDLE &&
                (new_tx_tail+1)%BUF_LEN == new_tx_head) {
            atomic {
                new_tx_tail = tx_tail;
                new_tx_head = tx_head;
            }
        }

        atomic {
            /* Initialize queue */
/*            if (tx_head == IDLE) {
                txbuf[0] = c;
                tx_head = tx_tail = 0;
                start_tx = 1;
            }
            /* Enqueue */
  /*          else {
                txbuf[tx_tail] = c;
                tx_tail = (tx_tail+1)%BUF_LEN;
            }
        }
        if (start_tx)
            call HPLUART.put(txbuf[0]);

        return 0;
    }*/

    async event result_t HPLUART.putDone() {
/*        uint8_t do_tx = 0;
        uint8_t tx_ch = 0;
        atomic {
            if (tx_head == tx_tail || tx_head == IDLE) {
                tx_head = IDLE;
            }
            else {
                do_tx = 1;
                tx_ch = txbuf[tx_head];
                tx_head = (tx_head+1)%BUF_LEN;
            }
        }
        if (do_tx)
            call HPLUART.put(tx_ch);*/
        return SUCCESS;
    }

    void task recv_str()
    {
        uint8_t len;
        atomic len = rx_len;
        signal Serial.Receive(rxbuf, len);
        atomic {
            rx_len = 0;
            rx_state = IDLE;
        }
    }

#ifndef PLATFORM_PC
    void outc(uint8_t c)
    {
        loop_until_bit_is_set(UCSR0A, UDRE);
        outp(c, UDR0);
    }

    void printbyte(uint8_t b)
    {
        uint8_t n;
        n = (b & 0xf0) >> 4;
        if (n <= 9)
            outc('0' + n);
        else
            outc(n - 10 + 'A');
        n = (b & 0x0f);
        if (n <= 9)
            outc('0' + n);
        else
            outc(n - 10 + 'A');
        outc(' ');
    }

    void stack_trace(uint8_t extra, uint16_t val) __attribute__ ((C,spontaneous))
    {
        uint8_t * ptr = (uint8_t *) inw(SPL);

        /* Disable serial interrupts */
        uint8_t tmp = inb(UCSR0B);
        outp((1 << RXEN) | (1 << TXEN), UCSR0B);

        outc('\n');
        if (extra) {
            outc('<');
            printbyte(val & 0xff);
            printbyte((val >> 8) & 0xff);
            outc('>');
        }

        printbyte(inb(SPH));
        printbyte(inb(SPL));
        outc(':');

        for (ptr += 27; ptr < (uint8_t *)0x1100; ptr++) {
            printbyte(*ptr);
        }
        outc('\n');

        outp(tmp, UCSR0B);
    }
#endif

    async event result_t HPLUART.get(uint8_t data)
    {
        uint8_t state;

        atomic state = rx_state;
        
//#ifndef PLATFORM_PC
//        if (data == 'q')
//            stack_trace(0, 0);
//#endif
        
//        if (data == '\r' || state == WAITING)
//            stack_trace(0, 0);
//            return SUCCESS;

        if (data == '\r' || data == '\n') {
            if (post recv_str()) {
                atomic {
                    rx_state = WAITING;
                    rxbuf[rx_len] = '\0';
                }
            }
            else {
                atomic rx_len = 0;
            }
            return SUCCESS;
        }
            
        atomic {
            if (rx_len < RECV_BUF_LEN-1)
                rxbuf[rx_len++] = data;
        }

        return SUCCESS;
    }

    command result_t Serial.SetStdoutSerial() {
#ifndef PLATFORM_PC
        /* Initialize the serial port */
        call HPLUART.init();
        /* Use the put() function for any output to stdout. */
        //fdevopen(put, NULL, 0);
#endif
        return SUCCESS;
    }
}

