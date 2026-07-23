#!/usr/bin/env python3

import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

import validate_rig_manifest as validator


class RigManifestTest(unittest.TestCase):
    def test_preserves_segment_lengths_for_every_pose(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            Image.new('RGBA', (64, 64), (0, 0, 0, 0)).save(root / 'master.png')
            manifest = {
                'source': 'master.png',
                'canvas': [64, 64],
                'status': 'draft',
                'styleReview': 'pending_owner_review',
                'lockedLayers': ['head', 'torso', 'left_arm', 'pelvis', 'left_leg', 'right_leg'],
                'joints': {
                    'right_shoulder': [10, 10], 'right_elbow': [20, 10],
                    'right_wrist': [30, 10], 'kettlebell_handle': [30, 15],
                },
                'segments': {
                    'right_upper_arm': {'from': 'right_shoulder', 'to': 'right_elbow', 'length': 10},
                    'right_forearm': {'from': 'right_elbow', 'to': 'right_wrist', 'length': 10},
                },
                'poses': [
                    {'id': 'rack', 'upperArmAngleDegrees': 90, 'forearmAngleDegrees': -90, 'kettlebellAngleDegrees': 0},
                    {'id': 'lockout', 'upperArmAngleDegrees': -90, 'forearmAngleDegrees': -90, 'kettlebellAngleDegrees': 0},
                ],
                'layerMasks': {'base': None, 'right_upper_arm': None, 'right_forearm_hand': None, 'kettlebell': None},
            }
            path = root / 'rig.json'
            path.write_text(json.dumps(manifest), encoding='utf-8')
            report = validator.run(path)
            self.assertEqual(report['status'], 'pass')
            self.assertFalse(report['readyForRender'])
            for pose in report['poseGeometry'].values():
                self.assertEqual(pose['upperArmLength'], 10.0)
                self.assertEqual(pose['forearmLength'], 10.0)


if __name__ == '__main__':
    unittest.main()
