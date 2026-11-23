# Animación temporal: orbe pixel art rebotando en la pantalla ST7735S 128x128.
# Ejecutar: mpremote connect /dev/cu.usbserial-0001 run demo_animacion.py
# No reemplaza el main.py permanente.
import machine
import time
import math

WIDTH = 128
HEIGHT = 128
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


# Inicialización ST7735S probada con el MSP1443.
rst.value(1)
time.sleep_ms(20)
rst.value(0)
time.sleep_ms(40)
rst.value(1)
time.sleep_ms(120)
command(0x01)
time.sleep_ms(150)
command(0x11)
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
command(0x20)
command(0x36, bytes((0x08,)))  # pines del LCD arriba (consola)
command(0x3A, bytes((0x05,)))
command(0x2A, bytes((0x00, 0x02, 0x00, 0x81)))
command(0x2B, bytes((0x00, 0x01, 0x00, 0x80)))
command(0xE0, bytes((0x0F,0x1A,0x0F,0x18,0x2F,0x28,0x20,0x22,0x1F,0x1B,0x23,0x37,0x00,0x07,0x02,0x10)))
command(0xE1, bytes((0x0F,0x1B,0x0F,0x17,0x33,0x2C,0x29,0x2E,0x30,0x30,0x39,0x3F,0x00,0x07,0x03,0x10)))
command(0x13)
time.sleep_ms(10)
command(0x29)
time.sleep_ms(100)

BLACK = 0x0000
NAVY = 0x0843
BLUE = 0x1190
PURPLE = 0x4010
PINK = 0xF986
CYAN = 0x07FF
YELLOW = 0xFFE0
WHITE = 0xFFFF
DARK = 0x18C3


def rgb_bytes(color):
    return bytes((color >> 8, color & 0xFF))


def put_pixel(buf, x, y, color):
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        i = (y * WIDTH + x) * 2
        buf[i] = color >> 8
        buf[i + 1] = color & 0xFF


def disk(buf, cx, cy, radius, color):
    r2 = radius * radius
    for y in range(max(0, cy-radius), min(HEIGHT, cy+radius+1)):
        dy = y - cy
        dx = int(math.sqrt(r2 - dy*dy))
        start_x = max(0, cx - dx)
        end_x = min(WIDTH, cx + dx + 1)
        if end_x > start_x:
            start = (y * WIDTH + start_x) * 2
            buf[start:start + (end_x-start_x)*2] = rgb_bytes(color) * (end_x-start_x)


# Fondo estático: cielo nocturno, estrellas y una línea de horizonte.
background = bytearray(WIDTH * HEIGHT * 2)
for y in range(HEIGHT):
    color = NAVY if y < 64 else BLUE if y < 94 else PURPLE if y < 112 else DARK
    row = rgb_bytes(color) * WIDTH
    start = y * WIDTH * 2
    background[start:start + WIDTH*2] = row
for sx, sy in ((12,12),(31,34),(49,18),(93,14),(111,39),(73,48),(19,59),(119,66),(54,52)):
    put_pixel(background, sx, sy, WHITE)
for x in range(WIDTH):
    put_pixel(background, x, 112, PINK if x % 8 < 4 else CYAN)

# Enviar cada fotograma completo. Unos 7 segundos de animación.
frame = bytearray(WIDTH * HEIGHT * 2)
x = 18.0
y = 73.0
vx = 2.4
vy = -3.3
gravity = 0.22
radius = 11

for _ in range(150):
    frame[:] = background
    # Sombra sobre el suelo y tres píxeles de estela.
    disk(frame, int(x), 113, 5, 0x3186)
    disk(frame, int(x - vx*2), int(y - vy*2), 2, PURPLE)
    disk(frame, int(x - vx), int(y - vy), 3, 0x7815)
    # Orbe con borde cian, centro amarillo y un reflejo blanco.
    disk(frame, int(x), int(y), radius, CYAN)
    disk(frame, int(x), int(y), radius-3, YELLOW)
    disk(frame, int(x-3), int(y-4), 2, WHITE)

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
    spi.write(frame)
    cs.value(1)

    x += vx
    if x < radius or x > WIDTH-radius:
        vx = -vx
        x += vx
    y += vy
    vy += gravity
    if y > 99:
        y = 99
        vy = -abs(vy) * 0.88
    time.sleep_ms(35)

print('Animación terminada. Presioná EN para volver a iniciar el programa Wi-Fi.')
