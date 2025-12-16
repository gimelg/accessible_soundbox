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
// - Replace the 3 large rectangular cutouts with 3 round cutouts (Ø24mm)
// - Keep original button layout sizing (so outer_len does NOT change)
//
// Table update:
// - Lightweight “skeleton” table plate: minimal material while keeping stiffness
//
// SHOW:
// 0=base only (with Pi standoffs + table posts)
// 1=lid only
// 2=assembly (base + removable table + lid lifted + speakers visual)
// 3=table only (print this part)
// 4=speakers visual only
// 5=base + table (NO lid)
*/


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

pi_bias_to_plusY = 33.0;
pi_usbeth_center_from_left = 31.0;
pi_port_fine_x = 0.0;
pi_side_margin = 2.0;

// -------------------------
// Height & width controls
// -------------------------
internal_hgt = 110;
internal_wid_default = 2 * (pi_wid + 2*14);

// -------------------------
// Button openings on -Y wall
// -------------------------
button_open_w = 2.5 * inch;
button_open_h = 1.5 * inch;
button_hole_d = 24.0;

button_gap_x     = 12.0;
button_extra_len = 30.0;

button_open_z = (internal_hgt + floor_th - button_open_h) / 2;

// -------------------------
// Speakers (adhesive-mounted)
// -------------------------
spk_w = 46.0;
spk_d = 46.0;
spk_h = 28.0;

spk_open_w = spk_w + 1.0;
spk_open_d = spk_d + 1.0;

spk_offset_x = 60;
spk_offset_y = 28;

// -------------------------
// Enclosure sizing (auto-elongate X to fit buttons)
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

PANEL_MOUNT_Z = floor_th + 14.0;
ports_right_margin = 27.0;

// -------------------------
// USB-C slit + screw holes
// -------------------------
USBC_SLIT_W = 10.0;
USBC_SLIT_H = 4.2;

USBC_HOLE_BOSS_W  = 25.0;
USBC_HOLE_EDGE_IN = 2.5;
USBC_SCREW_C2C    = USBC_HOLE_BOSS_W - 2*USBC_HOLE_EDGE_IN;
USBC_SCREW_D      = 2.6;

// -------------------------
// Removable table (service deck) w/ M2.5 screws
// -------------------------
table_th         = 2.4;
table_margin     = 6.0;
table_post_inset = 10.0;

m25_clear_d   = 2.8;
m25_pilot_d   = 2.2;
table_post_od = 8.0;

// -------------------------
// Lightweight table plate
// -------------------------
TABLE_LITE_ENABLE = true;

table_frame_w  = 6.0;
table_rib_w    = 6.0;
table_boss_pad = 14.0;

spk_pad_margin = 4.0;

underside_of_lid_z = outer_hgt - lid_th;
table_top_z        = underside_of_lid_z - spk_h;

table_plate_z0 = table_top_z - table_th;

table_post_z0 = floor_th;
table_post_h  = table_plate_z0 - table_post_z0;

// -------------------------
// NEW: Center catch-support post + table contact pad
// -------------------------
CENTER_CATCH_ENABLE = true;

// Same OD as corner posts; shorter by this gap (0.4–0.6mm recommended)
center_catch_gap = 0.5;

// Broad contact pad on underside of table at the + intersection
CENTER_PAD_ENABLE = true;
center_pad_size   = 18.0;  // square pad size (mm)
center_pad_th     = 1.6;   // pad thickness downward from table underside

// -------------------------
// Structural diagnostics: table supports
// -------------------------

// Corner posts (4x) — from floor to table underside
echo("CORNER POST HEIGHT (table_post_h) = ", table_post_h, " mm");

// Center catch post — actual printed height
h_center_catch =
  max(0,
      table_post_h
      - ((CENTER_PAD_ENABLE ? center_pad_th : 0) + center_catch_gap));

echo("CENTER CATCH POST HEIGHT = ", h_center_catch, " mm");

// Underside contact pad (underplate) thickness
echo("CENTER UNDERSIDE PAD THICKNESS (center_pad_th) = ", center_pad_th, " mm");

