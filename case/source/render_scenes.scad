// Render scenes for the MakerWorld listing, plus reference models of the
// 38-pin ESP32 DevKit and the 1.44" ST7735S LCD.
// Uses the dimensions from the main model (scifi_console.scad).
// Example: openscad --render -D 'scene="cover"' -o cover.png render_scenes.scad
include <scifi_console.scad>
part = "none";          // draw nothing from the main file

scene = "cover";        // cover, front, back, exploded, section, parts, reference, ref_esp32, ref_lcd, dims_front, dims_side
c_case = "#cfc9bd";
c_base = "#b9b3a7";

// ------------------------------------------------------------ ESP32
wire_col = ["#f39c12", "#4a4f57", "#9b59b6", "#e74c3c", "#f1c40f", "#27ae60", "#3498db"];
// used pins: [row (-1 left / +1 right in component-side view), pin number, color]
used_pins = [[-1, 1, 0], [1, 1, 1], [1, 6, 2], [1, 13, 3], [1, 3, 4], [-1, 15, 5], [-1, 12, 6]];
function pin_pos(row, k) = [W/2 + row*esp_row_span/2, esp_yc - pin_half + (k - 1)*2.54];

module esp32_nice(wires = true) {
  // PCB
  color("#1c1f24") difference() {
    translate([esp_x0, esp_y0, esp_under]) cube(esp_pcb);
    for (p = esp_holes) translate([p.x, p.y, esp_under - 1]) cylinder(d=esp_hole_d, h=4, $fn=24);
  }
  // ESP-WROOM-32 module (facing down): antenna + shield
  color("#22262c") translate([W/2 - 9, esp_y0, esp_under - 0.8]) cube([18, 7, 0.8]);
  color("#c9ccd1") translate([W/2 - 8.5, esp_y0 + 7, esp_under - 3.2]) cube([17, 18, 2.4]);
  color("#22262c") translate([W/2 - 9, esp_y0 + 7, esp_under - 0.8]) cube([18, 18.5, 0.8]);
  // USB and buttons
  color("#b8bcc2") translate([W/2 - esp_usb.x/2, esp_y1 - esp_usb.y + esp_usb_over, esp_under - esp_usb.z]) cube(esp_usb);
  for (p = esp_holes) if (p.y > esp_yc) {
    inward = p.x < W/2 ? 1 : -1;
    translate([p.x + inward*2.3 + (inward > 0 ? 0 : -2.8), p.y - 3.2, esp_under - 2]) {
      color("#d8d8d8") cube([2.8, 4.8, 1.4]);
      color("#222") translate([0.6, 1.6, -0.6]) cube([1.6, 1.6, 0.7]);
    }
  }
  // chips on the component side
  color("#111") translate([W/2 - 2.5, esp_y1 - 16, esp_under - 1]) cube([5, 5, 1]);
  color("#111") translate([W/2 - 10, esp_y1 - 14, esp_under - 1.6]) cube([6.5, 3.5, 1.6]);
  // yellow headers with pins facing up
  for (s = [-1, 1]) {
    color("#f2d23c") translate([W/2 + s*esp_row_span/2 - 1.27, esp_yc - pin_half - 1.27, esp_under + esp_pcb.z])
      cube([2.54, 2*pin_half + 2.54, header_h]);
    for (k = [1:esp_pins]) color("#d9d9d9") translate(concat(pin_pos(s, k), [esp_under + esp_pcb.z + header_h - eps]))
      translate([-0.32, -0.32, 0]) cube([0.64, 0.64, 6]);
  }
  // Dupont connectors and wires on the used pins
  if (wires) for (u = used_pins) {
    p = pin_pos(u[0], u[1]);
    z0 = esp_under + esp_pcb.z + header_h;
    color("#15171a") translate([p.x - 1.27, p.y - 1.27, z0]) cube([2.54, 2.54, 14]);
    color(wire_col[u[2]]) translate([p.x, p.y, z0 + 14]) cylinder(d=1.4, h=8, $fn=12);
  }
}

// ------------------------------------------------------------ LCD
// LCD local frame: x along the PCB (pins at -x), z = 0 at the glass face.
lit_cx = -lcd_pcb.x/2 + lcd_lit_top + lcd_view.y/2;     // image center along local x

module lcd_screen_ui() {
  // drawn in panel axes (x right, y up) and rotated into the local frame
  v = lcd_view;
  translate([lit_cx, 0, 0.02]) rotate([0, 0, 90]) {
    color("#0b1d1c") translate([-v.x/2, -v.y/2, 0]) cube([v.x, v.y, 0.1]);
    color("#ffb238") {
      translate([0, v.y/2 - 4, 0.1]) linear_extrude(0.12) text("SYS ONLINE", size=2.5, halign="center", valign="center", font="Liberation Mono:style=Bold");
      for (i = [0:5]) translate([-v.x/2 + 3.2 + i*3.4, -v.y/2 + 2.5, 0.1]) cube([2.2, 1.5 + (i*37 % 6), 0.12]);
    }
    color("#45e0c8") {
      translate([6, 1.5, 0.1]) difference() {
        cylinder(r=5, h=0.12, $fn=48); translate([0, 0, -0.5]) cylinder(r=4.4, h=1, $fn=48);
      }
      translate([6, 1.5, 0.1]) rotate(35) translate([0, -0.25, 0]) cube([4.6, 0.5, 0.12]);
      for (i = [0:3]) translate([-11, 4 - i*2.4, 0.1]) cube([7 - (i % 2)*2, 0.6, 0.12]);
    }
  }
}

