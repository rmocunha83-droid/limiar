#!/usr/bin/env python3
"""Append curated, source-verified passages. No network or runtime dependency."""
import argparse
import collections
import hashlib
import json
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Limiar/Resources/passages.json"
SOURCE = ROOT / "scripts/catalog-sources/bliv-n4_vpl-2018.2.0.zip"
CURATION = ROOT / "scripts/catalog-sources/selection.tsv"
SOURCE_SHA256 = "676e8d1efea3f576f1ae716fc0b3b7b37085c3d59c5e72daaea409ae083968e5"
PREFIX = "blivre-2018-"
CREDIT = "Bíblia Livre (BLIVRE), fevereiro de 2018. Copyright © Diego Santos, Mario Sérgio e Marco Teles. CC BY 3.0 BR. https://sites.google.com/site/biblialivre/ https://creativecommons.org/licenses/by/3.0/br/"
# Source code, app book, Portuguese name, ordinary section, eligible traditions.
BOOKS = {}
for line in """
GEN|genesis|Gênesis|torah|catholic,protestant,jewish
EXO|exodus|Êxodo|torah|catholic,protestant,jewish
LEV|leviticus|Levítico|torah|jewish
NUM|numbers|Números|torah|jewish
DEU|deuteronomy|Deuteronômio|torah|jewish
JOS|joshua|Josué|historicalBooks|catholic,protestant,jewish
JDG|judges|Juízes|historicalBooks|catholic,protestant,jewish
RUT|ruth|Rute|historicalBooks|protestant,jewish
EST|esther|Ester|historicalBooks|protestant,jewish
JOB|job|Jó|wisdomBooks|catholic,protestant,jewish,spiritist
PSA|psalms|Salmo|psalms|catholic,protestant,jewish,spiritist
PRO|proverbs|Provérbios|proverbs|catholic,protestant,jewish,spiritist
ECC|ecclesiastes|Eclesiastes|wisdomBooks|catholic,protestant,jewish,spiritist
SNG|songOfSongs|Cantares|wisdomBooks|protestant
ISA|isaiah|Isaías|prophets|catholic,protestant,jewish
JER|jeremiah|Jeremias|prophets|catholic,protestant,jewish
EZK|ezekiel|Ezequiel|prophets|catholic,protestant,jewish
DAN|daniel|Daniel|prophets|catholic,protestant,jewish
MAT|matthew|Mateus|gospels|catholic,protestant,spiritist
MRK|mark|Marcos|gospels|catholic,protestant,spiritist
LUK|luke|Lucas|gospels|catholic,protestant,spiritist
JHN|john|João|gospels|catholic,protestant,spiritist
ROM|romans|Romanos|paulineLetters|catholic,protestant,spiritist
1CO|corinthians|1 Coríntios|paulineLetters|catholic,protestant,spiritist
2CO|corinthians|2 Coríntios|paulineLetters|catholic,protestant,spiritist
GAL|galatians|Gálatas|paulineLetters|catholic,protestant
EPH|ephesians|Efésios|paulineLetters|catholic,protestant
HEB|hebrews|Hebreus|paulineLetters|protestant
JAS|james|Tiago|paulineLetters|catholic,protestant,spiritist
1PE|peter|1 Pedro|paulineLetters|catholic,protestant,spiritist
2PE|peter|2 Pedro|paulineLetters|catholic,protestant,spiritist
REV|revelation|Apocalipse|prophets|protestant
""".strip().splitlines():
    code, book, title, section, traditions = line.split("|")
    BOOKS[code] = (book, title, section, traditions.split(","))

SPIRITIST_THEMES = {
    "faith": "gospelOfJesus", "hope": "consolationHope", "anxiety": "consolationHope",
    "discipline": "innerReform", "wisdom": "moralApplication", "presence": "prayer",
    "purpose": "spiritualEvolution", "work": "practiceGood",
    "financialBalance": "moralApplication", "prosperityWithPurpose": "moralApplication",
}


