from __future__ import annotations

import json
import textwrap
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
MARKETING = ROOT / "marketing"
OUT = MARKETING / "paper-import"
BRAND = MARKETING / "brand"
APP_STORE = MARKETING / "app-store"
SITE_ASSETS = MARKETING / "site" / "assets"

COLORS = {
    "ink": (5, 10, 11),
    "surface": (19, 31, 28),
    "ivory": (240, 233, 216),
    "soft": (192, 194, 186),
    "sage": (179, 207, 184),
    "gold": (212, 159, 110),
}

GEORGIA = "/System/Library/Fonts/Supplemental/Georgia.ttf"
GEORGIA_BOLD = "/System/Library/Fonts/Supplemental/Georgia Bold.ttf"
ARIAL = "/System/Library/Fonts/Supplemental/Arial.ttf"
ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGB")
    sr = image.width / image.height
    dr = size[0] / size[1]
    if sr > dr:
        nw = int(image.height * dr)
        x = (image.width - nw) // 2
        image = image.crop((x, 0, x + nw, image.height))
    else:
        nh = int(image.width / dr)
        y = (image.height - nh) // 2
        image = image.crop((0, y, image.width, y + nh))
    return image.resize(size, Image.Resampling.LANCZOS)


def contain(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    scale = min(box[0] / image.width, box[1] / image.height)
    return image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)


def rounded_paste(base: Image.Image, image: Image.Image, xy: tuple[int, int], radius: int) -> None:
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, image.width, image.height), radius=radius, fill=255)
    base.paste(image, xy, mask)


def draw_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], label: str, caption: str = "") -> None:
    x, y = xy
    draw.text((x, y), label, font=font(ARIAL_BOLD, 24), fill=COLORS["gold"])
    if caption:
        draw.text((x, y + 34), caption, font=font(ARIAL, 20), fill=COLORS["soft"])


def header(draw: ImageDraw.ImageDraw, title: str, subtitle: str) -> None:
    draw.text((72, 64), "LIMIAR MARKETING ASSETS", font=font(ARIAL_BOLD, 24), fill=COLORS["gold"])
    draw.text((72, 106), title, font=font(GEORGIA_BOLD, 74), fill=COLORS["ivory"])
    draw.text((76, 200), subtitle, font=font(ARIAL, 27), fill=COLORS["soft"])


def make_brand_board() -> Path:
    canvas = Image.new("RGB", (1680, 1120), COLORS["ink"])
    draw = ImageDraw.Draw(canvas)
    header(draw, "Brand kit", "Logo, lockups, campaign visual, app icon and core palette.")

    lockup = Image.open(BRAND / "logo-lockup-dark.png")
    mark = Image.open(BRAND / "logo-mark-1024.png")
    hero = Image.open(MARKETING / "assets" / "limiar-threshold-visual.png")

    rounded_paste(canvas, contain(lockup, (720, 250)), (72, 312), 18)
    draw_label(draw, (72, 590), "Logo lockup", "PNG + SVG dark/light variants")

    rounded_paste(canvas, contain(mark, (260, 260)), (890, 304), 44)
    draw_label(draw, (890, 590), "Logo mark", "1024 PNG + SVG")

    rounded_paste(canvas, cover(hero, (380, 560)), (1218, 304), 18)
    draw_label(draw, (1218, 890), "Campaign visual", "Generated threshold artwork")

    palette = [
        ("Deep ink", "#050A0B", COLORS["ink"]),
        ("Ivory", "#F0E9D8", COLORS["ivory"]),
        ("Sage", "#B3CFB8", COLORS["sage"]),
        ("Gold", "#D49F6E", COLORS["gold"]),
        ("Surface", "#13201C", COLORS["surface"]),
    ]
    x = 72
    y = 760
    for name, hex_value, color in palette:
        draw.rounded_rectangle((x, y, x + 236, y + 128), radius=18, fill=color, outline=(255, 255, 255), width=1)
        draw.text((x, y + 150), name, font=font(ARIAL_BOLD, 20), fill=COLORS["ivory"])
        draw.text((x, y + 178), hex_value, font=font(ARIAL, 18), fill=COLORS["soft"])
        x += 276

    path = OUT / "paper-board-01-brand-kit.png"
    canvas.save(path, quality=95)
    return path


def make_app_store_board() -> Path:
    canvas = Image.new("RGB", (2200, 1540), COLORS["ink"])
    draw = ImageDraw.Draw(canvas)
    header(draw, "App Store cards", "Five 1290 x 2796 store cards grouped as a review board.")
    cards = sorted(APP_STORE.glob("[0-9][0-9]-*.png"))
    x = 72
    y = 310
    for idx, path in enumerate(cards, 1):
        thumb = contain(Image.open(path), (360, 780))
        rounded_paste(canvas, thumb, (x, y), 18)
        draw_label(draw, (x, y + thumb.height + 26), f"Card {idx}", path.stem.replace("-", " "))
        x += 412
    path = OUT / "paper-board-02-app-store-cards.png"
    canvas.save(path, quality=95)
    return path


