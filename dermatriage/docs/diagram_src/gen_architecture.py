#!/usr/bin/env python3
"""System architecture — DermaTriage mobile app + Cloudinary + Firebase +
review dashboard + the ML training flywheel."""
from svgkit import (Canvas, title_block, new_badge, INK, SUBINK, FAINT, LINE,
                    BORDER, PANEL, PANEL2, TEAL, TEAL_LINE, TEAL_FILL, BG)

W, H = 1580, 1080
c = Canvas(W, H)

title_block(c, 40, 30, "DermaTriage — System Architecture",
            "Offline-first on-device triage · cloud sync for the healthy-skin "
            "data flywheel")


def person(cx, top, label, sub=None):
    c.circle(cx, top + 14, 13, fill=TEAL_FILL, stroke=TEAL, sw=1.6)
    c.path(f"M{cx-20},{top+62} C{cx-20},{top+38} {cx+20},{top+38} {cx+20},"
           f"{top+62}", fill=TEAL_FILL, stroke=TEAL, sw=1.6)
    c.text(cx, top + 82, label, size=12.5, weight=700, fill=INK,
           anchor="middle")
    if sub:
        c.text(cx, top + 98, sub, size=10.5, fill=FAINT, anchor="middle")


# ---- legend --------------------------------------------------------------
lx, ly = 1170, 28
c.rect(lx, ly, 372, 96, r=10, fill=PANEL, stroke=BORDER, sw=1.2)
c.line(lx + 18, ly + 26, lx + 52, ly + 26, stroke=SUBINK, sw=1.6,
       marker_end="arrow")
c.text(lx + 60, ly + 30, "on-device / offline path", size=11, fill=SUBINK)
c.line(lx + 18, ly + 50, lx + 52, ly + 50, stroke=TEAL_LINE, sw=1.6,
       marker_end="arrowT")
c.text(lx + 60, ly + 54, "cloud / online path", size=11, fill=SUBINK)
c.line(lx + 18, ly + 74, lx + 52, ly + 74, stroke=TEAL_LINE, sw=1.6,
       dash="6 5", marker_end="arrowT")
c.text(lx + 60, ly + 78, "data flywheel (retraining)", size=11, fill=SUBINK)

# ---- CHW actor -----------------------------------------------------------
person(96, 300, "Community", "Health Worker")

# ---- Mobile app panel ----------------------------------------------------
mx, my, mw, mh = 200, 140, 486, 520
c.rect(mx, my, mw, mh, r=14, fill=BG, stroke=TEAL, sw=2, shadow=True)
c.rect(mx, my, mw, 46, r=14, fill=TEAL_FILL, stroke=None)
c.rect(mx, my + 32, mw, 14, fill=TEAL_FILL, stroke=None)
c.icon_tile("flutter", mx + 12, my + 7, tile=32, pad=6)
c.icon_tile("android", mx + 48, my + 7, tile=32, pad=6)
c.text(mx + 92, my + 21, "DermaTriage Mobile App", size=14.5, weight=700,
       fill=TEAL)
c.text(mx + 92, my + 37, "Flutter · Dart · Android — Provider · go_router · "
       "l10n EN/RW", size=10.5, fill=SUBINK)

# on-device triage sub-panel
sx, sy, sw_, sh = mx + 18, my + 66, mw - 36, 176
c.rect(sx, sy, sw_, sh, r=10, fill=PANEL, stroke=BORDER, sw=1.2)
c.text(sx + 14, sy + 22, "On-device triage", size=12, weight=700, fill=INK)
c.text(sx + 150, sy + 22, "offline · < 2 s", size=10, weight=700, fill=TEAL)
chips = [("Camera", None), ("Preprocess\n224 · ImageNet", None),
         ("TFLite model\nMobileNetV3-S", "tensorflow"), ("Triage\nresult", None)]
