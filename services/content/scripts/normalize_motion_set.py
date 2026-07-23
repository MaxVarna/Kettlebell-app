#!/usr/bin/env python3
"""Нормализует набор из 2–3 RGBA-кадров по одному масштабу и линии стоп."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from normalize_motion_pair import content_bbox, normalized_frame


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=Path, action='append', required=True)
    parser.add_argument('--output', type=Path, action='append', required=True)
    parser.add_argument('--reference-index', type=int, default=0)
    parser.add_argument('--reference-height', type=int, default=1285)
    parser.add_argument('--feet-baseline', type=int, default=1458)
    parser.add_argument('--canvas-width', type=int, default=1024)
    parser.add_argument('--canvas-height', type=int, default=1536)
    args = parser.parse_args()

    if len(args.input) != len(args.output):
        parser.error('Количество --input и --output должно совпадать')
    if len(args.input) not in (2, 3):
        parser.error('Текущий runner поддерживает только 2 или 3 кадра')
    if not 0 <= args.reference_index < len(args.input):
        parser.error('--reference-index выходит за границы набора')

    reference = Image.open(args.input[args.reference_index]).convert('RGBA')
    bbox = content_bbox(reference)
    reference_height = bbox[3] - bbox[1]
    scale = args.reference_height / reference_height

    for source, destination in zip(args.input, args.output, strict=True):
        normalized_frame(
            source,
            destination,
            scale,
            args.canvas_width,
            args.canvas_height,
            args.feet_baseline,
        )

    print(
        f'OK: frames={len(args.input)}, scale={scale:.6f}, '
        f'baseline={args.feet_baseline}'
    )


if __name__ == '__main__':
    main()
