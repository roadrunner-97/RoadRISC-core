#!/usr/bin/env python3
"""
Send 32-bit hex words to a serial port, one byte at a time.

Usage:
    ./uart_send.py /dev/ttyUSB0
    > 0xDEADBEEF
    > CAFEBABE
    > 0x12345678
    > quit

Each word is sent as 4 bytes in big-endian order (high byte first).
Baud rate defaults to 115200.
"""

import argparse
import sys

try:
    import serial
except ImportError:
    print("Need pyserial: pip install pyserial", file=sys.stderr)
    sys.exit(1)


def parse_word(s: str) -> int | None:
    s = s.strip().lower()
    if not s:
        return None
    try:
        v = int(s, 16)
    except ValueError:
        return None
    if v < 0 or v > 0xFFFFFFFF:
        return None
    return v


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("port", help="Serial port (e.g. /dev/ttyUSB0)")
    parser.add_argument("-b", "--baud", type=int, default=115200)
    parser.add_argument(
        "-e", "--endian",
        choices=["big", "little"],
        default="big",
        help="Byte order on the wire (default: big)",
    )
    args = parser.parse_args()

    try:
        ser = serial.Serial(args.port, args.baud, timeout=0.1)
    except serial.SerialException as e:
        print(f"Could not open {args.port}: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Connected to {args.port} at {args.baud} baud, {args.endian}-endian.")
    print("Enter 32-bit hex words. 'quit' or Ctrl-D to exit.\n")

    while True:
        try:
            line = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not line:
            continue
        if line.lower() in ("quit", "exit", "q"):
            break

        word = parse_word(line)
        if word is None:
            print(f"  ! not a valid 32-bit hex word: {line!r}")
            continue

        byteorder = "big" if args.endian == "big" else "little"
        data = word.to_bytes(4, byteorder)
        ser.write(data)
        ser.flush()

        print(f"  sent: {' '.join(f'{b:02X}' for b in data)}")

    ser.close()


if __name__ == "__main__":
    main()
