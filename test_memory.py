#!/usr/bin/env python3

# pip3 install --user pyserial
import serial

COMMAND_READ = 1
COMMAND_WRITE = 2


def write(ser, addr, byte):
    ser.write([COMMAND_WRITE, addr, byte])


def read(ser, addr):
    ser.write([COMMAND_READ, addr])
    data = ser.read(1)
    assert len(data) == 1, 'failed to read'
    return ord(data)


SIZE = 0x100

with serial.Serial('/dev/ttyUSB1', 9600, timeout=1) as ser:
    print('Writing')
    for i in range(SIZE):
        write(ser, i, i & 0xFF)
        print('.', end='', flush=True)

    print()
    print('Reading')
    for i in range(SIZE):
        b = read(ser, i)
        assert b == i & 0xFF, 'read error'
        print('.', end='', flush=True)

    print()
    print('All OK')
