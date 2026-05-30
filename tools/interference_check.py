#!/usr/bin/env python3
"""Clearance / interference analysis for LTDEngine.scad (Assembled mode defaults)."""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Iterable, List, Tuple

PI = math.pi

# --- Mirror LTDEngine.scad Customizer defaults ---
CAN_BODY_OD = 98.93
CAN_RIM_OD = 101.75
CAN_WALL_T = 0.21
CAN_INNER_D = CAN_BODY_OD - 2 * CAN_WALL_T
CAN_MOUTH_ID = CAN_INNER_D + 0.7  # rolled-rim inner step (Can401_lib seam_ri)
COLD_PLATE_RIM_CLEARANCE = 0.25
CYL_H = 47.0
AXLE_TO_DECK = 80.0
FLYWHEEL_D = 140.0
FLYWHEEL_W = 8.0
FLYWHEEL_X = -22.0
LEFT_SUPPORT_X = -40.0
RIGHT_SUPPORT_X = 40.0
POWER_PISTON_X = 22.0
DISP_LINK_LEN = 40.0
POWER_STROKE = 12.0
POWER_PISTON_H = 16.0
SV_RATIO = 40.0
PIN_D = 1.5
ROD_OD = 3.0
LINK_DISC_D = 8.0
CRANK_WEB_GAP = 3.4
CRANK_WEB_T = 2.5
COLLAR_OD = 10.0
COLLAR_LEN = 5.0
FLANGE_OD = 12.0
FRAME_W = 30.0
FRAME_T = 5.0
DISP_RADIAL_CLEARANCE = 1.5
DISP_AXIAL_CLEARANCE = 2.0
DISP_STROKE_RATIO = 0.55
COLD_PLATE_T = 6.35
COLD_PLATE_OD = CAN_MOUTH_ID - 2 * COLD_PLATE_RIM_CLEARANCE
RING_CLAMP_ID = COLD_PLATE_OD + 1.0
POWER_PISTON_AXIAL_CLEARANCE = 1.0
DISP_ROD_BLIND_DEPTH = 4.0
POWER_PISTON_CLEVIS_BOSS_H = 6.0
CRANK_WEB_X = CRANK_WEB_GAP / 2 + CRANK_WEB_T / 2
CAN_RIM_H = 3.15
CAN_FLANGE_STEP_H = 0.55


def cold_plate_seat_z(plate_od: float) -> float:
    ri = CAN_INNER_D / 2
    seam_ri = ri + 0.35
    z_rim = CYL_H - CAN_RIM_H
    z_step = z_rim + CAN_FLANGE_STEP_H
    plate_r = plate_od / 2
    if plate_r <= ri:
        return z_rim
    if plate_r >= seam_ri:
        return CYL_H
    return z_rim + (plate_r - ri) * (z_step - z_rim) / (seam_ri - ri)


COLD_PLATE_DROP = CYL_H - cold_plate_seat_z(COLD_PLATE_OD)


@dataclass
class Issue:
    severity: str  # FAIL, WARN, INFO
    check: str
    angle: float | None
    detail: str


