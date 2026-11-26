// ============================================================================
// Consola sci-fi HOLO para ESP32 (38 pines) + LCD ST7735S 1,44" 128x128
// Variante de 01-console/case/source/scifi_console.scad con pantalla "holográfica" (Pepper's ghost).
//
// Cómo funciona: el LCD va boca abajo arriba de una cámara negra y se refleja
// en una lámina transparente inclinada (tapa de caja de CD o acrílico fino).
// Mirando por la ventana del panel inclinado, la imagen aparece flotando
// dentro de la carcasa. Lo negro de la pantalla no se ve: solo lo encendido.
//
// Unidades: mm.  Ejes (visto de frente):
//   X = ancho, de izquierda a derecha
//   Y = profundidad, Y = 0 es el frente
//   Z = alto, Z = 0 es la cara superior de la base (= borde inferior de la carcasa)
//
// Piezas (elegir con `part`):
//   shell    carcasa naranja: cuña + panel con ventana + tapa + tabique.
//            Imprimir apoyada sobre el borde inferior abierto.
//   chamber  cámara oscura: lámina + asiento del LCD. Imprimir en NEGRO,
//            apoyada sobre el piso. Sin soportes.
//   base     placa inferior con columnas para la ESP32. Sin soportes.
//   glass    lámina transparente (solo referencia: se corta de una caja de CD).
//   assembly todo armado, con piezas fantasma.
//   check    muestra solo los choques (vacío = no hay choques).
// ============================================================================

/* [Vista] */
part = "assembly"; // [assembly, shell, chamber, base, glass, check]
ghosts = true;
cutaway = false;
show_rays = false;  // dibuja el volumen visible (para revisar la óptica)
show_virtual = false; // dibuja dónde aparece la imagen flotante
show_shell = true;
ghost_esp = true;

/* [Carcasa] */
D = 80;          // profundidad exterior
H = 68;          // alto exterior (8 mm más que la versión con pantalla directa)
lip_h = 10;      // zócalo frontal vertical
slope_a = 60;    // inclinación del panel respecto de la mesa (igual que la original)
wall = 2.6;
base_t = 3.2;
plinth = 1.5;
corner_ch = 4;
fit = 0.3;

/* [Óptica] */
// Rango de elevación del ojo (grados sobre la horizontal) en el que se ve la
// imagen completa. Fuera de ese rango se ve recortada.
view_lo = 12;
view_hi = 28;
glass_a = 27.5;           // inclinación de la lámina respecto de la mesa
glass_t = 1.3;            // espesor de la lámina (tapa de caja de CD: ~1,2-1,5)
glass_c = [56, 24];       // punto de referencia de la cara reflectante (y, z), bajo el centro del LCD
glass_u = [-34, 15];      // extremos de la lámina a lo largo de la pendiente, desde glass_c

/* [ESP32] */
esp_pcb = [28, 53, 1.6];
esp_hole_d = 3.0;
esp_hole_span = [24.0, 51.0];
esp_row_span = 25.4;
esp_pins = 19;
esp_top_h = 3.2;
esp_under = 7;
esp_peg_h = 1.2;
header_h = 2.5;
dupont_len = 20;
esp_usb = [7.5, 5.5, 2.6];
esp_usb_over = 3.0;
usb_inset = 0.3;
usb_cut = [14, 10];
usb_slot_w = esp_usb.x + 2;
esp_sd = 4.6;
esp_pilot = 2.2;

/* [LCD] */
// Marco local: largo de la PCB a lo largo de X (pines del lado +X, hacia la ESP32).
lcd_pcb = [44, 30, 1.6];
lcd_glass = [36, 28];
lcd_glass_t = 3.8;
lcd_lit_top = 13;               // la imagen arranca a 13 mm del borde de los pines
lcd_view = [28, 26];            // imagen: 28 a lo largo de la PCB x 26 a lo ancho
lcd_glass_off = lcd_pcb.x - 0.7 - lcd_glass.x;   // del borde de pines al vidrio
lcd_conn_len = 20.3;
lcd_back = 14;                  // Dupont sobre la PCB (incluye el header)