// Optional: verify clearance between post top and pad bottom
echo("CENTER GAP (post → pad bottom) = ",
     table_post_h - (h_center_catch + center_pad_th),
     " mm");


// -------------------------
// Vent slits on ±X walls
// -------------------------
VENT_ENABLE = true;

vent_slit_w   = 3.5;
vent_slit_h   = 30.0;
vent_count    = 7;
vent_margin_y = 12.0;
vent_z0       = 0;

// -------------------------
// LID “BOAT” POUCH (printed as one piece with lid)
// -------------------------
POUCH_ENABLE = true;

// CLEAR (inside) dimensions at the lid opening
pouch_open_len_y = 43.0;   // Y
pouch_open_wid_x = 10.0;   // X
pouch_depth      = 12.0;   // Z down

// Material thickness (grows outward)
pouch_wall  = 2.0;

// Outer shell dimensions under the lid
pouch_len_y = pouch_open_len_y + 2*pouch_wall; // 47
pouch_wid_x = pouch_open_wid_x + 2*pouch_wall; // 14

// Shape controls
pouch_round = 5.0;
pouch_taper = 0.80;

// Placement clamp
pouch_edge_clear = wall + 3.0;

function pouch_half_x() = (pouch_wid_x/2);
function pouch_half_y() = (pouch_len_y/2);

pouch_cx = clamp(outer_len/2,
                 pouch_edge_clear + pouch_half_x(),
                 outer_len - pouch_edge_clear - pouch_half_x());

// Base placement: toward -Y (button wall)...
pouch_cy_base = wall + 18.0;

// ...then shift toward the middle to create more room for the edge rib
pouch_cy_shift_to_mid = 10.0;

pouch_cy_desired = pouch_cy_base + pouch_cy_shift_to_mid;
pouch_cy = clamp(pouch_cy_desired,
                 pouch_edge_clear + pouch_half_y(),
                 outer_wid - pouch_edge_clear - pouch_half_y());

// Retention rib (X only) near bottom
pouch_retain_enable = true;
pouch_retain_th = 1.6;
pouch_retain_w  = 2.2;
pouch_retain_overlap = 0.8;

// -------------------------
// Lid reinforcements
// -------------------------
LID_REINF_ENABLE = true;

// 1) Flat ring under pouch opening
lid_ring_radial = 1.4;
lid_ring_th     = 1.0;

// 2) Lid stiffener ribs
lid_rib_enable = true;
lid_rib_h      = 1.6;
lid_rib_wy     = 7.0;
lid_rib_edge_x = 8.0;
lid_rib_edge_y = 8.0;
lid_rib_gap_from_features = 6.0;

// Middle rib between boat and speakers
lid_mid_rib_enable = true;
lid_mid_rib_clear  = 2.0;

// -------------------------
// Helpers
// -------------------------
module box(x,y,z) { cube([x,y,z], center=false); }

function clamp(v, lo, hi) = v < lo ? lo : (v > hi ? hi : v);

function nudge_away_from_band(yc, band0, band1, halfw, nudge) =
  (yc > band0 - halfw && yc < band1 + halfw)
    ? ((yc < (band0+band1)/2) ? (band0 - halfw - nudge) : (band1 + halfw + nudge))
    : yc;

module lid_rib_block(x0, x1, yc, wy, z_und, h) {
  translate([x0, yc - wy/2, z_und - h])
    box(x1 - x0, wy, h);
}

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

module capsule2d(L, W, R) {
  rr = clamp(R, 0.1, min(W/2 - 0.1, L/2 - 0.1));
  hull() {
    translate([-(L/2 - rr), 0]) circle(r=rr);
    translate([+(L/2 - rr), 0]) circle(r=rr);
  }
}

// -------------------------
// Pouch opening through lid
// -------------------------
module lid_pouch_opening_cut() {
  Lc = pouch_open_len_y;
  Wc = pouch_open_wid_x;
  Rc = clamp(pouch_round, 0.1, min(Wc/2 - 0.1, Lc/2 - 0.1));

  translate([pouch_cx, pouch_cy, outer_hgt - lid_th - 0.2])
    linear_extrude(height=lid_th + 0.4, convexity=10)
      rotate(90) capsule2d(Lc, Wc, Rc);
}

