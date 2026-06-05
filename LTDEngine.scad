
// Customizer Panel Settings
/* [Rendering Options] */
mode = "Assembled"; // [Individual, Assembled, Exploded]
export_part = "All on plate"; // [All on plate, Snap ring, Cold plate ref, Power cylinder, Power piston, Link discs x4, Support frame, Flywheel, Displacer crank arm, Power crank arm, Rod flange, Stiffener tubes x4]
show_y_section = false; // vertical cut at section_y_offset; keeps y >= offset (+Y half)
section_y_offset = 0; // mm; 0 = engine center plane (XZ)
/* [Kinematics & Animation] */
animate_engine = true; // [true, false]
manual_angle = 45; // [0:360]
/* [Hot cylinder — industry 401 can (see Can401_lib.scad)] */
can_body_od = 98.93;  // mm; BMT body plug OD (bore/displacer sizing)
can_wall_t = 0.21;    // mm; tinplate wall
cyl_h = 47;           // mm; can height (must match Can401_lib can_h)
/* [Layout & cranktrain] */
axle_to_deck = 80;  // crank Z=0 to cold-plate top; keep ≥ flywheel_d/2 + margin
flywheel_d = 140;
flywheel_w = 8;
flywheel_collar_od = 10;
flywheel_collar_h = 6;
left_support_x = -40;
flywheel_x = -22;
power_piston_x = 22;
right_support_x = 40;
disp_link_len = 40;   // mm pin-to-pin; displacer link + slider-crank constraint
power_stroke = 12;
power_piston_h = 16;  // mm; pin at h/2; taller = deeper cup
sv_ratio = 40.0;      // displacer:power swept-volume ratio
/* [Hardware & Mounting] */
pin_d = 1.5;          // silver linkage / clevis pins (mm)
rod_od = 3;           // crankshaft rod stock
screw_d = 3.2; screw_pitch = 16;
insert_hole_d = 4.0;  // press-fit bore for M3 heat-set insert (tune to your inserts)
insert_depth = 3.5;   // pocket depth; cold plate thickness = cold_plate_t
setscrew_d = 2.5;   // M3 grub screw (clearance/tap hole)
collar_od = 10;
collar_len = 5;     // grip length on crankshaft for timing adjustment
bearing_od = 8; bearing_th = 4; bearing_pocket_clearance = 0.2; // S693-class (8×4×3 mm)
seal_od = 4.7; seal_id = 3.0; seal_h = 15;
link_disc_d = 8;          // crank-end disc diameter (YZ face)
link_stick_bore_depth = 3;  // how far stick enters disc from the rim
clevis_tab_x = 2;           // fork tab thickness along pin axis (rod_flange / piston clevis)
clevis_tab_center_x = 3;    // tab center offset from flange axis
clevis_pin_len = 2 * (clevis_tab_center_x + clevis_tab_x / 2); // pin span = outer tab faces
crank_web_t = 2.5;        // web plate thickness (matches crank_arm h=2.5)
crank_web_gap = 3.4;      // clear slot between plates for green fork (≈ pin_d+1.2 + clearance)
crank_web_x = crank_web_gap / 2 + crank_web_t / 2; // arm center offset from linkage axis
shaft_seg_gap = 0.5; // clearance before/after web-plate sandwich gaps (linkage fork clearance)
/* [Assembly Offsets] */
explode_offset = 50;
/* [Displacer] */
displacer_radial_clearance = 1.5; // mm gap to can wall (each side)
displacer_axial_clearance = 2;    // mm at top and bottom of stroke
displacer_stroke_ratio = 0.55;    // stroke as fraction of usable bore depth
/* [Cold side] */
cold_plate_rim_clearance = 0.25; // mm radial gap; plate OD vs can mouth inner wall
cold_plate_t = 6.35;     // mm aluminum plate thickness
cold_plate_cup_depth = 0.05; // mm optional dish on plate top (inside wedge bore)
ring_clamp_overhang = 2.5;     // mm radial inset; wedge pad spans plate_r down to clamp_ir
ring_wedge_compress = 0.30;    // mm TPU squeeze into rim at mouth (see Can401_lib)
/* [Thermodynamic analysis] */
T_hot_C = 50;               // hot-side boundary temp (°C), e.g. warm water on hot can
T_cold_C = 20;              // cold-side boundary temp (°C), e.g. room air at cold plate
mean_pressure_kPa = 101.325; // mean charge pressure (kPa); atmospheric default
engine_rpm = 120;           // assumed running speed for power estimates
schmidt_phase_deg = 90;     // displacer lead over power piston (matches crank geometry)
mechanical_efficiency = 0.65; // [0.3:0.95] fraction of indicated work reaching shaft
dead_volume_scale = 1.0;    // scales geometry-derived clearance/dead volumes
/* [Hidden] */
$fn = 60;
section_half_size = 500; // Y-section clip volume (mm each axis from cut plane)
power_piston_axial_clearance = 1; // mm each end of power piston travel in bore
flange_od = 12; flange_t = 2.0;
disp_flange_pin_z_offset = (flange_t + 2) / 2 + 4; // tab clevis pin height above flange center
power_cyl_boss_h = 5;         // power cylinder pedestal on cold plate
frame_w = 30; frame_t = 5; slot_tolerance = 0.2; parts_y_axis = 0;
shaft_tube_bearing_gap = 0.5;
frame_foot_h = 5;          // support foot pad thickness (sits on cold-plate top)
// Individual-mode export plate layout (build-plate positions; 2 mm+ gaps)
ind_x_snap_ring = -170;
ind_x_cold = -65; ind_y_row1 = -35; ind_x_pwr_cyl = 65;
ind_x_pwr_piston = 15; ind_y_row2 = 40;
ind_x_link_discs = 90; ind_y_link_discs = -85; ind_link_disc_pitch = 12;
ind_x_frame = -65; ind_y_frame = 55;
ind_x_flywheel = 120; ind_y_flywheel = 90;
ind_x_disp_arm = 20; ind_x_pwr_arm = 58;
ind_y_disp_arm = -58; ind_y_pwr_arm = -72;
ind_x_flange = -105; ind_y_flange = -82;
ind_y_tubes = -100;
ind_x_tube0 = -155; ind_x_tube1 = -115; ind_x_tube2 = 55; ind_x_tube3 = 125;
ind_on_plate = export_part == "All on plate";
function export_show(name) = ind_on_plate || export_part == name;

