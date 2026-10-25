#!/usr/bin/env python3
"""Prove renamed Linux builds open the legacy character and settings directory."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
engine = shutil.which(os.environ.get('GODOT_BIN', 'godot'))
if not engine:
    raise SystemExit('Set GODOT_BIN to the pinned Godot 4.5.1 executable')
probe = '''extends SceneTree
const Data=preload("res://scripts/data.gd")
func _initialize():
 if "--write" in OS.get_cmdline_user_args():
  var hero=Data.fresh("Warrior");hero.gold=517;hero.level=6
  assert(Data.write_save(hero));assert(Data.write_save(hero))
  var c=ConfigFile.new();c.set_value("graphics","quality","Balanced");assert(c.save("user://graphics.cfg")==OK)
 else:
  var hero=Data.read_save();assert(not hero.is_empty() and hero.gold==517 and hero.level==6)
  assert(FileAccess.file_exists("user://character.json.bak"))
  var c=ConfigFile.new();assert(c.load("user://graphics.cfg")==OK);assert(c.get_value("graphics","quality")=="Balanced")
 print("USERDIR="+OS.get_user_data_dir());print("RENAME PROBE PASS");quit()
'''
with tempfile.TemporaryDirectory(prefix='vyrnspire-rename-') as temporary:
    temp = Path(temporary)
    legacy = temp / 'legacy'
    (legacy / 'scripts').mkdir(parents=True)
    (legacy / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Runebound Godot"\n')
    shutil.copyfile(ROOT / 'scripts/data.gd', legacy / 'scripts/data.gd')
    fixture = temp / 'probe.gd'
    fixture.write_text(probe)
    env = {**os.environ, 'XDG_DATA_HOME': str(temp / 'data'), 'XDG_CONFIG_HOME': str(temp / 'config'), 'GODOT_SILENCE_ROOT_WARNING': '1'}
    directories = []
    for project, flags in [(legacy, ['--write']), (ROOT, [])]:
        result = subprocess.run([engine, '--headless', '--path', str(project), '--script', str(fixture), '--', *flags], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
        assert result.returncode == 0 and 'RENAME PROBE PASS' in result.stdout and 'ERROR:' not in result.stdout, result.stdout
        directories.append(re.search(r'^USERDIR=(.+)$', result.stdout, re.M)[1])
    assert directories[0] == directories[1], directories
print('PASS: legacy and VYRNSPIRE resolve the identical user directory; real character, backup and graphics settings retained')
