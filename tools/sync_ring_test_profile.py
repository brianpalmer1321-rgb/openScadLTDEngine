#!/usr/bin/env python3
"""Sync Fusion snap ring DXF into ringTest.scad as a revolve profile polygon.

Reads canSnapRingFusionExport.dxf (repo root), tessellates bulge arcs,
converts Fusion −X sketch coords to radius = abs(x), shifts min-Y → z=0.
"""

from __future__ import annotations

import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DXF = ROOT / "canSnapRingFusionExport.dxf"
SCAD = ROOT / "ringTest.scad"
ARC_SEGMENTS = 12


def parse_lwpolyline(dxf_text: str) -> tuple[list[tuple[float, float]], list[float], bool]:
    lines = dxf_text.splitlines()
    verts: list[tuple[float, float]] = []
    bulges: list[float] = []
    closed = False
    in_poly = False
    pending_x: float | None = None
    i = 0
    while i < len(lines):
        code = lines[i].strip()
        if code == "LWPOLYLINE":
            in_poly = True
            verts.clear()
            bulges.clear()
            closed = False
            pending_x = None
            i += 1
            continue
        if not in_poly:
            i += 1
            continue
        if code == "0":
            nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
            if nxt in {"ENDSEC", "LINE", "LWPOLYLINE", "CIRCLE", "ARC"}:
                break
        if code == "70" and i + 1 < len(lines):
            closed = bool(int(float(lines[i + 1])) & 1)
        elif code == "10" and i + 1 < len(lines):
            pending_x = float(lines[i + 1])
        elif code == "20" and i + 1 < len(lines) and pending_x is not None:
            verts.append((pending_x, float(lines[i + 1])))
            bulges.append(0.0)
            pending_x = None
        elif code == "42" and i + 1 < len(lines) and bulges:
            bulges[-1] = float(lines[i + 1])
        i += 1
    if not verts:
        raise ValueError(f"No LWPOLYLINE found in {DXF}")
    return verts, bulges, closed


def bulge_arc_points(
    p0: tuple[float, float],
    p1: tuple[float, float],
    bulge: float,
    segments: int = ARC_SEGMENTS,
) -> list[tuple[float, float]]:
    if abs(bulge) < 1e-10:
        return []
    x0, y0 = p0
    x1, y1 = p1
    dx = x1 - x0
    dy = y1 - y0
    chord = math.hypot(dx, dy)
    if chord < 1e-12:
        return []
    theta = 4.0 * math.atan(bulge)
    sin_half = math.sin(theta / 2.0)
    if abs(sin_half) < 1e-12:
        return []
    radius = chord / (2.0 * sin_half)
    alpha = math.atan2(dy, dx)
    beta = math.pi / 2.0 - theta / 2.0
    center_angle = alpha - beta if bulge > 0 else alpha + beta
    cx = x0 + radius * math.cos(center_angle)
    cy = y0 + radius * math.sin(center_angle)
    a0 = math.atan2(y0 - cy, x0 - cx)
    a1 = math.atan2(y1 - cy, x1 - cx)
    if bulge > 0:
        if a1 <= a0:
            a1 += 2.0 * math.pi
    else:
        if a1 >= a0:
            a1 -= 2.0 * math.pi
    return [
        (
            cx + radius * math.cos(a0 + (a1 - a0) * t / segments),
            cy + radius * math.sin(a0 + (a1 - a0) * t / segments),
        )
        for t in range(1, segments)
    ]


def tessellate_polyline(
    verts: list[tuple[float, float]],
    bulges: list[float],
    closed: bool,
) -> list[tuple[float, float]]:
    n = len(verts)
    if n < 2:
        return verts
    out = [verts[0]]
    seg_count = n if closed else n - 1
    for i in range(seg_count):
        p0 = verts[i]
        p1 = verts[(i + 1) % n]
        b = bulges[i] if i < len(bulges) else 0.0
        out.extend(bulge_arc_points(p0, p1, b))
        out.append(p1)
    return out


def to_revolve_profile(verts: list[tuple[float, float]]) -> tuple[float, list[tuple[float, float]]]:
    y0 = -min(y for _, y in verts)
    raw = [(abs(x), y + y0) for x, y in verts]
    profile: list[tuple[float, float]] = []
    for p in raw:
        if not profile or math.hypot(p[0] - profile[-1][0], p[1] - profile[-1][1]) > 1e-6:
            profile.append(p)

    area = 0.0
    for (x0, z0), (x1, z1) in zip(profile, profile[1:] + profile[:1]):
        area += x0 * z1 - x1 * z0
    if area < 0:
        profile = list(reversed(profile))

    z_eps = 1e-6
    z_min = min(p[1] for p in profile)
    bottom = sorted([p for p in profile if abs(p[1] - z_min) < z_eps], key=lambda p: p[0])
    start = bottom[0]
    idx = profile.index(start)
    profile = profile[idx:] + profile[:idx]
    return y0, profile


def format_profile_block(y0: float, profile: list[tuple[float, float]]) -> str:
    lines = [
        f"// Fusion snap ring profile from {DXF.name} (mm; DXF Y offset −{y0:.6g} → z=0)",
        f"ring_fusion_y0 = {y0:.6g};",
        "ring_fusion_profile = [",
    ]
    for r, z in profile:
        lines.append(f"    [{r:.6g}, {z:.6g}],")
    lines[-1] = lines[-1].rstrip(",")
    lines.append("];")
    return "\n".join(lines)


def patch_scad(block: str) -> bool:
    text = SCAD.read_text()
    new_text, n = re.subn(
        r"// Fusion snap ring profile from canSnapRingFusionExport\.dxf.*?\n"
        r"ring_fusion_y0 = [0-9.+-]+;\n"
        r"ring_fusion_profile = \[\n(?:.*?\n)*?\];",
        block,
        text,
        count=1,
        flags=re.DOTALL,
    )
    if n != 1:
        raise RuntimeError(f"Could not locate ring_fusion_profile block in {SCAD.name}")
    if new_text == text:
        return False
    SCAD.write_text(new_text)
    return True


def main() -> None:
    if not DXF.is_file():
        raise FileNotFoundError(f"Missing {DXF}")
    verts, bulges, closed = parse_lwpolyline(DXF.read_text())
    tess = tessellate_polyline(verts, bulges, closed)
    y0, profile = to_revolve_profile(tess)
    block = format_profile_block(y0, profile)
    changed = patch_scad(block)
    height = max(p[1] for p in profile)
    od = 2.0 * max(p[0] for p in profile)
    print(f"Parsed {len(verts)} DXF vertices (+ bulge tessellation → {len(profile)} points)")
    print(f"  y0={y0:.6g} mm  height={height:.6g} mm  OD={od:.6g} mm")
    if changed:
        print(f"Updated {SCAD.name}")
    else:
        print(f"{SCAD.name} already matches DXF")


if __name__ == "__main__":
    main()
