
/*

pi4_table_speaker_enclosure.scad — Design Summary
================================================

OVERALL DESIGN INTENT
---------------------
This model defines a serviceable Raspberry Pi 4 enclosure with:
- externally accessible USB / Ethernet and panel-mounted USB-C power on one wall,
- adhesive-mounted internal speakers firing upward through the lid,
- a removable internal “service deck” (table) that supports the speakers,
- ventilation on the side walls,
- three large external button openings on the opposite wall,
- robust parametric alignment so Pi ports stay aligned even as dimensions change.

The enclosure is intentionally oversized (2× taller and wider than a minimal Pi case)
to allow cable routing, airflow, and future modification.


MAIN COMPONENTS
---------------

1. BASE ENCLOSURE (MAIN BODY)
   - Structural shell of the enclosure.
   - Houses the Raspberry Pi, cabling, internal table posts, and airflow paths.
   - Parametric wall thickness and floor thickness.
   - Printed as a single part.

2. RASPBERRY PI MOUNTING SYSTEM
   - Four cylindrical standoffs sized for M2.5 screws.
   - Lifts the Pi above the floor for airflow and cable clearance.
   - Pi placement is computed so the center of the Pi’s USB/Ethernet connector cluster
     aligns with the center of the USB/Ethernet opening in the wall.
   - Alignment is robust against enclosure resizing and mirroring.

3. +Y WALL: EXTERNAL I/O FACE
   - Intended to face a hidden or rear location (e.g., against a wall).

   a) USB / ETHERNET WINDOW
      - Rectangular opening sized for the Pi’s stacked USB + Ethernet connectors.
      - Position is parametric and can be shifted inward from the edge.
      - Mirroring logic ensures correct left/right orientation when viewed externally.

   b) PANEL-MOUNT USB-C POWER PORT
      - Rectangular slit for a USB-C receptacle.
      - Two screw holes (one on each side of the slit) to secure a panel-mount adapter.
      - Hole spacing derived from measured adapter dimensions (25 mm boss width).
      - Provides strain relief and allows power connection without opening the enclosure.

4. −Y WALL: BUTTON INTERFACE
   - Three rectangular openings for external control buttons.
   - Each opening is 2.5" × 1.5".
   - Automatically centered and spaced.
   - Enclosure length auto-expands if needed to fit the buttons comfortably.

5. VENTILATION SYSTEM (±X WALLS)
   - Vertical ventilation slits on both side walls.
   - Evenly spaced and sized for passive airflow.
   - Positioned to promote convection around the Pi and internal electronics.

6. REMOVABLE INTERNAL TABLE (SERVICE DECK)
   - Horizontal plate mounted near the top of the enclosure.
   - Supported by four vertical posts anchored to the base.
   - Plate is fastened with M2.5 screws and is fully removable.
   - Separates speaker hardware from the Pi and main wiring.
   - Allows servicing the Pi without disturbing speaker mounting.

7. SPEAKERS (ADHESIVE-MOUNTED)
   - Speakers sit on top of the removable table.
   - Attached via adhesive backing (no screws or brackets).
   - Oriented to fire upward.
   - Lid includes matching openings so sound exits through the top.

8. LID (TOP COVER)
   - Closes the enclosure.
   - Acts as a speaker grille via two rectangular openings.
   - Shown lifted in assembly view for clarity.
   - Thickness chosen for rigidity and printability.

ASSEMBLY & SERVICE PHILOSOPHY
-----------------------------
- The Raspberry Pi remains mounted to the base at all times.
- The speaker table can be removed independently for maintenance.
- USB-C adapter is mechanically secured to the wall and removable from outside.
- No glued structural components.
- All fasteners are standard metric (M2 / M2.5).

PARAMETRIC & DIAGNOSTIC FEATURES
--------------------------------
- All critical dimensions are parameterized.
- Echo statements report enclosure size, port positions, and Pi-to-wall spacing.
- Designed to tolerate repeated dimensional changes without breaking alignment.

SUMMARY
-------
This is a robust, service-oriented Raspberry Pi enclosure optimized for
maintainability, clean external I/O, internal modularity, and future expansion.
It is intentionally designed more like a small appliance enclosure than a minimal case.

*/
// pi4_table_speaker_enclosure.scad
//
// Removable speaker table with M2.5 screws.
// Pi alignment FIXED (robust):
// - Align Pi using a tunable reference: distance from Pi LEFT EDGE to USB/Eth CLUSTER CENTER.
// - We compute the rendered USB/Eth window CENTER (accounts for MIRROR_PORT_FACE).
// - We place the Pi so its USB/Eth cluster center lands on the port-window center.
//
// USB-C panel-mount update:
// - USB-C SLIT + two screw holes (no “metal shell” assumptions)
// - Boss width across holes = 25mm, holes near edges (edge inset param)
//
// Button openings update:
// - Keep original button layout sizing (so outer_len does NOT change)
// - Replace the 3 large rectangular cutouts with 3 round cutouts (Ø24mm)
//   centered within the original rectangles.
//
// Tuned values in this file:
// - SHOW = 2
// - min_gap_between_openings = 40.0
// - spk_offset_x = 60
// - vent_slit_h = 30.0
// - ports_right_margin = 27.0
// - pi_bias_to_plusY = 33.0
//
// SHOW:
// 0=base only (with Pi standoffs + table posts)
// 1=lid only
// 2=assembly (base + removable table + lid lifted + speakers visual)
// 3=table only (print this part)
// 4=speakers visual only

