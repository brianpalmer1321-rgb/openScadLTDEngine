"""
LTDEngine — Fusion 360 script (port of LTDEngine.scad + Can401_lib.scad)

Low Temperature Differential Stirling engine around an industry 401 food can.
Coordinate system matches OpenSCAD: Z up, crankshaft along +X, Y lateral.

Run: Utilities → Scripts and Add-Ins → Scripts → Run (open a Design document first)

Works in both Part and Assembly designs. Part documents build all bodies in the
root component and move them into position; Assembly documents use sub-components.

Edit MODE and MANUAL_ANGLE below, then re-run. Fusion has no $t animation loop;
use MANUAL_ANGLE to inspect kinematics at a given crank position.
"""

import adsk.core
import adsk.fusion
import traceback
import math

SCRIPT_VERSION = "LTDEngine-v2.5"

# =============================================================================
# Customizer-equivalent parameters (millimetres unless noted)
# =============================================================================

MODE = "Assembled"          # Assembled | Exploded
MANUAL_ANGLE = 45.0         # degrees; used when not animating
EXPLODE_OFFSET = 50.0       # mm

# Hot cylinder / can
CAN_BODY_OD = 98.93
CAN_WALL_T = 0.21
CYL_H = 47.0
CAN_RIM_OD = 101.75
CAN_RIM_H = 3.15
CAN_FLANGE_STEP_H = 0.55
CAN_CURL_H = 0.35
CAN_CURL_DROP = 0.12

# Layout & cranktrain
AXLE_TO_DECK = 80.0
FLYWHEEL_D = 140.0
FLYWHEEL_W = 8.0
FLYWHEEL_COLLAR_OD = 10.0
FLYWHEEL_COLLAR_H = 6.0
LEFT_SUPPORT_X = -40.0
FLYWHEEL_X = -22.0
POWER_PISTON_X = 22.0
RIGHT_SUPPORT_X = 40.0
DISP_LINK_LEN = 40.0
POWER_STROKE = 12.0
POWER_PISTON_H = 16.0
POWER_PISTON_WALL_T = 1.0
POWER_PISTON_RADIAL_CLEARANCE = 0.4
POWER_PISTON_CLEVIS_X = 3.0
SV_RATIO = 40.0

# Hardware
PIN_D = 1.5
ROD_OD = 3.0
SCREW_D = 3.2
FRAME_FOOT_PAD_W = 8.0
FRAME_STEM_Y_W = 14.0
FRAME_MOUNT_TAP_D = 2.5
FRAME_MOUNT_TAP_DEPTH = 4.5
SETSCREW_D = 2.5
COLLAR_OD = 10.0
COLLAR_LEN = 5.0
BEARING_OD = 8.0
BEARING_TH = 4.0
BEARING_POCKET_CLEARANCE = 0.2
SEAL_OD = 4.7
SEAL_ID = 3.0
SEAL_H = 15.0
LINK_DISC_D = 8.0
LINK_STICK_PIN_GAP = 0.5
CLEVIS_TAB_X = 2.0
CLEVIS_TAB_CENTER_X = 3.0
CRANK_WEB_T = 2.5
CRANK_WEB_GAP = 3.4
SHAFT_SEG_GAP = 0.5

# Displacer
DISPLACER_RADIAL_CLEARANCE = 1.5
DISPLACER_AXIAL_CLEARANCE = 2.0
DISPLACER_STROKE_RATIO = 0.55

# Cold side
COLD_PLATE_RIM_CLEARANCE = 0.08
COLD_PLATE_T = 2.87
COLD_PLATE_CUP_DEPTH = 0.0
RING_CLAMP_OVERHANG = 2.5
RING_WEDGE_COMPRESS = 0.30
RING_Z_OFFSET = -4.7  # mm; assembled Z nudge after flip (negative = toward can)

# Hidden / fixed
PARTS_Y_AXIS = 0.0
POWER_PISTON_AXIAL_CLEARANCE = 1.0
FLANGE_OD = 12.0
FLANGE_T = 2.0
POWER_CYL_BOSS_H = 5.0
FRAME_W = 30.0
FRAME_T = 5.0
SHAFT_TUBE_BEARING_GAP = 0.5
FRAME_FOOT_H = 5.0

# Can401 lid constants (snap ring profile)
LID_SLIP_CLEARANCE = 0.25
LID_OD = CAN_RIM_OD + 2 * LID_SLIP_CLEARANCE + 2.0  # lid_id + 2mm wall each side
LID_ID = CAN_RIM_OD + 2 * LID_SLIP_CLEARANCE
LID_SKIRT_H = 7.75
BEAD_ID = 99.75
BEAD_H = 1.2
BEAD_BELOW_SEAM = 0.0
BEAD_CHAMFER = 45.0

# =============================================================================
# Unit helpers — Fusion internal units are centimetres
# =============================================================================

def mm(v):
    return v * 0.1


def _val(v_mm):
    return adsk.core.ValueInput.createByReal(mm(v_mm))


def _body_count(comp):
    return comp.bRepBodies.count


def _single_new_body(comp, count_before):
    if comp.bRepBodies.count <= count_before:
        return None
    return comp.bRepBodies.item(comp.bRepBodies.count - 1)


def _as_body(obj):
    if obj is None:
        return None
    # BRepBody exposes faces; ExtrudeFeature does not.
    if hasattr(obj, "faces") and hasattr(obj, "isSolid"):
        return obj
    if hasattr(obj, "bodies") and obj.bodies.count > 0:
        return obj.bodies.item(0)
    return None


def _combine_cut(comp, target, tool):
    target_b = _as_body(target)
    tool_b = _as_body(tool)
    if not target_b or not tool_b:
        return target_b
    tools = adsk.core.ObjectCollection.create()
    tools.add(tool_b)
    inp = comp.features.combineFeatures.createInput(target_b, tools)
    inp.operation = adsk.fusion.FeatureOperations.CutFeatureOperation
    comp.features.combineFeatures.add(inp)
    return target_b


def _cut_extrude(comp, profile, depth_mm, target):
    """Create a solid tool from a profile, then subtract it from target."""
    n = _body_count(comp)
    ext_in = comp.features.extrudeFeatures.createInput(
        profile, adsk.fusion.FeatureOperations.NewBodyFeatureOperation,
    )
    if depth_mm >= 0:
        ext_in.setDistanceExtent(False, _val(depth_mm))
    else:
        ext_in.setDistanceExtent(True, _val(depth_mm))
    comp.features.extrudeFeatures.add(ext_in)
    tool = _single_new_body(comp, n)
    return _combine_cut(comp, target, tool)


