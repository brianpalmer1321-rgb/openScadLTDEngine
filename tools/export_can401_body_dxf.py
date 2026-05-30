#!/usr/bin/env python3
"""Export Can401 body meridional cross-section to profiles/can401_body.dxf.

Mirrors geometry in Can401_lib.scad (can401_body outer envelope + inner bore).
DXF coordinates: X = radius (mm), Y = axial height Z (mm), Y=0 at can bottom.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "Can401_lib.scad"
OUT = ROOT / "profiles" / "can401_body.dxf"


def parse_constants(scad_path: Path) -> dict[str, float]:
    text = scad_path.read_text()
    names = (
        "can_body_od",
        "can_rim_od",
        "can_rim_h",
        "can_flange_step_h",
        "can_curl_h",
        "can_curl_drop",
        "can_wall_t",
        "can_h",
    )
    out: dict[str, float] = {}
    for name in names:
        m = re.search(rf"^{name}\s*=\s*([0-9.+-]+)", text, re.MULTILINE)
        if not m:
            raise RuntimeError(f"Could not parse {name} from {scad_path}")
        out[name] = float(m.group(1))
    return out


def outer_profile(c: dict[str, float]) -> list[tuple[float, float]]:
    rb = c["can_body_od"] / 2
    rs = c["can_rim_od"] / 2
    z_rim = c["can_h"] - c["can_rim_h"]
    z_step = z_rim + c["can_flange_step_h"]
    z_wall_top = c["can_h"] - c["can_curl_h"]
    return [
        (rb, z_rim),
        (rb + (rs - rb) * 0.22, z_rim + c["can_flange_step_h"] * 0.18),
        (rb + (rs - rb) * 0.72, z_rim + c["can_flange_step_h"] * 0.55),
        (rs, z_step),
        (rs, z_wall_top),
        (rs - c["can_curl_drop"], c["can_h"]),
        (rs, c["can_h"]),
    ]


def body_sections(c: dict[str, float]) -> tuple[list[tuple[float, float]], list[tuple[float, float]]]:
    rb = c["can_body_od"] / 2
    ri = (c["can_body_od"] - 2 * c["can_wall_t"]) / 2
    z_rim = c["can_h"] - c["can_rim_h"]
    body_z0 = 0.25
    bore_z0 = 0.5
    bore_z1 = c["can_h"] + 1.0

    outer: list[tuple[float, float]] = [(0.0, body_z0), (rb, body_z0), (rb, z_rim)]
    outer.extend(outer_profile(c)[1:])  # skip duplicate (rb, z_rim)
    outer.append((0.0, c["can_h"]))

    inner: list[tuple[float, float]] = [
        (0.0, bore_z0),
        (ri, bore_z0),
        (ri, bore_z1),
        (0.0, bore_z1),
    ]
    return outer, inner


def dxf_lwpolyline(handle: str, layer: str, points: list[tuple[float, float]], closed: bool) -> str:
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
        "1" if closed else "0",
        "43",
        "0.0",
    ]
    for x, y in points:
        lines.extend(["10", f"{x}", "20", f"{y}"])
    lines.append("0")
    return "\n".join(lines)


def write_dxf(path: Path, outer: list[tuple[float, float]], inner: list[tuple[float, float]]) -> None:
    entities = [
        dxf_lwpolyline("10A", "OUTER", outer, closed=True),
        dxf_lwpolyline("10B", "INNER", inner, closed=True),
    ]
    body = "\n".join(entities)
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
                body,
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
    outer, inner = body_sections(c)
    write_dxf(OUT, outer, inner)
    rb = c["can_body_od"] / 2
    rs = c["can_rim_od"] / 2
    print(f"Wrote {OUT}")
    print(f"  can_h={c['can_h']} mm  body_r={rb:.3f} mm  seam_r={rs:.3f} mm")
    print(f"  OUTER layer: {len(outer)} vertices (meridional wall + rim)")
    print(f"  INNER layer: {len(inner)} vertices (bore)")


if __name__ == "__main__":
    main()
