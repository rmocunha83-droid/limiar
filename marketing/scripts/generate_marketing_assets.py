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
    for folder in (ASSETS, BRAND, APP_STORE, SITE_ASSETS):
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

    y = 450
    panel((x, y, 1092, y + 312))
    draw.text((x + 28, y + 26), "APP BLOQUEADO", font=font(ARIAL_BOLD, 27), fill=COLORS["gold"] + (255,))
    draw.rounded_rectangle((x + 28, y + 88, x + 142, y + 202), radius=24, fill=(179, 92, 146, 255))
    draw.text((x + 170, y + 82), "Instagram", font=font(GEORGIA, 62), fill=COLORS["ivory"] + (255,))
    draw.text((x + 172, y + 158), "Você abriu as 21:42", font=font(ARIAL, 34), fill=COLORS["soft_text"] + (255,))

    y += 398
    draw.text((x, y), "SEU LIMIAR", font=font(ARIAL_BOLD, 27), fill=COLORS["gold"] + (255,))
    y += 54
    draw_wrapped(draw, "O Senhor conduz", (x, y), font(GEORGIA, 78), COLORS["ivory"] + (255,), 940, 10)
    y += 120
    draw_wrapped(draw, "Uma pausa com trechos suficientes para atravessar com calma.", (x, y), font(ARIAL, 38), COLORS["soft_text"] + (255,), 920, 12)

    y += 150
    panel((x, y, 1092, y + 540))
    draw.text((x + 30, y + 30), "Salmo 23", font=font(ARIAL_BOLD, 31), fill=COLORS["gold"] + (255,))
    draw.text((930, y + 30), "5 min", font=font(ARIAL_BOLD, 31), fill=COLORS["gold"] + (255,))
    quote = "O Senhor é meu pastor: nada me faltará. Em verdes pastagens me faz repousar, para fontes tranquilas me conduz."
    draw_wrapped(draw, quote, (x + 30, y + 112), font(GEORGIA, 47), COLORS["ivory"] + (255,), 930, 16)
    draw_wrapped(draw, "A reflexão ajuda a aplicar o trecho ao momento, sem alterar o texto-base.", (x + 30, y + 384), font(ARIAL, 29), COLORS["soft_text"] + (255,), 900, 12)

    y += 612
    panel((x, y, 1092, y + 172))
    draw.text((x + 34, y + 38), "Ajustar apps do limiar", font=font(GEORGIA, 43), fill=COLORS["ivory"] + (255,))
    draw.text((x + 34, y + 96), "Escolha onde você quer criar um limiar", font=font(ARIAL, 30), fill=COLORS["soft_text"] + (255,))
    draw.text((1046, y + 64), "", font=font(ARIAL_BOLD, 62), fill=COLORS["sage"] + (255,))

    y += 230
    draw.rounded_rectangle((x, y, 1092, y + 204), radius=42, fill=COLORS["sage"] + (255,))
    draw.text((x + 52, y + 42), "Começar leitura", font=font(GEORGIA, 52), fill=COLORS["deep_ink"] + (255,))
    draw.text((x + 54, y + 108), "Atravesse com calma e retome em seguida", font=font(ARIAL, 30), fill=COLORS["deep_ink"] + (210,))
    draw.text((1010, y + 58), "", font=font(ARIAL_BOLD, 54), fill=COLORS["deep_ink"] + (255,))
    img.convert("RGB").save(path, quality=95)


