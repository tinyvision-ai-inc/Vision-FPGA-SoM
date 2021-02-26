from __future__ import division
import serial
import time
import threading
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation


ser = serial.Serial(port='COM18', baudrate=230400, timeout=1.0)
ser.set_buffer_size(rx_size = 25000, tx_size = 12800)

print(ser.name)
ser.flushInput()
ser.flushOutput()

# "Warm up" the AEC
#ser.write(b'x')
#ser.write(b'x')
#time.sleep(1)

#plt.ion()

# Throw away bad pixels
while(True):
    ser.flushInput()
    ser.write(b'x')
    resp = ser.read(50000) # Max length to be read is a frame
    image = np.asarray(list(resp))

    cols = 162
    rows = int(np.floor(len(image)/cols))
    print(rows)
    image = image[0:rows*cols]
    image = image.reshape(rows, cols)

    plt.imshow(image, cmap='gray', vmin=0, vmax=255)
    plt.show()
    time.sleep(0.1)