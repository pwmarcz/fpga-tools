#!/usr/bin/env python3

# pip3 install --user pyserial
import serial

COMMAND_READ = 1
COMMAND_WRITE = 2


def write(ser, addr, byte):
    ser.write([COMMAND_WRITE, addr >> 8, addr & 0xFF, byte])


def read(ser, addr):
    ser.write([COMMAND_READ, addr >> 8, addr & 0xFF])
    data = ser.read(1)
    assert len(data) == 1, 'failed to read'
    return ord(data)


SIZE = 0x2000

buf = [i % 254 for i in range(SIZE)]

with serial.Serial('/dev/ttyUSB1', 115200, timeout=60) as ser:
    print('Writing')
    for i in range(SIZE):
        write(ser, i, buf[i])
        print('.', end='', flush=True)

    print()
    print('Reading')
    for i in range(SIZE):
        b = read(ser, i)
        assert b == buf[i], 'read error'
        print('.', end='', flush=True)

    print()
    print('All OK')
