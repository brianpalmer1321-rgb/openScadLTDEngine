#!/usr/bin/env python3
"""Legacy: sync snap_ring_profile in LTDEngine.scad from profiles/*.dxf.

LTDEngine now uses can401_engine_snap_ring_profile() from Can401_lib.scad.
Use tools/export_can401_snap_ring_dxf.py to export the current parametric profile.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROFILE_DIR = ROOT / "profiles"
DXF_CANDIDATES = [
    PROFILE_DIR / "canSnapRing.dxf",
    PROFILE_DIR / "can_snap_ring.dxf",
]
SCAD = ROOT / "LTDEngine.scad"


def find_dxf() -> Path:
    existing = [p for p in DXF_CANDIDATES if p.is_file()]
    if not existing:
        raise FileNotFoundError(
            f"No snap ring DXF found in {PROFILE_DIR} "
            f"(expected one of: {', '.join(p.name for p in DXF_CANDIDATES)})"
        )
    return max(existing, key=lambda p: p.stat().st_mtime)


def parse_lwpolyline_vertices(dxf_text: str) -> list[tuple[float, float]]:
    lines = dxf_text.splitlines()
    verts: list[tuple[float, float]] = []
    in_poly = False
    i = 0
    while i < len(lines):
        code = lines[i].strip()
        if code == "LWPOLYLINE":
            in_poly = True
            verts.clear()
            i += 1
            continue
        if in_poly:
            if code == "0":
                nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
                if nxt in {"ENDSEC", "LINE", "LWPOLYLINE", "CIRCLE", "ARC"}:
                    break
            if code == "10" and i + 3 < len(lines) and lines[i + 2].strip() == "20":
                verts.append((float(lines[i + 1]), float(lines[i + 3])))
                i += 4
                continue
        i += 1
    if not verts:
        raise ValueError(f"No LWPOLYLINE found in {DXF}")
    return verts


def to_revolve_profile(verts: list[tuple[float, float]]) -> tuple[float, list[tuple[float, float]]]:
    y0 = -min(y for _, y in verts)
    profile = [(x, y + y0) for x, y in verts]

    area = 0.0
    for (x0, y0p), (x1, y1p) in zip(profile, profile[1:] + profile[:1]):
        area += x0 * y1p - x1 * y0p
    if area < 0:
        profile = list(reversed(profile))

    # Reorder from inner-bottom for stable SCAD diffs.
    z_eps = 1e-6
    z_min = min(p[1] for p in profile)
    bottom = sorted([p for p in profile if abs(p[1] - z_min) < z_eps], key=lambda p: p[0])
    start = bottom[0]
    idx = profile.index(start)
    profile = profile[idx:] + profile[:idx]

    return y0, profile


def format_profile(profile: list[tuple[float, float]]) -> str:
    lines = ["snap_ring_profile = ["]
    for x, z in profile:
        lines.append(f"    [{x}, {z}],")
    lines[-1] = lines[-1].rstrip(",")
    lines.append("];")
    return "\n".join(lines)


def patch_scad(y0: float, profile: list[tuple[float, float]], dxf_name: str) -> bool:
    text = SCAD.read_text()
    profile_block = format_profile(profile)
    new_text, n = re.subn(
        r"// TPU snap ring: revolved profile from profiles/[^\n]+\n"
        r"ring_profile_y0 = [0-9.+-]+;\n"
        r"snap_ring_profile = \[\n(?:.*?\n)*?\];",
        f"// TPU snap ring: revolved profile from profiles/{dxf_name} (mm; Y offset −{y0} → z=0)\n"
        f"ring_profile_y0 = {y0};\n{profile_block}",
        text,
        count=1,
        flags=re.DOTALL,
    )
    if n != 1:
        raise RuntimeError("Could not locate snap_ring_profile block in LTDEngine.scad")
    if new_text == text:
        return False
    SCAD.write_text(new_text)
    return True


def main() -> None:
    dxf = find_dxf()
    verts = parse_lwpolyline_vertices(dxf.read_text())
    y0, profile = to_revolve_profile(verts)
    changed = patch_scad(y0, profile, dxf.name)
    height = max(p[1] for p in profile)
    od = 2 * max(p[0] for p in profile)
    print(f"Parsed {len(profile)} vertices from {dxf.name}")
    print(f"  y0={y0:.6g} mm  height={height:.6g} mm  OD={od:.6g} mm")
    if changed:
        print(f"Updated {SCAD.name}")
    else:
        print(f"{SCAD.name} already matches DXF")


if __name__ == "__main__":
    main()
