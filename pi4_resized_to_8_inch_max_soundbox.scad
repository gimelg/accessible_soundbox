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
  	// 6=Table + speaker placeholders only
  	// 7=Full assembly: base + table + speakers + lid CLOSED
	*/

$fn = 48;

SHOW = 3;
MIRROR_PORT_FACE = true;

// Rotate lid + table (and speaker visual) 180° around Z relative to the base.
ROTATE_LID_AND_TABLE = true;

inch = 25.4;

// -------------------------
// “Stand on ports side” option
// -------------------------
// 0 = current behavior (USB-C on +Y wall; no speaker L supports)
// 1 = standing-use option (USB-C moved to adjacent +X wall; add speaker supports for standing)
STAND_MODE = 1;

// Adjacent wall choice when STAND_MODE=1
// (Implemented as +X.)
USBC_ON_ADJACENT_X_WALL = true;

// Speaker support wall geometry (table features that touch speaker body)
SPK_LSUP_ENABLE = true;
SPK_LSUP_CLEAR  = 0.6;   // clearance from speaker body
SPK_LSUP_T      = 2.0;   // thickness of support wall
SPK_LSUP_H      = 8.0;   // height above table plate
SPK_LSUP_PAD_INSET = 5.0; // place wall 5mm in from pad edge (your request)

// -------------------------
// General print params
// -------------------------
wall      = 2.4;
floor_th  = 2.4;
lid_th    = 2.0;
clearance = 0.6;

// Reduced to ensure features fit within 8" outer_len
edge_margin_x = 7.0;

min_gap_between_openings = 40.0;

// -------------------------
// Raspberry Pi 4 mounting
// -------------------------
pi_len      = 85.0;
pi_wid      = 56.0;
pi_hole_off = 3.5;

// Your measured correction:
// X spacing 9mm narrower, Y spacing 9mm longer
pi_hole_dx  = 49.0;
pi_hole_dy  = 58.0;

standoff_od = 6.5;
standoff_h  = 15.0;   // Pi "legs" higher (was 7.0 originally)
standoff_id = 2.9;

// Pi placement
pi_bias_to_plusY = 33.0;
pi_usbeth_center_from_left = 31.0;
pi_port_fine_x = 0.0;
pi_side_margin = 2.0;

// Blind pilot depth (from top down)
standoff_pilot_depth = 9.0;

// -------------------------
// Height & width controls
// -------------------------
internal_hgt = 110;
internal_wid_default = 2 * (pi_wid + 2*14);

// -------------------------
// Button openings on -Y wall
// -------------------------
button_open_h = 1.5 * inch; // kept for Z placement intent
button_hole_d = 25.5;       // hole diameter unchanged

// Uneven button “allocation lengths” for spacing only
button_len_L = 50.0;
button_len_M = 55.0;
button_len_R = 50.0;

button_open_z = (internal_hgt + floor_th - button_open_h) / 2;

// -------------------------
// Speakers (adhesive-mounted)
// -------------------------
spk_w = 46.0;
spk_d = 46.0;
spk_h = 28.0;

spk_open_w = spk_w + 1.0;
spk_open_d = spk_d + 1.0;

spk_offset_x = 61;
spk_offset_y = 28;

// -------------------------
// Enclosure sizing (FIXED outer length to fit printer)
// -------------------------
internal_hgt_local = internal_hgt;
internal_wid = internal_wid_default;

// Hard cap to 8 inches
outer_len = 8 * inch;               // 203.2 mm fixed
internal_len = outer_len - 2*wall;

outer_wid = internal_wid + 2*wall;
outer_hgt = internal_hgt_local + floor_th + lid_th;

underside_of_lid_z = outer_hgt - lid_th;

// -------------------------
// Ports on +Y wall
// -------------------------
usbeth_win_len_x = 52;
usbeth_win_h_z   = 16;

// IMPORTANT: keep opening height as in your original pasted file
usbeth_win_z     = floor_th + 15.0;  // FIXED opening height (decoupled from standoff_h)

PANEL_MOUNT_Z = floor_th + 14.0;     // USB-C slit height (original)
ports_right_margin = 27.0;

// CUT-ONLY shift for USB/Eth opening (moves only the cutout)
usbeth_move_to_nearest_edge_mm = 2.0;

// -------------------------
// USB-C slit + screw holes
// -------------------------
USBC_SLIT_W = 9.0;
USBC_SLIT_H = 4.2;

USBC_SCREW_C2C = 17.0; // center-to-center gap
USBC_SCREW_D   = 2.8;  // diameter only, position unchanged

// Explicit placement: center is exactly this far from the chosen outside edge
usbc_center_from_edge = 35.0; // mm

// -------------------------
// Local wall thinning behind USB-C region (<= USBC_LOCAL_WALL_MAX)
// -------------------------
USBC_LOCAL_WALL_MAX = 0.9; // THINNER (was 1.2)
USBC_LOCAL_THIN_MARGIN_X = 8.0;
USBC_LOCAL_THIN_MARGIN_Z = 8.0;

// Placement constraints for USB-C
usbc_edge_margin_x = 5.0;   // absolute minimum allowed (safety clamp)
usbc_post_clear_x  = 2.0;   // clearance beyond table post radius

// -------------------------
// USB-C internal gussets (inside wall ribs above/below slit)
// -------------------------
USBC_GUSSET_ENABLE = true;

// How far the rib protrudes inward from the inside face of the wall
usbc_gusset_in_y = 3.0;

// Rib thickness (Z) and clearance from the slit
usbc_gusset_h_z   = 2.0;
usbc_gusset_gap_z = 2.5;

// Rib span in X/Y around USB-C (adds on both sides of the max span)
usbc_gusset_pad_x = 7.0;

// -------------------------
// Removable table (service deck) w/ M2.5 screws
// -------------------------
table_th         = 2.4;
table_margin     = 6.0;
table_post_inset = 10.0;

