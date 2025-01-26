import time
import serial
import serial.threaded

def echo(readerthread, message):
    if not message.isascii():
        print("Message must be ascii")
        return
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
    message = input("Enter message: ")
    echo(reader, message)
    time.sleep(1)
    print()

reader.close()
exit()