def make_landing_board() -> Path:
    canvas = Image.new("RGB", (1680, 1420), COLORS["ink"])
    draw = ImageDraw.Draw(canvas)
    header(draw, "Landing and legal pages", "Static site, support, privacy and terms assets prepared for publication.")

    desktop = Image.open(MARKETING / "site" / "verification" / "home-desktop.png")
    mobile = Image.open(MARKETING / "site" / "verification" / "home-mobile.png")
    hero = Image.open(SITE_ASSETS / "hero-wide.jpg")

    rounded_paste(canvas, contain(desktop, (960, 690)), (72, 310), 18)
    draw_label(draw, (72, 1030), "Landing desktop", "marketing/site/index.html")

    rounded_paste(canvas, contain(mobile, (300, 720)), (1110, 310), 18)
    draw_label(draw, (1110, 1060), "Landing mobile", "responsive verification capture")

    rounded_paste(canvas, cover(hero, (438, 246)), (1110, 1130), 18)
    draw_label(draw, (72, 1150), "Public pages", "privacy.html  support.html  terms.html  app-store-copy.md")

    path = OUT / "paper-board-03-landing-legal.png"
    canvas.save(path, quality=95)
    return path


def make_index_html(board_paths: list[Path]) -> Path:
    asset_rows = "\n".join(
        f'<section><h2>{p.stem}</h2><img src="{p.name}" alt="{p.stem}"></section>' for p in board_paths
    )
    asset_list = "\n".join(
        f"<li>{path.relative_to(ROOT)}</li>"
        for path in sorted(MARKETING.glob("**/*"))
        if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".svg", ".html", ".md", ".json"}
    )
    html = f"""<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Limiar Paper Import Pack</title>
  <style>
    body {{ margin: 0; padding: 48px; background: #050A0B; color: #F0E9D8; font-family: Arial, sans-serif; }}
    h1 {{ font-family: Georgia, serif; font-size: 72px; margin: 0 0 12px; }}
    p {{ color: #C0C2BA; font-size: 20px; max-width: 860px; }}
    section {{ margin-top: 48px; }}
    h2 {{ color: #D49F6E; font-size: 20px; letter-spacing: .12em; text-transform: uppercase; }}
    img {{ width: 100%; max-width: 1680px; border: 1px solid rgba(179,207,184,.24); border-radius: 8px; }}
    ul {{ color: #C0C2BA; columns: 2; line-height: 1.7; }}
  </style>
</head>
<body>
  <h1>Limiar Paper Import Pack</h1>
  <p>Boards prontos para inserir no Paper quando a cota MCP estiver disponível: marca, cards App Store e landing/legal.</p>
  {asset_rows}
  <section><h2>Manifesto de arquivos</h2><ul>{asset_list}</ul></section>
</body>
</html>
"""
    path = OUT / "index.html"
    path.write_text(html, encoding="utf-8")
    return path


def make_zip(files: list[Path]) -> Path:
    zip_path = OUT / "limiar-paper-import-pack.zip"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for p in files:
            zf.write(p, p.relative_to(OUT))
        for p in [
            BRAND / "logo-mark.svg",
            BRAND / "logo-lockup-dark.svg",
            BRAND / "logo-lockup-light.svg",
            BRAND / "logo-mark-1024.png",
            BRAND / "logo-lockup-dark.png",
            BRAND / "logo-lockup-light.png",
            *sorted(APP_STORE.glob("[0-9][0-9]-*.png")),
            MARKETING / "assets" / "limiar-threshold-visual.png",
            MARKETING / "assets" / "limiar-dashboard-marketing.png",
            SITE_ASSETS / "hero-wide.jpg",
            SITE_ASSETS / "hero-portrait.jpg",
            SITE_ASSETS / "app-dashboard.png",
            SITE_ASSETS / "app-onboarding.png",
            MARKETING / "manifest.json",
            APP_STORE / "app-store-copy.md",
        ]:
            zf.write(p, p.relative_to(ROOT))
    return zip_path


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    boards = [make_brand_board(), make_app_store_board(), make_landing_board()]
    index = make_index_html(boards)
    manifest = {
        "paper_import_boards": [str(p.relative_to(ROOT)) for p in boards],
        "index": str(index.relative_to(ROOT)),
        "zip": "marketing/paper-import/limiar-paper-import-pack.zip",
        "note": "Paper MCP write was unavailable because the weekly MCP limit was reached.",
    }
    (OUT / "paper-import-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    make_zip([*boards, index, OUT / "paper-import-manifest.json"])


if __name__ == "__main__":
    main()
