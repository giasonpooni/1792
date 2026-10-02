"""Contract/regression tests for deferred Fall of Empire authoring data.
Copyright (c) 2026 Cartesian Graphics. All rights reserved.
"""
from __future__ import annotations
import copy
import unittest
from fall_of_empire import MANIFEST, PLAN, WORLD, CatalogueError, load, validate
from world_atlas import loads

class ContractTests(unittest.TestCase):
    def setUp(self):
        self.data, self.plan, self.world = load(MANIFEST), load(PLAN), load(WORLD)

    def good(self):
        validate(self.data, self.plan, self.world)

    def bad(self):
        with self.assertRaises(CatalogueError):
            self.good()

    def test_valid_contract_does_not_mutate(self):
        before = copy.deepcopy((self.data, self.plan, self.world))
        self.good()
        self.assertEqual(before, (self.data, self.plan, self.world))

    def test_existing_world_and_31_campaigns_retained(self):
        self.good()
        self.assertEqual(len(self.plan['campaigns']), 31)
        self.assertEqual(len(self.world['places']), 41)
        self.assertEqual(self.plan['current_deliverable'], 'ranjit_childhood')

    def test_release_remains_disabled(self):
        self.data['production']['release_enabled'] = True
        self.bad()

    def test_claiming_playable_campaign_refused(self):
        self.data['production']['playable_campaign_ready'] = True
        self.bad()

    def test_false_is_not_zero(self):
        self.data['production']['release_enabled'] = 0
        self.bad()

    def test_base_game_priority_retained(self):
        self.plan['current_deliverable'] = 'fall_of_empire'
        self.bad()

    def test_no_unified_lineage_allegiance(self):
        self.data['policy']['lineage_determines_allegiance'] = True
        self.bad()

    def test_no_identity_merge_hypothesis(self):
        self.data['policy']['hypotheses_merge_identity'] = True
        self.bad()

    def test_both_perspectives_required(self):
        self.data['policy']['both_sides'] = False
        self.bad()

    def test_no_religious_figure_spawn(self):
        self.data['policy']['religious_figures_embodied'] = True
        self.bad()

    def test_no_site_interior(self):
        self.data['policy']['site_interiors'] = True
        self.bad()

    def test_policy_bool_is_not_number(self):
        self.data['policy']['both_sides'] = 1
        self.bad()

    def test_closing_in_1857_refused(self):
        self.data['closing_anchor'] = 'delhi_assault_1857_09_14'
        self.bad()

    def test_closing_in_1873_refused(self):
        self.data['story_window'] = [1839, 1874]
        self.bad()

    def test_retained_1873_epilogue_not_deleted_or_in_dlc(self):
        self.good()
        self.assertTrue(any(c['id'] == 'epilogue' for c in self.plan['campaigns']))
        link = next(c for c in self.data['deferred_links'] if c['year'] == 1873)
        self.assertIs(link['in_dlc'], False)

    def test_mentana_not_admitted_into_dlc(self):
        self.data['deferred_links'][0]['in_dlc'] = True
        self.bad()

    def test_missing_bar_module_refused(self):
        self.data['chapters'][5]['retained_modules'] = []
        self.bad()

    def test_cycle_refused(self):
        self.data['chapters'][0]['requires'] = ['settlement']
        self.bad()

    def test_missing_prerequisite_refused(self):
        self.data['chapters'][-1]['requires'] = ['absent']
        self.bad()

    def test_skipping_last_campaigns_refused(self):
        self.data['chapters'][-1]['requires'] = ['divided_1857']
        self.bad()

    def test_duplicate_event_refused(self):
        self.data['events'].append(copy.deepcopy(self.data['events'][0]))
        self.bad()

    def test_missing_event_refused(self):
        self.data['chapters'][0]['event_ids'] = ['unlocated']
        self.bad()

    def test_unshared_place_refused(self):
        self.data['chapters'][0]['place_refs'] = ['invented_delhi_copy']
        self.bad()

    def test_invalid_calendar_refused(self):
        self.data['events'][-1]['window'][0] = '1859-02-30'
        self.bad()

    def test_reversed_calendar_refused(self):
        self.data['events'][0]['window'].reverse()
        self.bad()

    def test_editorial_is_not_corroboration(self):
        self.data['events'][0]['sources'] = ['editorial']
        self.bad()

    def test_unknown_source_refused(self):
        self.data['claims'][0]['sources'] = ['unread-book']
        self.bad()

    def test_hypothesis_not_canonical(self):
        self.data['claims'][-2]['status'] = 'canonical'
        self.bad()

    def test_kharal_existing_id_not_duplicated(self):
        person = next(c for c in self.data['cast'] if c['id'] == 'ahmad_khan_kharal')
        person['id'] = 'rai_ahmad_khan_kharal'
        self.bad()

    def test_thakur_military_role_not_silently_promoted(self):
        person = next(c for c in self.data['cast'] if c['id'] == 'thakur_singh_sandhawalia')
        person['admission'] = 'candidate'
        self.bad()

    def test_religious_context_not_cast(self):
        person = next(c for c in self.data['cast'] if c['id'] == 'bhai_maharaj_singh')
        person['admission'] = 'candidate'
        self.bad()

    def test_settlement_retains_missing_people(self):
        self.data['ending']['preserves'].remove('missing_people')
        self.bad()

    def test_formal_peace_cannot_replace_local_conditions(self):
        self.data['ending']['requires'] = ['formal_peace_1859_07_08']
        self.bad()

    def test_fixture_roles_not_historical_cast(self):
        self.data['qualification']['roles'][0] = 'sarup_singh_jind'
        self.bad()

    def test_source_parser_rejects_duplicate_json_keys(self):
        with self.assertRaises(CatalogueError): loads('{"id":1,"id":2}')

    def test_source_parser_rejects_nonfinite(self):
        with self.assertRaises(CatalogueError): loads('{"x":NaN}')

if __name__ == '__main__':
    unittest.main(verbosity=2)