/* [Cámara] */
ch_wall = 2.0;     // paredes de la cámara
ch_floor = 1.6;
mask_t = 1.6;      // placa con la ventana sobre la que apoya el LCD
pocket_h = 6;      // alto del bolsillo que ubica al LCD
ledge_w = 2.2;     // repisas donde apoya la lámina
y_if = 14;         // frente de la cámara
y_ib = 75.2;       // fondo de la cámara

/* [Decoración] */
plate_h = 1.0;
bez_w = 3.5;
bez_h = 3.2;
relief = 1.0;

/* [Oculto] */
$fn = 48;
eps = 0.01;

// ---------------------------------------------------------------- distribución en X
ins_x0 = wall + fit + 1.6 + 0.3;            // la cámara entra dentro del reborde de la base
pocket_in = [lcd_pcb.x + 2*fit, lcd_pcb.y + 2*fit];
ins_w = pocket_in.x + 2*ch_wall;
xi = ins_x0 + ins_w/2;                      // centro de la cámara y de la PCB del LCD
ins_x1 = ins_x0 + ins_w;
div_x0 = ins_x1 + 0.4;                      // tabique entre cámara y ESP32
div_t = 2;
esp_x0 = div_x0 + div_t + 2.6;
W = esp_x0 + esp_pcb.x + 1.6 + wall;        // ancho exterior (sale ~90)
esp_cx = esp_x0 + esp_pcb.x/2;

x_img = xi + lcd_pcb.x/2 - lcd_lit_top - lcd_view.x/2;   // centro de la imagen en X

// ---------------------------------------------------------------- óptica
gy = glass_c[0]; gz = glass_c[1];
al = glass_a;
nG = [0, -sin(al), cos(al)];                // normal de la cara reflectante (hacia el ojo)
Gp = [x_img, gy, gz];
z_m = H - wall - 0.5 - (lcd_glass_t + lcd_pcb.z + lcd_back);   // cara del LCD (apoya en la máscara)
ihx = lcd_view.x/2 + 0.5;
ihy = lcd_view.y/2 + 0.5;

function vdir(e) = [0, -cos(e), sin(e)];
function refl(p) = p - 2*((p - Gp)*nG)*nG;
function ghit(V, e) = let(v = vdir(e), t = -((V - Gp)*nG)/(v*nG)) V + t*v;

S_c = [for (sx = [-1, 1], sy = [-1, 1]) [x_img + sx*ihx, gy + sy*ihy, z_m]];
V_c = [for (p = S_c) refl(p)];
Qe  = [for (e = [view_lo, view_hi], V = V_c) [ghit(V, e), e]];
Q   = [for (q = Qe) q[0]];
Far = [for (q = Qe) q[0] + 160*vdir(q[1])];

module pts_hull(pts) hull() for (p = pts) translate(p) cube(0.02, center=true);
module view_vol() pts_hull(concat(Q, Far));      // del vidrio hacia el ojo
module light_col() pts_hull(concat(S_c, Q));     // del LCD al vidrio

function s_hit(q, e) = let(
  t = (lip_h + q.y*tan(slope_a) - q.z)/(sin(e) + cos(e)*tan(slope_a)),
  z = q.z + t*sin(e)) (z - lip_h)/sin(slope_a);
win_s0 = min([for (q = Qe) s_hit(q[0], q[1])]);
win_s1 = max([for (q = Qe) s_hit(q[0], q[1])]);

// lámina: plano de la cara reflectante, u = distancia a lo largo de la pendiente
gu = [0, cos(al), sin(al)];
g_lo = [gy, gz] + glass_u[0]*[cos(al), sin(al)];
g_hi = [gy, gz] + glass_u[1]*[cos(al), sin(al)];
glass_len = glass_u[1] - glass_u[0];
glass_w = pocket_in.x - 0.6;
function zb(y) = gz + (y - gy)*tan(al) - glass_t/cos(al);   // cara inferior de la lámina

