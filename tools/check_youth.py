"""Verify required youth stories and honest runtime-admission metadata."""
from __future__ import annotations
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / 'game/youth/story_catalogue.json').read_text(encoding='utf-8'))
REQUIRED = set('bhangi_market_brawl hashmat_ladewali sodhran_command throne_lahore_pardon regency_escape ammunition_rebellion river_races end_regency boar_hunt nihang_camp bazaar_revelry afghan_raiders pocket_money_companions captured_falcon unwritten_king sodhran_naming ancestral_mare jhang_night_raids gujranwala_skirmishes palace_purge maan_singh_lethal kasur_night raj_kaur_mystery ramnagar_cavalry brick_kilns hound_confrontation bazaar_arrest sialkot_tribute'.split())

class YouthCatalogueTests(unittest.TestCase):
    def test_complete_required_set(self):
        self.assertEqual({s['id'] for s in DATA['stories']}, REQUIRED)
        self.assertEqual(len(DATA['stories']), 28)
    def test_every_entry_requires_play(self):
        self.assertTrue(all(s['required_playable'] is True for s in DATA['stories']))
    def test_actions_completion_and_fallout(self):
        for story in DATA['stories']:
            for key in ('player_actions', 'completion', 'fallout'):
                self.assertGreater(len(story[key]), 8, (story['id'], key))
            self.assertIn(story['era_policy'], {'childhood','youth','late_youth','youth_adaptation','earlier_retrospective','later_retelling','ancestral_retelling'})
            self.assertTrue(story['dependencies'])
    def test_only_brawl_is_newly_playable(self):
        self.assertEqual([s['id'] for s in DATA['stories'] if s['implementation'] == 'playable_greybox'], ['bhangi_market_brawl'])
    def test_no_fake_launch_buttons(self):
        for story in DATA['stories']:
            self.assertEqual(story['runtime_entry'], 'home_market' if story['implementation']=='playable_greybox' else None)
    def test_sources_resolve(self):
        sources = {s['id'] for s in DATA['sources']}
        self.assertEqual(len(sources), len(DATA['sources']))
        for story in DATA['stories']:
            self.assertIn(story['source_id'], sources)
    def test_consultation_is_not_verification(self):
        for source in DATA['sources']:
            self.assertTrue(source['consulted'] and source['supports'])
            self.assertTrue(source['url'] is None or source['url'].startswith('https://'))
        for story in DATA['stories']:
            self.assertIn(story['evidence_status'], ['supplied_lore_unverified','source_attributed_details_unverified'])
    def test_variant_members_resolve(self):
        for group in DATA['variant_groups']:
            self.assertTrue(set(group['members']) <= REQUIRED)
            self.assertEqual(len(set(group['members'])), len(group['members']))
            self.assertTrue(group['rule'])
    def test_lethal_and_pardon_remain_separate(self):
        family = next(g for g in DATA['variant_groups'] if g['id']=='maan_singh_endings')
        self.assertEqual(set(family['members']), {'throne_lahore_pardon','maan_singh_lethal'})
    def test_existing_identity(self):
        self.assertEqual(DATA['actor_id'],'ranjit_singh')
        self.assertEqual(DATA['display_name'],'Buddh Singh')
    def test_seed_is_not_complete(self):
        seeds = {s['id'] for s in DATA['stories'] if s['implementation']=='existing_seed'}
        self.assertEqual(seeds, {'hashmat_ladewali','unwritten_king'})
    def test_runtime_files_exist(self):
        for file in ['brawl_chapter.gd','brawl_state.gd','brawl_rules.gd','catalogue.gd']:
            self.assertTrue((ROOT/'game/youth'/file).is_file())

if __name__ == '__main__':
    unittest.main()
