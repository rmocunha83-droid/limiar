from __future__ import annotations

import json
import math
import shutil
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
MARKETING = ROOT / "marketing"
ASSETS = MARKETING / "assets"
BRAND = MARKETING / "brand"
APP_STORE = MARKETING / "app-store"
PUBLIC_APP_STORE = ROOT / "app-store"
SITE_ASSETS = MARKETING / "site" / "assets"

GENERATED_SOURCE = Path(
    "/Users/romeucunha/.codex/generated_images/019eed3d-bedf-7aa2-bdb0-3e7cbe0d3fb7/"
    "ig_05da238ddc92832e016a38a3a05fc8819180a3a05fc8819180a3b28165c5b145.png"
)

# Corrected below if the image name above is not present; kept explicit in the manifest.
GENERATED_FALLBACK = Path(
    "/Users/romeucunha/.codex/generated_images/019eed3d-bedf-7aa2-bdb0-3e7cbe0d3fb7/"
    "ig_05da238ddc92832e016a38a3a05fc8819180a3b28165c5b145.png"
)

COLORS = {
    "deep_ink": (5, 10, 11),
    "deep_ink_2": (13, 27, 25),
    "ivory": (240, 233, 216),
    "soft_text": (192, 194, 186),
    "sage": (179, 207, 184),
    "sage_dark": (93, 125, 104),
    "gold": (212, 159, 110),
    "stone": (91, 86, 73),
    "white": (255, 255, 255),
}

GEORGIA = "/System/Library/Fonts/Supplemental/Georgia.ttf"
GEORGIA_BOLD = "/System/Library/Fonts/Supplemental/Georgia Bold.ttf"
ARIAL = "/System/Library/Fonts/Supplemental/Arial.ttf"
ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def ensure_dirs() -> None:
    for folder in (ASSETS, BRAND, APP_STORE, PUBLIC_APP_STORE, SITE_ASSETS):
        folder.mkdir(parents=True, exist_ok=True)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def paste_rounded(base: Image.Image, image: Image.Image, xy: tuple[int, int], radius: int) -> None:
    mask = rounded_mask(image.size, radius)
    base.paste(image, xy, mask)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        draw.line((0, y, width, y), fill=color)
    return img


def cover_crop(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGB")
    src_ratio = image.width / image.height
    dst_ratio = size[0] / size[1]
    if src_ratio > dst_ratio:
        new_h = image.height
        new_w = int(new_h * dst_ratio)
        left = (image.width - new_w) // 2
        image = image.crop((left, 0, left + new_w, image.height))
    else:
        new_w = image.width
        new_h = int(new_w / dst_ratio)
        top = (image.height - new_h) // 2
        image = image.crop((0, top, image.width, top + new_h))
    return image.resize(size, Image.Resampling.LANCZOS)


def contain(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    ratio = min(box[0] / image.width, box[1] / image.height)
    size = (int(image.width * ratio), int(image.height * ratio))
    return image.resize(size, Image.Resampling.LANCZOS)


def draw_wrapped(
    draw: ImageDraw.ImageDraw,
    text: str,
    xy: tuple[int, int],
    font_obj: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int] | tuple[int, int, int, int],
    max_width: int,
    line_spacing: int,
) -> int:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        test = word if not current else f"{current} {word}"
        if draw.textbbox((0, 0), test, font=font_obj)[2] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    x, y = xy
    for line in lines:
        draw.text((x, y), line, font=font_obj, fill=fill)
        bbox = draw.textbbox((x, y), line, font=font_obj)
        y = bbox[3] + line_spacing
    return y


def draw_centered_wrapped(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    font_obj: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int] | tuple[int, int, int, int],
    max_width: int,
    canvas_width: int,
    line_spacing: int,
) -> int:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        test = word if not current else f"{current} {word}"
        if draw.textbbox((0, 0), test, font=font_obj)[2] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font_obj)
        x = (canvas_width - (bbox[2] - bbox[0])) // 2
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += (bbox[3] - bbox[1]) + line_spacing
    return y


