// Industry 401 metal food can + snap-over lid (pet-food style)
// Nominal 401 = 4 1/16 in (~103 mm class); finished double-seam rim typically 101.5–102 mm OD.
//
// Rim geometry (not a straight cone):
//   • BMT 3-piece 401 body: plug OD 98.93 mm, flange width 2.67 mm, flange radius 1.98–2.29 mm
//   • CFIA / industry: seam height (length) ≈ 2.8–3.5 mm parallel to can axis
//   • External profile: vertical body → short flange step → vertical seam wall → top curl

/* [Display] */
show = "Assembled"; // [Assembled, Can only, Lid only, Exploded]
show_y_section = false; // vertical cut at y=0 (XZ mid-plane)
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
lid_id = 101.0;           // mm; primary inner skirt ID (slip fit over seam)
lid_od = 103.0;           // mm; outer skirt OD
lid_skirt_h = 7.75;       // mm; internal skirt depth (7.5–8.0)
lid_panel_t = 2.0;        // mm; top panel thickness
bead_id = 99.75;          // mm; snap bead ID (99.5–100.0 under seam)
bead_z = 4.25;            // mm; bead centerline below inner ceiling (4.0–4.5)
bead_h = 1.2;             // mm; axial height of bead land
bead_chamfer = 45;        // deg; lead-in under bead

/* [Hidden] */
can_body_id = can_body_od - 2 * can_wall_t;
can_rim_id = can_rim_od - 2 * can_wall_t;
lid_r = lid_od / 2;
lid_ir = lid_id / 2;
bead_ir = bead_id / 2;
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
    color("DarkGrey", 0.45) difference() {
        union() {
            translate([0, 0, 0.25])
                cylinder(d=can_body_od, h=can_h - can_rim_h - 0.25, center=false);
            can401_rim_wall();
        }
        translate([0, 0, 0.5])
            cylinder(d=can_body_id, h=can_h + 1, center=false);
    }
}

// Skirt inner profile (radius, y); y=0 at inner ceiling on can rim, +y down the skirt
module lid_skirt_profile() {
    z_slip_end = bead_z0 - chamfer_drop;
    polygon([
        [lid_r, 0],
        [lid_r, lid_skirt_h],
        [bead_ir, lid_skirt_h],
        [bead_ir, bead_z1],
        [lid_ir, max(bead_z1 - chamfer_drop, z_slip_end)],
        [lid_ir, z_slip_end],
        [bead_ir, bead_z0],
        [bead_ir, 0],
        [lid_ir, 0]
    ]);
}

module can401_snap_lid() {
    color("Teal", 0.92) union() {
        // Solid top panel (full OD); bottom face (z=0) seats on can rim
        cylinder(d=lid_od, h=lid_panel_t, center=false);
        // Skirt + inward snap bead hang downward from panel underside
        rotate_extrude(convexity = 12)
            scale([1, -1, 1])
            lid_skirt_profile();
    }
}

module with_y_section() {
    if (show_y_section) {
        intersection() {
            children();
            translate([-section_half, 0, -section_half])
                cube([2 * section_half, section_half, 2 * section_half]);
        }
    } else {
        children();
    }
}

module can401_assembly(explode = 0) {
    can401_body();
    translate([0, 0, can_h + explode])
        can401_snap_lid();
}

// --- Layout ---
with_y_section() {
    if (show == "Can only") {
        can401_body();
    } else if (show == "Lid only") {
        translate([0, 0, can_h])
            can401_snap_lid();
    } else if (show == "Exploded") {
        can401_assembly(explode = 15);
    } else {
        can401_assembly(explode = 0);
    }
}