use <Can401_lib.scad>

can_inner_d = can_body_od - 2 * can_wall_t;
can_mouth_id = can_inner_d + 0.7; // rolled-rim inner step (Can401_lib seam_ri + 0.35 mm)
cold_plate_od = can_mouth_id - 2 * cold_plate_rim_clearance;
cold_plate_drop = can401_cold_plate_drop(cold_plate_od); // seat plate OD on inner rim
cold_plate_top_z = -axle_to_deck;                        // deck reference; crank-to-plate-top distance
cold_plate_bottom_z = cold_plate_top_z - cold_plate_t;
can_top_z = cold_plate_bottom_z + cold_plate_drop;         // 401 rim seat preserved
snap_ring_profile = can401_engine_snap_ring_profile(
    cold_plate_od, cold_plate_drop, ring_clamp_overhang, ring_wedge_compress);
snap_ring_t = profile_max_z(snap_ring_profile);

// ==========================================
// 1. LTD OPTIMIZED THERMODYNAMIC CALCULATIONS
// ==========================================
link_stick_bore_d = pin_d + 0.15;
bearing_pocket_od = bearing_od + bearing_pocket_clearance;
bearing_pocket_h = bearing_th + 0.1;
bearing_shaft_hole_d = rod_od + 0.5;
bearing_inboard_t = bearing_pocket_h;
flywheel_hub_od = rod_od + 9;
crank_pin_show_len = link_disc_d;
displacer_d = can_inner_d - 2 * displacer_radial_clearance;
disp_bore_depth = cyl_h - 2 * displacer_axial_clearance;
displacer_stroke = disp_bore_depth * displacer_stroke_ratio;
displacer_h = disp_bore_depth - displacer_stroke;
displacer_r = displacer_d / 2; displacer_area = 3.14159265 * displacer_r * displacer_r;
displacer_swept_vol = displacer_area * displacer_stroke;
power_swept_vol = displacer_swept_vol / sv_ratio;
power_cyl_id = sqrt(power_swept_vol / (3.14159265 * 0.25 * power_stroke));
power_cyl_od = power_cyl_id + 4;
power_cyl_h = power_stroke + power_piston_h + 2 * power_piston_axial_clearance;
power_piston_od = power_cyl_id - 0.15;
power_piston_clevis_boss_h = 6; // fixed fork height at pin (original h=8 design)
displacer_crank_r = displacer_stroke / 2; power_crank_r = power_stroke / 2;
disp_can_top_z = can_top_z - displacer_axial_clearance;
disp_can_bottom_z = can_top_z - cyl_h;
disp_z_min = disp_can_bottom_z + displacer_axial_clearance + displacer_h / 2;
disp_z_max = disp_can_top_z - displacer_axial_clearance - displacer_h / 2;
disp_center_mid_z = (disp_z_min + disp_z_max) / 2;
power_cyl_base_z = cold_plate_top_z;
power_cyl_bore_top_z = power_cyl_base_z + power_cyl_h;
power_piston_base_min = power_cyl_base_z + power_piston_axial_clearance;
power_piston_base_max = power_cyl_bore_top_z - power_piston_axial_clearance - power_piston_h;
power_piston_base_mid = (power_piston_base_min + power_piston_base_max) / 2;
disp_rod_blind_depth = 4.0; // blind hole depth in printed rod_flange
// Fixed steel lengths seeded at nominal phase (displacer / power at +stroke/2, crank pin at +Y).
displacer_shaft_len =
    let(
        disp_rod_joint_z = displacer_crank_r - disp_link_len,
        disp_rod_attach_z = disp_rod_joint_z - disp_rod_blind_depth,
        disp_top_z = disp_center_mid_z + displacer_stroke / 2 + displacer_h / 2
    ) disp_rod_attach_z - disp_top_z;
power_link_len = abs(
    power_crank_r - (power_piston_base_mid + power_stroke / 2 + power_piston_h / 2));

// --- Schmidt / Carnot thermodynamic estimates (gamma-type LTD layout) ---
// Closed-form Schmidt indicated work per revolution (J)
function schmidt_work_per_rev(V_c0, V_e0, V_p, V_d, phase_deg, p_m) =
    let(
        K = (V_d + V_p) / 2 + V_c0 + V_e0,
        B = K + sqrt(K * K - 0.25 * V_d * V_p * pow(sin(phase_deg), 2))
    ) abs((PI * p_m * V_d * V_p * sin(phase_deg)) / (2 * B) * 1e-6);

T_hot_K = T_hot_C + 273.15;
T_cold_K = T_cold_C + 273.15;
eta_carnot = (T_hot_K > T_cold_K) ? (1 - T_cold_K / T_hot_K) : 0;
V_c0_dead = (3.14159265 / 4) * power_cyl_id * power_cyl_id
    * (2 * power_piston_axial_clearance + 3) * dead_volume_scale;
