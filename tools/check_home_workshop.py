"""Source-level integration checks; not a replacement for native gameplay tests."""
from pathlib import Path
import hashlib
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WorkshopIntegration(unittest.TestCase):
    def text(self, path):
        return (ROOT / path).read_text(encoding="utf-8")

    def test_original_home_retained(self):
        self.assertEqual(hashlib.sha256((ROOT / "game/world/home_territory.tscn").read_bytes()).hexdigest(),
                         "383ef8004ca41c84c084801f2ddb4a57f1730f66206f58cf32be7c3e1f2fb5c0")

    def test_current_authority_retained(self):
        self.assertIn('extends "res://youth/brawl_state.gd"', self.text("game/workshops/workshop_state.gd"))
        self.assertIn('extends "res://presentation/art_chapter.gd"', self.text("game/workshops/home_workshop_chapter.gd"))
        self.assertIn('super.advance()', self.text("game/workshops/workshop_state.gd"))

    def test_no_old_town_dependency(self):
        for p in (ROOT / "game/workshops").glob("*.gd"):
            for forbidden in ('town_state.gd', 'remount_state.gd', 'town_chapter.gd', 'HTTPRequest', 'Timer.new'):
                self.assertNotIn(forbidden, p.read_text())

    def test_reducer_is_code_selected(self):
        source = self.text("game/workshops/workshop_state.gd")
        self.assertIn('Craft.validate(value,tick)', source)
        self.assertIn('Economy.replay(events,Craft.apply)', source)
        self.assertNotRegex(source, r'(?<![A-Za-z_])load\s*\(')
        self.assertIn('_ledger_apply', self.text("game/misl/service_state.gd"))

    def test_not_old_town_save(self):
        self.assertIn('home-courtyard-smith.v2', self.text("game/workshops/workshop_rules.gd"))
        self.assertIn('1792-home-workshop-v2.json', self.text("game/workshops/workshop_state.gd"))

    def test_presentation_not_another_factory(self):
        text = self.text("game/workshops/workshop_world.gd")
        for forbidden in ('_physics_process', 'Timer.new', 'model.restore', 'model.operate', 'model._state', 'HTTPRequest'):
            self.assertNotIn(forbidden, text)
        self.assertIn('kit.sample(tick)', text)
        self.assertIn('tick==last_tick+1', text)

    def test_existing_capture_profile_kept(self):
        source = self.text("tools/capture_home_art.py")
        self.assertIn('default="home"', source)
        self.assertIn('exist_ok=False', source)
        self.assertIn('test_home_workshop.gd', source)
        self.assertIn('journey_sha256', source)

    def test_renderer_requires_executed_journey(self):
        source = self.text("game/tests/render_home_workshop.gd")
        self.assertIn('source_content_sha256', source)
        self.assertIn('home-workshop-journey.json', source)
        self.assertIn('_candidate_error', source)
        self.assertNotIn('Fixture.complete', source)


if __name__ == "__main__":
    unittest.main(verbosity=2)
