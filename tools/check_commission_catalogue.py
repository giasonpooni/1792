"""Check editorial officer contracts, without claiming executable historical chapters."""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]

class OfficerContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads((ROOT / 'game/commissions/officer_chapters.json').read_text())
        cls.officers = cls.data['officers']

    def test_unique_people(self):
        self.assertEqual(len({p['id'] for p in self.officers}), len(self.officers))

    def test_four_required_officers(self):
        self.assertEqual({p['id'] for p in self.officers}, {'jean_francois_allard', 'jean_baptiste_ventura', 'claude_auguste_court', 'paolo_avitabile'})

    def test_later_service_not_childhood(self):
        for person in self.officers:
            start, end = person['source_service_window']
            self.assertTrue(1792 < start <= end <= 1849)

    def test_no_fake_playable_chapters(self):
        for person in self.officers:
            self.assertIs(person['playable_chapter_required'], True)
            self.assertIs(person['playable_chapter_implemented'], False)

    def test_sources_resolve(self):
        ids = {source['id'] for source in self.data['sources']}
        for person in self.officers:
            self.assertTrue(person['source_ids'])
            self.assertLessEqual(set(person['source_ids']), ids)

    def test_economic_permission_not_body_ownership(self):
        for person in self.officers:
            self.assertEqual(person['paid_contract_grants'], ['agreed service only'])
            self.assertIn('sovereign treasury access', person['does_not_grant'])

    def test_no_automatic_army_upgrade(self):
        for person in self.officers:
            self.assertIn('troops', person['does_not_grant'])
            self.assertIn('global technology', person['does_not_grant'])

    def test_authored_pipeline_not_universal_history(self):
        for person in self.officers:
            self.assertIn('authored gameplay requirement', person['pipeline_evidence_status'])
            self.assertIn('officer consent', person['recruitment_pipeline'])

    def test_one_clock_and_treasury_contract(self):
        self.assertIn('one existing treasury', self.data['binding_rules']['cash'])
        self.assertIn('one active world clock', self.data['binding_rules']['clock'])

    def test_source_files_exist(self):
        for path in ('commission_rules.gd', 'commission_state.gd', 'commission_chapter.gd', 'officer_catalogue.gd'):
            self.assertTrue((ROOT / 'game/commissions' / path).is_file())

if __name__ == '__main__':
    unittest.main(verbosity=2)