can_annulus_area = 3.14159265 / 4 * (can_inner_d * can_inner_d - displacer_d * displacer_d);
V_e0_dead = (displacer_area * 2 * displacer_axial_clearance
    + can_annulus_area * cyl_h * 0.35
    + 3.14159265 / 4 * seal_id * seal_id * seal_h) * dead_volume_scale;
vol_eff_displacer = displacer_swept_vol / (displacer_swept_vol + V_e0_dead);
vol_eff_power = power_swept_vol / (power_swept_vol + V_c0_dead);
schmidt_phase_factor = max(sin(schmidt_phase_deg), 0.01);
schmidt_W_indicated = schmidt_work_per_rev(
    V_c0_dead, V_e0_dead, power_swept_vol, displacer_swept_vol,
    schmidt_phase_deg, mean_pressure_kPa);
// Practical indicated η: Carnot ceiling reduced by dead-volume and phase factors
eta_schmidt = eta_carnot * vol_eff_displacer * vol_eff_power * schmidt_phase_factor;
schmidt_Q_hot = (eta_schmidt > 0) ? (schmidt_W_indicated / eta_schmidt) : 0;
eta_shaft_est = eta_schmidt * mechanical_efficiency;
shaft_power_W = schmidt_W_indicated * mechanical_efficiency * (engine_rpm / 60);
heat_input_W = schmidt_Q_hot * (engine_rpm / 60);
echo("=== LTD Stirling thermodynamic estimate ===");
echo(str("Displacer swept volume: ", displacer_swept_vol / 1000, " cm³ (",
    displacer_stroke, " mm stroke)"));
echo(str("Power swept volume: ", power_swept_vol / 1000, " cm³ (",
    power_stroke, " mm stroke, ID ", power_cyl_id, " mm)"));
echo(str("Dead volume (cold / hot): ", V_c0_dead / 1000, " / ",
    V_e0_dead / 1000, " cm³"));
echo(str("Volume efficiency (displacer / power): ",
    vol_eff_displacer * 100, " % / ", vol_eff_power * 100, " %"));
echo(str("Temperatures: Th=", T_hot_C, "°C  Tc=", T_cold_C,
    "°C  ΔT=", T_hot_C - T_cold_C, "°C"));
echo(str("Carnot ceiling: ", eta_carnot * 100, " %"));
echo(str("Estimated indicated efficiency: ", eta_schmidt * 100,
    " %  (Carnot × volume × phase factors)"));
echo(str("Estimated shaft efficiency: ", eta_shaft_est * 100,
    " %  (× mechanical ", mechanical_efficiency * 100, " %)"));
echo(str("Schmidt indicated work / rev: ", schmidt_W_indicated, " J"));
echo(str("Estimated heat input / rev: ", schmidt_Q_hot, " J"));
echo(str("At ", engine_rpm, " RPM: ~", shaft_power_W, " W shaft  |  ~",
    heat_input_W, " W heat input"));
echo("Note: ideal-cycle estimate only — measure heat and torque on a built engine for real η.");

crank_web_outer = crank_web_x + crank_web_t / 2;
crank_web_inner = crank_web_x - crank_web_t / 2;
// Displacer crank webs at x = 0
disp_web_l_out = -crank_web_outer;
disp_web_l_in = -crank_web_inner;
disp_web_r_in = crank_web_inner;
disp_web_r_out = crank_web_outer;
// Power crank webs at x = power_piston_x
pwr_web_l_out = power_piston_x - crank_web_outer;
pwr_web_l_in = power_piston_x - crank_web_inner;
pwr_web_r_in = power_piston_x + crank_web_inner;
pwr_web_r_out = power_piston_x + crank_web_outer;
// Long spans: stop before sandwich gaps (linkage + fork live between inner web faces)
shaft_seg_flywheel_left = left_support_x;
shaft_seg_flywheel_right = disp_web_l_out - shaft_seg_gap;
shaft_seg_mid_left = disp_web_r_out + shaft_seg_gap;
shaft_seg_mid_right = pwr_web_l_out - shaft_seg_gap;
shaft_seg_power_left = pwr_web_r_out + shaft_seg_gap;
shaft_seg_power_right = right_support_x;
shaft_seg_flywheel_h = shaft_seg_flywheel_right - shaft_seg_flywheel_left;
shaft_seg_mid_h = shaft_seg_mid_right - shaft_seg_mid_left;
shaft_seg_power_h = shaft_seg_power_right - shaft_seg_power_left;
shaft_tube_id = rod_od + 0.2; // bore over crank rod (matches crank_arm shaft clearance)
flywheel_hub_l_x = flywheel_x - flywheel_w / 2; // −X face of flywheel hub (shaft axis = Z in geom → X after rotate)
flywheel_hub_r_x = flywheel_x + flywheel_w / 2; // +X face of hub; flywheel collar seats here
flywheel_collar_r_x = flywheel_hub_r_x + flywheel_collar_h; // +X face of flywheel timing collar (toward disp crank)
// Outboard crank collar faces along X (collar_outward clamps away from web sandwich)
disp_collar_l_face = -crank_web_x - collar_len;
disp_collar_r_face = crank_web_x + collar_len;
pwr_collar_l_face = power_piston_x - crank_web_x - collar_len;
pwr_collar_r_face = power_piston_x + crank_web_x + collar_len;
left_bearing_inboard_x = left_support_x + bearing_inboard_t;
right_bearing_inboard_x = right_support_x - bearing_inboard_t;
// Four stiffener tubes: butt crank collars + flywheel hub/collar; 0.5 mm clearance at frame bearings
shaft_tube_pwr_frame_x0 = pwr_collar_r_face;
shaft_tube_pwr_frame_x1 = right_bearing_inboard_x - shaft_tube_bearing_gap;
shaft_tube_pwr_disp_x0 = disp_collar_r_face;
shaft_tube_pwr_disp_x1 = pwr_collar_l_face;
shaft_tube_disp_fly_x0 = flywheel_collar_r_x;
shaft_tube_disp_fly_x1 = disp_collar_l_face;
shaft_tube_fly_frame_x0 = left_bearing_inboard_x + shaft_tube_bearing_gap;
shaft_tube_fly_frame_x1 = flywheel_hub_l_x;
shaft_tube_pwr_frame_len = shaft_tube_pwr_frame_x1 - shaft_tube_pwr_frame_x0;
shaft_tube_pwr_disp_len = shaft_tube_pwr_disp_x1 - shaft_tube_pwr_disp_x0;
shaft_tube_disp_fly_len = shaft_tube_disp_fly_x1 - shaft_tube_disp_fly_x0;
shaft_tube_fly_frame_len = shaft_tube_fly_frame_x1 - shaft_tube_fly_frame_x0;