m25_clear_d   = 2.8;
m25_pilot_d   = 2.2;
table_post_od = 8.0;

// Blind pilot depth for table posts (from top down)
table_post_pilot_depth = 8.0;

// -------------------------
// Lightweight table plate
// -------------------------
TABLE_LITE_ENABLE = true;

table_frame_w  = 6.0;
table_rib_w    = 6.0;
table_boss_pad = 14.0;

spk_pad_margin = 5.0;

// Speakers flush with TOP of lid:
table_top_z        = outer_hgt - spk_h;
table_plate_z0     = table_top_z - table_th;

table_post_z0 = floor_th;
table_post_h  = table_plate_z0 - table_post_z0;

// -------------------------
// Catch-support posts under speaker pads (base) + matching pads (table)
// -------------------------
CENTER_CATCH_ENABLE = true;
center_catch_gap = 0.5;

// These are the small DOWNWARD table pads that land on the catch posts
CENTER_PAD_ENABLE = true;
center_pad_size   = 18.0;
center_pad_th     = 1.6;

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
// LID “POUCH” (printed as one piece with lid)
// -------------------------
POUCH_ENABLE = true;
POUCH_ROTATE_90 = true;

// INSIDE clear-space dimensions:
pouch_open_len_y = 57.0;   // inside length
pouch_open_wid_x = 16.0;   // inside width
pouch_depth      = 20.0;   // inside depth (down from lid underside)

pouch_wall  = 2.0;

pouch_len_y = pouch_open_len_y + 2*pouch_wall;
pouch_wid_x = pouch_open_wid_x + 2*pouch_wall;

// Shape controls
pouch_round = 5.0;

// No “boat” taper: bottom same as top
pouch_taper = 1.00;

// Placement clamp
pouch_edge_clear = wall + 3.0;

function pouch_extent_x() = POUCH_ROTATE_90 ? pouch_len_y : pouch_wid_x;
function pouch_extent_y() = POUCH_ROTATE_90 ? pouch_wid_x : pouch_len_y;

function pouch_half_x() = pouch_extent_x()/2;
function pouch_half_y() = pouch_extent_y()/2;

// Pouch sides fully open
POUCH_OPEN_SIDES_ENABLE = true;
pouch_open_sides_extra  = 2.0;

// -------------------------
// Lid reinforcements
// -------------------------
LID_REINF_ENABLE = true;

lid_ring_radial = 1.4;
lid_ring_th     = 1.0;

lid_rib_enable = true;
lid_rib_h      = 1.6;
lid_rib_wy     = 7.0;
lid_rib_edge_x = 8.0;
lid_rib_edge_y = 8.0;
lid_rib_gap_from_features = 6.0;

lid_mid_rib_enable = true;
lid_mid_rib_clear  = 2.0;

// Add back stiffness (side rails under lid)
LID_SIDE_RAILS_ENABLE = true;
lid_side_rail_h   = 1.6;
lid_side_rail_wx  = 7.0;
lid_side_rail_inset_x = 10.0;
lid_side_rail_gap_from_pouch = 4.0;

// -------------------------
// Lid fastening (quarter-circle corner bosses + inward hole centers)
// -------------------------
LID_SCREWS_ENABLE   = true;

lid_corner_boss_r   = 7.0;
lid_boss_pilot_d    = 2.2;
lid_screw_clear_d   = 2.9;

lid_boss_top_clear  = 0.4;
lid_boss_z0         = floor_th;

lid_hole_inset_from_corner = 3.0;
lid_boss_pilot_depth = 8.0;

table_corner_clear_radial = 0.8;
table_corner_clear_r = lid_corner_boss_r + table_corner_clear_radial;

// -------------------------
// Helpers / primitives
// -------------------------
module box(x,y,z) { cube([x,y,z], center=false); }

function clamp(v, lo, hi) = v < lo ? lo : (v > hi ? hi : v);

module rounded_rect2d(L, W, R) {
  rr = clamp(R, 0.1, min(W/2 - 0.1, L/2 - 0.1));
  hull() {
    for (sx = [-1, +1])
      for (sy = [-1, +1])
        translate([sx*(L/2 - rr), sy*(W/2 - rr)]) circle(r=rr);
  }
}

module rotate_about_center_z(do_it=true) {
  if (do_it) {
    translate([outer_len/2, outer_wid/2, 0])
      rotate([0,0,180])
        translate([-outer_len/2, -outer_wid/2, 0])
          children();
  } else {
    children();
  }
}

// ADJUSTMENT:
// - lower the Pi standoffs by 1mm (start 1mm closer to the floor)
module standoff(x,y) {
  pilot_d = min(standoff_pilot_depth, max(0.2, standoff_h - 1.0));
  translate([x,y,floor_th - 1.0])
    difference() {
      cylinder(h=standoff_h, d=standoff_od);
      translate([0,0,standoff_h - pilot_d])
        cylinder(h=pilot_d + 0.2, d=standoff_id);
    }
}

module post_m25(x,y) {
  pilot_d = min(table_post_pilot_depth, max(0.2, table_post_h - 2.0));
  translate([x,y,table_post_z0])
    difference() {
      cylinder(h=table_post_h, d=table_post_od);
      translate([0,0,table_post_h - pilot_d])
        cylinder(h=pilot_d + 0.2, d=m25_pilot_d);
    }
}

// -------------------------
// Table helper functions
// -------------------------
function table_x0() = wall + table_margin;
function table_y0() = wall + table_margin;
function table_x1() = outer_len - wall - table_margin;
function table_y1() = outer_wid - wall - table_margin;

function post_x0() = wall + table_post_inset;
function post_x1() = outer_len - wall - table_post_inset;
function post_y0() = wall + table_post_inset;
function post_y1() = outer_wid - wall - table_post_inset;

