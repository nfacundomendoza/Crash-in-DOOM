"""Report native-engine observations without claiming a complete playthrough."""
from pathlib import Path
import re,json,hashlib,zipfile
ROOT=Path(__file__).resolve().parents[1]
log=(ROOT/'verification/verified-final.log').read_text(errors='replace')
states=[tuple(map(float,m)) for m in re.findall(r'CRASH_STATE tic=(\d+) x=([-\d.]+) y=([-\d.]+) z=([-\d.]+) floor=([-\d.]+) vz=([-\d.]+) spin=(\d+)',log)]
checks={
 'original_doom_collision_hull': 'hull=1' in log,
 'native_walls_block_proposed_moves': bool(re.search(r'walls=([1-9]\d*)',log)),
 'spin_damages_visible_imp':'spin_damage=1 before=60 after=15' in log,
 'wall_blocks_spin_damage':'wall_protects=1 before=60 after=60' in log,
 'jump_has_upward_velocity':any(s[5]>0 and s[3]>s[4] for s in states),
 'landed_after_jump':any(s[0]>170 and abs(s[3]-s[4])<.1 and s[5]==0 for s in states),
 'spin_key_activates_animation':any(s[6]>0 for s in states),
 'no_script_runtime_errors':not any(s in log for s in ('VM execution aborted','Script error')),
}
pkg=ROOT/'crash-in-doom.pk3'
with zipfile.ZipFile(pkg) as z:
    checks['verification_actor_not_shipped']=not any('CrashChecks' in z.read(n).decode('utf8','ignore') for n in z.namelist() if n.endswith('.zs'))
result={'passed':all(checks.values()),'checks':checks,'map':'Doom II MAP01 Entryway',
 'pk3_sha256':hashlib.sha256(pkg.read_bytes()).hexdigest(),
 'limits':'Native engine tests on MAP01, not a complete playthrough or all maps.'}
(ROOT/'verification/result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
assert result['passed']