cw, gap = 96, 14
cxp = sx + 16
cyp = sy + 40
for i, (lab, ic) in enumerate(chips):
    c.rect(cxp, cyp, cw, 74, r=8, fill=BG, stroke=BORDER, sw=1.2)
    if ic:
        c.icon(ic, cxp + cw / 2 - 11, cyp + 10, 22)
        yy = cyp + 48
    else:
        yy = cyp + 34
    for j, ln in enumerate(lab.split("\n")):
        c.text(cxp + cw / 2, yy + j * 13, ln, size=10.5,
               weight=700 if j == 0 else 400,
               fill=INK if j == 0 else SUBINK, anchor="middle")
    if i < len(chips) - 1:
        ax = cxp + cw + 1
        c.line(ax, cyp + 37, ax + gap - 2, cyp + 37, stroke=LINE, sw=1.5,
               marker_end="arrow")
    cxp += cw + gap
c.text(sx + 14, sy + sh - 10, "Grad-CAM heatmap removed — inference only",
       size=9.5, italic=True, fill=FAINT)

# local store sub-panel
tx, ty, tw, th = mx + 18, my + 260, mw - 36, 100
c.rect(tx, ty, tw, th, r=10, fill=PANEL, stroke=BORDER, sw=1.2)
c.icon_tile("sqlite", tx + 12, ty + 12, tile=34, pad=5)
c.text(tx + 56, ty + 26, "Local store — SQLite (sqflite) · v4", size=12,
       weight=700, fill=INK)
c.text(tx + 56, ty + 44, "patients (+ name) · encounters · disease_class · "
       "users", size=10.5, fill=SUBINK)
c.text(tx + 56, ty + 60, "model_evaluations · healthy_skin_contributions "
       "(upload queue)", size=10.5, fill=SUBINK)
nb = new_badge(c, tx + tw - 150, ty + th - 26, "patient name · v4")

# contribution queue sub-panel
qx, qy, qw, qh = mx + 18, my + 372, mw - 36, 118
c.rect(qx, qy, qw, qh, r=10, fill=TEAL_FILL, stroke=TEAL, sw=1.4)
c.text(qx + 14, qy + 22, "Healthy-skin contribution", size=12, weight=700,
       fill=TEAL_LINE)
new_badge(c, qx + 200, qy + 10, "new")
c.text(qx + 14, qy + 42, "Pick body region + Fitzpatrick type → capture →",
       size=10.5, fill=SUBINK)
c.text(qx + 14, qy + 58, "queue offline → upload when online "
       "(connectivity_plus).", size=10.5, fill=SUBINK)
c.text(qx + 14, qy + 80, "ContributionUploadService: multipart → Cloudinary,",
       size=10.5, fill=SUBINK)
c.text(qx + 14, qy + 96, "then Firestore doc (Timestamp).", size=10.5,
       fill=SUBINK)

# ---- Firebase panel ------------------------------------------------------
fx, fy, fw, fh = 770, 150, 300, 196
c.rect(fx, fy, fw, fh, r=12, fill=BG, stroke=BORDER, sw=1.6, shadow=True)
c.icon_tile("firebase", fx + 14, fy + 14, tile=36, pad=5)
c.text(fx + 60, fy + 30, "Firebase", size=14, weight=700, fill=INK)
c.text(fx + 60, fy + 47, "Google Cloud", size=10.5, fill=FAINT)
c.line(fx + 14, fy + 62, fx + fw - 14, fy + 62, stroke=BORDER, sw=1)
c.text(fx + 16, fy + 84, "Authentication", size=11.5, weight=700, fill=INK)
c.text(fx + 16, fy + 100, "email/password + Google Sign-In", size=10,
       fill=SUBINK)
c.text(fx + 16, fy + 128, "Cloud Firestore", size=11.5, weight=700, fill=INK)
c.text(fx + 16, fy + 144, "chws/{uid} — CHW profiles", size=10, fill=SUBINK)
c.text(fx + 16, fy + 160, "healthy_skin_contributions", size=10, fill=SUBINK)
c.text(fx + 16, fy + 176, "(metadata + review status)", size=10, fill=FAINT)

