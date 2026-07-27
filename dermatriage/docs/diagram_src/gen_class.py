#!/usr/bin/env python3
"""UML class diagram — DermaTriage domain model, DAOs and services, updated
with the patient name field and the healthy-skin contribution feature."""
from svgkit import (Canvas, title_block, new_badge, INK, SUBINK, FAINT, LINE,
                    BORDER, PANEL, HEADER, TEAL, TEAL_LINE, TEAL_FILL, BG, MONO)

W, H = 1600, 1230
c = Canvas(W, H)
title_block(c, 40, 30, "DermaTriage — Class Diagram",
            "Domain entities · persistence (DAO) · services — new: Patient.name "
            "and the healthy-skin contribution pipeline")

RH = 18


def class_box(x, y, w, name, attrs, methods, stereo=None, accent=False):
    hh = 30 + (15 if stereo else 0)
    ah = 8 + max(1, len(attrs)) * RH + 6
    mh = 8 + max(1, len(methods)) * RH + 6
    total = hh + ah + mh
    border = TEAL if accent else BORDER
    hfill = TEAL_FILL if accent else HEADER
    c.rect(x, y, w, total, r=9, fill=BG, stroke=border, sw=1.7, shadow=True)
    # header
    c.rect(x, y, w, hh, r=9, fill=hfill, stroke=None)
    c.rect(x, y + hh - 10, w, 10, fill=hfill, stroke=None)
    cxm = x + w / 2
    if stereo:
        c.text(cxm, y + 17, f"«{stereo}»", size=10.5, italic=True,
               fill=FAINT, anchor="middle")
        c.text(cxm, y + 35, name, size=14.5, weight=700,
               fill=TEAL if accent else INK, anchor="middle")
    else:
        c.text(cxm, y + 20, name, size=14.5, weight=700,
               fill=TEAL if accent else INK, anchor="middle")
    c.line(x, y + hh, x + w, y + hh, stroke=border, sw=1.2)
    # attributes
    ay = y + hh
    for i, a in enumerate(attrs):
        ry = ay + 8 + i * RH
        hl = a.startswith("*")
        txt = a[1:] if hl else a
        if hl:
            c.rect(x + 2, ry, w - 4, RH, fill=TEAL_FILL, stroke=None)
            c.text(x + 12, ry + 13, txt, size=11, fill=TEAL_LINE, weight=600,
                   font=MONO)
            c.text(x + w - 10, ry + 13, "new", size=9, weight=700, fill=TEAL,
                   anchor="end")
        else:
            c.text(x + 12, ry + 13, txt, size=11, fill=INK, font=MONO)
    c.line(x, ay + ah, x + w, ay + ah, stroke=border, sw=1.2)
    # methods
    my = ay + ah
    for i, m in enumerate(methods):
        ry = my + 8 + i * RH
        hl = m.startswith("*")
        txt = m[1:] if hl else m
        if hl:
            c.rect(x + 2, ry, w - 4, RH, fill=TEAL_FILL, stroke=None)
        c.text(x + 12, ry + 13, txt, size=11,
               fill=TEAL_LINE if hl else SUBINK,
               weight=600 if hl else 400, font=MONO)
    return total


# ------------------------------------------------------------- entities row
A, B, Cc, D = 60, 448, 836, 1210
EW = 300
DW = 330

h_pat = class_box(A, 96, EW, "Patient", [
    "+ id: String", "*+ name: String", "+ approximateAge: int?",
    "+ sex: String", "+ location: String", "+ fitzpatrickType: int",
    "+ consentGiven: bool", "+ photoConsent: bool", "+ createdAt: DateTime",
], ["+ toMap() / fromMap()", "+ copyWith()"])

h_enc = class_box(B, 96, EW, "Encounter", [
    "+ encounterId: String", "+ patientId: String", "+ diseaseId: int?",
    "+ encounterDate: DateTime", "+ photoPath: String",
    "+ predictedClass: String", "+ confidenceScore: double",
    "+ triageCategory: String", "+ synced: bool", "+ chwNotes: String?",
], ["+ toMap() / fromMap()"])

h_dis = class_box(Cc, 96, EW, "DiseaseClass", [
    "+ id: int", "+ displayName: String", "+ triageLevel: TriageLevel",
    "+ description: String", "+ icd10Code: String", "+ isNtd: bool",
], ["+ fromMap()"])

h_hsc = class_box(D, 96, DW, "HealthySkinContribution", [
    "+ id: String", "+ localPhotoPath: String",
    "+ fitzpatrickType: String  // I–VI", "+ bodyRegion: String",
    "+ contributorId: String", "+ facility: String",
    "+ capturedAt: DateTime", "+ syncStatus: String", "+ lastError: String?",
], ["+ toMap() / fromMap()"], accent=True)
new_badge(c, D + DW - 46, 104, "new")

# ----------------------------------------------------------- persistence row
PY = 470
h_pdao = class_box(A, PY, EW, "PatientDao", [], [
    "+ insertPatient(p)", "+ getPatient(id): Patient?",
    "+ getAllPatients(): List", "+ updatePatient(p)", "+ deletePatient(id)",
])
h_edao = class_box(B, PY, EW, "EncounterDao", [], [
    "+ insertEncounter(e)", "+ getAllEncounters(): List",
    "+ getEncounter(id): Encounter?",
])
h_db = class_box(Cc, PY, EW, "DatabaseHelper", [
    "+ instance: DatabaseHelper", "- _db: Database",
], [
    "+ database: Future<Database>", "- _onCreate()",
    "*- _onUpgrade()  // v4: patients.name",
], stereo="singleton")
h_hdao = class_box(D, PY, DW, "HealthySkinContributionDao", [], [
    "+ insert(c)", "+ queued(): List", "+ updateStatus(id, status, err?)",
])

