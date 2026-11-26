// ============================================================================
// Sci-fi console for an ESP32 DevKit (38 pins) + ST7735S 1.44" 128x128 LCD
// Style: retro industrial wedge console. Original design.
//
// Units: mm.  Axes (seen from the front):
//   X = width, left to right
//   Y = depth, Y = 0 is the front
//   Z = height, Z = 0 is the top face of the base (= bottom edge of the shell)
//
// Parameter tags:
//   [MEASURE] provisional value: check it with calipers before printing.
//   [PHOTO]   estimated from a photo of the board, using the 2.54 mm pin pitch.
//
// Parts (choose with `part`):
//   shell    wedge + panel + lid. Print standing on its open bottom edge,
//            no supports needed.
//   base     bottom plate with standoffs for the ESP32. No supports.
//   retainer bracket that holds the LCD from behind. No supports.
//   assembly everything assembled, with ghost parts to check for collisions.
//   check    shows only the collisions (empty = no collisions).
// ============================================================================

/* [View] */
part = "assembly"; // [assembly, shell, base, retainer, check]
ghosts = true;
cutaway = false;
check_what = "all"; // [all, esp_vs_case, lcd_vs_case, lcd_vs_esp, base_vs_shell]

/* [Case] */
// Smallest size with some air: 30x44 LCD on the panel, 28x53 ESP32 lying flat at the back.
W = 48;          // outer width
D = 80;          // outer depth
H = 60;          // outer height of the shell (without base)
lip_h = 10;      // vertical front lip
slope_a = 60;    // panel angle from the desk (degrees)
wall = 2.6;      // wall thickness
base_t = 3.2;    // base thickness
plinth = 1.5;    // how far the base sticks out around the shell
corner_ch = 4;   // chamfer on the front vertical edges
fit = 0.3;       // clearance between parts

/* [ESP32] */
esp_pcb = [28, 53, 1.6];       // measured with a ruler (datasheets: 28 x 52-55). [MEASURE] with calipers
esp_hole_d = 3.0;              // [MEASURE] hole diameter
esp_hole_span = [24.0, 51.0];  // measured twice with a ruler (centers ~1 mm from the edge: check against your board)
esp_row_span = 25.4;           // [MEASURE] distance between the two pin rows
esp_pins = 19;                 // pins per row
esp_top_h = 3.2;               // [MEASURE] height of the module shield
// The ESP32 is mounted UPSIDE DOWN: components (module, USB, buttons) face down
// and the pins + Dupont connectors face up, where there is room for the wires.
esp_under = 7;                 // standoff height = PCB component side above the base
esp_peg_h = 1.2;               // how far the locating peg sticks out above the PCB (antenna end, no screw)
header_h = 2.5;                // header plastic
dupont_len = 20;               // [PHOTO] female Dupont + start of the wire, measured above the header
esp_usb = [7.5, 5.5, 2.6];     // micro-USB (width, length, height)
esp_usb_over = 3.0;            // how far the USB sticks out past the PCB edge (approx. measured)
usb_inset = 0.3;               // USB mouth relative to the outer wall face (almost flush)
usb_cut = [14, 10];            // generous opening for the plug overmold
usb_slot_w = esp_usb.x + 2;    // slot from below so the shell can be lowered over the connector
esp_sd = 4.6;                  // ESP32 standoff diameter
esp_pilot = 2.2;               // pilot hole for an M2.5 self-tapping screw (USB end only)

/* [LCD] */
// LCD local frame: x = along the PCB (pins at -x), y = across.
// lcd_rot = -90 mounts it upright on the panel with the pins at the TOP (towards the lid).
lcd_pcb = [44, 30, 1.6];       // measured: 44 tall x 30 wide (red module datasheet: 43.4 x 29.7)
lcd_rot = -90;
lcd_glass = [36, 28];          // glass with white frame: 36 long (measured); ~28 wide (assumed)
lcd_lit_top = 13;              // measured: with the pins at the top, the image starts 13 mm from the pin edge (and ends 3 mm from the other edge)
lcd_glass_t = 3.8;             // [PHOTO] glass + white frame + adhesive (~2.4x the PCB in the side photo)
lcd_view = [26, 28];           // measured lit area: 26 wide x 28 tall (datasheet: 26.2 x 27.2)
lcd_glass_top = lcd_pcb.x - 0.7 - lcd_glass.x;   // [PHOTO] the white frame reaches ~0.7 mm from the edge without pins
lcd_view_off = [0, lcd_pcb.x/2 - lcd_lit_top - lcd_view.y/2];   // image center relative to the PCB center (+ = up)
lcd_pos = 33;                  // PCB center, measured along the panel from the bottom
lcd_x_off = 0;                 // sideways offset of the screen
lcd_conn_len = 20.3;           // 8 pins x 2.54
lcd_back = 14;                 // room behind the PCB for the Dupont connector (top end)

