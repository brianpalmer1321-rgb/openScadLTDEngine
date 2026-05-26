
// Customizer Panel Settings
/* [Rendering Options] */
mode = "Assembled"; // [Individual, Assembled, Exploded]
/* [Kinematics & Animation] */
animate_engine = true; // [true, false]
manual_angle = 45; // [0:360]
/* [Hardware & Mounting] */
screw_d = 3.2; screw_pitch = 16;
insert_hole_d = 4.0;  // press-fit bore for M3 heat-set insert (tune to your inserts)
insert_depth = 3.5;   // pocket depth; cold plate is 4 mm — use short M3 inserts or adjust
setscrew_d = 2.5;   // M3 grub screw (clearance/tap hole)
collar_od = 10;
collar_len = 5;     // grip length on crankshaft for timing adjustment
link_disc_d = 8;          // crank-end disc diameter (YZ face)
link_stick_bore_d = 1.65; // clearance for 1.5 mm silver rod
link_stick_bore_depth = 3;  // how far stick enters disc from the rim
crank_web_t = 2.5;        // web plate thickness (matches crank_arm h=2.5)
crank_web_gap = 3.4;      // clear slot between plates for green fork (≈ pin_d+1.2 + clearance)
crank_web_x = crank_web_gap / 2 + crank_web_t / 2; // arm center offset from linkage axis
crank_web_legacy_half = 2; // prior hardcoded web arm offset (±2 mm)
crank_web_span_delta = 2 * (crank_web_x - crank_web_legacy_half);
shaft_seg_flywheel_h = 46 - 0.75;
shaft_seg_mid_h = 20.5 - crank_web_span_delta;
shaft_seg_mid_x = 11 - crank_web_span_delta / 2;
shaft_seg_mid_right = shaft_seg_mid_x + shaft_seg_mid_h / 2;
shaft_seg_power_h = 23.75;
shaft_seg_power_x = shaft_seg_mid_right + shaft_seg_power_h / 2;
/* [Assembly Offsets] */
explode_offset = 50;
/* [Displacer] */
displacer_radial_clearance = 1.5; // mm gap to can wall (each side)
displacer_axial_clearance = 2;    // mm at top and bottom of stroke
displacer_stroke_ratio = 0.55;    // stroke as fraction of usable bore depth
/* [Hidden] */
$fn = 60; cyl_id = 100; cyl_wall_t = 0.40; cyl_h = 47; rod_od = 3; flange_od = 12; flange_t = 2.0;

// ==========================================
// 1. LTD OPTIMIZED THERMODYNAMIC CALCULATIONS
// ==========================================
sv_ratio = 40.0;
can_inner_d = cyl_id - 0.8; // matches tuna_tin_can() inner diameter
displacer_d = can_inner_d - 2 * displacer_radial_clearance;
disp_bore_depth = cyl_h - 2 * displacer_axial_clearance;
displacer_stroke = disp_bore_depth * displacer_stroke_ratio;
displacer_h = disp_bore_depth - displacer_stroke;
displacer_r = displacer_d / 2; displacer_area = 3.14159265 * displacer_r * displacer_r;
displacer_swept_vol = displacer_area * displacer_stroke;
power_swept_vol = displacer_swept_vol / sv_ratio; power_stroke = 12;
power_cyl_id = sqrt(power_swept_vol / (3.14159265 * 0.25 * power_stroke));
power_cyl_od = power_cyl_id + 4; power_cyl_h = power_stroke + 10;
power_piston_od = power_cyl_id - 0.15; power_piston_h = 8;
seal_od = 4.7; seal_id = 3.0; seal_h = 15;
displacer_crank_r = displacer_stroke / 2; power_crank_r = power_stroke / 2;         

axle_to_deck = 75; // Increased to 75 to completely clear the 140mm flywheel
disp_link_len = 40; power_link_len = 25; 
flywheel_d = 140; flywheel_w = 8; flywheel_collar_od = 10; flywheel_collar_h = 6;
frame_w = 30; frame_t = 5; slot_tolerance = 0.2; parts_y_axis = 0; 
left_support_x = -42; flywheel_x = -22; power_piston_x = 22; right_support_x = 42;