// -------------------------
// USB/Eth window placement (MODEL coords)
// -------------------------
usbeth_x0_min = edge_margin_x;
usbeth_x0_max = outer_len - edge_margin_x - usbeth_win_len_x;

usbeth_x0_desired = outer_len - edge_margin_x - ports_right_margin - usbeth_win_len_x;

// Reference placement (used for Pi alignment + USB-C “opposite side” logic)
usbeth_x0_ref = clamp(usbeth_x0_desired, usbeth_x0_min, usbeth_x0_max);

// Convert between MODEL and RENDERED X for consistency
function xr_to_model(xr) = MIRROR_PORT_FACE ? (outer_len - xr) : xr;
function x_model_to_rendered(xm) = MIRROR_PORT_FACE ? (outer_len - xm) : xm;

// Rendered x0 for +Y port-face reasoning (what you see from outside), for REF placement
function port_window_x0_ref() =
  MIRROR_PORT_FACE
    ? (outer_len - (usbeth_x0_ref + usbeth_win_len_x))
    : (usbeth_x0_ref);

function port_window_x1_ref() = port_window_x0_ref() + usbeth_win_len_x;
function port_center_x_ref()  = port_window_x0_ref() + usbeth_win_len_x/2;

// Compute a CUT-ONLY x0 that moves toward the nearest outside edge (rendered coords)
usbeth_x0_min_r = usbeth_x0_min;
usbeth_x0_max_r = usbeth_x0_max;

usbeth_x0_r_ref = port_window_x0_ref();
usbeth_center_r_ref = port_center_x_ref();

usbeth_shift_r =
  (usbeth_center_r_ref > outer_len/2) ? (+usbeth_move_to_nearest_edge_mm) : (-usbeth_move_to_nearest_edge_mm);

usbeth_x0_r_cut = clamp(usbeth_x0_r_ref + usbeth_shift_r, usbeth_x0_min_r, usbeth_x0_max_r);

// Convert rendered CUT x0 back to MODEL x0 for the actual subtraction geometry
function usbeth_x0r_to_model(x0r) =
  MIRROR_PORT_FACE ? (outer_len - (x0r + usbeth_win_len_x)) : x0r;

usbeth_x0_cut = usbeth_x0r_to_model(usbeth_x0_r_cut);

// -------------------------
// USB-C wall selection
// -------------------------
USBC_WALL_SEL = (STAND_MODE == 1 && USBC_ON_ADJACENT_X_WALL) ? "X" : "Y";

// -------------------------
// USB-C placement (for +Y wall) — existing logic retained
// -------------------------
usbc_half_span_x = max(USBC_SLIT_W/2, USBC_SCREW_C2C/2 + USBC_SCREW_D/2);

usbc_x_center_min_r = usbc_edge_margin_x + usbc_half_span_x;
usbc_x_center_max_r = outer_len - usbc_edge_margin_x - usbc_half_span_x;

// Opposite side from USB/Eth window in rendered view (based on REF placement)
place_usbc_left = (port_center_x_ref() > outer_len/2);

// Enforce separation from USB/Eth window (rendered, REF placement)
function enforce_sep(xc_r) =
  place_usbc_left
    ? min(xc_r, port_window_x0_ref() - min_gap_between_openings - usbc_half_span_x)
    : max(xc_r, port_window_x1_ref() + min_gap_between_openings + usbc_half_span_x);

// Use RENDERED X positions for the table posts so we’re consistent with hole positions
post_x0_r = x_model_to_rendered(post_x0());
post_x1_r = x_model_to_rendered(post_x1());

// Keepout band around each post, in X
post_r = table_post_od/2;
need = post_r + usbc_post_clear_x;

function forbL_a(px) = px - need + USBC_SCREW_C2C/2;
function forbL_b(px) = px + need + USBC_SCREW_C2C/2;

function forbR_a(px) = px - need - USBC_SCREW_C2C/2;
function forbR_b(px) = px + need + USBC_SCREW_C2C/2;

function shift_out(x, a, b, dir) =
  (x < a || x > b) ? x :
    (dir < 0 ? (a - 0.01) : (b + 0.01));

function clear_one_post(x, px, dir) =
  shift_out( shift_out(x, forbL_a(px), forbL_b(px), dir),
             forbR_a(px), forbR_b(px), dir);

function clear_all_posts(x0, dir) =
  let(
    x1 = clear_one_post(x0, post_x0_r, dir),
    x2 = clear_one_post(x1, post_x1_r, dir),
    x3 = clear_one_post(x2, post_x0_r, dir),
    x4 = clear_one_post(x3, post_x1_r, dir)
  ) x4;

// Preferred direction when escaping a post keepout: toward the middle
dir_pref = place_usbc_left ? +1 : -1;

// Explicit target: center is fixed distance from the chosen OUTSIDE edge (rendered view)
usbc_target_r =
  place_usbc_left ? usbc_center_from_edge : (outer_len - usbc_center_from_edge);

usbc_x_center_r =
  clamp(
    enforce_sep(
      clamp(
        clear_all_posts(
          clamp(enforce_sep(usbc_target_r), usbc_x_center_min_r, usbc_x_center_max_r),
          dir_pref
        ),
        usbc_x_center_min_r, usbc_x_center_max_r
      )
    ),
    usbc_x_center_min_r, usbc_x_center_max_r
  );

usbc_x_center = xr_to_model(usbc_x_center_r);

// -------------------------
// USB-C placement on +X wall
// Change requested: “closer to the OTHER corner of the wall”
// Implemented as: measure from the opposite Y edge (near outer_wid), not from 0.
// -------------------------
usbc_y_half_span = usbc_half_span_x;

usbc_y_center_min = usbc_edge_margin_x + usbc_y_half_span;
usbc_y_center_max = outer_wid - usbc_edge_margin_x - usbc_y_half_span;

