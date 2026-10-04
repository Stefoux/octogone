"""Tests des scripts de données : python -m unittest test_scripts (depuis data/scripts)."""
import unittest

from fetch_fighters import derive_from_record, division_key, wiki_division
from import_checklist import parse_card, parse_meta, parse_parallels
from rarity_rules import effect_for, odds_packs, parallel_rarity, series_rarity, stat_bonus


class ChecklistTests(unittest.TestCase):
    def test_parallels(self):
        p = parse_parallels("Refractor; X-Fractor (1 per Mega Box); Negative Refractor (1:3 Hobby); "
                            "Gold Refractor /50; Speckle Refractor #/299; SuperFractor 1/1.")
        self.assertEqual([x["nom"] for x in p],
                         ["Refractor", "X-Fractor", "Negative Refractor", "Gold Refractor", "Speckle Refractor",
                          "SuperFractor"])
        self.assertEqual([x["tirage"] for x in p], [None, None, None, 50, 299, 1])
        self.assertEqual(p[1]["cote"], "1 per Mega Box")

    def test_meta(self):
        m = parse_meta(" /10. 1:4,030 packs. Hobby exclusive.")
        self.assertEqual(m["tirage"], 10)
        self.assertEqual(m["cote"], "1:4,030 packs")
        self.assertEqual(m["exclusivite"], "Hobby exclusive")

    def test_cards(self):
        self.assertEqual(parse_card("1 Brad Katona RC", coded=False),
                         {"numero": "1", "nom_imprime": "Brad Katona", "mentions": ["RC"], "sous_titre": None})
        c = parse_card('AKA-11 Jon Jones - "Bones"', coded=True)
        self.assertEqual((c["numero"], c["nom_imprime"], c["sous_titre"]), ("AKA-11", "Jon Jones", "Bones"))
        self.assertIsNone(parse_card("1954 Topps Checklist", coded=True))


class RarityTests(unittest.TestCase):
    def test_parallel_rarity(self):
        self.assertEqual(parallel_rarity(None), "peu_commune")
        self.assertEqual(parallel_rarity(299), "rare")
        self.assertEqual(parallel_rarity(50), "epique")
        self.assertEqual(parallel_rarity(10), "legendaire")
        self.assertEqual(parallel_rarity(5), "mythique")
        self.assertEqual(parallel_rarity(1), "mythique")

    def test_series_rarity(self):
        self.assertEqual(series_rarity({"type": "base"}), "commune")
        self.assertEqual(series_rarity({"type": "insert", "cote": "1:3 Hobby"}), "peu_commune")
        self.assertEqual(series_rarity({"type": "insert", "cote": "1:72 Hobby; 1:7 Breaker"}), "rare")
        self.assertEqual(series_rarity({"type": "insert", "cote": "1:1,442 Hobby"}), "legendaire")
        self.assertEqual(series_rarity({"type": "autographe", "cote": "1:3 Hobby"}), "epique")
        self.assertEqual(series_rarity({"type": "insert", "cote": "1:2,705", "notes": ["50 copies"]}), "legendaire")
        self.assertEqual(odds_packs("1:4,030 packs"), 4030)

    def test_effects_and_bonus(self):
        self.assertEqual(effect_for("Blue Wave Refractor"), ("wave", "#2F6BFF"))
        self.assertEqual(effect_for("SuperFractor")[0], "superfractor")
        self.assertEqual(effect_for("Gold Refractor"), ("refractor", "#E8B04A"))
        self.assertEqual([stat_bonus(r) for r in ("commune", "rare", "mythique")], [0, 2, 6])


class FighterTests(unittest.TestCase):
    def test_divisions(self):
        self.assertEqual(division_key("Poids plume Division", "M"), "plume")
        self.assertEqual(division_key("Light Heavyweight Division", "M"), "mi_lourds")
        self.assertEqual(division_key("Heavyweight Division", "M"), "lourds")
        self.assertEqual(division_key("Women's Bantamweight Division", "F"), "coq_f")
        self.assertEqual(wiki_division("Lightweight (2012) Featherweight (2013–present)", "M"), "plume")

    def test_record_derivation(self):
        fights = [
            {"resultat": "Loss", "record": "13–4", "adversaire": "B", "methode": "TKO (punches)",
             "evenement": "UFC Freedom 250", "date": "14 June 2026", "round": 2, "temps": "1:27", "notes": ""},
            {"resultat": "Win", "record": "13–3", "adversaire": "C", "methode": "Decision (unanimous)",
             "evenement": "UFC 300", "date": "13 April 2024", "round": 5, "temps": "5:00",
             "notes": "Defended the UFC Light Heavyweight Championship. Fight of the Night."},
            {"resultat": "Win", "record": "12–3", "adversaire": "D", "methode": "Submission (rear-naked choke)",
             "evenement": "Glory 1", "date": "2015", "round": 1, "temps": "2:00", "notes": ""},
        ]
        d = derive_from_record(fights)
        self.assertEqual(d["combats_ufc"], 2)
        self.assertEqual(d["victoires_decision_5_rounds"], 1)
        self.assertEqual(d["bonus_fotn"], 1)
        self.assertEqual(d["defaites_ko_record"], 1)
        self.assertEqual(d["titres"][0]["action"], "defended")
        self.assertEqual(d["technique_favorite"], {"technique": "rear-naked choke", "finitions": 1})
        self.assertEqual(d["combats_ufc_par_annee"], {"2024": 1, "2026": 1})
        self.assertEqual(d["palmares_tableau"]["victoires"], 2)


if __name__ == "__main__":
    unittest.main()
