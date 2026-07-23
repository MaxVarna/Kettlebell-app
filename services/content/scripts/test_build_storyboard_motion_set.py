#!/usr/bin/env python3

import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

import build_storyboard_motion_set as builder


class StoryboardBuilderTest(unittest.TestCase):
    def test_uses_one_scale_and_explicit_feet_baseline(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            sheet = Image.new("RGBA", (200, 200), (0, 0, 0, 0))
            draw = ImageDraw.Draw(sheet)
            draw.rectangle((30, 30, 70, 180), fill=(20, 20, 20, 255))
            draw.rectangle((120, 10, 180, 180), fill=(20, 20, 20, 255))
            sheet.save(root / "sheet.png")
            manifest = {
                "source": "sheet.png",
                "sourceFeetBaseline": 180,
                "targetFeetBaseline": 190,
                "targetAthleteHeight": 150,
                "canvas": [200, 200],
                "referenceIndex": 0,
                "phases": [
                    {"id": "one", "output": "one.png"},
                    {"id": "two", "output": "two.png", "sourceFeetBaseline": 180},
                ],
            }
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            outputs = builder.build(path)
            self.assertEqual(len(outputs), 2)
            for output in outputs:
                bbox = Image.open(output).convert("RGBA").getchannel("A").getbbox()
                self.assertIsNotNone(bbox)
                self.assertEqual(bbox[3], 191)
            report = json.loads((root / "manifest-build-report.json").read_text())
            self.assertEqual(report["scale"], 1.0)


if __name__ == "__main__":
    unittest.main()