// --- Builder cut lengths (mm) ---
shaft_seg_disp_web_l_len = abs(disp_web_l_out - disp_web_l_in);
shaft_seg_disp_web_r_len = abs(disp_web_r_out - disp_web_r_in);
shaft_seg_pwr_web_l_len = abs(pwr_web_l_out - pwr_web_l_in);
shaft_seg_pwr_web_r_len = abs(pwr_web_r_out - pwr_web_r_in);
crankshaft_rod_total = shaft_seg_flywheel_h + shaft_seg_disp_web_l_len + shaft_seg_disp_web_r_len
    + shaft_seg_mid_h + shaft_seg_pwr_web_l_len + shaft_seg_pwr_web_r_len + shaft_seg_power_h;
link_stick_in_disc = 2 * link_stick_bore_depth; // silver rod inserted into both green discs

function disp_link_pin_span_at(deg) =
    let(
        dpy = -displacer_crank_r * sin(deg),
        dpz = displacer_crank_r * cos(deg),
        joint_z = dpz - sqrt(max(0.001, pow(disp_link_len, 2) - pow(dpy, 2)))
    ) sqrt(pow(dpy, 2) + pow(dpz - joint_z, 2));

function span_min(v0, v90, v180, v270) = min(v0, min(v90, min(v180, v270)));
function span_max(v0, v90, v180, v270) = max(v0, max(v90, max(v180, v270)));

disp_link_span_min = span_min(
    disp_link_pin_span_at(0), disp_link_pin_span_at(90),
    disp_link_pin_span_at(180), disp_link_pin_span_at(270));
disp_link_span_max = span_max(
    disp_link_pin_span_at(0), disp_link_pin_span_at(90),
    disp_link_pin_span_at(180), disp_link_pin_span_at(270));
linkage_rod_cut_len = disp_link_span_max + link_stick_in_disc;
power_link_rod_cut_len = power_link_len + link_stick_in_disc;

echo("=== Builder cut lengths (mm) ===");
echo(str("Crankshaft ", rod_od, " mm rod — cut ", crankshaft_rod_total,
    " mm total (or ", 7, " pieces below)"));
echo(str("  Flywheel→displacer left: ", shaft_seg_flywheel_h));
echo(str("  Displacer web stubs (×2): ", shaft_seg_disp_web_l_len, " each"));
echo(str("  Displacer→power span: ", shaft_seg_mid_h));
echo(str("  Power web stubs (×2): ", shaft_seg_pwr_web_l_len, " each"));
echo(str("  Power→right bearing: ", shaft_seg_power_h));
echo(str("Stiffener tubes (printed, reference): flywheel-frame ",
    shaft_tube_fly_frame_len, ", disp-fly ", shaft_tube_disp_fly_len,
    ", pwr-disp ", shaft_tube_pwr_disp_len, ", pwr-frame ", shaft_tube_pwr_frame_len));
echo(str("Displacer connecting rod (", pin_d, " mm silver + discs) — pin-to-pin ",
    disp_link_span_min, "–", disp_link_span_max,
    " mm; cut stock ", linkage_rod_cut_len, " mm",
    "  (Individual mode exports green discs only)"));
echo(str("Power connecting rod — pin-to-pin ", power_link_len,
    " mm; cut stock ", power_link_rod_cut_len, " mm",
    "  (Individual mode exports green discs only)"));
echo(str("Displacer shaft (", rod_od, " mm steel, flange→displacer): cut ",
    displacer_shaft_len, " mm  (", disp_rod_blind_depth, " mm blind hole in flange)"));
echo(str("At manual_angle=", manual_angle, "°: fixed displacer shaft ",
    displacer_shaft_len, " mm, disp link ", disp_link_len, " mm, power link ",
    power_link_len, " mm"));

