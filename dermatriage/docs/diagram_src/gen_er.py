#!/usr/bin/env python3
"""Entity-Relationship diagram — DermaTriage on-device SQLite schema (v4),
crow's-foot notation. New: patients.name (v4) and the
healthy_skin_contributions table (v3)."""
from svgkit import (Canvas, title_block, new_badge, INK, SUBINK, FAINT, LINE,
                    BORDER, PANEL, HEADER, TEAL, TEAL_LINE, TEAL_FILL, BG, MONO)

W, H = 1500, 900
c = Canvas(W, H)
title_block(c, 40, 30, "DermaTriage — Entity-Relationship Diagram",
            "On-device SQLite schema (database v4) · crow's-foot notation")

RH = 24
HH = 36


def table(x, y, w, name, rows, new=False, tag=None):
    total = HH + len(rows) * RH
    border = TEAL if new else BORDER
    c.rect(x, y, w, total, r=8, fill=BG, stroke=border, sw=1.7, shadow=True)
    c.rect(x, y, w, HH, r=8, fill=TEAL_FILL if new else HEADER, stroke=None)
    c.rect(x, y + HH - 8, w, 8, fill=TEAL_FILL if new else HEADER,
           stroke=None)
    c.text(x + 14, y + 24, name, size=13, weight=700,
           fill=TEAL if new else INK, font=MONO)
    if tag:
        new_badge(c, x + w - (8 * len(tag) + 22), y + 10, tag)
    c.line(x, y + HH, x + w, y + HH, stroke=border, sw=1.2)
    for i, row in enumerate(rows):
        col, typ, key = row[0], row[1], row[2]
        hl = col.startswith("*")
        col = col[1:] if hl else col
        ry = y + HH + i * RH
        if hl:
            c.rect(x + 1, ry, w - 2, RH, fill=TEAL_FILL, stroke=None)
        if i:
            c.line(x, ry, x + w, ry, stroke="#eef2f4", sw=1)
        # key badge
        if key:
            kc = TEAL if "PK" in key else FAINT
            c.text(x + 12, ry + 16, key, size=8.5, weight=700, fill=kc)
        # column + type
        cc = TEAL_LINE if hl else INK
        cw = 600 if ("PK" in (key or "")) else 400
        c.text(x + 52, ry + 16, col, size=11.5,
               weight=700 if "PK" in (key or "") or hl else 500, fill=cc,
               font=MONO)
        c.text(x + w - 12, ry + 16, typ, size=10, fill=FAINT, font=MONO,
               anchor="end")
    return total


def rel(one_x, many_x, y, zero=True, label=None):
    c.line(one_x, y, many_x, y, stroke=SUBINK, sw=1.6)
    d = 1 if many_x > one_x else -1
    bx = one_x + d * 13
    c.line(bx, y - 9, bx, y + 9, stroke=SUBINK, sw=1.6)      # "one" bar
    fx = many_x - d * 17
    c.line(many_x, y, fx, y - 9, stroke=SUBINK, sw=1.6)      # crow's foot
    c.line(many_x, y, fx, y, stroke=SUBINK, sw=1.6)
    c.line(many_x, y, fx, y + 9, stroke=SUBINK, sw=1.6)
    if zero:
        c.circle(many_x - d * 26, y, 5, fill=BG, stroke=SUBINK, sw=1.5)
    if label:
        c.text((one_x + many_x) / 2, y - 10, label, size=10, italic=True,
               fill=FAINT, anchor="middle")


