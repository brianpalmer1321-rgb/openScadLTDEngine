#!/usr/bin/env python3
"""Export Can401 engine snap ring profile to profiles/can401_snap_ring.dxf.

Profile matches can401_engine_snap_ring_profile() in Can401_lib.scad
(clamp face at z=0 for upside-down print, dual 45° bead, mouth hold-down shelf).
"""

from __future__ import annotations

import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "Can401_lib.scad"
OUT = ROOT / "profiles" / "can401_snap_ring.dxf"

PLATE_OD = 99.21 - 2 * 0.25
CLAMP_OVERHANG = 2.5
WEDGE_COMPRESS = 0.30


def parse_constants(scad_path: Path) -> dict[str, float]:
    text = scad_path.read_text()
    names = (
        "can_rim_od",
        "can_rim_h",
        "can_h",
        "can_wall_t",
        "can_body_od",
        "lid_slip_clearance",
        "lid_skirt_h",
        "bead_id",
        "bead_h",
        "bead_below_seam",
        "bead_chamfer",
        "ring_wedge_compress",
        "ring_bead_z_offset",
        "ring_bead_z_base",
        "ring_od_extra",
        "ring_od_extra_base",
        "ring_diameter_adjust",
    )
    out: dict[str, float] = {}
    for name in names:
        m = re.search(rf"^{name}\s*=\s*([0-9.+-]+)", text, re.MULTILINE)
        if not m:
            raise RuntimeError(f"Could not parse {name} from {scad_path}")
        out[name] = float(m.group(1))
    return out


def cold_plate_drop(c: dict[str, float], plate_od: float) -> float:
    inner_d = c["can_body_od"] - 2 * c["can_wall_t"]
    ri = inner_d / 2
    seam_ri = ri + 0.35
    z_rim = c["can_h"] - c["can_rim_h"]
    z_step = z_rim + 0.55
    plate_r = plate_od / 2
    if plate_r <= ri:
        seat_z = z_rim
    elif plate_r >= seam_ri:
        seat_z = c["can_h"]
    else:
        seat_z = z_rim + (plate_r - ri) * (z_step - z_rim) / (seam_ri - ri)
    return c["can_h"] - seat_z


def engine_snap_ring_profile(
    c: dict[str, float],
    plate_od: float,
    plate_drop: float,
    clamp_overhang: float,
    wedge_compress: float,
) -> list[tuple[float, float]]:
    lid_id = c["can_rim_od"] + 2 * c["lid_slip_clearance"]
    lid_od = lid_id + 2.0
    lid_r = lid_od / 2
    lid_ir = lid_id / 2
    bead_ir = c["bead_id"] / 2
    bead_z = c["can_rim_h"] + c["bead_h"] / 2 + c["bead_below_seam"]
    bead_z0 = bead_z - c["bead_h"] / 2
    bead_z1 = bead_z0 + c["bead_h"]

    plate_r = plate_od / 2
    clamp_ir = plate_r - clamp_overhang
    dia_adj = c.get("ring_diameter_adjust", 0.0)
    skirt_ir = lid_ir + dia_adj / 2
    snap_ir = bead_ir + dia_adj / 2
    outer_r = (
        lid_r
        + c.get("ring_od_extra_base", 0.0)
        + c.get("ring_od_extra", 0.0)
        + dia_adj / 2
    )
    chamfer_dz = (skirt_ir - snap_ir) * math.tan(math.radians(c["bead_chamfer"]))
    z_mouth = plate_drop
    z_top = plate_drop + c["lid_skirt_h"]
    z_off = c.get("ring_bead_z_base", 0.0) + c.get("ring_bead_z_offset", 0.0)
    z_bead0 = plate_drop + bead_z0 + z_off
    z_bead1 = plate_drop + bead_z1 + z_off
    z_chamfer_hi = z_bead1 + chamfer_dz  # tip-side 45°
    z_chamfer_lo = z_bead0 - chamfer_dz  # clamp-side 45° (printable from bed)

    return [
        (clamp_ir, 0.0),
        (outer_r, 0.0),
        (outer_r, z_top),
        (skirt_ir, z_top),
        (skirt_ir, z_chamfer_hi),
        (snap_ir, z_bead1),
        (snap_ir, z_bead0),
        (skirt_ir, z_chamfer_lo),
        (skirt_ir, z_mouth),
        (clamp_ir, z_mouth),  # hold-down shelf (on plate top after assembly flip)
    ]


def dxf_lwpolyline(handle: str, layer: str, points: list[tuple[float, float]]) -> str:
    lines = [
        "0",
        "LWPOLYLINE",
        "5",
        handle,
        "100",
        "AcDbEntity",
        "8",
        layer,
        "100",
        "AcDbPolyline",
        "90",
        str(len(points)),
        "70",
        "1",
        "43",
        "0.0",
    ]
    for x, y in points:
        lines.extend(["10", f"{x}", "20", f"{y}"])
    lines.append("0")
    return "\n".join(lines)


def write_dxf(path: Path, profile: list[tuple[float, float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(
            [
                "0",
                "SECTION",
                "2",
                "HEADER",
                "9",
                "$ACADVER",
                "1",
                "AC1014",
                "9",
                "$INSUNITS",
                "70",
                "4",
                "0",
                "ENDSEC",
                "0",
                "SECTION",
                "2",
                "ENTITIES",
                dxf_lwpolyline("20A", "SNAP_RING", profile),
                "0",
                "ENDSEC",
                "0",
                "EOF",
            ]
        )
        + "\n"
    )


def main() -> None:
    c = parse_constants(LIB)
    drop = cold_plate_drop(c, PLATE_OD)
    profile = engine_snap_ring_profile(
        c, PLATE_OD, drop, CLAMP_OVERHANG, WEDGE_COMPRESS
    )
    write_dxf(OUT, profile)
    height = max(p[1] for p in profile)
    od = 2 * max(p[0] for p in profile)
    print(f"Wrote {OUT}")
    print(f"  plate_drop={drop:.3f} mm  height={height:.3f} mm  OD={od:.3f} mm")


if __name__ == "__main__":
    main()
