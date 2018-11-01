#!/usr/bin/env python3

# pip3 install --user pyserial
import serial

BAUD_RATE = 19200

COMMAND_READ = 1
COMMAND_WRITE = 2
COMMAND_DRAW = 3

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


def draw(ser, sprite_addr, lines, x, y):
    ser.write([
        COMMAND_DRAW | (lines << 4),
        (x << 4) | y,
        sprite_addr >> 8,
        sprite_addr & 0xFF
    ])


def test_memory():
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
        print('Memory test OK')


def draw_screen(ser):
    buf = read(ser, 0x100, 256)
    print('Screen:')
    for y in range(32):
        for x in range(64):
            byte = buf[y * 8 + x // 8]
            bit = bool(byte & (1 << (7 - (x % 8))))
            print('#' if bit else '.', end='')
        print()
    print()


def test_gpu():
    with serial.Serial('/dev/ttyUSB1', 19200, timeout=10) as ser:
        write(ser, 0x100, [0] * 256)
        write(ser, 0x45, [
            0b00011000,
            0b01100110,
            0b01111110,
            0b01100110,
            0b01100110,
        ])
        draw(ser, 0x45, 5, 4, 4)
        draw(ser, 0x45, 5, 12, 4)
        draw_screen(ser)


if __name__ == '__main__':
    test_gpu()
    #test_memory()