// opposite edge targeting (closer to other corner)
usbc_y_center = clamp(outer_wid - usbc_center_from_edge, usbc_y_center_min, usbc_y_center_max);

// Diagnostics
echo("outer_len=", outer_len, " outer_wid=", outer_wid, " outer_hgt=", outer_hgt);
echo("USB/Eth REF rendered x0=", port_window_x0_ref(), " x1=", port_window_x1_ref(), " center=", port_center_x_ref());
echo("USB/Eth CUT rendered x0=", usbeth_x0_r_cut, " (shift_r=", usbeth_shift_r, ")");
echo("USB-C wall=", USBC_WALL_SEL, " opposite side (left?)=", place_usbc_left,
     " rendered centerX=", usbc_x_center_r, " model centerX=", usbc_x_center,
     " centerY(for +X wall)=", usbc_y_center);

// -------------------------
// Cutouts on +Y wall
// -------------------------
module usb_eth_window_plusY() {
  // CUT-ONLY placement: usbeth_x0_cut (everything else references REF placement)
  translate([usbeth_x0_cut, outer_wid - (wall + 2.0), usbeth_win_z])
    box(usbeth_win_len_x, (wall + 2.0) + 2.0, usbeth_win_h_z);
}

// -------------------------
// USB-C slit + screw holes (generalized wall selection)
// -------------------------
module usbc_slit_and_holes_on_wall(wall_sel="Y") {
  cut_depth = wall + 2.0;

  hole_z = PANEL_MOUNT_Z + USBC_SLIT_H/2;

  if (wall_sel == "Y") {
    // +Y wall
    translate([usbc_x_center - USBC_SLIT_W/2,
               outer_wid - cut_depth,
               PANEL_MOUNT_Z])
      box(USBC_SLIT_W, cut_depth + 2.0, USBC_SLIT_H);

    for (sx = [-USBC_SCREW_C2C/2, +USBC_SCREW_C2C/2]) {
      translate([usbc_x_center + sx, outer_wid - wall/2, hole_z])
        rotate([90,0,0])
          cylinder(h=cut_depth + 6.0, d=USBC_SCREW_D, center=true);
    }
  } else if (wall_sel == "X") {
    // +X wall
    translate([outer_len - cut_depth,
               usbc_y_center - USBC_SLIT_W/2,
               PANEL_MOUNT_Z])
      box(cut_depth + 2.0, USBC_SLIT_W, USBC_SLIT_H);

    for (sy = [-USBC_SCREW_C2C/2, +USBC_SCREW_C2C/2]) {
      translate([outer_len - wall/2, usbc_y_center + sy, hole_z])
        rotate([0,90,0])
          cylinder(h=cut_depth + 6.0, d=USBC_SCREW_D, center=true);
    }
  }
}

// Local inside pocket to thin the selected wall behind USB-C region (<=USBC_LOCAL_WALL_MAX)
module usbc_local_wall_thin_pocket_on_wall(wall_sel="Y") {
  remove_t = wall - USBC_LOCAL_WALL_MAX;
  if (remove_t > 0) {
    pad_x = usbc_half_span_x + USBC_LOCAL_THIN_MARGIN_X;

    z0 = PANEL_MOUNT_Z - USBC_LOCAL_THIN_MARGIN_Z;
    z1 = PANEL_MOUNT_Z + USBC_SLIT_H + USBC_LOCAL_THIN_MARGIN_Z;

    if (wall_sel == "Y") {
      x0 = usbc_x_center - pad_x;
      x1 = usbc_x_center + pad_x;

      translate([x0, outer_wid - wall - remove_t, z0])
        box(x1 - x0, remove_t + 0.2, z1 - z0);
    } else if (wall_sel == "X") {
      y0 = usbc_y_center - pad_x;
      y1 = usbc_y_center + pad_x;

      translate([outer_len - wall - remove_t, y0, z0])
        box(remove_t + 0.2, y1 - y0, z1 - z0);
    }
  }
}

// USB-C internal gussets: ribs ABOVE and BELOW the slit on the INSIDE of the selected wall.
module usbc_internal_gussets_on_wall(wall_sel="Y") {
  if (USBC_GUSSET_ENABLE) {
    span = 2*(usbc_half_span_x + usbc_gusset_pad_x);

    z_below = PANEL_MOUNT_Z - usbc_gusset_gap_z - usbc_gusset_h_z;
    z_above = PANEL_MOUNT_Z + USBC_SLIT_H + usbc_gusset_gap_z;

    z_below_c = clamp(z_below, 0.2, underside_of_lid_z - usbc_gusset_h_z - 0.2);
    z_above_c = clamp(z_above, 0.2, underside_of_lid_z - usbc_gusset_h_z - 0.2);

    if (wall_sel == "Y") {
      x0 = usbc_x_center - span/2;
      y0 = outer_wid - wall - usbc_gusset_in_y;

      if (z_below_c + usbc_gusset_h_z <= PANEL_MOUNT_Z - 0.2)
        translate([x0, y0, z_below_c]) box(span, usbc_gusset_in_y, usbc_gusset_h_z);

      if (z_above_c >= PANEL_MOUNT_Z + USBC_SLIT_H + 0.2)
        translate([x0, y0, z_above_c]) box(span, usbc_gusset_in_y, usbc_gusset_h_z);
    } else if (wall_sel == "X") {
      x0 = outer_len - wall - usbc_gusset_in_y;
      y0 = usbc_y_center - span/2;

      if (z_below_c + usbc_gusset_h_z <= PANEL_MOUNT_Z - 0.2)
        translate([x0, y0, z_below_c]) box(usbc_gusset_in_y, span, usbc_gusset_h_z);

      if (z_above_c >= PANEL_MOUNT_Z + USBC_SLIT_H + 0.2)
        translate([x0, y0, z_above_c]) box(usbc_gusset_in_y, span, usbc_gusset_h_z);
    }
  }
}