$fn = 48;

SHOW = 0;
MIRROR_PORT_FACE = true;

inch = 25.4;

// -------------------------
// General print params
// -------------------------
wall      = 2.4;
floor_th  = 2.4;
lid_th    = 2.0;
clearance = 0.6;

edge_margin_x = 10.0;
min_gap_between_openings = 40.0;

// -------------------------
// Raspberry Pi 4 mounting
// -------------------------
pi_len      = 85.0;
pi_wid      = 56.0;
pi_hole_off = 3.5;
pi_hole_dx  = 58.0;
pi_hole_dy  = 49.0;

standoff_od = 6.5;
standoff_h  = 7.0;
standoff_id = 2.9;

// Move Pi toward +Y wall (ports wall)
pi_bias_to_plusY = 33.0;

// Distance from LEFT edge of Pi PCB to CENTER of USB/Eth connector cluster (mm)
pi_usbeth_center_from_left = 31.0;

// Optional tiny nudge after that (mm)
pi_port_fine_x = 0.0;

// Safety margin when clamping Pi inside the base
pi_side_margin = 2.0;

// -------------------------
// Height & width controls
// -------------------------
internal_hgt = 110; // twice as tall
internal_wid_default = 2 * (pi_wid + 2*14); // twice as wide

// -------------------------
// Button openings on -Y wall
// -------------------------
button_open_w = 2.5 * inch; // 63.5
button_open_h = 1.5 * inch; // 38.1
button_hole_d = 24.0;       // NEW: round hole diameter
button_gap_x     = 12.0;
button_extra_len = 30.0;

button_open_z = (internal_hgt + floor_th - button_open_h) / 2;

// -------------------------
// Speakers (adhesive-mounted)
// -------------------------
spk_w = 46.0; // mm
spk_d = 46.0; // mm
spk_h = 28.0; // mm

spk_open_w = spk_w + 1.0;
spk_open_d = spk_d + 1.0;

spk_offset_x = 60; // tuned
spk_offset_y = 0;

// -------------------------
// Enclosure sizing (auto-elongate X to fit buttons)
// (UNCHANGED: still based on the original rectangle sizing so outer_len stays same)
// -------------------------
internal_hgt_local = internal_hgt;
internal_wid = internal_wid_default;

internal_len_default = pi_len + 2*12;

buttons_total_span_x = 3*button_open_w + 2*button_gap_x;
required_outer_len_for_buttons = 2*edge_margin_x + buttons_total_span_x + button_extra_len;
required_internal_len_for_buttons = required_outer_len_for_buttons - 2*wall;

internal_len = (internal_len_default > required_internal_len_for_buttons)
  ? internal_len_default
  : required_internal_len_for_buttons;

outer_len = internal_len + 2*wall;
outer_wid = internal_wid + 2*wall;
outer_hgt = internal_hgt_local + floor_th + lid_th;

// -------------------------
// Ports on +Y wall
// -------------------------
usbeth_win_len_x = 58;
usbeth_win_h_z   = 16;
usbeth_win_z     = floor_th + standoff_h + 8;
usbeth_cut_depth = wall + 2.0;