// ==========================================
// 2. SCAD GEOMETRY MODULES
// ==========================================
module bearing_pocket() {
    cylinder(d=bearing_pocket_od, h=bearing_pocket_h, center=false);
    translate([0, 0, -6]) cylinder(d=bearing_shaft_hole_d, h=10, center=false);
}
module mounting_holes(h_len=20) {
    translate([0, -screw_pitch/2, -h_len/2]) cylinder(d=screw_d, h=h_len, center=false);
    translate([0, screw_pitch/2, -h_len/2]) cylinder(d=screw_d, h=h_len, center=false);
}
module mounting_holes_from_top(z_top, h_len=20) {
    translate([0, -screw_pitch/2, z_top - h_len]) cylinder(d=screw_d, h=h_len, center=false);
    translate([0, screw_pitch/2, z_top - h_len]) cylinder(d=screw_d, h=h_len, center=false);
}
module insert_pockets() {
    insert_z = cold_plate_t - insert_depth;
    translate([0, -screw_pitch/2, insert_z])
        cylinder(d=insert_hole_d, h=insert_depth + 0.1, center=false);
    translate([0, screw_pitch/2, insert_z])
        cylinder(d=insert_hole_d, h=insert_depth + 0.1, center=false);
}
// Shaft stub along X only (omit if length <= 0)
module shaft_span_x(x_left, x_right) {
    span_h = x_right - x_left;
    x_mid = (x_left + x_right) / 2;
    if (span_h > 0)
        translate([axle_explode_x(x_mid), 0, 0])
        translate([x_mid, 0, 0]) rotate([0, 90, 0])
            color("DimGrey") cylinder(d=rod_od, h=span_h, center=true);
}
// Stiffener tube on exposed rod: OD = crank collar, ID clears 3 mm rod (skip linkage fork gaps)
module crank_shaft_tube_x(x_left, x_right) {
    len = x_right - x_left;
    x_mid = (x_left + x_right) / 2;
    if (len > 0)
        translate([axle_explode_x(x_mid), 0, 0])
        translate([x_mid, 0, 0]) rotate([0, 90, 0])
            difference() {
                color("SteelBlue") cylinder(d=collar_od, h=len, center=true);
                cylinder(d=shaft_tube_id, h=len + 0.1, center=true);
            }
}
module crank_shaft_tube(len) {
    difference() {
        color("SteelBlue") cylinder(d=collar_od, h=len, center=true);
        cylinder(d=shaft_tube_id, h=len + 0.1, center=true);
    }
}
module support_frame() {
    // Local z=0 = foot bottom on cold-plate top; bearing axis at z = axle_to_deck.
    difference() {
        union() {
            hull() {
                translate([0, 0, axle_to_deck]) rotate([90, 0, 90]) cylinder(d=14, h=frame_t, center=true);
                translate([0, 0, frame_foot_h / 2]) cube([frame_t, frame_w, frame_foot_h], center=true);
            }
            translate([0, 0, axle_to_deck]) rotate([90, 0, 90]) cylinder(d=14, h=frame_t, center=true);
        }
        translate([0, 0, axle_to_deck]) rotate([90, 0, 90]) bearing_pocket();
        mounting_holes_from_top(frame_foot_h, frame_foot_h + cold_plate_t + 5);
    }
}
// Fork tab: square shank, +Z crown rounded to link_disc_d (matches link_end_disc arc)
module clevis_boss_round_top(x, z, tab_h, tab_x = 2) {
    tab_y = link_disc_d;
    top_r = min(tab_y / 2, tab_h / 2);
    body_h = tab_h - top_r;
    z_top = z + tab_h / 2;
    z_bottom = z - tab_h / 2;
    union() {
        translate([x, 0, z_bottom + body_h / 2])
            cube([tab_x, tab_y, body_h], center=true);
        intersection() {
            translate([x, 0, z_top - top_r])
                rotate([0, 90, 0]) cylinder(d=2 * top_r, h=tab_x, center=true);
            translate([x, 0, z_top - top_r / 2])
                cube([tab_x, tab_y + 0.1, top_r], center=true);
        }
    }
}
module link_end_disc(pin_d, stick_rim_z=-1) {
    fork_thin = pin_d + 1.2;
    disc_r = link_disc_d / 2;
    color("LightGreen") difference() {
        rotate([0, 90, 0])
            cylinder(d=link_disc_d, h=fork_thin, center=true);
        rotate([0, 90, 0])
            cylinder(d=pin_d, h=fork_thin + 2, center=true);
        if (stick_rim_z < 0)
            translate([0, 0, -disc_r])
                cylinder(d=link_stick_bore_d, h=disc_r + link_stick_bore_depth, center=false);
        else
            mirror([0, 0, 1])
                translate([0, 0, -disc_r])
                cylinder(d=link_stick_bore_d, h=disc_r + link_stick_bore_depth, center=false);
    }
}
module linkage_rod(length, pin_d=pin_d, show_steel=true) {
    disc_r = link_disc_d / 2;
    if (show_steel)
        color("Silver")
            translate([0, 0, -length - disc_r - link_stick_bore_depth])
            cylinder(d=pin_d, h=length + disc_r + 2 * link_stick_bore_depth, center=false);
    // Crank end: pin along X; stick into -Z rim
    link_end_disc(pin_d, stick_rim_z=-1);
    // Piston / flange end: same disc; stick into +Z rim (rod approaches from crank)
    translate([0, 0, -length]) link_end_disc(pin_d, stick_rim_z=1);
}
// Single fork disc flat on build plate (stick bore opening toward +Z)
module link_disc_on_bed(stick_rim_z) {
    fork_thin = pin_d + 1.2;
    translate([0, 0, fork_thin / 2])
        rotate([0, -90, 0])
            link_end_disc(pin_d, stick_rim_z=stick_rim_z);
}
// collar_outward: +1 or -1, clamp extends away from web sandwich center only
module crank_arm(radius, pin_d=pin_d, collar_outward=1) {
    collar_z0 = (collar_outward > 0) ? 0 : -collar_len;
    collar_z1 = (collar_outward > 0) ? collar_len : 0;
    collar_mid_z = (collar_z0 + collar_z1) / 2;
    bore_z0 = min(-pin_d, collar_z0) - 0.5;
    bore_z1 = max(pin_d, collar_z1) + 0.5;

