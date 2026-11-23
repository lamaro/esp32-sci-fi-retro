# Guía de reproducción

## Materiales y herramientas

- ESP32 DevKit de 38 pines con ESP-WROOM-32 y USB serie CP2102.
- LCD SPI ST7735S de 1,44 pulgadas y 128 × 128, jumpers y cable micro-USB de datos.
- Python 3, Node.js 22 LTS o posterior compatible con el proyecto y npm.
- Red Wi‑Fi de 2,4 GHz para la ESP32. La computadora debe poder llegar a ella por la red local.

## Cableado

Con el USB desconectado, conectá por etiqueta GPIO. El número de GPIO puede diferir de la posición física.

| LCD | ESP32 |
|---|---|
| VCC y LED | 3V3 |
| GND | GND |
| CS | GPIO21 |
| RESET | GPIO4 |
| A0 / DC | GPIO22 |
| SDA / MOSI | GPIO13 |
| SCK | GPIO14 |

No hace falta conectar MISO. El firmware lo asigna internamente a GPIO12. Usá señales y alimentación de 3,3 V para este montaje. [Diagrama de cableado](conexion_pantalla_esp32.svg).

## Preparar MicroPython

Desde la raíz del repositorio, en macOS o Linux:

```sh
cd hello
python3 -m venv .venv
source .venv/bin/activate
python -m pip install esptool mpremote
mpremote connect list
```

Elegí el puerto USB serie que aparece al conectar la placa. Ejemplos: `/dev/cu.usbserial-0001` en macOS, `/dev/ttyUSB0` en Linux o `COM3` en Windows. Los comandos siguientes usan una variable de shell. En Windows, activá con `.venv\Scripts\Activate.ps1` en PowerShell y reemplazá `"$PORT"` por tu puerto COM.

```sh
PORT=/dev/cu.usbserial-0001
```

Si la placa ya tiene MicroPython, salteá el flasheo. Para una instalación nueva, descargá el .bin de [ESP32_GENERIC](https://micropython.org/download/ESP32_GENERIC/) para el ESP32 clásico y guardalo como `firmware.bin` en `hello/`. El borrado de flash elimina el firmware y archivos existentes.

```sh
python -m esptool --chip esp32 --port "$PORT" erase-flash
python -m esptool --chip esp32 --port "$PORT" write-flash 0x1000 firmware.bin
```

## Configurar y cargar la placa

Desde `hello/` con el entorno activo:

```sh
cp wifi_secrets.py.example wifi_secrets.py
python -c 'import secrets; print(secrets.token_hex(32))'
```

Completá `WIFI_SSID`, `WIFI_PASSWORD` y `API_TOKEN` en `wifi_secrets.py`. Guardá ese mismo token para configurar el panel. Copiá los archivos y reiniciá:

```sh
mpremote connect "$PORT" fs cp wifi_secrets.py :wifi_secrets.py &&
mpremote connect "$PORT" fs cp font5x7.py :font5x7.py &&
mpremote connect "$PORT" fs cp display_ui.py :display_ui.py &&
mpremote connect "$PORT" fs cp main.py :main.py &&
mpremote connect "$PORT" reset
```

La IP aparece en el LCD al iniciar. También podés abrir `mpremote connect "$PORT" repl` y presionar **EN** para ver el arranque. Salí con **Ctrl+]** antes de copiar archivos otra vez. Para actualizar el programa, copiá solo `font5x7.py`, `display_ui.py` y `main.py` y reiniciá. Volvé a copiar los secretos si cambian la red o el token.

## Levantar el panel

En otra terminal, desde la raíz del repositorio:

```sh
cd panel
npm ci
cp .env.example .env.local
```

Editá `.env.local`. Usá la IP que informa la placa en `ESP32_BASE_URL` y el mismo token en `ESP32_API_TOKEN`. Luego ejecutá:

```sh
npm run dev -- --hostname 127.0.0.1
```

