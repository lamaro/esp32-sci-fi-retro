# Demo temporal para probar el efecto holograma (Pepper's ghost) con una
# lámina transparente (tapa de caja de CD) delante de la pantalla.
#
# Ejecutar:  mpremote connect /dev/cu.usbserial-0001 run demo_holograma.py
# No reemplaza el main.py permanente: al terminar, presioná EN para volver.
#
# Muestra un cubo en wireframe cian girando sobre una base "emisora", con
# scanlines, barrido y glitches. El fondo es negro puro: en el reflejo no se ve.
#
# El reflejo invierte la imagen. La demo va alternando tres orientaciones
# (NORMAL, ESPEJO V y ESPEJO H) cada CICLO_MS. Mirando el reflejo, anotá en
# cuál el texto se lee derecho: esa es la que va a usar la versión holo.
import machine
import framebuf
import math
import random
import time
import micropython

WIDTH = 128
HEIGHT = 128
CICLO_MS = 10000        # tiempo de cada orientación
DURACION_S = 300        # duración total de la demo
FIJA = None             # poné 0, 1 o 2 para dejar una sola orientación

# (MADCTL, margen X, margen Y, nombre). Base: 0x08 = pines arriba, sin espejar.
#   MY (0x80) invierte las filas, MX (0x40) las columnas.
ORIENTACIONES = (
    (0x08, 2, 1, "NORMAL"),
    (0x88, 2, 3, "ESPEJO V"),
    (0x48, 2, 1, "ESPEJO H"),
)