# ---- Cloudinary panel ----------------------------------------------------
cx2, cy2, cw2, ch2 = 770, 380, 300, 150
c.rect(cx2, cy2, cw2, ch2, r=12, fill=BG, stroke=BORDER, sw=1.6, shadow=True)
c.icon_tile("cloudinary", cx2 + 14, cy2 + 14, tile=36, pad=5)
c.text(cx2 + 60, cy2 + 30, "Cloudinary", size=14, weight=700, fill=INK)
c.text(cx2 + 60, cy2 + 47, "image CDN", size=10.5, fill=FAINT)
new_badge(c, cx2 + cw2 - 158, cy2 + 16, "replaces Storage")
c.line(cx2 + 14, cy2 + 62, cx2 + cw2 - 14, cy2 + 62, stroke=BORDER, sw=1)
c.text(cx2 + 16, cy2 + 84, "Hosts contribution photos", size=10.5, fill=SUBINK)
c.text(cx2 + 16, cy2 + 102, "unsigned upload preset", size=10.5, fill=SUBINK)
c.text(cx2 + 16, cy2 + 124, "returns public secure_url", size=10.5,
       weight=700, fill=TEAL_LINE)

# ---- Dashboard panel -----------------------------------------------------
dx, dy, dw, dh = 1170, 150, 372, 340
c.rect(dx, dy, dw, dh, r=14, fill=BG, stroke=TEAL, sw=2, shadow=True)
c.rect(dx, dy, dw, 46, r=14, fill=TEAL_FILL, stroke=None)
c.rect(dx, dy + 32, dw, 14, fill=TEAL_FILL, stroke=None)
c.icon_tile("nextdotjs", dx + 12, dy + 7, tile=32, pad=6)
c.icon_tile("react", dx + 48, dy + 7, tile=32, pad=6)
c.text(dx + 92, dy + 21, "Review Dashboard", size=14.5, weight=700, fill=TEAL)
c.text(dx + 92, dy + 37, "Next.js 15 · React · TypeScript · Tailwind",
       size=10.5, fill=SUBINK)
rows = [
    ("Reviewer queue", "pending healthy-skin photos, live from Firestore"),
    ("Image detail review", "loads photo from Cloudinary secure_url"),
    ("Approve / Reject", "+ plausibility score (1–3), optional note"),
    ("My reviews", "filtered by reviewer email"),
    ("Light + dark mode", "app-logo brand · WCAG-legible type"),
]
ry = dy + 64
for lab, sub in rows:
    c.circle(dx + 24, ry + 10, 3.4, fill=TEAL, stroke=None)
    c.text(dx + 38, ry + 8, lab, size=11.5, weight=700, fill=INK)
    c.text(dx + 38, ry + 24, sub, size=10, fill=SUBINK)
    ry += 42
new_badge(c, dx + dw - 90, dy + 58, "dark mode")

# ---- Reviewer actor ------------------------------------------------------
person(1356, 560, "Reviewer /", "Dermatologist")

# ---- ML pipeline panel ---------------------------------------------------
px, py, pw, ph = 200, 740, 870, 232
c.rect(px, py, pw, ph, r=14, fill=PANEL2, stroke=BORDER, sw=1.6)
c.icon_tile("pytorch", px + 16, py + 16, tile=36, pad=5)
c.icon_tile("tensorflow", px + 54, py + 16, tile=36, pad=5)
c.text(px + 100, py + 30, "ML Training Pipeline", size=14, weight=700, fill=INK)
c.text(px + 100, py + 47, "Python · PyTorch + timm — offline, on Kaggle GPUs",
       size=10.5, fill=SUBINK)

stages = [
    ("EfficientNet-B0", "teacher"),
    ("Knowledge\ndistillation", ""),
    ("MobileNetV3-S", "student"),
    ("TFLite export", "quantise"),
    ("Bundled model", "dermatriage_diverse"),
]
stx = px + 24
sty = py + 84
sbw, sbg = 148, 22
for i, (lab, sub) in enumerate(stages):
    fill = TEAL_FILL if i == len(stages) - 1 else BG
    stroke = TEAL if i == len(stages) - 1 else BORDER
    c.rect(stx, sty, sbw, 92, r=9, fill=fill, stroke=stroke, sw=1.3)
    lines = lab.split("\n")
    yy = sty + (34 if len(lines) == 1 else 26)
    for j, ln in enumerate(lines):
        c.text(stx + sbw / 2, yy + j * 15, ln, size=11.5, weight=700,
               fill=INK, anchor="middle")
    if sub:
        c.text(stx + sbw / 2, sty + 70, sub, size=9.5, italic=True,
               fill=FAINT, anchor="middle")
    if i < len(stages) - 1:
        c.line(stx + sbw + 1, sty + 46, stx + sbw + sbg - 3, sty + 46,
               stroke=LINE, sw=1.6, marker_end="arrow")
    stx += sbw + sbg