echo(str("HOLO: W=", W, "  lámina ", glass_w, " x ", glass_len, " x ", glass_t,
         "  inclinación ", al, "°  LCD a z=", z_m, "  ventana s=", win_s0, "..", win_s1));

// ---------------------------------------------------------------- derivados carcasa
L_slope = (H - lip_h) / sin(slope_a);
y_top   = (H - lip_h) / tan(slope_a);

esp_y1 = D - usb_inset - esp_usb_over;
esp_y0 = esp_y1 - esp_pcb.y;
esp_yc = (esp_y0 + esp_y1)/2;
esp_holes = [for (i=[-1,1], j=[-1,1]) [esp_cx + i*esp_hole_span.x/2, esp_yc + j*esp_hole_span.y/2]];
pin_half = (esp_pins - 1)/2 * 2.54;

col_d = 6;
col_back_y = D - wall - col_d/2 + 0.6;
col_pos = [
  [wall + col_d/2 - 0.6,     y_if - col_d/2 - 1],      // izquierda, delante de la cámara
  [wall + col_d/2 - 0.6,     col_back_y],              // izquierda, detrás de la cámara
  [div_x0 + div_t/2 - 0.5,   col_back_y],              // sobre el tabique, atrás
  [W - wall - col_d/2 + 0.6, esp_y0 - col_d/2 - 3.5]   // derecha, delante de la ESP32
];
feet_pos = [[14, 14], [W-14, 14], [14, D-14], [W-14, D-14]];
rim_h = 2;
usb_z = esp_under - esp_usb.z/2;

// ---------------------------------------------------------------- helpers
module profile2d(ext=0)
  polygon([[0,-ext],[0,lip_h],[y_top,H],[D,H],[D,-ext]]);

module footprint2d(o=0)
  offset(delta=o) polygon([[corner_ch,0],[W-corner_ch,0],[W,corner_ch],[W,D],[0,D],[0,corner_ch]]);

module along_x(x0, x1) translate([x0,0,0]) rotate([90,0,90]) linear_extrude(x1-x0) children();
module on_panel() translate([0,0,lip_h]) rotate([slope_a,0,0]) children();

module rrect(s, r) offset(r) offset(-r) square(s, center=true);
module chrect(s, c) polygon([
  [-s.x/2+c,-s.y/2],[s.x/2-c,-s.y/2],[s.x/2,-s.y/2+c],[s.x/2,s.y/2-c],
  [s.x/2-c,s.y/2],[-s.x/2+c,s.y/2],[-s.x/2,s.y/2-c],[-s.x/2,-s.y/2+c]]);

module ch_extrude(h, c) hull() {
  linear_extrude(h - c) children();
  translate([0,0,h-c-eps]) linear_extrude(c+eps) offset(delta=-c) children();
}

// ---------------------------------------------------------------- carcasa
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

// Tabique entre la cámara y la ESP32: sostiene el techo (puente más corto)
// y tiene una ventana para pasar los cables del LCD.
module divider() intersection() {
  translate([div_x0, -1, 0]) cube([div_t, D + 2, H]);
  cavity();
}
module divider_window() {
  wy = [gy - 11, gy + 12];
  wz = [H - wall - 22, H - wall - 9];
  translate([div_x0 - 1, 0, 0]) rotate([90, 0, 90]) linear_extrude(div_t + 2) hull() {
    translate([wy[0], wz[0]]) square([wy[1] - wy[0], wz[1] - wz[0]]);
    translate([(wy[0] + wy[1])/2, wz[1] + (wy[1] - wy[0])/2 - 1]) square(0.1, center=true);
  }
}

module stripes2d(size, w=3.0, pitch=6.0, ang=45) intersection() {
  square(size, center=true);
  rotate(ang) for (i = [-40:40]) translate([i*pitch, 0]) square([w, 300], center=true);
}