    color("DarkOrange") difference() {
        union() {
            translate([0, 0, collar_z0])
                cylinder(d=collar_od, h=collar_len, center=false);
            hull() {
                cylinder(d=10, h=2.5, center=true);
                translate([0, radius, 0]) cylinder(d=7, h=2.5, center=true);
            }
            hull() {
                cylinder(d=10, h=2.5, center=true);
                translate([0, -radius*0.8, 0]) cylinder(d=16, h=2.5, center=true);
            }
        }
        translate([0, 0, bore_z0])
            cylinder(d=rod_od + 0.15, h=bore_z1 - bore_z0, center=false);
        // Setscrew 90° from pin bore (clockwise on collar, shaft axis = Z)
        translate([collar_od / 2, 0, collar_mid_z]) rotate([0, 90, 0])
            cylinder(d=setscrew_d, h=collar_od, center=true);
        translate([0, radius, 0]) cylinder(d=pin_d, h=6, center=true);
    }
}

module rod_flange(pin_d=pin_d) {
    clevis_base_z = (flange_t + 2) / 2;
    pin_z = clevis_base_z + 4;
    color("Gold") difference() {
        union() {
            cylinder(d=flange_od, h=flange_t + 2, center=true);
            translate([0, 0, clevis_base_z]) {
                clevis_boss_round_top(-clevis_tab_center_x, 4, tab_h=8, tab_x=clevis_tab_x);
                clevis_boss_round_top(clevis_tab_center_x, 4, tab_h=8, tab_x=clevis_tab_x);
            }
        }
        translate([0, 0, -flange_t]) cylinder(d=2.5, h=flange_t + 1.5, center=false); // Blind screw hole
        translate([0, 0, pin_z]) rotate([0, 90, 0])
            cylinder(d=pin_d, h=clevis_pin_len, center=true); // Pin along X, flush with tab outer faces
    }
}
module displacer() { color("LightBlue") cylinder(d=displacer_d, h=displacer_h, center=true); }
module power_piston(pin_d=pin_d) {
    pin_z = power_piston_h / 2;
    boss_h = power_piston_clevis_boss_h;
    color("DimGrey") difference() {
        union() {
            difference() {
                cylinder(d=power_piston_od, h=power_piston_h, center=false);
                translate([0, 0, 1.5]) cylinder(d=power_piston_od - 2, h=power_piston_h, center=false);
            }
            intersection() {
                translate([0, 0, 1.5]) cylinder(d=power_piston_od - 2.2, h=power_piston_h - 1.5, center=false);
                union() {
                    clevis_boss_round_top(-3, pin_z, boss_h);
                    clevis_boss_round_top(3, pin_z, boss_h);
                }
            }
        }
        translate([0, 0, pin_z]) rotate([0, 90, 0])
            cylinder(d=pin_d, h=power_piston_od + 2, center=true);
    }
}
module power_cylinder() {
    color("Silver") difference() {
        cylinder(d=power_cyl_od, h=power_cyl_h, center=false);
        translate([0, 0, -1]) cylinder(d=power_cyl_id, h=power_cyl_h + 2, center=false);
    }
}
module displacer_rod(rod_len) { color("SteelBlue") cylinder(d=rod_od, h=rod_len, center=false); }
module cold_plate() {
    color("Silver") difference() {
        union() {
            cylinder(d=cold_plate_od, h=cold_plate_t, center=false);
            translate([power_piston_x, parts_y_axis, 0]) cylinder(d=power_cyl_od + 4, h=power_cyl_boss_h, center=false);
        }
        translate([0, 0, -1]) cylinder(d=seal_od, h=10, center=false);
        translate([power_piston_x, parts_y_axis, -1]) cylinder(d=power_cyl_id, h=15, center=false);
        translate([left_support_x, parts_y_axis, 0]) mounting_holes_from_top(cold_plate_t, cold_plate_t + 2);
        translate([right_support_x, parts_y_axis, 0]) mounting_holes_from_top(cold_plate_t, cold_plate_t + 2);
        translate([left_support_x, parts_y_axis, 0]) insert_pockets();
        translate([right_support_x, parts_y_axis, 0]) insert_pockets();
        if (cold_plate_cup_depth > 0)
            translate([0, 0, cold_plate_t - cold_plate_cup_depth])
                cylinder(
                    d=cold_plate_od - 2 * ring_clamp_overhang - 1,
                    h=cold_plate_cup_depth + 0.01, center=false);
    }
}
module brass_tube_seal() {
    color("Gold") difference() {
        cylinder(h=seal_h, d=seal_od, center=false);
        translate([0, 0, -1]) cylinder(h=seal_h + 2, d=seal_id, center=false);
    }
}
// TPU snap ring: wedge pad at seated rim seal + lid-skirt grip (plate-local z, no flip)
module can_snap_ring() {
    color("Teal")
        can401_engine_snap_ring(
            cold_plate_od, cold_plate_drop, ring_clamp_overhang, ring_wedge_compress);
}
module flywheel_geom() {
    collar_z = flywheel_w / 2 + flywheel_collar_h / 2;
    difference() {
        union() {
            difference() { cylinder(d=flywheel_d, h=flywheel_w, center=true); cylinder(d=flywheel_d - 8, h=flywheel_w + 2, center=true); }
            cylinder(d=flywheel_hub_od, h=flywheel_w, center=true);
            translate([0, 0, flywheel_w / 2]) cylinder(d=flywheel_collar_od, h=flywheel_collar_h, center=false);
            cube([flywheel_d - 2, 2.5, flywheel_w - 2], center=true);
            cube([2.5, flywheel_d - 2, flywheel_w - 2], center=true);
        }
        cylinder(d=rod_od + 0.15, h=flywheel_w + flywheel_collar_h + 4, center=true);
        // Radial M3 setscrew through clamping collar (shaft axis = Z)
        translate([flywheel_collar_od / 2, 0, collar_z]) rotate([0, 90, 0])
            cylinder(d=setscrew_d, h=flywheel_collar_od + 2, center=true);
    }
}

