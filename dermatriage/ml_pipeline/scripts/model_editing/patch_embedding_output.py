"""One-time offline edit: expose the pre-classifier pooled-feature tensor of
the currently-shipping dermatriage_diverse.tflite as a second named output
("embedding"), alongside the existing classifier output (renamed "logits").

This is a pure metadata edit to the flatbuffer's primary-subgraph `outputs`
list and two tensor `name` fields. No weights, ops, or buffers are touched,
so the classifier's numerical behaviour is unchanged -- verified separately
in flutter_app/test/integration/embedding_model_parity_test.dart (asserts
max logit diff == 0.0 against the original file on real PASSION images).

Setup (schema bindings are generated, not committed -- regenerate as needed):

    brew install flatbuffers
    pip install flatbuffers
    curl -sL -o schema.fbs \
      https://raw.githubusercontent.com/tensorflow/tensorflow/master/tensorflow/compiler/mlir/lite/schema/schema.fbs
    flatc --python --gen-object-api -o <out_dir> schema.fbs

Then run this script with <out_dir> on sys.path (see SCHEMA_DIR below).
"""

import sys

SCHEMA_DIR = "/tmp/tflite_schema/out"  # see setup note above
sys.path.insert(0, SCHEMA_DIR)

import flatbuffers
from tflite.Model import Model, ModelT

SRC = "ml_pipeline/outputs/tflite/dermatriage_diverse.tflite"
DST = "ml_pipeline/outputs/tflite/dermatriage_diverse_embedding.tflite"

# torchvision MobileNetV3-Small tensor indices in dermatriage_diverse.tflite,
# confirmed via get_tensor_details(): 254 is the final classifier output
# ("serving_default_output_0_output", [1,5]); 251 is the top-level
# `MobileNetV3/AdaptiveAvgPool2d_avgpool` -- the 576-d pooled backbone
# feature immediately before the two classifier Linear layers. Re-check these
# indices with get_tensor_details() if the source checkpoint ever changes.
LOGITS_TENSOR_IDX = 254
EMBEDDING_TENSOR_IDX = 251


def main():
    with open(SRC, "rb") as f:
        buf = bytearray(f.read())

    model = Model.GetRootAsModel(buf, 0)
    model_obj = ModelT.InitFromObj(model)
    sg = model_obj.subgraphs[0]

    logits_tensor = sg.tensors[LOGITS_TENSOR_IDX]
    emb_tensor = sg.tensors[EMBEDDING_TENSOR_IDX]
    print("before rename:", logits_tensor.name, emb_tensor.name)
    logits_tensor.name = b"logits"
    emb_tensor.name = b"embedding"

    print("subgraph outputs before:", list(sg.outputs))
    sg.outputs = list(sg.outputs) + [EMBEDDING_TENSOR_IDX]
    print("subgraph outputs after:", list(sg.outputs))

    builder = flatbuffers.Builder(0)
    root = model_obj.Pack(builder)
    builder.Finish(root, file_identifier=b"TFL3")
    out_bytes = bytes(builder.Output())

    with open(DST, "wb") as f:
        f.write(out_bytes)
    print(f"wrote {DST} ({len(out_bytes)} bytes, was {len(buf)} bytes)")


if __name__ == "__main__":
    main()
