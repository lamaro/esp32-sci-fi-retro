# Demo temporal para la pantalla SPI ST7735S 128x128.
# Ejecutar con: mpremote connect /dev/cu.usbserial-0001 run demo_pantalla.py
# No reemplaza el main.py que conecta el ESP32 al Wi-Fi.
import machine
import time

WIDTH = 128
HEIGHT = 128
# Pines según el cableado acordado:
# SCK=GPIO14, MOSI=GPIO13, CS=GPIO21, DC/A0=GPIO22, RESET=GPIO4
spi = machine.SPI(1, baudrate=8000000, polarity=0, phase=0,
                  sck=machine.Pin(14), mosi=machine.Pin(13), miso=machine.Pin(12))
cs = machine.Pin(21, machine.Pin.OUT, value=1)
dc = machine.Pin(22, machine.Pin.OUT, value=1)
rst = machine.Pin(4, machine.Pin.OUT, value=1)


def command(value, data=None):
    cs.value(0)
    dc.value(0)
    spi.write(bytes((value,)))
    if data is not None:
        dc.value(1)
        spi.write(data)
    cs.value(1)


def init_display():
    rst.value(1)
    time.sleep_ms(20)
    rst.value(0)
    time.sleep_ms(40)
    rst.value(1)
    time.sleep_ms(120)
    command(0x01)  # SWRESET
    time.sleep_ms(150)
    command(0x11)  # SLPOUT
    time.sleep_ms(120)
    command(0xB1, bytes((0x01, 0x2C, 0x2D)))
    command(0xB2, bytes((0x01, 0x2C, 0x2D)))
    command(0xB3, bytes((0x01, 0x2C, 0x2D, 0x01, 0x2C, 0x2D)))
    command(0xB4, bytes((0x07,)))
    command(0xC0, bytes((0xA2, 0x02, 0x84)))
    command(0xC1, bytes((0xC5,)))
    command(0xC2, bytes((0x0A, 0x00)))
    command(0xC3, bytes((0x8A, 0x2A)))
    command(0xC4, bytes((0x8A, 0xEE)))
    command(0xC5, bytes((0x0E,)))
    command(0x20)  # INVOFF
    command(0x36, bytes((0x08,)))  # pines del LCD arriba (consola), orden BGR
    command(0x3A, bytes((0x05,)))  # color RGB565
    # El ST7735S tiene RAM 132x162; esta pantalla deja un borde interno.
    command(0x2A, bytes((0x00, 0x02, 0x00, 0x81)))  # columnas 2..129
    command(0x2B, bytes((0x00, 0x01, 0x00, 0x80)))  # filas visibles 1..128
    command(0xE0, bytes((0x0F,0x1A,0x0F,0x18,0x2F,0x28,0x20,0x22,0x1F,0x1B,0x23,0x37,0x00,0x07,0x02,0x10)))
    command(0xE1, bytes((0x0F,0x1B,0x0F,0x17,0x33,0x2C,0x29,0x2E,0x30,0x30,0x39,0x3F,0x00,0x07,0x03,0x10)))
    command(0x13)  # NORON
    time.sleep_ms(10)
    command(0x29)  # DISPON
    time.sleep_ms(100)


# RGB565 colors
BLACK = 0x0000
NAVY = 0x0843
BLUE = 0x1190
PURPLE = 0x6012
PINK = 0xF986
ORANGE = 0xFC60
YELLOW = 0xFFE0
WHITE = 0xFFFF
TEAL = 0x04F5
GREEN = 0x2588
DARK = 0x10A3

buf = bytearray(WIDTH * HEIGHT * 2)


def pixel(x, y, color):
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        i = (y * WIDTH + x) * 2
        buf[i] = color >> 8
        buf[i + 1] = color & 255


def rect(x, y, w, h, color):
    if w <= 0 or h <= 0:
        return
    pair = bytes((color >> 8, color & 255))
    row = pair * w
    for yy in range(max(0, y), min(HEIGHT, y + h)):
        left = max(0, x)
        right = min(WIDTH, x + w)
        if right > left:
            start = (yy * WIDTH + left) * 2
            buf[start:start + (right-left)*2] = pair * (right-left)


def circle(cx, cy, radius, color):
    rr = radius * radius
    for yy in range(max(0, cy-radius), min(HEIGHT, cy+radius+1)):
        dy = yy - cy
        dx = int((rr - dy*dy) ** 0.5)
        rect(cx-dx, yy, dx*2+1, 1, color)


def line(x0, y0, x1, y1, color):
    dx = abs(x1-x0)
    sx = 1 if x0 < x1 else -1
    dy = -abs(y1-y0)
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        pixel(x0, y0, color)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


# Tiny 3x5 bitmap font: enough for the demo title.
FONT = {
 'H':('101','101','111','101','101'), 'O':('111','101','101','101','111'),
 'L':('100','100','100','100','111'), 'A':('010','101','111','101','101'),
 'E':('111','100','110','100','111'), 'S':('011','100','111','001','110'),
 'P':('110','101','110','100','100'), '3':('110','001','011','001','110'),
 '2':('110','001','010','100','111'), ' ':('000','000','000','000','000')
}


def text3x5(x, y, message, color, scale=2):
    for char in message:
        glyph = FONT.get(char, FONT[' '])
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == '1':
                    rect(x + gx*scale, y + gy*scale, scale, scale, color)
        x += 4 * scale


init_display()
# Fondo nocturno con sol de atardecer y montañas estilo 16-bit.
for y in range(HEIGHT):
    color = NAVY if y < 55 else BLUE if y < 85 else PURPLE
    rect(0, y, WIDTH, 1, color)
# Estrellas
for x, y, size in ((12,14,2),(29,31,1),(48,12,1),(93,22,2),(113,39,1),(75,42,1),(18,55,1),(108,12,1)):
    rect(x, y, size, size, WHITE)
# Sol rayado
circle(91, 58, 22, ORANGE)
circle(91, 58, 17, YELLOW)
rect(69, 56, 45, 4, ORANGE)
rect(72, 64, 39, 3, ORANGE)
# Cordillera y silueta en capas
for y in range(69, 105):
    peak1 = 17 + abs(y-82)*2
    peak2 = 69 - abs(y-78)*2
    peak3 = 111 + abs(y-88)*2
    for x in range(WIDTH):
        if x < peak1 or (45 < x < peak2) or x > peak3:
            pixel(x, y, TEAL if y < 88 else GREEN)
# Reflejo/primer plano
for y in range(100, 128):
    rect(0, y, WIDTH, 1, DARK if y % 6 < 3 else GREEN)
# Marco y rótulo
rect(4, 4, 120, 2, PINK); rect(4, 122, 120, 2, PINK)
rect(4, 4, 2, 120, PINK); rect(122, 4, 2, 120, PINK)
rect(27, 106, 74, 13, BLACK)
text3x5(37, 109, 'HOLA', WHITE, 2)
text3x5(70, 109, 'ESP32', YELLOW, 2)

# Enviar la imagen completa al LCD.
cs.value(0)
dc.value(0)
spi.write(bytes((0x2A,)))
dc.value(1)
spi.write(bytes((0x00, 0x02, 0x00, 0x81)))
dc.value(0)
spi.write(bytes((0x2B,)))
dc.value(1)
spi.write(bytes((0x00, 0x01, 0x00, 0x80)))
dc.value(0)
spi.write(bytes((0x2C,)))
dc.value(1)
spi.write(buf)
cs.value(1)
print('Demo dibujada en la pantalla. Para volver al programa Wi-Fi, reiniciá la placa con EN o ejecutá mpremote reset.')
