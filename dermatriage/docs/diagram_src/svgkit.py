"""
svgkit — tiny SVG builder shared by the DermaTriage report diagrams.

Design language (per project convention):
  * Reduced palette: neutral greys + a single teal accent (#00695c).
  * Real technology brand icons in their real brand colours (loaded from
    _icons_raw/*.svg, which are Simple Icons single-path glyphs).
  * Generous spacing — never clamp/clip text or icons; widen the canvas.

Each generator builds a Canvas, then main() writes <name>.svg to ../ (docs/).
render.sh rasterises every SVG to PNG @2x with headless Chrome.
"""

import os
import re

# ---------------------------------------------------------------- palette
INK = "#1f2933"       # primary text / headings
SUBINK = "#52606d"    # secondary text
FAINT = "#7b8794"     # tertiary / captions
LINE = "#9aa5b1"      # connectors
BORDER = "#cbd2d9"    # box borders
BG = "#ffffff"
PANEL = "#f6f8fa"     # light neutral fill
PANEL2 = "#eceff3"    # slightly darker neutral fill
HEADER = "#e7ebf0"    # table/class header fill

TEAL = "#00695c"      # the one accent
TEAL_LINE = "#00897b"
TEAL_FILL = "#e2f1ef"
TEAL_DEEP = "#004d40"
NEW = "#00695c"       # "new feature" highlight == accent

FONT = "'Helvetica Neue', Helvetica, Arial, sans-serif"
MONO = "'SF Mono', 'Menlo', 'Consolas', monospace"

# Real brand colours (chosen for legibility on white where the canonical
# tone is too light — e.g. Firebase amber, React blue, Android green).
BRAND = {
    "flutter": "#02569B",
    "dart": "#0175C2",
    "firebase": "#F57C00",
    "cloudinary": "#3448C5",
    "nextdotjs": "#111827",
    "react": "#087EA4",
    "pytorch": "#EE4C2C",
    "tensorflow": "#FF6F00",
    "sqlite": "#003B57",
    "android": "#249B60",
    "google": "#4285F4",
}

_ICON_DIR = os.path.join(os.path.dirname(__file__), "_icons_raw")
_icon_cache = {}


def _load_paths(slug):
    if slug in _icon_cache:
        return _icon_cache[slug]
    with open(os.path.join(_ICON_DIR, slug + ".svg")) as fh:
        raw = fh.read()
    paths = re.findall(r'd="([^"]+)"', raw)
    _icon_cache[slug] = paths
    return paths


