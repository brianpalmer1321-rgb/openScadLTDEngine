# LTD Stirling Engine (OpenSCAD)

Parametric 3D model of a **Low Temperature Differential (LTD) Stirling engine** sized around a ~100 mm tuna-can hot cylinder, with animated crank/linkage kinematics.

## Requirements

- [OpenSCAD](https://openscad.org/) (2021.01 or newer recommended for Customizer)

## Quick start

1. Open `LTDEngine.scad` in OpenSCAD.
2. Use the **Customizer** panel to change mode, animation, and hardware parameters.
3. Press **F5** (preview) or **F6** (render), then export STLs from **Individual** mode for printing.

## Customizer modes

| Mode | Purpose |
|------|---------|
| `Assembled` | Full engine with crank animation |
| `Exploded` | Assembly with vertical separation |
| `Individual` | Parts laid out for STL export |

## Files

| File | Description |
|------|-------------|
| `LTDEngine.scad` | Main parametric model |
| `LTDEngine.scad.txt` | Earlier prototype (displacer cap + A-frames) |

## Design notes

- Swept-volume ratio defaults to **40:1** (displacer → power cylinder sizing).
- Power piston runs **90°** out of phase with the displacer crank.
- Hardware assumptions: M3 mounting screws, 8×4×3 mm bearings on the crank axle.