// Keep y >= section_y_offset for vertical (XZ) cross-section views
module with_y_section() {
    if (show_y_section) {
        intersection() {
            children();
            translate([-section_half_size, section_y_offset, -section_half_size])
                cube([2 * section_half_size, section_half_size, 2 * section_half_size]);
        }
    } else {
        children();
    }
}

// ==========================================
// 3. MAIN PARAMETRIC LAYOUT ENGINE
// ==========================================
ez = (mode == "Exploded") ? explode_offset : 0;
ring_ez = (mode == "Exploded") ? explode_offset * 0.4 : 0;
// Spread drive-train parts along crank axis (+X right); chassis still separates on −Z
function axle_explode_x(x) = (mode == "Exploded") ? (x / right_support_x) * explode_offset : 0;
engine_angle = (animate_engine == true) ? ($t * 360) : manual_angle;
disp_angle = engine_angle; 
piston_angle = engine_angle - 90; 

// Exact trigonometric tracking variables matching the physical rotation path
disp_pin_y = -displacer_crank_r * sin(disp_angle);
disp_pin_z = displacer_crank_r * cos(disp_angle);
piston_pin_y = -power_crank_r * sin(piston_angle);
piston_pin_z = power_crank_r * cos(piston_angle);

// Slider-crank: fixed-length rods close the kinematic loop at every crank angle
disp_rod_joint_z = disp_pin_z - sqrt(max(0.001, pow(disp_link_len, 2) - pow(disp_pin_y, 2)));
disp_rod_attach_z = disp_rod_joint_z - disp_rod_blind_depth;
disp_top_z = disp_rod_attach_z - displacer_shaft_len;
disp_center_z = disp_top_z - displacer_h / 2;
disp_link_len_eff = disp_link_len;
disp_rot_x = atan2(disp_pin_y, disp_pin_z - disp_rod_joint_z);

power_piston_pin_z = piston_pin_z - sqrt(max(0.001, pow(power_link_len, 2) - pow(piston_pin_y, 2)));
power_piston_base_z = power_piston_pin_z - power_piston_h / 2;
power_link_len_eff = power_link_len;
piston_rot_x = atan2(piston_pin_y, piston_pin_z - power_piston_pin_z);