// -------------------------
// Reinforcement ring around pouch opening (underside)
// -------------------------
module lid_pouch_reinforcement_ring() {
  if (LID_REINF_ENABLE && lid_ring_th > 0 && lid_ring_radial > 0) {
    z_und = outer_hgt - lid_th;

    Lc = pouch_open_len_y;
    Wc = pouch_open_wid_x;
    Rc = clamp(pouch_round, 0.1, min(Wc/2 - 0.1, Lc/2 - 0.1));

    Lout = Lc + 2*lid_ring_radial;
    Wout = Wc + 2*lid_ring_radial;
    Rout = Rc + lid_ring_radial;

    translate([pouch_cx, pouch_cy, z_und - lid_ring_th])
      difference() {
        linear_extrude(height=lid_ring_th, convexity=10)
          rotate(90) capsule2d(Lout, Wout, Rout);

        translate([0,0,-0.2])
          linear_extrude(height=lid_ring_th + 0.4, convexity=10)
            rotate(90) capsule2d(Lc, Wc, Rc);
      }
  }
}

// -------------------------
// Lid stiffener ribs (underside)
// - Middle rib between boat and speakers
// - Top rib explicitly ABOVE speakers (other side of speaker holes)
// -------------------------
module lid_stiffener_ribs() {
  if (LID_REINF_ENABLE && lid_rib_enable && lid_rib_h > 0 && lid_rib_wy > 0) {

    z_und = outer_hgt - lid_th;

    cx = outer_len/2;
    cy = outer_wid/2 + spk_offset_y;

    // Speaker opening band (avoid)
    spk_y0 = cy - spk_open_d/2;
    spk_y1 = spk_y0 + spk_open_d;

    // Speaker opening X bounds (keepouts)
    spk1_x0 = cx - spk_offset_x - spk_open_w/2;
    spk1_x1 = spk1_x0 + spk_open_w;
    spk2_x0 = cx + spk_offset_x - spk_open_w/2;
    spk2_x1 = spk2_x0 + spk_open_w;

    rib_x0 = lid_rib_edge_x;
    rib_x1 = outer_len - lid_rib_edge_x;

    rib_yc_min = lid_rib_edge_y + lid_rib_wy/2;
    rib_yc_max = outer_wid - lid_rib_edge_y - lid_rib_wy/2;

    // Boat keepout (outer pouch footprint + gap)
    boat_keep_y0 = pouch_cy - pouch_len_y/2 - lid_rib_gap_from_features - lid_rib_wy/2;
    boat_keep_y1 = pouch_cy + pouch_len_y/2 + lid_rib_gap_from_features + lid_rib_wy/2;

    low_zone_max = boat_keep_y0 - 1.0;

    rib1_ok = (low_zone_max > rib_yc_min);

    rib1_yc_base = rib1_ok ? clamp((rib_yc_min + low_zone_max)/2, rib_yc_min, low_zone_max) : 0;

    rib1_yc_final =
      rib1_ok
        ? clamp(nudge_away_from_band(rib1_yc_base, spk_y0, spk_y1, lid_rib_wy/2, 1.0), rib_yc_min, low_zone_max)
        : 0;

    // Middle rib: between boat and speakers
    mid_band_y0 = boat_keep_y1 + lid_mid_rib_clear + lid_rib_wy/2;
    mid_band_y1 = spk_y0      - lid_mid_rib_clear - lid_rib_wy/2;

    ribm_ok = (lid_mid_rib_enable && (mid_band_y1 > mid_band_y0));
    ribm_yc = ribm_ok ? clamp((mid_band_y0 + mid_band_y1)/2, rib_yc_min, rib_yc_max) : 0;

    // Top rib: explicitly ABOVE speakers
    top_band_y0 = spk_y1 + lid_rib_gap_from_features + lid_rib_wy/2;
    top_band_y1 = rib_yc_max;

    rib2_ok = (top_band_y1 > top_band_y0);
    rib2_yc_final = rib2_ok ? (top_band_y0 + top_band_y1)/2 : 0;

    // Diagnostics
    echo("pouch_cy=", pouch_cy, " boat_keep_y0=", boat_keep_y0, " boat_keep_y1=", boat_keep_y1);
    echo("spk_y0=", spk_y0, " spk_y1=", spk_y1);
    echo("mid_band=[", mid_band_y0, ",", mid_band_y1, "] ribm_ok=", ribm_ok, " mid=", ribm_yc);
    echo("top_band=[", top_band_y0, ",", top_band_y1, "] rib2_ok=", rib2_ok, " rib2=", rib2_yc_final);
    echo("rib1_ok=", rib1_ok, " rib1=", rib1_yc_final);

    difference() {
      union() {
        if (rib1_ok) lid_rib_block(rib_x0, rib_x1, rib1_yc_final, lid_rib_wy, z_und, lid_rib_h);
        if (ribm_ok) lid_rib_block(rib_x0, rib_x1, ribm_yc,       lid_rib_wy, z_und, lid_rib_h);
        if (rib2_ok) lid_rib_block(rib_x0, rib_x1, rib2_yc_final, lid_rib_wy, z_und, lid_rib_h);
      }

      // Speaker keepouts (safety)
      keep = 1.0;

      translate([spk1_x0 - keep, spk_y0 - keep, z_und - lid_rib_h - 0.2])
        box((spk1_x1 - spk1_x0) + 2*keep, (spk_y1 - spk_y0) + 2*keep, lid_rib_h + 0.4);

      translate([spk2_x0 - keep, spk_y0 - keep, z_und - lid_rib_h - 0.2])
        box((spk2_x1 - spk2_x0) + 2*keep, (spk_y1 - spk_y0) + 2*keep, lid_rib_h + 0.4);
    }
  }
}