module lcd_local(screen = true) {
  // glass with white frame and a black border around the image
  translate([-lcd_pcb.x/2 + lcd_glass_top, -lcd_glass.y/2, -lcd_glass_t]) color("#f1f1ee") cube([lcd_glass.x, lcd_glass.y, lcd_glass_t - 0.05]);
  color("#121416") translate([lit_cx - lcd_view.y/2 - 1.2, -lcd_glass.y/2 + 1, -0.06]) cube([lcd_view.y + 2.4, lcd_glass.y - 2, 0.05]);
  // red PCB
  color("#c8322b") translate([-lcd_pcb.x/2, -lcd_pcb.y/2, -lcd_glass_t - lcd_pcb.z]) cube(lcd_pcb);
  // 8-pin header with Dupont connectors facing back
  for (i = [0:7]) color("#15171a") translate([-lcd_pcb.x/2 + 0.3, (i - 3.5)*2.54 - 1.27, -lcd_glass_t - lcd_pcb.z - 14]) cube([2.54, 2.54, 14]);
  if (screen) lcd_screen_ui();
}

module lcd_nice(screen = true)
  on_panel() translate([lcd_c.x, lcd_c.y, -wall]) rotate([0, 0, lcd_rot]) lcd_local(screen);

// ------------------------------------------------------------ micro-USB cable
module usb_cable() {
  y0 = D - usb_inset;
  color("#b8bcc2") translate([W/2 - 3.4, y0 - 4.6, usb_z - 1.1]) cube([6.8, 6.6, 1.9]);
  color("#2b2d31") translate([W/2 - 5.5, y0 + 1.8, usb_z - 3.5]) cube([11, 14, 7]);
  color("#2b2d31") translate([W/2, y0 + 15.5, usb_z]) rotate([-90, 0, 0]) cylinder(d=3.4, h=30, $fn=24);
}

// ------------------------------------------------------------ scenes
module assembled(cut = false) {
  if (cut) color(c_case) difference() { shell(); translate([W/2, -50, -50]) cube([W, D + 100, H + 100]); }
  else color(c_case) shell();
  color(c_base) base();
  color(c_base) retainer_placed();
  esp32_nice();
  lcd_nice();
}

if (scene == "cover" || scene == "front") assembled();
else if (scene == "back") { assembled(); usb_cable(); }
else if (scene == "section") assembled(true);
else if (scene == "exploded") {
  color(c_base) base();
  esp32_nice();
  translate([0, 0, 85]) { color(c_case) shell(); color(c_base) retainer_placed(); }
  // LCD pulled out of the panel, between the base and the shell
  translate([0, 18, 40]) lcd_nice(true);
  translate([0, 18, 40]) translate([0, 0, 0]) color(c_base) retainer_placed();
}
else if (scene == "parts") {
  color(c_case) shell();
  color(c_base) translate([W + 14, 0, base_t]) base();
  color(c_base) translate([W + 14 + W/2 - 16, D + 14, 0]) retainer();
}
else if (scene == "reference") {
  translate([-30, 0, 0]) esp32_ref();
  translate([30, 0, lcd_glass_t + lcd_pcb.z + 14]) rotate([0, 0, lcd_rot]) lcd_local();
}
else if (scene == "ref_esp32") esp32_ref();
else if (scene == "ref_lcd") rotate([0, 0, lcd_rot]) lcd_local();

// centered ESP32, component side up (as it comes from the factory)
module esp32_ref() rotate([0, 180, 0]) translate([-W/2, -esp_yc, -esp_under - esp_pcb.z/2]) esp32_nice(false);

// ------------------------------------------------------------ dimensions
c_dim = "#ffb238";
module dim_line(a, b, label, off = [0, 0], ts = 4) {
  // line in the 2D (x, y) plane with end dots and a centered label
  color(c_dim) {
    hull() { translate(a) circle(d=0.6, $fn=8); translate(b) circle(d=0.6, $fn=8); }
    for (p = [a, b]) translate(p) circle(d=2, $fn=16);
    translate((a + b)/2 + off) text(label, size=ts, halign="center", valign="center", font="Liberation Sans:style=Bold");
  }
}
tot_h = 64.2 + base_t;
if (scene == "dims_front") {
  assembled();
  // XZ plane facing -Y
  translate([0, -8, 0]) rotate([90, 0, 0]) linear_extrude(0.5) {
    dim_line([-2.4, -base_t - 8], [W + 2.4, -base_t - 8], "53 mm", [0, -6]);
    dim_line([W + 12, -base_t], [W + 12, 64.2], "67 mm", [10.5, 0]);
  }
}
if (scene == "dims_side") {
  assembled();
  translate([W + 6, 0, 0]) rotate([90, 0, 90]) linear_extrude(0.5) {
    dim_line([-1.5, -base_t - 8], [D + 1.6, -base_t - 8], "83 mm", [0, -6]);
    translate([y_top/2 - 12, lip_h + (H - lip_h)/2 + 4]) color(c_dim) text("60°", size=4, font="Liberation Sans:style=Bold");
  }
}
