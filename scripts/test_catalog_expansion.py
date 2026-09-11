import collections
import copy
import hashlib
import json
import unittest

import expand_passages as expansion


class CatalogExpansionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads(expansion.CATALOG.read_text(encoding="utf-8"))
        cls.legacy = [e for e in cls.catalog if not e["id"].startswith(expansion.PREFIX)]
        cls.added = [e for e in cls.catalog if e["id"].startswith(expansion.PREFIX)]

    def test_existing_entries_remain_identical_and_in_order(self):
        encoded = json.dumps(self.legacy, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
        self.assertEqual(len(self.legacy), 977)
        self.assertEqual(hashlib.sha256(encoded).hexdigest(),
                         "9666df0151e997ba7f7bcee229df63dd88408a645c7e0bbe4f363cbff9d1618a")
        self.assertEqual(self.catalog[:977], self.legacy)

    def test_balanced_expansion_and_stable_reproduction(self):
        self.assertEqual(expansion.validate_expansion(self.catalog), 823)
        self.assertEqual(collections.Counter(e["tradition"] for e in self.catalog),
                         dict.fromkeys(["catholic", "protestant", "jewish", "spiritist"], 450))
        self.assertEqual(len({e["id"] for e in self.catalog}), 1800)

    def test_no_new_verse_overlap_even_with_legacy_punctuation(self):
        occupied = collections.defaultdict(list)
        for entry in self.legacy:
            ref = expansion.reference_parts(entry["reference"])
            if ref:
                occupied[entry["tradition"]].append(ref)
        for entry in self.added:
            ref = expansion.reference_parts(entry["reference"])
            self.assertIsNotNone(ref)
            self.assertFalse(any(expansion.overlaps(ref, old) for old in occupied[entry["tradition"]]), entry["id"])
            occupied[entry["tradition"]].append(ref)
        old = expansion.reference_parts("Tehillim / Salmo 121")
        new = expansion.reference_parts("Salmo 121:2-3 · BLIVRE")
        self.assertTrue(expansion.overlaps(old, new))
        self.assertEqual(expansion.reference_parts("Mateus 5, 8-9"),
                         expansion.reference_parts("Mateus 5:8-9 · BLIVRE"))

    def test_book_and_tradition_match_canonical_reference(self):
        for entry in self.added:
            ref = expansion.reference_parts(entry["reference"])
            book, _, _, traditions = expansion.BOOKS[ref[0]]
            self.assertEqual(entry["book"], book)
            self.assertIn(entry["tradition"], traditions)
            if entry["tradition"] == "jewish":
                self.assertNotIn(ref[0], {"MAT", "MRK", "LUK", "JHN", "ROM", "1CO", "2CO", "JAS", "1PE", "2PE"})

    def test_source_tampering_is_rejected(self):
        changed = copy.deepcopy(self.catalog)
        changed[-1]["text"] += " Conteúdo inventado."
        with self.assertRaises(ValueError):
            expansion.validate_expansion(changed)

    def test_reference_tampering_is_rejected(self):
        changed = copy.deepcopy(self.catalog)
        changed[-1]["reference"] = "João 99:1 · BLIVRE"
        with self.assertRaises(ValueError):
            expansion.validate_expansion(changed)

    def test_every_new_item_has_attribution_and_no_source_markup(self):
        for entry in self.added:
            self.assertTrue(entry["reference"].endswith(" · BLIVRE"))
            self.assertEqual(entry["source"]["credit"], expansion.CREDIT)
            self.assertNotRegex(entry["text"], r"[\[\]<>\\]")


if __name__ == "__main__":
    unittest.main()
