"""Validate production motion assets referenced by ExerciseRecord v2 exports.

The checker deliberately treats the athlete baseline and declared scale as the
stable animation anchors.  It does not compare the outer bounding boxes of
poses because a raised arm or a travelling kettlebell changes those boxes
without changing the athlete's body scale.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
EXPORT = ROOT / "services/content/exports/exercises.v2.json"
MOBILE = ROOT / "apps/mobile"
EXPECTED_CANVAS = (1024, 1536)
EXPECTED_BASELINE_PX = 1458
BASELINE_TOLERANCE_PX = 4


def resolve_asset(value: str) -> Path:
    return MOBILE / value


def alpha_bbox(path: Path) -> tuple[int, int, int, int] | None:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        if rgba.size != EXPECTED_CANVAS:
            raise ValueError(f"{path}: canvas={rgba.size}, expected={EXPECTED_CANVAS}")
        corners = [rgba.getpixel(point)[3] for point in ((0, 0), (1023, 0), (0, 1535), (1023, 1535))]
        if any(corners):
            raise ValueError(f"{path}: canvas corners are not transparent: {corners}")
        return rgba.getchannel("A").getbbox()


def main() -> int:
    records = json.loads(EXPORT.read_text(encoding="utf-8"))
    errors: list[str] = []
    checked: set[Path] = set()

    for record in records:
        phases = record["phases"]
        baselines = {phase["visual"]["feetBaseline"] for phase in phases}
        scales = {phase["visual"]["scale"] for phase in phases}
        if len(baselines) != 1:
            errors.append(f"{record['id']}: phase feetBaseline values differ: {sorted(baselines)}")
        if len(scales) != 1:
            errors.append(f"{record['id']}: phase scale values differ: {sorted(scales)}")

        for phase in phases:
            assets = phase["visual"]["assets"]
            if set(assets) != {"male", "female"}:
                errors.append(f"{record['id']}/{phase['id']}: expected male+female assets")
                continue
            if assets["male"] == assets["female"]:
                errors.append(f"{record['id']}/{phase['id']}: male and female point to the same file")
            for variant, value in assets.items():
                path = resolve_asset(value)
                if not path.is_file():
                    errors.append(f"{record['id']}/{phase['id']}/{variant}: missing {path}")
                    continue
                if path in checked:
                    continue
                checked.add(path)
                try:
                    bbox = alpha_bbox(path)
                    if bbox is None:
                        raise ValueError(f"{path}: empty alpha channel")
                    if abs(bbox[3] - EXPECTED_BASELINE_PX) > BASELINE_TOLERANCE_PX:
                        raise ValueError(
                            f"{path}: alpha bottom={bbox[3]}, expected {EXPECTED_BASELINE_PX}±{BASELINE_TOLERANCE_PX}"
                        )
                except (OSError, ValueError) as exc:
                    errors.append(str(exc))

        anatomy_value = record.get("anatomy", {}).get("asset")
        if anatomy_value and not resolve_asset(anatomy_value).is_file():
            errors.append(f"{record['id']}: missing anatomy asset {resolve_asset(anatomy_value)}")

    if errors:
        print("ERROR: motion asset validation failed", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"OK: {len(records)} exercises, {len(checked)} unique phase assets validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
