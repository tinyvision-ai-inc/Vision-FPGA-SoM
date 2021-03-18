import serial
import time
import numpy as np
import cv2
import argparse


parser = argparse.ArgumentParser(prog='read_himax', description='Himax image sensor downloader')
parser.add_argument('--baud', type=int, default=460800)
parser.add_argument('-l', '--loop', action='store_true')
parser.add_argument('-o', '--out', default='img')
parser.add_argument('port', help='Windows: COMx, /dev/ttyUSBx on Linux')

args = parser.parse_args()

ser = serial.Serial(port=args.port, baudrate=args.baud, timeout=1.0)

print(ser.name)
ser.flushInput()
ser.flushOutput()

# "Warm up" the board by acquiring a frame
ser.write(b'x')
time.sleep(1)

(cols, rows) = (162, 162)
#(cols, rows) = (324, 324)

frameno = 0
while(True):
    print('Frame no: %d' % (frameno) )
    ser.flushInput()
    ser.write(b'x')
    resp = ser.read(100000) # Max length to be read is a frame
    print(len(resp))
    if (len(resp)>0):
        image = np.frombuffer(resp, dtype=np.uint8).reshape(rows, -1)
        cv2.imshow('capture', image)
        k = cv2.waitKey(0)
        if args.loop and args.out:
            if frameno < 9999:
                fname = "%s-%04d.tiff" %(args.out, frameno)
                cv2.imwrite(fname, image)
            else:
                print("Exceeded frame count")
        if k == 27:         # wait for ESC key to exit
            cv2.destroyAllWindows()
            break
    frameno = frameno + 1