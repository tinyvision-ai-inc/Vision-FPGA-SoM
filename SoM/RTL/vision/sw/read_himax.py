from __future__ import division
import serial
import time
import threading
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation


ser = serial.Serial(port='COM18', baudrate=115200, timeout=1.0)
print(ser.name)
ser.flushInput()
ser.flushOutput()


ser.write(b'x')
#time.sleep(0.1)
resp = ser.read(160*120)
print(type(resp))
image = np.asarray(list(resp))

#image = np.random.randint(256, size=(120, 160))
#arr = np.asarray(image)
cols = 162
rows = int(np.floor(len(image)/cols))
print(rows)
print(image[0:rows*cols])
image = image[0:rows*cols]
image = image.reshape(rows, cols)

plt.imshow(image, cmap='gray', vmin=0, vmax=255)
plt.show()