def _deg(v):
    return adsk.core.ValueInput.createByReal(v)


# =============================================================================
# Derived geometry (mirrors LTDEngine.scad)
# =============================================================================

class Derived:
    pass


def compute_derived():
    d = Derived()
    d.can_body_id = CAN_BODY_OD - 2 * CAN_WALL_T
    d.can_inner_d = d.can_body_id
    d.can_mouth_id = d.can_inner_d + 0.7
    d.cold_plate_od = d.can_mouth_id - 2 * COLD_PLATE_RIM_CLEARANCE
    d.cold_plate_drop = _can401_cold_plate_drop(d.cold_plate_od)
    d.cold_plate_top_z = -AXLE_TO_DECK
    d.cold_plate_bottom_z = d.cold_plate_top_z - COLD_PLATE_T
    d.can_top_z = d.cold_plate_bottom_z + d.cold_plate_drop
    d.snap_ring_t = d.cold_plate_drop + LID_SKIRT_H  # matches can401_engine_snap_ring_profile max z

    d.link_stick_bore_d = PIN_D + 0.15
    d.bearing_pocket_od = BEARING_OD + BEARING_POCKET_CLEARANCE
    d.bearing_pocket_h = BEARING_TH + 0.1
    d.bearing_shaft_hole_d = ROD_OD + 0.5
    d.bearing_inboard_t = d.bearing_pocket_h
    d.flywheel_hub_od = ROD_OD + 9.0
    d.crank_pin_show_len = LINK_DISC_D

    d.displacer_d = d.can_inner_d - 2 * DISPLACER_RADIAL_CLEARANCE
    d.disp_bore_depth = CYL_H - 2 * DISPLACER_AXIAL_CLEARANCE
    d.displacer_stroke = d.disp_bore_depth * DISPLACER_STROKE_RATIO
    d.displacer_h = d.disp_bore_depth - d.displacer_stroke
    d.displacer_swept_vol = math.pi * (d.displacer_d / 2) ** 2 * d.displacer_stroke

    d.power_swept_vol = d.displacer_swept_vol / SV_RATIO
    d.power_cyl_id = math.sqrt(d.power_swept_vol / (math.pi * 0.25 * POWER_STROKE))
    d.power_cyl_od = d.power_cyl_id + 4.0
    d.power_cyl_h = POWER_STROKE + POWER_PISTON_H + 2 * POWER_PISTON_AXIAL_CLEARANCE
    d.power_piston_od = d.power_cyl_id - 2 * POWER_PISTON_RADIAL_CLEARANCE
    d.power_piston_cup_id = d.power_piston_od - 2 * POWER_PISTON_WALL_T
    d.power_piston_pin_len = 2 * (POWER_PISTON_CLEVIS_X + CLEVIS_TAB_X / 2)
    d.power_piston_clevis_boss_h = 6.0

    d.displacer_crank_r = d.displacer_stroke / 2
    d.power_crank_r = POWER_STROKE / 2
    d.disp_can_top_z = d.can_top_z - DISPLACER_AXIAL_CLEARANCE
    d.disp_can_bottom_z = d.can_top_z - CYL_H
    d.disp_z_min = d.disp_can_bottom_z + DISPLACER_AXIAL_CLEARANCE + d.displacer_h / 2
    d.disp_z_max = d.disp_can_top_z - DISPLACER_AXIAL_CLEARANCE - d.displacer_h / 2
    d.disp_center_mid_z = (d.disp_z_min + d.disp_z_max) / 2
    d.power_cyl_base_z = d.cold_plate_top_z
    d.power_cyl_bore_top_z = d.power_cyl_base_z + d.power_cyl_h
    d.power_piston_base_min = d.power_cyl_base_z + POWER_PISTON_AXIAL_CLEARANCE
    d.power_piston_base_max = d.power_cyl_bore_top_z - POWER_PISTON_AXIAL_CLEARANCE - POWER_PISTON_H
    d.power_piston_base_mid = (d.power_piston_base_min + d.power_piston_base_max) / 2
    d.disp_rod_blind_depth = 4.0

    disp_rod_joint_z_nom = d.displacer_crank_r - DISP_LINK_LEN
    disp_rod_attach_z_nom = disp_rod_joint_z_nom - d.disp_rod_blind_depth
    disp_top_z_nom = d.disp_center_mid_z + d.displacer_stroke / 2 + d.displacer_h / 2
    d.displacer_shaft_len = disp_rod_attach_z_nom - disp_top_z_nom
    d.power_link_len = abs(
        d.power_crank_r
        - (d.power_piston_base_mid + POWER_STROKE / 2 + POWER_PISTON_H / 2)
    )

    d.crank_web_x = CRANK_WEB_GAP / 2 + CRANK_WEB_T / 2
    d.crank_web_outer = d.crank_web_x + CRANK_WEB_T / 2
    d.crank_web_inner = d.crank_web_x - CRANK_WEB_T / 2
    d.disp_web_l_out = -d.crank_web_outer
    d.disp_web_l_in = -d.crank_web_inner
    d.disp_web_r_in = d.crank_web_inner
    d.disp_web_r_out = d.crank_web_outer
    d.pwr_web_l_out = POWER_PISTON_X - d.crank_web_outer
    d.pwr_web_l_in = POWER_PISTON_X - d.crank_web_inner
    d.pwr_web_r_in = POWER_PISTON_X + d.crank_web_inner
    d.pwr_web_r_out = POWER_PISTON_X + d.crank_web_outer

    d.shaft_seg_flywheel_left = LEFT_SUPPORT_X
    d.shaft_seg_flywheel_right = d.disp_web_l_out - SHAFT_SEG_GAP
    d.shaft_seg_mid_left = d.disp_web_r_out + SHAFT_SEG_GAP
    d.shaft_seg_mid_right = d.pwr_web_l_out - SHAFT_SEG_GAP
    d.shaft_seg_power_left = d.pwr_web_r_out + SHAFT_SEG_GAP
    d.shaft_seg_power_right = RIGHT_SUPPORT_X
    d.shaft_seg_flywheel_h = d.shaft_seg_flywheel_right - d.shaft_seg_flywheel_left
    d.shaft_seg_mid_h = d.shaft_seg_mid_right - d.shaft_seg_mid_left
    d.shaft_seg_power_h = d.shaft_seg_power_right - d.shaft_seg_power_left
    d.shaft_tube_id = ROD_OD + 0.2

    d.flywheel_hub_l_x = FLYWHEEL_X - FLYWHEEL_W / 2
    d.flywheel_hub_r_x = FLYWHEEL_X + FLYWHEEL_W / 2
    d.flywheel_collar_r_x = d.flywheel_hub_r_x + FLYWHEEL_COLLAR_H
    d.disp_collar_l_face = -d.crank_web_x - COLLAR_LEN
    d.disp_collar_r_face = d.crank_web_x + COLLAR_LEN
    d.pwr_collar_l_face = POWER_PISTON_X - d.crank_web_x - COLLAR_LEN
    d.pwr_collar_r_face = POWER_PISTON_X + d.crank_web_x + COLLAR_LEN
    d.left_bearing_inboard_x = LEFT_SUPPORT_X + d.bearing_inboard_t
    d.right_bearing_inboard_x = RIGHT_SUPPORT_X - d.bearing_inboard_t

    d.shaft_tube_pwr_frame_x0 = d.pwr_collar_r_face
    d.shaft_tube_pwr_frame_x1 = d.right_bearing_inboard_x - SHAFT_TUBE_BEARING_GAP
    d.shaft_tube_pwr_disp_x0 = d.disp_collar_r_face
    d.shaft_tube_pwr_disp_x1 = d.pwr_collar_l_face
    d.shaft_tube_disp_fly_x0 = d.flywheel_collar_r_x
    d.shaft_tube_disp_fly_x1 = d.disp_collar_l_face
    d.shaft_tube_fly_frame_x0 = d.left_bearing_inboard_x + SHAFT_TUBE_BEARING_GAP
    d.shaft_tube_fly_frame_x1 = d.flywheel_hub_l_x

    d.clevis_pin_len = 2 * (CLEVIS_TAB_CENTER_X + CLEVIS_TAB_X / 2)
    d.disp_flange_pin_z_offset = (FLANGE_T + 2) / 2 + 4.0
    d.frame_foot_y = (FRAME_W - FRAME_FOOT_PAD_W) / 2
    d.link_stick_reach = LINK_DISC_D / 2 - PIN_D / 2 - LINK_STICK_PIN_GAP

    bead_z = CAN_RIM_H + BEAD_H / 2 + BEAD_BELOW_SEAM
    d.bead_z0 = bead_z - BEAD_H / 2
    d.bead_z1 = d.bead_z0 + BEAD_H
    d.chamfer_drop = (LID_ID / 2 - BEAD_ID / 2) * math.tan(math.radians(BEAD_CHAMFER))

    return d


