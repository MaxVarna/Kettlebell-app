#!/usr/bin/env python3
"""Собирает светлый контактный лист storyboard-источников для ручного review."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
ROWS = [
    ("1. HALO", "halo/halo-male-storyboard-v1.png", "halo/halo-female-storyboard-v1.png"),
    ("2. FRONT RACK SQUAT", "front-squat/front-squat-male-storyboard-v1.png", "front-squat/front-squat-female-storyboard-v1.png"),
    ("3. HIGH WINDMILL", "high-windmill/high-windmill-male-storyboard-v1.png", "high-windmill/high-windmill-female-storyboard-v1.png"),
    ("4. FIGURE EIGHT", "figure-eight/figure-eight-male-storyboard-v1.png", "figure-eight/figure-eight-female-storyboard-v1.png"),
    ("5. BOTTOM-UP PRESS", "bottom-up-press/bottom-up-press-male-storyboard-v1.png", "bottom-up-press/bottom-up-press-female-storyboard-v1.png"),
]


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in (Path("C:/Windows/Fonts/arialbd.ttf"), Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")):
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def main() -> None:
    source_dir = ROOT / "services/content/storyboards"
    width, row_height = 1800, 520
    sheet = Image.new("RGB", (width, row_height * len(ROWS)), "#F6F7F8")
    draw = ImageDraw.Draw(sheet)
    title_font = _font(30)
    label_font = _font(22)
    for row_index, (title, male_value, female_value) in enumerate(ROWS):
        top = row_index * row_height
        draw.text((34, top + 24), title, fill="#18212A", font=title_font)
        draw.text((650, top + 30), "MALE", fill="#687783", font=label_font)
        draw.text((1510, top + 30), "FEMALE", fill="#687783", font=label_font)
        for column, value in enumerate((male_value, female_value)):
            image = Image.open(source_dir / value).convert("RGBA")
            target_width, target_height = 850, 430
            scale = min(target_width / image.width, target_height / image.height)
            resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
            x = column * 900 + (900 - resized.width) // 2
            y = top + 75 + (430 - resized.height) // 2
            sheet.paste(resized, (x, y), resized)
        draw.line((20, top + row_height - 1, width - 20, top + row_height - 1), fill="#D9DEE2", width=2)
    output = ROOT / "docs/visual-probes/new-exercises-review-v1.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    print(f"OK: {output}")


if __name__ == "__main__":
    main()
