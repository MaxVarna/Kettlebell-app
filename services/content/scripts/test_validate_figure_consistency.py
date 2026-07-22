#!/usr/bin/env python3

import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

import validate_figure_consistency as validator


LANDMARKS = {
    'crown': [100, 18], 'chin': [100, 48],
    'left_shoulder': [75, 62], 'right_shoulder': [125, 62],
    'left_elbow': [68, 105], 'right_elbow': [132, 105],
    'left_wrist': [65, 145], 'right_wrist': [135, 145],
    'left_hip': [84, 145], 'right_hip': [116, 145],
    'left_knee': [82, 205], 'right_knee': [118, 205],
    'left_ankle': [80, 265], 'right_ankle': [120, 265],
    'left_foot': [72, 280], 'right_foot': [128, 280],
}


def draw_person(path: Path, calf_width: int = 14, biceps_width: int = 14) -> None:
    image = Image.new('RGBA', (200, 300), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.ellipse((84, 18, 116, 50), fill='white')
    draw.polygon([(75, 62), (125, 62), (116, 145), (84, 145)], fill='white')
    for a, b, width in [
        ('left_shoulder', 'left_elbow', biceps_width), ('right_shoulder', 'right_elbow', biceps_width),
        ('left_elbow', 'left_wrist', 12), ('right_elbow', 'right_wrist', 12),
        ('left_hip', 'left_knee', 20), ('right_hip', 'right_knee', 20),
        ('left_knee', 'left_ankle', calf_width), ('right_knee', 'right_ankle', calf_width),
    ]:
        draw.line([tuple(LANDMARKS[a]), tuple(LANDMARKS[b])], fill='white', width=width)
    draw.line([tuple(LANDMARKS['left_ankle']), tuple(LANDMARKS['left_foot'])], fill='white', width=12)
    draw.line([tuple(LANDMARKS['right_ankle']), tuple(LANDMARKS['right_foot'])], fill='white', width=12)
    image.save(path)


class FigureConsistencyTest(unittest.TestCase):
    def test_passes_same_body_and_rejects_changed_calf_and_biceps(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            draw_person(root / 'reference.png')
            draw_person(root / 'same.png')
            draw_person(root / 'changed.png', calf_width=22, biceps_width=22)
            manifest = {
                'referenceFrame': 'reference',
                'frames': [
                    {'id': 'reference', 'image': 'reference.png', 'landmarks': LANDMARKS},
                    {'id': 'same', 'image': 'same.png', 'landmarks': LANDMARKS},
                    {'id': 'changed', 'image': 'changed.png', 'landmarks': LANDMARKS},
                ],
            }
            path = root / 'manifest.json'
            path.write_text(json.dumps(manifest), encoding='utf-8')
            report = validator.run(path)
            self.assertEqual(report['comparisons']['same']['status'], 'pass')
            self.assertEqual(report['comparisons']['changed']['status'], 'reject')
            self.assertEqual(report['status'], 'reject')


if __name__ == '__main__':
    unittest.main()