def _can401_cold_plate_seat_z(plate_od):
    ri = (CAN_BODY_OD - 2 * CAN_WALL_T) / 2
    seam_ri = ri + 0.35
    z_rim = CYL_H - CAN_RIM_H
    z_step = z_rim + CAN_FLANGE_STEP_H
    plate_r = plate_od / 2
    if plate_r <= ri:
        return z_rim
    if plate_r >= seam_ri:
        return CYL_H
    return z_rim + (plate_r - ri) * (z_step - z_rim) / (seam_ri - ri)


def _can401_cold_plate_drop(plate_od):
    return CYL_H - _can401_cold_plate_seat_z(plate_od)


def _can401_outer_profile():
    rb = CAN_BODY_OD / 2
    rs = CAN_RIM_OD / 2
    z_rim = CYL_H - CAN_RIM_H
    z_step = z_rim + CAN_FLANGE_STEP_H
    z_wall_top = CYL_H - CAN_CURL_H
    return [
        (rb, z_rim),
        (rb + (rs - rb) * 0.22, z_rim + CAN_FLANGE_STEP_H * 0.18),
        (rb + (rs - rb) * 0.72, z_rim + CAN_FLANGE_STEP_H * 0.55),
        (rs, z_step),
        (rs, z_wall_top),
        (rs - CAN_CURL_DROP, CYL_H),
        (rs, CYL_H),
    ]


def _can401_rim_wall_profile():
    rb = CAN_BODY_OD / 2
    ri = CAN_BODY_OD / 2 - CAN_WALL_T
    z_rim = CYL_H - CAN_RIM_H
    z_step = z_rim + CAN_FLANGE_STEP_H
    seam_ri = ri + 0.35
    return _can401_outer_profile() + [
        (seam_ri, CYL_H + 0.05),
        (seam_ri, z_step),
        (ri, z_rim),
    ]


def _can401_snap_ring_profile(plate_od, plate_drop, clamp_overhang, wedge_compress):
    """Full OpenSCAD profile (may self-touch at z=0; not used directly in Fusion)."""
    plate_r = plate_od / 2
    clamp_ir = plate_r - clamp_overhang
    ri = (CAN_BODY_OD - 2 * CAN_WALL_T) / 2
    seam_ri = ri + 0.35
    wedge_r = seam_ri - wedge_compress
    z_mouth = plate_drop
    z_top = plate_drop + LID_SKIRT_H
    bead_z0 = plate_drop + (CAN_RIM_H + BEAD_H / 2 + BEAD_BELOW_SEAM - BEAD_H / 2)
    bead_z1 = bead_z0 + BEAD_H
    chamfer_drop = (LID_ID / 2 - BEAD_ID / 2) * math.tan(math.radians(BEAD_CHAMFER))
    z_chamfer = plate_drop + bead_z1 + chamfer_drop
    return [
        (clamp_ir, 0),
        (LID_OD / 2, 0),
        (LID_OD / 2, z_top),
        (LID_ID / 2, z_top),
        (LID_ID / 2, z_chamfer),
        (BEAD_ID / 2, bead_z1),
        (BEAD_ID / 2, bead_z0),
        (LID_ID / 2, bead_z0),
        (LID_ID / 2, z_mouth),
        (wedge_r, z_mouth),
        (plate_r, z_mouth),
        (plate_r, 0),
    ]


def _can401_snap_ring_wedge_profile(plate_od, plate_drop, clamp_overhang, wedge_compress):
    """Inner TPU wedge at plate seat — simple closed loop for Fusion revolve."""
    plate_r = plate_od / 2
    clamp_ir = plate_r - clamp_overhang
    ri = (CAN_BODY_OD - 2 * CAN_WALL_T) / 2
    wedge_r = ri + 0.35 - wedge_compress
    z_mouth = plate_drop
    return [
        (clamp_ir, 0),
        (clamp_ir, z_mouth),
        (wedge_r, z_mouth),
        (plate_r, z_mouth),
        (plate_r, 0),
    ]


