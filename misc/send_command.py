import time
import serial
import serial.threaded

def echo(readerthread, message):
    msg_bytes = bytes(message, "Ascii")
    length = len(msg_bytes) + 4
    messageHeader = [0xec, 0x00, length & 0xff, length & 0xff00]
    msg = bytearray(messageHeader) + bytearray(msg_bytes)
    readerthread.write(msg)

class UARTMonitor(serial.threaded.Protocol):
    def data_received(self, data):
        try:
            print(data.decode('Ascii'), end='', flush=True)
        except:
            print(data, end='', flush=True)
        
ser = serial.Serial("/dev/ttyACM0", baudrate=115200, timeout=None)
reader = serial.threaded.ReaderThread(ser, UARTMonitor)
reader.start()

while 1:
    #echo(reader, "Hi")
    add32(ser, [0x00ff, 0xdead])
    #reader.write(bytearray([0xec, 0x00, 0x06, 0x00, 0x48, 0x69]))
    time.sleep(5)

reader.close()
exit()
