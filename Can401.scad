// Industry 401 metal food can + snap-over lid (pet-food style)
// Nominal 401 = 4 1/16 in (~103 mm class); finished double-seam rim typically 101.5–102 mm OD.
//
// Rim geometry (not a straight cone):
//   • BMT 3-piece 401 body: plug OD 98.93 mm, flange width 2.67 mm, flange radius 1.98–2.29 mm
//   • CFIA / industry: seam height (length) ≈ 2.8–3.5 mm parallel to can axis
//   • External profile: vertical body → short flange step → vertical seam wall → top curl

/* [Display] */
show = "Assembled"; // [Assembled, Can only, Lid only, Exploded]
show_y_section = false; // F5: highlighted caps; F6 Render: true can_section_color / lid_section_color
can_color = "Silver";           // can exterior
lid_color = "Teal";             // lid exterior
can_section_color = [0.75, 0.60, 0.35];    // can cut-face (metal tan); use F6 to preview
lid_section_color = [0.85, 0.28, 0.22];    // lid cut-face (TPU red); use F6 to preview
section_cap_t = 0.35; // mm; cap slab thickness on y=0 plane
$fn = 80;

/* [401 Can body] */
can_body_od = 98.93;      // mm; BMT body plug OD for 401×305 (straight-sided 3-piece)
can_rim_od = 101.75;      // mm; diameter over double seam (101.5–102.0 typical)
can_rim_h = 3.15;         // mm; seam height / length (2.8–3.5 per CFIA)
can_flange_step_h = 0.55; // mm; short outward bend before vertical seam wall
can_curl_h = 0.35;        // mm; rolled top lip above main seam wall
can_curl_drop = 0.12;     // mm; slight inset at outer lip (folded end curl)
can_wall_t = 0.21;        // mm; tinplate gauge (401 EOE spec ~0.21)
can_h = 47.0;             // mm; overall height (LTD engine default)

/* [Snap lid — TPU/PP] */
lid_slip_clearance = 0.25; // mm per side over seam OD (rigid preview gap)
lid_id = can_rim_od + 2 * lid_slip_clearance; // mm; skirt ID clears double seam
lid_od = lid_id + 2.0;    // mm; outer skirt OD (wall ~1 mm per side)
lid_skirt_h = 7.75;       // mm; internal skirt depth (7.5–8.0)
lid_panel_t = 2.0;        // mm; top panel thickness
bead_id = 99.75;          // mm; snap bead ID (99.5–100.0 under seam)
bead_below_seam = 0.0;    // mm; extra offset; 0 = bead starts at seam base
bead_h = 1.2;             // mm; axial height of bead land
bead_chamfer = 45;        // deg; 45° lead-in on bottom edge of snap bead (press-on)

/* [Hidden] */
can_body_id = can_body_od - 2 * can_wall_t;
can_rim_id = can_rim_od - 2 * can_wall_t;
lid_r = lid_od / 2;
lid_ir = lid_id / 2;
bead_ir = bead_id / 2;
bead_z = can_rim_h + bead_h / 2 + bead_below_seam; // center in seam; bottom at seam base when offset=0
bead_z0 = bead_z - bead_h / 2;
bead_z1 = bead_z0 + bead_h;
chamfer_drop = (lid_ir - bead_ir) * tan(bead_chamfer);
section_half = 250;

function tan(deg) = sin(deg) / cos(deg);

// External wall profile [radius, z]: vertical body, short flange step, vertical seam, top curl.
function can401_outer_profile() = let(
    rb = can_body_od / 2,
    rs = can_rim_od / 2,
    z_rim = can_h - can_rim_h,
    z_step = z_rim + can_flange_step_h,
    z_wall_top = can_h - can_curl_h
) [
    [rb, z_rim],
    [rb + (rs - rb) * 0.22, z_rim + can_flange_step_h * 0.18],
    [rb + (rs - rb) * 0.72, z_rim + can_flange_step_h * 0.55],
    [rs, z_step],
    [rs, z_wall_top],
    [rs - can_curl_drop, can_h],
    [rs, can_h]
];

