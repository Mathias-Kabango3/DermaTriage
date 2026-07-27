#!/usr/bin/env python3
"""UML use-case diagram — CHW (mobile app) and Reviewer (dashboard) actors,
with the new contribution + review use cases highlighted."""
from svgkit import (Canvas, title_block, INK, SUBINK, FAINT, LINE, BORDER,
                    PANEL, TEAL, TEAL_LINE, TEAL_FILL, BG)

W, H = 1600, 1000
c = Canvas(W, H)
title_block(c, 40, 30, "DermaTriage — Use-Case Diagram",
            "Community Health Worker (mobile app) · Reviewer (dashboard) — "
            "new contribution & review use cases in teal")


def actor(cx, cy, label, sub):
    s = TEAL
    c.circle(cx, cy - 40, 13, fill=BG, stroke=s, sw=2)
    c.line(cx, cy - 27, cx, cy + 6, stroke=s, sw=2)
    c.line(cx - 20, cy - 14, cx + 20, cy - 14, stroke=s, sw=2)
    c.line(cx, cy + 6, cx - 16, cy + 32, stroke=s, sw=2)
    c.line(cx, cy + 6, cx + 16, cy + 32, stroke=s, sw=2)
    c.text(cx, cy + 52, label, size=13, weight=700, fill=INK, anchor="middle")
    c.text(cx, cy + 69, sub, size=11, fill=FAINT, anchor="middle")


def uc(cx, cy, w, lines, new=False, updated=False):
    fill = TEAL_FILL if new else PANEL
    stroke = TEAL if new else BORDER
    c.ellipse(cx, cy, w / 2, 32, fill=fill, stroke=stroke,
              sw=1.8 if new else 1.4)
    n = len(lines)
    y0 = cy - (n - 1) * 8 + 4
    for i, ln in enumerate(lines):
        c.text(cx, y0 + i * 16, ln, size=11.5,
               weight=600 if (new or updated) and i == 0 else 500,
               fill=TEAL_LINE if new else INK, anchor="middle")
    if new:
        c.rect(cx + w / 2 - 30, cy - 40, 30, 15, r=7, fill=TEAL,
               stroke=None)
        c.text(cx + w / 2 - 15, cy - 29, "new", size=9, weight=700,
               fill="#ffffff", anchor="middle")
    elif updated:
        c.rect(cx + w / 2 - 46, cy - 40, 46, 15, r=7, fill=BG, stroke=TEAL,
               sw=1)
        c.text(cx + w / 2 - 23, cy - 29, "updated", size=8.5, weight=700,
               fill=TEAL, anchor="middle")
    return cx - w / 2  # left anchor for actor lines


# ---- system boundaries ----------------------------------------------------
mbx, mby, mbw, mbh = 220, 108, 660, 812
c.rect(mbx, mby, mbw, mbh, r=16, fill=BG, stroke=BORDER, sw=1.6)
c.text(mbx + 24, mby + 30, "DermaTriage Mobile App", size=13.5, weight=700,
       fill=SUBINK)
c.text(mbx + 24, mby + 48, "Flutter · Android · offline-first", size=10.5,
       fill=FAINT)

dbx, dby, dbw, dbh = 980, 300, 470, 430
c.rect(dbx, dby, dbw, dbh, r=16, fill=BG, stroke=BORDER, sw=1.6)
c.text(dbx + 24, dby + 30, "Review Dashboard", size=13.5, weight=700,
       fill=SUBINK)
c.text(dbx + 24, dby + 48, "Next.js · web", size=10.5, fill=FAINT)

# ---- actors ---------------------------------------------------------------
actor(110, 470, "Community", "Health Worker")
actor(1520, 500, "Reviewer /", "Dermatologist")

# ---- CHW use cases (main column) -----------------------------------------
UCW = 250
cxm = mbx + 250
chw_cases = [
    (180, ["Register / Sign in"], {}),
    (270, ["Register patient", "(name · demographics · consent)"],
     {"updated": True}),
    (360, ["Capture lesion photo"], {}),
    (450, ["Get on-device AI triage"], {}),
    (540, ["View encounter history", "(now shows patient name)"],
     {"updated": True}),
    (630, ["Contribute healthy-skin photo"], {"new": True}),
    (720, ["View my contributions"], {"new": True}),
    (810, ["Settings: language (EN/RW)", "· privacy & consent"], {}),
]
lefts = []
for cy, lines, kw in chw_cases:
    left = uc(cxm, cy, UCW, lines, **kw)
    lefts.append((cy, left))

# include: Capture ..> Get AI triage
c.line(cxm, 360 + 32, cxm, 450 - 32, stroke=SUBINK, sw=1.4, dash="6 5",
       marker_end="open")
c.text(cxm + 10, 410, "«include»", size=9.5, italic=True, fill=SUBINK)

# include target: Contribute ..> Queue & upload
qw = 210
qx, qy = mbx + mbw - 126, 630
uc(qx, qy, qw, ["Queue & upload", "(Cloudinary + Firestore)"], new=True)
c.line(cxm + UCW / 2, 630, qx - qw / 2 - 2, 630, stroke=TEAL_LINE, sw=1.4,
       dash="6 5", marker_end="openT")
c.text((cxm + UCW / 2 + qx - qw / 2) / 2, 620, "«include»", size=9.5,
       italic=True, fill=TEAL_LINE, anchor="middle")

# CHW actor -> use cases
for cy, left in lefts:
    c.line(132, 466, left - 2, cy, stroke=LINE, sw=1.3)

# ---- Reviewer use cases ---------------------------------------------------
rxm = dbx + 235
rev_cases = [
    (370, ["Sign in (allow-list)"], {}),
    (462, ["Review contribution queue"], {"new": True}),
    (554, ["Approve / Reject", "(+ plausibility score)"], {"new": True}),
    (646, ["View my reviews"], {"new": True}),
]
rrights = []
for cy, lines, kw in rev_cases:
    uc(rxm, cy, 300, lines, **kw)
    rrights.append((cy, rxm + 150))

for cy, right in rrights:
    c.line(1498, 496, right + 2, cy, stroke=LINE, sw=1.3)

# ---- cross-system flywheel link ------------------------------------------
c.path(f"M{qx+qw/2},{qy} C{qx+qw/2+70},{qy} {dbx-60},480 {dbx-4},468",
       stroke=TEAL_LINE, sw=1.6, dash="7 5", marker_end="arrowT")
c.text((qx + qw / 2 + dbx) / 2 + 6, 598, "contributed photos", size=10,
       weight=700, fill=TEAL_LINE, anchor="middle")
c.text((qx + qw / 2 + dbx) / 2 + 6, 613, "feed the review queue", size=10,
       fill=TEAL_LINE, anchor="middle")

# ---- legend ---------------------------------------------------------------
lx, ly = 220, 960
c.ellipse(lx + 12, ly, 12, 8, fill=PANEL, stroke=BORDER, sw=1.3)
c.text(lx + 32, ly + 4, "use case", size=11, fill=SUBINK)
c.ellipse(lx + 150, ly, 12, 8, fill=TEAL_FILL, stroke=TEAL, sw=1.6)
c.text(lx + 170, ly + 4, "new use case", size=11, fill=SUBINK)
c.line(lx + 300, ly, lx + 336, ly, stroke=SUBINK, sw=1.4, dash="6 5",
       marker_end="open")
c.text(lx + 344, ly + 4, "«include»", size=11, fill=SUBINK)
c.line(lx + 470, ly, lx + 506, ly, stroke=LINE, sw=1.3)
c.text(lx + 514, ly + 4, "actor association", size=11, fill=SUBINK)

c.save("use_case")
