"""Interfaz simple para la pantalla ST7735S 128x128."""
import machine
import time
import math
import random
from font5x7 import FONT57
from weather import Weather, describe
try:
    from micropython import native     # compila a código nativo las funciones más usadas
except ImportError:                     # simulador en la computadora
    def native(f):
        return f

WIDTH = 128
HEIGHT = 128
STRIP_ROWS = 8
BLACK, NAVY, BLUE, PURPLE = 0x0000, 0x0843, 0x1190, 0x6012
PINK, ORANGE, YELLOW, WHITE = 0xF986, 0xFC60, 0xFFE0, 0xFFFF
TEAL, GREEN, DARK = 0x04F5, 0x2588, 0x10A3
TERM, TERM_DIM, RED, HAZARD = 0x37E6, 0x0300, 0xF800, 0xFBE0
GRAY, LIGHT, SLATE, SKY = 0x8410, 0xC618, 0x4208, 0x3D9F

# Orientación del LCD. En la consola la pantalla va con los pines ARRIBA.
#   0x08 = sin espejar (pines arriba), márgenes de la memoria 2 y 1.
#   0xC8 = girada 180° (pines abajo), márgenes 2 y 3.
MADCTL = 0x08
X_OFF = 2
Y_OFF = 1
SPI_BAUD = 20000000

MODES = ("status", "sunset", "colors", "animation", "text", "console", "hacker", "fatal", "weather", "random")
RANDOM_POOL = ("status", "sunset", "colors", "animation", "console", "hacker", "fatal", "weather")
RANDOM_MS = 20000
ANIM_MS = 20            # objetivo: hasta 50 cuadros por segundo

# Consola: 21 columnas x 13 filas de texto 5x7 bajo una barra de título.
CON_X, CON_TOP, CON_LH, CON_ROWS = 2, 12, 9, 13
# Fragmentos del firmware real, acortados a 21 columnas.
#   "#" = comentario (verde tenue), "~" = salida del programa (aparece de golpe).
CODE = (
    "# main.py - ESP32 API", "import json, socket", "import network",
    "from machine import *", "", "def connect_wifi():", "  w = network.WLAN(",
    "    network.STA_IF)", "  w.active(True)", "  w.connect(ssid, pw)",
    "  while not w.ok():", "    time.sleep_ms(250)", "  return w.ifconfig()", "",
    "def serve(client):", "  req = read(client)", "  if req is None:",
    "    return send(400)", "  if not auth(req):", "    return send(401)",
    "  if path == '/led':", "    led.value(on)", "  send(200, state())", "",
    "# display_ui.py", "def update(self):", "  for s in range(16):",
    "    self.y0 = s * 8", "    self.draw(view)", "    self.flush()", "",
    "while True:", "  client = accept()", "  serve(client)",
    "  display.update()", "", ">>> import main", "~wifi: connected",
    "~api: listening :80", "~display: ready", ">>> ", "",
)
# Terminal hacker (todo ficticio). Marcas: "$" comando tipeado, "~" salida,
# "!" aviso destacado, "%XXXX" barra de progreso, "*N" N líneas de volcado hex.
HACK = (
    "$ ssh root@node-7", "~connecting...", "~key exchange ok", "!ACCESS DENIED",
    "$ sudo crack --fast", "%HASH", "*6", "!ACCESS GRANTED", "$ ls /secure",
    "~core.bin  keys.db", "~logs/  vault/", "$ cat vault/keys.db", "*9",
    "$ decrypt keys.db", "%DECR", "~3 keys recovered", "$ nmap -sS 10.0.0.0",
    "~22/tcp   open  ssh", "~80/tcp   open  http", "~443/tcp  filtered",
    "$ upload payload.py", "%UPLD", "!TRACE DETECTED", "$ wipe --logs", "%WIPE",
    "~done. disconnecting", "$ exit", "~",
)
# vista -> (guion, título, ms entre teclas, letras extra por paso, pausa tras salida)
TERMINALS = {
    "console": (CODE, "PYTHON 3 :: ESP32", 30, 1, 300),
    "hacker": (HACK, "ROOT@ESP32 :: TTY1", 22, 2, 45),
}


