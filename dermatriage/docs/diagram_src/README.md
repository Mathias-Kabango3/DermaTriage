# Report diagrams — source

These scripts generate the DermaTriage report diagrams. Each is a small Python
program that emits an **SVG** into `docs/`, which headless Chrome then
rasterises to a **PNG @2×**. The `.svg` is vector (use it in the report / for
zooming); the `.png` is a ready-to-paste bitmap.

## Regenerate everything

```bash
./build.sh
```

Outputs (written to `docs/`):

| Diagram | Files | What it shows |
|---|---|---|
| System architecture | `architecture.{svg,png}` | Mobile app, Firebase, Cloudinary, review dashboard, ML training flywheel |
| Class diagram | `class_diagram.{svg,png}` | Domain entities, DAOs, services (incl. `Patient.name`, contribution pipeline) |
| Use-case diagram | `use_case.{svg,png}` | CHW + Reviewer actors and their use cases |
| Sequence diagram | `sequence_diagram.{svg,png}` | Contribution capture → offline queue → Cloudinary + Firestore → review |
| ER diagram | `er_diagram.{svg,png}` | SQLite schema (database v4), crow's-foot notation |

## Requirements

- `python3` (standard library only — no pip installs)
- Google Chrome (or Chromium) for rasterising

## How it's built

- `svgkit.py` — shared SVG builder: palette, primitives, brand-icon loader,
  title block, badges, arrow markers.
- `_icons_raw/*.svg` — real brand marks (Flutter, Firebase, Cloudinary,
  Next.js, React, PyTorch, TensorFlow, SQLite, Android, Dart, Google) from
  [Simple Icons](https://simpleicons.org). `svgkit.icon()` recolours them with
  each brand's real colour.
- `gen_*.py` — one script per diagram; edit these to change content, then
  re-run `build.sh`.

## Style conventions (keep these)

- **Reduced palette:** neutral greys + a single teal accent (`#00695c`).
  Colour only otherwise appears in the real brand icons.
- **Never clamp/clip** text or icons — widen the canvas (`Canvas(W, H)` and the
  matching size in `build.sh`'s `win()`) instead of cramming.
- New / changed items this iteration are highlighted in teal with a `new` or
  `updated` badge.