module hex_bolt(d=5.6, h=1.6) difference() {
  union() {
    cylinder(d=d + 1.4, h=0.5);
    cylinder(d=d, h=h, $fn=6);
  }
  translate([0, 0, h - 0.7]) cylinder(d=d*0.42, h=1, $fn=6);
}

// distribución del panel (coordenadas del panel: x = ancho, y = s sube por la pendiente)
win_c = [x_img, (win_s0 + win_s1)/2];
win_sz = [2*ihx + 1.2, win_s1 - win_s0 + 1.2];
bz_out = win_sz + [2*bez_w, 2*bez_w];
pb = 5.5;
p_bolts = [[pb, pb], [W-pb, pb], [pb, L_slope-pb], [W-pb, L_slope-pb]];
ctrl_x0 = win_c.x + bz_out.x/2 + 3;          // zona de controles, a la derecha de la ventana
ctrl_x1 = W - 3;
ctrl_c = [(ctrl_x0 + ctrl_x1)/2, L_slope/2];
ctrl_sz = [ctrl_x1 - ctrl_x0 - 4, L_slope - 2*pb - 8];
btn_s = [for (k = [-1 : 1]) ctrl_c.y + 4 + k*12];

module panel_decor() on_panel() {
  translate([W/2, L_slope/2]) ch_extrude(plate_h, 0.5) chrect([W-6, L_slope-5], 4);
  // marco de la ventana en dos escalones
  translate(win_c) {
    ch_extrude(plate_h + 1.6, 0.6) chrect(bz_out, 4);
    ch_extrude(plate_h + bez_h, 1.0) chrect(bz_out - [4, 4], 3);
  }
  for (p = p_bolts) translate(p) hex_bolt(4.2, plate_h + 1.4);
  // zona de controles (por ahora decorativa): placa con tres botones
  translate(ctrl_c) ch_extrude(plate_h + 0.8, 0.5) chrect(ctrl_sz, 3);
  for (s = btn_s) translate([ctrl_c.x, s]) ch_extrude(plate_h + 2.4, 0.6) circle(d=6);
}

module panel_cuts() {
  // ventana: todo lo que esté en la línea de visión, solo dentro del espesor del panel
  intersection() {
    view_vol();
    on_panel() translate([-1, -10, -wall - 0.5]) cube([W + 2, L_slope + 20, 20]);
  }
  on_panel() {
    // embudo del marco
    hull() {
      translate([win_c.x - win_sz.x/2, win_c.y - win_sz.y/2, -eps]) cube([win_sz.x, win_sz.y, eps]);
      translate([win_c.x - win_sz.x/2 - 1.6, win_c.y - win_sz.y/2 - 1.6, plate_h + bez_h])
        cube([win_sz.x + 3.2, win_sz.y + 3.2, eps]);
    }
    // franjas de advertencia al pie de la zona de controles
    sh = btn_s[0] - 6 - (ctrl_c.y - ctrl_sz.y/2) - 1.5;
    if (sh > 2) translate([ctrl_c.x, ctrl_c.y - ctrl_sz.y/2 + 1.5 + sh/2, plate_h + 0.2])
      linear_extrude(1) stripes2d([ctrl_sz.x - 4, sh], 2.2, 4.4);
    for (s = btn_s) translate([ctrl_c.x, s, plate_h + 0.2])
      difference() { cylinder(d=7.8, h=1); translate([0,0,-1]) cylinder(d=6, h=3); }
  }
}

// chaflanes a 45° en el techo, contra las paredes y del lado ESP32 del tabique
roof_ch = 8;
module roof_gussets() intersection() {
  translate([0, D, 0]) rotate([90, 0, 0]) linear_extrude(D) {
    for (m = [0, 1]) translate([m*W, 0]) mirror([m, 0])
      polygon([[wall - eps, H - wall + eps], [wall + roof_ch, H - wall + eps], [wall - eps, H - wall - roof_ch]]);
    x = div_x0 + div_t;
    polygon([[x - eps, H - wall + eps], [x + roof_ch, H - wall + eps], [x - eps, H - wall - roof_ch]]);
  }
  along_x(0, W) profile2d(0);
}

