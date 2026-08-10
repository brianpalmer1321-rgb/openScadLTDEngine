// Fusion snap ring profile test viewer (geometry synced from canSnapRingFusionExport.dxf)
include <Can401_lib.scad>

/* [Display] */
profile_source = "Both"; // [Fusion DXF synced, Parametric reference, Both]
show_y_section = true;   // vertical cut at y=0 (XZ mid-plane)
show_context = true;     // cold plate + can rim reference
ring_color = "Teal";
param_color = "Magenta";
$fn = 80;

/* [Cold plate reference — LTDEngine defaults] */
cold_plate_rim_clearance = 0.08;
cold_plate_t = 2.87;
ring_clamp_overhang = 3; // mm lip inward over cold-plate top
ring_wedge_compress = 0.30;

/* [Hidden] */
can_inner_d = can_body_od - 2 * can_wall_t;
can_mouth_id = can_inner_d + 0.7;
cold_plate_od = can_mouth_id - 2 * cold_plate_rim_clearance;
cold_plate_drop = can401_cold_plate_drop(cold_plate_od);
section_half = 250;

// Fusion snap ring profile from canSnapRingFusionExport.dxf (mm; DXF Y offset −6.24875 → z=0)
ring_fusion_y0 = 6.24875;
ring_fusion_profile = [
    [56.9445, 0],
    [57.9012, 0.190301],
    [58.7122, 0.732233],
    [59.2542, 1.54329],
    [59.4445, 2.5],
    [59.2542, 3.45671],
    [58.7122, 4.26777],
    [57.9012, 4.8097],
    [56.9445, 5],
    [56.9445, 10.3908],
    [57.9012, 10.5811],
    [58.7122, 11.1231],
    [59.2542, 11.9341],
    [59.4445, 12.8908],
    [59.2542, 13.8476],
    [58.7122, 14.6586],
    [57.9012, 15.2005],
    [56.9445, 15.3908],
    [55.9877, 15.2005],
    [55.1767, 14.6586],
    [54.6348, 13.8476],
    [54.4445, 12.8908],
    [49.692, 12.8908],
    [49.5017, 13.8476],
    [48.9597, 14.6586],
    [48.1487, 15.2005],
    [47.192, 15.3908],
    [46.2353, 15.2005],
    [45.4242, 14.6586],
    [44.8823, 13.8476],
    [44.692, 12.8908],
    [44.8823, 11.9341],
    [45.4242, 11.1231],
    [46.2353, 10.5811],
    [47.192, 10.3908],
    [47.192, 9.24875],
    [50.8852, 9.24875],
    [50.8852, 5.70463],
    [49.4695, 5.70463],
    [49.4695, 2.5],
    [49.4695, 2.5],
    [54.4445, 2.5],
    [54.6348, 1.54329],
    [55.1767, 0.732233],
    [55.9877, 0.190301]
];

function profile_max_z(profile) =
    len(profile) == 0 ? 0 : max([for (p = profile) p[1]]);

ring_fusion_t = profile_max_z(ring_fusion_profile);

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

module fusion_snap_ring() {
    color(ring_color)
        rotate_extrude(convexity = 12)
            polygon(ring_fusion_profile);
}

module parametric_snap_ring() {
    color(param_color, 0.35)
        can401_engine_snap_ring(
            cold_plate_od, cold_plate_drop, ring_clamp_overhang, ring_wedge_compress);
}

module context_geometry() {
    // Cold plate disc (plate-local z=0 at bottom)
    color("Silver", 0.5)
        cylinder(d=cold_plate_od, h=cold_plate_t, center=false);
    // Can mouth rim plane at z = cold_plate_drop
    translate([0, 0, cold_plate_drop])
        color("DarkGrey", 0.25)
            can401_rim_wall();
    // Brass seal tube bore reference
    translate([0, 0, -1])
        color("Gold", 0.4)
            difference() {
                cylinder(h=15, d=4.7, center=false);
                translate([0, 0, -0.5]) cylinder(h=16, d=3.0, center=false);
            }
}

with_y_section() {
    if (show_context)
        context_geometry();

    if (profile_source == "Fusion DXF synced" || profile_source == "Both")
        fusion_snap_ring();

    if (profile_source == "Parametric reference" || profile_source == "Both")
        parametric_snap_ring();
}

echo(str("Fusion profile: height=", ring_fusion_t, " mm  OD=",
    2 * max([for (p = ring_fusion_profile) p[0]]), " mm  vertices=",
    len(ring_fusion_profile)));