def make_card(
    filename: str,
    kicker: str,
    headline: str,
    body: str,
    screenshot_path: Path | None,
    visual: Image.Image,
    accent: tuple[int, int, int],
    phone_side: str = "right",
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

    draw.text((88, 118), kicker.upper(), font=font(ARIAL_BOLD, 34), fill=COLORS["gold"] + (255,))
    y = draw_wrapped(draw, headline, (88, 190), font(GEORGIA_BOLD, 92), COLORS["ivory"] + (255,), 1020, 22)
    y = draw_wrapped(draw, body, (92, y + 34), font(ARIAL, 39), COLORS["soft_text"] + (255,), 920, 18)

    draw.rounded_rectangle((88, 2440, 1202, 2596), radius=46, fill=COLORS["sage"] + (238,))
    draw.text((138, 2484), "Limiar", font=font(GEORGIA_BOLD, 60), fill=COLORS["deep_ink"] + (255,))
    draw.text((400, 2504), "Pausa espiritual antes do impulso", font=font(ARIAL_BOLD, 33), fill=COLORS["deep_ink"] + (220,))

    if screenshot_path and screenshot_path.exists():
        framed = phone_frame(Image.open(screenshot_path), 1530)
        x = size[0] - framed.width - 72 if phone_side == "right" else 72
        if phone_side == "center":
            x = (size[0] - framed.width) // 2
        card.alpha_composite(framed, (x, 790))
    else:
        # Feature card with three quiet chips.
        chip_y = 790
        for label, detail in [
            ("Escolha os apps", "Use o seletor nativo do Tempo de Uso."),
            ("Leia com calma", "Trechos e reflexões de acordo com sua tradição."),
            ("Retome consciente", "Libere por um tempo e volte com presença."),
        ]:
            draw.rounded_rectangle((104, chip_y, 1186, chip_y + 300), radius=42, fill=(5, 10, 11, 196), outline=accent + (118,), width=2)
            draw.ellipse((144, chip_y + 72, 244, chip_y + 172), fill=accent + (255,))
            draw.text((292, chip_y + 64), label, font=font(GEORGIA_BOLD, 50), fill=COLORS["ivory"] + (255,))
            draw_wrapped(draw, detail, (294, chip_y + 138), font(ARIAL, 35), COLORS["soft_text"] + (255,), 760, 12)
            chip_y += 356

    card.convert("RGB").save(APP_STORE / filename, quality=95)


def make_app_store_cards() -> None:
    visual = Image.open(ASSETS / "limiar-threshold-visual.png")
    dashboard = ASSETS / "limiar-dashboard-marketing.png"
    onboarding = ROOT / "preview" / "limiar-onboarding.png"
    cards = [
        (
            "01-pausa-antes-do-impulso.png",
            "Foco com sentido",
            "Uma pausa antes de voltar para as distrações.",
            "O Limiar cria um espaço breve entre o impulso e o aplicativo bloqueado.",
            onboarding,
            COLORS["sage"],
            "right",
        ),
        (
            "02-leitura-com-proposito.png",
            "Seu limiar",
            "Leia alguns minutos e atravesse com calma.",
            "Trechos, reflexões e aplicações práticas ajudam você a retomar a atenção.",
            dashboard,
            COLORS["gold"],
            "right",
        ),
        (
            "03-protecao-nativa.png",
            "Tempo de Uso",
            "Escolha os apps que precisam de um limiar.",
            "O bloqueio usa recursos nativos do iPhone e fica sob seu controle.",
            None,
            COLORS["sage"],
            "center",
        ),
        (
            "04-tradicao-espiritual.png",
            "Leitura pessoal",
            "Uma linguagem espiritual que respeita sua tradição.",
            "Católica, evangélica, judaica ou espírita: você escolhe o tom da leitura.",
            onboarding,
            COLORS["gold"],
            "left",
        ),
        (
            "05-retome-consciente.png",
            "Volte melhor",
            "Depois da leitura, retome com mais presença.",
            "O objetivo não é punir o uso do celular. É devolver a escolha para você.",
            dashboard,
            COLORS["sage"],
            "left",
        ),
    ]
    for item in cards:
        filename, kicker, headline, body, screenshot_path, accent, phone_side = item
        make_card(filename, kicker, headline, body, screenshot_path, visual, accent, phone_side)


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
        "positioning": "Pausa espiritual antes de abrir apps que roubam atenção.",
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
