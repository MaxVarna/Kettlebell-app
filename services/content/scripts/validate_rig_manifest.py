#!/usr/bin/env python3
"""Проверяет геометрию производственного 2D-рига до нарезки слоёв."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image


def distance(a: list[float], b: list[float]) -> float:
    return math.hypot(b[0] - a[0], b[1] - a[1])


def run(manifest_path: Path) -> dict[str, Any]:
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    errors: list[str] = []
    source_path = (manifest_path.parent / manifest['source']).resolve()
    if not source_path.exists():
        errors.append(f'missing source: {source_path}')
        return {'status': 'reject', 'errors': errors}

    visual_reference = manifest.get('visualReference')
    visual_reference_path = (
        (manifest_path.parent / visual_reference).resolve()
        if visual_reference
        else None
    )
    if visual_reference_path and not visual_reference_path.exists():
        errors.append(f'missing visual reference: {visual_reference_path}')

    image = Image.open(source_path).convert('RGBA')
    if list(image.size) != manifest['canvas']:
        errors.append(f"canvas mismatch: {image.size} != {manifest['canvas']}")
    alpha = image.getchannel('A')
    if any(alpha.getpixel(point) != 0 for point in [(0, 0), (image.width - 1, 0), (0, image.height - 1), (image.width - 1, image.height - 1)]):
        errors.append('source corners must be transparent')

    joints = manifest['joints']
    measured: dict[str, float] = {}
    for name, segment in manifest['segments'].items():
        actual = distance(joints[segment['from']], joints[segment['to']])
        measured[name] = round(actual, 3)
        if abs(actual - float(segment['length'])) > 1.0:
            errors.append(f'{name} declared length differs from master by more than 1 px')

    pose_geometry: dict[str, Any] = {}
    shoulder = joints['right_shoulder']
    upper = measured['right_upper_arm']
    forearm = measured['right_forearm']
    for pose in manifest['poses']:
        upper_angle = math.radians(pose['upperArmAngleDegrees'])
        forearm_angle = math.radians(pose['forearmAngleDegrees'])
        elbow = [shoulder[0] + upper * math.cos(upper_angle), shoulder[1] + upper * math.sin(upper_angle)]
        wrist = [elbow[0] + forearm * math.cos(forearm_angle), elbow[1] + forearm * math.sin(forearm_angle)]
        pose_geometry[pose['id']] = {
            'shoulder': [round(value, 2) for value in shoulder],
            'elbow': [round(value, 2) for value in elbow],
            'wrist': [round(value, 2) for value in wrist],
            'upperArmLength': upper,
            'forearmLength': forearm,
        }

    required_locked = {'head', 'torso', 'left_arm', 'pelvis', 'left_leg', 'right_leg'}
    if not required_locked.issubset(set(manifest.get('lockedLayers', []))):
        errors.append('lockedLayers does not protect every invariant body layer')
    ready_for_render = all(manifest.get('layerMasks', {}).values()) and manifest.get('status') == 'approved'

    return {
        'schemaVersion': 1,
        'status': 'reject' if errors else 'pass',
        'rigStatus': manifest.get('status'),
        'styleReview': manifest.get('styleReview'),
        'readyForRender': ready_for_render,
        'source': str(source_path),
        'visualReference': str(visual_reference_path) if visual_reference_path else None,
        'measuredSegments': measured,
        'poseGeometry': pose_geometry,
        'errors': errors,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    report = run(args.manifest.resolve())
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f"{report['status'].upper()}: readyForRender={report['readyForRender']} {args.report}")
    raise SystemExit(0 if report['status'] == 'pass' else 2)


if __name__ == '__main__':
    main()