// -------------------------
// Button openings on -Y wall (3x Ø26mm)
// -------------------------
module button_openings_minusY() {
  eps = 0.8;
  cut_h = wall + eps;
  y_center = wall / 2;

  wL = button_len_L;
  wM = button_len_M;
  wR = button_len_R;

  avail = outer_len - 2*edge_margin_x;
  gap = (avail - (wL + wM + wR)) / 4;
  gap_safe = max(0, gap);

  x0 = edge_margin_x + gap_safe;

  xC1 = x0 + wL/2;
  xC2 = x0 + wL + gap_safe + wM/2;
  xC3 = x0 + wL + gap_safe + wM + gap_safe + wR/2;

  z_center = button_open_z + button_open_h/2;

  for (xc = [xC1, xC2, xC3]) {
    translate([xc, y_center, z_center])
      rotate([90,0,0])
        cylinder(h=cut_h, d=button_hole_d, center=true);
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
// Lid fastening geometry
// -------------------------
function screw_x_left()  = wall + lid_hole_inset_from_corner;
function screw_x_right() = outer_len - wall - lid_hole_inset_from_corner;
function screw_y_front() = wall + lid_hole_inset_from_corner;
function screw_y_back()  = outer_wid - wall - lid_hole_inset_from_corner;

module corner_quarter_boss(corner_x, corner_y, hole_x, hole_y) {
  boss_h = (outer_hgt - lid_th) - lid_boss_z0 - lid_boss_top_clear;
  pilot_d = min(lid_boss_pilot_depth, max(0.2, boss_h - 2.0));

  translate([0,0,lid_boss_z0])
    difference() {
      intersection() {
        translate([corner_x, corner_y, 0])
          cylinder(h=boss_h, r=lid_corner_boss_r);

        translate([wall, wall, 0])
          cube([outer_len - 2*wall, outer_wid - 2*wall, boss_h], center=false);
      }

      translate([hole_x, hole_y, boss_h - pilot_d])
        cylinder(h=pilot_d + 0.4, d=lid_boss_pilot_d);
    }
}

module lid_corner_bosses_quarter() {
  if (LID_SCREWS_ENABLE) {
    corner_quarter_boss(wall,             wall,             screw_x_left(),  screw_y_front());
    corner_quarter_boss(outer_len - wall, wall,             screw_x_right(), screw_y_front());
    corner_quarter_boss(wall,             outer_wid - wall,  screw_x_left(),  screw_y_back());
    corner_quarter_boss(outer_len - wall, outer_wid - wall,  screw_x_right(), screw_y_back());
  }
}

module lid_screw_holes() {
  if (LID_SCREWS_ENABLE) {
    for (x = [screw_x_left(), screw_x_right()])
      for (y = [screw_y_front(), screw_y_back()])
        translate([x, y, outer_hgt - lid_th - 0.2])
          cylinder(h=lid_th + 0.4, d=lid_screw_clear_d);
  }
}

// -------------------------
// Pouch placement + modules
// -------------------------
pouch_cx = clamp(outer_len/2,
                 pouch_edge_clear + pouch_half_x(),
                 outer_len - pouch_edge_clear - pouch_half_x());

pouch_cy_base = wall + 18.0;
pouch_cy_shift_to_mid = 10.0;
pouch_cy_desired = pouch_cy_base + pouch_cy_shift_to_mid;

pouch_cy = clamp(pouch_cy_desired,
                 pouch_edge_clear + pouch_half_y(),
                 outer_wid - pouch_edge_clear - pouch_half_y());

// Bottom support beams
pouch_retain_enable = true;
pouch_retain_th = 1.6;
pouch_retain_w  = 2.2;
pouch_retain_overlap = 0.8;

// Two beams instead of one
pouch_retain_two_beams = true;
pouch_retain_beam_spacing = 14.0;

// Remove both ±X side walls entirely (pouch-local coords)
module pouch_open_sides_local() {
  edge_x = pouch_extent_x()/2;

  cut_x = pouch_wall + 2*pouch_open_sides_extra;
  cut_y = pouch_extent_y() + 2*pouch_open_sides_extra;
  cut_z = pouch_depth + 2*pouch_open_sides_extra;

  for (s = [-1, +1]) {
    xc_wall_center = s * (edge_x - pouch_wall/2);
    translate([xc_wall_center, 0, pouch_depth/2])
      cube([cut_x, cut_y, cut_z], center=true);
  }
}

module lid_pouch_opening_cut() {
  Lc = pouch_open_len_y;
  Wc = pouch_open_wid_x;
  Rc = clamp(pouch_round, 0.1, min(Wc/2 - 0.1, Lc/2 - 0.1));
  rot2d = POUCH_ROTATE_90 ? 0 : 90;

  translate([pouch_cx, pouch_cy, outer_hgt - lid_th - 0.2])
    linear_extrude(height=lid_th + 0.4, convexity=10)
      rotate(rot2d) rounded_rect2d(Lc, Wc, Rc);
}

module lid_pouch_reinforcement_ring() {
  if (LID_REINF_ENABLE && lid_ring_th > 0 && lid_ring_radial > 0) {
    z_und = outer_hgt - lid_th;

    Lc = pouch_open_len_y;
    Wc = pouch_open_wid_x;
    Rc = clamp(pouch_round, 0.1, min(Wc/2 - 0.1, Lc/2 - 0.1));

    Lout = Lc + 2*lid_ring_radial;
    Wout = Wc + 2*lid_ring_radial;
    Rout = Rc + lid_ring_radial;

    rot2d = POUCH_ROTATE_90 ? 0 : 90;

    translate([pouch_cx, pouch_cy, z_und - lid_ring_th])
      difference() {
        linear_extrude(height=lid_ring_th, convexity=10)
          rotate(rot2d) rounded_rect2d(Lout, Wout, Rout);

        translate([0,0,-0.2])
          linear_extrude(height=lid_ring_th + 0.4, convexity=10)
            rotate(rot2d) rounded_rect2d(Lc, Wc, Rc);
      }
  }
}

module lid_pouch_shell() {
  z_lid_underside = outer_hgt - lid_th;

  L0 = pouch_len_y;
  W0 = pouch_wid_x;
  R0 = pouch_round + pouch_wall;

  Li0 = pouch_open_len_y;
  Wi0 = pouch_open_wid_x;
  Ri0 = pouch_round;

  rot2d = POUCH_ROTATE_90 ? 0 : 90;

  // no taper
  L1  = L0;
  Li1 = Li0;

  translate([pouch_cx, pouch_cy, z_lid_underside]) {
    mirror([0,0,1]) {
      difference() {
        hull() {
          linear_extrude(height=0.2, convexity=10)
            rotate(rot2d) rounded_rect2d(L0, W0, R0);

          translate([0,0,pouch_depth - 0.2])
            linear_extrude(height=0.2, convexity=10)
              rotate(rot2d) rounded_rect2d(L1, W0, R0);
        }

        translate([0,0,-0.2])
          hull() {
            linear_extrude(height=0.6, convexity=10)
              rotate(rot2d) rounded_rect2d(Li0, Wi0, Ri0);

            translate([0,0,pouch_depth - 0.2])
              linear_extrude(height=0.6, convexity=10)
                rotate(rot2d) rounded_rect2d(Li1, Wi0, Ri0);
          }

        if (POUCH_OPEN_SIDES_ENABLE) pouch_open_sides_local();
      }
    }
  }

  // Bottom support beams (under the pouch)
  if (pouch_retain_enable) {
    z_bottom = z_lid_underside - pouch_depth;

    inner_bot_w = pouch_open_wid_x;
    overlap = pouch_retain_overlap;
    rib_len = max(0.2, inner_bot_w + overlap);

    if (POUCH_ROTATE_90) {
      if (pouch_retain_two_beams) {
        dx = pouch_retain_beam_spacing / 2;
        for (xo = [-dx, +dx]) {
          translate([pouch_cx + xo - pouch_retain_w/2,
                     pouch_cy - rib_len/2,
                     z_bottom])
            box(pouch_retain_w, rib_len, pouch_retain_th);
        }
      } else {
        translate([pouch_cx - pouch_retain_w/2,
                   pouch_cy - rib_len/2,
                   z_bottom])
          box(pouch_retain_w, rib_len, pouch_retain_th);
      }
    } else {
      if (pouch_retain_two_beams) {
        dy = pouch_retain_beam_spacing / 2;
        for (yo = [-dy, +dy]) {
          translate([pouch_cx - rib_len/2,
                     pouch_cy + yo - pouch_retain_w/2,
                     z_bottom])
            box(rib_len, pouch_retain_w, pouch_retain_th);
        }
      } else {
        translate([pouch_cx - rib_len/2,
                   pouch_cy - pouch_retain_w/2,
                   z_bottom])
          box(rib_len, pouch_retain_w, pouch_retain_th);
      }
    }
  }
}

// -------------------------
// Lid stiffener ribs (minimal)
// -------------------------
function nudge_away_from_band(yc, band0, band1, halfw, nudge) =
  (yc > band0 - halfw && yc < band1 + halfw)
    ? ((yc < (band0+band1)/2) ? (band0 - halfw - nudge) : (band1 + halfw + nudge))
    : yc;

module lid_rib_block(x0, x1, yc, wy, z_und, h) {
  translate([x0, yc - wy/2, z_und - h]) box(x1 - x0, wy, h);
}

module lid_stiffener_ribs() {
  if (LID_REINF_ENABLE && lid_rib_enable && lid_rib_h > 0 && lid_rib_wy > 0) {
    z_und = outer_hgt - lid_th;

    cx = outer_len/2;
    cy = outer_wid/2 + spk_offset_y;

    spk_y0 = cy - spk_open_d/2;
    spk_y1 = spk_y0 + spk_open_d;

    rib_x0 = lid_rib_edge_x;
    rib_x1 = outer_len - lid_rib_edge_x;

    rib_yc_min = lid_rib_edge_y + lid_rib_wy/2;
    rib_yc_max = outer_wid - lid_rib_edge_y - lid_rib_wy/2;

    boat_keep_y0 = pouch_cy - pouch_extent_y()/2 - lid_rib_gap_from_features - lid_rib_wy/2;
    boat_keep_y1 = pouch_cy + pouch_extent_y()/2 + lid_rib_gap_from_features + lid_rib_wy/2;

    low_zone_max = boat_keep_y0 - 1.0;

    rib1_ok = (low_zone_max > rib_yc_min);
    rib1_yc_base = rib1_ok ? clamp((rib_yc_min + low_zone_max)/2, rib_yc_min, low_zone_max) : 0;

    rib1_yc_final =
      rib1_ok
        ? clamp(nudge_away_from_band(rib1_yc_base, spk_y0, spk_y1, lid_rib_wy/2, 1.0), rib_yc_min, low_zone_max)
        : 0;

    top_band_y0 = spk_y1 + lid_rib_gap_from_features + lid_rib_wy/2;
    top_band_y1 = rib_yc_max;

    rib2_ok = (top_band_y1 > top_band_y0);
    rib2_yc_final = rib2_ok ? (top_band_y0 + top_band_y1)/2 : 0;

    if (rib1_ok) lid_rib_block(rib_x0, rib_x1, rib1_yc_final, lid_rib_wy, z_und, lid_rib_h);
    if (rib2_ok) lid_rib_block(rib_x0, rib_x1, rib2_yc_final, lid_rib_wy, z_und, lid_rib_h);
  }
}

module lid_side_rails() {
  if (LID_SIDE_RAILS_ENABLE && lid_side_rail_h > 0 && lid_rib_wy > 0) {

    z_und = outer_hgt - lid_th;

    x0 = lid_rib_edge_x;
    x1 = outer_len - lid_rib_edge_x;

    cx = outer_len/2;
    cy = outer_wid/2 + spk_offset_y;
    spk_y0 = cy - spk_open_d/2;
    spk_y1 = spk_y0 + spk_open_d;

    keep0 = pouch_cy - pouch_extent_y()/2;
    keep1 = pouch_cy + pouch_extent_y()/2;

    yA = keep0 - lid_side_rail_gap_from_pouch - lid_rib_wy/2;
    yB = keep1 + lid_side_rail_gap_from_pouch + lid_rib_wy/2;

    y_min = lid_rib_edge_y + lid_rib_wy/2;
    y_max = outer_wid - lid_rib_edge_y - lid_rib_wy/2;

    yA2 = clamp(nudge_away_from_band(yA, spk_y0, spk_y1, lid_rib_wy/2, 1.0), y_min, y_max);
    yB2 = clamp(nudge_away_from_band(yB, spk_y0, spk_y1, lid_rib_wy/2, 1.0), y_min, y_max);

    if (yA2 >= y_min && yA2 <= y_max) {
      translate([x0, yA2 - lid_rib_wy/2, z_und - lid_side_rail_h])
        box(x1 - x0, lid_rib_wy, lid_side_rail_h);
    }
    if (yB2 >= y_min && yB2 <= y_max) {
      translate([x0, yB2 - lid_rib_wy/2, z_und - lid_side_rail_h])
        box(x1 - x0, lid_rib_wy, lid_side_rail_h);
    }
  }
}

// -------------------------
// Table geometry
// -------------------------
module table_corner_clearance_cutouts() {
  if (LID_SCREWS_ENABLE && table_corner_clear_r > 0) {
    zc = table_plate_z0 - 0.2;
    hh = table_th + 0.4;

    translate([wall,             wall,             zc]) cylinder(h=hh, r=table_corner_clear_r);
    translate([outer_len - wall, wall,             zc]) cylinder(h=hh, r=table_corner_clear_r);
    translate([wall,             outer_wid - wall,  zc]) cylinder(h=hh, r=table_corner_clear_r);
    translate([outer_len - wall, outer_wid - wall,  zc]) cylinder(h=hh, r=table_corner_clear_r);
  }
}

// Speaker support: ONE leg only (X-axis leg).
// - runs along X (long in X), thin in Y
// - placed toward the PORTS wall (your framing)
// - 5mm away from the pad edge
module spk_support_one_leg(x0, y0, w, d) {
  if (SPK_LSUP_ENABLE && SPK_LSUP_H > 0 && SPK_LSUP_T > 0) {

    // Run along X
    x_in = x0 + SPK_LSUP_CLEAR;
    w_in = max(0.2, w - 2*SPK_LSUP_CLEAR);

    // FLIPPED to the opposite Y edge (so it moves away from the button wall
    // and toward the ports wall in your view)
    y_wall = y0 + SPK_LSUP_PAD_INSET;

    translate([x_in, y_wall, table_plate_z0 + table_th])
      box(w_in, SPK_LSUP_T, SPK_LSUP_H);
  }
}

module table_plate() {
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

      // Standing-use support walls
      if (STAND_MODE == 1) {
        spk_support_one_leg(xL, y0, pad_w, pad_d);
        spk_support_one_leg(xR, y0, pad_w, pad_d);
      }

      y_mid = cy;
      translate([post_x0(), y_mid - table_rib_w/2, table_plate_z0])
        box(post_x1()-post_x0(), table_rib_w, table_th);

      x_mid = cx;
      translate([x_mid - table_rib_w/2, post_y0(), table_plate_z0])
        box(table_rib_w, post_y1()-post_y0(), table_th);

      // ------------------------------------------------------------
      // Two table "support pads" under the + intersection region,
      // aligned to the INNER edges of the two speaker pads.
      // ------------------------------------------------------------
      if (CENTER_PAD_ENABLE && center_pad_th > 0 && center_pad_size > 0) {

        post_r = table_post_od/2;

        // Inner edges of pads (facing centerline), inset by post radius
        x_left_inner_support_unrot  = (xL + pad_w) - post_r; // inside right edge of left pad
        x_right_inner_support_unrot = (xR) + post_r;         // inside left edge of right pad

        // Pads extend DOWNWARD from underside of the table plate
        translate([x_left_inner_support_unrot - center_pad_size/2,
                   y_mid - center_pad_size/2,
                   table_plate_z0 - center_pad_th])
          box(center_pad_size, center_pad_size, center_pad_th);

        translate([x_right_inner_support_unrot - center_pad_size/2,
                   y_mid - center_pad_size/2,
                   table_plate_z0 - center_pad_th])
          box(center_pad_size, center_pad_size, center_pad_th);
      }
    }

    for (px = [post_x0(), post_x1()])
      for (py = [post_y0(), post_y1()])
        translate([px, py, table_plate_z0 - 0.2])
          cylinder(h=table_th + 0.4, d=m25_clear_d);

    table_corner_clearance_cutouts();
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
  spk_z0 = table_top_z;

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

      // Pouch opening
      if (POUCH_ENABLE) lid_pouch_opening_cut();
      // Lid screw holes
      lid_screw_holes();
    }