/* [Decoration] */
plate_h = 1.0;
bez_w = 3.5;
bez_h = 3.2;
back_label = "";               // text engraved below the USB ("" = no text)
font = "Liberation Sans:style=Bold";
relief = 1.0;                  // how far the side armor plates stick out

/* [Hidden] */
$fn = 48;
eps = 0.01;

// ---------------------------------------------------------------- derived values
L_slope = (H - lip_h) / sin(slope_a);  // length of the sloped panel
y_top   = (H - lip_h) / tan(slope_a);  // where the panel ends and the lid begins

esp_x0 = W/2 - esp_pcb.x/2;
esp_y1 = D - usb_inset - esp_usb_over;             // PCB edge at the USB end
esp_y0 = esp_y1 - esp_pcb.y;                       // PCB edge at the antenna end
esp_yc = (esp_y0 + esp_y1)/2;
esp_holes = [for (i=[-1,1], j=[-1,1]) [W/2 + i*esp_hole_span.x/2, esp_yc + j*esp_hole_span.y/2]];
pin_half = (esp_pins - 1)/2 * 2.54;                // from the center to the last pin

col_d = 6;
col_front_y = 40;              // the front columns sit behind the LCD (no room further forward)
col_pos = [
  [wall + col_d/2 - 0.6,     col_front_y],
  [W - wall - col_d/2 + 0.6, col_front_y],
  [wall + col_d/2 - 0.6,     D - wall - col_d/2 + 0.6],
  [W - wall - col_d/2 + 0.6, D - wall - col_d/2 + 0.6]
];
feet_pos = [[14, 14], [W-14, 14], [14, D-14], [W-14, D-14]];
rim_h = 2;

lcd_c = [W/2 + lcd_x_off, lcd_pos];                   // LCD PCB center (panel coordinates)
vc = lcd_c + lcd_view_off;                 // center of the visible area
fh = lcd_glass_t + lcd_pcb.z;              // depth of the frame that holds glass + PCB
lcd_in = [lcd_pcb.x/2 + fit, lcd_pcb.y/2 + fit];
boss_r = 2.8;
boss_x = lcd_in.x + 1.6 + boss_r - 0.2;
boss_y = 12;
hook_w = lcd_in.y - lcd_conn_len/2 - 0.6;   // hooks clear of the pin strip

usb_z = esp_under - esp_usb.z/2;          // the USB hangs below the PCB

// ---------------------------------------------------------------- helpers
module profile2d(ext=0)
  polygon([[0,-ext],[0,lip_h],[y_top,H],[D,H],[D,-ext]]);

module footprint2d(o=0)
  offset(delta=o) polygon([[corner_ch,0],[W-corner_ch,0],[W,corner_ch],[W,D],[0,D],[0,corner_ch]]);

module along_x(x0, x1) translate([x0,0,0]) rotate([90,0,90]) linear_extrude(x1-x0) children();

// Panel frame: x = width, y = up the slope, z = outwards.
// z = 0 is the outer face of the panel.
module on_panel() translate([0,0,lip_h]) rotate([slope_a,0,0]) children();

module rrect(s, r) offset(r) offset(-r) square(s, center=true);
module chrect(s, c) polygon([
  [-s.x/2+c,-s.y/2],[s.x/2-c,-s.y/2],[s.x/2,-s.y/2+c],[s.x/2,s.y/2-c],
  [s.x/2-c,s.y/2],[-s.x/2+c,s.y/2],[-s.x/2,s.y/2-c],[-s.x/2,-s.y/2+c]]);

