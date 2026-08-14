// Rotary foam cutter for the LTDEngine displacer disc.
//
// Print support-free: flange + twist bars on the bed, tall blade + teeth pointing up.
// Use: flip so teeth face the foam. Wall height = handle_h + displacer_h so the foam
// sheet clears the back bars after cutting through a full-thickness displacer blank.
//
// Foam plug OD ≈ displacer_d (same sizing defaults as LTDEngine.scad).
// $fn=100 avoids slicer bed-triangle artifacts.

/* [Displacer sizing — match LTDEngine.scad] */
can_body_od = 98.93;              // mm; BMT body plug OD
can_wall_t = 0.21;                // mm; tinplate wall
displacer_radial_clearance = 1.5; // mm gap to can wall (each side)
displacer_axial_clearance = 2;    // mm at top and bottom of stroke
displacer_stroke_ratio = 0.55;    // stroke as fraction of usable bore depth
cyl_h = 47;                       // mm; can height (must match LTDEngine)
cut_d_offset = 0; // [-1:0.1:1] mm; + = larger foam disc than displacer_d

/* [Cutter body] */
wall_t = 1.6;           // mm; blade wall thickness
flange_w = 7;           // mm; grip flange radial width beyond blade OD
base_t = 3.5;           // mm; bed-layer thickness (flange + twist bars)
handle_w = 12;          // mm; twist-bar width
handle_h = 14;          // mm; extra wall above foam thickness (grip / clearance)
guide_hole = true;      // center hole for optional guide pin / displacer shaft
rod_od = 3;             // mm; guide pin diameter (friction fit)

/* [Saw teeth] */
n_teeth = 56;           // [24:4:96] tooth count around circumference
tooth_h = 4;            // mm; tooth height into foam
tooth_tip_t = 0.35;     // mm; tip land thickness
rake_deg = 28;          // [0:5:45] deg; forward rake in twist direction

/* [Hidden] */
$fn = 100; // keeps slicer bed clean (tested)
can_inner_d = can_body_od - 2 * can_wall_t;
displacer_d = can_inner_d - 2 * displacer_radial_clearance;
disp_bore_depth = cyl_h - 2 * displacer_axial_clearance;
displacer_h = disp_bore_depth * (1 - displacer_stroke_ratio);
cut_d = displacer_d + cut_d_offset;
cut_r = cut_d / 2;
outer_r = cut_r + wall_t;
flange_or = outer_r + flange_w;
// Tall blade: foam thickness + grip/clearance so sheet never hits the back bars
wall_h = handle_h + displacer_h;
tooth_pitch_a = 360 / n_teeth;
mid_r = cut_r + wall_t / 2;
tooth_chord = 2 * mid_r * sin(tooth_pitch_a / 2);

module cutter_wall() {
    difference() {
        cylinder(d=2 * outer_r, h=wall_h, center=false);
        translate([0, 0, -0.1])
            cylinder(d=2 * cut_r, h=wall_h + 0.2, center=false);
    }
}

// Tooth at +X: +X radial (matches wall), +Y tangent (twist), +Z into foam.
module saw_tooth() {
    y0 = -tooth_chord * 0.25;
    y1 = tooth_chord * 0.35;
    y_tip = tooth_chord * 0.15 + tooth_h * tan(rake_deg);
    hull() {
        translate([cut_r, y0, -0.3])
            cube([wall_t, 0.25, 0.4], center=false);
        translate([cut_r, y1, -0.3])
            cube([wall_t, 0.25, 0.4], center=false);
        translate([mid_r - tooth_tip_t / 2, y_tip, tooth_h - 0.2])
            cube([tooth_tip_t, 0.25, 0.2], center=false);
    }
}

module saw_rim() {
    for (i = [0:n_teeth - 1])
        rotate([0, 0, i * tooth_pitch_a])
            saw_tooth();
}

// Single bed layer: outer flange ring + twist bars (all supported by the bed).
module bed_base() {
    bar_len = 2 * (flange_or - 2);
    hub_d = max(handle_w * 1.8, rod_od + 5);
    union() {
        // Outer grip flange (outside the blade OD)
        difference() {
            cylinder(d=2 * flange_or, h=base_t, center=false);
            translate([0, 0, -0.1])
                cylinder(d=2 * outer_r, h=base_t + 0.2, center=false);
        }
        // Twist bars + hub — on the bed, spanning the open center
        translate([0, 0, base_t / 2]) {
            cube([bar_len, handle_w, base_t], center=true);
            cube([handle_w, bar_len, base_t], center=true);
            cylinder(d=hub_d, h=base_t, center=true);
        }
    }
}

module displacer_foam_cutter() {
    // Support-free stack: bed base → tall wall (handle_h + displacer_h) → teeth
    difference() {
        union() {
            bed_base();
            // Wall grows from the bed; annulus merges with flange / bar roots
            cutter_wall();
            translate([0, 0, wall_h])
                saw_rim();
        }
        if (guide_hole)
            translate([0, 0, -1])
                cylinder(d=rod_od, h=base_t + 2, center=false);
    }
}

displacer_foam_cutter();

echo(str("Displacer OD (target): ", displacer_d, " mm"));
echo(str("Displacer thickness h: ", displacer_h, " mm"));
echo(str("Wall height (handle_h + displacer_h): ", wall_h, " mm"));
echo(str("Cutter ID / foam plug: ", cut_d, " mm  (cut_d_offset=", cut_d_offset, ")"));
echo(str("Teeth: ", n_teeth, " × ", tooth_h, " mm, rake ", rake_deg, "°"));