def _can401_snap_ring_skirt_profile(plate_od, plate_drop):
    """Outer lid-skirt grip above the mouth — avoids z=0 profile overlap."""
    plate_r = plate_od / 2
    z_mouth = plate_drop
    z_top = plate_drop + LID_SKIRT_H
    bead_z0 = plate_drop + (CAN_RIM_H + BEAD_H / 2 + BEAD_BELOW_SEAM - BEAD_H / 2)
    bead_z1 = bead_z0 + BEAD_H
    chamfer_drop = (LID_ID / 2 - BEAD_ID / 2) * math.tan(math.radians(BEAD_CHAMFER))
    z_chamfer = plate_drop + bead_z1 + chamfer_drop
    return [
        (LID_ID / 2, z_mouth),
        (LID_ID / 2, z_chamfer),
        (BEAD_ID / 2, bead_z1),
        (BEAD_ID / 2, bead_z0),
        (LID_ID / 2, bead_z0),
        (LID_ID / 2, z_top),
        (LID_OD / 2, z_top),
        (LID_OD / 2, z_mouth),
    ]


# =============================================================================
# Fusion feature helpers
# =============================================================================

def _offset_plane(comp, base_plane, offset_mm):
    inp = comp.constructionPlanes.createInput()
    inp.setByOffset(base_plane, _val(offset_mm))
    return comp.constructionPlanes.add(inp)


def _polyline(sketch, pts_rz):
    lines = sketch.sketchCurves.sketchLines
    for i in range(len(pts_rz) - 1):
        r0, z0 = pts_rz[i]
        r1, z1 = pts_rz[i + 1]
        lines.addByTwoPoints(
            adsk.core.Point3D.create(mm(r0), mm(z0), 0),
            adsk.core.Point3D.create(mm(r1), mm(z1), 0),
        )
    r0, z0 = pts_rz[-1]
    r1, z1 = pts_rz[0]
    lines.addByTwoPoints(
        adsk.core.Point3D.create(mm(r0), mm(z0), 0),
        adsk.core.Point3D.create(mm(r1), mm(z1), 0),
    )


def _revolve(comp, pts_rz, z_shift_mm=0.0, operation=None, name=None):
    if operation is None:
        operation = adsk.fusion.FeatureOperations.NewBodyFeatureOperation
    plane = _offset_plane(comp, comp.xZConstructionPlane, z_shift_mm) if z_shift_mm else comp.xZConstructionPlane
    sketch = comp.sketches.add(plane)
    sketch.name = name or "RevolveProfile"
    _polyline(sketch, pts_rz)
    if sketch.profiles.count == 0:
        raise RuntimeError("Revolve sketch has no closed profile")
    prof = sketch.profiles.item(0)
    rev_in = comp.features.revolveFeatures.createInput(prof, comp.zConstructionAxis, operation)
    rev_in.setAngleExtent(False, _deg(360))
    n = _body_count(comp)
    comp.features.revolveFeatures.add(rev_in)
    body = _single_new_body(comp, n)
    if name and body:
        body.name = name
    return body


def _extrude_circle(comp, plane, center_xyz_mm, dia_mm, depth_mm, operation=None, body=None, name=None):
    if operation is None:
        operation = adsk.fusion.FeatureOperations.NewBodyFeatureOperation
    sketch = comp.sketches.add(plane)
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        adsk.core.Point3D.create(mm(center_xyz_mm[0]), mm(center_xyz_mm[1]), 0),
        mm(dia_mm / 2),
    )
    profile = sketch.profiles.item(0)

    if operation == adsk.fusion.FeatureOperations.CutFeatureOperation and body:
        _cut_extrude(comp, profile, depth_mm, body)
        return _as_body(body)

    n = _body_count(comp)
    ext_in = comp.features.extrudeFeatures.createInput(
        profile, adsk.fusion.FeatureOperations.NewBodyFeatureOperation,
    )
    ext_in.setDistanceExtent(False, _val(depth_mm))
    comp.features.extrudeFeatures.add(ext_in)
    result = _single_new_body(comp, n)
    if name and result:
        result.name = name
    return result


def _extrude_circle_z(comp, x, y, z0, dia_mm, height_mm, operation=None, body=None, name=None):
    plane = _offset_plane(comp, comp.xYConstructionPlane, z0)
    return _extrude_circle(comp, plane, (x, y, 0), dia_mm, height_mm, operation, body, name)


def _cylinder_z(comp, z_base, height, dia_mm, name=None):
    if height <= 0:
        return None
    return _extrude_circle_z(comp, 0, 0, z_base, dia_mm, height, name=name)


def _cylinder_x(comp, x_left, x_right, dia_mm, name=None):
    span = x_right - x_left
    if span <= 0:
        return None
    plane = _offset_plane(comp, comp.yZConstructionPlane, x_left)
    sketch = comp.sketches.add(plane)
    sketch.sketchCurves.sketchCircles.addByCenterRadius(adsk.core.Point3D.create(0, 0, 0), mm(dia_mm / 2))
    ext_in = comp.features.extrudeFeatures.createInput(
        sketch.profiles.item(0),
        adsk.fusion.FeatureOperations.NewBodyFeatureOperation,
    )
    ext_in.setDistanceExtent(False, _val(span))
    n = _body_count(comp)
    comp.features.extrudeFeatures.add(ext_in)
    body = _single_new_body(comp, n)
    if name and body:
        body.name = name
    return body


def _tube_x(comp, x_left, x_right, od_mm, id_mm, name=None):
    outer = _cylinder_x(comp, x_left, x_right, od_mm, name)
    if not outer:
        return None
    inner = _cylinder_x(comp, x_left - 0.05, x_right + 0.05, id_mm)
    if inner:
        _combine_cut(comp, outer, inner)
    return outer


def _combine(comp, target, tools):
    target_body = _as_body(target)
    col = adsk.core.ObjectCollection.create()
    for t in tools:
        tool_body = _as_body(t)
        if tool_body:
            col.add(tool_body)
    inp = comp.features.combineFeatures.createInput(target_body, col)
    inp.operation = adsk.fusion.FeatureOperations.JoinFeatureOperation
    comp.features.combineFeatures.add(inp)
    return target_body


def _matrix_translate(x, y, z):
    if x == 0 and y == 0 and z == 0:
        return adsk.core.Matrix3D.create()
    m = adsk.core.Matrix3D.create()
    m.translation = adsk.core.Vector3D.create(mm(x), mm(y), mm(z))
    return m


def _matrix_rotate_x(deg):
    m = adsk.core.Matrix3D.create()
    m.setToRotation(math.radians(deg), adsk.core.Vector3D.create(1, 0, 0), adsk.core.Point3D.create(0, 0, 0))
    return m


def _matrix_rotate_y(deg):
    m = adsk.core.Matrix3D.create()
    m.setToRotation(math.radians(deg), adsk.core.Vector3D.create(0, 1, 0), adsk.core.Point3D.create(0, 0, 0))
    return m


