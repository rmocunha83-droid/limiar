#!/usr/bin/env python3
"""Valida o catálogo de trechos (Limiar/Resources/passages.json).

Checa: JSON válido, campos obrigatórios, enums válidos, IDs e referências
únicos por tradição, coerência livro↔seção, regras de cânon por tradição e
tamanho dos textos. Sai com código 1 se houver erro (uso em CI).
"""
import json
import sys
import collections
from pathlib import Path

CATALOG = Path(__file__).resolve().parent.parent / "Limiar" / "Resources" / "passages.json"

TRADITIONS = {"catholic", "protestant", "jewish", "spiritist"}
THEMES = {
    "faith", "hope", "forgiveness", "discipline", "wisdom", "family", "work",
    "anxiety", "presence", "purpose", "gospelOfJesus", "innerReform", "charity",
    "prayer", "patience", "spiritualEvolution", "consolationHope",
    "moralApplication", "practiceGood", "prosperityWithPurpose", "financialBalance",
}
SECTIONS = {
    "gospels", "psalms", "proverbs", "paulineLetters", "prophets", "torah",
    "historicalBooks", "wisdomBooks", "deuterocanonical", "ketuvim",
    "ethicalWisdom", "sermonOnMount", "parablesOfJesus",
}
BOOKS = {
    "genesis", "exodus", "psalms", "proverbs", "isaiah", "matthew", "luke",
    "john", "romans", "corinthians", "revelation", "tobias", "wisdom",
    "sirach", "maccabees", "leviticus", "numbers", "deuteronomy",
    "mark", "job", "ecclesiastes", "songOfSongs", "galatians", "ephesians",
    "hebrews", "james", "peter", "jeremiah", "ezekiel", "daniel",
    "joshua", "judges", "ruth", "esther", "judith", "baruch",
}

# Seções aceitas por livro (inclui variações históricas do catálogo).
BOOK_SECTIONS = {
    "psalms": {"psalms", "ketuvim"},
    "proverbs": {"proverbs", "wisdomBooks", "ketuvim", "ethicalWisdom"},
    "isaiah": {"prophets"},
    "matthew": {"gospels", "sermonOnMount", "parablesOfJesus"},
    "luke": {"gospels", "parablesOfJesus"},
    "john": {"gospels", "parablesOfJesus"},
    "romans": {"paulineLetters"},
    "corinthians": {"paulineLetters"},
    "revelation": {"prophets"},
    "genesis": {"torah", "historicalBooks"},
    "exodus": {"torah", "historicalBooks"},
    "leviticus": {"torah"},
    "numbers": {"torah"},
    "deuteronomy": {"torah"},
    "tobias": {"deuterocanonical", "historicalBooks"},
    "wisdom": {"deuterocanonical", "wisdomBooks"},
    "sirach": {"deuterocanonical", "wisdomBooks"},
    "maccabees": {"deuterocanonical", "historicalBooks"},
    "mark": {"gospels", "parablesOfJesus"},
    "job": {"wisdomBooks", "ketuvim"},
    "ecclesiastes": {"wisdomBooks", "ketuvim", "ethicalWisdom", "proverbs"},
    "songOfSongs": {"wisdomBooks", "ketuvim"},
    "galatians": {"paulineLetters"},
    "ephesians": {"paulineLetters"},
    "hebrews": {"paulineLetters"},
    "james": {"paulineLetters"},
    "peter": {"paulineLetters"},
    "jeremiah": {"prophets"},
    "ezekiel": {"prophets"},
    "daniel": {"prophets", "ketuvim"},
    "joshua": {"historicalBooks", "prophets"},
    "judges": {"historicalBooks", "prophets"},
    "ruth": {"historicalBooks", "ketuvim"},
    "esther": {"historicalBooks", "ketuvim"},
    "judith": {"deuterocanonical", "historicalBooks"},
    "baruch": {"deuterocanonical", "prophets"},
}

NEW_TESTAMENT_BOOKS = {"matthew", "mark", "luke", "john", "romans", "corinthians", "revelation", "galatians", "ephesians", "hebrews", "james", "peter"}
DEUTEROCANONICAL_BOOKS = {"tobias", "wisdom", "sirach", "maccabees", "judith", "baruch"}


def main() -> int:
    errors = []
    warnings = []

    try:
        entries = json.loads(CATALOG.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        print(f"ERRO: não foi possível ler {CATALOG}: {exc}")
        return 1

    if not isinstance(entries, list) or not entries:
        print("ERRO: o catálogo deve ser uma lista não vazia")
        return 1

    seen_ids = set()
    seen_refs = set()
    counts = collections.Counter()

    for index, entry in enumerate(entries):
        where = f"[{index}] id={entry.get('id', '?')}"

        for field in ("id", "tradition", "title", "reference", "text", "estimatedMinutes", "theme", "section", "book"):
            if field not in entry:
                errors.append(f"{where}: campo ausente '{field}'")

        tradition = entry.get("tradition")
        book = entry.get("book")
        section = entry.get("section")
        theme = entry.get("theme")

        if tradition not in TRADITIONS:
            errors.append(f"{where}: tradition inválida '{tradition}'")
        if theme not in THEMES:
            errors.append(f"{where}: theme inválido '{theme}'")
        if section not in SECTIONS:
            errors.append(f"{where}: section inválida '{section}'")
        if book not in BOOKS:
            errors.append(f"{where}: book inválido '{book}'")

        if book in BOOK_SECTIONS and section not in BOOK_SECTIONS[book]:
            errors.append(f"{where}: seção '{section}' incoerente com o livro '{book}'")

        if tradition == "jewish" and book in NEW_TESTAMENT_BOOKS:
            errors.append(f"{where}: tradição judaica com livro do Novo Testamento '{book}'")
        if tradition == "jewish" and book in DEUTEROCANONICAL_BOOKS:
            errors.append(f"{where}: tradição judaica com livro deuterocanônico '{book}'")
        if tradition == "protestant" and book in DEUTEROCANONICAL_BOOKS:
            errors.append(f"{where}: tradição evangélica com livro deuterocanônico '{book}'")

        entry_id = entry.get("id", "")
        if entry_id in seen_ids:
            errors.append(f"{where}: id duplicado")
        seen_ids.add(entry_id)

        ref_key = (tradition, entry.get("reference", "").strip().lower())
        if ref_key in seen_refs:
            errors.append(f"{where}: referência duplicada na tradição ({entry.get('reference')})")
        seen_refs.add(ref_key)

        text = entry.get("text", "")
        word_count = len(text.split())
        if word_count < 6:
            errors.append(f"{where}: texto curto demais ({word_count} palavras)")
        elif word_count > 70:
            warnings.append(f"{where}: texto longo ({word_count} palavras)")

        if entry.get("estimatedMinutes") != 5:
            warnings.append(f"{where}: estimatedMinutes != 5")

        counts[(tradition, book)] += 1

    print(f"Catálogo: {len(entries)} trechos")
    by_tradition = collections.Counter(t for (t, _b) in counts.elements())
    for tradition in sorted(by_tradition):
        print(f"  {tradition}: {by_tradition[tradition]}")
        books = {b: c for (t, b), c in counts.items() if t == tradition}
        for book_name in sorted(books):
            marker = " ⚠ pouco conteúdo" if books[book_name] < 5 else ""
            print(f"    {book_name:12s} {books[book_name]:3d}{marker}")

    for warning in warnings:
        print(f"AVISO: {warning}")
    for error in errors:
        print(f"ERRO: {error}")

    if errors:
        print(f"\n{len(errors)} erro(s).")
        return 1
    print("\nOK — catálogo válido.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