// Closed rim-wall ring for rotate_extrude (outer up, inner down).
function can401_rim_wall_profile() = let(
    rb = can_body_od / 2,
    ri = can_body_id / 2,
    z_rim = can_h - can_rim_h,
    z_step = z_rim + can_flange_step_h,
    seam_ri = ri + 0.35
) concat(
    can401_outer_profile(),
    [[seam_ri, can_h + 0.05], [seam_ri, z_step], [ri, z_rim]]
);

module can401_rim_wall() {
    rotate_extrude(convexity = 8)
        polygon(can401_rim_wall_profile());
}

module can401_body() {
    difference() {
        union() {
            translate([0, 0, 0.25])
                cylinder(d=can_body_od, h=can_h - can_rim_h - 0.25, center=false);
            can401_rim_wall();
        }
        translate([0, 0, 0.5])
            cylinder(d=can_body_id, h=can_h + 1, center=false);
    }
}

// Slip wall at lid_ir from panel to bead; 45° chamfer below bead (y+) wedges over can rim.
module lid_skirt_profile() {
    polygon([
        [lid_r, 0],
        [lid_r, lid_skirt_h],
        [lid_ir, lid_skirt_h],
        [lid_ir, bead_z1 + chamfer_drop],
        [bead_ir, bead_z1],
        [bead_ir, bead_z0],
        [lid_ir, bead_z0],
        [lid_ir, 0]
    ]);
}

module can401_snap_lid() {
    union() {
        // Solid top panel; bottom face (z=0) seats on can rim top
        cylinder(d=lid_od, h=lid_panel_t, center=false);
        // Skirt hangs from panel underside only (avoids z=0 overlap with panel)
        translate([0, 0, -0.001])
            rotate_extrude(convexity = 12)
            scale([1, -1, 1])
            lid_skirt_profile();
    }
}

module clip_y_positive() {
    intersection() {
        children();
        translate([-section_half, 0, -section_half])
            cube([2 * section_half, section_half, 2 * section_half]);
    }
}

// Colored slab centered on y=0 (OpenSCAD 2021 cannot tint CSG cut faces per part in F5).
module y_section_cap(section_color) {
    if ($preview) {
        // F5: highlight so can/lid caps differ from default tan
        # color(section_color)
            intersection() {
                render() children();
                translate([-section_half, -section_cap_t / 2, -section_half])
                    cube([2 * section_half, section_cap_t, 2 * section_half]);
            }
    } else {
        color(section_color)
            intersection() {
                render() children();
                translate([-section_half, -section_cap_t / 2, -section_half])
                    cube([2 * section_half, section_cap_t, 2 * section_half]);
            }
    }
}

module with_y_section(part_color, section_color, alpha = 0.9) {
    if (show_y_section) {
        union() {
            color(part_color, alpha)
                if ($preview)
                    clip_y_positive() children();
                else
                    difference() {
                        children();
                        translate([-section_half, -section_half, -section_half])
                            cube([2 * section_half, section_half, 2 * section_half]);
                    }
            y_section_cap(section_color)
                children();
        }
    } else {
        color(part_color, alpha)
            children();
    }
}

module can401_assembly(explode = 0) {
    with_y_section(can_color, can_section_color, 0.85)
        can401_body();
    with_y_section(lid_color, lid_section_color, 0.92)
        translate([0, 0, can_h + explode])
        can401_snap_lid();
}

// --- Layout ---
if (show == "Can only") {
    with_y_section(can_color, can_section_color, 0.85)
        can401_body();
} else if (show == "Lid only") {
    with_y_section(lid_color, lid_section_color, 0.92)
        translate([0, 0, can_h])
        can401_snap_lid();
} else if (show == "Exploded") {
    can401_assembly(explode = 15);
} else {
    can401_assembly(explode = 0);
}