def draw_instagram_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = box
    size = x2 - x1
    draw.rounded_rectangle(box, radius=max(18, size // 5), fill=(192, 54, 139, 255))
    draw.ellipse((x1 + int(size * 0.04), y1 + int(size * 0.54), x1 + int(size * 0.58), y2 - int(size * 0.02)), fill=(245, 156, 70, 220))
    draw.ellipse((x1 + int(size * 0.46), y1 + int(size * 0.02), x2 - int(size * 0.02), y1 + int(size * 0.5)), fill=(104, 74, 202, 210))
    pad = int(size * 0.23)
    draw.rounded_rectangle((x1 + pad, y1 + pad, x2 - pad, y2 - pad), radius=int(size * 0.18), outline=(255, 255, 255, 236), width=max(3, size // 14))
    draw.ellipse((x1 + int(size * 0.42), y1 + int(size * 0.42), x1 + int(size * 0.58), y1 + int(size * 0.58)), outline=(255, 255, 255, 236), width=max(3, size // 16))
    draw.ellipse((x1 + int(size * 0.66), y1 + int(size * 0.28), x1 + int(size * 0.74), y1 + int(size * 0.36)), fill=(255, 255, 255, 236))


def draw_youtube_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = box
    draw.rounded_rectangle(box, radius=(x2 - x1) // 4, fill=(255, 0, 0, 255))
    cx = (x1 + x2) // 2
    cy = (y1 + y2) // 2
    s = (x2 - x1) // 3
    draw.polygon([(cx - s // 3, cy - s // 2), (cx - s // 3, cy + s // 2), (cx + s // 2, cy)], fill=(255, 255, 255, 255))


def draw_tiktok_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = box
    size = x2 - x1
    draw.rounded_rectangle(box, radius=size // 5, fill=(5, 10, 11, 255))
    note_font = font(ARIAL_BOLD, int(size * 0.72))
    draw.text((x1 + int(size * 0.28), y1 + int(size * 0.13)), "♪", font=note_font, fill=(255, 45, 85, 255))
    draw.text((x1 + int(size * 0.22), y1 + int(size * 0.08)), "♪", font=note_font, fill=(105, 201, 208, 255))
    draw.text((x1 + int(size * 0.25), y1 + int(size * 0.1)), "♪", font=note_font, fill=(255, 255, 255, 255))


def draw_x_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = box
    size = x2 - x1
    draw.rounded_rectangle(box, radius=size // 5, fill=(18, 22, 24, 255))
    draw.line((x1 + size * 0.28, y1 + size * 0.26, x2 - size * 0.26, y2 - size * 0.25), fill=(255, 255, 255, 245), width=max(5, size // 12))
    draw.line((x2 - size * 0.28, y1 + size * 0.26, x1 + size * 0.26, y2 - size * 0.25), fill=(255, 255, 255, 245), width=max(5, size // 12))


def draw_screen_time_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = box
    size = x2 - x1
    draw.rounded_rectangle(box, radius=size // 4, fill=COLORS["sage"] + (255,))
    cx = (x1 + x2) // 2
    cy = (y1 + y2) // 2
    r = int(size * 0.28)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=COLORS["deep_ink"] + (235,), width=max(4, size // 14))
    draw.line((cx, cy, cx, cy - int(size * 0.18)), fill=COLORS["deep_ink"] + (235,), width=max(4, size // 16))
    draw.line((cx, cy, cx + int(size * 0.16), cy + int(size * 0.1)), fill=COLORS["deep_ink"] + (235,), width=max(4, size // 16))


def draw_book_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: tuple[int, int, int] = COLORS["sage"]) -> None:
    x1, y1, x2, y2 = box
    w = x2 - x1
    draw.rounded_rectangle(box, radius=w // 5, fill=fill + (255,))
    pad = int(w * 0.22)
    mid = x1 + w // 2
    top = y1 + pad
    bottom = y2 - pad
    stroke = COLORS["deep_ink"] + (235,)
    draw.line((mid, top, mid, bottom), fill=stroke, width=max(3, w // 18))
    draw.line((x1 + pad, top + 4, mid, top + int(w * 0.14)), fill=stroke, width=max(4, w // 16))
    draw.line((x1 + pad, top + 4, x1 + pad, bottom - 4), fill=stroke, width=max(4, w // 16))
    draw.line((x1 + pad, bottom - 4, mid, bottom), fill=stroke, width=max(4, w // 16))
    draw.line((mid, top + int(w * 0.14), x2 - pad, top + 4), fill=stroke, width=max(4, w // 16))
    draw.line((x2 - pad, top + 4, x2 - pad, bottom - 4), fill=stroke, width=max(4, w // 16))
    draw.line((mid, bottom, x2 - pad, bottom - 4), fill=stroke, width=max(4, w // 16))


def draw_return_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = box
    size = x2 - x1
    draw.rounded_rectangle(box, radius=size // 5, fill=COLORS["gold"] + (255,))
    draw.arc((x1 + size * 0.22, y1 + size * 0.18, x2 - size * 0.18, y2 - size * 0.18), 45, 285, fill=COLORS["deep_ink"] + (245,), width=max(5, size // 13))
    draw.polygon([(x1 + size * 0.28, y1 + size * 0.55), (x1 + size * 0.12, y1 + size * 0.58), (x1 + size * 0.21, y1 + size * 0.42)], fill=COLORS["deep_ink"] + (245,))


def draw_lock_icon(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: tuple[int, int, int] = COLORS["deep_ink"]) -> None:
    x1, y1, x2, y2 = box
    size = x2 - x1
    stroke = fill + (245,)
    body = (x1 + int(size * 0.22), y1 + int(size * 0.44), x2 - int(size * 0.22), y2 - int(size * 0.14))
    shackle = (x1 + int(size * 0.30), y1 + int(size * 0.18), x2 - int(size * 0.30), y1 + int(size * 0.60))
    draw.arc(shackle, 180, 360, fill=stroke, width=max(4, size // 12))
    draw.rounded_rectangle(body, radius=max(5, size // 10), outline=stroke, width=max(4, size // 13))
    cx = (x1 + x2) // 2
    cy = y1 + int(size * 0.62)
    draw.ellipse((cx - size * 0.055, cy - size * 0.055, cx + size * 0.055, cy + size * 0.055), fill=stroke)
    draw.line((cx, cy + size * 0.04, cx, cy + size * 0.18), fill=stroke, width=max(3, size // 18))


def make_mark_svg() -> str:
    return """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" role="img" aria-labelledby="title desc">
  <title id="title">Limiar logo mark</title>
  <desc id="desc">A calm threshold-shaped mark combining an open doorway and an open book.</desc>
  <rect width="256" height="256" rx="56" fill="#050A0B"/>
  <path d="M72 206V57c0-6 5-11 11-11h83c10 0 18 8 18 18v142" fill="none" stroke="#B3CFB8" stroke-width="13" stroke-linecap="round"/>
  <path d="M100 72h51c6 0 11 5 11 11v96" fill="none" stroke="#EFE9D8" stroke-width="9" stroke-linecap="round" opacity=".82"/>
  <path d="M57 201c31-16 59-16 84 0 25-16 52-16 83 0" fill="none" stroke="#D49F6E" stroke-width="12" stroke-linecap="round"/>
  <path d="M141 90v112" fill="none" stroke="#D49F6E" stroke-width="7" stroke-linecap="round"/>
</svg>
"""


def make_lockup_svg(theme: str = "dark") -> str:
    bg = "#050A0B" if theme == "dark" else "none"
    text = "#EFE9D8" if theme == "dark" else "#050A0B"
    sub = "#BFC2BA" if theme == "dark" else "#5D6D61"
    mark_bg = "#050A0B"
    bg_rect = f'<rect width="760" height="256" rx="36" fill="{bg}"/>' if bg != "none" else ""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 256" role="img" aria-labelledby="title desc">
  <title id="title">Limiar logo lockup</title>
  <desc id="desc">Limiar wordmark with threshold and book symbol.</desc>
  {bg_rect}
  <g transform="translate(40 40) scale(.6875)">
    <rect width="256" height="256" rx="56" fill="{mark_bg}"/>
    <path d="M72 206V57c0-6 5-11 11-11h83c10 0 18 8 18 18v142" fill="none" stroke="#B3CFB8" stroke-width="13" stroke-linecap="round"/>
    <path d="M100 72h51c6 0 11 5 11 11v96" fill="none" stroke="#EFE9D8" stroke-width="9" stroke-linecap="round" opacity=".82"/>
    <path d="M57 201c31-16 59-16 84 0 25-16 52-16 83 0" fill="none" stroke="#D49F6E" stroke-width="12" stroke-linecap="round"/>
    <path d="M141 90v112" fill="none" stroke="#D49F6E" stroke-width="7" stroke-linecap="round"/>
  </g>
  <text x="246" y="119" fill="{text}" font-family="Georgia, serif" font-size="76" letter-spacing="0">Limiar</text>
  <text x="252" y="164" fill="{sub}" font-family="Arial, sans-serif" font-size="23" letter-spacing="1.6">ATRAVESSE COM CALMA</text>
</svg>
"""


def render_icon_png(path: Path, size: int = 1024) -> None:
    img = Image.new("RGBA", (size, size), COLORS["deep_ink"] + (255,))
    draw = ImageDraw.Draw(img)
    scale = size / 256

    def p(points):
        return tuple(int(v * scale) for v in points)

    # Subtle inner glow.
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse(p((82, 32, 232, 218)), fill=COLORS["sage"] + (45,))
    glow = glow.filter(ImageFilter.GaussianBlur(int(24 * scale)))
    img.alpha_composite(glow)

    draw.line(p((72, 206, 72, 57, 83, 46, 166, 46, 184, 64, 184, 206)), fill=COLORS["sage"] + (255,), width=int(13 * scale), joint="curve")
    draw.line(p((100, 72, 151, 72, 162, 83, 162, 179)), fill=COLORS["ivory"] + (220,), width=int(9 * scale), joint="curve")
    draw.arc(p((52, 180, 141, 225)), start=190, end=350, fill=COLORS["gold"] + (255,), width=int(12 * scale))
    draw.arc(p((141, 180, 230, 225)), start=190, end=350, fill=COLORS["gold"] + (255,), width=int(12 * scale))
    draw.line(p((141, 90, 141, 202)), fill=COLORS["gold"] + (255,), width=int(7 * scale))
    img.save(path)


def render_logo_png(path: Path, theme: str = "dark") -> None:
    size = (1520, 512)
    bg = COLORS["deep_ink"] + (255,) if theme == "dark" else (0, 0, 0, 0)
    img = Image.new("RGBA", size, bg)
    mark = Image.new("RGBA", (352, 352), (0, 0, 0, 0))
    tmp = BRAND / "_tmp_mark.png"
    render_icon_png(tmp, 512)
    mark = Image.open(tmp).resize((352, 352), Image.Resampling.LANCZOS)
    tmp.unlink(missing_ok=True)
    img.alpha_composite(mark, (82, 80))
    draw = ImageDraw.Draw(img)
    text = COLORS["ivory"] if theme == "dark" else COLORS["deep_ink"]
    sub = COLORS["soft_text"] if theme == "dark" else COLORS["sage_dark"]
    draw.text((494, 138), "Limiar", font=font(GEORGIA, 160), fill=text + (255,))
    draw.text((506, 310), "ATRAVESSE COM CALMA", font=font(ARIAL_BOLD, 42), fill=sub + (255,))
    img.save(path)


def copy_generated_visual() -> Path:
    source = GENERATED_SOURCE if GENERATED_SOURCE.exists() else GENERATED_FALLBACK
    target = ASSETS / "limiar-threshold-visual.png"
    shutil.copy2(source, target)
    shutil.copy2(source, SITE_ASSETS / "limiar-threshold-visual.png")
    return target


def make_logo_assets() -> None:
    (BRAND / "logo-mark.svg").write_text(make_mark_svg(), encoding="utf-8")
    (BRAND / "logo-lockup-dark.svg").write_text(make_lockup_svg("dark"), encoding="utf-8")
    (BRAND / "logo-lockup-light.svg").write_text(make_lockup_svg("light"), encoding="utf-8")
    render_icon_png(BRAND / "logo-mark-1024.png")
    render_icon_png(SITE_ASSETS / "logo-mark-1024.png")
    render_logo_png(BRAND / "logo-lockup-dark.png", "dark")
    render_logo_png(BRAND / "logo-lockup-light.png", "light")


def phone_frame(screenshot: Image.Image, height: int) -> Image.Image:
    screen = contain(screenshot, (int(height * 0.47), height - 68))
    w, h = screen.size
    frame = Image.new("RGBA", (w + 52, h + 52), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rounded_rectangle((0, 0, frame.width, frame.height), radius=86, fill=(12, 17, 17, 255))
    draw.rounded_rectangle((13, 13, frame.width - 13, frame.height - 13), radius=72, fill=(24, 29, 29, 255))
    paste_rounded(frame, screen, (26, 26), 58)
    draw.rounded_rectangle((frame.width // 2 - 80, 28, frame.width // 2 + 80, 58), radius=16, fill=(5, 10, 11, 235))
    return frame


def make_dashboard_mock(path: Path, visual: Image.Image) -> None:
    size = (1170, 2532)
    img = cover_crop(visual, size).convert("RGBA")
    img.alpha_composite(Image.new("RGBA", size, (5, 10, 11, 205)))
    draw = ImageDraw.Draw(img)

    # Status bar.
    draw.text((78, 48), "22:58", font=font(ARIAL_BOLD, 42), fill=COLORS["ivory"] + (255,))
    draw.text((935, 48), "  Wi-Fi", font=font(ARIAL_BOLD, 30), fill=COLORS["ivory"] + (230,))

    x = 78
    y = 160
    draw.text((x, y), "Limiar", font=font(GEORGIA, 96), fill=COLORS["ivory"] + (255,))
    y += 126
    draw_wrapped(draw, "Reserve alguns minutos para iluminar sua mente.", (x, y), font(ARIAL, 38), COLORS["soft_text"] + (255,), 780, 12)

    def panel(box):
        draw.rounded_rectangle(box, radius=34, fill=(5, 10, 11, 222), outline=COLORS["sage"] + (92,), width=2)

    y = 442
    panel((x, y, 1092, y + 220))
    draw.text((x + 28, y + 26), "APPS PROTEGIDOS", font=font(ARIAL_BOLD, 27), fill=COLORS["gold"] + (255,))
    icon_x = x + 30
    for icon_drawer in (draw_instagram_icon, draw_tiktok_icon, draw_youtube_icon, draw_x_icon):
        icon_drawer(draw, (icon_x, y + 86, icon_x + 98, y + 184))
        icon_x += 126
    draw_wrapped(draw, "Somente os ícones aparecem antes da leitura.", (x + 548, y + 88), font(ARIAL, 32), COLORS["soft_text"] + (255,), 430, 9)

    y += 300
    draw.text((x, y), "SEU LIMIAR", font=font(ARIAL_BOLD, 27), fill=COLORS["gold"] + (255,))
    y += 54
    draw_wrapped(draw, "Caminho de leitura", (x, y), font(GEORGIA, 78), COLORS["ivory"] + (255,), 940, 10)
    y += 120
    draw_wrapped(draw, "Leia com calma e conclua para liberar temporariamente os apps protegidos.", (x, y), font(ARIAL, 38), COLORS["soft_text"] + (255,), 920, 12)

    y += 132
    panel((x, y, 1092, y + 680))
    draw.text((x + 30, y + 30), "1. Salmo 23", font=font(ARIAL_BOLD, 31), fill=COLORS["gold"] + (255,))
    draw.text((958, y + 30), "Salvar", font=font(ARIAL_BOLD, 31), fill=COLORS["sage"] + (255,))
    quote = "O Senhor é meu pastor: nada me faltará. Em verdes pastagens me faz repousar, para fontes tranquilas me conduz."
    next_quote = "2. Mateus 11, 28-30: Venham a mim todos os que estão cansados e sobrecarregados, e eu lhes darei descanso."
    draw_wrapped(draw, quote, (x + 30, y + 112), font(GEORGIA, 43), COLORS["ivory"] + (255,), 930, 14)
    draw_wrapped(draw, next_quote, (x + 30, y + 338), font(GEORGIA, 39), COLORS["ivory"] + (240,), 930, 14)
    draw.text((x + 30, y + 524), "Explicação espiritual", font=font(ARIAL_BOLD, 28), fill=COLORS["gold"] + (255,))
    draw_wrapped(draw, "O trecho convida a atravessar o impulso com confiança, presença e cuidado interior.", (x + 30, y + 568), font(ARIAL, 29), COLORS["soft_text"] + (255,), 900, 10)

    y += 740
    panel((x, y, 1092, y + 172))
    draw.text((x + 34, y + 38), "Ajustar apps protegidos", font=font(GEORGIA, 43), fill=COLORS["ivory"] + (255,))
    draw.text((x + 34, y + 96), "Escolha quais apps você quer proteger", font=font(ARIAL, 30), fill=COLORS["soft_text"] + (255,))
    draw.text((1046, y + 58), "›", font=font(ARIAL_BOLD, 64), fill=COLORS["sage"] + (255,))

    y += 230
    draw.rounded_rectangle((x, y, 1092, y + 204), radius=42, fill=COLORS["sage"] + (255,))
    draw_lock_icon(draw, (x + 44, y + 58, x + 92, y + 106))
    draw.text((x + 118, y + 42), "Li com calma, liberar acesso", font=font(GEORGIA, 46), fill=COLORS["deep_ink"] + (255,))
    draw.text((x + 120, y + 108), "Libera por 30 minutos", font=font(ARIAL, 30), fill=COLORS["deep_ink"] + (210,))
    draw.text((1010, y + 58), "›", font=font(ARIAL_BOLD, 58), fill=COLORS["deep_ink"] + (255,))
    img.convert("RGB").save(path, quality=95)


def make_card(
    filename: str,
    kicker: str,
    headline: str,
    body: str,
    screenshot_path: Path | None,
    visual: Image.Image,
    accent: tuple[int, int, int],
) -> None:
    size = (1290, 2796)
    card = gradient(size, COLORS["deep_ink_2"], COLORS["deep_ink"]).convert("RGBA")
    bg = cover_crop(visual, size).convert("RGBA").filter(ImageFilter.GaussianBlur(2))
    overlay = Image.new("RGBA", size, (5, 10, 11, 142))
    card.alpha_composite(bg)
    card.alpha_composite(overlay)
    draw = ImageDraw.Draw(card)

    # Vignette.
    shade = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for i in range(0, 430, 8):
        alpha = int(80 * (i / 430))
        sd.rounded_rectangle((i, i, size[0] - i, size[1] - i), radius=80, outline=(0, 0, 0, alpha), width=10)
    card.alpha_composite(shade)

    draw.text((88, 112), kicker.upper(), font=font(ARIAL_BOLD, 34), fill=COLORS["gold"] + (255,))
    y = draw_wrapped(draw, headline, (88, 184), font(GEORGIA_BOLD, 86), COLORS["ivory"] + (255,), 1010, 20)
    y = draw_wrapped(draw, body, (92, y + 26), font(ARIAL, 37), COLORS["soft_text"] + (255,), 920, 16)

    draw.rounded_rectangle((88, 2440, 1202, 2596), radius=46, fill=COLORS["sage"] + (238,))
    draw.text((138, 2484), "Limiar", font=font(GEORGIA_BOLD, 60), fill=COLORS["deep_ink"] + (255,))
    draw.text((400, 2504), "Pausa espiritual antes do impulso", font=font(ARIAL_BOLD, 33), fill=COLORS["deep_ink"] + (220,))

    if screenshot_path and screenshot_path.exists():
        framed = phone_frame(Image.open(screenshot_path), 1380)
        x = (size[0] - framed.width) // 2
        visual_y = max(740, y + 86)
        visual_y = min(visual_y, 2384 - framed.height)

        glow = Image.new("RGBA", size, (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse((x - 120, visual_y - 72, x + framed.width + 120, visual_y + framed.height + 128), fill=accent + (42,))
        glow = glow.filter(ImageFilter.GaussianBlur(42))
        card.alpha_composite(glow)

        if filename.startswith("01"):
            pill = (162, visual_y - 86, 1128, visual_y + 22)
            draw.rounded_rectangle(pill, radius=36, fill=(5, 10, 11, 196), outline=COLORS["sage"] + (95,), width=2)
            icon_x = pill[0] + 36
            for icon_drawer in (draw_instagram_icon, draw_tiktok_icon, draw_youtube_icon, draw_x_icon):
                icon_drawer(draw, (icon_x, pill[1] + 20, icon_x + 68, pill[1] + 88))
                icon_x += 84
            draw.text((icon_x + 12, pill[1] + 28), "Apps sociais ganham um limiar", font=font(ARIAL_BOLD, 34), fill=COLORS["ivory"] + (238,))

        card.alpha_composite(framed, (x, visual_y))
    else:
        panel_x1, panel_y1, panel_x2, panel_y2 = 118, 760, 1172, 2246
        draw.rounded_rectangle((panel_x1, panel_y1, panel_x2, panel_y2), radius=58, fill=(5, 10, 11, 184), outline=COLORS["sage"] + (88,), width=2)
        draw.text((panel_x1 + 64, panel_y1 + 68), "Apps protegidos", font=font(GEORGIA_BOLD, 62), fill=COLORS["ivory"] + (255,))
        draw.text((panel_x1 + 66, panel_y1 + 142), "Escolha quais apps deseja proteger.", font=font(ARIAL, 34), fill=COLORS["soft_text"] + (255,))

        app_y = panel_y1 + 260
        social_icons = [
            ("Instagram", draw_instagram_icon),
            ("TikTok", draw_tiktok_icon),
            ("YouTube", draw_youtube_icon),
            ("X", draw_x_icon),
        ]
        for index, (label, icon_drawer) in enumerate(social_icons):
            row = index // 2
            col = index % 2
            x1 = panel_x1 + 64 + col * 472
            y1 = app_y + row * 186
            draw.rounded_rectangle((x1, y1, x1 + 412, y1 + 142), radius=34, fill=(255, 255, 255, 22), outline=COLORS["sage"] + (70,), width=2)
            icon_drawer(draw, (x1 + 28, y1 + 29, x1 + 112, y1 + 113))
            draw.text((x1 + 138, y1 + 36), label, font=font(ARIAL_BOLD, 35), fill=COLORS["deep_ink"] + (245,))
            draw.text((x1 + 138, y1 + 82), "proteger", font=font(ARIAL, 26), fill=COLORS["stone"] + (225,))

        chip_y = panel_y1 + 716
        features = [
            ("Tempo de Uso", "Permissões nativas do iPhone.", draw_screen_time_icon),
            ("Leitura com IA", "Três trechos com explicação.", draw_book_icon),
            ("Cadeado aberto", "Libera por 30 minutos.", draw_return_icon),
        ]
        for label, detail, icon_drawer in features:
            draw.rounded_rectangle((panel_x1 + 64, chip_y, panel_x2 - 64, chip_y + 210), radius=40, fill=(5, 10, 11, 214), outline=accent + (108,), width=2)
            icon_drawer(draw, (panel_x1 + 104, chip_y + 48, panel_x1 + 218, chip_y + 162))
            draw.text((panel_x1 + 252, chip_y + 48), label, font=font(GEORGIA_BOLD, 46), fill=COLORS["ivory"] + (255,))
            draw_wrapped(draw, detail, (panel_x1 + 254, chip_y + 110), font(ARIAL, 32), COLORS["soft_text"] + (255,), 720, 10)
            chip_y += 260

    out = card.convert("RGB")
    out.save(APP_STORE / filename, quality=95)
    out.save(PUBLIC_APP_STORE / filename, quality=95)


def make_app_store_cards() -> None:
    visual = Image.open(ASSETS / "limiar-threshold-visual.png")
    dashboard = ASSETS / "limiar-dashboard-marketing.png"
    onboarding = ROOT / "preview" / "limiar-onboarding.png"
    cards = [
        (
            "01-pausa-antes-do-impulso.png",
            "Foco com sentido",
            "Uma pausa antes de voltar para as distrações.",
            "Apps protegidos aparecem pelos ícones, sem nomes, horários ou descrições de uso.",
            onboarding,
            COLORS["sage"],
        ),
        (
            "02-leitura-com-proposito.png",
            "Seu limiar",
            "Três trechos para uma pausa real.",
            "Cada trecho vem com texto, explicação espiritual e botão próprio para salvar.",
            dashboard,
            COLORS["gold"],
        ),
        (
            "03-protecao-nativa.png",
            "Tempo de Uso",
            "Escolha os apps que precisam de um limiar.",
            "A proteção usa recursos nativos do iPhone e libera por 30 minutos após a leitura.",
            None,
            COLORS["sage"],
        ),
        (
            "04-tradicao-espiritual.png",
            "Leitura pessoal",
            "Uma linguagem espiritual que respeita sua tradição.",
            "Católica, evangélica, judaica ou espírita, com temas e livros que combinam com você.",
            onboarding,
            COLORS["gold"],
        ),
        (
            "05-retome-consciente.png",
            "Volte melhor",
            "Cadeado aberto, acesso liberado.",
            "Ao concluir a leitura, o botão muda de estado e os apps ficam livres por 30 minutos.",
            dashboard,
            COLORS["sage"],
        ),
    ]
    for item in cards:
        filename, kicker, headline, body, screenshot_path, accent = item
        make_card(filename, kicker, headline, body, screenshot_path, visual, accent)


def make_hero_exports() -> None:
    visual = Image.open(ASSETS / "limiar-threshold-visual.png")
    make_dashboard_mock(ASSETS / "limiar-dashboard-marketing.png", visual)
    cover_crop(visual, (2400, 1350)).save(SITE_ASSETS / "hero-wide.jpg", quality=92)
    cover_crop(visual, (1200, 1600)).save(SITE_ASSETS / "hero-portrait.jpg", quality=92)
    cover_crop(Image.open(ASSETS / "limiar-dashboard-marketing.png"), (720, 1558)).save(SITE_ASSETS / "app-dashboard.png")
    cover_crop(Image.open(ROOT / "preview" / "limiar-onboarding.png"), (720, 1558)).save(SITE_ASSETS / "app-onboarding.png")


def make_manifest(generated_visual: Path) -> None:
    manifest = {
        "brand": "Limiar",
        "positioning": "Jornada espiritual antes de liberar apps protegidos.",
        "source_imagegen_asset": str(GENERATED_FALLBACK),
        "workspace_visual": str(generated_visual.relative_to(ROOT)),
        "assets": {
            "campaign_base": [
                "marketing/assets/limiar-threshold-visual.png",
                "marketing/assets/limiar-dashboard-marketing.png",
            ],
            "logo": [
                "marketing/brand/logo-mark.svg",
                "marketing/brand/logo-lockup-dark.svg",
                "marketing/brand/logo-lockup-light.svg",
                "marketing/brand/logo-mark-1024.png",
                "marketing/brand/logo-lockup-dark.png",
                "marketing/brand/logo-lockup-light.png",
            ],
            "app_store_cards": sorted(str(p.relative_to(ROOT)) for p in APP_STORE.glob("*.png")),
            "landing_assets": sorted(str(p.relative_to(ROOT)) for p in SITE_ASSETS.glob("*")),
        },
        "colors": {
            "deep_ink": "#050A0B",
            "ivory": "#F0E9D8",
            "sage": "#B3CFB8",
            "gold": "#D49F6E",
            "soft_text": "#C0C2BA",
        },
    }
    (MARKETING / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")


def main() -> None:
    ensure_dirs()
    generated_visual = copy_generated_visual()
    make_logo_assets()
    make_hero_exports()
    make_app_store_cards()
    make_manifest(generated_visual)


if __name__ == "__main__":
    main()
