#!/usr/bin/env python3
"""Сравнивает пропорции одной фигуры в нескольких фазах движения.

Валидатор намеренно не определяет позу по bounding box. Он получает суставные
точки из manifest (от генератора позы или отдельного pose detector), оценивает
единый масштаб по длинам конечностей и измеряет толщину сегментов по alpha-маске.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


Point = tuple[float, float]

BONES = {
    'left_upper_arm': ('left_shoulder', 'left_elbow'),
    'right_upper_arm': ('right_shoulder', 'right_elbow'),
    'left_forearm': ('left_elbow', 'left_wrist'),
    'right_forearm': ('right_elbow', 'right_wrist'),
    'left_thigh': ('left_hip', 'left_knee'),
    'right_thigh': ('right_hip', 'right_knee'),
    'left_shin': ('left_knee', 'left_ankle'),
    'right_shin': ('right_knee', 'right_ankle'),
}

WIDTH_SAMPLES = {
    'left_biceps': ('left_shoulder', 'left_elbow', 0.48),
    'right_biceps': ('right_shoulder', 'right_elbow', 0.48),
    'left_forearm': ('left_elbow', 'left_wrist', 0.45),
    'right_forearm': ('right_elbow', 'right_wrist', 0.45),
    'left_thigh': ('left_hip', 'left_knee', 0.48),
    'right_thigh': ('right_hip', 'right_knee', 0.48),
    'left_calf': ('left_knee', 'left_ankle', 0.42),
    'right_calf': ('right_knee', 'right_ankle', 0.42),
}

DEFAULT_TOLERANCES = {
    'bone_length': 0.04,
    'head_width': 0.05,
    'shoulder_width': 0.05,
    'torso_width': 0.06,
    'limb_width': 0.07,
    'feet_baseline': 0.01,
}


def _point(landmarks: dict[str, list[float]], name: str) -> Point:
    value = landmarks.get(name)
    if not value or len(value) != 2:
        raise ValueError(f'Нет контрольной точки {name!r}')
    return float(value[0]), float(value[1])


def _distance(a: Point, b: Point) -> float:
    return math.hypot(b[0] - a[0], b[1] - a[1])


def _midpoint(a: Point, b: Point) -> Point:
    return (a[0] + b[0]) / 2, (a[1] + b[1]) / 2


def _alpha_mask(path: Path, threshold: int = 32) -> tuple[Image.Image, int, int]:
    image = Image.open(path).convert('RGBA')
    alpha = image.getchannel('A').point(lambda value: 255 if value >= threshold else 0)
    return alpha, image.width, image.height


def _occupied(mask: Image.Image, x: float, y: float) -> bool:
    ix, iy = round(x), round(y)
    return 0 <= ix < mask.width and 0 <= iy < mask.height and mask.getpixel((ix, iy)) > 0


def _section_width(mask: Image.Image, a: Point, b: Point, position: float) -> float:
    """Ширина непрозрачной фигуры поперёк сегмента около заданной доли длины."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy)
    if length < 2:
        raise ValueError('Слишком короткий сегмент для измерения')
    normal = (-dy / length, dx / length)
    center = (a[0] + dx * position, a[1] + dy * position)
    widths: list[float] = []
    # Не позволяем сечению «захватить» соседнюю ногу, вторую руку или корпус.
    # Радиус измерения привязан к длине конкретного сегмента.
    radius = max(12, min(90, round(length * 0.36)))
    for along in (-0.035, -0.0175, 0.0, 0.0175, 0.035):
        sample_center = (center[0] + dx * along, center[1] + dy * along)
        occupied = {
            offset
            for offset in range(-radius, radius + 1)
            if _occupied(mask, sample_center[0] + normal[0] * offset,
                         sample_center[1] + normal[1] * offset)
        }
        if not occupied:
            continue
        nearest = min(occupied, key=abs)
        run = {nearest}
        value = nearest - 1
        while value in occupied:
            run.add(value)
            value -= 1
        value = nearest + 1
        while value in occupied:
            run.add(value)
            value += 1
        widths.append(float(max(run) - min(run) + 1))
    if not widths:
        raise ValueError('Не найден силуэт в поперечном сечении сегмента')
    return statistics.median(widths)


def _horizontal_width(mask: Image.Image, y: float, center_x: float) -> float:
    occupied = [x for x in range(mask.width) if mask.getpixel((x, round(y))) > 0]
    if not occupied:
        raise ValueError('Не найден силуэт в горизонтальном сечении')
    center = min(occupied, key=lambda x: abs(x - center_x))
    run = {center}
    value = center - 1
    while value in occupied:
        run.add(value)
        value -= 1
    value = center + 1
    while value in occupied:
        run.add(value)
        value += 1
    return float(max(run) - min(run) + 1)


