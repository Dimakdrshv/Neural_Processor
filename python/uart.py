import serial
import numpy as np
from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split

# ==========================================
# Настройки
# ==========================================
PORT = "COM3"

BAUDRATE = 57600

TIMEOUT = 1.0

# True  -> только тестовый набор из 360 изображений
# False -> весь датасет из 1797 изображений
USE_TEST_SET = True

# Если True — рисовать вообще каждое изображение
SHOW_ALL = True

# Если True — обязательно рисовать ошибочные изображения
SHOW_ERRORS = True

# ==========================================
# Dataset
# ==========================================
digits = load_digits()

X = digits.data.astype(np.uint8)
Y = digits.target.astype(np.uint8)

# ==========================================
# Выбор набора данных
# ==========================================
if USE_TEST_SET:
    _, X, _, Y = train_test_split(
        X,
        Y,
        test_size=0.2,
        random_state=42,
        stratify=Y
    )
    print("Dataset: TEST SET")
    print(f"Images:  {len(X)}")
    
else:
    print("Dataset: FULL DATASET")
    print(f"Images:  {len(X)}")

# ==========================================
# Вывод изображения 8x8 в консоль
# ==========================================
def print_image(image):
    image = image.reshape(8, 8)

    symbols = " .:-=+*#%@"

    for row in image:
        line = ""
        for pixel in row:
            index = int(pixel) * (len(symbols) - 1) // 16
            line += symbols[index] * 2
        print(line)

# ==========================================
# UART
# ==========================================
uart = serial.Serial(
    port=PORT,
    baudrate=BAUDRATE,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=TIMEOUT
)

# Очищаем старые данные в UART
uart.reset_input_buffer()
uart.reset_output_buffer()

# ==========================================
# Тест
# ==========================================
correct = 0
errors = 0
timeouts = 0

try:
    for index in range(len(X)):
        image = X[index]
        expected = int(Y[index])

        # ==================================
        # Отправляем 64 байта на FPGA
        # ==================================
        uart.write(image.tobytes())
        uart.flush()

        # ==================================
        # Ждём один байт ответа
        # ==================================
        response = uart.read(1)

        # ==================================
        # Timeout
        # ==================================
        if len(response) != 1:
            timeouts += 1
            print()
            print("=" * 40)
            print(f"Image:    {index + 1}")
            print(f"Expected: {expected}")
            print("FPGA:     TIMEOUT")
            print("=" * 40)
            print_image(image)
            continue

        # ==================================
        # FPGA result
        # ==================================
        result = response[0]

        # ==================================
        # Сравнение
        # ==================================
        if result == expected:
            correct += 1
            status = "OK"
        else:
            errors += 1
            status = "ERROR"

        # ==================================
        # Краткий вывод
        # ==================================
        print(
            f"[{index + 1:4d}/{len(X)}] "
            f"expected={expected} "
            f"FPGA={result} "
            f"{status}"
        )

        # ==================================
        # Рисуем изображение
        # ==================================
        if SHOW_ALL or (SHOW_ERRORS and result != expected):
            print()
            print_image(image)
            print()
            print(
                f"Expected: {expected}    "
                f"FPGA: {result}"
            )
            print("-" * 40)

finally:

    uart.close()

# ==========================================
# Итог
# ==========================================
tested = correct + errors

if tested != 0:
    accuracy = 100.0 * correct / tested
else:
    accuracy = 0.0


print()
print("=" * 40)
print("FPGA NEURAL NETWORK TEST")
print("=" * 40)

if USE_TEST_SET:
    print("Dataset:   TEST SET")
else:
    print("Dataset:   FULL DATASET")

print(f"Images:    {len(X)}")
print(f"Tested:    {tested}")
print(f"Correct:   {correct}")
print(f"Errors:    {errors}")
print(f"Timeouts:  {timeouts}")
print(f"Accuracy:  {accuracy:.4f}%")
print("=" * 40)
