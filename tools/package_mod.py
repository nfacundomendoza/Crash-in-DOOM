from pathlib import Path
import json,zipfile
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];mod=ROOT/'mod'
assets=json.loads((ROOT/'source/assets.json').read_text())['animations']
codes={'idle':'CRID','walk':'CRWK','jump':'CRJP','fall':'CRFL','land':'CRLD','death':'CRDT','spin':'CRSP'}
codes.update({f'dance{i}':f'CDN{i}' for i in range(2,7)})
lines=['Model CrashPlayer','{','  Path "models/crash"','  Scale 0.9 0.9 0.9','  AngleOffset 180',
       '  Model 0 "crash.md3"','  Skin 0 "WillG.png"','  Model 1 "spin.md3"','  Skin 1 "WiBlG.png"']
for action,data in assets.items():
    i=data['model']
    for f in range(data['frames']):
        # One visible model at a time; others use an invalid frame to hide them.
        for other in range(2):
            lines.append(f'  FrameIndex {codes[action]} {chr(65+f)} {other} {f+data["first_frame"] if other==i else -1}')
lines.append('}')
for actor,model,skin,code in [('CrashAkuCrate','aku-crate','BD10G','AKBX'),('CrashAkuPickup','aku','WD10G','AKUP'),('CrashAkuOrbit','aku','WD10G','AKOR')]:
    lines.extend([f'Model {actor}','{','  Path "models/crash"','  Scale 1.0 1.0 1.0','  AngleOffset 180',f'  Model 0 "{model}.md3"',f'  Skin 0 "{skin}.png"',f'  FrameIndex {code} A 0 0','}'])
(mod/'modeldef.txt').write_text('\n'.join(lines)+'\n')
# GZDoom requires sprite frames even for models. Reuse transparent pixels of the
# converted original atlas as invisible placeholders; no new character art.
placeholder=Image.open(mod/'models/crash/WillG.png').crop((1016,1016,1024,1024))
for action,data in assets.items():
    for f in range(data['frames']):placeholder.save(mod/'sprites'/f'{codes[action]}{chr(65+f)}0.png')
for code in ['AKBX','AKUP','AKOR']:placeholder.save(mod/'sprites'/f'{code}A0.png')
with zipfile.ZipFile(ROOT/'crash-in-doom.pk3','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(mod.rglob('*')):
        if p.is_file():z.write(p,p.relative_to(mod).as_posix())
print('Packaged original Crash models and native Doom mod.')