module ch_along_x(x0, h, c) hull() {
  along_x(x0, x0 + h - c) children();
  along_x(x0 + h - c - eps, x0 + h) offset(delta=-c) children();
}

module side_relief() {
  ch_along_x(W - eps, relief + eps, 0.6) offset(delta=-6) profile2d(0);
  for (y = [y_top - 6 : 4.2 : y_top + 6.6]) ch_along_x(W + relief - eps, 1.2 + eps, 0.5)
    translate([y, 11]) square([1.8, H*0.36]);
  for (p = [[11, 11], [D - 11, 11], [D - 11, H - 11], [y_top + 8, H - 11]])
    translate([W + relief - eps, p[0], p[1]]) rotate([0, 90, 0]) hex_bolt(5, 1.4);
}

// ventilación solo del lado de la ESP32 (del otro lado está la cámara oscura)
module side_cuts() along_x(W - wall - 1, W + relief + 1)
  for (y = [D - 30 : 4.5 : D - 16]) hull() {
    translate([y, 16]) circle(d=2.2);
    translate([y, H - 22]) circle(d=2.2);
  }

gh = esp_pcb.x/2 - 5;            // media rejilla sobre la ESP32
module top_decor() {
  for (x = [esp_cx - gh - 7, esp_cx + gh + 7]) translate([x, (y_top + 7 + D - 5)/2, H - eps])
    ch_extrude(3 + eps, 1.0) square([5, D - 5 - y_top - 7], center=true);
  for (x = [esp_cx - gh - 7, esp_cx + gh + 7]) translate([x, D - 9, H + 3 - 2*eps]) hex_bolt(3.6, 1.2);
  // placa remachada sobre la cámara
  translate([(corner_ch + div_x0)/2 + 1, (y_top + 7 + D - 5)/2, H - eps])
    ch_extrude(1.2 + eps, 0.5) chrect([div_x0 - corner_ch - 8, D - 5 - y_top - 9], 3);
  for (x = [12, div_x0 - 8], y = [y_top + 11, D - 11]) translate([x, y, H + 1.2 - 2*eps]) hex_bolt(3.6, 1.0);
}

module top_cuts() {
  for (y = [D - 36 : 4.5 : D - 13]) translate([esp_cx, y, H - wall - 1])
    linear_extrude(wall + 2) hull() { translate([-gh, 0]) circle(d=2.2); translate([gh, 0]) circle(d=2.2); }
  translate([esp_cx, D - 24.5, H - 0.6]) linear_extrude(1) difference() {
    chrect([2*gh + 6, 30], 3); offset(delta=-0.7) chrect([2*gh + 6, 30], 3);
  }
  translate([corner_ch, y_top + 4, H - 0.6]) cube([W - 2*corner_ch, 0.8, 1]);
}

module back_decor() {
  translate([esp_cx, D - eps, usb_z]) rotate([-90,0,0]) ch_extrude(1.2 + eps, 0.5) rrect([usb_cut.x + 7, usb_cut.y + 7], 2);
  // aletas tipo disipador a lo ancho de la parte trasera
  fin0 = 12; fin1 = W - 12;
  for (x = [fin0 : 4 : fin1]) if (abs(x - esp_cx) > (usb_cut.x + 7)/2 + 2) translate([x, D - eps, 16]) hull() {
    translate([-1, 0, 0]) cube([2, 0.6, H - 32]);
    translate([-0.4, 0, 0.6]) cube([0.8, 1.6, H - 33.2]);
  }
  for (x = [6, W - 6], z = [7, H - 7]) translate([x, D - eps, z]) rotate([-90, 0, 0]) hex_bolt(5, 1.4);
}

