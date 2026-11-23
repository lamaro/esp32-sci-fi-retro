# Prueba de colores y cuadrícula para pantalla ST7735S 128x128.
# Ejecutar: mpremote connect /dev/cu.usbserial-0001 run demo_colores.py
import machine
import time

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


# Inicialización ST7735S usada por la demo del atardecer.
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

# Ocho parches RGB565: rojo, verde, azul, blanco / negro, cian, magenta, amarillo.
colors = (0xF800, 0x07E0, 0x001F, 0xFFFF,
          0x0000, 0x07FF, 0xF81F, 0xFFE0)
buf = bytearray(128 * 128 * 2)
for y in range(128):
    row = 0 if y < 64 else 1
    for x in range(128):
        col = x // 32
        color = colors[row * 4 + col]
        # Separadores de cuadrícula; oscuros sobre colores claros, blancos sobre oscuros.
        if x in (0, 31, 32, 63, 64, 95, 96, 127) or y in (0, 63, 64, 127):
            color = 0x0000 if color in (0xFFFF, 0xFFE0) else 0xFFFF
        i = (y * 128 + x) * 2
        buf[i] = color >> 8
        buf[i + 1] = color & 0xFF

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
print('Prueba de colores y cuadrícula dibujada.')
