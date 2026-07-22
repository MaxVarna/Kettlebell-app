#!/usr/bin/env python3
"""Нормализует два RGBA-кадра движения без изменения их взаимного масштаба."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def content_bbox(image: Image.Image, alpha_threshold: int = 16) -> tuple[int, int, int, int]:
    alpha = image.getchannel('A')
    bbox = alpha.point(lambda value: 255 if value > alpha_threshold else 0).getbbox()
    if bbox is None:
        raise ValueError('Кадр не содержит непрозрачных пикселей')
    return bbox


def normalized_frame(
    source: Path,
    destination: Path,
    scale: float,
    canvas_width: int,
    canvas_height: int,
    feet_baseline: int,
) -> None:
    image = Image.open(source).convert('RGBA')
    bbox = content_bbox(image)
    subject = image.crop(bbox)
    target_size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(target_size, Image.Resampling.LANCZOS)

    x = round((canvas_width - subject.width) / 2)
    y = feet_baseline - subject.height
    if x < 0 or y < 0 or x + subject.width > canvas_width or feet_baseline > canvas_height:
        raise ValueError(
            f'Нормализованный кадр не помещается в холст: {source.name}, '
            f'subject={subject.size}, canvas={canvas_width}x{canvas_height}'
        )

    canvas = Image.new('RGBA', (canvas_width, canvas_height), (0, 0, 0, 0))
    canvas.alpha_composite(subject, (x, y))
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--bottom', type=Path, required=True)
    parser.add_argument('--stand', type=Path, required=True)
    parser.add_argument('--out-bottom', type=Path, required=True)
    parser.add_argument('--out-stand', type=Path, required=True)
    parser.add_argument('--standing-height', type=int, default=1285)
    parser.add_argument('--feet-baseline', type=int, default=1458)
    parser.add_argument('--canvas-width', type=int, default=1024)
    parser.add_argument('--canvas-height', type=int, default=1536)
    args = parser.parse_args()

    standing = Image.open(args.stand).convert('RGBA')
    stand_bbox = content_bbox(standing)
    stand_height = stand_bbox[3] - stand_bbox[1]
    scale = args.standing_height / stand_height

    normalized_frame(
        args.bottom,
        args.out_bottom,
        scale,
        args.canvas_width,
        args.canvas_height,
        args.feet_baseline,
    )
    normalized_frame(
        args.stand,
        args.out_stand,
        scale,
        args.canvas_width,
        args.canvas_height,
        args.feet_baseline,
    )
    print(f'OK: scale={scale:.6f}, baseline={args.feet_baseline}')


if __name__ == '__main__':
    main()
