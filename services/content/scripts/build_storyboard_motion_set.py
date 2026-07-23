#!/usr/bin/env python3
"""Нарезает storyboard на фазы без независимого масштабирования персонажа.

Каждая колонка содержит одну фазу одного и того же персонажа. Масштаб вычисляется
один раз по эталонной колонке, а вертикальная позиция всех фаз задаётся общей
линией стоп из manifest. Это не позволяет гире или поднятой руке сдвинуть фигуру.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def _content_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Пустая колонка storyboard")
    return bbox


def build(manifest_path: Path) -> list[Path]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    source = (manifest_path.parent / manifest["source"]).resolve()
    image = Image.open(source).convert("RGBA")
    phases = manifest["phases"]
    columns = len(phases)
    if columns not in (2, 3):
        raise ValueError("Runner поддерживает storyboard только из 2–3 фаз")
    cell_width = image.width // columns
    if cell_width <= 0:
        raise ValueError("Storyboard уже числа фаз")
    cells = [
        image.crop((index * cell_width, 0, (index + 1) * cell_width, image.height))
        for index in range(columns)
    ]
    reference_index = int(manifest.get("referenceIndex", 0))
    if not 0 <= reference_index < columns:
        raise ValueError("referenceIndex выходит за границы storyboard")
    reference_bbox = _content_bbox(cells[reference_index])
    source_baseline = int(manifest["sourceFeetBaseline"])
    if not reference_bbox[1] < source_baseline <= image.height:
        raise ValueError("sourceFeetBaseline не пересекает высоту эталонной фигуры")

    canvas_width, canvas_height = manifest.get("canvas", [1024, 1536])
    target_baseline = int(manifest.get("targetFeetBaseline", 1458))
    target_height = int(manifest.get("targetAthleteHeight", 1285))
    source_height = source_baseline - reference_bbox[1]
    scale = target_height / source_height

    outputs: list[Path] = []
    phase_baselines: list[int] = []
    for phase, cell in zip(phases, cells, strict=True):
        bbox = _content_bbox(cell)
        phase_baseline = int(phase.get("sourceFeetBaseline", source_baseline))
        phase_baselines.append(phase_baseline)
        scaled = cell.resize(
            (round(cell.width * scale), round(cell.height * scale)),
            Image.Resampling.LANCZOS,
        )
        scaled_bbox = _content_bbox(scaled)
        content_center = (scaled_bbox[0] + scaled_bbox[2]) // 2
        x = canvas_width // 2 - content_center
        y = target_baseline - round(phase_baseline * scale)
        frame = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
        frame.alpha_composite(scaled, (x, y))
        out = (manifest_path.parent / phase["output"]).resolve()
        out.parent.mkdir(parents=True, exist_ok=True)
        frame.save(out)
        outputs.append(out)

    report_path = manifest_path.with_name(manifest_path.stem + "-build-report.json")
    report_path.write_text(
        json.dumps(
            {
                "status": "pass",
                "source": str(source),
                "scale": scale,
                "sourceFeetBaseline": source_baseline,
                "phaseSourceFeetBaselines": phase_baselines,
                "targetFeetBaseline": target_baseline,
                "discardedRightPixels": image.width - cell_width * columns,
                "outputs": [str(path) for path in outputs],
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    outputs = build(args.manifest.resolve())
    print(f"OK: {len(outputs)} phase assets built with one shared transform")


if __name__ == "__main__":
    main()
