import serial
import serial.threaded
import random

def add32(ser, operands):
    operand_split = []
    for i in operands:
        if i > ((1 << 31) - 1):
            print("operand is greater than 32 bits!")
            exit()

        for j in range(4):
            mask = 0xff << (8 * j)
            res = (i & mask) >> (8 * j)
            operand_split.append(res)

    length = len(operand_split) + 4
    if length % 4 != 0:
        print("Something went really wrong!")
        exit()

    message_header = [0xad, 0x00, length & 0xff, length & 0xff00]
    msg = bytearray(message_header) + bytearray(operand_split)
    ser.write(msg)
  
ser = serial.Serial("/dev/ttyACM0", baudrate=115200, timeout=None)

operands = []
rand_max = (1 << 31) - 1
rand_min = -1 * rand_max
for i in range(2):
    operands.append(random.randint(rand_min, rand_max))
print(operands)

expected = 0
for i in operands:
    expected += i

add32(ser, operands)

res = ser.read(4)
result = int.from_bytes(res, byteorder="little", signed=True)

print(f"Result: {result}")
print(f"{result:064b}")
print(f"Expected: {expected}")
print(f"{expected:064b}")

if result == expected:
    print("\033[0;32mMatching\033[0m");
else:
    print("\033[0;31mDifferent\033[0m");
