// Industry 401 can + snap lid viewer (geometry in Can401_lib.scad)
include <Can401_lib.scad>

/* [Display] */
show = "Assembled"; // [Assembled, Can only, Lid only, Exploded]
show_y_section = false; // vertical cut at y=0 (XZ mid-plane)
can_color = "Silver";
lid_color = "Teal";
$fn = 80;

section_half = 250;

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
    color(can_color) can401_body();
    color(lid_color)
        translate([0, 0, can_h + explode])
        can401_snap_lid();
}

// --- Layout ---
with_y_section() {
    if (show == "Can only") {
        color(can_color) can401_body();
    } else if (show == "Lid only") {
        color(lid_color)
            translate([0, 0, can_h])
            can401_snap_lid();
    } else if (show == "Exploded") {
        can401_assembly(explode = 15);
    } else {
        can401_assembly(explode = 0);
    }
}
