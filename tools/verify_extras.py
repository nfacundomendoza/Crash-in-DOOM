from pathlib import Path
import json,re,hashlib,zipfile
PROJECT=Path(__file__).resolve().parents[1]
log=(PROJECT/'verification/extras.log').read_text(errors='replace')
second=(PROJECT/'verification/map02.log').read_text(errors='replace')
save=(PROJECT/'verification/save-load.log').read_text(errors='replace')
checks={
 'map01_valid_crates':'placement=1 count=4 valid=4' in log,
 'map02_valid_crates':'placement=1 count=4 valid=4' in second,
 'native_player_hull_preserved':'hull=1' in log,
 'native_walls_block_moves':bool(re.search(r'walls=[1-9]',log)),
 'spin_breaks_crate':'spin_breaks_crate=1' in log,
 'crate_drops_mask':'crate_drops_mask=1' in log,
 'pickup_by_native_collision':'pickup=1 invulnerable=1 duration=700 damage_blocked=1' in log,
 'orbit_attached':'orbit=1' in log,
 'protection_expires':'expired=1 damage_restored=1 orphan_masks=0' in log,
 'higher_jump_and_flip':'jump_height=112.50 flip=1 landed=1' in log,
 'spin_sound_playing':'spin_sound=1' in log,
 'save_load_active_mask':'Game saved.' in save and 'Captured loaded-aku.png' in save,
 'no_script_errors':not any(e in log+second+save for e in ['Script error','VM execution aborted','Unknown sound','not found']),
}
package=PROJECT/'crash-in-doom.pk3'
with zipfile.ZipFile(package) as z:
    checks['test_fixture_not_shipped']=not any('ExtrasChecks' in z.read(n).decode('utf8','ignore') for n in z.namelist() if n.endswith('.zs'))
result={'passed':all(checks.values()),'checks':checks,'pk3_sha256':hashlib.sha256(package.read_bytes()).hexdigest(),
        'limits':'MAP01 gameplay tests and MAP02 placement smoke test; not a full campaign playthrough.'}
(PROJECT/'verification/extras-result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
assert result['passed']