c.text(px + 24, py + ph - 14, "PASSION (MICCAI 2024) + HAM10000 · WGAN-GP "
       "augmentation · 5-class: Fungal · Scabies · Eczema · healthy_skin · "
       "not_skin", size=10, fill=FAINT)

# ==== connections =========================================================
# CHW -> mobile app
c.line(150, 300, mx - 6, 300, stroke=SUBINK, sw=1.7, marker_end="arrow")
c.text(174, 292, "uses", size=10, fill=SUBINK)

# mobile -> firebase (auth + metadata)
gapc = (mx + mw + fx) / 2
c.line(mx + mw + 4, 232, fx - 6, 232, stroke=TEAL_LINE, sw=1.8,
       marker_end="arrowT")
c.text(gapc, 212, "sign in +", size=9.5, fill=TEAL_LINE, anchor="middle")
c.text(gapc, 224, "metadata", size=9.5, fill=TEAL_LINE, anchor="middle")

# mobile -> cloudinary (photo upload) + return
c.line(mx + mw + 4, 452, cx2 - 6, 452, stroke=TEAL_LINE, sw=1.8,
       marker_end="arrowT")
c.text(gapc, 444, "photo upload", size=9.5, fill=TEAL_LINE, anchor="middle")
c.line(cx2 - 6, 478, mx + mw + 4, 478, stroke=TEAL_LINE, sw=1.4, dash="4 4",
       marker_end="arrowT")
c.text(gapc, 496, "secure_url", size=9, italic=True, fill=FAINT,
       anchor="middle")

# firebase -> dashboard
c.line(fx + fw + 4, 240, dx - 6, 240, stroke=TEAL_LINE, sw=1.8,
       marker_start="openT", marker_end="arrowT")
c.text(fx + fw + 16, 226, "read queue /", size=10, fill=TEAL_LINE)
c.text(fx + fw + 16, 240, "write decision", size=10, fill=TEAL_LINE)

# cloudinary -> dashboard
c.line(cx2 + cw2 + 4, 440, dx - 6, 440, stroke=TEAL_LINE, sw=1.8,
       marker_end="arrowT")
c.text(cx2 + cw2 + 20, 426, "load images", size=10, fill=TEAL_LINE)

# reviewer -> dashboard
c.line(1356, 556, 1356, dy + dh + 6, stroke=SUBINK, sw=1.7,
       marker_end="arrow")
c.text(1366, 540, "reviews", size=10, fill=SUBINK)

# ML pipeline -> mobile app (model bundled) : vertical from ML top to mobile bottom
c.path(f"M{px+96},{py} L{px+96},{my+mh+30} L{mx+mw/2},{my+mh+30} "
       f"L{mx+mw/2},{my+mh+4}", stroke=SUBINK, sw=1.7, dash="1 0",
       marker_end="arrow")
c.text(px + 110, my + mh + 24, "model.tflite bundled at build time", size=10,
       fill=SUBINK)

# flywheel: firestore -> ML pipeline (dashed teal), routed around Cloudinary
c.path(f"M{fx+fw-40},{fy+fh+4} L{fx+fw-40},{fy+fh+18} L1128,{fy+fh+18} "
       f"L1128,{py+150} L{px+pw+6},{py+150}", stroke=TEAL_LINE, sw=1.8,
       dash="7 5", marker_end="arrowT")
c.text(1146, 694, "approved healthy-skin", size=10, weight=700,
       fill=TEAL_LINE)
c.text(1146, 710, "photos → retrain", size=10, fill=TEAL_LINE)

c.save("architecture")