def glyph_table(fg, bg):
    """32 filas posibles de 5 px (+1 de separación) ya convertidas a bytes."""
    f = bytes((fg >> 8, fg & 255))
    b = bytes((bg >> 8, bg & 255))
    return [b"".join([f if m & (16 >> c) else b for c in range(5)]) + b for m in range(32)]


class Display:
    def __init__(self, ip):
        self.ip = ip
        self.mode = "status"
        self.view = None
        self.view_since = time.ticks_ms()
        self.message = ""
        self.dirty = True
        self.last_frame = time.ticks_ms()
        self.blink = False
        self.reset_ball()
        self.reset_console()
        # Eight-row streaming buffer uses 2 KB instead of a 32 KB framebuffer.
        self.buf = bytearray(WIDTH * STRIP_ROWS * 2)
        self.zero = bytes(len(self.buf))
        self.rows = {}          # filas de un color y ancho, para no armarlas en cada cuadro
        self.spans = {}         # medio ancho de cada fila de un círculo, por radio
        self.y0 = 0
        self.t_term = glyph_table(TERM, BLACK)
        self.t_dim = glyph_table(TERM_DIM, BLACK)
        self.t_head = glyph_table(BLACK, TERM)
        self.t_alarm_on = glyph_table(BLACK, RED)
        self.t_alarm_off = glyph_table(HAZARD, BLACK)
        self.t_wx = glyph_table(WHITE, NAVY)
        self.t_wx_dim = glyph_table(TEAL, NAVY)
        self.t_wx_head = glyph_table(NAVY, TEAL)
        self.t_wx_warn = glyph_table(ORANGE, NAVY)
        self.weather = Weather()
        self.spi = machine.SPI(1, baudrate=SPI_BAUD, polarity=0, phase=0,
                               sck=machine.Pin(14), mosi=machine.Pin(13), miso=machine.Pin(12))
        self.cs = machine.Pin(21, machine.Pin.OUT, value=1)
        self.dc = machine.Pin(22, machine.Pin.OUT, value=1)
        self.rst = machine.Pin(4, machine.Pin.OUT, value=1)
        self.init()

    def command(self, value, data=None):
        self.cs.value(0)
        self.dc.value(0)
        self.spi.write(bytes((value,)))
        if data is not None:
            self.dc.value(1)
            self.spi.write(data)
        self.cs.value(1)

    def init(self):
        time.sleep_ms(20)
        self.rst.value(0)
        time.sleep_ms(40)
        self.rst.value(1)
        time.sleep_ms(120)
        self.command(0x01); time.sleep_ms(150)
        self.command(0x11); time.sleep_ms(120)
        self.command(0xB1, bytes((1, 44, 45)))
        self.command(0xB2, bytes((1, 44, 45)))
        self.command(0xB3, bytes((1, 44, 45, 1, 44, 45)))
        self.command(0xB4, bytes((7,)))
        self.command(0xC0, bytes((0xA2, 2, 0x84)))
        self.command(0xC1, bytes((0xC5,)))
        self.command(0xC2, bytes((10, 0)))
        self.command(0xC3, bytes((0x8A, 0x2A)))
        self.command(0xC4, bytes((0x8A, 0xEE)))
        self.command(0xC5, bytes((14,)))
        self.command(0x20)
        self.command(0x36, bytes((MADCTL,)))
        self.command(0x3A, bytes((5,)))
        self.command(0x2A, bytes((0, X_OFF, 0, X_OFF + WIDTH - 1)))
        self.command(0x2B, bytes((0, Y_OFF, 0, Y_OFF + HEIGHT - 1)))
        self.command(0xE0, bytes((15,26,15,24,47,40,32,34,31,27,35,55,0,7,2,16)))
        self.command(0xE1, bytes((15,27,15,23,51,44,41,46,48,48,57,63,0,7,3,16)))
        self.command(0x13); time.sleep_ms(10)
        self.command(0x29); time.sleep_ms(100)

    def pixel(self, x, y, color):
        if 0 <= x < WIDTH and self.y0 <= y < self.y0 + STRIP_ROWS:
            i = ((y - self.y0) * WIDTH + x) * 2
            self.buf[i] = color >> 8
            self.buf[i + 1] = color & 255

    @native
    def rect(self, x, y, w, h, color):
        if w <= 0 or h <= 0:
            return
        left, right = max(0, x), min(WIDTH, x + w)
        if right <= left:
            return
        key = (color << 8) | (right - left)
        row = self.rows.get(key)
        if row is None:
            row = self.rows[key] = bytes((color >> 8, color & 255)) * (right - left)
        for yy in range(max(self.y0, y), min(self.y0 + STRIP_ROWS, y + h)):
            start = ((yy - self.y0) * WIDTH + left) * 2
            self.buf[start:start + len(row)] = row

    @native
    def circle(self, cx, cy, radius, color):
        half = self.spans.get(radius)
        if half is None:
            half = self.spans[radius] = bytes(int(math.sqrt(radius * radius - d * d)) for d in range(-radius, radius + 1))
        for yy in range(max(self.y0, cy - radius), min(self.y0 + STRIP_ROWS, cy + radius + 1)):
            dx = half[yy - cy + radius]
            self.rect(cx - dx, yy, dx * 2 + 1, 1, color)

    def text(self, x, y, message, color, scale=1):
        if y + 5 * scale <= self.y0 or y >= self.y0 + STRIP_ROWS:
            return
        for char in message:
            glyph = FONT.get(char, FONT[' '])
            for gy, row in enumerate(glyph):
                for gx, bit in enumerate(row):
                    if bit == '1':
                        self.rect(x + gx*scale, y + gy*scale, scale, scale, color)
            x += 4 * scale

    @native
    def text57(self, x, y, message, table):
        """Texto 5x7 rápido: una copia de 12 bytes por fila de cada carácter."""
        top = self.y0
        if y + 7 <= top or y >= top + STRIP_ROWS:
            return
        message = message[:(WIDTH - x) // 6]
        buf = self.buf
        for r in range(max(0, top - y), min(7, top + STRIP_ROWS - y)):
            off = ((y + r - top) * WIDTH + x) * 2
            for ch in message:
                code = ord(ch) - 32
                if code < 0 or code > 94:
                    code = 0
                buf[off:off + 12] = table[FONT57[code * 7 + r]]
                off += 12

    def flush(self):
        y_start = self.y0 + Y_OFF
        y_end = y_start + STRIP_ROWS - 1
        self.cs.value(0)
        self.dc.value(0); self.spi.write(bytes((0x2A,)))
        self.dc.value(1); self.spi.write(bytes((0, X_OFF, 0, X_OFF + WIDTH - 1)))
        self.dc.value(0); self.spi.write(bytes((0x2B,)))
        self.dc.value(1); self.spi.write(bytes((0, y_start, 0, y_end)))
        self.dc.value(0); self.spi.write(bytes((0x2C,)))
        self.dc.value(1); self.spi.write(self.buf)
        self.cs.value(1)

    # ------------------------------------------------------------ modos
    def set_mode(self, mode, message=""):
        if mode not in MODES:
            return False
        self.mode = mode
        self.message = message if mode == "text" else ""
        self.dirty = True
        if mode == "random":
            self.view = None
        else:
            self.enter(mode)
        return True

    def current(self):
        return self.view if self.mode == "random" else self.mode

    def enter(self, view):
        if view == "animation":
            self.reset_ball()
        elif view in TERMINALS:
            self.reset_console(view)
        elif view == "fatal":
            self.blink = True
        self.last_frame = time.ticks_ms()

    def pick_random(self, now):
        options = [m for m in RANDOM_POOL if m != self.view]
        self.view = options[random.getrandbits(8) % len(options)]
        self.view_since = now
        self.enter(self.view)
        self.dirty = True

    # ------------------------------------------------------------ animación
    def reset_ball(self):
        self.x, self.y = 18.0, 73.0
        self.vx, self.vy = 2.4, -3.3

    def step_ball(self, dt):
        """Física por tiempo (la velocidad no depende de los FPS). Devuelve las franjas a redibujar."""
        k = min(dt, 60) / 35
        y_before, vy_before = self.y, self.vy
        self.x += self.vx * k
        if self.x < 11 or self.x > WIDTH - 11:
            self.vx = -self.vx
            self.x = min(max(self.x, 11), WIDTH - 11)
        self.y += self.vy * k
        self.vy += 0.22 * k
        if self.y > 99:
            self.y = 99
            self.vy = -abs(self.vy) * 0.88
            if self.vy > -2.2:          # que nunca se quede quieta
                self.vy = -5.2
        # filas que ocupan la pelota (radio 11) y su estela (hasta 2 pasos atrás), antes y después
        ys = (y_before, y_before - 2 * vy_before, self.y, self.y - 2 * self.vy)
        return ((int(min(ys)) - 12, int(max(ys)) + 13), (106, 120))

    # ------------------------------------------------------------ consola
    def reset_console(self, view="console"):
        self.c_cfg = TERMINALS.get(view, TERMINALS["console"])
        self.c_idx = 0
        self.c_queue = []
        self.c_cur = self.next_line()
        self.c_lines = [""]
        self.c_col = 0
        self.c_next = time.ticks_ms()

    def next_line(self):
        if self.c_queue:
            return self.c_queue.pop(0)
        script = self.c_cfg[0]
        line = script[self.c_idx]
        self.c_idx = (self.c_idx + 1) % len(script)
        if line.startswith("*"):
            bits = random.getrandbits
            self.c_queue = ["~%04X %04X %04X %04X" % (bits(16), bits(16), bits(16), bits(16))
                            for _ in range(int(line[1:]))]
            return self.c_queue.pop(0)
        return line

    def console_step(self, now):
        if time.ticks_diff(now, self.c_next) < 0:
            return None
        _script, _title, key_ms, extra, out_pause = self.c_cfg
        line = self.c_cur
        row = len(self.c_lines) - 1
        y = CON_TOP + row * CON_LH
        if line.startswith("%"):
            if self.c_col < 100:
                self.c_col = min(100, self.c_col + 2 + random.getrandbits(3))
                done = self.c_col // 10
                self.c_lines[-1] = "%%%s[%s%s]%3d%%" % (line[1:5], "#" * done, "." * (10 - done), self.c_col)
                self.c_next = time.ticks_add(now, 45)
                return ((y, y + 8),)
        elif self.c_col < len(line):
            if line[0] in "~!":
                self.c_col = len(line)
            else:
                self.c_col = min(len(line), self.c_col + 1 + random.getrandbits(1) * extra)
            self.c_lines[-1] = line[:self.c_col]
            self.c_next = time.ticks_add(now, key_ms + random.getrandbits(4))
            return ((y - 1, y + 8),)
        # línea terminada: pasar a la siguiente
        if line[:1] in "~!%":
            pause = out_pause
        elif line.startswith("$") or line.startswith(">>>"):
            pause = 280
        else:
            pause = 60
        self.c_cur = self.next_line()
        self.c_col = 0
        self.c_lines.append("")
        self.c_next = time.ticks_add(now, pause)
        if len(self.c_lines) > CON_ROWS:
            self.c_lines.pop(0)
            return ((CON_TOP - 1, HEIGHT),)
        return ((y - 1, y + CON_LH + 8),)

    def draw_console(self):
        if self.y0 < 10:
            self.rect(0, 0, WIDTH, 10, TERM)
            self.text57(2, 1, self.c_cfg[1], self.t_head)
        last = len(self.c_lines) - 1
        for i, raw in enumerate(self.c_lines):
            y = CON_TOP + i * CON_LH
            if y + 8 <= self.y0 or y - 1 >= self.y0 + STRIP_ROWS:
                continue
            mark = raw[:1]
            shown = raw[1:] if mark in "~!%" else raw
            if mark == "!":
                self.rect(0, y - 1, WIDTH, 9, TERM)
                table = self.t_head
            elif mark == "~" or mark == "#":
                table = self.t_dim
            else:
                table = self.t_term
            self.text57(CON_X, y, shown, table)
            if i == last and mark != "!":
                self.rect(CON_X + len(shown) * 6, y, 5, 7, TERM)

    # ------------------------------------------------------------ error fatal
    def hazard(self, y_a, y_b, color):
        for y in range(max(self.y0, y_a), min(self.y0 + STRIP_ROWS, y_b)):
            self.rect(0, y, WIDTH, 1, BLACK)
            shift = y % 16
            for x in range(-16, WIDTH, 16):
                self.rect(x + shift, y, 8, 1, color)

    def draw_fatal(self):
        on = self.blink
        self.rect(0, 0, WIDTH, HEIGHT, RED if on else BLACK)
        self.hazard(0, 13, HAZARD)
        self.hazard(115, 128, HAZARD)
        big = BLACK if on else RED
        self.text(26, 22, "FATAL", big, 4)
        self.text(26, 48, "ERROR", big, 4)
        table = self.t_alarm_on if on else self.t_alarm_off
        self.text57(25, 78, "SYSTEM HALTED", table)
        self.text57(25, 89, "CODE 0x7F3A00", table)
        self.text57(31, 100, "! DANGER !", table)

    # ------------------------------------------------------------ escenas fijas
    def draw_message(self):
        self.rect(0, 0, WIDTH, HEIGHT, NAVY)
        lines = self.message.split("\n")
        for i, line in enumerate(lines):
            self.text((WIDTH - len(line) * 8 + 2) // 2,
                      59 - (len(lines) - 1) * 8 + i * 16, line, WHITE, 2)

    def draw_status(self):
        self.rect(0, 0, 128, 128, NAVY)
        self.rect(0, 0, 128, 5, GREEN)
        self.text(10, 15, "ESP32 ONLINE", WHITE, 2)
        self.rect(10, 39, 108, 1, TEAL)
        self.text(10, 52, "WIFI OK", YELLOW, 2)
        self.text(10, 79, "IP LOCAL", WHITE, 1)
        self.text(10, 94, self.ip, TEAL, 1)
        self.text(10, 113, "NEXTJS READY", WHITE, 1)

    def draw_sunset(self):
        for y in range(self.y0, self.y0 + STRIP_ROWS):
            self.rect(0, y, WIDTH, 1, NAVY if y < 55 else BLUE if y < 85 else PURPLE)
        for x, y, size in ((12,14,2),(29,31,1),(48,12,1),(93,22,2),(113,39,1),(75,42,1),(18,55,1),(108,12,1)):
            self.rect(x, y, size, size, WHITE)
        self.circle(91, 58, 22, ORANGE); self.circle(91, 58, 17, YELLOW)
        self.rect(69, 56, 45, 4, ORANGE); self.rect(72, 64, 39, 3, ORANGE)
        for y in range(69, 105):
            self.rect(0, y, 128, 1, NAVY if y < 80 else BLUE if y < 91 else PURPLE)
        for x in range(128):
            self.pixel(x, 104, TEAL if x % 12 < 6 else PINK)
        self.text(12, 115, "SUNSET DEMO", WHITE, 1)

    def draw_colors(self):
        colors = (BLACK, NAVY, BLUE, PURPLE, PINK, ORANGE, YELLOW, WHITE)
        for i, color in enumerate(colors):
            self.rect((i % 2)*64, (i // 2)*32, 64, 32, color)
        self.text(15, 108, "RGB565 TEST", WHITE, 2)

    def draw_animation(self):
        self.rect(0, 0, WIDTH, HEIGHT, NAVY)
        for y in range(max(64, self.y0), min(112, self.y0 + STRIP_ROWS)):
            self.rect(0, y, WIDTH, 1, BLUE if y < 94 else PURPLE)
        self.rect(0, 112, WIDTH, 16, DARK)
        for sx, sy in ((12,12),(31,34),(49,18),(93,14),(111,39),(73,48),(19,59),(119,66),(54,52)):
            self.pixel(sx, sy, WHITE)
        self.rect(0, 112, WIDTH, 1, TEAL)
        self.circle(int(self.x), 113, 5, 0x3186)
        self.circle(int(self.x-self.vx*2), int(self.y-self.vy*2), 2, PURPLE)
        self.circle(int(self.x-self.vx), int(self.y-self.vy), 3, 0x7815)
        self.circle(int(self.x), int(self.y), 11, TEAL)
        self.circle(int(self.x), int(self.y), 8, YELLOW)
        self.circle(int(self.x-3), int(self.y-4), 2, WHITE)

    # ------------------------------------------------------------ clima
    def cloud(self, x, y, color):
        """Nube de unos 34 x 18 px con el borde inferior en y."""
        self.circle(x + 9, y - 6, 6, color)
        self.circle(x + 19, y - 10, 9, color)
        self.circle(x + 28, y - 6, 6, color)
        self.rect(x + 3, y - 6, 31, 7, color)

    def sun(self, cx, cy, r):
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            self.rect(cx + dx * (r + 3) - 1, cy + dy * (r + 3) - 1, 3, 3, YELLOW)
        for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
            self.rect(cx + dx * (r + 1) - 1, cy + dy * (r + 1) - 1, 2, 2, YELLOW)
        self.circle(cx, cy, r, YELLOW)

    def moon(self, cx, cy, r):
        self.circle(cx, cy, r, LIGHT)
        self.circle(cx + r // 2, cy - r // 3, r - 1, NAVY)

    def weather_icon(self, kind, day):
        cx, cy = 26, 36
        if kind == "clear":
            if day:
                self.sun(cx, cy, 10)
            else:
                self.moon(cx, cy, 12)
            return
        if kind == "partly":
            if day:
                self.sun(cx + 6, cy - 7, 8)
            else:
                self.moon(cx + 6, cy - 7, 9)
            self.cloud(cx - 19, cy + 12, WHITE)
            return
        if kind == "fog":
            for i, w in enumerate((30, 36, 26, 34)):
                self.rect(cx - w // 2, cy - 10 + i * 7, w, 3, GRAY)
            return
        dark = kind in ("rain", "storm")
        self.cloud(cx - 17, cy + 4, SLATE if kind == "storm" else GRAY if dark else LIGHT)
        if kind == "rain":
            for x in (cx - 10, cx - 2, cx + 6, cx + 14):
                self.rect(x - 2, cy + 8, 2, 4, SKY)
                self.rect(x - 4, cy + 14, 2, 4, SKY)
        elif kind == "snow":
            for x, y in ((cx - 9, cy + 9), (cx + 1, cy + 11), (cx + 11, cy + 9), (cx - 4, cy + 16), (cx + 6, cy + 17)):
                self.rect(x - 1, y, 3, 1, WHITE)
                self.rect(x, y - 1, 1, 3, WHITE)
        elif kind == "storm":
            for i, (x, y) in enumerate(((3, 6), (1, 9), (-1, 12), (3, 12), (1, 15), (-1, 18))):
                self.rect(cx + x, cy + y, 4, 3, YELLOW)

    def draw_weather(self):
        w = self.weather
        d = w.data
        self.rect(0, 0, WIDTH, HEIGHT, NAVY)
        self.rect(0, 0, WIDTH, 11, TEAL)
        name = w.city["name"][:21]
        self.text57((WIDTH - len(name) * 6) // 2, 2, name, self.t_wx_head)
        if d is None:
            self.cloud(47, 58, GRAY)
            msg = "SIN CONEXION" if w.error else "CARGANDO..."
            self.text57((WIDTH - len(msg) * 6) // 2, 72, msg, self.t_wx_warn if w.error else self.t_wx_dim)
            return
        kind, label = describe(d["code"])
        self.weather_icon(kind, d["day"])
        temp = "%d\u00b0" % d["temp"]
        scale = 5 if len(temp) <= 3 else 4
        self.text(124 - len(temp) * 4 * scale + scale, 19, temp, WHITE, scale)
        feels = "ST %d" % d["feels"]
        self.text57(122 - len(feels) * 6, 49, feels, self.t_wx_dim)
        self.text57((WIDTH - len(label) * 6) // 2, 63, label, self.t_wx)
        self.rect(6, 75, WIDTH - 12, 1, TEAL)
        self.text57(4, 81, "MAX %d  MIN %d" % (d["max"], d["min"]), self.t_wx)
        self.text57(4, 92, "HUMEDAD %d%%" % d["hum"], self.t_wx)
        rain = d["rain"]
        self.text57(4, 103, "PROB LLUVIA " + ("--" if rain is None else "%d%%" % rain), self.t_wx)
        if w.error:
            self.text57(4, 117, "SIN CONEXION " + d["time"], self.t_wx_warn)
        else:
            self.text57(4, 117, "ACTUALIZADO " + d["time"], self.t_wx_dim)

    def draw(self, view):
        if view == "status":
            self.draw_status()
        elif view == "text":
            self.draw_message()
        elif view == "sunset":
            self.draw_sunset()
        elif view == "colors":
            self.draw_colors()
        elif view in TERMINALS:
            self.draw_console()
        elif view == "fatal":
            self.draw_fatal()
        elif view == "weather":
            self.draw_weather()
        else:
            self.draw_animation()

    def update(self):
        now = time.ticks_ms()
        if self.mode == "random" and (self.view is None or time.ticks_diff(now, self.view_since) >= RANDOM_MS):
            self.pick_random(now)
        view = self.current()
        spans = ((0, HEIGHT),)
        if not self.dirty:
            dt = time.ticks_diff(now, self.last_frame)
            if view == "animation":
                if dt < ANIM_MS:
                    return
                spans = self.step_ball(dt)
            elif view in TERMINALS:
                spans = self.console_step(now)
                if spans is None:
                    return
            elif view == "fatal":
                if dt < 450:
                    return
                self.blink = not self.blink
            elif view == "weather":
                # Se consulta la API solo con esta escena en pantalla, y después
                # de dibujar "CARGANDO" para no demorar la respuesta al panel.
                if not self.weather.due(now):
                    return
                self.weather.fetch()
                now = time.ticks_ms()
            else:
                return
        strips = set()
        for a, b in spans:
            for s in range(max(0, a) // STRIP_ROWS, (min(HEIGHT, b) + STRIP_ROWS - 1) // STRIP_ROWS):
                strips.add(s)
        for strip in sorted(strips):
            self.y0 = strip * STRIP_ROWS
            self.buf[:] = self.zero
            self.draw(view)
            self.flush()
        self.dirty = False
        self.last_frame = now


FONT = {
 'A':('010','101','111','101','101'), 'B':('110','101','110','101','110'),
 'C':('011','100','100','100','011'), 'D':('110','101','101','101','110'),
 'E':('111','100','110','100','111'), 'F':('111','100','110','100','100'),
 'G':('011','100','101','101','011'), 'H':('101','101','111','101','101'),
 'I':('111','010','010','010','111'), 'J':('001','001','001','101','010'),
 'K':('101','101','110','101','101'), 'L':('100','100','100','100','111'),
 'M':('101','111','111','101','101'), 'N':('101','111','111','111','101'),
 'O':('111','101','101','101','111'), 'P':('110','101','110','100','100'),
 'Q':('111','101','101','111','001'), 'R':('110','101','110','101','101'),
 'S':('011','100','111','001','110'), 'T':('111','010','010','010','010'),
 'U':('101','101','101','101','111'), 'V':('101','101','101','101','010'),
 'W':('101','101','111','111','101'), 'X':('101','101','010','101','101'),
 'Y':('101','101','010','010','010'), 'Z':('111','001','010','100','111'),
 '3':('110','001','011','001','110'), '8':('111','101','111','101','111'),
 '0':('111','101','101','101','111'), '1':('010','110','010','010','111'),
 '2':('110','001','010','100','111'), '4':('101','101','111','001','001'),
 '5':('111','100','110','001','110'), '6':('011','100','111','101','111'),
 '7':('111','001','010','010','010'), '9':('111','101','111','001','110'),
 '!':('010','010','010','000','010'), '?':('111','001','010','000','010'),
 '.':('000','000','000','000','010'), ':':('000','010','000','010','000'),
 '\u00b0':('111','101','111','000','000'),
 ' ':('000','000','000','000','000'), '-':('000','000','111','000','000')
}
