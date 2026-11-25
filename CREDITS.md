# Credits

## Exercise illustrations

The exercise art in `assets/art/` comes from
[Workout Guide](https://github.com/bryllim/workout-guide) by
[Bryl Lim](https://bryllim.com), which builds on pose artwork from
[Everkinetic](https://github.com/everkinetic/data).

Both are licensed under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/), and GymMane's
copy stays under that same license — the rest of the app is GPLv3.

**Changes made.** Each Workout Guide frame is a 512 × 512 SVG holding a single
`<path>`. That path data was lifted into one plain-text file per exercise —
three lines, one per frame — so the app draws it with `path_drawing` and tints
it with the current theme instead of shipping a fixed-colour image. The
geometry is untouched.

**Presentation.** When a real-human clip is not available, those same frames
are drawn as crisp monochrome silhouettes on a light card, framed with a little
padding so the figure sits cleanly in the layout. The path geometry is
unchanged and stays CC BY-SA 4.0.


## Exercise demo videos

Built-in demonstrations in the top demo area are original flat anatomical
diagram loops in `assets/demos/video/`, with start-frame posters in
`assets/demos/diagram/`. Each clip is a short muted H.264 loop of the named
movement (HQ 960×720, Option A style). The mapping is conservative: a clip
attaches only to the exercise it depicts, never to close variations that share
an art slug. Copy new `hq/<slug>.mp4` files with `scripts/sync_hq_demos.sh`
and rebuild.

The older Mixkit videos, Wikimedia photographs, 3D renders, and flat-shaded
mannequin assets were removed from `assets/` and are not shipped.

### What was not used

[yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) is
Unlicense for its JSON, but the photographs have unclear provenance. The
maintainer has said they do not know where the images came from, and later
discussion points to some frames possibly originating on ExRx.net. Those
photos, and wger copies credited to that project, are not included.

wger.de community “PHOTO” uploads were also reviewed and not shipped. Many
are miscategorized illustrations, anatomy renders, or graphics with third-party
watermarks, and wger’s own maintainers have noted that community image
licenses may need cleanup. wger’s Goulart videos (CC BY-SA 4.0) were
considered for gym-machine movements; this pass did not bundle them (large
HEVC sources, and the Home Workout library is mostly bodyweight work those
clips do not cover).

## Body-diagram exercise images

Exercise images use GymMane's original flat anatomical body-diagram style.
The standard push-up still in `assets/demos/diagram/push-up.png` is an
original GymMane diagram (chest and triceps highlighted in the app lime).
Other exercises reuse the in-app muscle-map figure
(`lib/catalog/body_svg.dart`) with the relevant muscles highlighted.
A light bob, tilt, and pulsing highlight is applied in the app only on
the top demo of the detail and session screens; list thumbnails, cards,
and panel icons stay static.

The Mixkit clip previously shown for the standard push-up is still
shipped at `assets/demos/video/push-up.mp4` under its original Free
License; the app prefers the body diagram for `I4hDWkc`.

## Outfit typeface

The UI uses [Outfit](https://github.com/Outfitio/Outfit-Fonts) by
[Rodrigo Fuenzalida](https://www.rodrigo.fuenzalida.com/) and
[Smarttype Foundry](https://www.smarttypefoundry.com/), licensed under the
[SIL Open Font License 1.1](https://scripts.sil.org/OFL). The license text is
vendored at `assets/fonts/outfit/OFL.txt`.

Every exercise in the catalogue names the illustration it uses in its `art:`
field, and the files under `assets/art/` are named after the Workout Guide
exercise they come from, so any frame can be traced back to its original.
Several exercises share one illustration when they are the same movement done
with different equipment.

**Taken straight from Everkinetic.** 88 illustrations that Workout Guide does
not use come directly from the Everkinetic `dist/svg/` drawings: each
exercise's two poses (`NNNN-relaxation.svg` and `NNNN-tension.svg`) were
rasterized, cropped to the same box so they stay aligned, recoloured for
monochrome display and vector-traced with potrace into a single path per pose,
the same treatment Workout Guide gives its Everkinetic frames. Those files hold
two lines instead of three.

**From Open Exercise Art.** `reverse-pec-deck` and `bayesian-cable-curl` start from
single drawings of [Open Exercise Art](https://github.com/AlexMollard/Open-Exercise-Art)
by Alex Mollard, under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/):
`reverse-pec-deck.svg` and `one-arm-cable-curl.svg`. The other two frames of each were made
by moving the arms and the machine parts of that same drawing; the body and the line weight
are unchanged.

## Fonts

Nunito, by the Nunito Project Authors, under the SIL Open Font License
(`assets/fonts/Nunito-OFL.txt`).
