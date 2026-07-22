#!/usr/bin/env python3
"""Детерминированно разделяет утверждённый двухфазный storyboard пополам."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--out-left', type=Path, required=True)
    parser.add_argument('--out-right', type=Path, required=True)
    args = parser.parse_args()

    image = Image.open(args.input).convert('RGBA')
    if image.width % 2:
        raise ValueError(f'Ширина storyboard должна быть чётной: {image.width}')
    split = image.width // 2
    left = image.crop((0, 0, split, image.height))
    right = image.crop((split, 0, image.width, image.height))
    args.out_left.parent.mkdir(parents=True, exist_ok=True)
    args.out_right.parent.mkdir(parents=True, exist_ok=True)
    left.save(args.out_left)
    right.save(args.out_right)
    print(f'OK: {image.size} -> {left.size} + {right.size}')


if __name__ == '__main__':
    main()