def esc(t):
    return (
        str(t)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


class Canvas:
    def __init__(self, width, height, title=""):
        self.w = width
        self.h = height
        self.title = title
        self.parts = []

    def add(self, s):
        self.parts.append(s)
        return self

    # -- primitives -----------------------------------------------------
    def rect(self, x, y, w, h, r=0, fill=BG, stroke=BORDER, sw=1.4,
             dash=None, opacity=None, shadow=False):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        o = f' opacity="{opacity}"' if opacity is not None else ""
        f = ' filter="url(#soft)"' if shadow else ""
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        self.parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" ry="{r}"'
            f' fill="{fill}"{st}{d}{o}{f}/>'
        )
        return self

    def line(self, x1, y1, x2, y2, stroke=LINE, sw=1.4, dash=None,
             marker_end=None, marker_start=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        me = f' marker-end="url(#{marker_end})"' if marker_end else ""
        ms = f' marker-start="url(#{marker_start})"' if marker_start else ""
        self.parts.append(
            f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"'
            f' stroke="{stroke}" stroke-width="{sw}"{d}{me}{ms}/>'
        )
        return self

    def path(self, d, stroke=LINE, sw=1.4, fill="none", dash=None,
             marker_end=None, marker_start=None):
        da = f' stroke-dasharray="{dash}"' if dash else ""
        me = f' marker-end="url(#{marker_end})"' if marker_end else ""
        ms = f' marker-start="url(#{marker_start})"' if marker_start else ""
        self.parts.append(
            f'<path d="{d}" fill="{fill}" stroke="{stroke}"'
            f' stroke-width="{sw}"{da}{me}{ms}/>'
        )
        return self

    def poly(self, pts, fill=BG, stroke=BORDER, sw=1.4):
        p = " ".join(f"{x},{y}" for x, y in pts)
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        self.parts.append(f'<polygon points="{p}" fill="{fill}"{st}/>')
        return self

    def circle(self, cx, cy, r, fill=BG, stroke=BORDER, sw=1.4):
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        self.parts.append(
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"{st}/>'
        )
        return self

    def ellipse(self, cx, cy, rx, ry, fill=BG, stroke=BORDER, sw=1.4):
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        self.parts.append(
            f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}"'
            f' fill="{fill}"{st}/>'
        )
        return self

    def text(self, x, y, s, size=13, fill=INK, weight=400, anchor="start",
             font=FONT, italic=False, spacing=None):
        it = ' font-style="italic"' if italic else ""
        ls = f' letter-spacing="{spacing}"' if spacing else ""
        self.parts.append(
            f'<text x="{x}" y="{y}" font-family="{font}" font-size="{size}"'
            f' font-weight="{weight}" fill="{fill}"'
            f' text-anchor="{anchor}"{it}{ls}>{esc(s)}</text>'
        )
        return self

    def icon(self, slug, x, y, size, color=None):
        color = color or BRAND.get(slug, INK)
        s = size / 24.0
        inner = "".join(
            f'<path d="{d}" fill="{color}"/>' for d in _load_paths(slug)
        )
        self.parts.append(
            f'<g transform="translate({x},{y}) scale({s:.5f})">{inner}</g>'
        )
        return self

    def icon_tile(self, slug, x, y, tile=34, pad=6, r=8,
                  fill="#ffffff", stroke=BORDER):
        """Brand icon centred inside a soft rounded tile."""
        self.rect(x, y, tile, tile, r=r, fill=fill, stroke=stroke, sw=1.2)
        self.icon(slug, x + pad, y + pad, tile - 2 * pad)
        return self

    # -- render ---------------------------------------------------------
    def svg(self):
        defs = f"""<defs>
  <filter id="soft" x="-8%" y="-8%" width="116%" height="120%">
    <feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#1f2933"
      flood-opacity="0.10"/>
  </filter>
  <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8"
    markerHeight="8" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="{LINE}"/>
  </marker>
  <marker id="arrowT" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8"
    markerHeight="8" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="{TEAL_LINE}"/>
  </marker>
  <marker id="open" viewBox="0 0 12 12" refX="10" refY="6" markerWidth="12"
    markerHeight="12" orient="auto-start-reverse">
    <path d="M1,1 L11,6 L1,11" fill="none" stroke="{SUBINK}"
      stroke-width="1.4"/>
  </marker>
  <marker id="openT" viewBox="0 0 12 12" refX="10" refY="6" markerWidth="12"
    markerHeight="12" orient="auto-start-reverse">
    <path d="M1,1 L11,6 L1,11" fill="none" stroke="{TEAL_LINE}"
      stroke-width="1.4"/>
  </marker>
  <marker id="tri" viewBox="0 0 14 14" refX="12" refY="7" markerWidth="14"
    markerHeight="14" orient="auto-start-reverse">
    <path d="M1,1 L13,7 L1,13 z" fill="#ffffff" stroke="{SUBINK}"
      stroke-width="1.3"/>
  </marker>
</defs>"""
        body = "\n".join(self.parts)
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}"'
            f' height="{self.h}" viewBox="0 0 {self.w} {self.h}"'
            f' font-family="{FONT}">\n'
            f'<rect width="{self.w}" height="{self.h}" fill="{BG}"/>\n'
            f'{defs}\n{body}\n</svg>\n'
        )

    def save(self, name):
        out = os.path.join(os.path.dirname(__file__), "..", name + ".svg")
        with open(out, "w") as fh:
            fh.write(self.svg())
        print("wrote", os.path.normpath(out))


# ---------------------------------------------------------- shared pieces
def title_block(c, x, y, title, subtitle=None):
    c.rect(x, y + 6, 5, 22, r=2.5, fill=TEAL, stroke=None)
    c.text(x + 16, y + 17, title, size=21, weight=700, fill=INK)
    if subtitle:
        c.text(x + 16, y + 37, subtitle, size=12.5, fill=FAINT)


def new_badge(c, x, y, label="new"):
    w = 34 if label == "new" else 8 * len(label) + 14
    c.rect(x, y, w, 16, r=8, fill=TEAL_FILL, stroke=TEAL, sw=1)
    c.text(x + w / 2, y + 11.5, label, size=9.5, weight=700, fill=TEAL,
           anchor="middle", spacing="0.3")
    return w


def wrap(text, width):
    words = text.split()
    lines, cur = [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if len(t) > width and cur:
            lines.append(cur)
            cur = w
        else:
            cur = t
    if cur:
        lines.append(cur)
    return lines