// extrusion with a chamfered top (convex shapes only)
module ch_extrude(h, c) hull() {
  linear_extrude(h - c) children();
  translate([0,0,h-c-eps]) linear_extrude(c+eps) offset(delta=-c) children();
}

// ---------------------------------------------------------------- shell
module shell_outer() intersection() {
  along_x(0, W) profile2d(0);
  translate([0,0,-1]) linear_extrude(H+2) footprint2d(0);
}

module cavity() intersection() {
  along_x(wall, W-wall) offset(delta=-wall) profile2d(12);
  translate([0,0,-14]) linear_extrude(H+16) footprint2d(-wall);
}

module case_columns() intersection() {
  for (p = col_pos) translate([p.x, p.y, 0]) cylinder(d=col_d, h=H);
  shell_outer();
}

// diagonal hazard stripes (2D), clipped to the `size` rectangle
module stripes2d(size, w=3.0, pitch=6.0, ang=45) intersection() {
  square(size, center=true);
  rotate(ang) for (i = [-30:30]) translate([i*pitch, 0]) square([w, 300], center=true);
}

// hex bolt head on a washer, with an Allen socket
module hex_bolt(d=5.6, h=1.6) difference() {
  union() {
    cylinder(d=d + 1.4, h=0.5);
    cylinder(d=d, h=h, $fn=6);
  }
  translate([0, 0, h - 0.7]) cylinder(d=d*0.42, h=1, $fn=6);
}

// panel layout (panel coordinates)
bz_out = lcd_view.x + 1.2 + 2*bez_w;            // screen bezel, lower step
pb = 5.5;                                         // decorative bolts in the panel corners
p_bolts = [[pb, pb], [W-pb, pb], [pb, L_slope-pb], [W-pb, L_slope-pb]];
bz_top = vc.y + bz_out/2;                         // top edge of the screen bezel
bz_bot = vc.y - bz_out/2;
row_y = (bz_top + L_slope)/2;                     // row of buttons above the screen
btn_x = [W/2 - 8, W/2, W/2 + 8];

module panel_decor() on_panel() {
  // instrument plate
  translate([W/2, L_slope/2]) ch_extrude(plate_h, 0.5) chrect([W-6, L_slope-5], 4);
  // two-step screen bezel
  translate([vc.x, vc.y]) {
    ch_extrude(plate_h + 1.6, 0.6) chrect([bz_out, bz_out], 4);
    ch_extrude(plate_h + bez_h, 1.0) chrect([bz_out - 4, bz_out - 4], 3);
  }
  // exposed bolts in the corners
  for (p = p_bolts) translate(p) hex_bolt(4.2, plate_h + 1.4);
  // round buttons above the screen
  for (x = btn_x) translate([x, row_y]) ch_extrude(plate_h + 1.8, 0.6) circle(d=5);
}

module panel_cuts() on_panel() {
  // LCD window: straight through the panel, funnel-shaped in the bezel
  m = 0.6;
  v = [lcd_view.x + 2*m, lcd_view.y + 2*m];
  translate([vc.x, vc.y, 0]) {
    translate([-v.x/2, -v.y/2, -wall - 1]) cube([v.x, v.y, wall + 1 + eps]);
    hull() {
      translate([-v.x/2, -v.y/2, -eps]) cube([v.x, v.y, eps]);
      translate([-v.x/2 - 1.6, -v.y/2 - 1.6, plate_h + bez_h]) cube([v.x + 3.2, v.y + 3.2, eps]);
    }
  }
  // hazard stripe below the screen, between the bolts
  sh = bz_bot - 1.2 - 3;
  if (sh > 1.5) translate([W/2, 3 + sh/2, plate_h - 0.6]) linear_extrude(1) stripes2d([W - 2*pb - 8, sh], 2.2, 4.4);
  // recessed ring around each button
  for (x = btn_x) translate([x, row_y, plate_h - 0.6])
    difference() { cylinder(d=6.6, h=1); translate([0,0,-1]) cylinder(d=5, h=3); }
}