def _matrix_rotate_z(deg):
    m = adsk.core.Matrix3D.create()
    m.setToRotation(math.radians(deg), adsk.core.Vector3D.create(0, 0, 1), adsk.core.Point3D.create(0, 0, 0))
    return m


def _matrix_mirror_z():
    """OpenSCAD mirror([0, 0, 1]) — reflect through the XY plane."""
    m = adsk.core.Matrix3D.create()
    m.setWithCoordinateSystem(
        adsk.core.Point3D.create(0, 0, 0),
        adsk.core.Vector3D.create(1, 0, 0),
        adsk.core.Vector3D.create(0, 1, 0),
        adsk.core.Vector3D.create(0, 0, -1),
    )
    return m


def _mat_prod(a, b):
    out = a.copy()
    out.transformBy(b)
    return out


def _chain_transforms(*mats):
    """OpenSCAD order: translate * rotate * child  (rightmost matrix hits geometry first)."""
    mats = [m for m in mats if m is not None]
    if not mats:
        return adsk.core.Matrix3D.create()
    result = mats[0]
    for m in mats[1:]:
        result = _mat_prod(result, m)
    return result


def _rot_openscad(ax, ay, az):
    """OpenSCAD rotate([ax, ay, az]) — rotations about X, then Y, then Z."""
    return _chain_transforms(
        _matrix_rotate_x(ax) if ax else None,
        _matrix_rotate_y(ay) if ay else None,
        _matrix_rotate_z(az) if az else None,
    )


def _new_component_occ(parent_comp, name, transform=None):
    """Add a child component at the given rigid transform."""
    xform = transform if transform is not None else adsk.core.Matrix3D.create()
    occ = parent_comp.occurrences.addNewComponent(xform)
    occ.component.name = name
    return occ


def _assert_fusion_script_loaded():
    """Fail fast if Fusion is executing a stale cached copy of this file."""
    import inspect
    if SCRIPT_VERSION != "LTDEngine-v2.5":
        raise RuntimeError(
            "Expected LTDEngine-v2.5 but got {}.\n"
            "Remove and re-add the script in Fusion, then run again.".format(SCRIPT_VERSION)
        )
    for fn in (_new_component_occ, _matrix_translate):
        src = inspect.getsource(fn)
        if "setToTranslation" in src:
            raise RuntimeError(
                "Fusion is running a stale LTDEngine.py ({} still uses setToTranslation).\n"
                "Quit Fusion, re-add this script file, then run again.".format(fn.__name__)
            )
        if fn is _new_component_occ and ("occ.transform2" in src or ".transform2 =" in src):
            raise RuntimeError(
                "Fusion is running a stale LTDEngine.py (still sets transform2).\n"
                "Quit Fusion, re-add this script file, then run again."
            )


def _can_add_subcomponents(comp):
    """Part Design allows only one component; Assembly allows nested components."""
    try:
        occ = comp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
        occ.deleteMe()
        return True
    except RuntimeError:
        return False


def _body_ids(comp):
    return {id(comp.bRepBodies.item(i)) for i in range(comp.bRepBodies.count)}


def _move_bodies(comp, bodies, transform):
    if bodies.count == 0:
        return
    move_in = comp.features.moveFeatures.createInput(
        bodies, adsk.fusion.MoveFeatureOptions.Create(transform),
    )
    comp.features.moveFeatures.add(move_in)


def _move_new_bodies(comp, before_ids, transform):
    bodies = adsk.core.ObjectCollection.create()
    for i in range(comp.bRepBodies.count):
        body = comp.bRepBodies.item(i)
        if id(body) not in before_ids:
            bodies.add(body)
    _move_bodies(comp, bodies, transform)


class Builder:
    """Assembly mode: nested components. Part mode: single root + body moves."""

    def __init__(self, geom_comp, use_subcomponents, parent_comp=None, world_xform=None):
        self.geom = geom_comp
        self.use_sub = use_subcomponents
        self.parent = parent_comp or geom_comp
        self.world = world_xform or adsk.core.Matrix3D.create()

    def group(self, name, local_xform, fn):
        if self.use_sub:
            occ = _new_component_occ(self.parent, name, local_xform)
            fn(Builder(occ.component, True, occ.component))
        else:
            child_world = _mat_prod(self.world, local_xform)
            before = _body_ids(self.geom)
            fn(Builder(self.geom, False, self.parent, child_world))
            _move_new_bodies(self.geom, before, child_world)

    def comp(self):
        return self.geom


# =============================================================================
# Part builders (local coords unless noted)
# =============================================================================

def build_can401_body(comp, d, z_base):
    body = _revolve(comp, _can401_rim_wall_profile(), z_base, name="Can401Rim")
    cyl = _extrude_circle_z(
        comp, 0, 0, z_base + 0.25, CAN_BODY_OD, CYL_H - CAN_RIM_H - 0.25, name="Can401Straight",
    )
    _combine(comp, body, [cyl])
    _extrude_circle_z(
        comp, 0, 0, z_base + 0.5, d.can_body_id, CYL_H + 1,
        adsk.fusion.FeatureOperations.CutFeatureOperation, body,
    )


def build_cold_plate(comp, d):
    plate = _extrude_circle_z(comp, 0, 0, 0, d.cold_plate_od, COLD_PLATE_T, name="ColdPlate")
    boss = _extrude_circle_z(
        comp, POWER_PISTON_X, PARTS_Y_AXIS, 0, d.power_cyl_od + 4, POWER_CYL_BOSS_H, name="PowerBoss",
    )
    _combine(comp, plate, [boss])
    _extrude_circle_z(
        comp, 0, 0, -1, SEAL_OD, 10, adsk.fusion.FeatureOperations.CutFeatureOperation, plate,
    )
    _extrude_circle_z(
        comp, POWER_PISTON_X, PARTS_Y_AXIS, -1, d.power_cyl_id, 15,
        adsk.fusion.FeatureOperations.CutFeatureOperation, plate,
    )
    if COLD_PLATE_CUP_DEPTH > 0:
        _extrude_circle_z(
            comp, 0, 0, COLD_PLATE_T - COLD_PLATE_CUP_DEPTH,
            d.cold_plate_od - 2 * RING_CLAMP_OVERHANG - 1,
            COLD_PLATE_CUP_DEPTH + 0.01,
            adsk.fusion.FeatureOperations.CutFeatureOperation, plate,
        )
    return plate