# ---- tables ---------------------------------------------------------------
patients = [
    ("patient_id", "TEXT", "PK"),
    ("*name", "TEXT", None),
    ("approximate_age", "INTEGER", None),
    ("sex", "TEXT", None),
    ("location", "TEXT", None),
    ("fitzpatrick_type", "INTEGER", None),
    ("consent_given", "INTEGER", None),
    ("photo_consent", "INTEGER", None),
    ("created_at", "TEXT", None),
]
encounters = [
    ("encounter_id", "TEXT", "PK"),
    ("patient_id", "TEXT", "FK"),
    ("disease_id", "INTEGER", "FK"),
    ("encounter_date", "TEXT", None),
    ("photo_path", "TEXT", None),
    ("predicted_class", "TEXT", None),
    ("confidence_score", "REAL", None),
    ("triage_category", "TEXT", None),
    ("synced", "INTEGER", None),
    ("chw_notes", "TEXT", None),
]
disease_classes = [
    ("disease_id", "INTEGER", "PK"),
    ("disease_name", "TEXT", None),
    ("triage_level", "TEXT", None),
    ("referral_urgency", "TEXT", None),
    ("ntd_flag", "INTEGER", None),
    ("icd10_code", "TEXT", None),
]
hsc = [
    ("id", "TEXT", "PK"),
    ("local_photo_path", "TEXT", None),
    ("fitzpatrick_type", "INTEGER", None),
    ("body_region", "TEXT", None),
    ("contributor_id", "TEXT", None),
    ("facility", "TEXT", None),
    ("captured_at", "TEXT", None),
    ("sync_status", "TEXT", None),
    ("last_error", "TEXT", None),
]
users = [
    ("id", "INTEGER", "PK"),
    ("username", "TEXT", "UQ"),
    ("password_hash", "TEXT", None),
    ("security_question", "TEXT", None),
    ("security_answer_hash", "TEXT", None),
    ("created_at", "TEXT", None),
]
model_eval = [
    ("eval_id", "INTEGER", "PK"),
    ("model_version", "TEXT", None),
    ("accuracy_overall", "REAL", None),
    ("dvs_score", "REAL", None),
    ("evaluated_at", "TEXT", None),
]

PX, PW = 70, 330
EX, EW = 560, 380
DX, DW = 1090, 330

h_p = table(PX, 150, PW, "patients", patients, tag="+ name · v4")
h_e = table(EX, 150, EW, "encounters", encounters)
h_d = table(DX, 150, DW, "disease_classes", disease_classes)

h_h = table(PX, 560, PW + 40, "healthy_skin_contributions", hsc, new=True,
            tag="new · v3")
h_u = table(EX, 560, 330, "users", users)
h_m = table(DX, 560, DW, "model_evaluations", model_eval)

# ---- relationships (crow's foot) -----------------------------------------
# patients ||--o{ encounters   (patient_id FK, ON DELETE CASCADE)
rel(PX + PW, EX, 150 + HH + 1 * RH + 12, label="records")
c.text((PX + PW + EX) / 2, 150 + HH + 1 * RH + 30, "ON DELETE CASCADE",
       size=8.5, italic=True, fill=FAINT, anchor="middle")
# disease_classes ||--o{ encounters   (disease_id FK, nullable)
rel(DX, EX + EW, 150 + HH + 2 * RH + 12, label="classifies")

# standalone note for contributions
c.text(PX + 4, 560 + h_h + 24, "contributor_id = CHW's Firebase uid "
       "(auth, not a local FK) · upload queue for the review dashboard",
       size=10, italic=True, fill=FAINT)
c.text(EX + 4, 560 + h_u + 24, "offline CHW authentication", size=10,
       italic=True, fill=FAINT)
c.text(DX + 4, 560 + h_m + 24, "on-device model metrics", size=10,
       italic=True, fill=FAINT)

# ---- legend ---------------------------------------------------------------
lx, ly = 70, 850
c.text(lx, ly + 4, "PK", size=9.5, weight=700, fill=TEAL)
c.text(lx + 24, ly + 4, "primary key", size=11, fill=SUBINK)
c.text(lx + 130, ly + 4, "FK", size=9.5, weight=700, fill=FAINT)
c.text(lx + 154, ly + 4, "foreign key", size=11, fill=SUBINK)
c.text(lx + 262, ly + 4, "UQ", size=9.5, weight=700, fill=FAINT)
c.text(lx + 288, ly + 4, "unique", size=11, fill=SUBINK)
# crow's foot key
kx = lx + 380
c.line(kx, ly, kx + 70, ly, stroke=SUBINK, sw=1.6)
c.line(kx + 12, ly - 8, kx + 12, ly + 8, stroke=SUBINK, sw=1.6)
c.line(kx + 70, ly, kx + 53, ly - 8, stroke=SUBINK, sw=1.6)
c.line(kx + 70, ly, kx + 53, ly, stroke=SUBINK, sw=1.6)
c.line(kx + 70, ly, kx + 53, ly + 8, stroke=SUBINK, sw=1.6)
c.circle(kx + 44, ly, 5, fill=BG, stroke=SUBINK, sw=1.5)
c.text(kx + 84, ly + 4, "one  →  zero-or-many", size=11, fill=SUBINK)

c.save("er_diagram")