module lcd_mount() on_panel() translate([lcd_c.x, lcd_c.y, -wall]) rotate([0, 0, lcd_rot]) {
  // frame on three sides; the connector side stays open
  mirror([0,0,1]) {
    linear_extrude(fh) difference() {
      translate([-lcd_in.x - 1.6, -lcd_in.y - 1.6]) square([2*lcd_in.x + 3.2, 2*lcd_in.y + 3.2]);
      translate([-lcd_in.x, -lcd_in.y]) square([2*lcd_in.x, 2*lcd_in.y]);
      translate([-lcd_in.x - 2, -lcd_in.y + hook_w]) square([4, 2*lcd_in.y - 2*hook_w]);   // connector side open
    }
    // hooks on the connector side (the PCB slides in under them)
    for (s = [-1, 1]) translate([-lcd_in.x - 1.6, s > 0 ? lcd_in.y - hook_w : -lcd_in.y - 1.6, fh])
      cube([1.6 + fit + 2, hook_w + 1.6, 1.2]);
    // bosses for the retainer
    for (s = [-1, 1]) translate([boss_x, s*boss_y, 0]) cylinder(r=boss_r, h=fh);
  }
}

// Solid ledge between the front lip and the LCD frame: it fills in under the
// retainer bosses and the bottom bar of the frame, which would otherwise print
// in mid-air. Its back face is the plane the retainer sits on (30° from
// vertical) and it ends in a short ceiling above the base rim.
module lcd_ledge() intersection() {
  on_panel() translate([lcd_c.x - lcd_in.y - 1.6, -30, -wall - fh])
    cube([2*lcd_in.y + 3.2, 30 + lcd_c.y - lcd_in.x - 1.6, fh + eps]);
  cavity();
  translate([-1, -1, rim_h + fit]) cube([W + 2, D + 2, H]);
}

// 45° chamfers along the ceiling edges: they shorten the lid bridge to
// ~W - 2*(wall + roof_ch) so the vent grille prints without supports.
roof_ch = 8;
module roof_gussets() intersection() {
  // XZ triangles extruded along Y (rotate X 90: polygon y = world z)
  translate([0, D, 0]) rotate([90, 0, 0]) linear_extrude(D) for (m = [0, 1])
    translate([m*W, 0]) mirror([m, 0])
      polygon([[wall - eps, H - wall + eps], [wall + roof_ch, H - wall + eps], [wall - eps, H - wall - roof_ch]]);
  along_x(0, W) profile2d(0);
}

module lcd_mount_holes() on_panel() translate([lcd_c.x, lcd_c.y, -wall]) rotate([0, 0, lcd_rot]) mirror([0,0,1])
  for (s = [-1, 1]) translate([boss_x, s*boss_y, -wall + 0.8]) cylinder(d=1.8, h=wall - 0.8 + fh + 1);

// extrusion along X with a chamfered outer face (convex 2D shape)
module ch_along_x(x0, h, c) hull() {
  along_x(x0, x0 + h - c) children();
  along_x(x0 + h - c - eps, x0 + h) offset(delta=-c) children();
}

// right side relief; the left side is its mirror
module side_relief() {
  // armor plate
  ch_along_x(W - eps, relief + eps, 0.6) offset(delta=-6) profile2d(0);
  // vertical ribs at the front of the plate
  for (y = [y_top - 6 : 4.2 : y_top + 6.6]) ch_along_x(W + relief - eps, 1.2 + eps, 0.5)
    translate([y, 11]) square([1.8, H*0.36]);
  // bolts in the plate corners
  for (p = [[11, 11], [D - 11, 11], [D - 11, H - 11], [y_top + 8, H - 11]])
    translate([W + relief - eps, p[0], p[1]]) rotate([0, 90, 0]) hex_bolt(5, 1.4);
}

module side_cuts() {
  // vertical vents near the back (through plate and wall)
  for (x = [[-relief - 1, wall + 1], [W - wall - 1, W + relief + 1]]) along_x(x[0], x[1])
    for (y = [D - 30 : 4.5 : D - 16]) hull() {
      translate([y, 16]) circle(d=2.2);
      translate([y, H - 22]) circle(d=2.2);
    }
}

