python3 -c "
import serial
import time

ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)
ser.setDTR(False)
time.sleep(0.1)
ser.setDTR(True)
time.sleep(0.5)

start = time.time()
while time.time() - start < 20:
    if ser.in_waiting:
        line = ser.readline().decode('utf-8', errors='replace')
        print(line, end='')
ser.close()" 2>&1 | tail -30