spi = machine.SPI(1, baudrate=20000000, polarity=0, phase=0,
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


def init_lcd():
    # Misma inicialización ST7735S que display_ui.py
    rst.value(1); time.sleep_ms(20)
    rst.value(0); time.sleep_ms(40)
    rst.value(1); time.sleep_ms(120)
    command(0x01); time.sleep_ms(150)
    command(0x11); time.sleep_ms(120)
    command(0xB1, bytes((1, 44, 45)))
    command(0xB2, bytes((1, 44, 45)))
    command(0xB3, bytes((1, 44, 45, 1, 44, 45)))
    command(0xB4, bytes((7,)))
    command(0xC0, bytes((0xA2, 2, 0x84)))
    command(0xC1, bytes((0xC5,)))
    command(0xC2, bytes((10, 0)))
    command(0xC3, bytes((0x8A, 0x2A)))
    command(0xC4, bytes((0x8A, 0xEE)))
    command(0xC5, bytes((14,)))
    command(0x20)
    command(0x3A, bytes((5,)))
    command(0xE0, bytes((15, 26, 15, 24, 47, 40, 32, 34, 31, 27, 35, 55, 0, 7, 2, 16)))
    command(0xE1, bytes((15, 27, 15, 23, 51, 44, 41, 46, 48, 48, 57, 63, 0, 7, 3, 16)))
    command(0x13); time.sleep_ms(10)
    command(0x29); time.sleep_ms(100)


win = [bytes(4), bytes(4)]


def orientar(i):
    mad, xo, yo, _ = ORIENTACIONES[i]
    command(0x36, bytes((mad,)))
    win[0] = bytes((0, xo, 0, xo + WIDTH - 1))
    win[1] = bytes((0, yo, 0, yo + HEIGHT - 1))


def enviar(buf):
    cs.value(0)
    dc.value(0); spi.write(b"\x2a")
    dc.value(1); spi.write(win[0])
    dc.value(0); spi.write(b"\x2b")
    dc.value(1); spi.write(win[1])
    dc.value(0); spi.write(b"\x2c")
    dc.value(1); spi.write(buf)
    cs.value(1)


# framebuf guarda RGB565 en little endian y el LCD lo espera en big endian:
# se pasan los colores con los bytes invertidos.
def c565(r, g, b):
    c = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
    return ((c & 0xFF) << 8) | (c >> 8)


CYAN = c565(60, 255, 235)
GLOW = c565(0, 90, 100)
DIM = c565(0, 45, 60)
WHITE = c565(255, 255, 255)
BEAM = c565(0, 60, 80)


@micropython.viper
def scanlines(buf, fase: int):
    # Oscurece a la mitad una fila de cada dos (colores en big endian).
    b = ptr8(buf)
    y = fase
    while y < 128:
        i = y * 256
        fin = i + 256
        while i < fin:
            c = (b[i] << 8) | b[i + 1]
            if c:
                c = (c >> 1) & 0x7BEF
                b[i] = c >> 8
                b[i + 1] = c & 0xFF
            i += 2
        y += 2


def glitch(buf, y0, alto, dx):
    # Corre horizontalmente una franja de filas.
    for y in range(y0, min(HEIGHT, y0 + alto)):
        a = y * 256
        fila = bytes(buf[a:a + 256])
        s = (dx % WIDTH) * 2
        buf[a:a + 256] = fila[256 - s:] + fila[:256 - s]


VERT = [(x, y, z) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
ARISTAS = [(a, b) for a in range(8) for b in range(a + 1, 8)
           if sum(VERT[a][k] != VERT[b][k] for k in range(3)) == 1]


def proyectar(ax, ay, cx, cy, escala):
    sa, ca, sb, cb = math.sin(ay), math.cos(ay), math.sin(ax), math.cos(ax)
    out = []
    for x, y, z in VERT:
        x, z = x * ca + z * sa, -x * sa + z * ca
        y, z = y * cb - z * sb, y * sb + z * cb
        f = escala / (z + 4.2)
        out.append((int(cx + x * f), int(cy + y * f), z))
    return out


def main():
    init_lcd()
    buf = bytearray(WIDTH * HEIGHT * 2)
    fb = framebuf.FrameBuffer(buf, WIDTH, HEIGHT, framebuf.RGB565)
    t0 = time.ticks_ms()
    modo = -1
    barrido = 0
    glitch_hasta = 0
    cuadros = 0
    while time.ticks_diff(time.ticks_ms(), t0) < DURACION_S * 1000:
        ahora = time.ticks_diff(time.ticks_ms(), t0)
        m = FIJA if FIJA is not None else (ahora // CICLO_MS) % len(ORIENTACIONES)
        if m != modo:
            modo = m
            orientar(modo)
            print("Orientación:", ORIENTACIONES[modo][3])
        t = ahora / 1000

        fb.fill(0)
        # base emisora con anillos que laten
        pulso = int(3 * (1 + math.sin(t * 4)))
        fb.ellipse(64, 114, 34, 7, DIM, True)
        fb.ellipse(64, 114, 34, 7, GLOW)
        fb.ellipse(64, 114, 22 + pulso, 4 + pulso // 3, CYAN)
        fb.ellipse(64, 114, 8, 2, WHITE, True)
        # haz desde la base hacia el cubo
        for x0, x1 in ((34, 38), (94, 90), (50, 52), (78, 76)):
            fb.line(x0, 112, x1, 82, BEAM)

        # cubo flotando, con un halo desplazado 1 px para que "brille"
        cy = 62 + int(3 * math.sin(t * 1.3))
        p = proyectar(t * 0.7, t * 1.1, 64, cy, 78)
        for a, b in ARISTAS:
            fb.line(p[a][0] + 1, p[a][1] + 1, p[b][0] + 1, p[b][1] + 1, GLOW)
        parpadeo = random.random() < 0.04
        for a, b in ARISTAS:
            fb.line(p[a][0], p[a][1], p[b][0], p[b][1], DIM if parpadeo else CYAN)
        for x, y, z in p:
            if z < 0:
                fb.fill_rect(x - 1, y - 1, 3, 3, WHITE)

        # título y orientación actual (para elegir la que se lee derecha)
        fb.text("HOLO-01", 36, 4, CYAN)
        fb.text(ORIENTACIONES[modo][3], 64 - 4 * len(ORIENTACIONES[modo][3]), 16, GLOW)

        # barrido horizontal tenue
        barrido = (barrido + 3) % 160
        if barrido < HEIGHT:
            fb.hline(0, barrido, WIDTH, DIM)

        scanlines(buf, 1)

        # glitch ocasional
        if ahora < glitch_hasta or random.random() < 0.02:
            if ahora >= glitch_hasta:
                glitch_hasta = ahora + 120
            glitch(buf, random.randint(30, 100), random.randint(3, 9), random.choice((-6, -3, 4, 7)))

        enviar(buf)
        cuadros += 1

    fb.fill(0)
    enviar(buf)
    seg = time.ticks_diff(time.ticks_ms(), t0) / 1000
    print("Fin de la demo:", cuadros, "cuadros,", round(cuadros / seg, 1), "por segundo.")
    print("Presioná EN para volver al programa normal.")


main()