def derived() -> dict:
    can_inner_d = CAN_BODY_OD - 2 * CAN_WALL_T
    displacer_d = can_inner_d - 2 * DISP_RADIAL_CLEARANCE
    disp_bore_depth = CYL_H - 2 * DISP_AXIAL_CLEARANCE
    displacer_stroke = disp_bore_depth * DISP_STROKE_RATIO
    displacer_h = disp_bore_depth - displacer_stroke
    displacer_area = PI / 4 * displacer_d * displacer_d
    displacer_swept_vol = displacer_area * displacer_stroke
    power_swept_vol = displacer_swept_vol / SV_RATIO
    power_cyl_id = math.sqrt(power_swept_vol / (PI * 0.25 * POWER_STROKE))
    power_cyl_h = POWER_STROKE + POWER_PISTON_H + 2 * POWER_PISTON_AXIAL_CLEARANCE
    power_piston_od = power_cyl_id - 0.15
    displacer_crank_r = displacer_stroke / 2
    power_crank_r = POWER_STROKE / 2
    disp_can_bottom_z = -AXLE_TO_DECK - CYL_H
    disp_can_top_z = -AXLE_TO_DECK - DISP_AXIAL_CLEARANCE
    disp_z_min = disp_can_bottom_z + DISP_AXIAL_CLEARANCE + displacer_h / 2
    disp_z_max = disp_can_top_z - DISP_AXIAL_CLEARANCE - displacer_h / 2
    disp_center_mid_z = (disp_z_min + disp_z_max) / 2
    power_cyl_base_z = -AXLE_TO_DECK - COLD_PLATE_DROP + COLD_PLATE_T
    power_cyl_bore_top_z = power_cyl_base_z + power_cyl_h
    power_piston_base_min = power_cyl_base_z + POWER_PISTON_AXIAL_CLEARANCE
    power_piston_base_max = (
        power_cyl_bore_top_z - POWER_PISTON_AXIAL_CLEARANCE - POWER_PISTON_H
    )
    power_piston_base_mid = (power_piston_base_min + power_piston_base_max) / 2
    crank_web_outer = CRANK_WEB_X + CRANK_WEB_T / 2
    fork_thin = PIN_D + 1.2
    displacer_shaft_len = (
        (displacer_crank_r - DISP_LINK_LEN - DISP_ROD_BLIND_DEPTH)
        - (disp_center_mid_z + displacer_stroke / 2 + displacer_h / 2)
    )
    power_link_len = abs(
        power_crank_r
        - (power_piston_base_mid + POWER_STROKE / 2 + POWER_PISTON_H / 2)
    )
    return {
        "can_inner_d": can_inner_d,
        "displacer_d": displacer_d,
        "displacer_stroke": displacer_stroke,
        "displacer_h": displacer_h,
        "power_cyl_id": power_cyl_id,
        "power_cyl_h": power_cyl_h,
        "power_piston_od": power_piston_od,
        "displacer_crank_r": displacer_crank_r,
        "power_crank_r": power_crank_r,
        "disp_can_bottom_z": disp_can_bottom_z,
        "disp_can_top_z": disp_can_top_z,
        "disp_center_mid_z": disp_center_mid_z,
        "power_cyl_base_z": power_cyl_base_z,
        "power_cyl_bore_top_z": power_cyl_bore_top_z,
        "power_piston_base_min": power_piston_base_min,
        "power_piston_base_max": power_piston_base_max,
        "power_piston_base_mid": power_piston_base_mid,
        "crank_web_outer": crank_web_outer,
        "fork_thin": fork_thin,
        "displacer_shaft_len": displacer_shaft_len,
        "power_link_len": power_link_len,
    }


def kinematics(deg: float, d: dict) -> dict:
    disp_angle = math.radians(deg)
    piston_angle = math.radians(deg - 90)

    disp_pin_y = -d["displacer_crank_r"] * math.sin(disp_angle)
    disp_pin_z = d["displacer_crank_r"] * math.cos(disp_angle)
    piston_pin_y = -d["power_crank_r"] * math.sin(piston_angle)
    piston_pin_z = d["power_crank_r"] * math.cos(piston_angle)

    disp_under = DISP_LINK_LEN * DISP_LINK_LEN - disp_pin_y * disp_pin_y
    disp_joint_ok = disp_under > 0
    disp_rod_joint_z = disp_pin_z - math.sqrt(max(0.001, disp_under))

    disp_rod_attach_z = disp_rod_joint_z - DISP_ROD_BLIND_DEPTH
    disp_top_z = disp_rod_attach_z - d["displacer_shaft_len"]
    disp_center_z = disp_top_z - d["displacer_h"] / 2
    disp_bottom_z = disp_center_z - d["displacer_h"] / 2

    power_under = d["power_link_len"] * d["power_link_len"] - piston_pin_y * piston_pin_y
    power_joint_ok = power_under > 0
    power_piston_pin_z = piston_pin_z - math.sqrt(max(0.001, power_under))
    power_piston_base_z = power_piston_pin_z - POWER_PISTON_H / 2
    power_piston_top_z = power_piston_base_z + POWER_PISTON_H
    power_piston_bottom_z = power_piston_base_z

    return {
        "disp_pin_y": disp_pin_y,
        "disp_pin_z": disp_pin_z,
        "piston_pin_y": piston_pin_y,
        "piston_pin_z": piston_pin_z,
        "disp_joint_ok": disp_joint_ok,
        "power_joint_ok": power_joint_ok,
        "disp_rod_joint_z": disp_rod_joint_z,
        "disp_center_z": disp_center_z,
        "disp_top_z": disp_top_z,
        "disp_bottom_z": disp_bottom_z,
        "disp_rod_attach_z": disp_rod_attach_z,
        "disp_rod_len": d["displacer_shaft_len"],
        "power_piston_base_z": power_piston_base_z,
        "power_piston_pin_z": power_piston_pin_z,
        "power_piston_top_z": power_piston_top_z,
        "power_piston_bottom_z": power_piston_bottom_z,
        "power_link_len_eff": d["power_link_len"],
        "disp_link_len_eff": DISP_LINK_LEN,
    }


