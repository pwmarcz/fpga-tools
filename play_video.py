# pip3 install --user pyserial
# python3 play_video.py < bad_apple.raw

import serial
import sys
import base64
import time

BAUD_RATE = 19200
FPS = 24

t_prev = time.time()
t_frame = 1 / FPS

with serial.Serial('/dev/ttyUSB1', BAUD_RATE) as ser:
    for line in sys.stdin:
        t = time.time()
        dt = t - t_prev
        if (dt <= t_frame):
            time.sleep(t_frame - dt)
        else:
            print(f'Frame is late by {dt - t_frame} s!')
        t_prev = 1

        frame = base64.b64decode(line)
        ser.write(frame)