// ==========================================
// 2. SCAD GEOMETRY MODULES
// ==========================================
module bearing_pocket() {
    cylinder(d=8.2, h=4.1, center=false);
    translate([0, 0, -6]) cylinder(d=3.5, h=10, center=false);
}
module mounting_holes(h_len=20) {
    translate([0, -screw_pitch/2, -h_len/2]) cylinder(d=screw_d, h=h_len, center=false);
    translate([0, screw_pitch/2, -h_len/2]) cylinder(d=screw_d, h=h_len, center=false);
}
module insert_pockets() {
    insert_z = 4 - insert_depth;
    translate([0, -screw_pitch/2, insert_z])
        cylinder(d=insert_hole_d, h=insert_depth + 0.1, center=false);
    translate([0, screw_pitch/2, insert_z])
        cylinder(d=insert_hole_d, h=insert_depth + 0.1, center=false);
}
module support_frame() {
    difference() {
        union() {
            hull() {
                rotate([90, 0, 90]) cylinder(d=14, h=frame_t, center=true);
                translate([0, 0, -axle_to_deck + 2.5]) cube([frame_t, frame_w, 5], center=true);
            }
            rotate([90, 0, 90]) cylinder(d=14, h=frame_t, center=true);
        }
        rotate([90, 0, 90]) bearing_pocket();
        translate([0, 0, -axle_to_deck + 2.5]) mounting_holes(h_len=50);
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
module linkage_rod(length, pin_d=2) {
    disc_r = link_disc_d / 2;
    color("Silver")
        translate([0, 0, -length - disc_r - link_stick_bore_depth])
        cylinder(d=1.5, h=length + disc_r + 2 * link_stick_bore_depth, center=false);
    // Crank end: pin along X; stick into -Z rim
    link_end_disc(pin_d, stick_rim_z=-1);
    // Piston / flange end: same disc; stick into +Z rim (rod approaches from crank)
    translate([0, 0, -length]) link_end_disc(pin_d, stick_rim_z=1);
}
// collar_outward: +1 or -1, clamp extends away from web sandwich center only
module crank_arm(radius, pin_d=2, collar_outward=1) {
    collar_z0 = (collar_outward > 0) ? 0 : -collar_len;
    collar_z1 = (collar_outward > 0) ? collar_len : 0;
    collar_mid_z = (collar_z0 + collar_z1) / 2;
    bore_z0 = min(-1.5, collar_z0) - 0.5;
    bore_z1 = max(1.5, collar_z1) + 0.5;

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

module rod_flange(pin_d=2.0) {
    clevis_base_z = (flange_t + 2) / 2;
    pin_z = clevis_base_z + 4;
    color("Gold") difference() {
        union() {
            cylinder(d=flange_od, h=flange_t + 2, center=true);
            translate([0, 0, clevis_base_z]) {
                clevis_boss_round_top(-3, 4, tab_h=8);
                clevis_boss_round_top(3, 4, tab_h=8);
            }
        }
        translate([0, 0, -flange_t]) cylinder(d=2.5, h=flange_t + 1.5, center=false); // Blind screw hole
        translate([0, 0, pin_z]) rotate([0, 90, 0])
            cylinder(d=pin_d, h=flange_od + 2, center=true); // Pin along X (matches link_end_disc)
    }
}
module displacer() { color("LightBlue") cylinder(d=displacer_d, h=displacer_h, center=true); }
module power_piston(pin_d=1.5) {
    pin_z = power_piston_h / 2;
    boss_h = power_piston_h - 2;
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
module tuna_tin_can() {
    color("DarkGrey", 0.4) difference() {
        cylinder(d=100, h=cyl_h, center=false);
        translate([0, 0, 0.5]) cylinder(d=100 - 0.8, h=cyl_h + 1, center=false);
    }
}
module cold_plate() {
    difference() {
        union() {
            cylinder(d=106, h=4, center=false);
            translate([power_piston_x, parts_y_axis, 0]) cylinder(d=power_cyl_od + 4, h=5, center=false);
        }
        translate([0, 0, -0.5]) difference() { cylinder(d=101.5, h=2.5, center=false); cylinder(d=98.5, h=3.0, center=false); }
        translate([0, 0, -1]) cylinder(d=seal_od, h=10, center=false);
        translate([power_piston_x, parts_y_axis, -1]) cylinder(d=power_cyl_id, h=15, center=false);
        translate([left_support_x, parts_y_axis, 2]) cube([frame_t + slot_tolerance, frame_w + slot_tolerance, 2.5], center=true);
        translate([right_support_x, parts_y_axis, 2]) cube([frame_t + slot_tolerance, frame_w + slot_tolerance, 2.5], center=true);
        translate([left_support_x, parts_y_axis, 2]) mounting_holes(h_len=50);
        translate([right_support_x, parts_y_axis, 2]) mounting_holes(h_len=50);
        translate([left_support_x, parts_y_axis, 0]) insert_pockets();
        translate([right_support_x, parts_y_axis, 0]) insert_pockets();
    }
}
module flywheel_geom() {
    collar_z = flywheel_w / 2 + flywheel_collar_h / 2;
    difference() {
        union() {
            difference() { cylinder(d=flywheel_d, h=flywheel_w, center=true); cylinder(d=flywheel_d - 8, h=flywheel_w + 2, center=true); }
            cylinder(d=12, h=flywheel_w, center=true);
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

// ==========================================
// 3. MAIN PARAMETRIC LAYOUT ENGINE
// ==========================================
ez = (mode == "Exploded") ? explode_offset : 0;
engine_angle = (animate_engine == true) ? ($t * 360) : manual_angle;
disp_angle = engine_angle; 
piston_angle = engine_angle - 90; 

// Exact trigonometric tracking variables matching the physical rotation path
disp_pin_y = -displacer_crank_r * sin(disp_angle);
disp_pin_z = displacer_crank_r * cos(disp_angle);
piston_pin_y = -power_crank_r * sin(piston_angle);
piston_pin_z = power_crank_r * cos(piston_angle);

// Slider-crank: wrist joint Z for displacer rod flange (vertical constraint, Y=0)
disp_rod_joint_z = disp_pin_z - sqrt(pow(disp_link_len, 2) - pow(disp_pin_y, 2));

// Displacer vertical travel centered in tuna-can bore
disp_can_bottom_z = -axle_to_deck - cyl_h;
disp_can_top_z = -axle_to_deck - displacer_axial_clearance;
disp_z_min = disp_can_bottom_z + displacer_axial_clearance + displacer_h / 2;
disp_z_max = disp_can_top_z - displacer_axial_clearance - displacer_h / 2;
disp_center_mid_z = (disp_z_min + disp_z_max) / 2;
disp_center_z = disp_center_mid_z + (displacer_stroke / 2) * cos(disp_angle);
disp_top_z = disp_center_z + displacer_h / 2;
disp_flange_pin_z_offset = (flange_t + 2) / 2 + 4; // tab clevis pin height above flange center
disp_rod_attach_z = disp_rod_joint_z - 4.0; // top of steel displacer rod (blind hole in flange)
disp_rod_len = disp_rod_attach_z - disp_top_z;
// Linkage far-end link_end_disc pin is at disp_rod_joint_z (same as silver pin / flange hole)
disp_link_len_eff = sqrt(pow(disp_pin_y, 2) + pow(disp_pin_z - disp_rod_joint_z, 2));
disp_rot_x = atan2(disp_pin_y, disp_pin_z - disp_rod_joint_z);

// Power piston vertical travel inside power cylinder bore
power_piston_axial_clearance = 1;
power_cyl_base_z = -axle_to_deck + 4;
power_cyl_bore_top_z = power_cyl_base_z + power_cyl_h;
power_piston_base_min = power_cyl_base_z + power_piston_axial_clearance;
power_piston_base_max = power_cyl_bore_top_z - power_piston_axial_clearance - power_piston_h;
power_piston_base_mid = (power_piston_base_min + power_piston_base_max) / 2;
power_piston_base_z = power_piston_base_mid + (power_stroke / 2) * cos(piston_angle);
power_piston_pin_z = power_piston_base_z + power_piston_h / 2;
power_link_len_eff = sqrt(pow(piston_pin_y, 2) + pow(piston_pin_z - power_piston_pin_z, 2));
piston_rot_x = atan2(piston_pin_y, piston_pin_z - power_piston_pin_z);

if (mode == "Assembled" || mode == "Exploded") {
    // 1. DRIVE AXLE LEVEL (Z = 0) - MULTI-SEGMENT CRANKSHAFT ASSEMBLY
    translate([-shaft_seg_flywheel_h / 2, 0, 0]) rotate([0, 90, 0]) color("DimGrey") cylinder(d=rod_od, h=shaft_seg_flywheel_h, center=true);
    translate([flywheel_x, 0, 0]) rotate([engine_angle, 0, 0]) rotate([90, 0, 90]) flywheel_geom();
    translate([shaft_seg_mid_x, 0, 0]) rotate([0, 90, 0]) color("DimGrey") cylinder(d=rod_od, h=shaft_seg_mid_h, center=true);
    translate([shaft_seg_power_x, 0, 0]) rotate([0, 90, 0]) color("DimGrey") cylinder(d=rod_od, h=shaft_seg_power_h, center=true);
    
    // DISPLACER KINEMATICS (X = 0) - DUAL WEB SANDWICH CLUSTER
    translate([0, 0, 0]) {
        translate([-crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, disp_angle]) crank_arm(displacer_crank_r, collar_outward=-1);
        translate([crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, disp_angle]) crank_arm(displacer_crank_r, collar_outward=1);
        translate([0, disp_pin_y, disp_pin_z]) rotate([0, 90, 0]) color("Silver") cylinder(d=1.5, h=8, center=true);

translate([0, disp_pin_y, disp_pin_z]) rotate([-disp_rot_x, 0, 0]) linkage_rod(disp_link_len_eff, pin_d=1.5);
}
// POWER PISTON KINEMATICS (X = 22) - DUAL WEB SANDWICH CLUSTER
translate([power_piston_x, 0, 0]) {
translate([-crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, piston_angle]) crank_arm(power_crank_r, collar_outward=-1);
translate([crank_web_x, 0, 0]) rotate([90, 0, 90]) rotate([0, 0, piston_angle]) crank_arm(power_crank_r, collar_outward=1);
translate([0, piston_pin_y, piston_pin_z]) rotate([0, 90, 0]) color("Silver") cylinder(d=1.5, h=8, center=true);
translate([0, piston_pin_y, piston_pin_z]) rotate([-piston_rot_x, 0, 0]) linkage_rod(power_link_len_eff, pin_d=1.5);
}

// 2. CHASSIS MOUNT DECK (Spans downward to frame top beds)
translate([0, 0, -ez]) {
translate([left_support_x, parts_y_axis, 0]) support_frame();
translate([right_support_x, parts_y_axis, 0]) mirror([1, 0, 0]) support_frame();
translate([0, parts_y_axis, -axle_to_deck]) {
cold_plate();
translate([power_piston_x, parts_y_axis, 4]) power_cylinder();
}
}
// 3. INTERNAL ENGINE CAVITY (Pistons, clevis couplings, and pressure vessels)
translate([0, 0, -ez * 2]) {
// POWER PISTON CLUSTER WITH MECHANICAL HINGE PIN
translate([power_piston_x, parts_y_axis, power_piston_base_z]) {
power_piston(pin_d=1.5);
translate([0, 0, power_piston_h / 2]) rotate([0, 90, 0])
color("Silver") cylinder(d=1.5, h=power_piston_od + 1, center=true);
}
// DISPLACER ASSEMBLY WITH INTEGRATED CLEVIS HARDWARE
translate([0, parts_y_axis, 0]) {
translate([0, 0, disp_rod_joint_z - disp_flange_pin_z_offset]) rod_flange(pin_d=1.5);
translate([0, 0, disp_rod_joint_z]) rotate([0, 90, 0]) color("Silver") cylinder(d=1.5, h=14, center=true);
translate([0, 0, disp_rod_attach_z]) mirror([0, 0, 1])
displacer_rod(abs(disp_rod_len));
translate([0, 0, disp_center_z]) displacer();
}
translate([0, parts_y_axis, -axle_to_deck - cyl_h]) tuna_tin_can();
}
} else if (mode == "Individual") {
// FIXED: Shifted items down to Z=0 and added missing parameter signatures for print safety
// Flat on bed; insert pockets and power-cylinder boss toward +Z
translate([-65, -35, 0]) cold_plate();
translate([65, -35, 0]) power_cylinder();
translate([20, 35, 0]) power_piston(pin_d=1.5);
translate([-30, -75, 1.5]) rotate([0, 90, 0]) linkage_rod(disp_link_len, pin_d=1.5);
translate([30, -75, 1.5]) rotate([0, 90, 0]) linkage_rod(power_link_len, pin_d=1.5);
// Lay frame on bed; bearing pocket opening faces +Z (no overhang into pocket)
translate([-65, 55, 0]) rotate([90, 0, 0]) rotate([0, 0, 90]) support_frame();
translate([45, 50, flywheel_w/2]) flywheel_geom();
translate([0, -40, 1.25]) rotate([0, 180, 0]) crank_arm(displacer_crank_r, pin_d=1.5, collar_outward=-1);
translate([20, -40, 1.25]) crank_arm(power_crank_r, pin_d=1.5, collar_outward=1);
// Disc on bed, clevis tabs toward +Z (pin end up — no overhang into clevis)
translate([0, -75, (flange_t + 2) / 2]) rod_flange(pin_d=1.5);
}