def analyze_angles(angles: Iterable[float]) -> Tuple[List[Issue], dict]:
    d = derived()
    issues: List[Issue] = []
    stats = {
        "disp_rod_len_min": float("inf"),
        "disp_rod_len_max": float("-inf"),
        "power_link_len_min": float("inf"),
        "power_link_len_max": float("-inf"),
        "disp_top_clearance_min": float("inf"),
        "disp_bottom_clearance_min": float("inf"),
        "piston_top_clearance_min": float("inf"),
        "piston_bottom_clearance_min": float("inf"),
    }

    radial_piston_clear = (d["power_cyl_id"] - d["power_piston_od"]) / 2
    if radial_piston_clear < 0:
        issues.append(
            Issue("FAIL", "power piston radial fit", None, f"{radial_piston_clear:.3f} mm")
        )

    for deg in angles:
        k = kinematics(deg, d)

        if not k["disp_joint_ok"]:
            issues.append(
                Issue(
                    "FAIL",
                    "displacer slider-crank",
                    deg,
                    f"|disp_pin_y|={abs(k['disp_pin_y']):.3f} mm > disp_link_len={DISP_LINK_LEN} mm",
                )
            )
        if not k["power_joint_ok"]:
            issues.append(
                Issue(
                    "FAIL",
                    "power slider-crank",
                    deg,
                    f"|piston_pin_y|={abs(k['piston_pin_y']):.3f} mm > power_link_len={d['power_link_len']:.3f} mm",
                )
            )

        stats["disp_rod_len_min"] = min(stats["disp_rod_len_min"], k["disp_rod_len"])
        stats["disp_rod_len_max"] = max(stats["disp_rod_len_max"], k["disp_rod_len"])
        stats["power_link_len_min"] = min(
            stats["power_link_len_min"], k["power_link_len_eff"]
        )
        stats["power_link_len_max"] = max(
            stats["power_link_len_max"], k["power_link_len_eff"]
        )

        if k["disp_rod_len"] < 0:
            issues.append(
                Issue(
                    "FAIL",
                    "displacer steel rod length",
                    deg,
                    f"rod_len={k['disp_rod_len']:.3f} mm (flange below displacer top)",
                )
            )

        disp_top_clear = d["disp_can_top_z"] - k["disp_top_z"]
        disp_bottom_clear = k["disp_bottom_z"] - d["disp_can_bottom_z"]
        stats["disp_top_clearance_min"] = min(stats["disp_top_clearance_min"], disp_top_clear)
        stats["disp_bottom_clearance_min"] = min(
            stats["disp_bottom_clearance_min"], disp_bottom_clear
        )
        if disp_top_clear < 0:
            issues.append(
                Issue(
                    "FAIL",
                    "displacer vs can top",
                    deg,
                    f"overlap {abs(disp_top_clear):.3f} mm",
                )
            )
        if disp_bottom_clear < 0:
            issues.append(
                Issue(
                    "FAIL",
                    "displacer vs can bottom",
                    deg,
                    f"overlap {abs(disp_bottom_clear):.3f} mm",
                )
            )

        piston_top_clear = d["power_cyl_bore_top_z"] - k["power_piston_top_z"]
        piston_bottom_clear = (
            k["power_piston_bottom_z"]
            - d["power_cyl_base_z"]
            - POWER_PISTON_AXIAL_CLEARANCE
        )
        stats["piston_top_clearance_min"] = min(
            stats["piston_top_clearance_min"], piston_top_clear
        )
        stats["piston_bottom_clearance_min"] = min(
            stats["piston_bottom_clearance_min"], piston_bottom_clear
        )
        if piston_top_clear < -0.01:
            issues.append(
                Issue(
                    "FAIL",
                    "power piston vs cylinder top",
                    deg,
                    f"overlap {abs(piston_top_clear):.3f} mm",
                )
            )
        if piston_bottom_clear < -0.01:
            issues.append(
                Issue(
                    "FAIL",
                    "power piston vs cylinder bottom",
                    deg,
                    f"overlap {abs(piston_bottom_clear):.3f} mm",
                )
            )

        # Crank web fork slot: green disc thickness along X must fit web gap
        web_slot = CRANK_WEB_GAP
        if d["fork_thin"] > web_slot:
            issues.append(
                Issue(
                    "FAIL",
                    "link fork vs crank web gap",
                    None,
                    f"fork_thin={d['fork_thin']:.2f} > gap={web_slot:.2f} mm",
                )
            )

    # Static assembly checks
    if COLD_PLATE_OD > CAN_RIM_OD:
        issues.append(
            Issue(
                "FAIL",
                "cold plate vs can OD",
                None,
                f"plate OD {COLD_PLATE_OD} > can seam {CAN_RIM_OD}",
            )
        )
    if RING_CLAMP_ID < COLD_PLATE_OD:
        issues.append(
            Issue(
                "WARN",
                "snap ring bore vs plate",
                None,
                f"ring ID {RING_CLAMP_ID} < plate OD {COLD_PLATE_OD} (may bind on assembly)",
            )
        )

    # Flywheel (disk in YZ at flywheel_x) vs left frame pillar (at left_support_x)
    fly_x_band = (FLYWHEEL_X - FLYWHEEL_W / 2, FLYWHEEL_X + FLYWHEEL_W / 2)
    frame_x_band = (LEFT_SUPPORT_X - FRAME_T / 2, LEFT_SUPPORT_X + FRAME_T / 2)
    x_gap = fly_x_band[0] - frame_x_band[1]  # flywheel −X face minus frame +X (inboard) face
    if x_gap < 0:
        issues.append(
            Issue(
                "FAIL",
                "flywheel vs left frame (X)",
                None,
                f"axial overlap {abs(x_gap):.2f} mm",
            )
        )
    elif x_gap < 8:
        issues.append(
            Issue(
                "WARN",
                "flywheel vs left frame (X)",
                None,
                f"tight hub clearance {x_gap:.2f} mm (different X planes; rim is in YZ)",
            )
        )

    stats["power_link_span_min"] = d["power_link_len"]
    stats["power_link_span_max"] = d["power_link_len"]
    stats["displacer_shaft_len"] = d["displacer_shaft_len"]
    stats["power_link_len"] = d["power_link_len"]
    stats["radial_piston_clearance_mm"] = radial_piston_clear
    if stats["piston_bottom_clearance_min"] < 0.05:
        issues.append(
            Issue(
                "WARN",
                "power piston bottom clearance",
                None,
                f"min {stats['piston_bottom_clearance_min']:.3f} mm at BDC (at limit with {POWER_PISTON_H} mm piston)",
            )
        )
    if stats["radial_piston_clearance_mm"] < 0.05:
        issues.append(
            Issue(
                "WARN",
                "power piston radial clearance",
                None,
                f"{stats['radial_piston_clearance_mm']:.3f} mm/side — very tight for print tolerance",
            )
        )
    return issues, stats