// -------------------------
// Pouch shell (printed with lid)
// -------------------------
module lid_pouch_shell() {
  z_lid_underside = outer_hgt - lid_th;

  L0 = pouch_len_y;
  W0 = pouch_wid_x;
  R0 = pouch_round + pouch_wall;

  Li0 = pouch_open_len_y;
  Wi0 = pouch_open_wid_x;
  Ri0 = pouch_round;

  s = pouch_taper;

  translate([pouch_cx, pouch_cy, z_lid_underside]) {
    mirror([0,0,1]) {
      difference() {
        linear_extrude(height=pouch_depth, scale=s, convexity=10)
          rotate(90) capsule2d(L0, W0, R0);

        translate([0,0,-0.2])
          linear_extrude(height=pouch_depth + 0.4, scale=s, convexity=10)
            rotate(90) capsule2d(Li0, Wi0, Ri0);
      }
    }
  }

  if (pouch_retain_enable) {
    z_bottom = z_lid_underside - pouch_depth;

    inner_bot_wx = pouch_open_wid_x * pouch_taper;
    overlap = pouch_retain_overlap;

    rib_x_len = max(0.2, inner_bot_wx + overlap);

    translate([pouch_cx - rib_x_len/2,
               pouch_cy - pouch_retain_w/2,
               z_bottom])
      box(rib_x_len, pouch_retain_w, pouch_retain_th);
  }
}

// -------------------------
// Compute +Y port cutout positions
// -------------------------
usbc_half_span_x =
  max(USBC_SLIT_W/2, USBC_SCREW_C2C/2 + USBC_SCREW_D/2);

usbc_x_center_min = edge_margin_x + usbc_half_span_x;
usbc_x_center_max = outer_len - edge_margin_x - usbc_half_span_x;

usbeth_x0_min = edge_margin_x;
usbeth_x0_max = outer_len - edge_margin_x - usbeth_win_len_x;

usbeth_x0_desired = outer_len - edge_margin_x - ports_right_margin - usbeth_win_len_x;
usbeth_x0 = clamp(usbeth_x0_desired, usbeth_x0_min, usbeth_x0_max);

usbc_x_center_desired = usbeth_x0 - min_gap_between_openings - usbc_half_span_x;
usbc_x_center = clamp(usbc_x_center_desired, usbc_x_center_min, usbc_x_center_max);