// USB-C panel mount placement height (Z)
PANEL_MOUNT_Z = floor_th + 14.0;

// Move ports inward from outer edge
ports_right_margin = 27.0;

// -------------------------
// USB-C slit + screw holes (per your part)
// -------------------------
USBC_SLIT_W = 10.0;   // mm
USBC_SLIT_H = 4.2;    // mm

USBC_HOLE_BOSS_W  = 25.0;  // mm
USBC_HOLE_EDGE_IN = 2.5;   // mm (tune 2.0..3.0)
USBC_SCREW_C2C    = USBC_HOLE_BOSS_W - 2*USBC_HOLE_EDGE_IN; // mm
USBC_SCREW_D      = 2.6;   // mm clearance

// -------------------------
// Removable table (service deck) w/ M2.5 screws
// -------------------------
table_th         = 2.4;
table_margin     = 6.0;
table_post_inset = 10.0;

m25_clear_d   = 2.8;
m25_pilot_d   = 2.2;
table_post_od = 8.0;

underside_of_lid_z = outer_hgt - lid_th;
table_top_z        = underside_of_lid_z - spk_h;

table_plate_z0 = table_top_z - table_th;

table_post_z0 = floor_th;
table_post_h  = table_plate_z0 - table_post_z0;

// -------------------------
// Vent slits on ±X walls
// -------------------------
VENT_ENABLE = true;

vent_slit_w   = 3.5;
vent_slit_h   = 30.0; // tuned
vent_count    = 7;
vent_margin_y = 12.0;
vent_z0       = 0;

// -------------------------
// Helpers
// -------------------------
module box(x,y,z) { cube([x,y,z], center=false); }

function clamp(v, lo, hi) = v < lo ? lo : (v > hi ? hi : v);

module standoff(x,y) {
  translate([x,y,floor_th])
    difference() {
      cylinder(h=standoff_h, d=standoff_od);
      translate([0,0,-0.1]) cylinder(h=standoff_h+0.2, d=standoff_id);
    }
}

module post_m25(x,y) {
  translate([x,y,table_post_z0])
    difference() {
      cylinder(h=table_post_h, d=table_post_od);
      translate([0,0,-0.1]) cylinder(h=table_post_h+0.2, d=m25_pilot_d);
    }
}

// -------------------------
// Compute +Y port cutout positions (model space, before optional mirroring)
// -------------------------
usbc_half_span_x =
  max(USBC_SLIT_W/2, USBC_SCREW_C2C/2 + USBC_SCREW_D/2);

usbc_x_center_min = edge_margin_x + usbc_half_span_x;
usbc_x_center_max = outer_len - edge_margin_x - usbc_half_span_x;

usbeth_x0_min = edge_margin_x;
usbeth_x0_max = outer_len - edge_margin_x - usbeth_win_len_x;

usbeth_x0_desired = outer_len - edge_margin_x - ports_right_margin - usbeth_win_len_x;
usbeth_x0 = clamp(usbeth_x0_desired, usbeth_x0_min, usbeth_x0_max);

// Place USB-C to the LEFT of USB/Eth window with required gap
usbc_x_center_desired = usbeth_x0 - min_gap_between_openings - usbc_half_span_x;
usbc_x_center = clamp(usbc_x_center_desired, usbc_x_center_min, usbc_x_center_max);

// If clamping caused overlap, push USB/Eth right as far as possible
usbc_rightmost_x = usbc_x_center + usbc_half_span_x;
if (usbc_rightmost_x + min_gap_between_openings > usbeth_x0) {
  usbeth_x0 = clamp(usbc_rightmost_x + min_gap_between_openings, usbeth_x0_min, usbeth_x0_max);
}

// Rendered USB/Eth window left edge X0 (base coordinates), accounting for mirroring
function port_window_x0() =
  MIRROR_PORT_FACE
    ? (outer_len - (usbeth_x0 + usbeth_win_len_x))
    : (usbeth_x0);

function port_center_x() = port_window_x0() + usbeth_win_len_x/2;