def build_brass_seal(comp):
    seal = _extrude_circle_z(comp, 0, 0, 0, SEAL_OD, SEAL_H, name="BrassSeal")
    _extrude_circle_z(
        comp, 0, 0, -1, SEAL_ID, SEAL_H + 2,
        adsk.fusion.FeatureOperations.CutFeatureOperation, seal,
    )
    return seal


def build_snap_ring(comp, d):
    wedge = _revolve(
        comp,
        _can401_snap_ring_wedge_profile(
            d.cold_plate_od, d.cold_plate_drop, RING_CLAMP_OVERHANG, RING_WEDGE_COMPRESS,
        ),
        0,
        name="SnapRingWedge",
    )
    skirt = _revolve(
        comp,
        _can401_snap_ring_skirt_profile(d.cold_plate_od, d.cold_plate_drop),
        0,
        name="SnapRingSkirt",
    )
    return _combine(comp, wedge, [skirt])


def build_power_cylinder(comp, d):
    cyl = _extrude_circle_z(comp, 0, 0, 0, d.power_cyl_od, d.power_cyl_h, name="PowerCylinder")
    _extrude_circle_z(
        comp, 0, 0, -1, d.power_cyl_id, d.power_cyl_h + 2,
        adsk.fusion.FeatureOperations.CutFeatureOperation, cyl,
    )
    return cyl


def build_displacer(comp, d):
    return _extrude_circle_z(
        comp, 0, 0, -d.displacer_h / 2, d.displacer_d, d.displacer_h, name="Displacer",
    )


def build_power_piston(comp, d):
    piston = _extrude_circle_z(comp, 0, 0, 0, d.power_piston_od, POWER_PISTON_H, name="PowerPiston")
    cup_floor = 1.5
    cup_h = POWER_PISTON_H - cup_floor
    _extrude_circle_z(
        comp, 0, 0, cup_floor, d.power_piston_cup_id, cup_h + 0.01,
        adsk.fusion.FeatureOperations.CutFeatureOperation, piston,
    )
    pin_z = POWER_PISTON_H / 2
    plane = _offset_plane(comp, comp.xZConstructionPlane, 0)
    sketch = comp.sketches.add(plane)
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        adsk.core.Point3D.create(mm(POWER_PISTON_CLEVIS_X), mm(pin_z), 0), mm(CLEVIS_TAB_X / 2),
    )
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        adsk.core.Point3D.create(mm(-POWER_PISTON_CLEVIS_X), mm(pin_z), 0), mm(CLEVIS_TAB_X / 2),
    )
    _cut_extrude(comp, sketch.profiles, POWER_PISTON_H, piston)
    return piston


def build_flywheel(comp, d):
    fw = _extrude_circle_z(
        comp, 0, 0, -FLYWHEEL_W / 2, FLYWHEEL_D, FLYWHEEL_W, name="FlywheelRim",
    )
    _extrude_circle_z(
        comp, 0, 0, -FLYWHEEL_W / 2 - 0.01, FLYWHEEL_D - 8, FLYWHEEL_W + 2,
        adsk.fusion.FeatureOperations.CutFeatureOperation, fw,
    )
    hub = _extrude_circle_z(
        comp, 0, 0, -FLYWHEEL_W / 2, d.flywheel_hub_od, FLYWHEEL_W, name="FlywheelHub",
    )
    collar = _extrude_circle_z(
        comp, 0, 0, FLYWHEEL_W / 2, FLYWHEEL_COLLAR_OD, FLYWHEEL_COLLAR_H, name="FlywheelCollar",
    )
    _combine(comp, fw, [hub, collar])
    _extrude_circle_z(
        comp, 0, 0, -(FLYWHEEL_W + FLYWHEEL_COLLAR_H) / 2 - 2,
        ROD_OD + 0.15, FLYWHEEL_W + FLYWHEEL_COLLAR_H + 4,
        adsk.fusion.FeatureOperations.CutFeatureOperation, fw,
    )
    return fw


def build_crank_arm(comp, radius, collar_outward):
    z0 = 0 if collar_outward > 0 else -COLLAR_LEN
    arm = _extrude_circle_z(comp, 0, 0, z0, COLLAR_OD, COLLAR_LEN, name="CrankCollar")
    half = CRANK_WEB_T / 2.0
    web = _extrude_circle_z(comp, 0, radius, -half, 7, CRANK_WEB_T, name="CrankWeb")
    hub = _extrude_circle_z(comp, 0, 0, -half, 10, CRANK_WEB_T, name="CrankHub")
    _combine(comp, arm, [web, hub])
    _extrude_circle_z(
        comp, 0, radius, -half - 0.01, PIN_D, CRANK_WEB_T + 2,
        adsk.fusion.FeatureOperations.CutFeatureOperation, arm,
    )
    _extrude_circle_z(
        comp, 0, 0, -1, ROD_OD + 0.15, COLLAR_LEN + 2,
        adsk.fusion.FeatureOperations.CutFeatureOperation, arm,
    )
    return arm


def build_link_disc(comp):
    fork_t = PIN_D + 1.2
    plane = comp.yZConstructionPlane
    sketch = comp.sketches.add(plane)
    sketch.sketchCurves.sketchCircles.addByCenterRadius(adsk.core.Point3D.create(0, 0, 0), mm(LINK_DISC_D / 2))
    ext_in = comp.features.extrudeFeatures.createInput(
        sketch.profiles.item(0), adsk.fusion.FeatureOperations.NewBodyFeatureOperation,
    )
    ext_in.setSymmetricExtent(_val(fork_t / 2.0), True)
    n = _body_count(comp)
    comp.features.extrudeFeatures.add(ext_in)
    disc = _single_new_body(comp, n)
    if disc:
        disc.name = "LinkDisc"
    cut_sk = comp.sketches.add(plane)
    cut_sk.sketchCurves.sketchCircles.addByCenterRadius(adsk.core.Point3D.create(0, 0, 0), mm(PIN_D / 2))
    _cut_extrude(comp, cut_sk.profiles.item(0), fork_t + 2, disc)
    return disc

def build_rod_flange(comp):
    flange = _extrude_circle_z(comp, 0, 0, 0, FLANGE_OD, FLANGE_T + 2, name="RodFlange")
    _extrude_circle_z(
        comp, 0, 0, -FLANGE_T, 2.5, FLANGE_T + 1.5,
        adsk.fusion.FeatureOperations.CutFeatureOperation, flange,
    )
    return flange