usbc_rightmost_x = usbc_x_center + usbc_half_span_x;
if (usbc_rightmost_x + min_gap_between_openings > usbeth_x0) {
  usbeth_x0 = clamp(usbc_rightmost_x + min_gap_between_openings, usbeth_x0_min, usbeth_x0_max);
}

function port_window_x0() =
  MIRROR_PORT_FACE
    ? (outer_len - (usbeth_x0 + usbeth_win_len_x))
    : (usbeth_x0);

function port_center_x() = port_window_x0() + usbeth_win_len_x/2;

echo("outer_len=", outer_len, " outer_wid=", outer_wid, " outer_hgt=", outer_hgt);
echo("USB/Eth x0(model)=", usbeth_x0, " port_window_x0(rendered)=", port_window_x0(), " port_center_x=", port_center_x());
echo("USB-C center X(model)=", usbc_x_center, " USBC_SCREW_C2C=", USBC_SCREW_C2C);

// -------------------------
// Cutouts on +Y wall
// -------------------------
module usb_eth_window_plusY() {
  translate([usbeth_x0, outer_wid - usbeth_cut_depth, usbeth_win_z])
    box(usbeth_win_len_x, usbeth_cut_depth + 2.0, usbeth_win_h_z);
}

module usbc_slit_and_holes_plusY() {
  cut_depth = wall + 2.0;

  translate([usbc_x_center - USBC_SLIT_W/2,
             outer_wid - cut_depth,
             PANEL_MOUNT_Z])
    box(USBC_SLIT_W, cut_depth + 2.0, USBC_SLIT_H);

  hole_z = PANEL_MOUNT_Z + USBC_SLIT_H/2;

  for (sx = [-USBC_SCREW_C2C/2, +USBC_SCREW_C2C/2]) {
    translate([usbc_x_center + sx, outer_wid - wall/2, hole_z])
      rotate([90,0,0])
        cylinder(h=cut_depth + 6.0, d=USBC_SCREW_D, center=true);
  }
}

// -------------------------
// Three button openings on -Y wall (3x Ø24mm)
// -------------------------
module button_openings_minusY() {
  eps = 0.8;
  cut_h = wall + eps;
  y_center = wall / 2;

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
        rotate([90,0,0])
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
// Removable table
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
  if (!TABLE_LITE_ENABLE) {
    difference() {
      translate([table_x0(), table_y0(), table_plate_z0])
        box(table_x1()-table_x0(), table_y1()-table_y0(), table_th);

      for (px = [post_x0(), post_x1()])
        for (py = [post_y0(), post_y1()])
          translate([px, py, table_plate_z0 - 0.2])
            cylinder(h=table_th + 0.4, d=m25_clear_d);
    }
  } else {
    difference() {
      union() {
        if (table_frame_w > 0) {
          translate([table_x0(), table_y0(), table_plate_z0])
            box(table_x1()-table_x0(), table_frame_w, table_th);
          translate([table_x0(), table_y1()-table_frame_w, table_plate_z0])
            box(table_x1()-table_x0(), table_frame_w, table_th);

          translate([table_x0(), table_y0(), table_plate_z0])
            box(table_frame_w, table_y1()-table_y0(), table_th);
          translate([table_x1()-table_frame_w, table_y0(), table_plate_z0])
            box(table_frame_w, table_y1()-table_y0(), table_th);
        }

        for (px = [post_x0(), post_x1()])
          for (py = [post_y0(), post_y1()])
            translate([px - table_boss_pad/2, py - table_boss_pad/2, table_plate_z0])
              box(table_boss_pad, table_boss_pad, table_th);

        cx = outer_len/2;
        cy = outer_wid/2 + spk_offset_y;

        pad_w = spk_w + 2*spk_pad_margin;
        pad_d = spk_d + 2*spk_pad_margin;

        xL = cx - spk_offset_x - pad_w/2;
        xR = cx + spk_offset_x - pad_w/2;
        y0 = cy - pad_d/2;

        translate([xL, y0, table_plate_z0]) box(pad_w, pad_d, table_th);
        translate([xR, y0, table_plate_z0]) box(pad_w, pad_d, table_th);

        y_mid = cy;

        translate([post_x0(), y_mid - table_rib_w/2, table_plate_z0])
          box(post_x1()-post_x0(), table_rib_w, table_th);

        x_mid = cx;
        translate([x_mid - table_rib_w/2, post_y0(), table_plate_z0])
          box(table_rib_w, post_y1()-post_y0(), table_th);

        // NEW: broad contact pad on UNDERSIDE at the + intersection
        if (CENTER_PAD_ENABLE && center_pad_th > 0 && center_pad_size > 0) {
          translate([x_mid - center_pad_size/2,
                     y_mid - center_pad_size/2,
                     table_plate_z0 - center_pad_th])
            box(center_pad_size, center_pad_size, center_pad_th);
        }
      }

      for (px = [post_x0(), post_x1()])
        for (py = [post_y0(), post_y1()])
          translate([px, py, table_plate_z0 - 0.2])
            cylinder(h=table_th + 0.4, d=m25_clear_d);
    }
  }
}

