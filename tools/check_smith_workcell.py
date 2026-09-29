"""Validate the source capsule without loading a game, model, NET or container."""
import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
PROFILE=ROOT/'tools/net/smith-workcell.profile.json'


def check():
    p=json.loads(PROFILE.read_text())
    assert p['schema']=='ciw.workcell-title-profile.v1' and p['recipe']=='1792.smith.v1'
    assert p['writable']==['workshops/workshop_world.gd','workshops/workshop_rules.gd']
    assert len(p['sources'])==13
    for name,item in p['sources'].items():
        assert '..' not in Path(name).parts and not Path(name).is_absolute()
        raw=(ROOT/'game'/name).read_bytes()
        assert item=={'sha256':'sha256:'+hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}, name
        for dependency in re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)',raw.decode()):
            assert dependency in p['sources'] or dependency=='smith.scn', (name,dependency)
    assert (ROOT/'game/workcells/NOTICE.txt').read_bytes()==(ROOT/'LICENSE').read_bytes()
    return p


class CapsuleTests(unittest.TestCase):
    def test_scoped_sources_and_original_licence(self):self.assertEqual(len(check()['sources']),13)
    def test_no_live_launch_or_save_changes(self):
        text=(ROOT/'game/project.godot').read_text()
        self.assertIn('run/main_scene="res://ui/main_menu.tscn"',text)
        for name in ['baked_smith.gd','smith_scene.gd','smith_probe.gd']:
            self.assertNotIn('user://',(ROOT/'game/workcells'/name).read_text())
    def test_rules_are_reused_not_copied(self):
        text=(ROOT/'game/workcells/smith_scene.gd').read_text()
        self.assertIn('Craft.apply(',text)
        self.assertNotIn('ledger.stock.tools+=',text)
        self.assertIn('extends "res://workshops/workshop_world.gd"',(ROOT/'game/workcells/baked_smith.gd').read_text())


if __name__=='__main__':unittest.main()