def build_support_frame(comp, d, mirror_x=False):
    foot = _extrude_box(comp, 0, 0, FRAME_FOOT_H / 2, FRAME_T, FRAME_STEM_Y_W, FRAME_FOOT_H)
    for fy in (d.frame_foot_y, -d.frame_foot_y):
        pad = _extrude_box(comp, 0, fy, FRAME_FOOT_H / 2, FRAME_T, FRAME_FOOT_PAD_W, FRAME_FOOT_H)
        _combine(comp, foot, [pad])

    if mirror_x:
        tower_plane_x = FRAME_T / 2.0
        tower_extent = -FRAME_T
        bore_plane_x = FRAME_T / 2.0 + 0.5
        bore_extent = -(FRAME_T + 1.0)
    else:
        tower_plane_x = -FRAME_T / 2.0
        tower_extent = FRAME_T
        bore_plane_x = -FRAME_T / 2.0 - 0.5
        bore_extent = FRAME_T + 1.0

    plane = _offset_plane(comp, comp.yZConstructionPlane, tower_plane_x)
    sketch = comp.sketches.add(plane)
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        adsk.core.Point3D.create(0, mm(AXLE_TO_DECK), 0), mm(7),
    )
    ext_in = comp.features.extrudeFeatures.createInput(
        sketch.profiles.item(0), adsk.fusion.FeatureOperations.NewBodyFeatureOperation,
    )
    if tower_extent >= 0:
        ext_in.setDistanceExtent(False, _val(tower_extent))
    else:
        ext_in.setDistanceExtent(True, _val(tower_extent))
    n = _body_count(comp)
    comp.features.extrudeFeatures.add(ext_in)
    tower = _single_new_body(comp, n)
    if tower:
        tower.name = "FrameTower"
    _combine(comp, foot, [tower])

    bore_plane = _offset_plane(comp, comp.yZConstructionPlane, bore_plane_x)
    bore_sk = comp.sketches.add(bore_plane)
    bore_sk.sketchCurves.sketchCircles.addByCenterRadius(
        adsk.core.Point3D.create(0, mm(AXLE_TO_DECK), 0), mm(d.bearing_pocket_od / 2),
    )
    _cut_extrude(comp, bore_sk.profiles.item(0), bore_extent, foot)
    shaft_sk = comp.sketches.add(bore_plane)
    shaft_sk.sketchCurves.sketchCircles.addByCenterRadius(
        adsk.core.Point3D.create(0, mm(AXLE_TO_DECK), 0), mm(d.bearing_shaft_hole_d / 2),
    )
    _cut_extrude(comp, shaft_sk.profiles.item(0), bore_extent, foot)
    return foot


def _extrude_box(comp, x, y, z, sx, sy, sz):
    plane = _offset_plane(comp, comp.xYConstructionPlane, z - sz / 2)
    sketch = comp.sketches.add(plane)
    sketch.sketchCurves.sketchLines.addCenterPointRectangle(
        adsk.core.Point3D.create(mm(x), mm(y), 0),
        adsk.core.Point3D.create(mm(x + sx / 2), mm(y + sy / 2), 0),
    )
    return _extrude_profile(comp, sketch.profiles.item(0), sz)


def _extrude_profile(comp, profile, depth_mm, operation=None, name=None):
    if operation is None:
        operation = adsk.fusion.FeatureOperations.NewBodyFeatureOperation
    n = _body_count(comp)
    ext_in = comp.features.extrudeFeatures.createInput(
        profile, adsk.fusion.FeatureOperations.NewBodyFeatureOperation,
    )
    ext_in.setDistanceExtent(False, _val(depth_mm))
    comp.features.extrudeFeatures.add(ext_in)
    body = _single_new_body(comp, n)
    if name and body:
        body.name = name
    return body


# =============================================================================
# Kinematics
# =============================================================================

class Kinematics:
    pass


def compute_kinematics(d, engine_angle_deg):
    k = Kinematics()
    disp_angle = math.radians(engine_angle_deg)
    piston_angle = math.radians(engine_angle_deg - 90)

    k.disp_pin_y = -d.displacer_crank_r * math.sin(disp_angle)
    k.disp_pin_z = d.displacer_crank_r * math.cos(disp_angle)
    k.piston_pin_y = -d.power_crank_r * math.sin(piston_angle)
    k.piston_pin_z = d.power_crank_r * math.cos(piston_angle)

    k.disp_rod_joint_z = k.disp_pin_z - math.sqrt(max(0.001, DISP_LINK_LEN ** 2 - k.disp_pin_y ** 2))
    k.disp_rod_attach_z = k.disp_rod_joint_z - d.disp_rod_blind_depth
    k.disp_top_z = k.disp_rod_attach_z - d.displacer_shaft_len
    k.disp_center_z = k.disp_top_z - d.displacer_h / 2
    k.disp_rot_x = math.degrees(math.atan2(k.disp_pin_y, k.disp_pin_z - k.disp_rod_joint_z))

    k.power_piston_pin_z = k.piston_pin_z - math.sqrt(
        max(0.001, d.power_link_len ** 2 - k.piston_pin_y ** 2)
    )
    k.power_piston_base_z = k.power_piston_pin_z - POWER_PISTON_H / 2
    k.piston_rot_x = math.degrees(math.atan2(k.piston_pin_y, k.piston_pin_z - k.power_piston_pin_z))
    return k


# =============================================================================
# Assembly
# =============================================================================