if (mode == "Assembled" || mode == "Exploded") {
with_y_section() {
    // 1. DRIVE AXLE (Z = 0): 3 mm rod + four collar-OD tubes between major stations
    shaft_span_x(shaft_seg_flywheel_left, shaft_seg_flywheel_right);
    shaft_span_x(disp_web_l_out, disp_web_l_in);
    shaft_span_x(disp_web_r_in, disp_web_r_out);
    shaft_span_x(shaft_seg_mid_left, shaft_seg_mid_right);
    shaft_span_x(pwr_web_l_out, pwr_web_l_in);
    shaft_span_x(pwr_web_r_in, pwr_web_r_out);
    shaft_span_x(shaft_seg_power_left, shaft_seg_power_right);
    crank_shaft_tube_x(shaft_tube_pwr_frame_x0, shaft_tube_pwr_frame_x1);
    crank_shaft_tube_x(shaft_tube_pwr_disp_x0, shaft_tube_pwr_disp_x1);
    crank_shaft_tube_x(shaft_tube_disp_fly_x0, shaft_tube_disp_fly_x1);
    crank_shaft_tube_x(shaft_tube_fly_frame_x0, shaft_tube_fly_frame_x1);
    translate([flywheel_x + axle_explode_x(flywheel_x), 0, 0])
        rotate([engine_angle, 0, 0]) rotate([90, 0, 90]) flywheel_geom();
    
    // DISPLACER KINEMATICS (X = 0) - DUAL WEB SANDWICH CLUSTER
    translate([axle_explode_x(0), 0, 0]) {
        translate([-crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, disp_angle]) crank_arm(displacer_crank_r, collar_outward=-1);
        translate([crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, disp_angle]) crank_arm(displacer_crank_r, collar_outward=1);
        translate([0, disp_pin_y, disp_pin_z]) rotate([0, 90, 0]) color("Silver") cylinder(d=pin_d, h=crank_pin_show_len, center=true);

translate([0, disp_pin_y, disp_pin_z]) rotate([-disp_rot_x, 0, 0]) linkage_rod(disp_link_len_eff);
}
// POWER PISTON KINEMATICS — dual web sandwich at power_piston_x
translate([power_piston_x + axle_explode_x(power_piston_x), 0, 0]) {
translate([-crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, piston_angle]) crank_arm(power_crank_r, collar_outward=-1);
translate([crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, piston_angle]) crank_arm(power_crank_r, collar_outward=1);
translate([0, piston_pin_y, piston_pin_z]) rotate([0, 90, 0]) color("Silver") cylinder(d=pin_d, h=crank_pin_show_len, center=true);
translate([0, piston_pin_y, piston_pin_z]) rotate([-piston_rot_x, 0, 0]) linkage_rod(power_link_len_eff);
}

// 2. CHASSIS MOUNT DECK (Spans downward to frame top beds)
translate([0, 0, -ez]) {
translate([left_support_x, parts_y_axis, cold_plate_top_z]) support_frame();
translate([right_support_x, parts_y_axis, cold_plate_top_z]) mirror([1, 0, 0]) support_frame();
translate([0, parts_y_axis, cold_plate_bottom_z]) {
cold_plate();
translate([0, 0, -1]) brass_tube_seal(); // press-fit bore; bottom aligned with plate cut
translate([0, 0, ring_ez]) can_snap_ring();
translate([power_piston_x, parts_y_axis, cold_plate_t]) power_cylinder();
}
}
// 3. INTERNAL ENGINE CAVITY (Pistons, clevis couplings, and pressure vessels)
translate([0, 0, -ez * 2]) {
// POWER PISTON CLUSTER WITH MECHANICAL HINGE PIN
translate([power_piston_x, parts_y_axis, power_piston_base_z]) {
power_piston();
translate([0, 0, power_piston_h / 2]) rotate([0, 90, 0])
color("Silver") cylinder(d=pin_d, h=power_piston_od + 1, center=true);
}
// DISPLACER ASSEMBLY WITH INTEGRATED CLEVIS HARDWARE
translate([0, parts_y_axis, 0]) {
translate([0, 0, disp_rod_joint_z - disp_flange_pin_z_offset]) rod_flange();
translate([0, 0, disp_rod_joint_z]) rotate([0, 90, 0])
    color("Silver") cylinder(d=pin_d, h=clevis_pin_len, center=true);
translate([0, 0, disp_rod_attach_z]) mirror([0, 0, 1])
displacer_rod(displacer_shaft_len);
translate([0, 0, disp_center_z]) displacer();
}
translate([0, parts_y_axis, disp_can_bottom_z])
    color("DarkGrey") can401_body();
}
}
} else if (mode == "Individual") {
// export_part dropdown: "All on plate" uses layout below; else single part at origin for STL
if (export_show("Cold plate ref"))
    translate(ind_on_plate ? [ind_x_cold, ind_y_row1, 0] : [0, 0, 0]) cold_plate();
if (export_show("Snap ring"))
    translate(ind_on_plate ? [ind_x_snap_ring, ind_y_row1, 0] : [0, 0, 0]) can_snap_ring();
if (export_show("Power cylinder"))
    translate(ind_on_plate ? [ind_x_pwr_cyl, ind_y_row1, 0] : [0, 0, 0]) power_cylinder();
if (export_show("Power piston"))
    translate(ind_on_plate ? [ind_x_pwr_piston, ind_y_row2, 0] : [0, 0, 0]) power_piston();
if (export_show("Link discs x4")) {
    link_ox = ind_on_plate ? ind_x_link_discs : -ind_link_disc_pitch / 2;
    link_oy = ind_on_plate ? ind_y_link_discs : -ind_link_disc_pitch / 2;
    translate([link_ox, link_oy + ind_link_disc_pitch, 0]) link_disc_on_bed(-1);
    translate([link_ox + ind_link_disc_pitch, link_oy + ind_link_disc_pitch, 0]) link_disc_on_bed(1);
    translate([link_ox, link_oy, 0]) link_disc_on_bed(-1);
    translate([link_ox + ind_link_disc_pitch, link_oy, 0]) link_disc_on_bed(1);
}
if (export_show("Support frame"))
    translate(ind_on_plate ? [ind_x_frame, ind_y_frame, 0] : [0, 0, 0])
        rotate([90, 0, 0]) rotate([0, 0, 90]) support_frame();
if (export_show("Flywheel"))
    translate(ind_on_plate ? [ind_x_flywheel, ind_y_flywheel, flywheel_w / 2] : [0, 0, flywheel_w / 2])
        flywheel_geom();
if (export_show("Displacer crank arm"))
    translate(ind_on_plate ? [ind_x_disp_arm, ind_y_disp_arm, 1.25] : [0, 0, 1.25])
        rotate([0, 180, 0]) crank_arm(displacer_crank_r, collar_outward=-1);
if (export_show("Power crank arm"))
    translate(ind_on_plate ? [ind_x_pwr_arm, ind_y_pwr_arm, 1.25] : [0, 0, 1.25])
        crank_arm(power_crank_r, collar_outward=1);
if (export_show("Rod flange"))
    translate(ind_on_plate ? [ind_x_flange, ind_y_flange, (flange_t + 2) / 2] : [0, 0, (flange_t + 2) / 2])
        rod_flange();
if (export_show("Stiffener tubes x4")) {
    if (ind_on_plate) {
        translate([ind_x_tube0, ind_y_tubes, shaft_tube_fly_frame_len / 2]) crank_shaft_tube(shaft_tube_fly_frame_len);
        translate([ind_x_tube1, ind_y_tubes, shaft_tube_disp_fly_len / 2]) crank_shaft_tube(shaft_tube_disp_fly_len);
        translate([ind_x_tube2, ind_y_tubes, shaft_tube_pwr_disp_len / 2]) crank_shaft_tube(shaft_tube_pwr_disp_len);
        translate([ind_x_tube3, ind_y_tubes, shaft_tube_pwr_frame_len / 2]) crank_shaft_tube(shaft_tube_pwr_frame_len);
    } else {
        translate([shaft_tube_fly_frame_len / 2, 0, 0]) crank_shaft_tube(shaft_tube_fly_frame_len);
        translate([shaft_tube_fly_frame_len + 3 + shaft_tube_disp_fly_len / 2, 0, 0]) crank_shaft_tube(shaft_tube_disp_fly_len);
        translate([shaft_tube_fly_frame_len + 3 + shaft_tube_disp_fly_len + 3 + shaft_tube_pwr_disp_len / 2, 0, 0])
            crank_shaft_tube(shaft_tube_pwr_disp_len);
        translate([
            shaft_tube_fly_frame_len + 3 + shaft_tube_disp_fly_len + 3 + shaft_tube_pwr_disp_len + 3 + shaft_tube_pwr_frame_len / 2,
            0, 0]) crank_shaft_tube(shaft_tube_pwr_frame_len);
    }
}
}