def read_source():
    if hashlib.sha256(SOURCE.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise ValueError("Source archive checksum mismatch")
    with zipfile.ZipFile(SOURCE) as archive:
        lines = archive.read("bliv-n4_vpl.txt").decode("utf-8-sig").splitlines()
    verses = {}
    for line in lines:
        match = re.fullmatch(r"(\w+) (\d+):(\d+) (.+)", line)
        if not match:
            raise ValueError(f"Unrecognized source line: {line[:80]}")
        code, chapter, verse, text = match.groups()
        code = {"MAR": "MRK", "JOH": "JHN", "EZE": "EZK", "JAM": "JAS", "SOL": "SNG"}.get(code, code)
        key = (code, int(chapter), int(verse))
        if key in verses:
            raise ValueError(f"Duplicate source verse {key}")
        verses[key] = text.strip()
    return verses


def reference_parts(reference):
    # References without verses reserve the entire chapter, conservatively.
    clean = reference.split(" · ")[0].split(" / ")[-1]
    match = re.fullmatch(r"(.+?) (\d+)(?:[:,]\s*(\d+)(?:[-–](\d+))?)?", clean)
    if not match:
        return None
    name, chapter, start, end = match.groups()
    code = next((c for c, (_, title, _, _) in BOOKS.items() if title == name), None)
    if code is None:
        return None
    return code, int(chapter), int(start or 1), int(end or start or 1000)


def overlaps(a, b):
    return a[:2] == b[:2] and a[2] <= b[3] and b[2] <= a[3]


def source_text(verses, ref):
    code, chapter, start, end = ref
    parts = []
    for v in range(start, end + 1):
        text = verses[code, chapter, v]
        if code == "PSA" and chapter == 119:
            text = re.sub(r"^\[[^\]]+\]\s*:\s*", "", text)
        # Square brackets mark translator-supplied words, retained in full.
        text = text.replace("[", "").replace("]", "")
        if code == "PSA":
            text = re.sub(r"^Cântico dos degraus:\s*", "", text)
        text = re.sub(r"\s+([,;:.!?])", r"\1", text)
        text = re.sub(r"([?!])(?=[A-Za-zÀ-ÿ])", r"\1 ", text)
        parts.append(text)
    return " ".join(" ".join(parts).split())


def selections():
    for line in CURATION.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        ref, theme, title = line.split("\t")
        match = re.fullmatch(r"(\w+) (\d+):(\d+)(?:-(\d+))?", ref)
        if not match:
            raise ValueError(f"Invalid curated reference {ref}")
        code, chapter, start, end = match.groups()
        yield (code, int(chapter), int(start), int(end or start)), theme, title


def section_for(code, chapter, tradition):
    book, _, section, _ = BOOKS[code]
    if tradition == "jewish":
        if code in {"JOS", "JDG"}:
            return "prophets"
        if code in {"RUT", "EST", "DAN"}:
            return "ketuvim"
    if tradition == "spiritist":
        if code == "MAT" and 5 <= chapter <= 7:
            return "sermonOnMount"
        if code in {"JOB", "ECC"}:
            # Match the existing wisdom category's section filter.
            return "proverbs" if code == "ECC" else section
    return section


def generate(baseline):
    verses = read_source()
    occupied = collections.defaultdict(list)
    texts = collections.defaultdict(set)
    for item in baseline:
        ref = reference_parts(item["reference"])
        if ref:
            occupied[item["tradition"]].append(ref)
        texts[item["tradition"]].add(" ".join(item["text"].casefold().split()))
    result = []
    skipped = collections.Counter()
    for ref, theme, title in selections():
        code, chapter, start, end = ref
        if end < start:
            raise ValueError(f"Reversed range {ref}")
        text = source_text(verses, ref)
        if not 6 <= len(text.split()) <= 100:
            raise ValueError(f"Curated passage must have 6-100 words: {ref} ({len(text.split())})")
        if any(marker in text for marker in ["<", ">", "\\", "["]):
            raise ValueError(f"Unreviewed markup in {ref}")
        book, name, _, traditions = BOOKS[code]
        for tradition in traditions:
            if any(overlaps(ref, used) for used in occupied[tradition]):
                skipped[tradition] += 1
                continue
            normalized = " ".join(text.casefold().split())
            if normalized in texts[tradition]:
                skipped[tradition] += 1
                continue
            verse_label = str(start) if start == end else f"{start}-{end}"
            result.append({
                "id": f"{PREFIX}{tradition}-{code.lower()}-{chapter}-{start}-{end}",
                "tradition": tradition, "title": title,
                "reference": f"{name} {chapter}:{verse_label} · BLIVRE",
                "text": text, "estimatedMinutes": 5,
                "theme": ("consolationHope" if theme == "faith" and code in {"PSA", "PRO", "JOB", "ECC"}
                          else SPIRITIST_THEMES.get(theme, theme)) if tradition == "spiritist" else theme,
                "section": section_for(code, chapter, tradition), "book": book,
                "source": {"edition": "BLIVRE-2018.2.0-n4", "reference": f"{code} {chapter}:{verse_label}",
                           "credit": CREDIT, "changes": "Versículos unidos por espaço; colchetes tipográficos removidos, preservando as palavras; títulos alfabéticos do Salmo 119 e título Cântico dos degraus omitidos; espaços de pontuação normalizados."},
            })
            occupied[tradition].append(ref)
            texts[tradition].add(normalized)
    # Balance the first batch by tradition, then strengthen thin books/themes.
    chosen = []
    for tradition in ("catholic", "protestant", "jewish", "spiritist"):
        existing = [e for e in baseline if e["tradition"] == tradition]
        book_counts = collections.Counter(e["book"] for e in existing)
        theme_counts = collections.Counter(e["theme"] for e in existing)
        pool = [e for e in result if e["tradition"] == tradition]
        default_books = {
            "catholic": {"matthew", "mark", "luke", "john", "psalms", "proverbs", "job", "ecclesiastes", "wisdom", "sirach"},
            "protestant": {"matthew", "mark", "luke", "john", "psalms", "proverbs", "job", "ecclesiastes", "songOfSongs"},
            "jewish": {"genesis", "exodus", "leviticus", "numbers", "deuteronomy", "psalms", "proverbs", "ecclesiastes", "job"},
            "spiritist": {"matthew", "mark", "luke", "john", "psalms"},
        }[tradition]
        default_sections = {
            "catholic": {"gospels", "psalms", "proverbs", "wisdomBooks"},
            "protestant": {"gospels", "psalms", "proverbs", "wisdomBooks"},
            "jewish": {"torah", "psalms", "proverbs", "wisdomBooks"},
            "spiritist": {"gospels", "sermonOnMount", "parablesOfJesus", "psalms"},
        }[tradition]
        def is_default(e):
            return e["book"] in default_books and e["section"] in default_sections
        default_count = sum(is_default(e) for e in existing)
        for _ in range(max(0, 450 - len(existing))):
            if not pool:
                raise ValueError(f"Insufficient curated candidates for {tradition}")
            eligible = [e for e in pool if is_default(e)] if default_count < 180 else pool
            entry = min(eligible, key=lambda e: (book_counts[e["book"]], theme_counts[e["theme"]], e["id"]))
            chosen.append(entry)
            pool.remove(entry)
            book_counts[entry["book"]] += 1
            theme_counts[entry["theme"]] += 1
            default_count += is_default(entry)
    return chosen, skipped


def validate_expansion(entries):
    baseline = [e for e in entries if not e["id"].startswith(PREFIX)]
    expected, _ = generate(baseline)
    actual = [e for e in entries if e["id"].startswith(PREFIX)]
    if actual != expected:
        raise ValueError("Expansion differs from curated source: regenerate or review selection.tsv")
    return len(actual)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    baseline = [e for e in catalog if not e["id"].startswith(PREFIX)]
    additions, skipped = generate(baseline)
    output = baseline + additions
    if args.write:
        CATALOG.write_text(json.dumps(output, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(json.dumps({"before": len(baseline), "added": len(additions), "total": len(output),
                      "addedByTradition": collections.Counter(e["tradition"] for e in additions),
                      "overlappingCandidatesSkipped": skipped}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
