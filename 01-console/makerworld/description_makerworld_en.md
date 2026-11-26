# MakerWorld listing (English)

**Name:** ESP32 Retro Sci-Fi Case – Console for 1.44" ST7735 Screen

**Category:** Hobby & DIY › Electronics

---

### ESP32 Retro Sci-Fi Case

A small desk console for a 38-pin ESP32 DevKit and a 1.44" ST7735S SPI screen (128×128). It's styled as a retro-futuristic industrial terminal: 60° sloped panel, raised bolts, hazard stripes, a vent grille and rear fins.

All the detail is in the relief, so it looks good in a single filament. For a worn look, dry-brush the edges with metallic gray and add a dark wash in the engravings.

### Features

- Compact: 53 × 83 × 67 mm.
- Prints without supports. The ceiling has 45° internal chamfers and the screen retainer sits on a solid ledge.
- The screen is screwed in from the inside with a retainer, centered in the window.
- The ESP32 is mounted upside down, pins facing up, so the Dupont wires have room above it.
- The micro-USB port is flush with the back, so you plug the cable in from outside.
- Parametric OpenSCAD source included, to adapt it to other boards.

### What you need

- 1 × ESP32 DevKit, 38 pins (ESP-WROOM-32, PCB approx. 28 × 53 mm)
- 1 × ST7735S SPI LCD, 1.44", 128×128, red PCB 30 × 44 mm
- 8 × female-female Dupont jumper wires (one as a Y-splice for VCC + LED)
- 2 × M2.5 × 6 self-tapping screws (ESP32)
- 2 × M2 × 6 screws (screen retainer)
- 4 × M3 × 10 countersunk screws (base to shell)
- 4 × 10 mm rubber feet (optional)

### Printing

- Profile: Bambu Lab A2L, 0.4 mm nozzle, PLA, 0.20 mm layers.
- 3 walls, 15 % gyroid infill.
- No supports, with thick bridges enabled.
- All three parts on one plate: about 3 h and 79 g.
- The shell stands on its open bottom edge. The base and the retainer lie flat.

**Optional supports:** the shell prints fine without supports, but a few loose strands may stay inside the ceiling (under the vent grille) and on the hooks that hold the screen. They are hidden once assembled and don't affect the fit. For a cleaner inside, enable tree supports on build plate only.

### Wiring

- VCC + LED → 3V3
- GND → GND
- CS → GPIO21
- RESET → GPIO4
- A0 / DC → GPIO22
- SDA / MOSI → GPIO13
- SCK → GPIO14

MISO is not connected. Use 3.3 V only, never 5 V on the GPIOs. Wire everything with the board unplugged.

The screen is mounted with its pins at the top, so you may need to rotate the image 180° in your driver. For the ST7735S that means MADCTL `0x08`, with the 128×128 window offset by column 2, row 1.

### Assembly

1.  Wire the screen and the ESP32 following the diagram. The ESP32 sits upside down in the case, so go by the pin labels, not by their position.
2.  Place the ESP32 on the base, components facing down. The pegs go into the holes at the antenna end. Fasten the USB end with 2 M2.5 screws.
3.  Fit the screen into its frame from inside the shell, pin edge first, under the hooks. Secure it with the retainer and 2 M2 screws.
4.  Lower the shell onto the base, with the USB connector going through the slot at the back. Screw it from below with 4 countersunk M3 screws.
5.  Stick on the rubber feet.

The full step-by-step guide with pictures is in the documentation PDF.

### About the screen content

The photos and video show my own MicroPython firmware with several screen modes: a scrolling Python console, a hacker terminal, a fatal error alarm, a status screen and animations. It also includes a local web panel to switch modes over Wi-Fi.

**Firmware, web panel and source files on GitHub:** [github.com/lamaro/esp32-sci-fi-retro](https://github.com/lamaro/esp32-sci-fi-retro)

The case also works with any other firmware that drives an ST7735S over SPI (Arduino, ESPHome).

### Before you print

The design fits a 38-pin ESP32 DevKit with mounting holes 24 × 51 mm apart. Some clones differ. If you're not sure, print the base first (about 30 minutes) and test it. If needed, change `esp_hole_span` in the included `.scad` file.
