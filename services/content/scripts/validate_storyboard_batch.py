#!/usr/bin/env python3
"""Проверяет все manifest-сборки storyboard и сохраняет воспроизводимый отчёт."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]


def run(storyboards_dir: Path) -> dict:
    errors: list[str] = []
    assets: list[dict] = []
    manifests = sorted(storyboards_dir.glob("*/*.manifest.json"))
    for manifest_path in manifests:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        expected_canvas = tuple(manifest.get("canvas", [1024, 1536]))
        target_baseline = int(manifest.get("targetFeetBaseline", 1458))
        for phase in manifest["phases"]:
            path = (manifest_path.parent / phase["output"]).resolve()
            if not path.is_file():
                errors.append(f"missing: {path}")
                continue
            image = Image.open(path).convert("RGBA")
            bbox = image.getchannel("A").getbbox()
            if image.size != expected_canvas:
                errors.append(f"{path.name}: canvas {image.size} != {expected_canvas}")
            if bbox is None:
                errors.append(f"{path.name}: empty alpha")
                continue
            corners = [image.getpixel(point)[3] for point in ((0, 0), (image.width - 1, 0), (0, image.height - 1), (image.width - 1, image.height - 1))]
            if any(corners):
                errors.append(f"{path.name}: opaque corner")
            baseline_delta = bbox[3] - target_baseline
            if abs(baseline_delta) > 5:
                errors.append(f"{path.name}: baseline delta {baseline_delta}px")
            assets.append({
                "exerciseId": manifest["exerciseId"],
                "figureVariant": manifest["figureVariant"],
                "phaseId": phase["id"],
                "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "alphaBBox": list(bbox),
                "baselineDeltaPx": baseline_delta,
            })
    return {
        "schemaVersion": 1,
        "status": "pass" if not errors else "reject",
        "manifestCount": len(manifests),
        "exerciseCount": len({item["exerciseId"] for item in assets}),
        "assetCount": len(assets),
        "assets": assets,
        "errors": errors,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--storyboards-dir", type=Path, default=ROOT / "services/content/storyboards")
    parser.add_argument("--report", type=Path, default=ROOT / "services/content/storyboards/build-validation-report.json")
    args = parser.parse_args()
    report = run(args.storyboards_dir.resolve())
    args.report.resolve().write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{report['status'].upper()}: {report['exerciseCount']} exercises, {report['assetCount']} assets")
    raise SystemExit(0 if report["status"] == "pass" else 2)


if __name__ == "__main__":
    main()