def main() -> None:
    angles = list(range(0, 360, 5))
    issues, stats = analyze_angles(angles)

    fails = [i for i in issues if i.severity == "FAIL"]
    warns = [i for i in issues if i.severity == "WARN"]
    infos = [i for i in issues if i.severity == "INFO"]

    print("=== LTDEngine interference / clearance analysis ===")
    print(f"Sweep: crank 0–355° every 5° ({len(angles)} positions), Assembled-mode kinematics")
    print()
    print("Design clearances (static):")
    print(f"  Power piston radial: {stats['radial_piston_clearance_mm']:.3f} mm/side")
    print(f"  Displacer radial:    {DISP_RADIAL_CLEARANCE:.2f} mm/side")
    print(f"  Displacer axial:     {DISP_AXIAL_CLEARANCE:.2f} mm end")
    print(f"  Power piston axial:  {POWER_PISTON_AXIAL_CLEARANCE:.2f} mm end")
    print()
    print("Kinematic ranges:")
    print(
        f"  Displacer steel rod (flange→displacer): {stats['displacer_shaft_len']:.3f} mm (fixed)"
    )
    print(
        f"  Assembled power link pin span:          {stats['power_link_len']:.3f} mm (fixed)"
    )
    print(
        f"  Displacer top clearance (min):          {stats['disp_top_clearance_min']:.3f} mm"
    )
    print(
        f"  Displacer bottom clearance (min):       {stats['disp_bottom_clearance_min']:.3f} mm"
    )
    print(
        f"  Power piston top clearance (min):       {stats['piston_top_clearance_min']:.3f} mm"
    )
    print(
        f"  Power piston bottom clearance (min):    {stats['piston_bottom_clearance_min']:.3f} mm"
    )
    print()

    if fails:
        print(f"FAILURES ({len(fails)}):")
        seen = set()
        for i in fails:
            key = (i.check, i.detail)
            if key in seen:
                continue
            seen.add(key)
            ang = f" @ {i.angle:.0f}°" if i.angle is not None else ""
            print(f"  [{i.check}]{ang}: {i.detail}")
        print()
    else:
        print("No hard kinematic failures in swept analysis.")
        print()

    if warns:
        print(f"WARNINGS ({len(warns)}):")
        seen = set()
        for i in warns:
            key = (i.check, i.detail)
            if key in seen:
                continue
            seen.add(key)
            ang = f" @ {i.angle:.0f}°" if i.angle is not None else ""
            print(f"  [{i.check}]{ang}: {i.detail}")
        print()

    if infos:
        print("NOTES:")
        seen = set()
        for i in infos:
            key = (i.check, i.detail)
            if key in seen:
                continue
            seen.add(key)
            print(f"  [{i.check}]: {i.detail}")
        print()

    print("Intentional contact (not bugs): snap ring clamp shelf on cold plate; crank pins in link forks.")
    print("Limitation: coarse envelope checks only — no full 3D mesh intersection. Visually inspect flywheel/frame and link vs webs in OpenSCAD preview.")


if __name__ == "__main__":
    main()