    if (POUCH_ENABLE) lid_pouch_reinforcement_ring();
    lid_stiffener_ribs();
    lid_side_rails();
    if (POUCH_ENABLE) lid_pouch_shell();
  }
}

// -------------------------
// Base (with cutouts + positive features)
// -------------------------
module base() {
  difference() {
    box(outer_len, outer_wid, outer_hgt - lid_th);

    // interior cavity
    translate([wall, wall, floor_th])
      box(internal_len, internal_wid, internal_hgt_local);

    // +Y wall cutouts (USB/Eth always here; mirroring optional)
    if (MIRROR_PORT_FACE) {
      translate([outer_len, 0, 0]) mirror([1,0,0]) {
        usb_eth_window_plusY();

        // USB-C: only mirror when it lives on +Y (port face).
        if (USBC_WALL_SEL == "Y") {
          usbc_slit_and_holes_on_wall("Y");
          usbc_local_wall_thin_pocket_on_wall("Y");
        }
      }
    } else {
      usb_eth_window_plusY();
      if (USBC_WALL_SEL == "Y") {
        usbc_slit_and_holes_on_wall("Y");
        usbc_local_wall_thin_pocket_on_wall("Y");
      }
    }

    // USB-C on adjacent +X wall (do NOT mirror, or it becomes -X)
    if (USBC_WALL_SEL == "X") {
      usbc_slit_and_holes_on_wall("X");
      usbc_local_wall_thin_pocket_on_wall("X");
    }

    // -Y buttons
    button_openings_minusY();

    // vents
    vents_on_side_walls();
  }

