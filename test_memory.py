#!/usr/bin/env python3

# pip3 install --user pyserial
import serial

COMMAND_READ = 1
COMMAND_WRITE = 2


def write(ser, addr, b):
    ser.write([COMMAND_WRITE, addr, b])


def read(ser, addr):
    ser.write([COMMAND_READ, addr])
    b = ser.read()
    if b is None:
        return None
    return ord(b)


with serial.Serial('/dev/ttyUSB1', 9600, timeout=1) as ser:
    write(ser, 0xFE, 42)
    write(ser, 0xAB, 44)
    write(ser, 0xCD, read(ser, 0xCD) + 1)

    print(read(ser, 0xFE))
    print(read(ser, 0xAB))
    print(read(ser, 0xCD))