module top_decor() {
  // handle-like rails on both sides of the grille
  for (x = [9, W - 9]) translate([x, (y_top + 7 + D - 5)/2, H - eps])
    ch_extrude(3 + eps, 1.0) square([5, D - 5 - y_top - 7], center=true);
  // bolts on the back ends of the rails
  for (x = [9, W - 9]) translate([x, D - 9, H + 3 - 2*eps]) hex_bolt(3.6, 1.2);
}

module top_cuts() {
  // vent grille in the lid
  gh = W/2 - 16;                 // half grille width, between the rails
  for (y = [D - 36 : 4.5 : D - 13]) translate([W/2, y, H - wall - 1])
    linear_extrude(wall + 2) hull() { translate([-gh, 0]) circle(d=2.2); translate([gh, 0]) circle(d=2.2); }
  // engraved frame around the grille
  translate([W/2, D - 24.5, H - 0.6]) linear_extrude(1) difference() {
    chrect([2*gh + 6, 30], 3); offset(delta=-0.7) chrect([2*gh + 6, 30], 3);
  }
  // seam between panel and lid
  translate([corner_ch, y_top + 4, H - 0.6]) cube([W - 2*corner_ch, 0.8, 1]);
}

module back_decor() {
  // USB frame
  translate([W/2, D - eps, usb_z]) rotate([-90,0,0]) ch_extrude(1.2 + eps, 0.5) rrect([usb_cut.x + 7, usb_cut.y + 7], 2);
  // heatsink-style vertical fins on both sides of the USB
  fin0 = (usb_cut.x + 7)/2 + 3;
  for (s = [-1, 1], k = [0 : max(0, floor((W/2 - 9 - fin0)/4))]) translate([W/2 + s*(fin0 + k*4), D - eps, 16]) hull() {
    translate([-1, 0, 0]) cube([2, 0.6, H - 32]);
    translate([-0.4, 0, 0.6]) cube([0.8, 1.6, H - 33.2]);
  }
  // corner bolts
  for (x = [6, W - 6], z = [7, H - 7]) translate([x, D - eps, z]) rotate([-90, 0, 0]) hex_bolt(5, 1.4);
}

module back_cuts() {
  translate([W/2, D - wall - 1, usb_z]) rotate([-90,0,0]) linear_extrude(wall + 4) rrect(usb_cut, 2);
  // slot open at the bottom: the connector goes through the wall, so the shell is
  // lowered over it. The plug on the base (usb_plug) closes it.
  translate([W/2 - usb_slot_w/2, D - wall - 1, -1]) cube([usb_slot_w, wall + 4, usb_z + 1]);
  if (back_label != "") translate([W/2, D + 1 + eps, usb_z - 12]) rotate([90,0,180]) translate([0,0,-0.6 - 1])
    linear_extrude(1.6) text(back_label, size=3.2, font=font, halign="center", valign="center");
}

module front_cuts() {
  // front lip with hazard stripes
  translate([W/2, 0.6, lip_h/2 - 0.5]) rotate([90,0,0]) linear_extrude(2) stripes2d([W - 2*corner_ch - 6, lip_h - 6]);
}

module shell() difference() {
  intersection() { union() {
    difference() { shell_outer(); cavity(); }
    case_columns();
    panel_decor();
    lcd_mount();
    lcd_ledge();
    roof_gussets();
    side_relief();
    translate([W, 0, 0]) mirror([1, 0, 0]) side_relief();
    top_decor();
    back_decor();
  }
  translate([-50, -50, 0]) cube([W + 100, D + 100, H + 50]); }   // nothing below the bottom edge
  // M3 pilot holes in the columns
  for (p = col_pos) translate([p.x, p.y, -eps]) cylinder(d=2.5, h=12);
  panel_cuts();
  lcd_mount_holes();
  side_cuts();
  top_cuts();
  back_cuts();
  front_cuts();
  esp_grooves();
}

