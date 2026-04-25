"""Fine-tune MobileNetV2 on Egyptian Pound notes & coins, then export TFLite.

Workflow:

1. Acquire a public Roboflow Universe dataset (e.g. "Egyptian Currency Detection").
   Roboflow exports a folder per class. Expected structure:

       data/egp/
           train/<class_name>/*.jpg
           val/<class_name>/*.jpg

   Class names must match (or be mappable to) `denominationToEgp` keys in
   `lib/src/features/vision/data/currency_classifier.dart`. Common synonyms
   like "100_pounds" and "100 EGP" are normalised below.

2. Run:  python scripts/train_egp_classifier.py --data data/egp --epochs 12

3. Copy `currency_egp.tflite` to `assets/models/`.

The exported model expects 224x224 RGB float32 input in [0, 1] and outputs a
softmax over `denominationsLabels` (see the Dart file for the canonical order).
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys

import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

LABELS = [
    "background",
    "25 piaster",
    "50 piaster",
    "1 EGP",
    "5 EGP",
    "10 EGP",
    "20 EGP",
    "50 EGP",
    "100 EGP",
    "200 EGP",
    "1 EGP coin",
]

LABEL_ALIASES = {
    "25_piaster": "25 piaster",
    "25piasters": "25 piaster",
    "50_piaster": "50 piaster",
    "50piasters": "50 piaster",
    "1_pound": "1 EGP",
    "1pound": "1 EGP",
    "5_pounds": "5 EGP",
    "10_pounds": "10 EGP",
    "20_pounds": "20 EGP",
    "50_pounds": "50 EGP",
    "100_pounds": "100 EGP",
    "200_pounds": "200 EGP",
    "1_pound_coin": "1 EGP coin",
    "background": "background",
}


def normalise_class_dirs(root: str) -> None:
    for split in ("train", "val"):
        split_dir = os.path.join(root, split)
        if not os.path.isdir(split_dir):
            continue
        for d in list(os.listdir(split_dir)):
            cur = os.path.join(split_dir, d)
            if not os.path.isdir(cur):
                continue
            mapped = LABEL_ALIASES.get(d.lower(), d)
            if mapped != d:
                target = os.path.join(split_dir, mapped)
                os.makedirs(target, exist_ok=True)
                for f in os.listdir(cur):
                    shutil.move(os.path.join(cur, f), os.path.join(target, f))
                os.rmdir(cur)


def build_model(num_classes: int) -> tf.keras.Model:
    base = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights="imagenet")
    base.trainable = False  # transfer learning first; unfreeze later for fine-tune
    inputs = tf.keras.Input(shape=(224, 224, 3))
    x = preprocess_input(inputs * 255.0)  # data already in [0, 1]
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)
    return tf.keras.Model(inputs, outputs)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True)
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--batch", type=int, default=32)
    parser.add_argument("--out", default="assets/models/currency_egp.tflite")
    args = parser.parse_args()

    normalise_class_dirs(args.data)

    train_ds = tf.keras.utils.image_dataset_from_directory(
        os.path.join(args.data, "train"),
        image_size=(224, 224),
        batch_size=args.batch,
        label_mode="categorical",
        class_names=LABELS,
        shuffle=True,
    ).map(lambda x, y: (x / 255.0, y))
    val_ds = tf.keras.utils.image_dataset_from_directory(
        os.path.join(args.data, "val"),
        image_size=(224, 224),
        batch_size=args.batch,
        label_mode="categorical",
        class_names=LABELS,
    ).map(lambda x, y: (x / 255.0, y))

    model = build_model(len(LABELS))
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(train_ds, validation_data=val_ds, epochs=args.epochs)

    # Optional fine-tune phase
    model.layers[2].trainable = True
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(train_ds, validation_data=val_ds, epochs=4)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite = converter.convert()
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "wb") as fh:
        fh.write(tflite)
    print(f"Wrote {args.out} ({len(tflite) / 1024:.1f} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
