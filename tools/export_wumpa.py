"""Extract the original animated fruit and orange HUD numerals from GOOL."""
from pathlib import Path
import struct,json
import export_crash as e
sprites=e.PROJECT/'mod/sprites';graphics=e.PROJECT/'mod/graphics'
graphics.mkdir(exist_ok=True)
fruit=e.entries[e.byname['FruiC']][5]
for i in range(14):
    at=8+i*8
    fake=bytes(20)+fruit[at:at+4]+fruit[4:8]+fruit[at+4:at+8]
    im,_=e.material(fake,0)
    # Native Doom sprite offsets put the bottom at the actor's base.
    import io,zlib
    buf=io.BytesIO();im.save(buf,format='PNG');png=buf.getvalue()
    offset=struct.pack('>ii',16,32);chunk=b'grAb'+offset
    png=png[:33]+struct.pack('>I',8)+chunk+struct.pack('>I',zlib.crc32(chunk)&0xffffffff)+png[33:]
    (sprites/f'WMFR{chr(65+i)}0.png').write_bytes(png)
    if i==0:im.save(graphics/'WMPICON.png')
font=e.entries[e.byname['DispC']][5][568:]
for i in range(10):
    at=8+(16+i)*12
    fake=bytes(20)+font[at:at+4]+font[4:8]+font[at+4:at+8]
    im,_=e.material(fake,0);im.save(graphics/f'WMNUM{i}.png')
(e.PROJECT/'source/wumpa-assets.json').write_text(json.dumps({'fruit':'FruiC: original 14-frame sprite','digits':'DispC: font at offset 568, glyphs 16..25'},indent=2))