module back_cuts() {
  translate([esp_cx, D - wall - 1, usb_z]) rotate([-90,0,0]) linear_extrude(wall + 4) rrect(usb_cut, 2);
  translate([esp_cx - usb_slot_w/2, D - wall - 1, -1]) cube([usb_slot_w, wall + 4, usb_z + 1]);
}

module front_cuts() {
  translate([W/2, 0.6, lip_h/2 - 0.5]) rotate([90,0,0]) linear_extrude(2) stripes2d([W - 2*corner_ch - 6, lip_h - 6]);
}

module shell() difference() {
  intersection() { union() {
    difference() { shell_outer(); cavity(); }
    case_columns();
    divider();
    panel_decor();
    roof_gussets();
    side_relief();
    translate([W, 0, 0]) mirror([1, 0, 0]) side_relief();
    top_decor();
    back_decor();
  }
  translate([-50, -50, 0]) cube([W + 100, D + 100, H + 50]); }
  for (p = col_pos) translate([p.x, p.y, -eps]) cylinder(d=2.5, h=12);
  panel_cuts();
  divider_window();
  side_cuts();
  top_cuts();
  back_cuts();
  front_cuts();
  esp_grooves();
}

// ---------------------------------------------------------------- cámara oscura
// Pieza negra: piso, paredes laterales y trasera, repisas para la lámina,
// placa-máscara con ventana y bolsillo donde apoya el LCD boca abajo.
ch_y0 = y_if; ch_y1 = y_ib;
ch_top = z_m + pocket_h;
mask_y0 = gy - pocket_in.y/2 - ch_wall;     // frente de la máscara

// perfil lateral (YZ): sigue la pendiente por dentro, con juego
module chamber_side2d() intersection() {
  translate([ch_y0, 0]) square([ch_y1 - ch_y0, ch_top]);
  offset(delta=-wall - 0.6) profile2d(12);
}

module chamber_body() {
  // piso
  translate([ins_x0, ch_y0, 0]) cube([ins_w, ch_y1 - ch_y0, ch_floor]);
  // paredes laterales
  for (x = [ins_x0, ins_x1 - ch_wall]) along_x(x, x + ch_wall) chamber_side2d();
  // pared trasera
  translate([ins_x0, ch_y1 - ch_wall, 0]) cube([ins_w, ch_wall, ch_top]);
  // máscara
  translate([ins_x0, mask_y0, z_m - mask_t]) cube([ins_w, ch_y1 - mask_y0, mask_t]);
  // bolsillo del LCD
  translate([xi, gy, z_m]) linear_extrude(pocket_h) difference() {
    square(pocket_in + [2*ch_wall, 2*ch_wall], center=true);
    square(pocket_in, center=true);
  }
  // chaflanes a 45° bajo la máscara (acortan el puente), fuera de la columna de luz
  gl = x_img - ihx - 1 - (xi - pocket_in.x/2);
  gr = (xi + pocket_in.x/2) - (x_img + ihx + 1);
  translate([0, ch_y1, 0]) rotate([90, 0, 0]) linear_extrude(ch_y1 - mask_y0) {
    x0 = xi - pocket_in.x/2; x1 = xi + pocket_in.x/2;
    if (gl > 1) polygon([[x0 - eps, z_m - mask_t + eps], [x0 + gl, z_m - mask_t + eps], [x0 - eps, z_m - mask_t - gl]]);
    if (gr > 1) polygon([[x1 + eps, z_m - mask_t + eps], [x1 - gr, z_m - mask_t + eps], [x1 + eps, z_m - mask_t - gr]]);
  }
  // repisas bajo los bordes de la lámina, con tope abajo
  for (x = [xi - pocket_in.x/2, xi + pocket_in.x/2 - ledge_w]) along_x(x, x + ledge_w) {
    polygon([[g_lo.x + 1, ch_floor - eps], [g_hi.x, ch_floor - eps], [g_hi.x, zb(g_hi.x)], [g_lo.x + 1, zb(g_lo.x + 1)]]);
    translate([g_lo.x - 3.5, 0]) square([3, zb(g_lo.x) + 3]);          // tope inferior
  }
}