Abrí http://localhost:3000. Esperá **Conectado** y probá **Colores**, **Atardecer**, **Animación**, **Consola** (código Python que se escribe solo), **Terminal hacker**, **Error fatal** o **Aleatorio** (cambia de escena cada 20 segundos). En **Texto personalizado**, escribí `VOLVÉ EN 5 MIN` y pulsá **Mostrar en pantalla**. La vista previa aplica mayúsculas, elimina tildes y divide el texto en hasta dos líneas de 15 caracteres. Se admiten letras, números, espacios y `. ! ? : -`. Al reiniciar, la placa vuelve a mostrar la IP.

El navegador llama a Next.js y el servidor envía el token a la ESP32. Ese tramo usa HTTP en la LAN. Mantené el panel en localhost, evitá abrir puertos en el router y excluí `.env.local` y `wifi_secrets.py` de Git.

## Demos por USB

Desde `hello/`, con el entorno y `PORT` configurados y el monitor serie cerrado:

| Comando | Resultado esperado |
|---|---|
| `mpremote connect "$PORT" run demo_pantalla.py` | Atardecer en pixel art |
| `mpremote connect "$PORT" run demo_colores.py` | Cuadrícula RGB565 para verificar color y bordes |
| `mpremote connect "$PORT" run demo_animacion.py` | Orbe rebotando durante unos segundos |
| `mpremote connect "$PORT" run blink.py` | Demo opcional de LED externo. Mirá el GPIO en el archivo y usá una resistencia en serie de 200–330 Ω |

`run` ejecuta un script temporalmente. Presioná **EN** o ejecutá `mpremote connect "$PORT" reset` para volver a la API Wi‑Fi.

## Carcasa impresa en 3D

La carpeta [`case/`](case) tiene el proyecto de Bambu Studio, los STL, el modelo paramétrico de OpenSCAD y la [guía de armado en PDF](case/assembly_guide.pdf) (en inglés). Se imprime en PLA sin soportes, en unas 3 horas. La ESP32 va dada vuelta, con los pines hacia arriba, y la pantalla va con los pines arriba, por eso el firmware rota la imagen 180°.

## Solución de problemas

| Síntoma | Qué revisar |
|---|---|
| No aparece el puerto | Probá un cable de datos, otro puerto y los permisos USB. En macOS, Información del Sistema → USB permite distinguir un puente detectado de un puerto serie ausente. Consultá [Silicon Labs](https://www.silabs.com/software-and-tools/usb-to-uart-bridge-vcp-drivers) si hace falta el controlador CP210x. |
| Puerto ocupado | Cerrá el REPL y otros monitores serie. Repetí `mpremote connect list`. |
| Flasheo queda en Connecting | Mantené **BOOT** mientras empieza la conexión de esptool. |
| El editor subraya `import machine` | Ese módulo existe en MicroPython en la placa. Usá `mpremote` para ejecutarlo ahí. |
| Panel desconectado | Leé la IP en pantalla o REPL, corroborá el token y actualizá `.env.local` si cambió la IP. Reiniciá Next.js tras editarlo. Si la red de invitados aísla clientes, usá una red que permita la comunicación entre ambos. |
| El panel no abre | Confirmá que `npm run dev` sigue activo y usá la dirección que imprime Next.js. |
| LCD blanco aunque la API responde | Ejecutá la demo de atardecer por USB. Si sigue blanco, desconectá la alimentación, revisá VCC/GND y los cables SPI por etiqueta y probá otros jumpers. La luz de fondo puede encender aunque el LCD no reciba datos. |
| Línea de colores en el borde | Usá la cuadrícula para verificar orientación y offsets. Para el módulo probado, con los pines arriba el driver usa MADCTL `0x08`, columnas 2–129 y filas 1–128. Si cambiás la orientación, ajustá `MADCTL`, `X_OFF` y `Y_OFF` en `display_ui.py`. |
| `MemoryError` o mensaje de firmware anterior | Cargá juntos `font5x7.py`, `display_ui.py` y `main.py`. El driver integrado usa un buffer de 2 KB y dibuja en tiras de ocho filas. Buscá errores de arranque en el REPL. |

[Referencia de mpremote](https://docs.micropython.org/en/latest/reference/mpremote.html).
