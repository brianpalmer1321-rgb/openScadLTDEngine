#!/usr/bin/env python3
"""Export Can401 engine snap ring profile to profiles/can401_snap_ring.dxf.

Profile matches can401_engine_snap_ring_profile() in Can401_lib.scad
(lid-skirt can grip + cold-plate hook).
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "Can401_lib.scad"
OUT = ROOT / "profiles" / "can401_snap_ring.dxf"

# LTDEngine defaults for plate hook (also in LTDEngine.scad customizer)
PLATE_OD = 97.25
CLAMP_OVERHANG = 2.5


def parse_constants(scad_path: Path) -> dict[str, float]:
    text = scad_path.read_text()
    names = (
        "can_rim_od",
        "can_rim_h",
        "lid_slip_clearance",
        "lid_skirt_h",
        "bead_id",
        "bead_h",
        "bead_below_seam",
        "bead_chamfer",
        "ring_grip_z0",
        "ring_clamp_shelf_z",
    )
    out: dict[str, float] = {}
    for name in names:
        m = re.search(rf"^{name}\s*=\s*([0-9.+-]+)", text, re.MULTILINE)
        if not m:
            raise RuntimeError(f"Could not parse {name} from {scad_path}")
        out[name] = float(m.group(1))
    return out


def engine_snap_ring_profile(
    c: dict[str, float], plate_od: float, clamp_overhang: float
) -> list[tuple[float, float]]:
    import math

    lid_id = c["can_rim_od"] + 2 * c["lid_slip_clearance"]
    lid_od = lid_id + 2.0
    lid_r = lid_od / 2
    lid_ir = lid_id / 2
    bead_ir = c["bead_id"] / 2
    bead_z = c["can_rim_h"] + c["bead_h"] / 2 + c["bead_below_seam"]
    bead_z0 = bead_z - c["bead_h"] / 2
    bead_z1 = bead_z0 + c["bead_h"]
    chamfer_drop = (lid_ir - bead_ir) * math.tan(math.radians(c["bead_chamfer"]))

    hook_r = plate_od / 2 - clamp_overhang
    foot_r = lid_r
    grip_z0 = c["ring_grip_z0"]
    z_top = grip_z0 + c["lid_skirt_h"]
    z_bead0 = grip_z0 + bead_z0
    z_bead1 = grip_z0 + bead_z1
    z_chamfer = grip_z0 + bead_z1 + chamfer_drop

    return [
        (hook_r, 0.0),
        (foot_r, 0.0),
        (foot_r, z_top),
        (lid_ir, z_top),
        (lid_ir, z_chamfer),
        (bead_ir, z_bead1),
        (bead_ir, z_bead0),
        (lid_ir, z_bead0),
        (lid_ir, grip_z0),
        (hook_r, c["ring_clamp_shelf_z"]),
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
    profile = engine_snap_ring_profile(c, PLATE_OD, CLAMP_OVERHANG)
    write_dxf(OUT, profile)
    height = max(p[1] for p in profile)
    od = 2 * max(p[0] for p in profile)
    print(f"Wrote {OUT}")
    print(f"  height={height:.3f} mm  OD={od:.3f} mm  vertices={len(profile)}")


if __name__ == "__main__":
    main()
