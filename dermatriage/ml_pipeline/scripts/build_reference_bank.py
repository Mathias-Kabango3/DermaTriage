"""Regenerate reference_bank.json's embeddings using the model the app
actually ships (dermatriage_diverse_embedding.tflite), keeping every other
field (file/label/subject_id/fitzpatrick) from the curated case list.

Why: the case list was originally embedded with a different checkpoint
(the pre-"diverse not_skin retrain" export used by the abandoned
CAM/explainability attempt). Measured cosine similarity between that bank's
stored embeddings and fresh embeddings of the *same images* from the model
we actually ship was only ~0.60 on average -- nowhere near the ~1.0 you'd
expect if it were the same feature space, and not reliable enough for
clinical nearest-neighbour retrieval. Recomputing keeps the curated case
list (dataset balance, subject selection) but makes the vectors comparable
to what the app computes for a live query.

Run from dermatriage/:  python3 ml_pipeline/scripts/build_reference_bank.py
"""

import json

import numpy as np
from PIL import Image

try:
    from ai_edge_litert.interpreter import Interpreter
except ImportError:
    from tensorflow.lite.python.interpreter import Interpreter

SRC_BANK = "ml_pipeline/reference_bank.json"
DST_BANK = "flutter_app/assets/reference/reference_bank.json"
MODEL = "ml_pipeline/outputs/tflite/dermatriage_diverse_embedding.tflite"
IMAGES_DIR = "PASSION_MICCAI_2024/images"

MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def preprocess_nchw(path):
    im = Image.open(path).convert("RGB").resize((224, 224), Image.BILINEAR)
    arr = np.asarray(im).astype(np.float32) / 255.0
    arr = (arr - MEAN) / STD
    nhwc = arr[np.newaxis, ...].astype(np.float32)
    return np.transpose(nhwc, (0, 3, 1, 2))


def main():
    with open(SRC_BANK) as f:
        bank = json.load(f)

    interp = Interpreter(model_path=MODEL)
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    outs = {d["name"]: d for d in interp.get_output_details()}

    new_items = []
    for item in bank["items"]:
        path = f"{IMAGES_DIR}/{item['file']}"
        x = preprocess_nchw(path)
        interp.set_tensor(inp["index"], x)
        interp.invoke()
        emb = interp.get_tensor(outs["embedding"]["index"])[0]
        emb = emb / np.linalg.norm(emb)
        new_items.append({
            "file": item["file"],
            "label": item["label"],
            "subject_id": item["subject_id"],
            "fitzpatrick": item["fitzpatrick"],
            "embedding": [round(float(v), 6) for v in emb],
        })

    out = {
        "feat_dim": bank["feat_dim"],
        "classes": bank["classes"],
        "model": "dermatriage_diverse_embedding.tflite",
        "items": new_items,
    }
    with open(DST_BANK, "w") as f:
        json.dump(out, f)

    print(f"wrote {DST_BANK}: {len(new_items)} items")


if __name__ == "__main__":
    main()