  // Add USB-C internal ribs AFTER cutouts so they remain solid.
  // Mirror only when USB-C is on +Y.
  if (USBC_WALL_SEL == "Y") {
    if (MIRROR_PORT_FACE) {
      translate([outer_len, 0, 0]) mirror([1,0,0])
        usbc_internal_gussets_on_wall("Y");
    } else {
      usbc_internal_gussets_on_wall("Y");
    }
  } else if (USBC_WALL_SEL == "X") {
    usbc_internal_gussets_on_wall("X");
  }

  // ---- Pi placement (align cluster center to REF port center) ----
  pi_origin_x_raw =
    port_center_x_ref()
    - pi_usbeth_center_from_left
    + pi_port_fine_x;

  pi_origin_x_min = wall + pi_side_margin;
  pi_origin_x_max = outer_len - wall - pi_len - pi_side_margin;
  pi_origin_x = clamp(pi_origin_x_raw, pi_origin_x_min, pi_origin_x_max);

  // - push all 4 standoffs back 10mm toward the -Y wall (the button wall)
  pi_origin_y = wall + (internal_wid - pi_wid)/2 + pi_bias_to_plusY - 10.0;

  // Pi standoffs: corrected dx/dy rectangle
  standoff(pi_origin_x + pi_hole_off,               pi_origin_y + pi_hole_off);
  standoff(pi_origin_x + pi_hole_off + pi_hole_dx,  pi_origin_y + pi_hole_off);
  standoff(pi_origin_x + pi_hole_off,               pi_origin_y + pi_hole_off + pi_hole_dy);
  standoff(pi_origin_x + pi_hole_off + pi_hole_dx,  pi_origin_y + pi_hole_off + pi_hole_dy);

