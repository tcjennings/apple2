# RS232 Signal Pins (DTE to DCE)

| RS232 Signal | DB9 Pin | Apple //c Pin | Modem 300/1200 Pin | DB25 Pin |
|---|---|---|---|---|
| DCD | 1 | NC | 7 | 8 |
| RXD | 2 | 4 | 5 | 3 |
| TXD | 3 | 2 | 9 | 2 |
| DTR | 4 | 1 | 6 | 20 |
| GND | 5 | 3 | 3 | 7 |
| DSR | 6 | 5 | 2 | 6 |
| RTS | 7 | NC | NC | 4 |
| CTS | 8 | NC | NC | 5 |
| RI | 9 | NC | NC | 22 |
| SHD | NC | NC | 8 | 1 |

# Modem 300/1200

| Modem 300/1200 Pin | RS232 Signal | Apple //c Pin |
|---|---|---|
| 1 | NC | NC |
| 2 | DSR | 5 |
| 3 | GND | 3 |
| 4 | NC | NC |
| 5 | RXD | 4 |
| 6 | DTR | 1 |
| 7 | DCD | NC |
| 8 | GND | NC |
| 9 | TXD | 2 |

On both modems, the standard DIP switch settings are DOWN, UP, UP.

# RS232 Signal Pins (DTE to DTE)

DTE to DTE cables are used for computer connections to serial printers and other computers.

At a minimum, such a cable has a common ground and TXD and RXD crossed. More sophisticated cables support handshaking.

## Null Modem Cable

### Apple //c

| Apple //c Pin | RS232 Signal | DB 9 Pin | Note |
|---|---|---|---|
| 1 | DTR | NC | Loopback Pin 5 |
| 2 | TXD | 2 |
| 3 | GND | 5 |
| 4 | RXD | 3 |
| 5 | DSR | NC | Loopback Pin 1 |
| NC | DCD | 1 | Loopback Pin 4 |
| NC | DTR | 4 | Loopback Pin 1,6 |
| NC | DSR | 6 | Loopback Pin 4 |
| NC | RTS | 7 | Looopback Pin 8 |
| NC | CTS | 8 | Loopback Pin 7 |

* On the Apple //c side, short pins 1 and 5 (DTR/DSR).
* On the DB9 side, short pins 1,4,6 (DCD/DTR/DSR) and pins 7,8 (RTS/CTS).