echo("outer_len=", outer_len, " outer_wid=", outer_wid, " outer_hgt=", outer_hgt);
echo("USB/Eth x0(model)=", usbeth_x0, " port_window_x0(rendered)=", port_window_x0(), " port_center_x=", port_center_x());
echo("USB-C center X(model)=", usbc_x_center, " USBC_SCREW_C2C=", USBC_SCREW_C2C);
echo("pi_usbeth_center_from_left=", pi_usbeth_center_from_left, " pi_port_fine_x=", pi_port_fine_x, " pi_bias_to_plusY=", pi_bias_to_plusY);

// -------------------------
// Cutouts on +Y wall
// -------------------------
module usb_eth_window_plusY() {
  translate([usbeth_x0, outer_wid - usbeth_cut_depth, usbeth_win_z])
    box(usbeth_win_len_x, usbeth_cut_depth + 2.0, usbeth_win_h_z);
}

module usbc_slit_and_holes_plusY() {
  cut_depth = wall + 2.0;

  // Slit bottom at PANEL_MOUNT_Z
  translate([usbc_x_center - USBC_SLIT_W/2,
             outer_wid - cut_depth,
             PANEL_MOUNT_Z])
    box(USBC_SLIT_W, cut_depth + 2.0, USBC_SLIT_H);

  // Screw holes centered vertically on the slit
  hole_z = PANEL_MOUNT_Z + USBC_SLIT_H/2;

  // FIX: make hole cylinders centered through the wall so they always cut visibly
  for (sx = [-USBC_SCREW_C2C/2, +USBC_SCREW_C2C/2]) {
    translate([usbc_x_center + sx, outer_wid - wall/2, hole_z])
      rotate([90,0,0])
        cylinder(h=cut_depth + 6.0, d=USBC_SCREW_D, center=true);
  }
}

// -------------------------
// Three button openings on -Y wall (UPDATED: 3x Ø24mm, -Y wall only)
// -------------------------
module button_openings_minusY() {
  // Robust wall-only cutter: centered in the -Y wall thickness.
  eps = 0.8;                // small safety to avoid coplanar/tolerance issues
  cut_h = wall + eps;       // slightly larger than wall
  y_center = wall / 2;      // center of the -Y wall (y=0..wall)

  let(
    total_span = buttons_total_span_x,
    x_min = edge_margin_x,
    x_max = outer_len - edge_margin_x - total_span,
    x_start_raw = (outer_len - total_span)/2,
    x_start = (x_max < x_min) ? x_min : clamp(x_start_raw, x_min, x_max)
  ) {
    for (i = [0:2]) {
      let(
        x0 = x_start + i*(button_open_w + button_gap_x),
        x_center = x0 + button_open_w/2,
        z_center = button_open_z + button_open_h/2
      )
      translate([x_center, y_center, z_center])
        rotate([90,0,0]) // cylinder axis along Y
          cylinder(h=cut_h, d=button_hole_d, center=true);
    }
  }
}

// -------------------------
// Vent slits on ±X walls
// -------------------------
module vents_on_side_walls() {
  if (VENT_ENABLE) {
    cut_x = wall + 3.0;

    z_raw = (vent_z0 == 0) ? (table_top_z - table_th + 6.0) : vent_z0;
    z_max = underside_of_lid_z - vent_slit_h - 4.0;
    z_start = (z_raw > z_max) ? z_max : z_raw;

    vent_band_y0 = wall + vent_margin_y;
    vent_band_y1 = outer_wid - wall - vent_margin_y;

    band_len = vent_band_y1 - vent_band_y0;
    step = band_len / (vent_count + 1);

    for (i = [1 : vent_count]) {
      y_i = vent_band_y0 + i*step;

      translate([-1.0, y_i - vent_slit_w/2, z_start])
        box(cut_x + 2.0, vent_slit_w, vent_slit_h);

      translate([outer_len - cut_x + 1.0, y_i - vent_slit_w/2, z_start])
        box(cut_x + 2.0, vent_slit_w, vent_slit_h);
    }
  }
}

// -------------------------
// Removable table: plate + clearance holes
// -------------------------
function table_x0() = wall + table_margin;
function table_y0() = wall + table_margin;
function table_x1() = outer_len - wall - table_margin;
function table_y1() = outer_wid - wall - table_margin;

function post_x0() = wall + table_post_inset;
function post_x1() = outer_len - wall - table_post_inset;
function post_y0() = wall + table_post_inset;
function post_y1() = outer_wid - wall - table_post_inset;

