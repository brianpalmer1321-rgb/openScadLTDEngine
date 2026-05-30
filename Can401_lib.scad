// Industry 401 metal food can + snap-over lid (library — no top-level geometry)
// Nominal 401 = 4 1/16 in (~103 mm class); finished double-seam rim typically 101.5–102 mm OD.
//
// Rim geometry (not a straight cone):
//   • BMT 3-piece 401 body: plug OD 98.93 mm, flange width 2.67 mm, flange radius 1.98–2.29 mm
//   • CFIA / industry: seam height (length) ≈ 2.8–3.5 mm parallel to can axis
//   • External profile: vertical body → short flange step → vertical seam wall → top curl

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

/* [Engine snap ring — TPU; mates cold plate to can (uses lid skirt grip)] */
ring_grip_z0 = 3.0;       // mm; profile z where can seam grip starts (plate-bottom reference)
ring_clamp_shelf_z = 2.0; // mm; inward shelf height on plate side of profile

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

function tan(deg) = sin(deg) / cos(deg);

function profile_max_z(profile) =
    len(profile) == 0 ? 0 : max([for (p = profile) p[1]]);

// Axial z (can coords, z=0 at bottom) where plate OD just touches inner rim wall.
function can401_cold_plate_seat_z(plate_od) = let(
    ri = can_body_id / 2,
    seam_ri = ri + 0.35,
    z_rim = can_h - can_rim_h,
    z_step = z_rim + can_flange_step_h,
    plate_r = plate_od / 2
) (plate_r <= ri) ? z_rim
  : (plate_r >= seam_ri) ? can_h
  : z_rim + (plate_r - ri) * (z_step - z_rim) / (seam_ri - ri);

// Lower cold plate until OD contacts rim; 0 if plate already spans full mouth ID.
function can401_cold_plate_drop(plate_od) = can_h - can401_cold_plate_seat_z(plate_od);

// Lid skirt meridional section [radius, z]; z=0 at panel underside, +z toward panel.
function lid_skirt_profile_points() = [
    [lid_r, 0],
    [lid_r, lid_skirt_h],
    [lid_ir, lid_skirt_h],
    [lid_ir, bead_z1 + chamfer_drop],
    [bead_ir, bead_z1],
    [bead_ir, bead_z0],
    [lid_ir, bead_z0],
    [lid_ir, 0]
];

// Engine TPU snap ring: plate hook + lid-skirt can grip (revolved [radius, z] profile).
// z=0 at foot (plate/can interface); +z toward can seam. Outer wall at lid_r.
function can401_engine_snap_ring_profile(plate_od, clamp_overhang, grip_z0 = ring_grip_z0) = let(
    hook_r = plate_od / 2 - clamp_overhang,
    foot_r = lid_r,
    z_top = grip_z0 + lid_skirt_h,
    z_bead0 = grip_z0 + bead_z0,
    z_bead1 = grip_z0 + bead_z1,
    z_chamfer = grip_z0 + bead_z1 + chamfer_drop
) [
    [hook_r, 0],
    [foot_r, 0],
    [foot_r, z_top],
    [lid_ir, z_top],
    [lid_ir, z_chamfer],
    [bead_ir, z_bead1],
    [bead_ir, z_bead0],
    [lid_ir, z_bead0],
    [lid_ir, grip_z0],
    [hook_r, ring_clamp_shelf_z]
];

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
    polygon(lid_skirt_profile_points());
}

module can401_engine_snap_ring(plate_od, clamp_overhang, grip_z0 = ring_grip_z0) {
    rotate_extrude(convexity = 12)
        polygon(can401_engine_snap_ring_profile(plate_od, clamp_overhang, grip_z0));
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