def build_assembled(root, d, k, ez, use_sub):
    b = Builder(root, use_sub)

    def crankshaft(bg):
        c = bg.comp()
        _cylinder_x(c, d.shaft_seg_flywheel_left, d.shaft_seg_flywheel_right, ROD_OD)
        _cylinder_x(c, d.disp_web_l_out, d.disp_web_l_in, ROD_OD)
        _cylinder_x(c, d.disp_web_r_in, d.disp_web_r_out, ROD_OD)
        _cylinder_x(c, d.shaft_seg_mid_left, d.shaft_seg_mid_right, ROD_OD)
        _cylinder_x(c, d.pwr_web_l_out, d.pwr_web_l_in, ROD_OD)
        _cylinder_x(c, d.pwr_web_r_in, d.pwr_web_r_out, ROD_OD)
        _cylinder_x(c, d.shaft_seg_power_left, d.shaft_seg_power_right, ROD_OD)
        _tube_x(c, d.shaft_tube_pwr_frame_x0, d.shaft_tube_pwr_frame_x1, COLLAR_OD, d.shaft_tube_id)
        _tube_x(c, d.shaft_tube_pwr_disp_x0, d.shaft_tube_pwr_disp_x1, COLLAR_OD, d.shaft_tube_id)
        _tube_x(c, d.shaft_tube_disp_fly_x0, d.shaft_tube_disp_fly_x1, COLLAR_OD, d.shaft_tube_id)
        _tube_x(c, d.shaft_tube_fly_frame_x0, d.shaft_tube_fly_frame_x1, COLLAR_OD, d.shaft_tube_id)

    b.group("Crankshaft", adsk.core.Matrix3D.create(), crankshaft)

    b.group(
        "Flywheel",
        _chain_transforms(
            _matrix_translate(FLYWHEEL_X, 0, 0),
            _rot_openscad(MANUAL_ANGLE, 0, 0),
            _rot_openscad(90, 0, 90),
        ),
        lambda bg: build_flywheel(bg.comp(), d),
    )

    def displacer_crank(bg):
        for sign, outward in ((-1, -1), (1, 1)):
            bg.group(
                "DispArm_{}".format(sign),
                _chain_transforms(
                    _matrix_translate(sign * d.crank_web_x, 0, 0),
                    _rot_openscad(90, 0, 90),
                    _rot_openscad(0, 0, MANUAL_ANGLE),
                ),
                lambda arm_bg, o=outward: build_crank_arm(arm_bg.comp(), d.displacer_crank_r, o),
            )
        bg.group(
            "DisplacerLink",
            _chain_transforms(
                _matrix_translate(0, k.disp_pin_y, k.disp_pin_z),
                _matrix_rotate_x(-k.disp_rot_x),
            ),
            lambda link_bg: build_link_disc(link_bg.comp()),
        )

    b.group("DisplacerCrank", adsk.core.Matrix3D.create(), displacer_crank)

    def power_crank(bg):
        for sign, outward in ((-1, -1), (1, 1)):
            bg.group(
                "PwrArm_{}".format(sign),
                _chain_transforms(
                    _matrix_translate(sign * d.crank_web_x, 0, 0),
                    _rot_openscad(90, 0, 90),
                    _rot_openscad(0, 0, MANUAL_ANGLE - 90),
                ),
                lambda arm_bg, o=outward: build_crank_arm(arm_bg.comp(), d.power_crank_r, o),
            )
        bg.group(
            "PowerLink",
            _chain_transforms(
                _matrix_translate(0, k.piston_pin_y, k.piston_pin_z),
                _matrix_rotate_x(-k.piston_rot_x),
            ),
            lambda link_bg: build_link_disc(link_bg.comp()),
        )

    b.group("PowerCrank", _matrix_translate(POWER_PISTON_X, 0, 0), power_crank)

    def chassis_deck(bg):
        for x, mirror, label in (
            (LEFT_SUPPORT_X, False, "Frame_L"),
            (RIGHT_SUPPORT_X, True, "Frame_R"),
        ):
            bg.group(
                label,
                _matrix_translate(x, PARTS_Y_AXIS, d.cold_plate_top_z),
                lambda frame_bg, m=mirror: build_support_frame(frame_bg.comp(), d, mirror_x=m),
            )

        def cold_plate_assy(plate_bg):
            build_cold_plate(plate_bg.comp(), d)
            plate_bg.group("Seal", _matrix_translate(0, 0, -1), lambda s: build_brass_seal(s.comp()))
            plate_bg.group(
                "SnapRing",
                _chain_transforms(
                    _matrix_translate(0, 0, ring_ez(ez) + RING_Z_OFFSET + d.snap_ring_t),
                    _matrix_mirror_z(),
                ),
                lambda s: build_snap_ring(s.comp(), d),
            )
            plate_bg.group(
                "PowerCyl", _matrix_translate(POWER_PISTON_X, 0, COLD_PLATE_T),
                lambda s: build_power_cylinder(s.comp(), d),
            )

        bg.group(
            "ColdPlateAssy",
            _matrix_translate(0, PARTS_Y_AXIS, d.cold_plate_bottom_z),
            cold_plate_assy,
        )

    b.group("ChassisDeck", _matrix_translate(0, 0, -ez), chassis_deck)

    def internal_cavity(bg):
        bg.group(
            "PowerPiston",
            _matrix_translate(POWER_PISTON_X, PARTS_Y_AXIS, k.power_piston_base_z),
            lambda s: build_power_piston(s.comp(), d),
        )
        bg.group(
            "RodFlange",
            _matrix_translate(0, PARTS_Y_AXIS, k.disp_rod_joint_z - d.disp_flange_pin_z_offset),
            lambda s: build_rod_flange(s.comp()),
        )
        bg.group(
            "DisplacerShaft",
            _matrix_translate(
                0, PARTS_Y_AXIS, k.disp_rod_attach_z - d.displacer_shaft_len,
            ),
            lambda s: _cylinder_z(s.comp(), 0, d.displacer_shaft_len, ROD_OD),
        )
        bg.group(
            "Displacer",
            _matrix_translate(0, PARTS_Y_AXIS, k.disp_center_z),
            lambda s: build_displacer(s.comp(), d),
        )
        bg.group(
            "Can401",
            _matrix_translate(0, PARTS_Y_AXIS, d.disp_can_bottom_z),
            lambda s: build_can401_body(s.comp(), d, 0),
        )

    b.group("InternalCavity", _matrix_translate(0, 0, -ez * 2), internal_cavity)


def ring_ez(ez):
    return EXPLODE_OFFSET * 0.4 if MODE == "Exploded" else 0.0


# =============================================================================
# Entry point
# =============================================================================

def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        design = adsk.fusion.Design.cast(app.activeProduct)
        if not design:
            ui.messageBox("Open a Design document first.")
            return

        _assert_fusion_script_loaded()

        d = compute_derived()
        k = compute_kinematics(d, MANUAL_ANGLE)
        ez = EXPLODE_OFFSET if MODE == "Exploded" else 0.0

        root = design.rootComponent
        use_sub = _can_add_subcomponents(root)
        if use_sub:
            engine_occ = _new_component_occ(root, "LTDEngine")
            build_assembled(engine_occ.component, d, k, ez, use_sub)
        else:
            build_assembled(root, d, k, ez, use_sub)

        doc_type = "Assembly" if use_sub else "Part"
        ui.messageBox(
            "LTDEngine {} created ({} document).\n\n"
            "Mode: {}\n"
            "Crank angle: {:.1f}°\n\n"
            "Edit parameters at the top of LTDEngine.py and re-run.\n"
            "Displacer swept vol: {:.1f} cm³\n"
            "Power cyl ID: {:.2f} mm".format(
                SCRIPT_VERSION,
                doc_type,
                MODE,
                MANUAL_ANGLE,
                d.displacer_swept_vol / 1000.0,
                d.power_cyl_id,
            )
        )

    except Exception:
        if ui:
            ui.messageBox("Failed:\n{}".format(traceback.format_exc()))