# --------------------------------------------------------------- service row
SY = 800
h_hist = class_box(A, SY, EW, "HistoryProvider", [
    "- _encounters: List", "*- _patientsById: Map",
], [
    "+ loadEncounters()", "*+ patientFor(id): Patient?",
], stereo="ChangeNotifier")
h_inf = class_box(B, SY, EW, "InferenceService", [
    "- _interpreter: Interpreter",
], [
    "+ runTriage(img): TriageResult", "  // times preprocess + run, < 2 s",
])
h_up = class_box(Cc, SY, EW, "ContributionUploadService", [], [
    "+ uploadPending()", "- _uploadOne(c)",
    "  // multipart → Cloudinary,", "  // then Firestore (Timestamp)",
], accent=True)
h_cfg = class_box(D, SY, DW, "CloudinaryConfig", [
    "+ cloudName: String", "+ uploadPreset: String",
], ["+ uploadEndpoint: Uri"], stereo="const config")

# ================================================================ relations
def dep(x1, y1, x2, y2, mid=None, teal=False):
    col = TEAL_LINE if teal else SUBINK
    mk = "openT" if teal else "open"
    c.line(x1, y1, x2, y2, stroke=col, sw=1.4, dash="6 5", marker_end=mk)


# Patient 1 ◆—— 0..* Encounter (composition)
py = 150
c.poly([(A + EW, py), (A + EW + 11, py - 7), (A + EW + 22, py),
        (A + EW + 11, py + 7)], fill=INK, stroke=INK, sw=1)
c.line(A + EW + 22, py, B - 2, py, stroke=SUBINK, sw=1.5)
c.text(A + EW + 30, py - 8, "1", size=11, weight=700, fill=INK)
c.text(B - 12, py - 8, "0..*", size=11, weight=700, fill=INK, anchor="end")
c.text((A + EW + 22 + B) / 2, py + 16, "records", size=10, italic=True,
       fill=FAINT, anchor="middle")

# Encounter 0..* ——> 1 DiseaseClass (directed association)
ey = 160
c.line(B + EW + 2, ey, Cc - 4, ey, stroke=SUBINK, sw=1.5, marker_end="open")
c.text(B + EW + 10, ey - 8, "0..*", size=11, weight=700, fill=INK)
c.text(Cc - 16, ey - 8, "1", size=11, weight=700, fill=INK, anchor="end")
c.text((B + EW + Cc) / 2, ey + 16, "classified as", size=10, italic=True,
       fill=FAINT, anchor="middle")

# DAO ..> entity (dashed «uses», up each column)
dep(A + 60, PY, A + 60, 96 + h_pat + 2, teal=False)
dep(B + 60, PY, B + 60, 96 + h_enc + 2)
dep(D + 70, PY, D + 70, 96 + h_hsc + 2, teal=True)

# DAOs ..> DatabaseHelper
dep(A + EW + 2, PY + 40, Cc - 4, PY + 40)
dep(B + EW + 2, PY + 44, Cc - 4, PY + 44)
dep(D - 4, PY + 40, Cc + EW + 4, PY + 40)
c.text(Cc + EW / 2, PY - 6, "DAOs open the shared database", size=9.5,
       italic=True, fill=FAINT, anchor="middle")

# HistoryProvider ..> PatientDao (column) + EncounterDao (right) — new lookup
dep(A + 150, SY, A + 150, PY + h_pdao + 2, teal=True)
c.text(A + 158, SY - 6, "reads", size=9, italic=True, fill=TEAL_LINE)
c.line(A + 250, SY, B + 50, PY + h_edao + 2, stroke=TEAL_LINE, sw=1.4,
       dash="6 5", marker_end="openT")

# ContributionUploadService ..> HSCDao + CloudinaryConfig
c.line(Cc + EW - 50, SY, D + 50, PY + h_hdao + 2, stroke=TEAL_LINE, sw=1.4,
       dash="6 5", marker_end="openT")
c.line(Cc + EW + 2, SY + 44, D - 4, SY + 44, stroke=TEAL_LINE, sw=1.4,
       dash="6 5", marker_end="openT")
c.text((Cc + EW + D) / 2, SY + 38, "uses", size=9, italic=True,
       fill=TEAL_LINE, anchor="middle")

# ---- legend
lx, ly = 60, 1150
c.line(lx, ly, lx + 30, ly, stroke=SUBINK, sw=1.5)
c.poly([(lx, ly - 30 + 30), (lx, ly)], fill=None, stroke=None)
c.text(lx + 40, ly + 4, "association", size=11, fill=SUBINK)
c.poly([(lx + 150, ly), (lx + 161, ly - 6), (lx + 172, ly),
        (lx + 161, ly + 6)], fill=INK, stroke=INK, sw=1)
c.text(lx + 182, ly + 4, "composition", size=11, fill=SUBINK)
c.line(lx + 300, ly, lx + 330, ly, stroke=SUBINK, sw=1.4, dash="6 5",
       marker_end="open")
c.text(lx + 340, ly + 4, "dependency «uses»", size=11, fill=SUBINK)
c.rect(lx + 500, ly - 9, 26, 15, r=7, fill=TEAL_FILL, stroke=TEAL, sw=1)
c.text(lx + 513, ly + 2, "new", size=9, weight=700, fill=TEAL,
       anchor="middle")
c.text(lx + 536, ly + 4, "added this iteration", size=11, fill=SUBINK)

c.save("class_diagram")
