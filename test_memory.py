#!/usr/bin/env python3

# pip3 install --user pyserial
import serial

BAUD_RATE = 19200

COMMAND_READ = 1
COMMAND_WRITE = 2

SIZE = 0x1000
CHUNK_SIZE = 0x80
assert SIZE % CHUNK_SIZE == 0


def write(ser, addr, buf):
    assert 0 < len(buf) <= 0x100, len(buf)
    ser.write([COMMAND_WRITE, len(buf) - 1, addr >> 8, addr & 0xFF])
    ser.write(buf)


def read(ser, addr, count):
    ser.write([COMMAND_READ, count - 1, addr >> 8, addr & 0xFF])
    data = list(ser.read(count))
    assert len(data) == count, f'read only {len(data)} bytes, not {count}\n{data}'
    return data


buf = [i % 254 for i in range(SIZE)]

with serial.Serial('/dev/ttyUSB1', 19200, timeout=10) as ser:
    print('Writing')
    for i in range(0, SIZE, CHUNK_SIZE):
        write(ser, i, buf[i:i + CHUNK_SIZE])
        print('.', end='', flush=True)

    print()
    print('Reading')
    for i in range(0, SIZE, CHUNK_SIZE):
        data = read(ser, i, CHUNK_SIZE)
        expected = buf[i:i + CHUNK_SIZE]
        assert data == expected, f'read error:\n{data}\n{expected}'
        print('.', end='', flush=True)

    print()
    print('All OK')
