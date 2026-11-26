# Texto para la publicación en MakerWorld (español, opcional)

## Título (sugerencias)

- Consola sci-fi para ESP32 + pantalla 1,44"
- Terminal retro-futurista para ESP32 DevKit y LCD ST7735S

## Resumen corto

Carcasa de escritorio en forma de consola industrial retro-futurista para una ESP32 DevKit de 38 pines y una pantalla SPI ST7735S de 1,44" (128×128). Se imprime en un solo color, sin soportes, y todo se arma con tornillos.

## Descripción

Una consolita de 53 × 83 × 67 mm con panel inclinado a 60°, tornillos y franjas de advertencia en relieve, rejilla de ventilación y aletas atrás. Todo el detalle está en el relieve, así que queda bien con un solo filamento. Si querés un look gastado, pasale pincel seco gris metálico en los bordes y una aguada oscura en los grabados.

- La pantalla va atornillada desde adentro con un sujetador, centrada en la ventana.
- La ESP32 va dada vuelta, con los pines hacia arriba, para que los cables Dupont tengan lugar arriba. Apoya sobre columnas con pernos de centrado y 2 tornillos.
- El micro-USB queda al ras de la parte de atrás para enchufarlo desde afuera.
- Se imprime sin soportes. El techo tiene chaflanes internos a 45° y el sujetador apoya sobre una repisa maciza.

## Qué necesitás

| Cantidad | Pieza |
|---|---|
| 1 | ESP32 DevKit de 38 pines (ESP-WROOM-32, PCB de 28 × 53 mm aprox.) |
| 1 | LCD SPI ST7735S de 1,44", 128×128, PCB roja de 30 × 44 mm |
| 8 | Cables Dupont hembra-hembra (uno en Y para VCC + LED) |
| 2 | Tornillos autorroscantes M2.5 × 6 (ESP32) |
| 2 | Tornillos M2 × 6 (sujetador de la pantalla) |
| 4 | Tornillos M3 × 10 cabeza avellanada (base a carcasa) |
| 4 | Patas de goma de 10 mm (opcional) |

## Impresión

- **Archivo:** `esp32_scifi_console.3mf`, con las tres piezas en un plato.
- **Perfil:** Bambu Lab A2L, boquilla 0,4, PLA, 0,20 mm.
- **Paredes y relleno:** 3 paredes, 15 % gyroid.
- **Soportes:** sin soportes, con puentes gruesos activados.
- **Tiempo:** unas 3 h y 79 g en total.

**Orientación:** la carcasa va parada sobre su borde inferior abierto. La base y el sujetador van planos.

**Soportes opcionales:** la carcasa sale bien sin soportes, pero pueden quedar algunos hilos sueltos adentro del techo (bajo la rejilla) y en los ganchos que sostienen la pantalla. Una vez armada no se ven y no afectan el encastre. Si querés el interior más prolijo, activá soportes en árbol solo desde la cama.

## Conexión

| LCD | ESP32 |
|---|---|
| VCC + LED | 3V3 |
| GND | GND |
| CS | GPIO21 |
| RESET | GPIO4 |
| A0 / DC | GPIO22 |
| SDA / MOSI | GPIO13 |
| SCK | GPIO14 |

MISO no se conecta. Usá 3,3 V, nunca 5 V en los GPIO. Conectá todo con la placa desenchufada.

## Armado

1. Cableá la pantalla y la ESP32 siguiendo el diagrama. Como la ESP32 va dada vuelta en la carcasa, guiate por las etiquetas de los pines y no por la posición.
2. Apoyá la ESP32 en la base, con los componentes hacia abajo:
   - **Lado de la antena:** los pernos entran en sus agujeros.
   - **Lado del USB:** atornillá con 2 M2.5.
3. Meté la pantalla en su marco desde adentro de la carcasa, primero el borde de los pines bajo los ganchos. Fijala con el sujetador y 2 tornillos M2.
4. Bajá la carcasa sobre la base: el conector USB entra por la ranura de atrás. Atornillá desde abajo con 4 M3 avellanados.
5. Pegá las patas de goma.

## Archivos incluidos

- `esp32_scifi_console.3mf`: proyecto de Bambu Studio con las tres piezas.
- `stl/`: `shell.stl` (carcasa), `base.stl` y `screen_bracket.stl` (sujetador) por separado.
- `reference/`: modelos de la ESP32 y de la pantalla. Son solo de referencia y no se imprimen.
- `source/`: modelo paramétrico de OpenSCAD (`scifi_console.scad`), escenas de render y diagrama de pines en SVG.

## Antes de imprimir

Las medidas de la placa son de una ESP32 DevKit de 38 pines con agujeros a 24 × 51 mm. Hay clones con otras medidas. Si los tuyos no coinciden, imprimí primero la base (unos 30 minutos) y probá. Si hace falta, cambiá `esp_hole_span` en el `.scad`.