// ---------------------------------------------------------------- base
// the back standoffs sit right against the wall: they go into a vertical groove
// in the wall (open at the bottom) and only what goes past it is trimmed
groove_d = 1.0;   // groove depth in the back wall
module esp_standoff(p) intersection() {
  esp_standoff_raw(p);
  translate([-1, -1, -1]) cube([W + 2, D - wall + groove_d - fit + 1, H]);
}
module esp_grooves() for (p = esp_holes) if (p.y > esp_yc)
  translate([p.x - (esp_sd + 1.4)/2 - fit, D - wall - 1, -1]) cube([esp_sd + 1.4 + 2*fit, 1 + groove_d, esp_under + 1.5]);

// USB end: standoff with a pilot hole for a screw.
// Antenna end: standoff with a locating peg and NO screw, because the corner pins
// there (3V3 and GND) carry Dupont connectors and leave no room for a screw head.
// The top is flattened towards the middle of the board: RST and BOOT sit there at
// the USB end, and the module edge at the antenna end, ~2.3 mm from the hole center
// (from a photo of the component side).
esp_sd_flat = 1.8;             // from the hole center to the flat, inwards
esp_flat_h = 4;                // height of the flat (components ~3.2 + margin)
esp_peg_d = esp_hole_d - 0.8;  // peg with 0.4 mm clearance per side
module esp_standoff_raw(p) {
  inward = p.x < W/2 ? 1 : -1;
  translate([p.x, p.y, 0]) cylinder(d1=esp_sd + 2, d2=esp_sd, h=2);
  difference() {
    translate([p.x, p.y, 0]) cylinder(d=esp_sd, h=esp_under);
    translate([p.x + inward*esp_sd_flat + (inward > 0 ? 0 : -esp_sd), p.y - esp_sd, esp_under - esp_flat_h])
      cube([esp_sd, 2*esp_sd, esp_flat_h + 1]);
  }
  if (p.y < esp_yc) translate([p.x, p.y, esp_under - eps]) {
    cylinder(d=esp_peg_d, h=esp_pcb.z + esp_peg_h - 0.4 + eps);
    translate([0, 0, esp_pcb.z + esp_peg_h - 0.4]) cylinder(d1=esp_peg_d, d2=esp_peg_d - 0.8, h=0.4);
  }
}

// plug that closes the back slot up to just below the USB connector
module usb_plug() {
  tw = usb_slot_w - 2*fit;
  translate([W/2 - tw/2, D - wall, 0]) cube([tw, wall, usb_z - esp_usb.z/2 - 0.4]);
  translate([W/2 - tw/2, D - eps, 0]) cube([tw, 1.2 + eps, usb_z - usb_cut.y/2]);   // fills the frame
}

module base() difference() {
  union() {
    usb_plug();
    hull() {
      translate([0,0,-base_t]) linear_extrude(base_t - 1) footprint2d(plinth);
      translate([0,0,-1 - eps]) linear_extrude(1 + eps) footprint2d(plinth - 1);
    }
    difference() {
      linear_extrude(rim_h) difference() { footprint2d(-wall - fit); footprint2d(-wall - fit - 1.6); }
      for (p = col_pos) translate([p.x, p.y, -1]) cylinder(d=col_d + 6, h=rim_h + 2);
    }
    for (p = esp_holes) esp_standoff(p);
  }
  for (p = esp_holes) if (p.y > esp_yc) translate([p.x, p.y, 1]) cylinder(d=esp_pilot, h=esp_under);
  for (p = col_pos) {
    translate([p.x, p.y, -base_t - 1]) cylinder(d=3.4, h=base_t + 2);
    translate([p.x, p.y, -base_t - eps]) cylinder(d1=6.6, d2=3.4, h=1.6);
  }
  for (p = feet_pos) translate([p.x, p.y, -base_t - eps]) cylinder(d=10.5, h=1);
}

// ---------------------------------------------------------------- LCD retainer
module retainer2d() difference() {
  hull() for (s = [-1, 1]) {
    translate([boss_x, s*boss_y]) circle(r=3.6);
    translate([lcd_pcb.x/2 - 4, s*(boss_y + 3.6) - 0.5]) square([1, 1], center=true);
  }
  for (s = [-1, 1]) translate([boss_x, s*boss_y]) circle(d=2.3);
}
module retainer() linear_extrude(2.5) retainer2d();

module retainer_placed() on_panel() translate([lcd_c.x, lcd_c.y, -wall - fh - 2.5]) rotate([0, 0, lcd_rot]) retainer();

