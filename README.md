# LTD Stirling Engine (OpenSCAD)

Parametric 3D model of a **Low Temperature Differential (LTD) Stirling engine** sized around a ~100 mm tuna-can hot cylinder, with animated crank/linkage kinematics.

## Requirements

- [OpenSCAD](https://openscad.org/) (2021.01 or newer recommended for Customizer)

## Quick start

1. Open `LTDEngine.scad` in OpenSCAD.
2. Use the **Customizer** panel to change mode, animation, and hardware parameters.
3. Press **F5** (preview) or **F6** (render), then export STLs from **Individual** mode for printing.
4. In **Individual** mode, set **export_part** to one part (or **All on plate**), render, and export STL.

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
| `profiles/canSnapRing.dxf` | TPU snap ring 2D profile (revolved in `can_snap_ring()`) |
| `tools/sync_snap_ring_profile.py` | Re-sync `snap_ring_profile` in SCAD after editing the DXF |
| `LTDEngine.scad.txt` | Earlier prototype (displacer cap + A-frames) |

## Parts list

Names below match the OpenSCAD modules and assembly labels used in `LTDEngine.scad`. Use **Individual** mode to export STLs for printed parts.

### Fabricated parts

| Part name | Module | Qty | Role |
|-----------|--------|-----|------|
| Cold plate | `cold_plate()` | 1 | **Aluminum** top deck (default 97.25 mm OD × 6.35 mm); mounts seal bore, power cylinder boss, frame slots, and heat-set inserts. Machined from plate stock; STL in Individual mode is for reference or optional printing. |

### Printed parts

| Part name | Module | Qty | Role |
|-----------|--------|-----|------|
| Can snap ring | `can_snap_ring()` | 1 | **TPU** ring from `profiles/can_snap_ring.dxf` profile; snaps on can rim and clamps cold plate |
| Support frame (left) | `support_frame()` | 1 | Crankshaft bearing tower, left side |
| Support frame (right) | `support_frame()` | 1 | Crankshaft bearing tower, right side (mirror of left) |
| Flywheel | `flywheel_geom()` | 1 | Main inertia wheel on crankshaft |
| Displacer crank arm | `crank_arm()` | 4 | Two per displacer web sandwich (inner + outer plate) |
| Power crank arm | `crank_arm()` | 4 | Two per power-piston web sandwich (inner + outer plate) |
| Displacer connecting rod | `linkage_rod()` | 1 | Crank to displacer rod flange (length varies with angle) |
| Power connecting rod | `linkage_rod()` | 1 | Crank to power piston pin (length varies with angle) |
| Displacer rod flange | `rod_flange()` | 1 | Clevis hub at top of displacer shaft |
| Displacer | `displacer()` | 1 | Hot-side displacer disc |
| Displacer shaft | `displacer_rod()` | 1 | Steel rod from flange to displacer (length is parametric) |
| Power cylinder | `power_cylinder()` | 1 | Power piston bore / cylinder block |
| Power piston | `power_piston()` | 1 | Cold-side power piston |

### Crankshaft (not a single module)

The crankshaft is built from **3 mm rod** segments in the assembly (grey cylinders in the model):

| Part name | Qty | Role |
|-----------|-----|------|
| Crankshaft segment (flywheel to displacer) | 1 | Flywheel hub to displacer crank station |
| Crankshaft segment (displacer to power) | 1 | Displacer crank to power crank station |
| Crankshaft segment (power to frame) | 1 | Power crank to right bearing |
| Crankshaft segment (frame to flywheel) | 1 | Left bearing to flywheel (short stub) |

### Purchased / non-printed parts

| Part name | Module (reference) | Qty | Notes |
|-----------|-------------------|-----|-------|
| Tuna tin can (hot cylinder) | `tuna_tin_can()` | 1 | ~100 mm OD × 47 mm tall |
| Brass seal tube | (bore in `cold_plate()`) | 1 | 4.7 mm OD × 3.0 mm ID × 15 mm long |
| Crankshaft rod stock | `rod_od` | 1 | 3 mm diameter, cut to total crank length |
| Crank pins (linkage) | (holes in `linkage_rod()`) | 4 | 1.5 mm pins at rod ends (displacer + power × 2) |
| Displacer flange pin | (hole in `rod_flange()`) | 1 | 1.5 mm |
| Power piston pin | (hole in `power_piston()`) | 1 | 1.5 mm |
| Crank arm pins | (holes in `crank_arm()`) | 8 | 1.5 mm at small crank radius (4 arms × 2 ends conceptually; 4 arms with one pin each) |

### Hardware

| Part name | Parameter | Qty | Notes |
|-----------|-----------|-----|-------|
| Frame mounting screw | `screw_d` | 4 | M3 × ~16 mm pitch across frames (2 per frame) |
| M3 heat-set insert | `insert_hole_d` / `insert_depth` | 4 | Brass inserts in cold plate (2 per frame mount) |
| Crank-arm setscrew | `setscrew_d` | 4 | M3 grub screw per crank arm collar (timing trim) |
| Frame bearing | `bearing_pocket()` | 2 | 8×4×3 mm (e.g. S693ZZ / S693-2RS class) |

### Individual mode layout (export reference)

When `mode = "Individual"`, parts are placed on the build plate in this order (left to right):

| Part name | Approx. layout position |
|-----------|-------------------------|
| Cold plate (aluminum; insert pockets up) | Left — optional STL export |
| Can snap ring | Left of cold plate |
| Power cylinder | Right of cold plate |
| Power piston | Center |
| Displacer connecting rod | Lower left |
| Power connecting rod | Lower right |
| Support frame | Upper left (rotated flat for printing) |
| Flywheel | Upper right |
| Displacer crank arm | Lower center-left |
| Power crank arm | Lower center-right |
| Displacer rod flange (clevis up) | Lower center |

Export each solid separately from the rendered view, or split the file into per-part SCAD files if your workflow requires it.

## Design notes

- Swept-volume ratio defaults to **40:1** (displacer → power cylinder sizing).
- Power piston runs **90°** out of phase with the displacer crank.
- Hardware assumptions: M3 mounting screws, M3 heat-set inserts in the **aluminum** cold plate, 8×4×3 mm bearings on the crank axle.
- Cold plate defaults: **97.25 mm OD × 6.35 mm** (`cold_plate_od`, `cold_plate_t` in Customizer). **TPU** snap ring clamp lip holds it on the can mouth; tune `ring_plastic_clearance` if the rim fit is too tight or loose.