module chamber() difference() {
  chamber_body();
  // nada en el camino de la luz
  view_vol();
  light_col();
  // agujeros para los pernos de la base
  for (p = chamber_pegs) translate([p.x, p.y, -1]) cylinder(d=3.4, h=ch_floor + 2);
  // muescas para las columnas de la carcasa
  for (p = col_pos) translate([p.x, p.y, -1]) cylinder(d=col_d + 0.8, h=H);
  // paso de los cables del LCD por la pared lateral derecha, arriba
  translate([ins_x1 - ch_wall - 1, gy - lcd_conn_len/2 - 1.5, ch_top - 3]) cube([ch_wall + 2, lcd_conn_len + 3, 4]);
}

chamber_pegs = [[xi - pocket_in.x/2 + 5, ch_y0 + 5], [xi + pocket_in.x/2 - 5, ch_y1 - 7]];

// ---------------------------------------------------------------- lámina
module glass() translate([xi - glass_w/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(glass_w)
  hull() {
    translate(g_lo) square(0.01);
    translate(g_hi) square(0.01);
    translate(g_lo - glass_t*[-sin(al), cos(al)]) square(0.01);
    translate(g_hi - glass_t*[-sin(al), cos(al)]) square(0.01);
  }

// ---------------------------------------------------------------- base
groove_d = 1.0;
module esp_standoff(p) intersection() {
  esp_standoff_raw(p);
  translate([-1, -1, -1]) cube([W + 2, D - wall + groove_d - fit + 1, H]);
}
module esp_grooves() for (p = esp_holes) if (p.y > esp_yc)
  translate([p.x - (esp_sd + 1.4)/2 - fit, D - wall - 1, -1]) cube([esp_sd + 1.4 + 2*fit, 1 + groove_d, esp_under + 1.5]);

esp_sd_flat = 1.8;
esp_flat_h = 4;
esp_peg_d = esp_hole_d - 0.8;
module esp_standoff_raw(p) {
  inward = p.x < esp_cx ? 1 : -1;
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

module usb_plug() {
  tw = usb_slot_w - 2*fit;
  translate([esp_cx - tw/2, D - wall, 0]) cube([tw, wall, usb_z - esp_usb.z/2 - 0.4]);
  translate([esp_cx - tw/2, D - eps, 0]) cube([tw, 1.2 + eps, usb_z - usb_cut.y/2]);
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
      translate([div_x0 - fit, -1, -1]) cube([div_t + 2*fit, D + 2, rim_h + 2]);   // paso del tabique
    }
    for (p = esp_holes) esp_standoff(p);
    // pernos que ubican la cámara
    for (p = chamber_pegs) translate([p.x, p.y, -eps]) {
      cylinder(d=2.8, h=ch_floor + 0.8);
      translate([0, 0, ch_floor + 0.8]) cylinder(d1=2.8, d2=2.0, h=0.4);
    }
  }
  for (p = esp_holes) if (p.y > esp_yc) translate([p.x, p.y, 1]) cylinder(d=esp_pilot, h=esp_under);
  for (p = col_pos) {
    translate([p.x, p.y, -base_t - 1]) cylinder(d=3.4, h=base_t + 2);
    translate([p.x, p.y, -base_t - eps]) cylinder(d1=6.6, d2=3.4, h=1.6);
  }
  for (p = feet_pos) translate([p.x, p.y, -base_t - eps]) cylinder(d=10.5, h=1);
}

// ---------------------------------------------------------------- piezas fantasma
module esp_body() {
  difference() {
    translate([esp_x0, esp_y0, esp_under]) cube(esp_pcb);
    for (p = esp_holes) translate([p.x, p.y, esp_under - 1]) cylinder(d=esp_hole_d, h=esp_pcb.z + 2);
  }
  translate([esp_cx - 9.5, esp_y0, esp_under - esp_top_h]) cube([19, 25.5, esp_top_h]);
  for (p = esp_holes) if (p.y > esp_yc) {
    inward = p.x < esp_cx ? 1 : -1;
    translate([p.x + inward*2.3 + (inward > 0 ? 0 : -2.8), p.y - 3.2, esp_under - 2]) cube([2.8, 4.8, 2]);
  }
  translate([esp_cx - esp_usb.x/2, esp_y1 - esp_usb.y + esp_usb_over, esp_under - esp_usb.z]) cube(esp_usb);
}
module esp_headers() for (s = [-1, 1])
  translate([esp_cx + s*esp_row_span/2 - 1.27, esp_yc - pin_half - 1.27, esp_under + esp_pcb.z])
    cube([2.54, 2*pin_half + 2.54, header_h]);
module esp_dupont() for (s = [-1, 1])
  translate([esp_cx + s*esp_row_span/2 - 1.27, esp_yc - pin_half - 1.27, esp_under + esp_pcb.z + header_h])
    cube([2.54, 2*pin_half + 2.54, dupont_len]);
module esp_envelope() { esp_body(); esp_headers(); esp_dupont(); }

// LCD boca abajo: vidrio sobre la máscara, PCB arriba, pines del lado +X
module lcd_body() {
  translate([xi + lcd_pcb.x/2 - lcd_glass_off - lcd_glass.x, gy - lcd_glass.y/2, z_m])
    cube([lcd_glass.x, lcd_glass.y, lcd_glass_t - 0.1]);
  translate([xi - lcd_pcb.x/2, gy - lcd_pcb.y/2, z_m + lcd_glass_t]) cube([lcd_pcb.x, lcd_pcb.y, lcd_pcb.z]);
}
module lcd_lit() translate([x_img - lcd_view.x/2, gy - lcd_view.y/2, z_m - 0.05]) cube([lcd_view.x, lcd_view.y, 0.1]);
module lcd_connector() translate([xi + lcd_pcb.x/2 - 0.3 - 2.6, gy - lcd_conn_len/2, z_m + lcd_glass_t + lcd_pcb.z])
  cube([2.6, lcd_conn_len, lcd_back - 0.1]);
module lcd_envelope() { lcd_body(); lcd_connector(); }

module ghosts_all() {
  if (ghost_esp) {
    color("#1b1b1b") esp_body();
    color("#333") esp_headers();
    color([1, 0.55, 0, 0.45]) esp_dupont();
  }
  color("#d23a2a") lcd_body();
  color("#3cf2e0") lcd_lit();
  color([1, 0.55, 0, 0.45]) lcd_connector();
  color([0.7, 0.95, 1, 0.35]) glass();
}

// ---------------------------------------------------------------- salida
module maybe_cut() if (cutaway) difference() { children(); translate([x_img, -50, -50]) cube([W, D + 100, H + 100]); } else children();

if (part == "assembly") {
  if (show_shell) maybe_cut() color("#e8681e") shell();
  maybe_cut() color("#34363b") chamber();
  color("#3d3f42") base();
  if (ghosts) ghosts_all();
  if (show_rays) %view_vol();
  if (show_virtual) color([0.25, 1, 0.9, 0.55]) pts_hull(V_c);
} else if (part == "shell") {
  shell();
} else if (part == "chamber") {
  chamber();
} else if (part == "base") {
  translate([0, 0, base_t]) base();
} else if (part == "glass") {
  glass();
} else if (part == "check") {
  color("red")     intersection() { esp_envelope(); union() { shell(); base(); chamber(); } }
  color("magenta") intersection() { lcd_envelope(); union() { shell(); chamber(); } }
  color("blue")    intersection() { chamber(); shell(); }
  color("orange")  intersection() { chamber(); base(); }
  color("green")   intersection() { glass(); chamber(); }
  color("yellow")  intersection() { glass(); shell(); }
  color("cyan")    intersection() { light_col(); union() { chamber(); shell(); } }
}