module table_plate() {
  difference() {
    translate([table_x0(), table_y0(), table_plate_z0])
      box(table_x1()-table_x0(), table_y1()-table_y0(), table_th);

    for (px = [post_x0(), post_x1()])
      for (py = [post_y0(), post_y1()])
        translate([px, py, table_plate_z0 - 0.2])
          cylinder(h=table_th + 0.4, d=m25_clear_d);
  }
}

module table_posts() {
  for (px = [post_x0(), post_x1()])
    for (py = [post_y0(), post_y1()])
      post_m25(px, py);
}

// -------------------------
// Speakers (visual solids only)
// -------------------------
module speakers_visual() {
  spk_z0 = table_top_z - spk_h;

  cx = outer_len/2;
  cy = outer_wid/2 + spk_offset_y;

  sxL = cx - spk_offset_x - spk_w/2;
  sxR = cx + spk_offset_x - spk_w/2;
  sy  = cy - spk_d/2;

  translate([sxL, sy, spk_z0]) box(spk_w, spk_d, spk_h);
  translate([sxR, sy, spk_z0]) box(spk_w, spk_d, spk_h);
}

// -------------------------
// Lid with speaker openings
// -------------------------
module lid() {
  difference() {
    translate([0,0,outer_hgt - lid_th])
      box(outer_len, outer_wid, lid_th);

    cx = outer_len/2;
    cy = outer_wid/2 + spk_offset_y;
    z0 = outer_hgt - lid_th - 0.1;

    translate([cx - spk_offset_x - spk_open_w/2, cy - spk_open_d/2, z0])
      box(spk_open_w, spk_open_d, lid_th + 0.2);

    translate([cx + spk_offset_x - spk_open_w/2, cy - spk_open_d/2, z0])
      box(spk_open_w, spk_open_d, lid_th + 0.2);
  }
}

// -------------------------
// Base
// -------------------------
module base() {
  difference() {
    box(outer_len, outer_wid, outer_hgt - lid_th);

    // Inner cavity
    translate([wall, wall, floor_th])
      box(internal_len, internal_wid, internal_hgt_local);

    // +Y wall ports (mirror around center plane if enabled)
    if (MIRROR_PORT_FACE) {
      translate([outer_len, 0, 0]) mirror([1,0,0]) {
        usb_eth_window_plusY();
        usbc_slit_and_holes_plusY();
      }
    } else {
      usb_eth_window_plusY();
      usbc_slit_and_holes_plusY();
    }

    // -Y wall buttons
    button_openings_minusY();

    // Vents
    vents_on_side_walls();
  }

  // Pi standoffs:
  // Align Pi so its USB/Eth cluster center matches the rendered port-window center.
  pi_origin_x_raw =
    port_center_x()
    - pi_usbeth_center_from_left
    + pi_port_fine_x;

  pi_origin_x_min = wall + pi_side_margin;
  pi_origin_x_max = outer_len - wall - pi_len - pi_side_margin;
  pi_origin_x = clamp(pi_origin_x_raw, pi_origin_x_min, pi_origin_x_max);

  pi_origin_y = wall + (internal_wid - pi_wid)/2 + pi_bias_to_plusY;

  // Diagnostic for Pi vs port wall distance (Y)
  y_inner_ports_wall = outer_wid - wall;
  y_row_near_ports = pi_origin_y + pi_hole_off + pi_hole_dy;
  echo("Y gap (inside wall -> near Pi hole row) = ", y_inner_ports_wall - y_row_near_ports, "mm");

  standoff(pi_origin_x + pi_hole_off,              pi_origin_y + pi_hole_off);
  standoff(pi_origin_x + pi_hole_off + pi_hole_dx, pi_origin_y + pi_hole_off);
  standoff(pi_origin_x + pi_hole_off,              pi_origin_y + pi_hole_off + pi_hole_dy);
  standoff(pi_origin_x + pi_hole_off + pi_hole_dx, pi_origin_y + pi_hole_off + pi_hole_dy);

  table_posts();
}

// -------------------------
// Build selector
// -------------------------
if (SHOW == 0) {
  base();
} else if (SHOW == 1) {
  lid();
} else if (SHOW == 2) {
  base();
  table_plate();
  translate([0,0,8]) lid();
  speakers_visual();
} else if (SHOW == 3) {
  table_plate();
} else {
  speakers_visual();
}

