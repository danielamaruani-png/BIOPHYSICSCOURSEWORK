# PhysiGrab VR Bowling — Project Documentation

This document explains the systems built for the VR bowling project, so that
someone who has never seen the project can understand what was built, why,
and how to modify it.

## Table of Contents

1. [Ball Launch Deviation (Angle Control)](#1-ball-launch-deviation-angle-control)

---

## 1. Ball Launch Deviation (Angle Control)

### What it does

When the player releases the bowling ball in VR, the ball normally flies in
whatever direction the player's real hand motion gives it. This system adds
a **controlled, adjustable horizontal deviation** on top of that natural
throw: the ball's flight direction is rotated left or right by a fixed
number of degrees, while its speed stays exactly what the player actually
threw.

This exists so that the effect of throw angle on the game outcome (e.g. pins
knocked down) can be tested in a controlled way, independent of how
consistently the player can physically aim — an experimental variable for
the coursework, not just a gameplay feature.

### Where it lives

Blueprint: `Grabbable_SmallCube` (the ball's Blueprint), in its Event Graph,
on the same execution chain that runs when the ball is released.

### The variable: `LaunchAngleDegrees`

- Type: `Float`
- Marked **Instance Editable**, so it can be set per-instance from the
  **Details panel** in the level (select the ball actor, use the search bar
  in Details and type "LaunchAngle" to find it — it appears under a category
  named after the Blueprint, e.g. "Grabbable Small Cube").
- Default meaning:
  - `0` = no deviation, ball flies exactly where the player's hand aimed it.
  - Positive/negative values rotate the direction left or right by that many
    degrees (test with a small value like `20` first to confirm which sign
    means "left" vs "right" — this depends on the level's coordinate axes).
  - `90` = the ball's direction is rotated a full quarter turn from the
    original throw direction, **regardless of how fast or slow the ball was
    thrown** — rotation only changes direction, never speed.

### The logic (node by node)

On the Release execution chain, before the ball is allowed to fly freely:

1. **Get Physics Linear Velocity** (Target = the ball's Static Mesh
   component) — reads the ball's actual velocity vector at the moment of
   release, as physically thrown by the player's hand. This is a *pure*
   node (no exec pins); it's evaluated lazily wherever its output is wired.

2. **Rotate Vector Around Axis** — takes that raw velocity vector and
   rotates it:
   - `In Vect` = the velocity vector from step 1
   - `Axis` = `(X=0, Y=0, Z=1)`, i.e. the world's vertical axis — this
     keeps the rotation horizontal (left/right), not tilting the ball up
     or down.
   - `Angle (Deg)` = `Get LaunchAngleDegrees`

   Rotating a vector around an axis changes only its direction, not its
   length — so the ball's speed is mathematically guaranteed to stay the
   same before and after this step.

3. **Set Physics Linear Velocity** — writes the rotated vector back onto the
   ball's physics body:
   - `Target` = the ball's Static Mesh component
   - `New Velocity` = the rotated vector from step 2
   - `VelChange` / `bAddToCurrent` = **unchecked (False)** — this replaces
     the ball's velocity outright rather than adding to it. If this were
     left checked, the deviation would stack on top of the original
     velocity instead of redirecting it, giving wrong results.

This whole block runs at release time, before the ball is measured for the
data log (see the bowling attempt recording system, documented separately),
so the logged `BallDirection` for that attempt already reflects the
deviated trajectory, not the player's raw, un-rotated throw.

### How to modify it

- **Change the deviation for a test run**: select the ball actor in the
  level, find `LaunchAngleDegrees` in Details, type a new value (e.g. `0`,
  `20`, `45`, `70`, `-30`), save, and re-run the level.
- **Change which axis the deviation rotates around** (e.g. to make it a
  vertical/up-down deviation instead of left/right): change the `Axis` input
  on `Rotate Vector Around Axis` from `(0,0,1)` to `(1,0,0)` or `(0,1,0)`
  depending on the level's layout, and re-test to confirm the direction
  makes sense.
- **Make the deviation happen automatically instead of manually**: replace
  the `Get LaunchAngleDegrees` read with a random value (e.g.
  `Random Float in Range`) generated once per throw, if the goal shifts from
  "fixed, chosen angle" to "randomized deviation" as an experimental noise
  source.

### Known limitations

- The angle is applied once, at release. If the ball's velocity is somehow
  changed again mid-flight by other game logic, this deviation will not be
  re-applied.
- No validation is done on the `LaunchAngleDegrees` value — entering
  something like `400` degrees is mathematically valid (rotation wraps
  around) but likely not a meaningful test condition.