def measure(frame: dict[str, Any], manifest_dir: Path) -> dict[str, Any]:
    landmarks = frame['landmarks']
    image_path = (manifest_dir / frame['image']).resolve()
    mask, width, height = _alpha_mask(image_path)
    bones = {
        name: _distance(_point(landmarks, start), _point(landmarks, end))
        for name, (start, end) in BONES.items()
    }
    limb_widths = {
        name: _section_width(mask, _point(landmarks, start), _point(landmarks, end), position)
        for name, (start, end, position) in WIDTH_SAMPLES.items()
    }
    crown = _point(landmarks, 'crown')
    chin = _point(landmarks, 'chin')
    shoulders = (_point(landmarks, 'left_shoulder'), _point(landmarks, 'right_shoulder'))
    hips = (_point(landmarks, 'left_hip'), _point(landmarks, 'right_hip'))
    head_center = _midpoint(crown, chin)
    feet_y = max(_point(landmarks, 'left_foot')[1], _point(landmarks, 'right_foot')[1])
    return {
        'image': frame['image'],
        'imageSha256': hashlib.sha256(image_path.read_bytes()).hexdigest(),
        'canvas': [width, height],
        'bones': bones,
        'limbWidths': limb_widths,
        'headWidth': _horizontal_width(mask, head_center[1], head_center[0]),
        'shoulderWidth': _distance(*shoulders),
        'torsoWidth': _distance(*hips),
        'feetBaseline': feet_y / height,
    }


def compare(reference: dict[str, Any], candidate: dict[str, Any], tolerances: dict[str, float]) -> dict[str, Any]:
    if reference['canvas'] != candidate['canvas']:
        return {'status': 'reject', 'reason': 'canvas_mismatch', 'metrics': {}}
    scale_samples = [
        reference['bones'][name] / candidate['bones'][name]
        for name in BONES
        if candidate['bones'][name] > 0
    ]
    scale = statistics.median(scale_samples)
    metrics: dict[str, dict[str, float | str]] = {}

    def add(name: str, ref: float, value: float, tolerance: float, group: str, apply_scale: bool = True) -> None:
        normalized = value * scale if apply_scale else value
        deviation = abs(normalized / ref - 1) if ref else 0.0
        metrics[name] = {
            'reference': round(ref, 3),
            'candidate': round(normalized, 3),
            'deviation': round(deviation, 4),
            'tolerance': tolerance,
            'group': group,
        }

    for name in BONES:
        add(f'bone_{name}', reference['bones'][name], candidate['bones'][name], tolerances['bone_length'], 'bone_length')
    for name in WIDTH_SAMPLES:
        add(name, reference['limbWidths'][name], candidate['limbWidths'][name], tolerances['limb_width'], 'limb_width')
    add('head_width', reference['headWidth'], candidate['headWidth'], tolerances['head_width'], 'head_width')
    add('shoulder_width', reference['shoulderWidth'], candidate['shoulderWidth'], tolerances['shoulder_width'], 'shoulder_width')
    add('torso_width', reference['torsoWidth'], candidate['torsoWidth'], tolerances['torso_width'], 'torso_width')
    add('feet_baseline', reference['feetBaseline'], candidate['feetBaseline'], tolerances['feet_baseline'], 'feet_baseline', False)

    exceeded = [item for item in metrics.values() if item['deviation'] > item['tolerance']]
    severe = [item for item in metrics.values() if item['deviation'] > item['tolerance'] * 1.5]
    status = 'reject' if severe or len(exceeded) >= 2 else 'warn' if exceeded else 'pass'
    return {'status': status, 'scale': round(scale, 6), 'metrics': metrics}


def run(manifest_path: Path) -> dict[str, Any]:
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    tolerances = {**DEFAULT_TOLERANCES, **manifest.get('tolerances', {})}
    frames = manifest['frames']
    reference_id = manifest['referenceFrame']
    measured = {frame['id']: measure(frame, manifest_path.parent) for frame in frames}
    if reference_id not in measured:
        raise ValueError(f'Не найден referenceFrame {reference_id!r}')
    comparisons = {
        frame_id: compare(measured[reference_id], values, tolerances)
        for frame_id, values in measured.items()
        if frame_id != reference_id
    }
    overall = 'reject' if any(v['status'] == 'reject' for v in comparisons.values()) else (
        'warn' if any(v['status'] == 'warn' for v in comparisons.values()) else 'pass'
    )
    return {
        'schemaVersion': 1,
        'referenceFrame': reference_id,
        'status': overall,
        'tolerances': tolerances,
        'measurements': measured,
        'comparisons': comparisons,
    }


def write_overlays(manifest_path: Path, output_dir: Path) -> None:
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    output_dir.mkdir(parents=True, exist_ok=True)
    for frame in manifest['frames']:
        image = Image.open((manifest_path.parent / frame['image']).resolve()).convert('RGBA')
        draw = ImageDraw.Draw(image)
        landmarks = frame['landmarks']
        for start, end in BONES.values():
            draw.line([_point(landmarks, start), _point(landmarks, end)], fill=(220, 45, 45, 255), width=4)
        for name, value in landmarks.items():
            x, y = float(value[0]), float(value[1])
            draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill=(255, 205, 0, 255), outline=(80, 20, 20, 255), width=2)
            draw.text((x + 8, y - 8), name, fill=(220, 45, 45, 255))
        image.save(output_dir / f"{frame['id']}-landmarks.png")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--overlay-dir', type=Path)
    args = parser.parse_args()
    report = run(args.manifest.resolve())
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    if args.overlay_dir:
        write_overlays(args.manifest.resolve(), args.overlay_dir.resolve())
    print(f"{report['status'].upper()}: {args.report}")
    raise SystemExit(0 if report['status'] == 'pass' else 1 if report['status'] == 'warn' else 2)


if __name__ == '__main__':
    main()