// ---------------------------------------------------------------- ghost parts
module esp_body() {
  difference() {
    translate([esp_x0, esp_y0, esp_under]) cube(esp_pcb);
    for (p = esp_holes) translate([p.x, p.y, esp_under - 1]) cylinder(d=esp_hole_d, h=esp_pcb.z + 2);
  }
  translate([W/2 - 9.5, esp_y0, esp_under - esp_top_h]) cube([19, 25.5, esp_top_h]);        // module, facing down (19 wide in the photo)
  // RST and BOOT buttons next to the USB-end holes (position relative to the hole, from the photo)
  for (p = esp_holes) if (p.y > esp_yc) {
    inward = p.x < W/2 ? 1 : -1;
    translate([p.x + inward*2.3 + (inward > 0 ? 0 : -2.8), p.y - 3.2, esp_under - 2]) cube([2.8, 4.8, 2]);
  }
  translate([W/2 - esp_usb.x/2, esp_y1 - esp_usb.y + esp_usb_over, esp_under - esp_usb.z]) cube(esp_usb);
}
module esp_headers() for (s = [-1, 1])
  translate([W/2 + s*esp_row_span/2 - 1.27, esp_yc - pin_half - 1.27, esp_under + esp_pcb.z])
    cube([2.54, 2*pin_half + 2.54, header_h]);
module esp_dupont() for (s = [-1, 1])
  translate([W/2 + s*esp_row_span/2 - 1.27, esp_yc - pin_half - 1.27, esp_under + esp_pcb.z + header_h])
    cube([2.54, 2*pin_half + 2.54, dupont_len]);
module esp_envelope() { esp_body(); esp_headers(); esp_dupont(); }

module lcd_body() on_panel() translate([lcd_c.x, lcd_c.y, -wall]) rotate([0, 0, lcd_rot]) {
  // glass with white frame, away from the pins
  translate([-lcd_pcb.x/2 + lcd_glass_top + lcd_glass.x/2, 0, -lcd_glass_t / 2])
    cube([lcd_glass.x, lcd_glass.y, lcd_glass_t - 0.1], center=true);
  translate([0, 0, -lcd_glass_t - lcd_pcb.z / 2]) cube([lcd_pcb.x, lcd_pcb.y, lcd_pcb.z], center=true);
}
module lcd_connector() on_panel() translate([lcd_c.x, lcd_c.y, -wall - fh]) rotate([0, 0, lcd_rot])
  translate([-lcd_pcb.x/2 + 0.3, -lcd_conn_len/2, -lcd_back]) cube([2.6, lcd_conn_len, lcd_back]);
module lcd_envelope() { lcd_body(); lcd_connector(); }

module ghosts_all() {
  color("#1b1b1b") esp_body();
  color("#333") esp_headers();
  color([1, 0.55, 0, 0.45]) esp_dupont();
  color("#d23a2a") lcd_body();
  color([1, 0.55, 0, 0.45]) lcd_connector();
}

// ---------------------------------------------------------------- output
module maybe_cut() if (cutaway) difference() { children(); translate([W/2, -50, -50]) cube([W, D + 100, H + 100]); } else children();

if (part == "assembly") {
  maybe_cut() color("#b9b3a7") shell();
  color("#3d3f42") base();
  color("#3d3f42") retainer_placed();
  if (ghosts) ghosts_all();
} else if (part == "shell") {
  shell();
} else if (part == "base") {
  translate([0, 0, base_t]) base();
} else if (part == "retainer") {
  retainer();
} else if (part == "check") {
  if (check_what == "all" || check_what == "esp_vs_case")
    color("red") intersection() { esp_envelope(); union() { shell(); base(); } }
  if (check_what == "all" || check_what == "lcd_vs_case")
    color("magenta") intersection() { lcd_envelope(); union() { shell(); base(); retainer_placed(); } }
  if (check_what == "all" || check_what == "lcd_vs_esp")
    color("blue") intersection() { lcd_envelope(); esp_envelope(); }
  if (check_what == "all" || check_what == "base_vs_shell")
    color("orange") intersection() { base(); shell(); }
}
