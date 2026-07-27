#!/usr/bin/env python3
"""UML sequence diagram — the healthy-skin contribution flywheel: capture →
offline queue → Cloudinary + Firestore upload → dashboard review."""
from svgkit import (Canvas, title_block, INK, SUBINK, FAINT, LINE, BORDER,
                    PANEL, PANEL2, HEADER, TEAL, TEAL_LINE, TEAL_FILL, BG)

W, H = 1620, 1120
c = Canvas(W, H)
title_block(c, 40, 30, "DermaTriage — Sequence Diagram",
            "Healthy-skin contribution → offline queue → Cloudinary + Firestore "
            "→ dashboard review")

# lifelines: (x, [label lines], icon, is_actor)
LL = [
    (96, ["CHW"], None, True),
    (300, ["Mobile app", "(contribution UI)"], "flutter", False),
    (500, ["Local queue", "SQLite"], "sqlite", False),
    (700, ["Contribution", "UploadService"], None, False),
    (900, ["Cloudinary"], "cloudinary", False),
    (1096, ["Cloud", "Firestore"], "firebase", False),
    (1310, ["Review", "Dashboard"], "nextdotjs", False),
    (1520, ["Reviewer"], None, True),
]
X = [ll[0] for ll in LL]
TOP, BOT = 96, 1044

# ---- lifelines ------------------------------------------------------------
for x, lines, icon, is_actor in LL:
    hh = 56
    bw = 150
    if is_actor:
        # stick figure
        c.circle(x, TOP + 14, 9, fill=BG, stroke=TEAL, sw=1.8)
        c.line(x, TOP + 23, x, TOP + 40, stroke=TEAL, sw=1.8)
        c.line(x - 13, TOP + 30, x + 13, TOP + 30, stroke=TEAL, sw=1.8)
        c.line(x, TOP + 40, x - 11, TOP + 54, stroke=TEAL, sw=1.8)
        c.line(x, TOP + 40, x + 11, TOP + 54, stroke=TEAL, sw=1.8)
        c.text(x, TOP + 74, lines[0], size=12.5, weight=700, fill=INK,
               anchor="middle")
    else:
        c.rect(x - bw / 2, TOP, bw, hh, r=9, fill=HEADER, stroke=BORDER,
               sw=1.5)
        if icon:
            c.icon(icon, x - bw / 2 + 12, TOP + hh / 2 - 11, 22)
            tx, anc = x + 6, "middle"
        else:
            tx, anc = x, "middle"
        for i, ln in enumerate(lines):
            c.text(tx, TOP + (25 if len(lines) == 2 else 32) + i * 15, ln,
                   size=11.5, weight=700 if i == 0 else 500,
                   fill=INK if i == 0 else SUBINK, anchor=anc)
    c.line(x, TOP + 80, x, BOT, stroke=BORDER, sw=1.3, dash="3 5")

# ---- helpers --------------------------------------------------------------
def section(y, label):
    c.rect(64, y, W - 128, 26, r=6, fill=PANEL2, stroke=None)
    c.text(78, y + 17, label, size=11.5, weight=700, fill=SUBINK)


def activation(i, y1, y2):
    c.rect(X[i] - 6, y1, 12, y2 - y1, r=2, fill=PANEL, stroke=BORDER, sw=1.2)


def act_teal(i, y1, y2):
    c.rect(X[i] - 6, y1, 12, y2 - y1, r=2, fill=TEAL_FILL, stroke=TEAL,
           sw=1.2)


def msg(y, i1, i2, text, ret=False, num=None):
    x1, x2 = X[i1], X[i2]
    d = 1 if x2 > x1 else -1
    sx = x1 + d * 6
    ex = x2 - d * 6
    if ret:
        c.line(sx, y, ex, y, stroke=FAINT, sw=1.3, dash="5 4",
               marker_end="open")
        c.text((sx + ex) / 2, y - 7, text, size=10.5, italic=True,
               fill=FAINT, anchor="middle")
    else:
        c.line(sx, y, ex, y, stroke=SUBINK, sw=1.6, marker_end="arrow")
        c.text((sx + ex) / 2, y - 7, text, size=11, fill=INK,
               anchor="middle")
    if num is not None:
        nx = x1 + d * 14
        c.circle(nx, y, 9, fill=TEAL, stroke=None)
        c.text(nx, y + 3.5, str(num), size=10, weight=700, fill="#ffffff",
               anchor="middle")


def note(y, i, lines, w=220):
    x = X[i]
    h = 12 + len(lines) * 15
    c.path(f"M{x-w/2},{y} L{x+w/2-12},{y} L{x+w/2},{y+12} L{x+w/2},{y+h} "
           f"L{x-w/2},{y+h} Z", fill="#fff9e8", stroke="#e6c964", sw=1.2)
    c.path(f"M{x+w/2-12},{y} L{x+w/2-12},{y+12} L{x+w/2},{y+12}",
           fill="none", stroke="#e6c964", sw=1.2)
    for i2, ln in enumerate(lines):
        c.text(x - w / 2 + 12, y + 20 + i2 * 15, ln, size=10.5, fill="#6b5a16")


# ---- activations (drawn behind messages) ---------------------------------
activation(1, 250, 366)          # mobile UI
activation(2, 258, 300)          # queue insert
act_teal(3, 424, 660)            # upload service
activation(2, 430, 470)          # queue fetch
activation(2, 636, 660)          # queue update
activation(4, 494, 538)          # cloudinary upload
activation(5, 566, 610)          # firestore write
act_teal(6, 716, 968)            # dashboard
activation(5, 746, 790)          # firestore query
activation(4, 818, 862)          # cloudinary get
activation(5, 924, 968)          # firestore update

# ==== Section A: capture & queue (offline) ================================
section(150, "A · Capture & queue — on-device, works fully offline")
msg(196, 0, 1, "select body region + Fitzpatrick type", num=1)
msg(232, 0, 1, "capture healthy-skin photo", num=2)
msg(272, 1, 2, "insert(contribution, status = 'queued')", num=3)
msg(304, 2, 1, "id", ret=True)
msg(342, 1, 0, "“Saved — uploads when you’re online”", ret=True)

# ==== Section B: background upload (online) ===============================
section(388, "B · Background upload — when connectivity returns "
        "(connectivity_plus)")
msg(442, 3, 2, "fetch queued", num=4)
msg(474, 2, 3, "[ contribution ]", ret=True)
msg(510, 3, 4, "POST photo — multipart, unsigned preset", num=5)
msg(542, 4, 3, "secure_url", ret=True)
msg(578, 3, 5, "set doc { imageUrl, meta, Timestamp, status:'pending' }",
    num=6)
msg(612, 5, 3, "ack", ret=True)
msg(648, 3, 2, "update status = 'uploaded'", num=7)

# ==== Section C: review (later, in the dashboard) =========================
section(694, "C · Review — later, in the dashboard")
msg(742, 7, 6, "open review queue", num=8)
msg(776, 6, 5, "query status == 'pending'", num=9)
msg(808, 5, 6, "pending contributions", ret=True)
msg(844, 6, 4, "GET image (secure_url)", num=10)
msg(876, 4, 6, "image", ret=True)
msg(912, 7, 6, "approve / reject  (+ plausibility score)", num=11)
msg(946, 6, 5, "update { status, reviewedBy, score }", num=12)
msg(980, 5, 6, "ack", ret=True)

# note on the offline-first guarantee
note(214, 3, ["ContributionUploadService retries", "on every connectivity change —",
              "the CHW never waits for upload."], w=250)

c.save("sequence_diagram")