  table_posts();

  // Lid bosses
  lid_corner_bosses_quarter();

  // ------------------------------------------------------------
  // TWO catch-support posts under the INNER edges of both pads
  // ------------------------------------------------------------
  if (CENTER_CATCH_ENABLE) {

    // Must match table_plate() speaker-pad geometry
    pad_w = spk_w + 2*spk_pad_margin;
    pad_d = spk_d + 2*spk_pad_margin;

    cx = outer_len/2;
    cy_unrot = outer_wid/2 + spk_offset_y;

    // Pad x positions (same as table_plate)
    xL = cx - spk_offset_x - pad_w/2;  // left pad lower-left X
    xR = cx + spk_offset_x - pad_w/2;  // right pad lower-left X

    // Inner edges of pads (facing centerline), inset by post radius so the post lands under the pad
    post_r = table_post_od/2;
    x_left_inner_support_unrot  = (xL + pad_w) - post_r; // inside right edge of left pad
    x_right_inner_support_unrot = (xR) + post_r;         // inside left edge of right pad

    // Apply the same 180° rotation logic as lid/table (transform BOTH X and Y)
    x_left_support  = ROTATE_LID_AND_TABLE ? (outer_len - x_left_inner_support_unrot)   : x_left_inner_support_unrot;
    x_right_support = ROTATE_LID_AND_TABLE ? (outer_len - x_right_inner_support_unrot)  : x_right_inner_support_unrot;
    cy = ROTATE_LID_AND_TABLE ? (outer_wid - cy_unrot) : cy_unrot;

    // Height: keep your existing clearance logic
    h_catch = max(0, table_post_h - ((CENTER_PAD_ENABLE ? center_pad_th : 0) + center_catch_gap));

    translate([x_left_support,  cy, table_post_z0])
      cylinder(h=h_catch, d=table_post_od);

    translate([x_right_support, cy, table_post_z0])
      cylinder(h=h_catch, d=table_post_od);
  }
}

// -------------------------
// Build selector
// -------------------------
if (SHOW == 0) {
  base();
} else if (SHOW == 1) {
  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    lid();
} else if (SHOW == 2) {
  base();

  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    table_plate();

  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    translate([0,0,20]) lid();

  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    speakers_visual();
} else if (SHOW == 3) {
  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    table_plate();
} else if (SHOW == 4) {
  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    speakers_visual();
} else if (SHOW == 5) {
  base();

  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    table_plate();
} else if (SHOW == 6) {
  rotate_about_center_z(ROTATE_LID_AND_TABLE) {
    table_plate();
    speakers_visual();
  }
} else if (SHOW == 7) {
  base();

  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    table_plate();

  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    speakers_visual();

  rotate_about_center_z(ROTATE_LID_AND_TABLE)
    lid();
}