module table_posts() {
  for (px = [post_x0(), post_x1()])
    for (py = [post_y0(), post_y1()])
      post_m25(px, py);
}

// -------------------------
// Speakers (visual only)
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
// Lid
// -------------------------
module lid() {
  union() {
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

      if (POUCH_ENABLE) lid_pouch_opening_cut();
    }

    if (POUCH_ENABLE) lid_pouch_reinforcement_ring();
    lid_stiffener_ribs();
    if (POUCH_ENABLE) lid_pouch_shell();
  }
}

// -------------------------
// Base
// -------------------------
module base() {
  difference() {
    box(outer_len, outer_wid, outer_hgt - lid_th);

    translate([wall, wall, floor_th])
      box(internal_len, internal_wid, internal_hgt_local);

    if (MIRROR_PORT_FACE) {
      translate([outer_len, 0, 0]) mirror([1,0,0]) {
        usb_eth_window_plusY();
        usbc_slit_and_holes_plusY();
      }
    } else {
      usb_eth_window_plusY();
      usbc_slit_and_holes_plusY();
    }

    button_openings_minusY();
    vents_on_side_walls();
  }

  pi_origin_x_raw =
    port_center_x()
    - pi_usbeth_center_from_left
    + pi_port_fine_x;

  pi_origin_x_min = wall + pi_side_margin;
  pi_origin_x_max = outer_len - wall - pi_len - pi_side_margin;
  pi_origin_x = clamp(pi_origin_x_raw, pi_origin_x_min, pi_origin_x_max);

  pi_origin_y = wall + (internal_wid - pi_wid)/2 + pi_bias_to_plusY;

  y_inner_ports_wall = outer_wid - wall;
  y_row_near_ports = pi_origin_y + pi_hole_off + pi_hole_dy;
  echo("Y gap (inside wall -> near Pi hole row) = ", y_inner_ports_wall - y_row_near_ports, "mm");

  standoff(pi_origin_x + pi_hole_off,              pi_origin_y + pi_hole_off);
  standoff(pi_origin_x + pi_hole_off + pi_hole_dx, pi_origin_y + pi_hole_off);
  standoff(pi_origin_x + pi_hole_off,              pi_origin_y + pi_hole_off + pi_hole_dy);
  standoff(pi_origin_x + pi_hole_off + pi_hole_dx, pi_origin_y + pi_hole_off + pi_hole_dy);

  table_posts();

  // NEW: center catch-support post (no screw, no hole) under the + intersection
  if (CENTER_CATCH_ENABLE) {
    cx = outer_len/2;
    cy = outer_wid/2 + spk_offset_y;

    h_catch = max(0, table_post_h - ( (CENTER_PAD_ENABLE ? center_pad_th : 0) + center_catch_gap ));
    echo("center_catch: gap=", center_catch_gap, " h_catch=", h_catch, " at (", cx, ",", cy, ")");

    translate([cx, cy, table_post_z0])
      cylinder(h=h_catch, d=table_post_od);
  }
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
} else if (SHOW == 4) {
  speakers_visual();
} else if (SHOW == 5) {
  base();
  table_plate();
}

