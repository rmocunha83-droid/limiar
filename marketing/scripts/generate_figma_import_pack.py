from __future__ import annotations

import base64
import html
import json
import zipfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
MARKETING = ROOT / "marketing"
OUT = MARKETING / "figma-import"
BRAND = MARKETING / "brand"
APP_STORE = MARKETING / "app-store"
ASSETS = MARKETING / "assets"
SITE = MARKETING / "site"


def data_uri(path: Path) -> str:
    suffix = path.suffix.lower()
    mime = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".svg": "image/svg+xml",
    }[suffix]
    return f"data:{mime};base64,{base64.b64encode(path.read_bytes()).decode('ascii')}"


def image_size(path: Path) -> tuple[int, int]:
    if path.suffix.lower() == ".svg":
        text = path.read_text(encoding="utf-8")
        if "viewBox=\"0 0 760 256\"" in text:
            return 760, 256
        return 256, 256
    with Image.open(path) as img:
        return img.size


def image_tag(path: Path, x: int, y: int, w: int, h: int, label: str) -> str:
    return f"""
  <g id="{html.escape(label)}">
    <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="#0D1715" stroke="#B3CFB8" stroke-opacity=".28"/>
    <image href="{data_uri(path)}" x="{x + 18}" y="{y + 18}" width="{w - 36}" height="{h - 82}" preserveAspectRatio="xMidYMid meet"/>
    <text x="{x + 20}" y="{y + h - 34}" fill="#F0E9D8" font-family="Inter, Arial, sans-serif" font-size="22" font-weight="700">{html.escape(label)}</text>
    <text x="{x + 20}" y="{y + h - 12}" fill="#C0C2BA" font-family="Inter, Arial, sans-serif" font-size="15">{html.escape(str(path.relative_to(ROOT)))}</text>
  </g>"""


def make_figma_svg() -> Path:
    width, height = 3200, 3600
    parts: list[str] = [
        f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
  <rect width="{width}" height="{height}" fill="#050A0B"/>
  <text x="96" y="132" fill="#D49F6E" font-family="Inter, Arial, sans-serif" font-size="30" font-weight="800" letter-spacing="6">LIMIAR MARKETING ASSETS</text>
  <text x="96" y="230" fill="#F0E9D8" font-family="Georgia, serif" font-size="104" font-weight="700">Figma import board</text>
  <text x="100" y="286" fill="#C0C2BA" font-family="Inter, Arial, sans-serif" font-size="34">Brand, App Store cards, landing assets and legal pages for the Limiar app.</text>

  <text x="96" y="410" fill="#D49F6E" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" letter-spacing="4">01 BRAND</text>"""
    ]

    brand_items = [
        (BRAND / "logo-lockup-dark.png", "Logo lockup dark"),
        (BRAND / "logo-lockup-light.png", "Logo lockup light"),
        (BRAND / "logo-mark-1024.png", "Logo mark"),
        (ASSETS / "limiar-threshold-visual.png", "Campaign visual"),
        (ASSETS / "limiar-dashboard-marketing.png", "Dashboard mock"),
    ]
    x, y = 96, 460
    for idx, (path, label) in enumerate(brand_items):
        w = 760 if idx < 2 else 430
        h = 330 if idx < 2 else 590
        parts.append(image_tag(path, x, y, w, h, label))
        x += w + 34
        if x > 2600:
            x, y = 96, y + 630

    parts.append('<text x="96" y="1320" fill="#D49F6E" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" letter-spacing="4">02 APP STORE CARDS</text>')
    x, y = 96, 1370
    for idx, path in enumerate(sorted(APP_STORE.glob("[0-9][0-9]-*.png")), 1):
        parts.append(image_tag(path, x, y, 560, 1120, f"App Store card {idx}"))
        x += 604

    parts.append('<text x="96" y="2680" fill="#D49F6E" font-family="Inter, Arial, sans-serif" font-size="26" font-weight="800" letter-spacing="4">03 LANDING + SITE</text>')
    site_items = [
        (SITE / "verification" / "home-desktop.png", "Landing desktop capture"),
        (SITE / "verification" / "home-mobile.png", "Landing mobile capture"),
        (SITE / "assets" / "hero-wide.jpg", "Hero wide"),
        (SITE / "assets" / "hero-portrait.jpg", "Hero portrait"),
        (SITE / "assets" / "app-dashboard.png", "Site dashboard crop"),
        (SITE / "assets" / "app-onboarding.png", "Site onboarding crop"),
    ]
    x, y = 96, 2730
    for idx, (path, label) in enumerate(site_items):
        parts.append(image_tag(path, x, y, 470, 640, label))
        x += 514
        if x > 2700:
            x, y = 96, y + 700

    parts.append("""
  <text x="96" y="3496" fill="#B3CFB8" font-family="Inter, Arial, sans-serif" font-size="28" font-weight="800">Source folders</text>
  <text x="96" y="3540" fill="#C0C2BA" font-family="Inter, Arial, sans-serif" font-size="22">marketing/brand  marketing/app-store  marketing/site  marketing/assets  marketing/manifest.json</text>
</svg>""")
    path = OUT / "limiar-figma-import-board.svg"
    path.write_text("\n".join(parts), encoding="utf-8")
    return path


def make_manifest(svg_path: Path, zip_path: Path) -> None:
    manifest = {
        "figma_import_svg": str(svg_path.relative_to(ROOT)),
        "zip": str(zip_path.relative_to(ROOT)),
        "recommended_import": "Drag limiar-figma-import-board.svg into a blank Figma canvas, then upload source assets from the ZIP if needed.",
        "asset_count": len([p for p in MARKETING.glob("**/*") if p.is_file()]),
    }
    (OUT / "figma-import-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def make_zip(svg_path: Path) -> Path:
    zip_path = OUT / "limiar-figma-import-pack.zip"
    include_suffixes = {".png", ".jpg", ".jpeg", ".svg", ".html", ".css", ".md", ".json"}
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.write(svg_path, svg_path.relative_to(ROOT))
        for p in sorted(MARKETING.glob("**/*")):
            if p.is_file() and p.suffix.lower() in include_suffixes and "figma-import" not in p.parts:
                zf.write(p, p.relative_to(ROOT))
    return zip_path


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    svg = make_figma_svg()
    zip_path = make_zip(svg)
    make_manifest(svg, zip_path)
    print(svg)
    print(zip_path)


if __name__ == "__main__":
    main()
